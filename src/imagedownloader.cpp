// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "imagedownloader.h"
#include "pikiconfig.h"
#include <QNetworkRequest>
#include <QUrl>
#include <QDir>
#include <QCoro>

void ImageDownloader::SetProgress(qint64 bytesReceived, qint64 bytesTotal) {
    m_progress = bytesReceived;
    Q_EMIT progressChanged();
    m_total = bytesTotal;
    Q_EMIT totalChanged();
}

QCoro::QmlTask ImageDownloader::Download(QString url) { return DownloadTask(url); }
QCoro::Task<QString> ImageDownloader::DownloadTask(QString url) {
    QString cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) % QDir::separator() % "images" % QDir::separator();
    if (!QDir().exists(cachePath))
        QDir().mkpath(cachePath);
    cachePath = cachePath + url.mid(url.lastIndexOf("/") + 1);

    QFile file(cachePath);
    if (file.exists()) co_return "file://" + cachePath;

    QNetworkRequest request((QUrl(url)));
    request.setRawHeader("Referer", "https://app-api.pixiv.net/");
    QNetworkReply* reply = manager.get(request);
    connect(reply, &QNetworkReply::downloadProgress, this, &ImageDownloader::SetProgress);
    co_await reply;

    if (reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 200) {
        file.open(QIODevice::WriteOnly);
        file.write(reply->readAll());
        file.close();

        co_return "file://" + cachePath;
    }
    else co_return "../assets/pixiv_no_profile.png";
}
