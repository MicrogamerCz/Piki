// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

#include <QtGlobal>
#include <qqml.h>
#ifdef Q_OS_ANDROID
#include <QGuiApplication>
#else
#include <QApplication>
#endif

#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QUrl>

#include "version-piki.h"
#include <KAboutData>
#include <KLocalizedContext>
#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include "pikiconfig.h"
#include "pixivnamfactory.h"

using namespace Qt::Literals::StringLiterals;

#ifdef Q_OS_ANDROID
Q_DECL_EXPORT
#endif
int main(int argc, char *argv[])
{
#ifdef Q_OS_ANDROID
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle(QStringLiteral("org.kde.breeze"));
#else
    QApplication app(argc, argv);

    // Default to org.kde.desktop style unless the user forces another style
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }
#endif

#ifdef Q_OS_WINDOWS
    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
        freopen("CONOUT$", "w", stdout);
        freopen("CONOUT$", "w", stderr);
    }

    QApplication::setStyle(QStringLiteral("breeze"));
    auto font = app.font();
    font.setPointSize(10);
    app.setFont(font);
#endif

    KLocalizedString::setApplicationDomain("piki");
    // QCoreApplication::setOrganizationName(u"io.github.micro"_s);

    KAboutData aboutData(
        // The program name used internally.
        u"piki"_s,
        // A displayable program name string.
        i18nc("@title", "Piki"),
        // The program version string.
        QStringLiteral(PIKI_VERSION_STRING),
        // Short description of what the app does.
        i18n("Application Description"),
        // The license this code is released under.
        KAboutLicense::GPL,
        // Copyright Statement.
        i18n("(c) 2025"));
    aboutData.addAuthor(i18nc("@info:credit", "Micro"),
                        i18nc("@info:credit", "Maintainer"),
                        u"microgamercz@proton.me"_s);
                        // u"https://yourwebsite.com"_s);
    // aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    KAboutData::setApplicationData(aboutData);
    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"io.github.microgamercz.piki"_s));
    // QGuiApplication::setWindowIcon(QIcon("io/github/micro/piki/contents/assets/io.github.micro.piki.svg"));

    PikiConfig* config = PikiConfig::self();
    qmlRegisterSingletonInstance("io.github.micro.piki", 1, 0, "Config", config);

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);
    // engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    PixivNAMFactory *nam = new PixivNAMFactory;
    nam->cfg = config;
    engine.setNetworkAccessManagerFactory(nam);
    engine.loadFromModule("io.github.micro.piki", u"Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
