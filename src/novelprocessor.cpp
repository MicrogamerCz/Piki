#include "novelprocessor.h"
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qregularexpression.h>

NovelProcessor::NovelProcessor(QObject *parent)
    : QObject(parent)
{
}

QString NovelProcessor::loadNovel(const QString &htmlString)
{
    QRegularExpressionMatch htmlMatch = htmlRegex.match(htmlString);
    if (!htmlMatch.hasMatch())
        return {};

    QString htmlCaptured = htmlMatch.captured(0);
    QRegularExpressionMatch jsObjectMatch = jsObjectRegex.match(htmlCaptured);
    if (!jsObjectMatch.hasMatch())
        return {};

    QString jsObjectCaptured = jsObjectMatch.captured(1);
    QString jsonString = jsObjectCaptured.replace(jsonKeyRegex, "\"\\1\": ");
    jsonString = jsonString.replace(jsonCommaRegex, "\\1}");

    QJsonDocument novelData = QJsonDocument::fromJson(jsonString.toUtf8());
    if (novelData.isNull())
        return {};

    QJsonObject novelObject = novelData.object()["value"].toObject()["novel"].toObject();
    m_title = novelObject["title"].toString();
    m_coverImageUrl = novelObject["coverUrl"].toString();
    m_text = novelObject["text"].toString();
    Q_EMIT titleChanged();
    Q_EMIT coverImageUrlChanged();
    Q_EMIT textChanged();

    return jsonString;
}
