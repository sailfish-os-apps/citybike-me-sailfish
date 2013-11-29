import QtQuick 2.0;
import harbour.citybikeme.myQtCoreImports 5.1;
import Sailfish.Silica 1.0;
import "Ajax.js" as Ajax;
import "pages";
import "cover";

ApplicationWindow {
    id: rootItem;
    cover: CoverPage { }
    initialPage: firstPage;
    onCurrentStationItemChanged: {
        if (currentStationItem !== null) {
            centerViewOnPosRequested (currentStationItem ['latitude'],
                                      currentStationItem ['longitude']);
        }
    }
    onHaveABikeChanged: {
        if (haveABike) {
            timerBike.start ();
        }
        else {
            timerBike.stop ();
        }
    }

    Timer {
        id: timerRefresh;
        running: (autoUpdate && rootItem.applicationActive);
        repeat: true;
        interval: 15000;
        triggeredOnStart: true;
        onTriggered: { refreshModel (); }
    }
    PreciseTimer {
        id: timerBike;
        singleShot: false;
        interval: 1000;
        timerType: Qt.PreciseTimer;
        onTimeout: { currentTimeSecs++; }
    }
    Timer {
        id: timerReset;
        interval: 1000;
        running: false;
        repeat: false;
        onTriggered: {
            initialized          = false;
            autoUpdate           = false;
            minLatitude          = 0;
            maxLatitude          = 0;
            minLongitude         = 0;
            maxLongitude         = 0;
            currentStationItem   = null;
            currentContract      = BikesModel.getContractId ();
            currentCommercial    = BikesModel.getContractName ();
            currentCountryCode   = BikesModel.getContractCountry ();
            BikesModel.truncate ();
            autoUpdate           = true;
        }
    }
    ListModel {
        id: modelContracts;
        Component.onCompleted: {
            Ajax.doRequest ('GET',
                            urlOfJsonContracts.arg (_jcdApiKey),
                            function (obj) {
                                for (var it = 0; it < obj.length; it++) {
                                    var entry = obj [it];
                                    append ({
                                                "name"            : entry ['name'],
                                                "commercial_name" : entry ['commercial_name'],
                                                "country_code"    : entry ['country_code']
                                            });
                                }
                            });
        }
    }
    FirstPage {
        id: firstPage;
    }
    SecondPage {
        id: secondPage;
    }
    Formatter {
        id: formatter;
    }
    TouchBlocker {
        visible: !initialized;
        anchors.fill: parent;

        Rectangle {
            color: "black";
            opacity: 0.65;
            anchors.fill: parent;
        }
        BusyIndicator {
            running: (!initialized && rootItem.applicationActive);
            size: BusyIndicatorSize.Large;
            anchors.centerIn: parent;
        }
    }
    Page {
        id: dialogContract;

        PageHeader {
            id: header;
            title: qsTr ("Select a contract :");
        }
        SilicaListView {
            model: modelContracts;
            delegate: BackgroundItem {
                onClicked: {
                    BikesModel.setContract (model ['name'], model ['commercial_name'], model ['country_code']);
                    timerReset.start ();
                    pageStack.navigateBack ();
                }

                Row {
                    spacing: Theme.paddingSmall;
                    anchors {
                        left: parent.left;
                        right: parent.right;
                        margins: Theme.paddingLarge;
                        verticalCenter: parent.verticalCenter;
                    }

                    property real itemWidth : (width - spacing) / 2;

                    Label {
                        id: label;
                        text: model ['commercial_name'];
                        font.pixelSize: Theme.fontSizeSmall;
                        font.bold: (currentContract === model ['name']);
                        color: (currentContract === model ['name'] ? Theme.highlightColor : Theme.primaryColor);
                        width: parent.itemWidth;
                        horizontalAlignment: Text.AlignRight;
                    }
                    Label {
                        text: "(%1, %2)".arg (model ['name']).arg (model ['country_code']);
                        font.pixelSize: Theme.fontSizeExtraSmall;
                        color: Theme.secondaryColor;
                        anchors.baseline: label.baseline;
                        width: parent.itemWidth;
                        horizontalAlignment: Text.AlignLeft;
                    }
                }
            }
            anchors {
                top: header.bottom;
                left: parent.left;
                right: parent.right;
                bottom: parent.bottom;
            }
        }
    }

    property QtObject         currentStationItem : null;
    property int              currentStationIdx  : (currentStationItem ? currentStationItem ['number'] || -1 : -1);
    property real             currentTimeSecs    : 0;
    property string           currentContract    : BikesModel.getContractId ();
    property string           currentCommercial  : BikesModel.getContractName ();
    property string           currentCountryCode : BikesModel.getContractCountry ();
    property bool             initialized        : false;
    property bool             haveABike          : false;
    property bool             autoUpdate         : true;

    property real             minLatitude        : 0;
    property real             maxLatitude        : 0;
    property real             minLongitude       : 0;
    property real             maxLongitude       : 0;

    readonly property string  urlOfJsonStations  : "https://api.jcdecaux.com/vls/v1/stations?apiKey=%1&contract=%2";
    readonly property string  urlOfJsonContracts : "https://api.jcdecaux.com/vls/v1/contracts?apiKey=%1";
    readonly property string  _jcdApiKey         : "3328d091b7fdf20ce51df42de35e18c3ec793f0f";

    signal globalViewRequested      ();
    signal centerViewOnPosRequested (real lat, real lon);

    function refreshModel () {
        Ajax.doRequest ('GET',
                        urlOfJsonStations.arg (_jcdApiKey).arg (currentContract),
                        function (obj) {
                            var latList = [];
                            var lonList = [];
                            for (var it = 0; it < obj.length; it++) {
                                var entry = obj [it];
                                if (entry ['position']) {
                                    var lat = (entry ['position']['lat'] || -1);
                                    var lon = (entry ['position']['lng'] || -1);
                                    if (lat >= 0 && lon >= 0) {
                                        latList.push (lat);
                                        lonList.push (lon);
                                        BikesModel.insertOrUpdate (entry ['number'], {
                                                                       "name"      : entry ['name'],
                                                                       "address"   : entry ['address'],
                                                                       "contract"  : entry ['contract_name'],
                                                                       "updated"   : entry ['last_update'],
                                                                       "number"    : entry ['number'],
                                                                       "status"    : entry ['status'],
                                                                       "bonus"     : entry ['bonus'],
                                                                       "banking"   : entry ['banking'],
                                                                       "slots"     : entry ['bike_stands'],
                                                                       "free"      : entry ['available_bike_stands'],
                                                                       "bikes"     : entry ['available_bikes'],
                                                                       "latitude"  : lat,
                                                                       "longitude" : lon
                                                                   });
                                    }
                                    else { }
                                }
                            }
                            if (!initialized) {
                                latList.sort ();
                                lonList.sort ();
                                minLatitude  = (latList [0] || 0);
                                maxLatitude  = (latList [latList.length -1] || 0);
                                minLongitude = (lonList [0] || 0);
                                maxLongitude = (lonList [lonList.length -1] || 0);
                                initialized = true;
                            }
                        });
    }
}


