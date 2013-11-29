#ifndef MYBIKESMODEL_H
#define MYBIKESMODEL_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QColor>
#include <QHash>
#include <QList>
#include <QDateTime>
#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QMetaObject>
#include <QMetaProperty>
#include <QMetaMethod>
#include <QRegularExpression>
#include <QSettings>

#define QML_PUBLIC_PROPERTY(type, name) \
    protected: \
        Q_PROPERTY (type name READ get_##name WRITE set_##name NOTIFY name##Changed) \
    private: \
        type m_##name; \
    public: \
        type get_##name () const { \
            return m_##name ; \
        } \
    public Q_SLOTS: \
        bool set_##name (type name) { \
            bool ret = false; \
            if (m_##name != name) { \
                m_##name = name; \
                ret = true; \
                emit name##Changed (m_##name); \
            } \
            return ret; \
        } \
    Q_SIGNALS: \
        void name##Changed (type name);

class MyBikesItem : public QObject {
    Q_OBJECT
    QML_PUBLIC_PROPERTY (int,       number)
    QML_PUBLIC_PROPERTY (QString,   name)
    QML_PUBLIC_PROPERTY (QString,   address)
    QML_PUBLIC_PROPERTY (qreal,     updated)
    QML_PUBLIC_PROPERTY (QString,   status)
    QML_PUBLIC_PROPERTY (bool,      bonus)
    QML_PUBLIC_PROPERTY (bool,      banking)
    QML_PUBLIC_PROPERTY (int,       slot)
    QML_PUBLIC_PROPERTY (int,       free)
    QML_PUBLIC_PROPERTY (int,       bikes)
    QML_PUBLIC_PROPERTY (qreal,     latitude)
    QML_PUBLIC_PROPERTY (qreal,     longitude)
    QML_PUBLIC_PROPERTY (QString,   sector)

public: explicit MyBikesItem (QObject * parent = NULL);
};

class MyBikesModel : public QAbstractListModel {
    Q_OBJECT

public:
    explicit MyBikesModel (QObject * parent = NULL);

    virtual int rowCount (const QModelIndex & parent) const;
    virtual QVariant data (const QModelIndex & index, int role) const;
    virtual QHash<int, QByteArray> roleNames () const;

    Q_INVOKABLE QObject * getByUid (quint16 uid);

public slots:
    void truncate       ();
    void insertOrUpdate (quint16 uid, QVariantMap values);

private slots:
    void onItemPropertyChanged ();

private:
    QMetaObject                   m_metaObj;
    QList<MyBikesItem *>          m_items;
    QHash<int, QByteArray>        m_roles;
    QHash<quint16, MyBikesItem *> m_index;
};

class MyBikesProxyFilter : public QSortFilterProxyModel {
    Q_OBJECT
    Q_PROPERTY (QString filter READ getFilter WRITE setFilter NOTIFY filterChanged)

public:
    explicit MyBikesProxyFilter (QObject * parent = NULL);

    QString getFilter () const;

    Q_INVOKABLE void truncate ();
    Q_INVOKABLE void insertOrUpdate (quint16 uid, QVariantMap values);
    Q_INVOKABLE QString highlightText (QString text, QString filter, QString highlight);
    Q_INVOKABLE QObject * getByUid (quint16 uid);
    Q_INVOKABLE QString getContractId ();
    Q_INVOKABLE QString getContractName ();
    Q_INVOKABLE QString getContractCountry ();
    Q_INVOKABLE void setContract (QString id, QString name, QString country);

public slots:
    void setFilter(QString arg);

signals:
    void filterChanged(QString arg);

protected:
    virtual bool filterAcceptsRow (int source_row, const QModelIndex & source_parent) const;

private:
    MyBikesModel * m_model;
    QString        m_filter;
    QSettings    * m_settings;
};

#endif // MYBIKESMODEL_H
