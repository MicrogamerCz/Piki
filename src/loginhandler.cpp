// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginhandler.h"
#include "pikicache.h"
#include "piqi/user.h"
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qdir.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qtmetamacros.h>

LoginHandler::LoginHandler(QObject* parent) : QObject(parent) {
    wallet = KWallet::Wallet::openWallet(KWallet::Wallet::LocalWallet(), 0);
    if (!wallet->hasFolder("Piki")) wallet->createFolder("Piki");
    wallet->setFolder("Piki");
}
QString LoginHandler::GetUser() {
    QString user;
    wallet->readPassword("current_user", user);
    return user;
}
void LoginHandler::SetUser(QString username) {
    wallet->writePassword("current_user", username);
    RefreshOtherUsers();
}
void LoginHandler::WriteToken(QString token) {
    wallet->writePassword(GetUser(), token);
}
QString LoginHandler::GetToken() {
    QString token;
    wallet->readPassword(GetUser(), token);
    return token;
}
QCoro::QmlTask LoginHandler::SetCacheIfNotExists(Cache *cache)
{
    if (!pkc)
        pkc = cache;

    return RefreshOtherUsersTask();
}
QCoro::QmlTask LoginHandler::RefreshOtherUsers()
{
    return RefreshOtherUsersTask();
}
QCoro::Task<void> LoginHandler::RefreshOtherUsersTask()
{
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
    return pkc->WriteUserToCache(user);
}
