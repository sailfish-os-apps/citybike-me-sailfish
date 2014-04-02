
################## CONFIG ########################

TARGET       = harbour-citybikeme
TEMPLATE     = app
QT          += core network gui qml quick
INCLUDEPATH += /usr/include/sailfishapp

############### SOURCES & CONTENT #####################

SOURCES     += \
    src/main.cpp \
    src/MyBikesModel.cpp \
    src/MyTileProvider.cpp

HEADERS     += \
    src/MyTileProvider.h \
    src/MyBikesModel.h

OTHER_FILES += \
    harbour-citybikeme.desktop \
    harbour-citybikeme.png \
    harbour-citybikeme.svg \
    rpm/harbour-citybikeme.yaml \
    qml/Ajax.js \
    qml/harbour-citybikeme.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/SecondPage.qml \
    qml/components/OpenStreetMapView.qml \
    qml/data/bike.png \
    qml/data/slot.png \
    qml/data/bike.svg \
    qml/data/slot.svg \
    qml/components/ScrollDimmer.qml

RESOURCES   += \
    data.qrc

################## PACKAGING ########################

CONFIG       += link_pkgconfig
PKGCONFIG    += sailfishapp

target.files  = $${TARGET}
target.path   = /usr/bin
desktop.files = $${TARGET}.desktop
desktop.path  = /usr/share/applications
icon.files    = $${TARGET}.png
icon.path     = /usr/share/icons/hicolor/86x86/apps
INSTALLS     += target desktop icon
