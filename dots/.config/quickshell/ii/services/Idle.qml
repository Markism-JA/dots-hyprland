pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Singleton {
    id: root

    // ERROR FIXED: Removed the invalid deep aliases.
    // We will read these directly from Persistent in the functions below.

    // Internal State
    property bool inhibit: false
    property int timeRemaining: 0

    // Enums
    enum IdleMode {
        Timer,
        Indefinite
    }

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                // Restore the state from JSON
                root.toggleInhibit(Persistent.states.idle.inhibit);
            } else {
                // Reset to false on fresh boot
                Persistent.states.idle.inhibit = false;
                root.inhibit = false;
            }
        }
    }

    function toggleInhibit(enable) {
        if (enable === undefined) enable = !inhibit

        inhibit = enable
        
        // Sync the state back to JSON
        Persistent.states.idle.inhibit = enable

        if (inhibit) {
            // FIX: Access Persistent directly here instead of using aliases
            // 0 = Timer Mode
            if (Persistent.states.idle.mode === root.IdleMode.Timer) {
                timeRemaining = Persistent.states.idle.durationSeconds
                countdownTimer.start()
            }

            // FIX: Check Persistent directly for screen preference
            if (Persistent.states.idle.keepScreenOn) {
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
            // FIX: Check Persistent directly here
            if (root.inhibit && !Persistent.states.idle.keepScreenOn) {
                root.toggleInhibit(false)
            }
        }
    }
}
