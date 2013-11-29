import QtQuick 2.0;
import Sailfish.Silica 1.0;

CoverBackground {
    id: background;

    Column {
        anchors {
            top: parent.top;
            left: parent.left;
            right: parent.right;
            margins: Theme.paddingLarge;
        }

        Label {
            text: currentCommercial;
            color: Theme.primaryColor;
            fontSizeMode: Text.HorizontalFit;
            font.bold: true;
            font.pixelSize: Theme.itemSizeExtraLarge;
            font.family: Theme.fontFamilyHeading
            height: contentHeight;
            anchors {
                left: parent.left;
                right: parent.right;
            }
        }
        Label {
            text: (haveABike ? qsTr ("Current time") : qsTr ("No bike yet"));
            color: Theme.secondaryHighlightColor;
            fontSizeMode: Text.HorizontalFit;
            font.pixelSize: Theme.itemSizeExtraLarge;
            height: contentHeight;
            anchors {
                left: parent.left;
                right: parent.right;
            }
        }
        Item {
            height: Theme.paddingSmall;
            anchors {
                left: parent.left;
                right: parent.right;
            }
        }
        Item {
            height: width;
            anchors {
                left: parent.left;
                right: parent.right;
                margins: Theme.paddingLarge;
            }

            Repeater {
                model: 60;
                delegate: Item {
                    rotation: model.index * (360 / 60);
                    anchors {
                        top: parent.top;
                        bottom: parent.bottom;
                        horizontalCenter: parent.horizontalCenter;
                    }

                    Rectangle {
                        color: (haveABike ? (model.index <= currentTimeSecs % 60 ? Theme.highlightColor : Theme.highlightDimmerColor) : "transparent");
                        width: 5;
                        height: width;
                        radius: (width / 2);
                        antialiasing: true;
                        anchors {
                            verticalCenter: parent.top;
                            horizontalCenter: parent.horizontalCenter;
                        }
                    }
                }
            }
            Text {
                text: " %1'%2%3\"".arg (Math.floor (currentTimeSecs / 60)).arg (currentTimeSecs % 60 < 10 ? "0" : "").arg (currentTimeSecs % 60);
                font.pixelSize: Theme.itemSizeExtraLarge;
                font.bold: true;
                color: (haveABike ? Theme.highlightColor : Theme.secondaryHighlightColor);
                fontSizeMode: Text.Fit;
                horizontalAlignment: Text.AlignHCenter;
                verticalAlignment: Text.AlignVCenter;
                anchors {
                    fill: parent;
                    margins: (parent.width / 4);
                }
            }
        }
    }
    CoverActionList {
        id: coverAction;
        iconBackground: true;

        CoverAction {
            iconSource: "image://theme/%1".arg (haveABike ? "icon-cover-cancel" : "icon-cover-timer");
            onTriggered: {
                if (!haveABike) {
                    currentTimeSecs = 0;
                }
                haveABike = !haveABike;
            }
        }
    }
}


