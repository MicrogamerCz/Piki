// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include <qcontainerfwd.h>
#include <qdbusconnection.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <qurl.h>

class LoginProcessor : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    LoginProcessor(QObject *parent = nullptr);
    Q_INVOKABLE void openLoginPage();
    Q_SCRIPTABLE void finish(QString code);

    Q_SIGNAL void loggedIn(QString response);

private:
    QDBusConnection dbus;
    QNetworkAccessManager manager;
    QString codeVerifier;

    void codeRecieved(QNetworkReply *reply);
};
