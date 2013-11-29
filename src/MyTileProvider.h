#ifndef MYTILEPROVIDER_H
#define MYTILEPROVIDER_H

#include <QQuickImageProvider>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkProxy>
#include <QPixmap>
#include <QImage>
#include <QEventLoop>
#include <QImageReader>
#include <QCoreApplication>
#include <QSemaphore>
#include <QMutex>
#include <QMutexLocker>
#include <QThread>
#include <QQueue>
#include <QTimer>
#include <QStandardPaths>
#include <QFile>
#include <QDir>

class MyTileLoadWorker : public QObject {
    Q_OBJECT

public:
    explicit MyTileLoadWorker (QObject * parent = NULL);

public slots:
    void loadTile (QString uri);

signals:
    void tileLoaded (QString uri, QString file);

protected slots:
    void doLoading     (QString uri);
    void doProcessNext ();

private slots:
    void onRequestFinished (QNetworkReply * reply);

private:
    QString                 m_cacheDir;
    QMutex                  m_mutex;
    QTimer                * m_timer;
    QQueue<QString>         m_queue;
    QNetworkAccessManager * m_nam;
};

class MyTileHelper : public QObject {
    Q_OBJECT
    Q_PROPERTY (QString uri  READ getUri  WRITE setUri  NOTIFY uriChanged)
    Q_PROPERTY (QString file READ getFile WRITE setFile NOTIFY fileChanged)

public:
    explicit MyTileHelper (QObject * parent = NULL);

    QString getUri  () const { return m_uri;  }
    QString getFile () const { return m_file; }

public slots:
    void setUri  (QString uri);
    void setFile (QString file);

signals:
    void uriChanged  (QString uri);
    void fileChanged (QString file);

protected slots:
    void onCacheTileReady (QString uri, QString file);

private:
    QString m_uri;
    QString m_file;
};

class MyTileCache : public QObject {
    Q_OBJECT

public:
    static MyTileCache * getInstance ();

    QString getFileForUri (QString uri) const;

signals:
    void tileRequested (QString uri);
    void tileReady     (QString uri, QString file);

protected slots:
    void onTileReady   (QString uri, QString file);

protected:
    explicit MyTileCache ();

private:
    QThread                     * m_thread;
    MyTileLoadWorker            * m_worker;
    QHash<QString, QString>       m_index;

    static MyTileCache          * s_instance;
};

#endif // MYTILEPROVIDER_H
