// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginhandler.h"
#include "pikicache.h"
#include <QJsonDocument>
#include <qcorotask.h>
#include <qdir.h>
#include <qtimer.h>
#include <qtmetamacros.h>

LoginHandler::LoginHandler(QObject* parent) : QObject(parent) {
}
bool LoginHandler::IsKeyringPresent()
{
    wallet = KWallet::Wallet::openWallet(KWallet::Wallet::LocalWallet(), 0);
    m_keyringProviderInstalled = wallet != nullptr;
    Q_EMIT keyringProviderInstalledChanged();
    if (!m_keyringProviderInstalled)
        return false;

    if (!wallet->hasFolder("Piki")) wallet->createFolder("Piki");
    wallet->setFolder("Piki");

    return true;
}
QString LoginHandler::GetUser() {
    if (!m_keyringProviderInstalled)
        return "";
    QString user;
    wallet->readPassword("current_user", user);
    return user;
}
void LoginHandler::SetUser(QString username) {
    if (!m_keyringProviderInstalled)
        return;
    wallet->writePassword("current_user", username);
    RefreshOtherUsers();
}
void LoginHandler::WriteToken(QString token) {
    if (m_keyringProviderInstalled)
        wallet->writePassword(GetUser(), token);
    else
        refreshToken = token;
}
QString LoginHandler::GetToken() {
    if (!m_keyringProviderInstalled)
        return accessToken;
    QString token;
    wallet->readPassword(GetUser(), token);
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
    QString currentAccount = GetUser();
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
    wallet->writePassword(user->m_account, "");
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
