import QtQuick 2.0;
import Sailfish.Silica 1.0;
import "../components";

Page {
    id: page;
    allowedOrientations: (currentStationItem ? Orientation.Portrait : Orientation.Portrait | Orientation.Landscape);

    PageHeader {
        id: header;
        title: qsTr ("Stations map");
    }
    Connections {
        target: rootItem;
        onCenterViewOnPosRequested: {
            osm.isZoomed = true;
            osm.centerOnCoord (lat, lon);
            osm.refreshTiles ();
        }
        onGlobalViewRequested: {
            osm.isZoomed = false;
            osm.refreshTiles ();
        }
    }
    OpenStreetMapView {
        id: osm;
        latMin: minLatitude;
        latMax: maxLatitude;
        lonMin: minLongitude;
        lonMax: maxLongitude;
        markerModel: (initialized ? BikesModel.sourceModel : 0);
        markerDelegate: Item {
            id: marker;
            z: (isCurrent ? 99999 : 999);
            Component.onCompleted: {
                var pos = osm.coord2pos (model ['latitude'], model ['longitude']);
                x = pos.x;
                y = pos.y;
            }

            property real pulseEffect : 1.0;
            property bool isCurrent   : (model ['number'] === currentStationIdx);

            MouseArea {
                width: (Theme.itemSizeSmall / 2);
                height: width;
                enabled: !marker.isCurrent;
                anchors.centerIn: parent;
                onClicked: { currentStationItem = BikesModel.getByUid (model ['number']); }
            }
            Rectangle {
                id: circle;
                width: 12;
                height: 12;
                radius: 6;
                color: "transparent";
                antialiasing: true;
                transformOrigin: Item.Center;
                scale: marker.pulseEffect;
                border {
                    width: 2;
                    color: (marker.isCurrent ? "blue" : "red");
                }
                anchors.centerIn: parent;
            }
        }
        anchors {
            fill: parent;
            topMargin: header.height;
            bottomMargin: panelBottom.visibleSize;
        }

        NumberAnimation {
            targets: osm.markerContainer.children;
            properties: "pulseEffect";
            from: 0.5;
            to: 1.5;
            duration: 1250;
            running: rootItem.applicationActive;
            loops: Animation.Infinite;
        }
        //VerticalScrollDecorator   {}
        //HorizontalScrollDecorator {}
    }
    DockedPanel {
        id: panelBottom;
        height: (layout.height + layout.anchors.margins * 2);
        open: (currentStationItem !== null);
        dock: Dock.Bottom;
        anchors {
            left: parent.left;
            right: parent.right;
        }

        Column {
            id: layout;
            spacing: Theme.paddingSmall;
            anchors {
                top: parent.top;
                left: parent.left;
                right: parent.right;
                margins: Theme.paddingLarge;
            }

            Label {
                text: (currentStationItem ? currentStationItem ['name'] : "");
                color: Theme.highlightColor;
                visible: (text !== "");
                wrapMode: Text.NoWrap;
                fontSizeMode: Text.HorizontalFit;
                font.pixelSize: Theme.fontSizeSmall;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
            Label {
                text: (currentStationItem ? currentStationItem ['address'] : "");
                color: Theme.secondaryHighlightColor;
                visible: (text !== "");
                wrapMode: Text.WordWrap;
                font.pixelSize: Theme.fontSizeExtraSmall;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
            Row {
                spacing: Theme.paddingLarge;
                anchors.horizontalCenter: parent.horizontalCenter;

                property real itemHeight : Theme.itemSizeMedium;

                Column {
                    anchors.verticalCenter: parent.verticalCenter;

                    property int bikeCount : (currentStationItem ? currentStationItem ['bikes'] : 0);

                    Label {
                        text: parent.bikeCount;
                        color: Theme.primaryColor;
                        font.pixelSize: Theme.fontSizeLarge;
                        anchors.horizontalCenter: parent.horizontalCenter;
                    }
                    Label {
                        text: (parent.bikeCount > 1 ? qsTr ("Bikes") : qsTr ("Bike"));
                        color: Theme.highlightColor;
                        font.pixelSize: Theme.fontSizeTiny;
                        anchors.horizontalCenter: parent.horizontalCenter;
                    }
                }
                Image {
                    width: height;
                    height: parent.itemHeight;
                    source: "../data/bike.png";
                    sourceSize.width: width;
                    sourceSize.height: height;
                    antialiasing: true;
                }
                Rectangle {
                    width: 1;
                    height: parent.itemHeight;
                    color: Theme.secondaryHighlightColor;
                }
                Image {
                    width: height;
                    height: parent.itemHeight;
                    source: "../data/slot.png";
                    sourceSize.width: width;
                    sourceSize.height: height;
                    antialiasing: true;
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter;

                    property int freeCount : (currentStationItem ? currentStationItem ['free'] : 0);

                    Label {
                        text: parent.freeCount;
                        color: Theme.primaryColor;
                        font.pixelSize: Theme.fontSizeLarge;
                        anchors.horizontalCenter: parent.horizontalCenter;
                    }
                    Label {
                        text: (parent.freeCount > 1 ? qsTr ("Slots") : qsTr ("Slot"));
                        color: Theme.highlightColor;
                        font.pixelSize: Theme.fontSizeTiny;
                        anchors.horizontalCenter: parent.horizontalCenter;
                    }
                }
            }
            Label {
                text: (currentStationItem
                       ? qsTr ("Last update : ") + formatter.formatDate (new Date (currentStationItem ['updated']), Formatter.TimepointRelative)
                       : "");
                visible: (text !== "");
                color: Theme.secondaryColor;
                font.italic: true;
                font.pixelSize: Theme.fontSizeTiny;
                horizontalAlignment: Text.AlignHCenter;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
        }
    }
}
