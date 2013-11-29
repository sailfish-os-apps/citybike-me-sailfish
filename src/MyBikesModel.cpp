
#include "MyBikesModel.h"

#include <QDebug>

inline QString canonized (QString str) {
    return str
            .trimmed ()
            .toLower ()
            .replace ("  ", " ")
            .replace (QRegularExpression ("[âà]"),   "a")
            .replace (QRegularExpression ("[éèêë]"), "e")
            .replace (QRegularExpression ("[ïî]"),   "i")
            .replace (QRegularExpression ("[öô]"),   "o")
            .replace (QRegularExpression ("[ù]"),    "u")
            .replace (QRegularExpression ("[ç]"),    "c");
}

MyBikesItem::MyBikesItem (QObject * parent) : QObject (parent) { }

MyBikesModel::MyBikesModel (QObject * parent) : QAbstractListModel (parent) {
    m_metaObj = MyBikesItem::staticMetaObject;
    for (int i = 0; i < m_metaObj.propertyCount (); i++) {
        m_roles.insert (i, m_metaObj.property (i).name ());
    }
}

int MyBikesModel::rowCount (const QModelIndex & parent) const {
    Q_UNUSED (parent)
    return m_items.count ();
}

QVariant MyBikesModel::data (const QModelIndex & index, int role) const {
    QVariant ret;
    int row = index.row ();
    if (row >= 0 && row < m_items.count ()) {
        MyBikesItem * item = m_items.at (row);
        if (item != NULL) {
            ret.setValue (item->property (m_roles.value (role)));
        }
    }
    return ret;
}

QHash<int, QByteArray> MyBikesModel::roleNames () const {
    return m_roles;
}

QObject * MyBikesModel::getByUid (quint16 uid) {
    return m_index.value (uid, NULL);
}

void MyBikesModel::truncate () {
    beginResetModel ();
    foreach (MyBikesItem * item, m_items) {
        if (item != NULL) {
            item->disconnect ();
            delete item;
        }
    }
    m_items.clear ();
    m_index.clear ();
    endResetModel ();
}

void MyBikesModel::insertOrUpdate (quint16 uid, QVariantMap values) {
    MyBikesItem * item = m_index.value (uid, NULL);
    if (item == NULL) {
        int row = m_items.count ();
        beginInsertRows (QModelIndex (), row, row);
        item = new MyBikesItem (this);
        for (int i = 0; i < m_metaObj.propertyCount (); i++) {
            QMetaProperty metaProp = m_metaObj.property (i);
            if (metaProp.hasNotifySignal ()) {
                connect (item, QString ("%1%2").arg (QSIGNAL_CODE).arg (QString (metaProp.notifySignal ().methodSignature ())).toLocal8Bit ().constData (),
                         this, SLOT (onItemPropertyChanged ()));
            }
        }
        m_items.append (item);
        m_index.insert (uid, item);
        endInsertRows ();
    }
    foreach (QString key, values.keys ()) {
        item->setProperty (key.toLocal8Bit (), values.value (key));
    }
}

void MyBikesModel::onItemPropertyChanged () {
    QString notifier (m_metaObj.method (senderSignalIndex ()).name ());
    int row = m_items.indexOf (qobject_cast<MyBikesItem *>(sender ()));
    if (row >= 0) {
        QModelIndex idx = index (row, 0, QModelIndex ());
        emit dataChanged (idx, idx, QVector<int> () << m_roles.key (notifier.remove (QRegularExpression ("(Changed)$")).toLocal8Bit ()));
    }
}

MyBikesProxyFilter::MyBikesProxyFilter (QObject * parent) : QSortFilterProxyModel (parent) {
    m_settings = new QSettings (this);
    if (getContractId().isEmpty() && getContractName().isEmpty()) {
        setContract ("Lyon", "Vélov", "FR");
    }
    m_model = new MyBikesModel (this);
    setSourceModel (m_model);
    setDynamicSortFilter (true);
    setSortRole (m_model->roleNames ().key ("number"));
    sort (0, Qt::AscendingOrder);
    setFilterRole (m_model->roleNames ().key ("name"));
}

QString MyBikesProxyFilter::getFilter () const {
    return m_filter;
}

QString MyBikesProxyFilter::highlightText (QString text, QString filter, QString highlight) {
    QString ret = text.trimmed ();
    QString search = canonized (filter);
    if (!search.isEmpty ()) {
        int pos = canonized (ret).indexOf (search);
        QString tagStart = QString ("<font color=\"%1\">").arg (highlight);
        QString tagEnd   = QString ("</font>");
        ret.insert (pos, tagStart);
        ret.insert (pos + tagStart.size() + search.size (), tagEnd);
    }
    return ret;
}

QObject * MyBikesProxyFilter::getByUid (quint16 uid) {
    return m_model->getByUid (uid);
}

QString MyBikesProxyFilter::getContractId () {
    return m_settings->value ("Contract/ID").toString ();
}

QString MyBikesProxyFilter::getContractName () {
    return m_settings->value ("Contract/Name").toString ();
}

QString MyBikesProxyFilter::getContractCountry () {
    return m_settings->value ("Contract/Country").toString ();
}

void MyBikesProxyFilter::setContract (QString id, QString name, QString country) {
    m_settings->setValue ("Contract/ID", id);
    m_settings->setValue ("Contract/Name", name);
    m_settings->setValue ("Contract/Country", country);
}

void MyBikesProxyFilter::truncate () {
    m_model->truncate ();
}

void MyBikesProxyFilter::insertOrUpdate (quint16 uid, QVariantMap values) {
    m_model->insertOrUpdate (uid, values);
}

void MyBikesProxyFilter::setFilter (QString arg) {
    QString filter = canonized (arg);
    if (m_filter != filter) {
        m_filter = filter;
        emit filterChanged (filter);
        invalidateFilter ();
    }
}

bool MyBikesProxyFilter::filterAcceptsRow (int source_row, const QModelIndex & source_parent) const {
    QModelIndex sourceIdx  = m_model->index (source_row, 0, source_parent);
    QString     sourceName = m_model->data (sourceIdx, filterRole ()).toString ();
    return (m_filter.isEmpty () || canonized (sourceName).contains (m_filter));
}
