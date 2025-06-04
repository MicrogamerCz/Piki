// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include <qcontainerfwd.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickwebengineprofile.h>
#include <qtmetamacros.h>
#include <qurl.h>
#include <QWebEngineUrlRequestInterceptor>
#include <QQuickWebEngineProfile>
#include <qwebengineurlrequestinterceptor.h>

class PixivInterceptor : public QWebEngineUrlRequestInterceptor
{
    Q_OBJECT

    public:
        void interceptRequest(QWebEngineUrlRequestInfo &info) override;
        Q_SIGNAL void callbackFound(QString code);
};
class LoginProcessor : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QNetworkAccessManager manager;
    PixivInterceptor interceptor;
    QString codeVerifier = "";

    void Finish(QString code);

    public:
        void CodeRecieved(QNetworkReply* reply);
        Q_SLOT void AddInterceptor(QQuickWebEngineProfile* profile);
        Q_SLOT QUrl Begin();
        Q_SIGNAL void loggedIn(QString response);
};
