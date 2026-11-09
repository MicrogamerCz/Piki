#include <QObject>
#include <piqi/QEPR>
#include <qqmlintegration.h>
#include <qregularexpression.h>
#include <qtmetamacros.h>

class NovelProcessor : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QM_PROPERTY(QString, title)
    QM_PROPERTY(QString, coverImageUrl)
    QM_PROPERTY(QString, text)

public:
    NovelProcessor(QObject *parent = nullptr);

    Q_INVOKABLE QString loadNovel(const QString &htmlString);

private:
    const QRegularExpression htmlRegex =
        QRegularExpression("<script>\\s*(.*)\\s*<\\/script>", QRegularExpression::DotMatchesEverythingOption | QRegularExpression::InvertedGreedinessOption);
    const QRegularExpression jsObjectRegex = QRegularExpression("({(?>[^{}]|(?R))*})", QRegularExpression::DotMatchesEverythingOption);
    const QRegularExpression jsonKeyRegex = // ! needs to glob replace with '"$1": '
        QRegularExpression("(\\w+):\\s", QRegularExpression::DotMatchesEverythingOption | QRegularExpression::InvertedGreedinessOption);
    const QRegularExpression jsonCommaRegex = // ! needs to glob replace with '$1}'
        QRegularExpression(",(|\\s+)}", QRegularExpression::DotMatchesEverythingOption | QRegularExpression::InvertedGreedinessOption);
};
