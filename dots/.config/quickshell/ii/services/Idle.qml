pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Singleton {
    id: root

    property bool inhibit: false
    property int timeRemaining: 0

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
            if (Persistent.states.idle.mode === 0) {
                timeRemaining = Persistent.states.idle.durationSeconds
                countdownTimer.start()
            }

            if (Persistent.states.idle.keepScreenOn) {
                idleInhibitor.enabled = true
                systemdInhibitor.running = false

                console.log("idleInhibitor:", idleInhibitor.enabled, "| systemdInhibitor:", systemdInhibitor.running)
            } else {
                idleInhibitor.enabled = false
                systemdInhibitor.running = true

                console.log("idleInhibitor:", idleInhibitor.enabled, "| systemdInhibitor:", systemdInhibitor.running)
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
    }

    IdleInhibitor {
        id: idleInhibitor
        enabled: false
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
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
            if (root.inhibit && !Persistent.states.idle.keepScreenOn) {
                root.toggleInhibit(false)
            }
        }
    }
}
