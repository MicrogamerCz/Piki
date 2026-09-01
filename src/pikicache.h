// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikitags.h"
#include "pikiuser.h"
#include <QCoro>
#include <QCoroQml>
#include <piqi/Piqi>
#include <threadeddatabase.h>

inline auto hashTagPtrs = [](const Tag *tag) {
    return qHashMulti(0, tag->m_name, tag->m_translatedName);
};
inline auto equalTagPtrs = [](const Tag *a, const Tag *b) {
    return *a == *b;
};

class Cache : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    QM_PROPERTY(PikiUser *, currentUser)
    QM_PROPERTY(std::vector<PikiUser *>, otherUsers)
    QM_PROPERTY(PikiTags *, suggestedTags)
    QM_PROPERTY(PikiTags *, historyTags)
    QM_PROPERTY(PikiTags *, selectedTags)

public:
    Cache(QObject *parent = nullptr);

public Q_SLOTS:
    QCoro::QmlTask setup();
    QCoro::QmlTask setCurrentUser(PikiUser *user); // check if it updates tags history
    QCoro::QmlTask removeUser(User *user);

    QCoro::QmlTask getTagHistory() const;
    QCoro::QmlTask pushTagHistory() const;
    void setTagSuggestions(const QList<Tag *> &tags) const;

    bool selectTag(Tag *tag);
    void unselectTag(Tag *tag);

private:
    std::unique_ptr<ThreadedDatabase> database;
    std::unordered_set<Tag *, decltype(hashTagPtrs), decltype(equalTagPtrs)> selectedTagSet;

    QCoro::Task<> setupTask();

    QCoro::Task<> refreshUsersTask();
    QCoro::Task<> setCurrentUserTask(PikiUser *user);

    QCoro::Task<> getTagHistoryTask() const;
    QCoro::Task<> pushTagHistoryTask() const;

    void clearPikiTags(PikiTags &tags) const;
    int getPikiTagsIndex(PikiTags &tags, Tag *tag) const;
};
