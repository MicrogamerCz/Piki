// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginhandler.h"
#include "pikicache.h"
#include <QCoro>
#include <QCoroSignal>
#include <QJsonDocument>
#include <qcorofuture.h>
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qdir.h>
#include <qt6keychain/keychain.h>
#include <qtimer.h>
#include <qtmetamacros.h>

LoginHandler::LoginHandler(QObject* parent) : QObject(parent) {
}
bool LoginHandler::IsKeyringPresent()
{
    m_keyringProviderInstalled = QKeychain::isAvailable();

    Q_EMIT keyringProviderInstalledChanged();
    if (!m_keyringProviderInstalled)
        return false;

    return true;
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
    co_await qCoro(&writeJob, &QKeychain::ReadPasswordJob::finished);
}
QCoro::Task<QString> LoginHandler::GetUser()
{
    return GetPassword("current_user");
}
QCoro::QmlTask LoginHandler::SetUser(QString username)
{
    return WritePassword("current_user", username).then([this]() {
        if (m_keyringProviderInstalled)
            RefreshOtherUsers();
    });
}
void LoginHandler::WriteToken(QString token) {
    // return GetUser().then([this](QString username) {
    // });
    // if (m_keyringProviderInstalled)
    // wallet->writePassword(GetUser(), token);
    // else
    // refreshToken = token;
}
QString LoginHandler::GetToken() {
    if (!m_keyringProviderInstalled)
        return accessToken;
    QString token;
    // wallet->readPassword(GetUser(), token);
    return token;
}
QCoro::QmlTask LoginHandler::SetCacheIfNotExists(Cache *cache)
{
    if (!pkc)
        pkc = cache;

    if (m_keyringProviderInstalled)
        return RefreshOtherUsersTask();
    else
        return PlaceholderTask();
}
QCoro::QmlTask LoginHandler::RefreshOtherUsers()
{
    return RefreshOtherUsersTask();
}
QCoro::Task<void> LoginHandler::RefreshOtherUsersTask()
{
    if (!m_keyringProviderInstalled)
        co_return;
    m_otherUsers = co_await pkc->ReadUserCache();
    QString currentAccount = co_await GetUser();
    int i = 0;
    for (i = 0; i < m_otherUsers.length(); i++) {
        User *u = m_otherUsers[i];
        if (u->m_account == currentAccount)
            break;
    }
    if (i < m_otherUsers.length())
        m_otherUsers.remove(i);
    Q_EMIT otherUsersChanged();
}
QCoro::QmlTask LoginHandler::RemoveUser(User *user)
{
    if (!m_keyringProviderInstalled)
        return PlaceholderTask();
    // wallet->writePassword(user->m_account, "");
    return pkc->DeleteUserFromCache(user);
}
QCoro::QmlTask LoginHandler::SaveUserToCache(QString data, Piqi *client)
{
    QJsonObject obj = QJsonDocument::fromJson(data.toUtf8()).object();
    Account *user = new Account(nullptr, obj);
    if (client) {
        client->m_user = user;
        Q_EMIT client->userChanged();
    }
    if (!m_keyringProviderInstalled)
        return PlaceholderTask();
    return pkc->WriteUserToCache(user);
}

QCoro::Task<> LoginHandler::PlaceholderTask()
{
    co_return;
}
