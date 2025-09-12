// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include <QNetworkAccessManager>

#ifndef Q_OS_ANDROID
#include <QQuickWebEngineProfile>
#include <QWebEngineUrlRequestInterceptor>
#endif

#ifndef Q_OS_ANDROID
class PixivInterceptor : public QWebEngineUrlRequestInterceptor
{
    Q_OBJECT

    public:
        void interceptRequest(QWebEngineUrlRequestInfo &info) override;
        Q_SIGNAL void callbackFound(QString code);
};
#endif
class LoginProcessor : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QNetworkAccessManager manager;
    QString codeVerifier = "";

#ifndef Q_OS_ANDROID
    PixivInterceptor interceptor;
#else
public
    Q_SLOT
#endif
    void Finish(QString code);

    public:
        void CodeRecieved(QNetworkReply* reply);
#ifndef Q_OS_ANDROID
        Q_SLOT void AddInterceptor(QQuickWebEngineProfile* profile);
#endif
        Q_SLOT QUrl Begin();
        Q_SIGNAL void loggedIn(QString response);
};
