import QtQuick 2.0;
import Sailfish.Silica 1.0;

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
        anchors {
            top: parent.top;
            left: parent.left;
            right: parent.right;
            bottom: panelBottom.top;
        }

        PullDownMenu {
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
    OpacityRampEffect {
        sourceItem: view;
        enabled: (!view.atYEnd);
        direction: OpacityRamp.TopToBottom;
        offset: 0.35;
        slope: 1.25;
        width: view.width;
        height: view.height;
        anchors.fill: null;
    }
    Button {
        id: panelBottom;
        text: qsTr ("Back to top");
        anchors {
            left: parent.left;
            right: parent.right;
            bottom: parent.bottom;
            bottomMargin: (view.atYBeginning ? -height : 0);
            margins: 0;
        }
        onClicked: { view.scrollToTop (); }
    }
}


