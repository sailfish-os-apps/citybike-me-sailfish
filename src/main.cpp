
#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QQuickView>
#include <QQmlContext>
#include <QQmlEngine>
#include <QGuiApplication>
#include <QTimer>
#include <qqml.h>

#include <sailfishapp.h>

#include "MyBikesModel.h"
#include "MyTileProvider.h"

int main (int argc, char * argv []){
    qmlRegisterType<MyTileHelper>("harbour.citybikeme.myTileProvider", 1, 0, "TileHelper");
    qmlRegisterType<QTimer>      ("harbour.citybikeme.myQtCoreImports", 5, 1, "PreciseTimer");
    qmlRegisterUncreatableType<QAbstractItemModel>  ("harbour.citybikeme.myQtCoreImports", 5, 1, "AbstractItemModel", "");
    qmlRegisterUncreatableType<QAbstractProxyModel> ("harbour.citybikeme.myQtCoreImports", 5, 1, "AbstractProxyMode", "");
    QGuiApplication * app = SailfishApp::application (argc, argv);
    app->setApplicationName ("CityBikeMe");
    app->setOrganizationName ("TheBootroo");
    QQuickView * view = SailfishApp::createView ();
    view->rootContext ()->setContextProperty ("BikesModel", new MyBikesProxyFilter (view));
    view->setSource (QUrl ("qrc:/qml/harbour-citybikeme.qml"));
    view->show ();
    return app->exec();
}

