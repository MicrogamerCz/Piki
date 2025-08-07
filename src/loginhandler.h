// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikicache.h"
#include <KWallet>
#include <QCoroQmlTask>
#include <QtQmlIntegration>
#include <piqi/Piqi>

#include "pikicache.h"

class LoginHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON;

    QM_PROPERTY(QList<User *>, otherUsers)
    QM_PROPERTY(bool, keyringProviderInstalled)

    KWallet::Wallet* wallet;
    Cache *pkc = nullptr;
    // Access and refresh tokens are used for the current session,
    // on desktops without a keyring provider, until Piki is closed
    QString currentUser, accessToken, refreshToken;

    QString GetUser();
    QCoro::Task<void> RefreshOtherUsersTask();

public:
    LoginHandler(QObject *parent = nullptr);
public Q_SLOTS:
    QCoro::QmlTask SetCacheIfNotExists(Cache *cache);
    QCoro::QmlTask SaveUserToCache(QString data, Piqi *client = nullptr);
    bool IsKeyringPresent();
    void SetUser(QString username);
    void WriteToken(QString token);
    QString GetToken();
    QCoro::QmlTask RefreshOtherUsers();
    QCoro::QmlTask RemoveUser(User *user);

    QCoro::Task<> PlaceholderTask();
};
