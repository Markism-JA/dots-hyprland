import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 400 // Adjusted height for idle inhibitor settings

    WindowDialogTitle {
        text: Translation.tr("Idle Inhibitor Settings")
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal
        
        ConfigSwitch {
            id: inhibitSwitch
            text: Translation.tr("Enable Idle Inhibition")
            checked: Idle.inhibit
            onCheckedChanged: Idle.toggleInhibit(checked)
        }

        WindowDialogSeparator { Layout.fillWidth: true }

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Mode")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: 600
        }

        SelectionGroupButton {
            id: modeSelection
            Layout.fillWidth: true
            model: [
                { text: Translation.tr("Timer"), value: Idle.IdleMode.Timer },
                { text: Translation.tr("Indefinite"), value: Idle.IdleMode.Indefinite }
            ]
            currentIndex: Idle.mode
            onCurrentIndexChanged: Idle.mode = currentIndex
            enabled: inhibitSwitch.checked // Only allow changing mode if inhibition is enabled
        }

        ConfigSpinBox {
            id: durationSpinBox
            Layout.fillWidth: true
            visible: modeSelection.currentIndex === Idle.IdleMode.Timer
            enabled: inhibitSwitch.checked && visible
            text: Translation.tr("Duration (seconds)")
            value: Idle.durationSeconds
            from: 10
            to: 3600
            stepSize: 10
            onValueChanged: Idle.durationSeconds = value
        }

        ConfigSwitch {
            id: keepScreenOnSwitch
            text: Translation.tr("Keep Screen On")
            checked: Idle.keepScreenOn
            onCheckedChanged: Idle.keepScreenOn = checked
            enabled: inhibitSwitch.checked
        }

        WindowDialogSeparator { Layout.fillWidth: true }

        StyledText {
            id: timeRemainingText
            Layout.fillWidth: true
            visible: Idle.inhibit && Idle.mode === Idle.IdleMode.Timer && Idle.timeRemaining > 0
            text: Translation.tr("Time Remaining: %1s").arg(Idle.timeRemaining)
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurfaceVariant
        }
        
        Item {
            Layout.fillHeight: true
        }
    }

    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}