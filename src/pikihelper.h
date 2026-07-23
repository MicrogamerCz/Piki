// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#pragma once
#include "piqi/illustration.h"
#include "piqi/user.h"
#include "pixivnamfactory.h"
#include <QCoroQml>
#include <QtQmlIntegration>
#include <libportal/portal-helpers.h>
#include <qtmetamacros.h>

class PikiHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool isPortalSupported READ getIsPortalSupported NOTIFY supportedWallpaperSessionChanged)

    const QStringList explicitlySupportedSessions{"Hyprland"};
    bool portalPresent;
    PixivNAM manager;

    bool getIsPortalSupported() const;

    static g_autoptr(XdpPortal) portal;
    static void setWallpaperPortal(GObject *source_object, GAsyncResult *res, gpointer data);

public:
    PikiHelper(QObject *parent = nullptr);
    QCoro::Task<QString> CheckFanboxTask(int id);
    QCoro::Task<> SetWallpaperTask(Illustration *illust, uint screen = 0, int index = 0);

    // Wallpaper backends (Wallpaper portal + implementations without portal)
    void SetWallpaperHyprpaper(QString path, uint screen = 0);
    uint GetScreenCountHyprland();
    QJsonArray GetScreensHyprland();

    Q_SIGNAL void supportedWallpaperSessionChanged();
public Q_SLOTS:
    QCoro::QmlTask CheckFanbox(User *user);
    QCoro::QmlTask SetWallpaper(Illustration *illust, uint screen = 0, int index = 0);
    uint GetScreenCount(); // -1 is default for unknown number of screens
};
