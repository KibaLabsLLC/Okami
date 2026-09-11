import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    width: 1280
    height: 720
    title: "Okami"

    readonly property color bgBase:      "#f4f6fb"
    readonly property color bgSurface:   "#ffffff"
    readonly property color bgCard:      "#ffffff"
    readonly property color bgCardHover: "#f7faff"
    readonly property color accent:      "#2f6fed"
    readonly property color accentSoft:  "#e8f0fe"
    readonly property color textPrimary: "#1c1e26"
    readonly property color textMuted:   "#8890a0"
    readonly property color divider:     "#e9ecf3"

    function decodeHtml(str) {
        if (!str) return "";
        return str
            .replace(/&amp;/g,  "&")
            .replace(/&lt;/g,   "<")
            .replace(/&gt;/g,   ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;/g,  "'")
    }

    background: Rectangle { color: root.bgBase }

    globalDrawer: Kirigami.GlobalDrawer {
        title: "Okami"
        titleIcon: "applications-all"
        modal: false
        width: Kirigami.Units.gridUnit * 13
        background: Rectangle { color: root.bgSurface }

        actions: [
            Kirigami.Action {
                text: "Discover"
                icon.name: "applications-all"
                onTriggered: {
                    backend.fetchApps("discover")
                    pageStack.replace(appsPage)
                }
            },
            Kirigami.Action {
                text: "Productivity"
                icon.name: "applications-office"
                onTriggered: {
                    backend.fetchApps("productivity")
                    pageStack.replace(appsPage)
                }
            },
            Kirigami.Action {
                text: "Development"
                icon.name: "applications-development"
                onTriggered: {
                    backend.fetchApps("development")
                    pageStack.replace(appsPage)
                }
            },
            Kirigami.Action {
                text: "Multimedia"
                icon.name: "applications-multimedia"
                onTriggered: {
                    backend.fetchApps("multimedia")
                    pageStack.replace(appsPage)
                }
            },
            Kirigami.Action {
                text: "Games"
                icon.name: "applications-games"
                onTriggered: {
                    backend.fetchApps("games")
                    pageStack.replace(appsPage)
                }
            },
            Kirigami.Action {
                text: "Installed"
                icon.name: "checkmark"
                onTriggered: {
                    backend.fetchApps("installed")
                    pageStack.replace(appsPage)
                }
            },
            Kirigami.Action {
                text: "About"
                icon.name: "help-about"
                onTriggered: pageStack.push(aboutPage)
            }
        ]
    }

    Component {
        id: appsPage

        Kirigami.Page {
            background: Rectangle { color: root.bgBase }
            padding: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header / search bar — keeps the flow to one screen, no extra navigation
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    color: root.bgSurface

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing * 1.5
                        anchors.rightMargin: Kirigami.Units.largeSpacing * 1.5
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.SearchField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: "Search apps"
                            onTextChanged: backend.filterApps(text)

                            background: Rectangle {
                                radius: 19
                                color: root.bgBase
                                border.color: searchField.activeFocus ? root.accent : root.divider
                                border.width: searchField.activeFocus ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: root.divider
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.gridUnit * 4
                        visible: backend.apps.length === 0 && !backend.loading
                        icon.name: "applications-all"
                        text: "No apps found"
                        explanation: "Try a different category or search term."
                    }

                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        visible: backend.loading
                        text: "Fetching apps..."
                        explanation: "Please wait while we update the catalog."
                        Kirigami.Action {
                            icon.name: "view-refresh"
                            text: "Stop"
                            onTriggered: backend.loading = false
                        }
                    }

                    GridView {
                        id: appsGrid
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        model: backend.apps
                        visible: !backend.loading && backend.apps.length > 0
                        clip: true
                        focus: true

                        readonly property int cellSpacing: Kirigami.Units.largeSpacing
                        readonly property int minCellW: Kirigami.Units.gridUnit * 11
                        readonly property int cols: Math.max(2, Math.floor(width / minCellW))
                        cellWidth:  Math.floor(width / cols)
                        cellHeight: Kirigami.Units.gridUnit * 15.5

                        add: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
                        }
                        populate: Transition {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
                        }

                        delegate: Item {
                            id: delegateRoot
                            width:  appsGrid.cellWidth
                            height: appsGrid.cellHeight

                            readonly property bool isFocused: appsGrid.currentIndex === index
                            readonly property var status: backend.installationProgress[modelData.packageId] || {"installing": false, "progress": 0, "status": ""}
                            readonly property bool isInstalled: backend.installedApps.indexOf(modelData.packageId) !== -1

                            Rectangle {
                                id: cardBody
                                anchors.fill: parent
                                anchors.margins: appsGrid.cellSpacing / 2
                                radius: 22
                                color: hoverHandler.hovered || delegateRoot.isFocused ? root.bgCardHover : root.bgCard

                                scale: hoverHandler.hovered || delegateRoot.isFocused ? 1.025 : 1.0
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 140 } }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: "#1c2b4a"
                                    shadowOpacity: (hoverHandler.hovered || delegateRoot.isFocused) ? 0.16 : 0.07
                                    shadowBlur: (hoverHandler.hovered || delegateRoot.isFocused) ? 0.6 : 0.4
                                    shadowVerticalOffset: (hoverHandler.hovered || delegateRoot.isFocused) ? 6 : 2
                                    Behavior on shadowOpacity { NumberAnimation { duration: 140 } }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.largeSpacing
                                    spacing: Kirigami.Units.smallSpacing / 1.5

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: 56
                                        Layout.preferredHeight: 56
                                        radius: 16
                                        color: root.accentSoft

                                        Image {
                                            anchors.centerIn: parent
                                            width: 38; height: 38
                                            source: modelData.icon || ""
                                            fillMode: Image.PreserveAspectFit
                                        }
                                    }

                                    Label {
                                        text: root.decodeHtml(modelData.name)
                                        font.bold: true
                                        font.pixelSize: 14
                                        color: root.textPrimary
                                        Layout.fillWidth: true
                                        Layout.topMargin: 4
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: delegateRoot.status.installing ? delegateRoot.status.status : (delegateRoot.isInstalled ? "Installed" : "Free")
                                        font.pixelSize: 11
                                        color: delegateRoot.isInstalled ? root.accent : root.textMuted
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    ProgressBar {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 2
                                        visible: delegateRoot.status.installing
                                        value: delegateRoot.status.progress
                                        from: 0
                                        to: 1

                                        background: Rectangle {
                                            implicitHeight: 4
                                            radius: 2
                                            color: root.divider
                                        }
                                        contentItem: Item {
                                            implicitHeight: 4
                                            Rectangle {
                                                width: parent.width * (parent.parent.visualPosition ?? 0)
                                                height: parent.height
                                                radius: 2
                                                color: root.accent
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Button {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        text: delegateRoot.isInstalled ? "Open" : (delegateRoot.status.installing ? "Installing…" : "Install")
                                        enabled: !delegateRoot.status.installing
                                        flat: !delegateRoot.isInstalled

                                        background: Rectangle {
                                            radius: 16
                                            color: delegateRoot.isInstalled
                                                   ? root.accentSoft
                                                   : (parent.pressed ? Qt.darker(root.accent, 1.1) : root.accent)
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                        }
                                        contentItem: Label {
                                            text: parent.text
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: delegateRoot.isInstalled ? root.accent : "#ffffff"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: {
                                            if (delegateRoot.isInstalled) {
                                                backend.openApp(modelData.packageId)
                                            } else {
                                                backend.installApp(modelData.packageId, modelData.name, modelData.icon)
                                            }
                                        }
                                    }
                                }
                            }

                            HoverHandler { id: hoverHandler }
                            TapHandler {
                                onTapped: {
                                    appsGrid.currentIndex = index
                                    appsGrid.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: aboutPage
        Kirigami.AboutPage {
            title: "About Okami"
            aboutData: {
                "displayName": "Okami",
                "productName": "Okami",
                "version": "3.5.7",
                "description": "KibaOS App Store",
                "copyrightStatement": "Copyright (c) 2026 Kiba Labs, LLC",
                "authors": [{ "name": "Kiba Labs, LLC" }]
            }
        }
    }

    pageStack.initialPage: appsPage

    ProgressBar {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        indeterminate: true
        visible: backend.loading

        background: Rectangle { color: root.divider }
        contentItem: Item {
            Rectangle {
                anchors.fill: parent
                color: root.accent
            }
        }
    }

    Connections {
        target: backend
        function onInstallationFinished(packageId, success, message) {
            root.showPassiveNotification(message)
        }
    }

    Component.onCompleted: {
        backend.fetchApps("discover")
    }
}
