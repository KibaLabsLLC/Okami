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

    // ---- Palette --------------------------------------------------------
    readonly property color bgBase:      "#f2f4fa"
    readonly property color bgSurface:   "#ffffff"
    readonly property color bgCard:      "#ffffff"
    readonly property color bgCardHover: "#f7faff"
    readonly property color bgCardPress: "#eef3fd"
    readonly property color accent:      "#2f6fed"
    readonly property color accentDark:  "#2557c7"
    readonly property color accentSoft:  "#e8f0fe"
    readonly property color textPrimary: "#1c1e26"
    readonly property color textMuted:   "#8890a0"
    readonly property color divider:     "#e9ecf3"

    readonly property int radiusLg: 26
    readonly property int radiusMd: 18
    readonly property int radiusSm: 12
    readonly property int radiusPill: 999

    property string activeCategory: "discover"

    readonly property var categories: [
        { id: "discover",     label: "Discover",     icon: "applications-all" },
        { id: "productivity", label: "Productivity",  icon: "applications-office" },
        { id: "development",  label: "Development",   icon: "applications-development" },
        { id: "multimedia",   label: "Multimedia",    icon: "applications-multimedia" },
        { id: "games",        label: "Games",         icon: "applications-games" },
        { id: "installed",    label: "Installed",     icon: "checkmark" }
    ]

    function decodeHtml(str) {
        if (!str) return "";
        return str
            .replace(/&amp;/g,  "&")
            .replace(/&lt;/g,   "<")
            .replace(/&gt;/g,   ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;/g,  "'")
    }

    function selectCategory(id) {
        root.activeCategory = id
        backend.fetchApps(id)
        pageStack.replace(appsPage)
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
                checked: root.activeCategory === "discover"
                onTriggered: root.selectCategory("discover")
            },
            Kirigami.Action {
                text: "Productivity"
                icon.name: "applications-office"
                checked: root.activeCategory === "productivity"
                onTriggered: root.selectCategory("productivity")
            },
            Kirigami.Action {
                text: "Development"
                icon.name: "applications-development"
                checked: root.activeCategory === "development"
                onTriggered: root.selectCategory("development")
            },
            Kirigami.Action {
                text: "Multimedia"
                icon.name: "applications-multimedia"
                checked: root.activeCategory === "multimedia"
                onTriggered: root.selectCategory("multimedia")
            },
            Kirigami.Action {
                text: "Games"
                icon.name: "applications-games"
                checked: root.activeCategory === "games"
                onTriggered: root.selectCategory("games")
            },
            Kirigami.Action {
                text: "Installed"
                icon.name: "checkmark"
                checked: root.activeCategory === "installed"
                onTriggered: root.selectCategory("installed")
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

                // ---- Header: search + category chips (one screen, no drilldown) ----
                Rectangle {
                    id: headerBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 116
                    color: root.bgSurface

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#1c2b4a"
                        shadowOpacity: appsGrid.contentY > 4 ? 0.08 : 0
                        shadowBlur: 0.5
                        shadowVerticalOffset: 3
                        Behavior on shadowOpacity { NumberAnimation { duration: 150 } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing * 1.5
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.SearchField {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            placeholderText: "Search apps"
                            // A short debounce instead of filtering on every
                            // keystroke — waits for a pause in typing, the
                            // way a person actually expects search to react.
                            onTextChanged: searchDebounce.restart()

                            Timer {
                                id: searchDebounce
                                interval: 220
                                onTriggered: backend.filterApps(searchField.text)
                            }

                            background: Rectangle {
                                radius: root.radiusPill
                                color: root.bgBase
                                border.color: searchField.activeFocus ? root.accent : "transparent"
                                border.width: searchField.activeFocus ? 2 : 0
                                Behavior on border.color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                            }
                        }

                        // Quick category chips — lets users switch categories
                        // without opening the drawer, which is friendlier on
                        // narrower windows and faster for quick browsing.
                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            contentWidth: chipRow.width
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            Row {
                                id: chipRow
                                spacing: Kirigami.Units.smallSpacing
                                Repeater {
                                    model: root.categories
                                    delegate: Rectangle {
                                        id: chip
                                        readonly property bool isActive: root.activeCategory === modelData.id
                                        height: 34
                                        width: chipLabel.implicitWidth + 34
                                        radius: root.radiusPill
                                        color: isActive ? root.accent : (chipHover.hovered ? root.bgCardHover : root.bgBase)
                                        scale: chipTap.pressed ? 0.94 : 1.0
                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                                        Label {
                                            id: chipLabel
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: 12
                                            font.bold: chip.isActive
                                            color: chip.isActive ? "#ffffff" : root.textPrimary
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        HoverHandler { id: chipHover }
                                        TapHandler { id: chipTap; onTapped: root.selectCategory(modelData.id) }
                                    }
                                }
                            }
                        }
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

                    // Skeleton grid while loading, instead of a bare spinner —
                    // gives an immediate sense of layout and feels faster.
                    GridView {
                        id: skeletonGrid
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.largeSpacing
                        visible: backend.loading
                        interactive: false
                        model: 8
                        cellWidth: Math.floor(width / Math.max(2, Math.floor(width / (Kirigami.Units.gridUnit * 11))))
                        cellHeight: Kirigami.Units.gridUnit * 15.5

                        delegate: Item {
                            width: skeletonGrid.cellWidth
                            height: skeletonGrid.cellHeight
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                radius: root.radiusLg
                                color: root.bgCard

                                Rectangle {
                                    id: shimmer
                                    anchors.fill: parent
                                    radius: parent.radius
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#00000000" }
                                        GradientStop { position: 0.5; color: "#08000000" }
                                        GradientStop { position: 1.0; color: "#00000000" }
                                    }
                                    // A brief pause between sweeps reads as a
                                    // breath rather than a mechanical loop.
                                    SequentialAnimation on x {
                                        loops: Animation.Infinite
                                        NumberAnimation { from: -parent.width; to: parent.width; duration: 1000; easing.type: Easing.InOutSine }
                                        PauseAnimation { duration: 450 }
                                    }
                                }
                            }
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
                        boundsBehavior: Flickable.DragOverBounds
                        maximumFlickVelocity: 2500

                        readonly property int cellSpacing: Kirigami.Units.largeSpacing
                        readonly property int minCellW: Kirigami.Units.gridUnit * 11
                        readonly property int cols: Math.max(2, Math.floor(width / minCellW))
                        cellWidth:  Math.floor(width / cols)
                        cellHeight: Kirigami.Units.gridUnit * 15.5

                        // Each card eases in a beat after the last rather
                        // than all at once — a small ripple instead of a
                        // synchronized, mechanical pop.
                        add: Transition {
                            SequentialAnimation {
                                PauseAnimation { duration: Math.min(index * 16, 240) }
                                ParallelAnimation {
                                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
                                    NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                                }
                            }
                        }
                        populate: Transition {
                            SequentialAnimation {
                                PauseAnimation { duration: Math.min(index * 14, 220) }
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                            }
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
                                radius: root.radiusLg
                                color: pressHandler.pressed
                                       ? root.bgCardPress
                                       : (hoverHandler.hovered || delegateRoot.isFocused ? root.bgCardHover : root.bgCard)

                                scale: pressHandler.pressed ? 0.985
                                       : (hoverHandler.hovered || delegateRoot.isFocused ? 1.03 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                                Behavior on color { ColorAnimation { duration: 140 } }

                                border.width: delegateRoot.isFocused ? 2 : 0
                                border.color: root.accent

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: "#1c2b4a"
                                    shadowOpacity: (hoverHandler.hovered || delegateRoot.isFocused) ? 0.18 : 0.06
                                    shadowBlur: (hoverHandler.hovered || delegateRoot.isFocused) ? 0.7 : 0.4
                                    shadowVerticalOffset: (hoverHandler.hovered || delegateRoot.isFocused) ? 8 : 2
                                    Behavior on shadowOpacity { NumberAnimation { duration: 140 } }
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.largeSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: 60
                                        Layout.preferredHeight: 60
                                        radius: root.radiusMd
                                        color: root.accentSoft

                                        Image {
                                            anchors.centerIn: parent
                                            width: 40; height: 40
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

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 4

                                        Rectangle {
                                            visible: delegateRoot.isInstalled
                                            width: 6; height: 6; radius: 3
                                            color: root.accent
                                        }
                                        Label {
                                            text: delegateRoot.status.installing ? delegateRoot.status.status : (delegateRoot.isInstalled ? "Installed" : "Free")
                                            font.pixelSize: 11
                                            color: delegateRoot.isInstalled ? root.accent : root.textMuted
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.topMargin: 2
                                        visible: delegateRoot.status.installing
                                        implicitHeight: 5
                                        radius: root.radiusPill
                                        color: root.divider

                                        Rectangle {
                                            height: parent.height
                                            radius: parent.radius
                                            width: parent.width * delegateRoot.status.progress
                                            color: root.accent
                                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Button {
                                        id: actionButton
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        text: delegateRoot.isInstalled ? "Open" : (delegateRoot.status.installing ? "Installing…" : "Install")
                                        enabled: !delegateRoot.status.installing
                                        flat: !delegateRoot.isInstalled

                                        background: Rectangle {
                                            radius: root.radiusPill
                                            color: delegateRoot.isInstalled
                                                   ? root.accentSoft
                                                   : (actionButton.pressed ? root.accentDark : root.accent)
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                        }
                                        contentItem: Label {
                                            text: actionButton.text
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
                                id: pressHandler
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

    // Slim top-of-window progress indicator, rounded ends
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 0
        height: 3
        color: "transparent"
        visible: backend.loading

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: root.divider
        }
        Rectangle {
            width: parent.width * 0.35
            height: parent.height
            radius: 2
            color: root.accent
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { from: -parent.width * 0.35; to: parent.parent.width; duration: 1000; easing.type: Easing.InOutQuad }
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