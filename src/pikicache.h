// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikitags.h"
#include "pikiuser.h"
#include <QCoro>
#include <QCoroQml>
#include <piqi/Piqi>
#include <threadeddatabase.h>

class Cache : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    QM_PROPERTY(PikiUser *, currentUser)
    QM_PROPERTY(QList<PikiUser *>, otherUsers)
    QM_PROPERTY(PikiTags *, suggestedTags)
    QM_PROPERTY(PikiTags *, historyTags)
    QM_PROPERTY(PikiTags *, selectedTags)

public:
    Cache(QObject *parent = nullptr);

public Q_SLOTS:
    QCoro::QmlTask setup();
    QCoro::QmlTask setCurrentUser(PikiUser *user);
    QCoro::QmlTask removeUser(User *user);
    QCoro::QmlTask getTagHistory();
    QCoro::QmlTask pushTagHistory(QList<Tag *> tags);
    void setSuggestedTags(QList<Tag *> tags);

private:
    std::unique_ptr<ThreadedDatabase> database;
    Piqi *client = nullptr; // * use later

    QCoro::Task<> refreshUsersTask();
    QCoro::Task<> setCurrentUserTask(PikiUser *user);
    QCoro::Task<QList<Tag *>> getTagHistoryTask();
    QCoro::Task<> pushTagHistoryTask(QList<Tag *> tags);
};
