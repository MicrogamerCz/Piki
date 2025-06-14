// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include "pikihelper.h"
#include "illustration.h"
#include "pikiconfig.h"
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
#include <qlocalsocket.h>
#include <qlogging.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
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
QCoro::QmlTask PikiHelper::SetWallpaper(Illustration *illust)
{
    return SetWallpaperTask(illust);
}
QCoro::Task<> PikiHelper::SetWallpaperTask(Illustration *illust)
{
    QString url;
    if (illust->m_pageCount > 1)
        url = illust->m_metaPages[0]->m_original;
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
    // Unix socket, as long as the wallpaper is passed as a path and not the data
    const QStringList supportedSessions{"KDE", "Hyprland"};
    QString sessionDesktop = qEnvironmentVariable("XDG_CURRENT_DESKTOP");
    switch (supportedSessions.indexOf(sessionDesktop)) {
    case 0: {
        // Using: https://invent.kde.org/plasma/plasma-workspace/-/blob/master/shell/tests/setwallpapertest.cpp
        // SPDX-FileCopyrightText: 2022 Méven Car <meven@kde.org>
        // SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL

        QDBusInterface *interface = new QDBusInterface("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", QDBusConnection::sessionBus(), this);
        if (!interface->isValid())
            co_return;

        QVariantMap params{{"Image", path}};
        QDBusReply<void> response = co_await interface->asyncCall("setWallpaper", "org.kde.image", params, uint(0));
        break;
    }
    case 1: {
        QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR"), his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE"),
                socketPath = runtimeDir + "/hypr/" + his + "/.hyprpaper.sock";
        QLocalSocket sock;
        sock.connectToServer(socketPath);
        if (sock.waitForConnected()) {
            sock.write(("preload " + path + "\n").toUtf8());
            sock.flush();
            sock.waitForReadyRead();
            sock.write(("wallpaper eDP-1," + path + "\n").toUtf8());
            sock.flush();
            sock.waitForReadyRead();
            sock.disconnectFromServer();
        }
        break;
    }
    }
}
void PikiHelper::ShareToClipboard(Illustration *illust)
{
    QClipboard *cbd = QApplication::clipboard();
    cbd->setText("https://pixiv.net/artworks/" + QString::number(illust->m_id));
}
