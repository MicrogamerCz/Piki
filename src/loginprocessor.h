// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include <qcontainerfwd.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>

class LoginProcessor : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QNetworkAccessManager manager;

public:
    void CodeRecieved(QNetworkReply *reply);
    Q_INVOKABLE void LoginWithRefreshToken(QString refreshToken);
    Q_SIGNAL void loggedIn(QString response);
};
