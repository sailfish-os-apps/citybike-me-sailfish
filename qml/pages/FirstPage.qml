import QtQuick 2.0;
import Sailfish.Silica 1.0;
import "../components";

Page {
    id: page;
    allowedOrientations: (Orientation.Portrait | Orientation.Landscape);

    SilicaListView {
        id: view;
        currentIndex: -1;
        model: BikesModel;
        header: Column {
            spacing: Theme.paddingSmall;
            anchors {
                left: (parent ? parent.left : undefined);
                right: (parent ? parent.right : undefined);
            }

            PageHeader {
                title: qsTr ("CityBike'me");
            }
            Label {
                text: qsTr ("Find a bike or a station easily and quickly in cities that have contract with JCDecaux.");
                color: Theme.secondaryHighlightColor;
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere;
                font.pixelSize: Theme.fontSizeExtraSmall;
                anchors {
                    left: parent.left;
                    right: parent.right;
                    margins: Theme.paddingLarge;
                }
            }
            Row {
                height: childrenRect.height;
                anchors {
                    left: parent.left;
                    right: parent.right;
                    margins: Theme.paddingSmall;
                }

                Image {
                    id: iconSearch;
                    source: "image://theme/icon-m-search";
                    height: inputSearch.height;
                    width: height;
                }
                Item {
                    width: (parent.width - parent.spacing - iconSearch.width);
                    height: iconSearch.height;

                    TextField {
                        id: inputSearch;
                        label: qsTr ("Search a station");
                        placeholderText: qsTr ("Search a station");
                        anchors {
                            left: parent.left;
                            right: parent.right;
                        }
                        onTextChanged: { BikesModel.filter = inputSearch.text; }
                        EnterKey.onClicked: { inputSearch.focus = false; }
                    }
                    MouseArea {
                        visible: (inputSearch.text !== "");
                        width: height;
                        anchors {
                            top: parent.top;
                            right: parent.right;
                            bottom: parent.verticalCenter;
                        }
                        onClicked: { inputSearch.text = ""; }

                        Image {
                            source: "image://theme/icon-m-clear";
                            antialiasing: true;
                            fillMode: Image.PreserveAspectFit;
                            anchors.fill: parent;
                        }
                    }
                }
            }
        }
        delegate: BackgroundItem {
            id: backgroundItem;
            onClicked: {
                currentStationItem = BikesModel.getByUid (model ['number']);
                pageStack.push (secondPage);
            }
            ListView.onAdd: AddAnimation { target: backgroundItem; }

            Label {
                text: BikesModel.highlightText (model ['name'], BikesModel.filter, Theme.highlightColor.toString ());
                textFormat: Text.RichText;
                truncationMode: TruncationMode.Fade;
                color: BikesModel.filter.length > 0 ? (highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                                                    : (highlighted ? Theme.highlightColor          : Theme.primaryColor);
                anchors {
                    left: parent.left;
                    right: parent.right;
                    margins: Theme.paddingLarge;
                    verticalCenter: parent.verticalCenter;
                }
            }
        }
        footer: Item {
            height: btnBackToTop.height;
            anchors {
                left:  (parent ? parent.left  : undefined);
                right: (parent ? parent.right : undefined);
            }
        }
        anchors {
            top: parent.top;
            left: parent.left;
            right: parent.right;
            bottom: parent.bottom;
        }

        PullDownMenu {
            id: pulley;

            MenuItem {
                text: qsTr ("Current contract");
                color: Theme.highlightColor;
                font.pixelSize: Theme.fontSizeMedium;
                font.family: Theme.fontFamilyHeading;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
                onClicked: {
                    pageStack.push (dialogContract);
                }
            }
            Label {
                text: qsTr ("&ldquo;&nbsp;<b>%1</b>&nbsp;&rdquo; (%2, %3)").arg (currentCommercial).arg (currentContract).arg (currentCountryCode);
                textFormat: Text.RichText;
                font.pixelSize: Theme.fontSizeMedium;
                font.family: Theme.fontFamilyHeading;
                horizontalAlignment: Text.AlignHCenter;
                color: Theme.secondaryHighlightColor;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
            MenuItem {
                text: qsTr ("Show map of stations");
                font.pixelSize: Theme.fontSizeMedium;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
                onClicked: {
                    currentStationItem = null;
                    globalViewRequested ();
                    pageStack.push (secondPage);
                }
            }
        }
        ViewPlaceholder {
            enabled: (initialized && !view.count);
            text: qsTr ("No matching station");
        }
        VerticalScrollDecorator {}
    }
    ScrollDimmer { flickable: view; }
    Rectangle {
        visible: btnBackToTop.visible;
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba (0, 0, 0, 0); }
            GradientStop { position: 1.0; color: Qt.rgba (0, 0, 0, 1); }
        }
        anchors {
            fill: btnBackToTop;
            topMargin: (-btnBackToTop.height / 2);
        }
    }
    Button {
        id: btnBackToTop;
        text: qsTr ("Back to top");
        visible: (!view.atYBeginning && view.visibleArea.heightRatio < 1.0 && !pulley.active);
        anchors {
            left: view.left;
            right: view.right;
            bottom: view.bottom;
        }
        onClicked: { view.positionViewAtBeginning (); }
    }
}


