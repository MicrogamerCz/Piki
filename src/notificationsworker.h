#pragma once

#include <KNotification>
#include <QTimer>
#include <piqi/Notifications>
#include <piqi/Piqi>

class NotificationsWorker : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QM_PROPERTY(Piqi *, client)
    Q_PROPERTY(int unreadNotifications READ unreadNotifications NOTIFY unreadNotificationsChanged)
    Q_PROPERTY(Notifications *notificationsList READ notificationsList NOTIFY notificationsListChanged)

public:
    NotificationsWorker(QObject *parent = nullptr);

    Q_INVOKABLE void start();

private:
    static constexpr int interval = 600000; // 10 minutes
    QTimer timer;
    int unreadCount;
    Notifications *piqiNotifications;

    KNotification *getNotification(const Notification *piqiNotif) const;
    void checkNotifications();
    void listNotifications();
    void finishListNotifications(PiqiResponse *response);

    KNotification *getLikedNotification() const;
    KNotification *getFollowedNotification() const;
    KNotification *getGenericNotification() const;

    int unreadNotifications() const;
    Notifications *notificationsList() const;

    Q_SIGNAL void unreadNotificationsChanged();
    Q_SIGNAL void notificationsListChanged();
};
