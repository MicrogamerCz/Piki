// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginprocessor.h"
#include <QDesktopServices>
#include <QRandomGenerator>
#include <qcontainerfwd.h>
#include <qcryptographichash.h>
#include <qdbusconnection.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qtmetamacros.h>
#include <qurl.h>
#include <qurlquery.h>

LoginProcessor::LoginProcessor(QObject *parent)
    : QObject(parent)
    , dbus(QDBusConnection::sessionBus())
{
}

void LoginProcessor::openLoginPage()
{
    const QString chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";

    QRandomGenerator* gen = QRandomGenerator::global();
    for (int i = 0; i < 32; i++)
        codeVerifier.append(chars[gen->bounded(chars.length())]);

    QByteArray digest = QCryptographicHash::hash(codeVerifier.toUtf8(), QCryptographicHash::Sha256).toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals);
    QString codeChallenge = QString::fromUtf8(digest);

    QUrlQuery query {
        { "code_challenge", codeChallenge },
        { "code_challenge_method", "S256" },
        { "client", "pixiv-android" }
    };
    QUrl url("https://app-api.pixiv.net/web/v1/login");
    url.setQuery(query);

    QDBusConnection::sessionBus().registerService("io.github.microgamercz.piki");
    QDBusConnection::sessionBus().registerObject("/authcode", this, QDBusConnection::ExportScriptableContents);

    QDesktopServices::openUrl(url);
}

void LoginProcessor::finish(QString code)
{
    qDebug() << "recieved the code";
    QDBusConnection::sessionBus().unregisterObject("/authcode");
    QDBusConnection::sessionBus().unregisterService("io.github.microgamercz.piki");

    QNetworkRequest request((QUrl("https://oauth.secure.pixiv.net/auth/token")));
    request.setHeader(QNetworkRequest::UserAgentHeader, "PixivAndroidApp/5.0.234 (Android 11; Pixel 5)");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QUrlQuery data {
        { "client_id", "MOBrBDS8blbauoSck0ZfDbtuzpyT" },
        { "client_secret", "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj" },
        { "code", code },
        { "code_verifier", codeVerifier },
        { "grant_type", "authorization_code" },
        { "include_policy", "true" },
        { "redirect_uri", "https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback" }
    };
    connect(&manager, &QNetworkAccessManager::finished, this, &LoginProcessor::codeRecieved);
    manager.post(request, data.toString(QUrl::FullyEncoded).toUtf8());
}

void LoginProcessor::codeRecieved(QNetworkReply *reply)
{
    Q_EMIT loggedIn(reply->readAll());
}
