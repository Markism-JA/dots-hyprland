pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property alias mode: Persistent.states.idle.mode
    property alias keepScreenOn: Persistent.states.idle.keepScreenOn
    property alias durationSeconds: Persistent.states.idle.durationSeconds

    property bool inhibit: false
    property int timeRemaining: 0

    enum IdleMode {
        Timer,
        Indefinite
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                root.toggleInhibit(Persistent.states.idle.inhibit);
            } else {
                Persistent.states.idle.inhibit = false;
                root.inhibit = false;
            }
        }
    }

    function toggleInhibit(enable) {
        if (enable === undefined) enable = !inhibit

        inhibit = enable

        Persistent.states.idle.inhibit = enable

        if (inhibit) {
            if (mode === root.IdleMode.Timer) {
                timeRemaining = durationSeconds
                countdownTimer.start()
            }

            if (keepScreenOn) {
                idleInhibitor.enabled = true
                systemdInhibitor.running = false
            } else {
                idleInhibitor.enabled = false
                systemdInhibitor.running = true
            }
        } else {
            countdownTimer.stop()
            idleInhibitor.enabled = false
            systemdInhibitor.running = false
            timeRemaining = 0
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            root.timeRemaining -= 1
            if (root.timeRemaining <= 0) {
                root.toggleInhibit(false)
            }
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }

    Process {
        id: systemdInhibitor
        command: ["systemd-inhibit", "--what=sleep", "--who=Quickshell", "--why=UserRequest", "sleep", "infinity"]
        running: false
        onExited: {
            if (root.inhibit && !root.keepScreenOn) root.toggleInhibit(false)
        }
    }
}
