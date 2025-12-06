import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 500
    WindowDialogTitle {
        text: Translation.tr("Idle Inhibitor")
        Layout.alignment: Qt.AlignHCenter
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16
        anchors.margins: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                
                StyledText {
                    text: Translation.tr("Inhibit Idle")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: 600
                }
                StyledText {
                    text: Translation.tr("Prevent screen sleep")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.7
                }
            }

            ConfigSwitch {
                id: inhibitSwitch
                checked: Idle.inhibit
                onCheckedChanged: Idle.toggleInhibit(checked)
            }
        }

        // --- 2. Settings Card ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: settingsColumn.implicitHeight + 32
            
            // Inset Background
            color: Qt.rgba(0, 0, 0, 0.25) 
            radius: 16
            
            // Dim if disabled
            opacity: inhibitSwitch.checked ? 1.0 : 0.5
            enabled: inhibitSwitch.checked
            Behavior on opacity { NumberAnimation { duration: 200 } }

            ColumnLayout {
                id: settingsColumn
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 24

                // A. Mode Selection
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Mode")
                        font.weight: 600
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Item { Layout.fillWidth: true }
                    
                    ComboBox {
                        id: modeSelection
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 36
                        
                        model: [ 
                            Translation.tr("Timer"), 
                            Translation.tr("Indefinite"),
                            Translation.tr("Until Time") 
                        ]
                        
                        currentIndex: Persistent.states.idle.mode 
                        onActivated: index => {
                            Persistent.states.idle.mode = index
                            if (index === 2) applyTargetTime() // Calc immediately on switch
                        }
                        Component.onCompleted: currentIndex = Persistent.states.idle.mode

                        // Custom Dropdown Styling
                        background: Rectangle {
                            color: Appearance.colors.colLayer1
                            radius: 12
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                        }
                        contentItem: Item {
                            anchors.fill: parent
                            StyledText {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                text: modeSelection.displayText
                                font.weight: 500
                                color: Appearance.colors.colOnSurface
                            }
                        }
                        indicator: Canvas {
                            x: modeSelection.width - width - 12
                            y: modeSelection.topPadding + (modeSelection.availableHeight - height) / 2
                            width: 10
                            height: 6
                            contextType: "2d"
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(width, 0);
                                ctx.lineTo(width / 2, height);
                                ctx.closePath();
                                ctx.fillStyle = Appearance.colors.colOnSurfaceVariant;
                                ctx.fill();
                            }
                        }
                        popup: Popup {
                            y: modeSelection.height + 5
                            width: modeSelection.width
                            implicitHeight: contentItem.implicitHeight + 10
                            padding: 5
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: modeSelection.popup.visible ? modeSelection.delegateModel : null
                                currentIndex: modeSelection.highlightedIndex
                                ScrollIndicator.vertical: ScrollIndicator { }
                            }
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                border.color: Qt.rgba(1,1,1,0.1)
                                radius: 12
                            }
                        }
                        delegate: ItemDelegate {
                            width: parent.width
                            height: 36
                            highlighted: modeSelection.highlightedIndex === index
                            contentItem: StyledText {
                                text: modelData
                                color: highlighted ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                                font.weight: highlighted ? 600 : 400
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                            background: Rectangle {
                                color: highlighted ? Appearance.colors.colPrimary : "transparent"
                                radius: 8
                            }
                        }
                    }
                }

                // B. Timer Mode UI (Presets + Slider)
                ColumnLayout {
                    visible: modeSelection.currentIndex === 0 
                    Layout.fillWidth: true
                    spacing: 16

                    // Preset Chips
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        property var options: [
                            { label: "30m", val: 1800 },
                            { label: "1h",  val: 3600 },
                            { label: "2h",  val: 7200 },
                            { label: "4h",  val: 14400 },
                            { label: "Work", val: 28800 } // 8 hours
                        ]

                        Repeater {
                            model: parent.options
                            delegate: Rectangle {
                                id: chip
                                Layout.preferredHeight: 32
                                Layout.fillWidth: true
                                radius: 16
                                
                                property bool isActive: Math.abs(Persistent.states.idle.durationSeconds - modelData.val) < 10

                                color: isActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                border.color: isActive ? "transparent" : Qt.rgba(1,1,1,0.1)
                                border.width: 1

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.weight: 600
                                    color: chip.isActive ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Persistent.states.idle.durationSeconds = modelData.val
                                }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }

                    // Slider Section
                    ColumnLayout {
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            StyledText {
                                text: Translation.tr("Duration")
                                font.weight: 600
                            }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: formatTime(durationSlider.value)
                                font.weight: 700
                                color: Appearance.colors.colPrimary
                            }
                        }

                        Slider {
                            id: durationSlider
                            Layout.fillWidth: true
                            from: 60
                            to: 28800 // Extended to 8 hours
                            stepSize: 60
                            value: Persistent.states.idle.durationSeconds
                            onMoved: Persistent.states.idle.durationSeconds = value

                            handle: Rectangle {
                                x: durationSlider.leftPadding + durationSlider.visualPosition * (durationSlider.availableWidth - width)
                                y: durationSlider.topPadding + durationSlider.availableHeight / 2 - height / 2
                                implicitWidth: 6; implicitHeight: 32
                                radius: 4
                                color: Appearance.colors.colOnSurface
                                border.color: Qt.rgba(0,0,0,0.1)
                            }
                            background: Rectangle {
                                x: durationSlider.leftPadding
                                y: durationSlider.topPadding + durationSlider.availableHeight / 2 - height / 2
                                implicitHeight: 24
                                width: durationSlider.availableWidth; height: implicitHeight
                                radius: 12
                                color: Qt.rgba(1, 1, 1, 0.1) 
                                Rectangle {
                                    width: durationSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Appearance.colors.colPrimary
                                    radius: 12
                                }
                            }
                        }
                    }
                }

                // C. Until Time Mode UI (Custom Time Picker)
                ColumnLayout {
                    visible: modeSelection.currentIndex === 2
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        StyledText {
                            text: Translation.tr("End Time")
                            font.weight: 600
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            // Live calculation feedback
                            text: {
                                let d = new Date();
                                let target = new Date();
                                target.setHours(hourSpin.value);
                                target.setMinutes(minuteSpin.value);
                                target.setSeconds(0);
                                if (target <= d) target.setDate(target.getDate() + 1);
                                let diff = (target - d) / 1000;
                                return "(" + formatTime(diff) + ")"
                            }
                            color: Appearance.colors.colPrimary
                            font.weight: 700
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        // Custom Hour Spinner
                        Control {
                            id: hourSpin
                            property int value: new Date().getHours()
                            onValueChanged: applyTargetTime()
                            Layout.preferredWidth: 80; Layout.preferredHeight: 46
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: 12
                                border.color: Qt.rgba(1,1,1,0.1)
                            }
                            contentItem: StyledText {
                                text: (hourSpin.value < 10 ? "0" : "") + hourSpin.value
                                font.pixelSize: 20; font.weight: 700
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onWheel: (wheel) => {
                                    if (wheel.angleDelta.y > 0) hourSpin.value = (hourSpin.value + 1) % 24
                                    else hourSpin.value = (hourSpin.value - 1 + 24) % 24
                                }
                            }
                        }

                        StyledText { text: ":"; font.pixelSize: 20; font.weight: 700; color: Appearance.colors.colOnSurfaceVariant }

                        // Custom Minute Spinner
                        Control {
                            id: minuteSpin
                            property int value: 0
                            onValueChanged: applyTargetTime()
                            Layout.preferredWidth: 80; Layout.preferredHeight: 46
                            background: Rectangle {
                                color: Appearance.colors.colLayer1
                                radius: 12
                                border.color: Qt.rgba(1,1,1,0.1)
                            }
                            contentItem: StyledText {
                                text: (minuteSpin.value < 10 ? "0" : "") + minuteSpin.value
                                font.pixelSize: 20; font.weight: 700
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onWheel: (wheel) => {
                                    let step = 5; 
                                    if (wheel.angleDelta.y > 0) minuteSpin.value = (minuteSpin.value + step) % 60
                                    else minuteSpin.value = (minuteSpin.value - step + 60) % 60
                                }
                            }
                        }
                    }
                }

                // D. Keep Screen On Toggle
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Translation.tr("Keep Screen On")
                        font.weight: 600
                        Layout.fillWidth: true
                    }
                    ConfigSwitch {
                        checked: Persistent.states.idle.keepScreenOn
                        onCheckedChanged: Persistent.states.idle.keepScreenOn = checked
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // Spacer

        // --- 3. Status Footer ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "transparent"
            // Show only if Inhibitor is Active AND we are in Timer/Time Mode
            visible: Idle.inhibit && Persistent.states.idle.mode !== 1 && Idle.timeRemaining > 0

            RowLayout {
                anchors.fill: parent
                spacing: 10
                StyledText {
                    text: Translation.tr("Remaining:")
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    text: formatTime(Idle.timeRemaining)
                    font.weight: 700
                    color: Appearance.colors.colPrimary
                }
                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: Persistent.states.idle.durationSeconds
                    value: Idle.timeRemaining
                    background: Rectangle {
                        implicitHeight: 6
                        color: Qt.rgba(1,1,1,0.1)
                        radius: 3
                    }
                    contentItem: Item {
                        implicitHeight: 6
                        Rectangle {
                            width: parent.parent.visualPosition * parent.width
                            height: parent.height
                            radius: 3
                            color: Appearance.colors.colPrimary
                        }
                    }
                }
            }
        }
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Close")
            onClicked: root.dismiss()
        }
    }

    // --- Helper Functions ---

    function formatTime(seconds) {
        let m = Math.floor(seconds / 60);
        let h = Math.floor(m / 60);
        m = m % 60;
        if (h > 0) return h + "h " + (m < 10 ? "0" + m : m) + "m";
        return m + "m";
    }

    function applyTargetTime() {
        if (modeSelection.currentIndex !== 2) return;

        let now = new Date();
        let target = new Date();
        
        target.setHours(hourSpin.value);
        target.setMinutes(minuteSpin.value);
        target.setSeconds(0);

        // If time is in the past, assume it means tomorrow
        if (target <= now) {
            target.setDate(target.getDate() + 1);
        }

        let diffSeconds = Math.floor((target - now) / 1000);
        Persistent.states.idle.durationSeconds = diffSeconds;
    }
}
