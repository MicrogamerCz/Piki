// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikicache.h"
#include "piqi/illustration.h"
#include "piqi/imageurls.h"
#include <algorithm>
#include <qcoroqmltask.h>
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
User *UserResult::toUser() const
{
    User *u = new User;
    u->m_id = id;
    u->m_name = name;
    u->m_account = account;
    u->m_profileImageUrls = new ImageUrls;
    u->m_profileImageUrls->m_px50 = pfp;
    return u;
}

TagResult TagResult::fromSql(ColumnTypes &&tuple)
{
    auto [id, name, translated] = tuple;
    return TagResult{id, name, translated};
}
Tag *TagResult::toTag() const
{
    Tag *tg = new Tag;
    tg->m_name = name;
    tg->m_translatedName = translated;
    return tg;
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

        co_await database->execute("BEGIN TRANSACTION");
        co_await database->execute(
            "INSERT INTO tags (name, translated) VALUES (?, ?) ON CONFLICT(name) "
            "DO UPDATE SET name = excluded.name, translated = COALESCE(translated, excluded.translated)",
            tag->m_name,
            tag->m_translatedName);
        co_await database->execute(
            "INSERT INTO tags_history (tag_id, user_id) VALUES (SELECT id FROM tags WHERE name = ?, "
            "SELECT id FROM accounts WHERE is_primary = 1) ON CONFLICT(tag_id) "
            "DO UPDATE SET frequency = frequency + 1",
            tag->m_name);
        co_await database->execute("COMMIT");
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
        "SELECT tags.* FROM tags "
        "JOIN tags_history ON tags.id = tags_history.tag_id "
        "ORDER BY tags_history.frequency DESC LIMIT 20");
    std::for_each(tagsResult.begin(), tagsResult.end(), [&tags](const TagResult &res) {
        tags.append(res.toTag());
    });
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
    QList<User *> users;
    std::vector<UserResult> results = co_await database->getResults<UserResult>("SELECT * FROM accounts WHERE accounts.account != ?", excludedUser);
    std::for_each(results.begin(), results.end(), [&users](const UserResult &res) {
        users.append(res.toUser());
    });
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
