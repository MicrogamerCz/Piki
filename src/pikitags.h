#pragma once
#include "piqi/tags.h"
#include <qtmetamacros.h>

class PikiTags : public Tags
{
    Q_OBJECT
    QML_ELEMENT

public:
    PikiTags(QObject *parent = nullptr);

public Q_SLOTS:
    void append(Tag *tag);
    void remove(int index);
    void clear();

Q_SIGNALS:
    void added();
    void removed();
};

class PikiBookmarkTags : public Tags
{
    Q_OBJECT
    QML_ELEMENT

public:
    PikiBookmarkTags(QObject *parent = nullptr);
};
