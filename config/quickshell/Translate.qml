// Translate.qml — popup translator over bin/translate.sh
// Standalone: qs -p ~/ledot/config/quickshell/Translate.qml
// Enter: translate + copy · Submit: translate + copy + close · Esc/mod+q: close
// Translation is copied to the clipboard (wl-copy) as soon as it arrives
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/ledot/bin/translate.sh"
    readonly property color bg: "#181818"
    readonly property color fg: "#d8d8d8"
    readonly property color field: "#282828"
    readonly property color dim: "#808080"

    // Close after the pending translation lands (Submit button)
    property bool quitWhenDone: false
    // Input/target of the last successful translation, to skip re-running it on Submit
    property string lastKey

    function key() {
        return input.text.trim() + "\u0000" + (target.text.trim() || "pt-BR");
    }

    function translate() {
        const text = input.text.trim();
        if (!text || proc.running)
            return;
        output.text = "Translating…";
        proc.key = root.key();
        proc.out = "";
        proc.err = "";
        proc.command = [root.script, text];
        proc.running = true;
    }

    function submit() {
        if (!input.text.trim() || root.lastKey === root.key()) {
            Qt.quit();
            return;
        }
        root.quitWhenDone = true;
        root.translate();
    }

    FloatingWindow {
        title: "Translate"
        // Closed by the compositor (mod+q): end the process too, not just the window
        onClosed: Qt.quit()
        implicitWidth: 520
        implicitHeight: 260
        color: root.bg

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 4
                    color: root.field

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.fg
                        font.family: "monospace"
                        clip: true
                        focus: true
                        Keys.onReturnPressed: root.translate()
                        Keys.onEnterPressed: root.translate()
                        Keys.onEscapePressed: Qt.quit()

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Text to translate…"
                            color: root.dim
                            font: input.font
                            visible: !input.text
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 32
                    radius: 4
                    color: root.field

                    TextInput {
                        id: target
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        text: "pt-BR"
                        color: root.fg
                        font.family: "monospace"
                        clip: true
                        Keys.onReturnPressed: root.translate()
                        Keys.onEnterPressed: root.translate()
                        Keys.onEscapePressed: Qt.quit()
                    }
                }

                Rectangle {
                    implicitWidth: 72
                    implicitHeight: 32
                    radius: 4
                    color: submitArea.containsMouse ? Qt.lighter(root.field, 1.4) : root.field

                    Text {
                        anchors.centerIn: parent
                        text: "Submit"
                        color: root.fg
                        font.family: "monospace"
                    }

                    MouseArea {
                        id: submitArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 4
                color: root.field

                TextEdit {
                    id: output
                    anchors.fill: parent
                    anchors.margins: 8
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    color: root.fg
                    font.family: "monospace"
                    Keys.onEscapePressed: Qt.quit()
                }
            }
        }
    }

    Process {
        id: proc
        // stdout wins; stderr (trans notices/errors, ANSI-colored) only shows when there is no result
        property string out
        property string err
        property string key

        function show() {
            output.text = out || err.replace(/\x1b\[[0-9;]*m/g, "") || "Translating…";
        }

        environment: ({ TO: target.text.trim() || "pt-BR" })
        stdout: StdioCollector {
            onStreamFinished: {
                proc.out = this.text.trim();
                proc.show();
                if (!proc.out) {
                    root.quitWhenDone = false;  // failed: stay open to show the error
                    return;
                }
                Quickshell.execDetached(["wl-copy", proc.out]);
                root.lastKey = proc.key;
                if (root.quitWhenDone)
                    Qt.quit();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: { proc.err = this.text.trim(); proc.show(); }
        }
    }
}
