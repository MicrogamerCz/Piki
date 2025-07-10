// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikiconfig.h"
#include "piqi/illustration.h"
#include "piqi/tag.h"
#include <QCoro>
#include <QObject>
#include <QtQmlIntegration>
#include <ThreadedDatabase>
#include <coroutine.h>
#include <kio/directorysizejob.h>
#include <kjob.h>
#include <qabstractnetworkcache.h>
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qhash.h>
#include <qobject.h>
#include <qtmetamacros.h>

struct UserResult {
    using ColumnTypes = std::tuple<int, QString, QString, QString>;
    static UserResult fromSql(ColumnTypes &&tuple);
    int id;
    QString name, account, pfp;
};
struct TagResult {
    using ColumnTypes = std::tuple<int, QString, QString>;
    static TagResult fromSql(ColumnTypes &&tuple);
    int id;
    QString name, translated;
};
struct TagHistoryResult {
    using ColumnTypes = std::tuple<int, int>;
    static TagHistoryResult fromSql(ColumnTypes &&tuple);
    int id, frequency;
};

class Cache : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    PikiConfig *conf;
    std::unique_ptr<ThreadedDatabase> database;
    QHash<int, Illustration *> illustCache;
    QCoro::Task<void> PushTagHistoryTask(QList<Tag *> tags);
    QCoro::Task<void> SetupTask();
    QCoro::Task<QList<Tag *>> GetTagHistoryTask();

public:
    Cache(QObject *parent = nullptr);
    QCoro::Task<QList<User *>> ReadUserCache();
    QCoro::Task<> WriteUserToCache(User *user);
    QCoro::Task<> DeleteUserFromCache(User *user);
    Q_SLOT QCoro::QmlTask Setup();
    Q_SLOT QCoro::QmlTask PushTagHistory(QList<Tag *> tags);
    Q_SLOT QCoro::QmlTask GetTagHistory();
    Q_SLOT void SynchroniseIllusts(QList<Illustration *> illusts);
};

/*
 * Unlike with normal QNetworkDiskCache, in this case, all images are saved in a normal
 * readable format, so that they can be literally copy-pasted anywhere, set to anything, etc.
 * Post metadata will be saved to the central cache DBs
 */
class PikiNetworkCache : public QAbstractNetworkCache
{
    Q_OBJECT

    const QString cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/cache/";

    KIO::DirectorySizeJob *job;
    qint64 i_cacheSize;
    void directorySizeFinished(KJob *j);

public:
    PikiNetworkCache(QObject *parent = nullptr);
    ~PikiNetworkCache() override;

    QNetworkCacheMetaData metaData(const QUrl &url) override;
    void updateMetaData(const QNetworkCacheMetaData &metaData) override;
    QIODevice *data(const QUrl &url) override;
    bool remove(const QUrl &url) override;
    qint64 cacheSize() const override;
    QIODevice *prepare(const QNetworkCacheMetaData &metaData) override;
    void insert(QIODevice *device) override;
    void clear() override;
};
