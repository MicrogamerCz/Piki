// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginprocessor.h"
#include <qcborvalue.h>
#include <QRandomGenerator>
#include <qcontainerfwd.h>
#include <qcryptographichash.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qquickwebengineprofile.h>
#include <qtmetamacros.h>
#include <qurl.h>
#include <qurlquery.h>
#include <qwebengineurlrequestinfo.h>

void LoginProcessor::AddInterceptor(QQuickWebEngineProfile* profile) {
    connect(&interceptor, &PixivInterceptor::callbackFound, this, &LoginProcessor::Finish);
    profile->setUrlRequestInterceptor(&interceptor);
}
QUrl LoginProcessor::Begin() {
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

    return url;
}
void LoginProcessor::Finish(QString code) {
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
    connect(&manager, &QNetworkAccessManager::finished, this, &LoginProcessor::CodeRecieved);
    manager.post(request, data.toString(QUrl::FullyEncoded).toUtf8());
}
void LoginProcessor::CodeRecieved(QNetworkReply* reply) {
    Q_EMIT loggedIn(reply->readAll());
}
void PixivInterceptor::interceptRequest(QWebEngineUrlRequestInfo &info) {
    QUrl url = info.requestUrl();
    if (!url.toString().startsWith("https://app-api.pixiv.net/web/v1/users/auth/pixiv/callback")) return;

    QUrlQuery query(url);
    Q_EMIT callbackFound(query.queryItemValue("code"));
}
