#include "pikitags.h"
#include <algorithm>
#include <functional>

PikiTags::PikiTags(QObject *parent)
    : Tags(parent)
{
}
void PikiTags::append(Tag *tag)
{
    if (!tag)
        return;

    tag->setParent(this);

    int count = m_tags.size();
    beginInsertRows({}, count, count);
    m_tags.append(tag);
    endInsertRows();

    Q_EMIT added();
}
void PikiTags::remove(int index)
{
    if (index < 0 || index >= m_tags.size())
        return;

    beginRemoveRows({}, index, index + 1);
    m_tags[index]->deleteLater();
    m_tags.removeAt(index);
    endRemoveRows();

    Q_EMIT removed();
}
void PikiTags::clear()
{
    beginRemoveRows({}, 0, m_tags.size());
    std::for_each(m_tags.begin(), m_tags.end(), std::mem_fn(&Tag::deleteLater));
    m_tags.clear();
    endRemoveRows();
}

PikiBookmarkTags::PikiBookmarkTags(QObject *parent)
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
