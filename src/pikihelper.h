// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "piqi/illustration.h"
#include "piqi/user.h"
#include "pixivnamfactory.h"
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

    const QStringList supportedSessions{"KDE", "Hyprland"};
    PixivNAM manager;

public:
    PikiHelper(QObject *parent = nullptr);
    QCoro::Task<QString> CheckFanboxTask(int id);
    QCoro::Task<> SetWallpaperTask(Illustration *illust, uint screen = 0, int index = 0);

    // Wallpaper backends (TODO: Plugins for setting wallpaper, not hosting ALL backends in the main Piki code (only KDE by def?))
    void SetWallpaperKDE(QString path, uint screen = 0);
    // uint GetScreenCountKDE(); // TODO
    void SetWallpaperHyprpaper(QString path, uint screen = 0);
    uint GetScreenCountHyprland();
    QJsonArray GetScreensHyprland();
public Q_SLOTS:
    QCoro::QmlTask CheckFanbox(User *user);
    QCoro::QmlTask SetWallpaper(Illustration *illust, uint screen = 0, int index = 0);
    uint GetScreenCount(); // -1 is default for unknown number of screens
    void ShareToClipboard(Illustration *illust);
};
