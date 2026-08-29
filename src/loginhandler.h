// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikicache.h"
#include <piqi/User>

class LoginHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON;

    QM_PROPERTY(Cache *, cache)
    QM_PROPERTY(bool, keyringProviderInstalled)

public:
    LoginHandler(QObject *parent = nullptr);

public Q_SLOTS:
    QCoro::QmlTask GetToken();
    QCoro::QmlTask WriteToken(QString token);

private:
    // ? does it need to stay?
    // Access and refresh tokens are used for the current session,
    // on desktops without a keyring provider, until Piki is closed
    QString currentUser, accessToken, refreshToken;

    QCoro::Task<QString> GetPassword(QString key);
    QCoro::Task<> WritePassword(QString key, QString password);

    QCoro::Task<> WriteTokenTask(QString token);
};
