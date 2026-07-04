// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "loginprocessor.h"
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qtmetamacros.h>
#include <qurl.h>
#include <qurlquery.h>

void LoginProcessor::LoginWithRefreshToken(QString refreshToken)
{
    QNetworkRequest request((QUrl("https://oauth.secure.pixiv.net/auth/token")));
    request.setHeader(QNetworkRequest::UserAgentHeader, "PixivAndroidApp/5.0.234 (Android 11; Pixel 5)");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    QUrlQuery data{{"client_id", "MOBrBDS8blbauoSck0ZfDbtuzpyT"},
                   {"client_secret", "lsACyCD94FhDUtGTXi3QzcFE2uU1hqtDaKeqrdwj"},
                   {"grant_type", "refresh_token"},
                   {"refresh_token", refreshToken}};
    connect(&manager, &QNetworkAccessManager::finished, this, &LoginProcessor::CodeRecieved);
    manager.post(request, data.toString(QUrl::FullyEncoded).toUtf8());
}
void LoginProcessor::CodeRecieved(QNetworkReply* reply) {
    Q_EMIT loggedIn(reply->readAll());
}
