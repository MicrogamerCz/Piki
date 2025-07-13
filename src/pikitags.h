#pragma once
#include "piqi/tags.h"
#include <piqi/tag.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>

class PikiTags : public Tags
{
    Q_OBJECT
    QML_ELEMENT

public:
    PikiTags(QObject *parent = nullptr)
        : Tags(parent)
    {
        beginResetModel();
        BookmarkTag *allTag = new BookmarkTag;
        allTag->m_name = "All";
        m_tags.append(allTag);
        BookmarkTag *uncategorizedTag = new BookmarkTag;
        uncategorizedTag->m_name = "Uncategorized";
        m_tags.append(uncategorizedTag);
        endResetModel();
    }
};
