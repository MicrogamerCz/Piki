// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikicache.h"
#include "pikitags.h"
#include <QHashFunctions>
#include <QSet>
#include <algorithm>
#include <functional>
#include <qcorofuture.h>

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
    return setupTask();
}
QCoro::Task<> Cache::setupTask()
{
    co_await database->runMigrations(":/qt/qml/io/github/micro/piki/contents/migrations/");
    co_await refreshUsersTask();
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

QCoro::QmlTask Cache::getTagHistory() const
{
    return getTagHistoryTask();
}
QCoro::QmlTask Cache::pushTagHistory() const
{
    return pushTagHistoryTask();
}
void Cache::setTagSuggestions(const QList<Tag *> &tags) const
{
    clearPikiTags(*m_suggestedTags);

    for (Tag *tag : tags) {
        if (selectedTagSet.contains(tag))
            continue;

        m_suggestedTags->append(tag);
    }
}

bool Cache::selectTag(Tag *tag)
{
    if (!tag)
        return false;

    auto [iter, inserted] = selectedTagSet.insert(tag);
    if (!inserted)
        return false;

    // ! Fix issue with memory of tags
    m_selectedTags->append(tag);

    m_suggestedTags->remove(getPikiTagsIndex(*m_suggestedTags, tag));
    m_historyTags->remove(getPikiTagsIndex(*m_historyTags, tag));

    Q_EMIT selectedTagsChanged();
    Q_EMIT suggestedTagsChanged();
    Q_EMIT historyTagsChanged();

    return true;
}
void Cache::unselectTag(Tag *tag)
{
    if (!tag) // ? why it's null sometimes?
    {
        qDebug() << "No?";
        return;
    }

    m_selectedTags->remove(getPikiTagsIndex(*m_selectedTags, tag));
    selectedTagSet.erase(tag);

    Q_EMIT selectedTagsChanged();
}

QCoro::Task<> Cache::refreshUsersTask()
{
    // co_await database->runMigrations(":/qt/qml/io/github/micro/piki/contents/migrations/"); // * move migrations to code executed only once
    co_await getTagHistoryTask();

    m_otherUsers = co_await database->getObjects<PikiUser>("SELECT * FROM accounts WHERE is_primary = 0;");

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
QCoro::Task<> Cache::getTagHistoryTask() const
{
    std::vector<Tag *> tagsResult = co_await database->getObjects<Tag>(
        "SELECT name, translated FROM tags "
        "JOIN tags_history ON tags.id = tags_history.tag_id "
        "WHERE user_id IN (SELECT id FROM accounts WHERE is_primary = 1) "
        "ORDER BY tags_history.frequency DESC, tags.name LIMIT 20"); // TODO: add variable limit via kconfig

    clearPikiTags(*m_historyTags);

    std::for_each(tagsResult.begin(), tagsResult.end(), [this](Tag *tag) {
        if (!selectedTagSet.contains(tag))
            m_historyTags->append(tag);
    });
}
QCoro::Task<> Cache::pushTagHistoryTask() const
{
    co_await database->execute("BEGIN TRANSACTION");

    for (Tag *tag : m_selectedTags->m_tags) {
        if (tag->m_name.isEmpty())
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

void Cache::clearPikiTags(PikiTags &tags) const
{
    std::for_each(tags.m_tags.begin(), tags.m_tags.end(), std::mem_fn(&Tag::deleteLater));
    tags.clear();
}
int Cache::getPikiTagsIndex(PikiTags &tags, Tag *tag) const
{
    QList<Tag *> &tagList = tags.m_tags;
    for (int i = 0; i < tagList.count(); i++) {
        if (equalTagPtrs(tagList[i], tag))
            return i;
    }
    return -1;
}
