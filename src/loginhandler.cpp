// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginhandler.h"
#include <QCoro/QCoroSignal>
#include <qt6keychain/keychain.h>

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

QCoro::QmlTask LoginHandler::GetToken()
{
    return GetPassword(m_cache->m_currentUser->m_account);
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

    co_await WritePassword(m_cache->m_currentUser->m_account, token);
}
