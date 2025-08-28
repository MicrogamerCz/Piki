// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginhandler.h"
#include "pikicache.h"
#include <QCoro>
#include <QCoroSignal>
#include <QJsonDocument>
#include <qcontainerfwd.h>
#include <qcorofuture.h>
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qdir.h>
#include <qt6keychain/keychain.h>
#include <qtimer.h>
#include <qtmetamacros.h>

LoginHandler::LoginHandler(QObject *parent)
    : QObject(parent)
{
    m_keyringProviderInstalled = QKeychain::isAvailable();
    Q_EMIT keyringProviderInstalledChanged();
}

QCoro::Task<QString> LoginHandler::GetPassword(QString key)
{
    if (!m_keyringProviderInstalled)
        co_return "";

    QKeychain::ReadPasswordJob readJob = QKeychain::ReadPasswordJob{"Piki"};
    readJob.setKey(key);
    readJob.setAutoDelete(false);

    readJob.start();
    co_await qCoro(&readJob, &QKeychain::ReadPasswordJob::finished);

    QString user = readJob.textData();
    readJob.deleteLater();
    co_return user;
}
QCoro::Task<> LoginHandler::WritePassword(QString key, QString password)
{
    if (!m_keyringProviderInstalled)
        co_return;

    QKeychain::WritePasswordJob writeJob = QKeychain::WritePasswordJob{"Piki"};
    writeJob.setKey(key);
    writeJob.setTextData(password);
    writeJob.setAutoDelete(true);
    writeJob.start();
    co_await qCoro(&writeJob, &QKeychain::WritePasswordJob::finished);
}

QCoro::Task<QString> LoginHandler::GetUser()
{
    return GetPassword("current_user");
}
QCoro::QmlTask LoginHandler::SetUser(QString username)
{
    return SetUserTask(username);
}
QCoro::Task<> LoginHandler::SetUserTask(QString username)
{
    co_await WritePassword("current_user", username);
    co_await RefreshOtherUsersTask();
}

QCoro::QmlTask LoginHandler::GetToken()
{
    return GetTokenTask();
}
QCoro::Task<QString> LoginHandler::GetTokenTask()
{
    if (!m_keyringProviderInstalled)
        co_return accessToken;
    QString user = co_await GetUser();
    co_return (co_await GetPassword(user));
}

QCoro::QmlTask LoginHandler::WriteToken(QString token)
{
    return WriteTokenTask(token);
}
QCoro::Task<> LoginHandler::WriteTokenTask(QString token)
{
    if (!m_keyringProviderInstalled) {
        refreshToken = token;
        co_return;
    }
    QString user = co_await GetUser();
    co_await WritePassword(user, token);
}

QCoro::QmlTask LoginHandler::SetCacheIfNotExists(Cache *cache)
{
    return SetCacheIfNotExistsTask(cache);
}
QCoro::Task<> LoginHandler::SetCacheIfNotExistsTask(Cache *cache)
{
    if (!pkc)
        pkc = cache;

    co_await RefreshOtherUsersTask();
}

QCoro::Task<void> LoginHandler::RefreshOtherUsersTask()
{
    if (!m_keyringProviderInstalled)
        co_return;
    QString currentUser = co_await GetUser();
    m_otherUsers = co_await pkc->ReadUserCache(currentUser);
    Q_EMIT otherUsersChanged();
}

QCoro::QmlTask LoginHandler::SaveUserToCache(QString data, Piqi *client)
{
    return SaveUserToCacheTask(data, client);
}
QCoro::Task<> LoginHandler::SaveUserToCacheTask(QString data, Piqi *client)
{
    QJsonObject obj = QJsonDocument::fromJson(data.toUtf8()).object();
    Account *user = new Account(nullptr, obj);
    if (client) {
        client->m_user = user;
        Q_EMIT client->userChanged();
    }
    if (m_keyringProviderInstalled)
        co_await pkc->WriteUserToCache(user);
}

QCoro::QmlTask LoginHandler::RemoveUser(User *user)
{
    return RemoveUserTask(user);
}
QCoro::Task<> LoginHandler::RemoveUserTask(User *user)
{
    if (!m_keyringProviderInstalled)
        co_return;
    co_await WritePassword(user->m_account, "");
    co_await pkc->DeleteUserFromCache(user);
    co_await RefreshOtherUsersTask();
}
