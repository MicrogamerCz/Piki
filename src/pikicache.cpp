// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikicache.h"
#include "pikitags.h"
#include <algorithm>

Cache::Cache(QObject *parent)
    : QObject(parent)
    , m_suggestedTags(new PikiTags(this))
    , m_historyTags(new PikiTags(this))
    , m_selectedTags(new PikiTags(this))
{
    DatabaseConfiguration config;
    config.setDatabaseName(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/data.sqlite");
    config.setType(DatabaseType::SQLite);

    database = ThreadedDatabase::establishConnection(config);
}

QCoro::QmlTask Cache::setup()
{
    return refreshUsersTask();
}
QCoro::QmlTask Cache::setCurrentUser(PikiUser *user)
{
    m_currentUser = user;
    Q_EMIT currentUserChanged();
    return setCurrentUserTask(user);
}
QCoro::QmlTask Cache::removeUser(User *user)
{
    return database->execute("DELETE FROM accounts WHERE id = ?", user->m_id);
}
QCoro::QmlTask Cache::getTagHistory()
{
    return getTagHistoryTask();
}
QCoro::QmlTask Cache::pushTagHistory(QList<Tag *> tags)
{
    return pushTagHistoryTask(tags);
}
void Cache::setSuggestedTags(Tags *tags)
{
    m_suggestedTags->clear();
}

QCoro::Task<> Cache::refreshUsersTask()
{
    co_await database->runMigrations(":/qt/qml/io/github/micro/piki/contents/migrations/");
    std::vector<PikiUser *> users = co_await database->getObjects<PikiUser>("SELECT * FROM accounts WHERE is_primary = 0;");

    m_otherUsers.resize(users.size());
    std::move(users.begin(), users.end(), m_otherUsers.begin());

    std::optional<PikiUser *> optUser = co_await database->getObject<PikiUser>("SELECT * FROM accounts WHERE is_primary = 1;");
    if (!optUser.has_value() && !m_otherUsers.empty()) {
        co_await database->execute("UPDATE accounts SET is_primary = 1 WHERE id = (SELECT id FROM accounts ORDER BY id LIMIT 1);");
        co_await refreshUsersTask();
        co_return;
    }
    m_currentUser = optUser ? optUser.value() : nullptr;

    Q_EMIT currentUserChanged();
    Q_EMIT otherUsersChanged();
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
QCoro::Task<QList<Tag *>> Cache::getTagHistoryTask()
{
    std::vector<Tag *> tagsResult = co_await database->getObjects<Tag>(
        "SELECT name, translated FROM tags "
        "JOIN tags_history ON tags.id = tags_history.tag_id "
        "WHERE user_id IN (SELECT id FROM accounts WHERE is_primary = 1) "
        "ORDER BY tags_history.frequency DESC LIMIT 20"); // TODO: add variable limit with kconfig
    QList<Tag *> tags;
    tags.resize(tagsResult.size());
    std::move(tagsResult.begin(), tagsResult.end(), tags.begin());

    co_return tags;
}
QCoro::Task<> Cache::pushTagHistoryTask(QList<Tag *> tags)
{
    co_await database->execute("BEGIN TRANSACTION");

    for (Tag *tag : tags) {
        if (tag->m_name == "")
            continue;

        co_await database->execute(
            "INSERT INTO tags (name, translated) VALUES (?, ?) ON CONFLICT(name) "
            "DO UPDATE SET name = excluded.name, translated = COALESCE(translated, excluded.translated)",
            tag->m_name,
            tag->m_translatedName);
        co_await database->execute(
            "INSERT INTO tags_history (tag_id, user_id) VALUES ((SELECT id FROM tags WHERE name = ? LIMIT 1), "
            "(SELECT id FROM accounts WHERE is_primary = 1 LIMIT 1)) ON CONFLICT(tag_id, user_id) "
            "DO UPDATE SET frequency = frequency + 1",
            tag->m_name);
    }

    co_await database->execute("COMMIT");
}
