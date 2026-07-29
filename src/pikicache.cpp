// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikicache.h"
#include <QCoro/QCoroCore>
#include <QCoro/QCoroFuture>
#include <algorithm>

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
    return refreshUsersTask();
}
QCoro::Task<> Cache::refreshUsersTask()
{
    co_await database->runMigrations(":/qt/qml/io/github/micro/piki/contents/migrations/");
    std::vector<PikiUser *> users = co_await database->getObjects<PikiUser>("SELECT * FROM accounts WHERE is_primary = 0;");
    std::move(users.begin(), users.end(), m_otherUsers.begin());

    std::optional<PikiUser *> optUser = co_await database->getObject<PikiUser>("SELECT * FROM accounts WHERE is_primary = 1;");
    if (!optUser.has_value() && !m_otherUsers.empty()) {
        co_await database->execute("UPDATE accounts SET is_primary = 1 WHERE id = (SELECT id FROM accounts ORDER BY id LIMIT 1);");
        co_await refreshUsersTask();
        co_return;
    }
    qDebug() << "Is there primary user? " << optUser.has_value();
    m_currentUser = optUser ? optUser.value() : nullptr;

    Q_EMIT currentUserChanged();
    Q_EMIT otherUsersChanged();
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

QCoro::QmlTask Cache::removeUser(User *user)
{
    return database->execute("DELETE FROM accounts WHERE id = ?", user->m_id);
}

QCoro::QmlTask Cache::setCurrentUser(PikiUser *user)
{
    m_currentUser = user;
    Q_EMIT currentUserChanged();
    return setCurrentUserTask(user);
}
QCoro::Task<> Cache::setCurrentUserTask(PikiUser *user)
{
    co_await database->execute("INSERT INTO accounts (id, name, account, pfp) VALUES (?, ?, ?, ?);",
                               user->m_id,
                               user->m_name,
                               user->m_account,
                               user->m_profileImageUrls->m_px50);
    co_await database->execute("UPDATE accounts SET is_primary = (account = ?);", user->m_account);
    co_await refreshUsersTask();
}
