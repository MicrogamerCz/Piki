# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

qt_standard_project_setup(REQUIRES 6.9)

qt_add_library(piki_st STATIC)
ecm_add_qml_module(piki_st
    GENERATE_PLUGIN_SOURCE
    URI io.github.micro.piki
    VERSION 0.1
    QML_FILES
        contents/ui/Main.qml
        contents/ui/Loading.qml
        contents/ui/Login.qml
        contents/ui/Home.qml
        contents/ui/Settings.qml
        contents/ui/Following.qml
        contents/ui/IllustView.qml
        contents/ui/Search.qml
        contents/ui/Newest.qml
        contents/ui/Collection.qml
        contents/ui/History.qml
        contents/ui/Welcome.qml
        contents/ui/ProfileView.qml

        contents/controls/Header.qml
        contents/controls/Sidebar.qml
        contents/controls/SidebarButton.qml
        contents/controls/SelectionButtons.qml
        contents/controls/IllustrationButton.qml
        contents/controls/PixivImage.qml
        contents/controls/AccountButton.qml
        contents/controls/IllustDetails.qml
        contents/controls/CommentCard.qml
        contents/controls/CommentSection.qml
        contents/controls/TagChip.qml
        contents/controls/PremiumBanner.qml
        contents/controls/AccountsManager.qml
        contents/controls/RequestsCard.qml
        contents/controls/FlatAction.qml
        contents/controls/XWorkAsWallpaperOptions.qml
        contents/controls/WallpaperSelections.qml
        contents/controls/WebAction.qml
        contents/controls/templates/DoubleAbstractCard.qml
        contents/controls/templates/FeedPage.qml
    SOURCES
        imagedownloader.cpp
        loginprocessor.cpp
        loginhandler.cpp
        pikicache.cpp
        pikihelper.cpp
        pikitags.h
    # RESOURCE_PREFIX /
    RESOURCES
        contents/assets/io.github.micro.piki.svg
        contents/assets/ranking.svg
        contents/assets/pixiv_no_profile.png
        contents/assets/pixivLogo2025.svg
        contents/assets/favorites-symbolic.svg
        contents/assets/folder-paint-symbolic.svg
        contents/assets/premium_1.svg
        contents/assets/premium_2.svg
    OUTPUT_DIRECTORY
        "${CMAKE_BINARY_DIR}/io/github/micro/piki"
)
target_compile_options (piki_st PUBLIC -fexceptions)

target_link_libraries(piki_st PUBLIC
    Qt6::QuickControls2
    Qt6::WebEngineQuick
    KF6::I18n
    KF6::ConfigGui
    KF6::Wallet
    KF6::Purpose
    FutureSQL6::FutureSQL
    Piqi::piqi
    # The following dependencies might not be necessary:
    Qt6::Gui
    Qt6::Quick
    Qt6::Svg
    KF6::KirigamiPlatform
    KF6::CoreAddons
    KF6::ConfigCore
)
target_include_directories(piki_st PUBLIC ${CMAKE_BINARY_DIR})

if (ANDROID)
    kirigami_package_breeze_icons(ICONS
        list-add
        help-about
        application-exit
        applications-graphics
    )
else()
    target_link_libraries(piki_st PUBLIC Qt::Widgets)
endif()

kconfig_add_kcfg_files(piki_st GENERATE_MOC pikiconfig.kcfgc)


add_executable(piki
    pixivnamfactory.h
    main.cpp
)
target_link_libraries(piki PUBLIC piki_st piki_stplugin)

install(TARGETS piki ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
