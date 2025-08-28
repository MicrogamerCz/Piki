// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikicache.h"
#include "piqi/illustration.h"
#include "piqi/imageurls.h"
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qdebug.h>
#include <qdir.h>
#include <qiodevicebase.h>
#include <qlogging.h>
#include <qstandardpaths.h>
#include <qtimer.h>
#include <qtpreprocessorsupport.h>
#include <sys/socket.h>

UserResult UserResult::fromSql(ColumnTypes &&tuple)
{
    auto [id, name, account, pfp] = tuple;
    return UserResult{id, name, account, pfp};
}

TagResult TagResult::fromSql(ColumnTypes &&tuple)
{
    auto [id, name, translated] = tuple;
    return TagResult{id, name, translated};
}

TagHistoryResult TagHistoryResult::fromSql(ColumnTypes &&tuple)
{
    auto [id, frequency] = tuple;
    return TagHistoryResult{id, frequency};
}

Cache::Cache(QObject *parent)
    : QObject(parent)
{
    DatabaseConfiguration config;
    config.setDatabaseName(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/data.sqlite");
    config.setType(DatabaseType::SQLite);

    database = ThreadedDatabase::establishConnection(config);
}

QCoro::QmlTask Cache::Setup()
{
    return database->runMigrations(":/qt/qml/io/github/micro/piki/contents/migrations/");
}

QCoro::QmlTask Cache::PushTagHistory(QList<Tag *> tags)
{
    return PushTagHistoryTask(tags);
}
QCoro::Task<void> Cache::PushTagHistoryTask(QList<Tag *> tags)
{
    for (Tag *tag : tags) {
        if (tag->m_name == "")
            continue;

        std::optional<TagResult> queried = co_await database->getResult<TagResult>("SELECT * FROM tags WHERE name = ?", tag->m_name);
        if (queried.has_value() && queried.value().translated == "" && tag->m_translatedName != "") {
            co_await database->execute("UPDATE tags SET translated = ? WHERE name = ?", tag->m_translatedName, tag->m_name);
        } else if (!queried.has_value()) {
            co_await database->execute("INSERT INTO tags (name, translated) VALUES (?, ?)", tag->m_name, tag->m_translatedName);
            queried = co_await database->getResult<TagResult>("SELECT id, name, translated FROM tags WHERE name = ?", tag->m_name);
        }

        std::optional<TagHistoryResult> history =
            co_await database->getResult<TagHistoryResult>("SELECT tag_id, frequency FROM tags_history WHERE tag_id = ?", queried.value().id);
        if (history.has_value())
            co_await database->execute("UPDATE tags_history SET frequency = frequency + 1 WHERE tag_id = ?", history.value().id);
        else
            co_await database->execute("INSERT INTO tags_history (tag_id) VALUES (?)", queried.value().id);
    }

    co_return;
}

QCoro::QmlTask Cache::GetTagHistory()
{
    return GetTagHistoryTask();
}
QCoro::Task<QList<Tag *>> Cache::GetTagHistoryTask()
{
    QList<Tag *> tags;
    std::vector<TagResult> tagsResult = co_await database->getResults<TagResult>(
        "SELECT tags.* FROM tags JOIN tags_history ON tags.id = tags_history.tag_id ORDER BY tags_history.frequency DESC LIMIT 20");
    for (TagResult result : tagsResult) {
        Tag *tg = new Tag;
        tg->m_name = result.name;
        tg->m_translatedName = result.translated;
        tags.append(tg);
    }
    co_return tags;
}

void Cache::SynchroniseIllusts(QList<Illustration *> illusts)
{
    return; // Unstable
    for (int i = 0; i < illusts.count(); i++) {
        Illustration *illust = illusts[i];

        int id = illust->m_id;
        if (illustCache.contains(id)) {
            illusts[i] = illustCache[id];
            illust->deleteLater();
        } else
            illustCache.insert(id, illust);
    }
}

QCoro::Task<QList<User *>> Cache::ReadUserCache(QString excludedUser)
{
    qDebug() << "Excluded user:" << excludedUser;
    QList<User *> users;
    std::vector<UserResult> results = co_await database->getResults<UserResult>("SELECT * FROM accounts WHERE (accounts.account != ?)", excludedUser);
    for (UserResult result : results) {
        User *u = new User;
        u->m_id = result.id;
        u->m_name = result.name;
        u->m_account = result.account;
        u->m_profileImageUrls = new ImageUrls;
        u->m_profileImageUrls->m_px50 = result.pfp;
        users.append(u);
    }
    co_return users;
}
QCoro::Task<> Cache::WriteUserToCache(User *user)
{
    co_await database->execute("INSERT INTO accounts (id, name, account, pfp) VALUES (?, ?, ?, ?)",
                               user->m_id,
                               user->m_name,
                               user->m_account,
                               user->m_profileImageUrls->m_px50);
}

QCoro::Task<> Cache::DeleteUserFromCache(User *user)
{
    co_await database->execute("DELETE FROM accounts WHERE id = ?", user->m_id);
}
