import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root
    width: 1280
    height: 800
    title: "Okami"

    // ---- Design Tokens & Palette ---------------------------------------
    readonly property color bgBase:      "#f8fafc"
    readonly property color bgSurface:   "#ffffff"
    readonly property color bgCard:      "#ffffff"
    readonly property color bgCardHover: "#f1f5f9"
    readonly property color bgCardPress: "#e2e8f0"
    readonly property color accent:      "#2563eb"
    readonly property color accentDark:  "#1d4ed8"
    readonly property color accentSoft:  "#eff6ff"
    readonly property color accentLight: "#dbeafe"
    readonly property color textPrimary: "#0f172a"
    readonly property color textMuted:   "#64748b"
    readonly property color textLight:   "#94a3b8"
    readonly property color divider:     "#e2e8f0"
    readonly property color cardBorder:  "#f1f5f9"
    readonly property color success:     "#10b981"
    readonly property color successSoft: "#ecfdf5"

    readonly property int radiusXl: 24
    readonly property int radiusLg: 18
    readonly property int radiusMd: 12
    readonly property int radiusSm: 8
    readonly property int radiusPill: 999

    property string activeCategory: "all"
    property var selectedApp: null

    readonly property var categories: [
        { id: "all",          label: "All Apps",      icon: "applications-all" },
        { id: "discover",     label: "Discover",      icon: "compass" },
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

    function openAppDetails(appData) {
        root.selectedApp = appData
        detailSheet.open()
    }

    background: Rectangle { color: root.bgBase }

    globalDrawer: Kirigami.GlobalDrawer {
        title: "Okami App Store"
        titleIcon: "applications-all"
        modal: false
        width: Kirigami.Units.gridUnit * 14
        background: Rectangle { color: root.bgSurface }

        actions: [
            Kirigami.Action {
                text: "All Apps"
                icon.name: "applications-all"
                checked: root.activeCategory === "all"
                onTriggered: root.selectCategory("all")
            },
            Kirigami.Action {
                text: "Discover"
                icon.name: "compass"
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

                // ---- Modern Sticky Glassmorphism Header Bar ----
                Rectangle {
                    id: headerBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 124
                    color: root.bgSurface

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: root.divider
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.largeSpacing * 1.5
                        anchors.rightMargin: Kirigami.Units.largeSpacing * 1.5
                        anchors.topMargin: Kirigami.Units.largeSpacing
                        anchors.bottomMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.mediumSpacing

                        // Top Row: Title + Search Field + Result Count
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.largeSpacing

                            Label {
                                text: {
                                    for (var i=0; i<root.categories.length; i++) {
                                        if (root.categories[i].id === root.activeCategory) return root.categories[i].label
                                    }
                                    return "Apps"
                                }
                                font.pixelSize: 22
                                font.bold: true
                                color: root.textPrimary
                            }

                            Rectangle {
                                visible: !backend.loading && backend.apps.length > 0
                                height: 22
                                width: appCountLabel.implicitWidth + 16
                                radius: root.radiusPill
                                color: root.accentSoft

                                Label {
                                    id: appCountLabel
                                    anchors.centerIn: parent
                                    text: backend.apps.length + " apps"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: root.accent
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Modern Search Bar with Clear Button
                            Rectangle {
                                Layout.preferredWidth: 320
                                Layout.preferredHeight: 40
                                radius: root.radiusPill
                                color: root.bgBase
                                border.color: searchInput.activeFocus ? root.accent : root.divider
                                border.width: searchInput.activeFocus ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Kirigami.Icon {
                                        source: "search"
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        color: root.textMuted
                                    }

                                    TextInput {
                                        id: searchInput
                                        Layout.fillWidth: true
                                        font.pixelSize: 13
                                        color: root.textPrimary
                                        selectByMouse: true
                                        onTextChanged: searchDebounce.restart()

                                        Text {
                                            text: "Search apps…"
                                            font.pixelSize: 13
                                            color: root.textMuted
                                            visible: !searchInput.text && !searchInput.activeFocus
                                        }

                                        Timer {
                                            id: searchDebounce
                                            interval: 220
                                            onTriggered: backend.filterApps(searchInput.text)
                                        }
                                    }

                                    Rectangle {
                                        visible: searchInput.text.length > 0
                                        width: 18; height: 18; radius: 9
                                        color: clearTap.pressed ? root.bgCardPress : root.divider

                                        Label {
                                            anchors.centerIn: parent
                                            text: "✕"
                                            font.pixelSize: 10
                                            color: root.textMuted
                                        }

                                        TapHandler {
                                            id: clearTap
                                            onTapped: {
                                                searchInput.text = ""
                                                backend.filterApps("")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Category Pills Bar
                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            contentWidth: chipRow.width
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            Row {
                                id: chipRow
                                spacing: 8
                                Repeater {
                                    model: root.categories
                                    delegate: Rectangle {
                                        id: chip
                                        readonly property bool isActive: root.activeCategory === modelData.id
                                        height: 36
                                        width: chipLayout.implicitWidth + 24
                                        radius: root.radiusPill
                                        color: isActive ? root.accent : (chipHover.hovered ? root.bgCardHover : root.bgBase)
                                        border.color: isActive ? root.accent : (chipHover.hovered ? root.divider : "transparent")
                                        border.width: 1
                                        scale: chipTap.pressed ? 0.95 : 1.0
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on scale { NumberAnimation { duration: 120 } }

                                        RowLayout {
                                            id: chipLayout
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Kirigami.Icon {
                                                source: modelData.icon
                                                Layout.preferredWidth: 14
                                                Layout.preferredHeight: 14
                                                color: chip.isActive ? "#ffffff" : root.textMuted
                                            }

                                            Label {
                                                text: modelData.label
                                                font.pixelSize: 12
                                                font.bold: chip.isActive
                                                color: chip.isActive ? "#ffffff" : root.textPrimary
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }

                                        HoverHandler { id: chipHover }
                                        TapHandler { id: chipTap; onTapped: root.selectCategory(modelData.id) }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- Content Area ----
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: Kirigami.Units.largeSpacing

                        // Featured Hero Banner (Shown when apps are loaded on All or Discover views)
                        Rectangle {
                            id: heroBanner
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.largeSpacing * 1.5
                            Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                            Layout.topMargin: Kirigami.Units.largeSpacing
                            Layout.preferredHeight: 180
                            visible: !backend.loading && backend.apps.length > 0 && (root.activeCategory === "all" || root.activeCategory === "discover")
                            radius: root.radiusXl

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#1e40af" }
                                GradientStop { position: 1.0; color: "#3b82f6" }
                            }

                            readonly property var featuredApp: backend.apps.length > 0 ? backend.apps[0] : null
                            readonly property bool isInstalled: featuredApp ? backend.installedApps.indexOf(featuredApp.packageId) !== -1 : false

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.largeSpacing * 1.5
                                spacing: Kirigami.Units.largeSpacing * 1.5

                                Rectangle {
                                    Layout.preferredWidth: 96
                                    Layout.preferredHeight: 96
                                    radius: root.radiusLg
                                    color: "#ffffff"

                                    Image {
                                        anchors.centerIn: parent
                                        width: 72; height: 72
                                        source: heroBanner.featuredApp ? (heroBanner.featuredApp.icon || "") : ""
                                        fillMode: Image.PreserveAspectFit
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        height: 22
                                        width: featuredTag.implicitWidth + 16
                                        radius: root.radiusPill
                                        color: "#30ffffff"

                                        Label {
                                            id: featuredTag
                                            anchors.centerIn: parent
                                            text: "FEATURED SPOTLIGHT"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }

                                    Label {
                                        text: heroBanner.featuredApp ? root.decodeHtml(heroBanner.featuredApp.name) : ""
                                        font.pixelSize: 22
                                        font.bold: true
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: heroBanner.featuredApp ? (heroBanner.featuredApp.category || "App") + " • Verified Flatpak" : ""
                                        font.pixelSize: 13
                                        color: "#dbeafe"
                                        Layout.fillWidth: true
                                    }
                                }

                                Button {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 42
                                    text: heroBanner.isInstalled ? "Open App" : "Install"

                                    background: Rectangle {
                                        radius: root.radiusPill
                                        color: heroBtnTap.pressed ? "#e2e8f0" : "#ffffff"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }
                                    contentItem: Label {
                                        text: parent.text
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: root.accent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    TapHandler {
                                        id: heroBtnTap
                                        onTapped: {
                                            if (!heroBanner.featuredApp) return
                                            if (heroBanner.isInstalled) {
                                                backend.openApp(heroBanner.featuredApp.packageId)
                                            } else {
                                                backend.installApp(heroBanner.featuredApp.packageId, heroBanner.featuredApp.name, heroBanner.featuredApp.icon)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Placeholder Message when no apps
                        Kirigami.PlaceholderMessage {
                            Layout.fillWidth: true
                            Layout.topMargin: Kirigami.Units.gridUnit * 4
                            visible: backend.apps.length === 0 && !backend.loading
                            icon.name: "applications-all"
                            text: "No apps found"
                            explanation: "Try a different category or search term."
                        }

                        // Skeleton Grid While Loading
                        GridView {
                            id: skeletonGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.ceil(8 / cols) * cellHeight
                            Layout.leftMargin: Kirigami.Units.largeSpacing * 1.5
                            Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                            visible: backend.loading
                            interactive: false
                            model: 8

                            readonly property int minCellW: Kirigami.Units.gridUnit * 12
                            readonly property int cols: Math.max(2, Math.floor(width / minCellW))
                            cellWidth: Math.floor(width / cols)
                            cellHeight: 220

                            delegate: Item {
                                width: skeletonGrid.cellWidth
                                height: skeletonGrid.cellHeight

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    radius: root.radiusLg
                                    color: root.bgSurface
                                    border.color: root.cardBorder

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: parent.radius
                                        clip: true

                                        Rectangle {
                                            id: shimmer
                                            width: parent.width
                                            height: parent.height
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0.0; color: "#00ffffff" }
                                                GradientStop { position: 0.5; color: "#40f1f5f9" }
                                                GradientStop { position: 1.0; color: "#00ffffff" }
                                            }
                                            SequentialAnimation on x {
                                                loops: Animation.Infinite
                                                NumberAnimation { from: -parent.width; to: parent.width; duration: 1100; easing.type: Easing.InOutSine }
                                                PauseAnimation { duration: 300 }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Modern App Grid
                        GridView {
                            id: appsGrid
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.ceil(model ? model.length / cols : 0) * cellHeight + 40
                            Layout.leftMargin: Kirigami.Units.largeSpacing * 1.5
                            Layout.rightMargin: Kirigami.Units.largeSpacing * 1.5
                            model: backend.apps
                            visible: !backend.loading && backend.apps.length > 0
                            interactive: false

                            readonly property int minCellW: Kirigami.Units.gridUnit * 12
                            readonly property int cols: Math.max(2, Math.floor(width / minCellW))
                            cellWidth: Math.floor(width / cols)
                            cellHeight: 230

                            add: Transition {
                                SequentialAnimation {
                                    PauseAnimation { duration: Math.min(index * 15, 200) }
                                    ParallelAnimation {
                                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                                        NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                                    }
                                }
                            }

                            delegate: Item {
                                id: delegateRoot
                                width: appsGrid.cellWidth
                                height: appsGrid.cellHeight

                                readonly property var status: backend.installationProgress[modelData.packageId] || {"installing": false, "progress": 0, "status": ""}
                                readonly property bool isInstalled: backend.installedApps.indexOf(modelData.packageId) !== -1

                                Rectangle {
                                    id: cardBody
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    radius: root.radiusLg
                                    color: cardTap.pressed ? root.bgCardPress : (cardHover.hovered ? root.bgCardHover : root.bgCard)
                                    border.color: cardHover.hovered ? root.accentLight : root.cardBorder
                                    border.width: 1

                                    scale: cardTap.pressed ? 0.98 : (cardHover.hovered ? 1.02 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        // Top Row: App Icon & Installed Badge
                                        RowLayout {
                                            Layout.fillWidth: true

                                            Rectangle {
                                                Layout.preferredWidth: 54
                                                Layout.preferredHeight: 54
                                                radius: root.radiusMd
                                                color: root.accentSoft

                                                Image {
                                                    anchors.centerIn: parent
                                                    width: 38; height: 38
                                                    source: modelData.icon || ""
                                                    fillMode: Image.PreserveAspectFit
                                                }
                                            }

                                            Item { Layout.fillWidth: true }

                                            // Status Badge Chip
                                            Rectangle {
                                                height: 22
                                                width: badgeText.implicitWidth + 14
                                                radius: root.radiusPill
                                                color: delegateRoot.isInstalled ? root.successSoft : root.bgBase
                                                border.color: delegateRoot.isInstalled ? root.success : root.divider
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Rectangle {
                                                        visible: delegateRoot.isInstalled
                                                        width: 6; height: 6; radius: 3
                                                        color: root.success
                                                    }
                                                    Label {
                                                        id: badgeText
                                                        text: delegateRoot.status.installing ? "Installing" : (delegateRoot.isInstalled ? "Installed" : "Free")
                                                        font.pixelSize: 10
                                                        font.bold: true
                                                        color: delegateRoot.isInstalled ? root.success : root.textMuted
                                                    }
                                                }
                                            }
                                        }

                                        // App Title
                                        Label {
                                            text: root.decodeHtml(modelData.name)
                                            font.bold: true
                                            font.pixelSize: 14
                                            color: root.textPrimary
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Category Tag
                                        Label {
                                            text: modelData.category || "Application"
                                            font.pixelSize: 11
                                            color: root.textMuted
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Installation Progress Bar
                                        Rectangle {
                                            Layout.fillWidth: true
                                            visible: delegateRoot.status.installing
                                            implicitHeight: 4
                                            radius: root.radiusPill
                                            color: root.divider

                                            Rectangle {
                                                height: parent.height
                                                radius: parent.radius
                                                width: parent.width * delegateRoot.status.progress
                                                color: root.accent
                                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                            }
                                        }

                                        Item { Layout.fillHeight: true }

                                        // Action Button
                                        Button {
                                            id: cardActionBtn
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 32
                                            text: delegateRoot.isInstalled ? "Open" : (delegateRoot.status.installing ? "Installing…" : "Install")
                                            enabled: !delegateRoot.status.installing

                                            background: Rectangle {
                                                radius: root.radiusPill
                                                color: delegateRoot.isInstalled
                                                       ? root.accentSoft
                                                       : (cardActionBtn.pressed ? root.accentDark : root.accent)
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                            }
                                            contentItem: Label {
                                                text: cardActionBtn.text
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

                                    HoverHandler { id: cardHover }
                                    TapHandler {
                                        id: cardTap
                                        onTapped: root.openAppDetails(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- App Details Overlay Sheet ----
    Kirigami.OverlaySheet {
        id: detailSheet
        title: root.selectedApp ? root.decodeHtml(root.selectedApp.name) : ""

        readonly property bool isInstalled: root.selectedApp ? backend.installedApps.indexOf(root.selectedApp.packageId) !== -1 : false
        readonly property var appProgress: root.selectedApp ? (backend.installationProgress[root.selectedApp.packageId] || {"installing": false, "progress": 0, "status": ""}) : {"installing": false, "progress": 0, "status": ""}

        ColumnLayout {
            width: Math.min(root.width * 0.8, 540)
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 80
                    radius: root.radiusLg
                    color: root.accentSoft

                    Image {
                        anchors.centerIn: parent
                        width: 56; height: 56
                        source: root.selectedApp ? (root.selectedApp.icon || "") : ""
                        fillMode: Image.PreserveAspectFit
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: root.selectedApp ? root.decodeHtml(root.selectedApp.name) : ""
                        font.pixelSize: 20
                        font.bold: true
                        color: root.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Label {
                        text: root.selectedApp ? root.selectedApp.packageId : ""
                        font.pixelSize: 12
                        color: root.textMuted
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        height: 22
                        width: catDetailLabel.implicitWidth + 14
                        radius: root.radiusPill
                        color: root.bgBase
                        border.color: root.divider
                        border.width: 1

                        Label {
                            id: catDetailLabel
                            anchors.centerIn: parent
                            text: root.selectedApp ? (root.selectedApp.category || "Application") : "App"
                            font.pixelSize: 11
                            color: root.textMuted
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.divider
            }

            // Action Row: Install / Launch / Uninstall
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.mediumSpacing

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: detailSheet.isInstalled ? "Launch Application" : (detailSheet.appProgress.installing ? "Installing…" : "Install Application")
                    enabled: !detailSheet.appProgress.installing

                    background: Rectangle {
                        radius: root.radiusPill
                        color: detailSheet.isInstalled ? root.accentSoft : root.accent
                    }
                    contentItem: Label {
                        text: parent.text
                        font.pixelSize: 13
                        font.bold: true
                        color: detailSheet.isInstalled ? root.accent : "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (!root.selectedApp) return
                        if (detailSheet.isInstalled) {
                            backend.openApp(root.selectedApp.packageId)
                        } else {
                            backend.installApp(root.selectedApp.packageId, root.selectedApp.name, root.selectedApp.icon)
                        }
                    }
                }

                Button {
                    visible: detailSheet.isInstalled
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 40
                    text: "Uninstall"

                    background: Rectangle {
                        radius: root.radiusPill
                        color: "#fef2f2"
                        border.color: "#fca5a5"
                        border.width: 1
                    }
                    contentItem: Label {
                        text: parent.text
                        font.pixelSize: 12
                        font.bold: true
                        color: "#dc2626"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (!root.selectedApp) return
                        backend.uninstallApp(root.selectedApp.packageId)
                        detailSheet.close()
                    }
                }
            }

            // Detail information
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    text: "Package Details"
                    font.bold: true
                    font.pixelSize: 13
                    color: root.textPrimary
                }

                Label {
                    text: "Source: Flathub (Flatpak)\nApplication ID: " + (root.selectedApp ? root.selectedApp.packageId : "")
                    font.pixelSize: 12
                    color: root.textMuted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
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

    // Slim top progress bar indicator when loading
    Rectangle {
        id: progressContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: "transparent"
        visible: backend.loading
        z: 999

        Rectangle {
            anchors.fill: parent
            color: root.divider
        }
        Rectangle {
            id: progressBar
            width: progressContainer.width * 0.35
            height: parent.height
            color: root.accent
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { from: -progressBar.width; to: progressContainer.width; duration: 900; easing.type: Easing.InOutQuad }
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
        backend.fetchApps("all")
    }
}