// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikihelper.h"
#include <QCoro>
#include <QLocalSocket>
#include <QNetworkReply>
#include <QtDBus>
#include <libportal/wallpaper.h>

XdpPortal *PikiHelper::portal = nullptr;

PikiHelper::PikiHelper(QObject *parent)
    : QObject(parent)
{
    if (portal)
        return;

    GError *error = nullptr;
    portal = xdp_portal_initable_new(&error);
    portalPresent = portal;
    Q_EMIT supportedWallpaperSessionChanged();

    if (error)
        qDebug() << "Error when initializing portal: " << error->message;
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

    QString cachePath = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QString wallpapersPath = cachePath + "/wallpapers/";
    QString path = wallpapersPath + url.mid(url.lastIndexOf("/") + 1);
    QFile file(path);

    QDir wallpapersDir(wallpapersPath);
    if (!wallpapersDir.exists())
        wallpapersDir.mkpath(wallpapersPath);

    if (!file.exists()) {
        QNetworkRequest request((QUrl(url)));
        request.setRawHeader("Referer", "https://app-api.pixiv.net/");
        QNetworkReply *reply = co_await manager.get(request);
        QByteArray data = reply->readAll();

        if (!file.open(QIODevice::WriteOnly)) {
            qDebug() << "Failed to open file (" << path << ") for write: " << file.errorString();
            co_return;
        }

        file.write(data);
        file.close();
    }

    // Custom backends should be added only for DEs without Wallpaper portal
    QString sessionDesktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP");
    switch (explicitlySupportedSessions.indexOf(sessionDesktop)) {
    case -1: {
        if (!portal)
            break; // TODO: notify that portal is not installed and custom backend is not implemented
        xdp_portal_set_wallpaper(portal, nullptr, path.toStdString().c_str(), XDP_WALLPAPER_FLAG_BACKGROUND, nullptr, &PikiHelper::setWallpaperPortal, nullptr);
        break;
    }
    case 0: {
        SetWallpaperHyprpaper(path, screen);
        break;
    }
    }
}
void PikiHelper::setWallpaperPortal(GObject *source_object, GAsyncResult *res, gpointer data)
{
    xdp_portal_set_wallpaper_finish(portal, res, nullptr);
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
    switch (explicitlySupportedSessions.indexOf(sessionDesktop)) {
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

bool PikiHelper::getIsPortalSupported() const
{
    return explicitlySupportedSessions.contains(qEnvironmentVariable("XDG_CURRENT_DESKTOP")) || portalPresent;
}
