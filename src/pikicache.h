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
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qhash.h>

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
    QCoro::Task<QList<Tag *>> GetTagHistoryTask();

public:
    Cache(QObject *parent = nullptr);
    QCoro::Task<QList<User *>> ReadUserCache(QString excludedUser = "");
    QCoro::Task<> WriteUserToCache(User *user);
    QCoro::Task<> DeleteUserFromCache(User *user);
    Q_SLOT QCoro::QmlTask Setup();
    Q_SLOT QCoro::QmlTask PushTagHistory(QList<Tag *> tags);
    Q_SLOT QCoro::QmlTask GetTagHistory();
    Q_SLOT void SynchroniseIllusts(QList<Illustration *> illusts);
};
