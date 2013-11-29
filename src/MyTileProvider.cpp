
#include "MyTileProvider.h"

#include <QDebug>

// uri = zoom/col/row

/********************* CONSTRUCTORS *****************************/

MyTileCache * MyTileCache::s_instance = NULL;

MyTileCache * MyTileCache::getInstance () {
    if (s_instance == NULL) {
        s_instance = new MyTileCache;
    }
    return s_instance;
}

MyTileCache::MyTileCache () {
    m_thread = new QThread (this);
    m_worker = new  MyTileLoadWorker ();
    m_worker->moveToThread (m_thread);
    connect (this, &MyTileCache::tileRequested, m_worker, &MyTileLoadWorker::loadTile);
    connect (m_worker, &MyTileLoadWorker::tileLoaded, this, &MyTileCache::onTileReady);
    m_thread->start (QThread::HighPriority);
}

MyTileLoadWorker::MyTileLoadWorker (QObject * parent) : QObject (parent) {
    m_cacheDir = QStandardPaths::writableLocation (QStandardPaths::CacheLocation).append ("/OSM_Tiles");
    QDir dir;
    dir.mkpath (m_cacheDir);
    m_nam = new QNetworkAccessManager (this);
    connect (m_nam, &QNetworkAccessManager::finished, this, &MyTileLoadWorker::onRequestFinished);
    m_timer = new QTimer (this);
    m_timer->setInterval (5);
    m_timer->setTimerType (Qt::CoarseTimer);
    m_timer->setSingleShot (true);
    connect (m_timer, &QTimer::timeout, this, &MyTileLoadWorker::doProcessNext);
    m_timer->start ();
}

MyTileHelper::MyTileHelper (QObject * parent) : QObject (parent) {
    connect (MyTileCache::getInstance (), &MyTileCache::tileReady, this, &MyTileHelper::onCacheTileReady);
}

void MyTileHelper::setUri (QString uri) {
    if (m_uri != uri) {
        m_uri = uri;
        if (!m_uri.isEmpty ()) {
            setFile (MyTileCache::getInstance ()->getFileForUri (m_uri));
            if (getFile ().isEmpty ()) {
                MyTileCache::getInstance ()->tileRequested (m_uri);
            }
        }
        else {
            setFile ("");
        }
        emit uriChanged (uri);
    }
}
void MyTileHelper::setFile (QString file) {
    if (m_file != file) {
        m_file = file;
        emit fileChanged (file);
    }
}

void MyTileHelper::onCacheTileReady (QString uri, QString file) {
    if (m_uri == uri) {
        setFile (file);
    }
}

void MyTileCache::onTileReady (QString uri, QString file) {
    m_index.insert (uri, file);
    emit tileReady (uri, file);
}

/**************************** API ********************************/

QString MyTileCache::getFileForUri (QString uri) const {
    return m_index.value (uri);
}

void MyTileLoadWorker::loadTile (QString uri) {
    m_timer->stop   ();
    m_mutex.lock    ();
    if (!m_queue.contains (uri)) {
        m_queue.enqueue (uri);
    }
    m_mutex.unlock  ();
    m_timer->start  ();
}

void MyTileLoadWorker::onRequestFinished (QNetworkReply * reply) {
    //qDebug () << "MyTileLoadWorker::onRequestFinished" << reply;
    if (reply->error () == QNetworkReply::NoError) {
        QString uri = reply->property ("uri").toString ();
        QStringList tokens = uri.split ('/');
        QDir dir (m_cacheDir);
        dir.mkpath (tokens.at (0));
        dir.cd (tokens.at (0));
        dir.mkpath (tokens.at (1));
        dir.cd (tokens.at (1));
        QFile file (QString ("%1/%2.png").arg (m_cacheDir).arg (uri));
        QString out = QUrl::fromLocalFile (file.fileName ()).toString ();
        file.open (QIODevice::WriteOnly);
        if (file.isOpen () && file.isWritable ()) {
            file.write (reply->readAll ());
            file.flush ();
            file.close ();
            emit tileLoaded (uri, out);
        }
        //qDebug () << ">>> file :" << out;
    }
    else {
        qWarning () << ">>> reply error :" << reply->errorString ();
    }
    m_timer->start ();
}

void MyTileLoadWorker::doLoading (QString uri) {
    //qDebug () << "MyTileLoadWorker::doLoading" << uri;
    QFile file (QString ("%1/%2.png").arg (m_cacheDir).arg (uri));
    if (!file.exists ()) {
        QNetworkReply * reply = m_nam->get (QNetworkRequest (QUrl (QString ("http://tile.openstreetmap.org/%1.png").arg (uri))));
        reply->setProperty ("uri", uri);
    }
    else {
        QString out = QUrl::fromLocalFile (file.fileName ()).toString ();
        emit tileLoaded (uri, out);
        m_timer->start ();
    }
}

void MyTileLoadWorker::doProcessNext () {
    //qDebug () << "MyTileLoadWorker::doProcessNext";
    if (!m_queue.isEmpty ()) {
        m_mutex.lock ();
        QString uri = m_queue.dequeue ();
        m_mutex.unlock ();
        doLoading (uri);
    }
}
