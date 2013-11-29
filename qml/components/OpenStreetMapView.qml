import QtQuick 2.1;
import harbour.citybikeme.myTileProvider 1.0;

Rectangle {
    id: viewport;
    width: 800;
    height: 600;
    clip: true;
    color: "#2C2C2C";
    onWidthChanged: {
        timerCenter.restart ();
        refreshTiles ();
    }
    onHeightChanged: {
        timerCenter.restart ();
        refreshTiles ();
    }
    onCenterCoordsChanged: {
        if (centerCoords !== Qt.point (0,0)) {
            timerCenter.restart ();
        }
        else {
            timerCenter.stop ();
        }
    }
    onIsZoomedChanged: {
        timerCenter.restart ();
    }

    readonly
    property int     tileSize           : 256;
    readonly
    property string  tileUri            : "%1/%2/%3"; // uri = zoom/column/row

    property bool    isZoomed           : false;

    property real    lonMin             : 0.0;
    property real    lonMax             : 0.0;
    property real    latMin             : 0.0;
    property real    latMax             : 0.0;

    property point   centerCoords       : Qt.point (0,0);

    readonly
    property alias   markerContainer    : container;
    property alias   markerModel        : repeaterMarkers.model;
    property alias   markerDelegate     : repeaterMarkers.delegate;

    function refreshTiles () {
        if (initialized) {
            var view = Qt.rect (-grid.x - tileSize,
                                -grid.y - tileSize,
                                clicker.width + tileSize,
                                clicker.height + tileSize);
            for (var idx = 0; idx < repeater.count; idx++) {
                var item = repeater.itemAt (idx);
                if (Qt.isQtObject (item)) {
                    item.load = (view.x + view.width > item.x &&
                                 view.x < item.x + item.width &&
                                 view.y + view.height > item.y &&
                                 view.y < item.y + item.height);
                }
            }
        }
    }
    function coord2pos (lat, lon) {
        var x = 0;
        var y = 0;
        x = (lon - map.lonLeft) * (map.viewWidth / map.lonDelta);
        lat = (lat * Math.PI / 180);
        var worldMapWidth = (map.viewWidth / map.lonDelta * 360) / (2 * Math.PI);
        var mapOffsetY = (worldMapWidth / 2 * Math.log ((1 + Math.sin (map.latBottomDegree)) / (1 - Math.sin (map.latBottomDegree))));
        y = map.viewHeight - ((worldMapWidth / 2 * Math.log ((1 + Math.sin (lat)) / (1 - Math.sin (lat)))) - mapOffsetY);
        return Qt.point (x, y);
    }
    function centerOnPos (xPos, yPos) {
        if (initialized) {
            var anim = Qt.createQmlObject ('import QtQuick 2.0;' +
                                           '    ParallelAnimation {' +
                                           '    alwaysRunToEnd: true;' +
                                           '    loops: 1;' +
                                           '    running: true;' +
                                           '    onStopped: { destroy (); }' +
                                           '        PropertyAnimation {' +
                                           '            target: grid;' +
                                           '            property: "x";' +
                                           '            to: %1;'.arg (xPos) +
                                           '            duration: 250;' +
                                           '        }' +
                                           '        PropertyAnimation {' +
                                           '            target: grid;' +
                                           '            property: "y";' +
                                           '            to: %1;'.arg (yPos) +
                                           '            duration: 250;' +
                                           '        }' +
                                           '}',
                                           grid,
                                           "centerOn anim");
        }
    }

    QtObject {
        id: preview;

        readonly
        property int  zoomLevel : 14;

        property int  colMin          : lon2x (lonMin, zoomLevel) -1;
        property int  colMax          : lon2x (lonMax, zoomLevel) +1;
        property int  rowMin          : lat2y (latMax, zoomLevel) -1;
        property int  rowMax          : lat2y (latMin, zoomLevel) +1;

        property int  columns         : Math.abs (colMax - colMin);
        property int  rows            : Math.abs (rowMax - rowMin);

        property real viewWidth       : (tileSize * columns);
        property real viewHeight      : (tileSize * rows);

        property real lonLeft         : x2lon (colMin, zoomLevel);
        property real lonRight        : x2lon (colMax, zoomLevel);
        property real latTop          : y2lat (rowMax, zoomLevel);
        property real latBottom       : y2lat (rowMin, zoomLevel);

        property real lonDelta        : (lonRight - lonLeft);
        property real latBottomDegree : (latTop * Math.PI / 180);
    }
    QtObject {
        id: map;

        readonly
        property int  zoomLevel       : 16;

        property int  zoomDiff        : (zoomLevel - preview.zoomLevel);

        property int  colMin          : preview.colMin * Math.pow (2, zoomDiff);
        property int  colMax          : preview.colMax * Math.pow (2, zoomDiff);
        property int  rowMin          : preview.rowMin * Math.pow (2, zoomDiff);
        property int  rowMax          : preview.rowMax * Math.pow (2, zoomDiff);

        property int  columns         : Math.abs (colMax - colMin);
        property int  rows            : Math.abs (rowMax - rowMin);

        property real  viewWidth       : (tileSize * columns);
        property real  viewHeight      : (tileSize * rows);

        property alias lonLeft         : preview.lonLeft;
        property alias lonRight        : preview.lonRight;
        property alias latTop          : preview.latTop;
        property alias latBottom       : preview.latBottom;

        property alias lonDelta        : preview.lonDelta;
        property alias latBottomDegree : preview.latBottomDegree;
    }
    Timer {
        id: timerCenter;
        interval: 350;
        running: false;
        repeat: false;
        onTriggered: {
            if (centerCoords !== Qt.point (0,0) && isZoomed) {
                var centerPos = coord2pos (centerCoords.x, centerCoords.y); // lat / lon
                var pos    = Qt.point (Math.round (-centerPos.x + (viewport.width / 2)),
                                       Math.round (-centerPos.y + (viewport.height / 2)));
                var xPos = clipValue (pos.x, clicker.drag.minimumX, clicker.drag.maximumX);
                var yPos = clipValue (pos.y, clicker.drag.minimumY, clicker.drag.maximumY);
                centerOnPos (xPos, yPos);
            }
        }
    }
    MouseArea {
        id: clicker;
        drag {
            target: (isZoomed ? grid : null);
            minimumX: (viewport.width - grid.width);
            minimumY: (viewport.height - grid.height);
            maximumX: 0;
            maximumY: 0;
        }
        anchors.fill: parent;
        onPositionChanged: {
            centerCoords = Qt.point (0,0);
        }
        onDoubleClicked: {
            if (!isZoomed) {
                var center = viewport.mapToItem (gridPreview, mouse.x, mouse.y);
                var ratioX = (center.x / gridPreview.width);
                var ratioY = (center.y / gridPreview.height);
                var pos    = Qt.point (Math.round ((-ratioX * grid.width) + (viewport.width / 2)),
                                       Math.round ((-ratioY * grid.height) + (viewport.height / 2)));
                centerOnPos (pos.x, pos.y);
            }
            isZoomed = !isZoomed;
        }
    }
    Grid {
        id: grid;
        width: map.viewWidth;
        height: map.viewHeight;
        columns: (initialized ? map.columns : 1);
        rows: (initialized ? map.rows : 1);
        opacity: (isZoomed ? 1.0 : 0.0);
        onXChanged: { refreshTiles (); }
        onYChanged: { refreshTiles (); }
        Component.onCompleted: {
            x = (viewport.width - grid.width) / 2;
            y = (viewport.height - grid.height) / 2;
        }

        Behavior on opacity { NumberAnimation { duration: 650; }}
        Repeater {
            id: repeater;
            model: (initialized ? map.rows * map.columns : 0);
            delegate: Component {
                Image {
                    id: tile;
                    source: helper.file;
                    cache: false;
                    asynchronous: true;
                    antialiasing: false;
                    smooth: false;
                    width: tileSize;
                    height: tileSize;

                    property bool load : false;
                    onLoadChanged: {
                        if (load) {
                            var idx = model ['index'];
                            var col = map.colMin + (idx % map.columns);
                            var row = map.rowMin + Math.floor (idx / map.columns);
                            helper.uri = tileUri.arg (map.zoomLevel).arg (col).arg (row);
                        }
                        else {
                            helper.uri = "";
                        }
                    }

                    TileHelper { id: helper; }
                }
            }
        }
    }
    Item {
        id: container;
        visible: (grid.opacity === 1.0);
        anchors {
            top: grid.top;
            left: grid.left;
        }

        Repeater {
            id: repeaterMarkers;

            property real pulseEffect : 1.0;
        }
    }
    Grid {
        id: gridPreview;
        width: preview.viewWidth;
        height: preview.viewHeight;
        columns: preview.columns;
        rows: preview.rows;
        transformOrigin: Item.Center;
        scale: (!isZoomed ? Math.min (viewport.width / width, viewport.height / height) : Math.min (map.viewWidth / width, map.viewHeight / height) );
        opacity: (!isZoomed ? 1.0 : 0.0);
        anchors.centerIn: parent;

        Behavior on scale   { NumberAnimation { duration: 650; }}
        Behavior on opacity { NumberAnimation { duration: 650; }}
        Repeater {
            model: (initialized ? preview.rows * preview.columns : 0);
            delegate: Component {
                Image {
                    cache: false;
                    asynchronous: true;
                    smooth: false;
                    antialiasing: false;
                    width: tileSize;
                    height: tileSize;
                    source: helper.file;

                    TileHelper {
                        id: helper;
                        Component.onCompleted: {
                            var idx = model ['index'];
                            var col = preview.colMin + (idx % preview.columns);
                            var row = preview.rowMin + Math.floor (idx / preview.columns);
                            uri = tileUri.arg (preview.zoomLevel).arg (col).arg (row);
                        }
                    }
                }
            }
        }
    }

    function clipValue (val, min, max) {
        return Math.max (min, Math.min (max, val));
    }
    function lon2x (lon, zoom) {
        return (Math.floor ((lon + 180) / 360 * Math.pow (2, zoom)));
    }
    function lat2y (lat, zoom) {
        return (Math.floor ((1 - Math.log (Math.tan (lat * Math.PI / 180) + 1 / Math.cos (lat * Math.PI / 180)) / Math.PI) / 2 * Math.pow (2, zoom)));
    }
    function x2lon (x, zoom) {
        return (x / Math.pow (2, zoom) * 360 - 180);
    }
    function y2lat (y, zoom) {
        var n = (Math.PI - 2 * Math.PI * y / Math.pow (2, zoom));
        return (180 / Math.PI * Math.atan (0.5 * (Math.exp (n) - Math.exp (-n))));
    }
}

