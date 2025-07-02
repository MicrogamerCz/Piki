// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikihelper.h"
#include "pikiconfig.h"
#include "piqi/illustration.h"
#include <QClipboard>
#include <QCoro>
#include <QLocalSocket>
#include <QtDBus>
#include <qapplication.h>
#include <qcontainerfwd.h>
#include <qcoroqmltask.h>
#include <qdbusconnection.h>
#include <qdbusinterface.h>
#include <qdbusreply.h>
#include <qdebug.h>
#include <qdir.h>
#include <qiodevicebase.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qlocalsocket.h>
#include <qlogging.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qobject.h>
#include <qstringliteral.h>
#include <qtenvironmentvariables.h>
#include <qurl.h>
#include <qwindowdefs.h>

PikiHelper::PikiHelper(QObject *parent)
    : QObject(parent)
{
}
QCoro::QmlTask PikiHelper::CheckFanbox(User *user)
{
    return CheckFanboxTask(user->m_id);
}
QCoro::Task<QString> PikiHelper::CheckFanboxTask(int id)
{
    QUrl url("https://www.pixiv.net/fanbox/creator/" + QString::number(id));

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    QNetworkReply *reply = co_await manager.head(request);

    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (statusCode == 404)
        co_return "";

    QString header = reply->header(QNetworkRequest::LocationHeader).toString();
    co_return header;
}
void PikiHelper::ShareToClipboard(Illustration *illust)
{
    QClipboard *cbd = QApplication::clipboard();
    cbd->setText("https://pixiv.net/artworks/" + QString::number(illust->m_id));
}
QCoro::QmlTask PikiHelper::SetWallpaper(Illustration *illust, uint screen, int index)
{
    return SetWallpaperTask(illust, screen, index);
}
QCoro::Task<> PikiHelper::SetWallpaperTask(Illustration *illust, uint screen, int index)
{
    QString url;
    if (illust->m_pageCount > 1)
        url = illust->m_metaPages[index]->m_original;
    else
        url = illust->m_metaSinglePage;

    QString path = PikiConfig::self()->cachePath() + "wallpapers/" + url.mid(url.lastIndexOf("/") + 1);
    QFile file(path);

    if (!file.exists()) {
        QNetworkRequest request((QUrl(url)));
        request.setRawHeader("Referer", "https://app-api.pixiv.net/");
        QNetworkReply *reply = co_await manager.get(request);
        QByteArray data = reply->readAll();
        file.open(QIODevice::WriteOnly);
        file.write(data);
        file.close();
    }

    // Options for other DEs/compositors
    // First attempt is checking for official wallpaper backend (eg. Plasma for KDE,
    // Hyprpaper for Hyprland, etc.) then there could be a check against other common
    // (or contributed) backends
    // For adding backends, the intergration should be prefferably by DBus or a
    // Unix socket, as long as the wallpaper is passed as a path to a file and not
    // the data
    QString sessionDesktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP");
    switch (supportedSessions.indexOf(sessionDesktop)) {
    case 0: {
        SetWallpaperKDE(path, screen);
        break;
    }
    case 1: {
        SetWallpaperHyprpaper(path, screen);
        break;
    }
    }
}
void PikiHelper::SetWallpaperKDE(QString path, uint screen)
{
    // Using: https://invent.kde.org/plasma/plasma-workspace/-/blob/master/shell/tests/setwallpapertest.cpp
    // SPDX-FileCopyrightText: 2022 Méven Car <meven@kde.org>
    // SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

    QDBusInterface *interface = new QDBusInterface("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", QDBusConnection::sessionBus(), this);
    if (!interface->isValid())
        return;

    QVariantMap params{{"Image", path}};
    interface->call("setWallpaper", "org.kde.image", params, screen);
}
void PikiHelper::SetWallpaperHyprpaper(QString path, uint screen)
{
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR"), his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE"),
            socketPath = runtimeDir + "/hypr/" + his + "/.hyprpaper.sock";
    QLocalSocket sock;
    sock.connectToServer(socketPath);
    if (sock.waitForConnected()) {
        sock.write(("preload " + path + "\n").toUtf8());
        sock.flush();
        sock.waitForReadyRead();
        QJsonArray screens = GetScreensHyprland();
        QString request = "wallpaper " + screens[screen].toObject()["name"].toString() + "," + path + "\n";
        sock.write(request.toUtf8());
        sock.flush();
        sock.waitForReadyRead();
        sock.disconnectFromServer();
    }
}
uint PikiHelper::GetScreenCount()
{
    QString sessionDesktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP");
    switch (supportedSessions.indexOf(sessionDesktop)) {
    case 1:
        return GetScreenCountHyprland();
    default:
        return 0; // 0 is the default for unknown number of screens/missing implementation for such method
    }
}
uint PikiHelper::GetScreenCountHyprland()
{
    return GetScreensHyprland().count();
}
QJsonArray PikiHelper::GetScreensHyprland()
{
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR"), his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE"),
            socketPath = runtimeDir + "/hypr/" + his + "/.socket.sock";
    QLocalSocket sock;
    sock.connectToServer(socketPath);
    if (!sock.waitForConnected())
        return QJsonArray();

    sock.write(QString("-j/monitors\n").toUtf8());
    sock.flush();
    sock.waitForReadyRead();
    QJsonArray arr = QJsonDocument::fromJson(sock.readAll()).array();
    sock.disconnectFromServer();
    return arr;
}
