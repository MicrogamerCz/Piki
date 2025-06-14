// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "illustration.h"
#include "pixivnamfactory.h"
#include "user.h"
#include <QtQmlIntegration>
#include <qcoroqmltask.h>
#include <qcorotask.h>
#include <qhashfunctions.h>
#include <qnetworkaccessmanager.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>

class PikiHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    PixivNAM manager;

public:
    PikiHelper(QObject *parent = nullptr);
    QCoro::Task<QString> CheckFanboxTask(int id);
    QCoro::Task<> SetWallpaperTask(Illustration *illust);
public Q_SLOTS:
    QCoro::QmlTask CheckFanbox(User *user);
    QCoro::QmlTask SetWallpaper(Illustration *illust);
    void ShareToClipboard(Illustration *illust);
};
