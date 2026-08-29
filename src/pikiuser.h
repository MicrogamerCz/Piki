// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Micro <microgamercz@proton.me>

#pragma once
#include <piqi/User>

class PikiUser : public User
{
    Q_OBJECT
    QML_ELEMENT

    QM_PROPERTY(bool, isPrimary)
    Q_PROPERTY(QString pfp READ getPfp WRITE setPfp NOTIFY profilePictureChanged)

    QString getPfp() const
    {
        return m_profileImageUrls->m_px50;
    }
    void setPfp(const QString &pfp)
    {
        m_profileImageUrls->m_px50 = pfp;
        Q_EMIT profilePictureChanged();
    }

public:
    PikiUser(QObject *parent = nullptr)
        : User(parent)
    {
        m_profileImageUrls = new ImageUrls(this);
    }
    Q_INVOKABLE PikiUser(QJsonObject data, QObject *parent = nullptr)
        : User(parent, data)
    {
    }

    Q_SIGNAL void profilePictureChanged();
};
