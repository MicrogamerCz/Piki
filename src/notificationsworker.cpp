#include "notificationsworker.h"
#include <KLocalization>
#include <KNotification>
#include <QCoroTask>
#include <QTimer>

NotificationsWorker::NotificationsWorker(QObject *parent)
    : QObject(parent)
    , m_client(nullptr)
    , timer()
    , unreadCount(0)
{
    timer.setInterval(interval);
    connect(&timer, &QTimer::timeout, this, &NotificationsWorker::checkNotifications);
}

void NotificationsWorker::start()
{
    if (!m_client)
        return;

    timer.start();
    listNotifications();
}

KNotification *NotificationsWorker::getNotification(const Notification *piqiNotif) const
{
    if (!piqiNotif->m_viewMore)
        return getGenericNotification();

    if (piqiNotif->m_viewMore->m_title == "Likes")
        return getLikedNotification();
    if (piqiNotif->m_viewMore->m_title == "Someone followed you")
        return getFollowedNotification();

    KNotification *genericNotif = getGenericNotification();
    QString message = QStringLiteral("<b>%1</b>: '%2'").arg(piqiNotif->m_viewMore->m_title).arg(piqiNotif->m_content->m_text);
    genericNotif->setText(message);

    return genericNotif;
}

void NotificationsWorker::checkNotifications()
{
    if (!m_client)
        return;

    QCoro::Task<bool> task = m_client->checkUnreadNotificationsTask();
    QCoro::connect(std::move(task), this, [&](bool hasUnreadNotifications) { // ? mem leak?
        if (hasUnreadNotifications)
            listNotifications();
    });
}

void NotificationsWorker::listNotifications()
{
    QCoro::Task<PiqiResponse *> task = m_client->notificationsListTask();
    QCoro::connect(std::move(task), this, &NotificationsWorker::finishListNotifications);
}
void NotificationsWorker::finishListNotifications(PiqiResponse *response)
{
    if (!response->isSuccessful())
        return; // TODO: add error signal

    unreadCount = 0;

    piqiNotifications = response->data().value<Notifications *>();
    for (Notification *notif : piqiNotifications->m_notifications) {
        if (notif->m_isRead)
            continue;

        unreadCount++;

        KNotification *knotif = getNotification(notif);
        const char *title = notif->m_viewMore ? notif->m_viewMore->m_title.toUtf8().constData() : "Notification";
        knotif->setTitle(i18n(title));
        if (knotif->text().isEmpty())
            knotif->setText(notif->m_content->m_text);

        knotif->sendEvent();
    }

    Q_EMIT unreadNotificationsChanged();
    Q_EMIT notificationsListChanged();
}

KNotification *NotificationsWorker::getLikedNotification() const
{
    KNotification *notification = new KNotification("liked");
    notification->setIconName("love");
    return notification;
}

KNotification *NotificationsWorker::getFollowedNotification() const
{
    KNotification *notification = new KNotification("followed");
    notification->setIconName("actor");
    return notification;
}

KNotification *NotificationsWorker::getGenericNotification() const
{
    KNotification *notification = new KNotification("other");
    notification->setIconName("notification-active");
    return notification;
}

int NotificationsWorker::unreadNotifications() const
{
    return unreadCount;
}
Notifications *NotificationsWorker::notificationsList() const
{
    return piqiNotifications;
}
