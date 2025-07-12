// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "piqi/qepr.h"
#include <QCoroQmlTask>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QtQmlIntegration>

class ImageDownloader : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QM_PROPERTY(qint64, progress)
    QM_PROPERTY(qint64, total)

    QNetworkAccessManager manager;

    void SetProgress(qint64 bytesReceived, qint64 bytesTotal);
    QCoro::Task<QString> DownloadTask(QString url);

    public:
        Q_SLOT QCoro::QmlTask Download(QString url);
};
