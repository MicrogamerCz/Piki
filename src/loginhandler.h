// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikicache.h"
#include <QCoroQmlTask>
#include <QtQmlIntegration>
#include <piqi/Piqi>
#include <piqi/user.h>

#include "pikicache.h"

class LoginHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON;

    QM_PROPERTY(QList<User *>, otherUsers)
    QM_PROPERTY(bool, keyringProviderInstalled)

    Cache *pkc = nullptr;
    // Access and refresh tokens are used for the current session,
    // on desktops without a keyring provider, until Piki is closed
    QString currentUser, accessToken, refreshToken;

    QCoro::Task<QString> GetPassword(QString key);
    QCoro::Task<> WritePassword(QString key, QString password);

    QCoro::Task<QString> GetUser();
    QCoro::Task<> SetUserTask(QString user);

    QCoro::Task<QString> GetTokenTask();
    QCoro::Task<> WriteTokenTask(QString token);

    QCoro::Task<> SetCacheIfNotExistsTask(Cache *cache);
    QCoro::Task<> RefreshOtherUsersTask();

    QCoro::Task<> SaveUserToCacheTask(QString data, Piqi *client = nullptr);

    QCoro::Task<> RemoveUserTask(User *user);

public:
    LoginHandler(QObject *parent = nullptr);
public Q_SLOTS:
    QCoro::QmlTask SetUser(QString username);

    QCoro::QmlTask GetToken();
    QCoro::QmlTask WriteToken(QString token);

    QCoro::QmlTask SetCacheIfNotExists(Cache *cache);
    QCoro::QmlTask SaveUserToCache(QString data, Piqi *client = nullptr);

    QCoro::QmlTask RemoveUser(User *user);
};
