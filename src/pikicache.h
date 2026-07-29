// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "pikiuser.h"
#include <QCoro/QCoroQmlTask>
#include <threadeddatabase.h>

class Cache : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    QM_PROPERTY(PikiUser *, currentUser)
    QM_PROPERTY(QList<PikiUser *>, otherUsers)

    std::unique_ptr<ThreadedDatabase> database;
    QCoro::Task<> pushTagHistoryTask(QList<Tag *> tags);
    QCoro::Task<> refreshUsersTask();
    QCoro::Task<QList<Tag *>> getTagHistoryTask();
    Q_SLOT QCoro::Task<> setCurrentUserTask(PikiUser *user);

public:
    Cache(QObject *parent = nullptr);
    Q_SLOT QCoro::QmlTask setCurrentUser(PikiUser *user);
    Q_SLOT QCoro::QmlTask removeUser(User *user);
    Q_SLOT QCoro::QmlTask setup();
    Q_SLOT QCoro::QmlTask pushTagHistory(QList<Tag *> tags);
    Q_SLOT QCoro::QmlTask getTagHistory();
};
