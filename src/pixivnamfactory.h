// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikiconfig.h"
#include <QDir>
#include <QNetworkDiskCache>
#include <QQmlNetworkAccessManagerFactory>
#include <qmath.h>
#include <qnetworkaccessmanager.h>
#include <qqmlengine.h>
#include <qtypes.h>

class PixivNAM : public QNetworkAccessManager
{
    Q_OBJECT

public:
    PixivNAM(QObject *parent = nullptr)
        : QNetworkAccessManager(parent)
    {
    }

protected:
    QNetworkReply *createRequest(Operation op, const QNetworkRequest &request, QIODevice *outgoingData = nullptr) override
    {
        QNetworkRequest modifiedRequest = request;
        modifiedRequest.setRawHeader("Referer", "https://app-api.pixiv.net/");
        return QNetworkAccessManager::createRequest(op, modifiedRequest, outgoingData);
    }
};

class PixivNAMFactory : public QQmlNetworkAccessManagerFactory
{
    const qint64 infinity = 9223372036854775807; // infinite cache(TM)
public:
    PikiConfig *cfg = nullptr;

    inline QNetworkAccessManager *create(QObject *parent) override
    {
        QString cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
        if (!QDir().exists(cachePath + "/wallpapers"))
            QDir(cachePath).mkdir("/wallpapers");

        QNetworkAccessManager *networkAccessManager = new PixivNAM(parent);
        QNetworkDiskCache *diskCache = new QNetworkDiskCache(parent);
        uint maxSize = cfg->cacheSize();
        qint64 cache = qPow(2, maxSize) * qPow(1024, 3);
        if (maxSize == 8)
            cache = infinity;
        diskCache->setMaximumCacheSize(cache);

        diskCache->setCacheDirectory(cachePath + "/cache");

        networkAccessManager->setCache(diskCache);

        return networkAccessManager;
    }
};
