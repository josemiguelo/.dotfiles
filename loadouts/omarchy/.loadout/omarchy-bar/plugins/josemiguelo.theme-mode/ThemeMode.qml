import QtQuick
import Quickshell.Io
import qs.Commons as Commons
import qs.Ui

// Whether the current Omarchy theme is dark or light, as omarchy-theme-color
// reads it (the mode omarchy-theme-set hands GTK), shown as Material Design's
// dark or light mode glyph (night light's moon and the weather's sun are
// taken), drawn by BarIconButton like every bar icon, at the bar's icon size.
// A click runs omarchy-theme-mode-toggle, which switches to the machine's
// theme of the other mode (omarchy-theme-mode, in the dotfiles).
BarWidget {
  id: root
  moduleName: "josemiguelo.theme-mode"

  property string mode: ""

  // A theme switch recolours the shell, so a new background is when the
  // mode is read again.
  readonly property color themeBackground: Commons.Color.background
  onThemeBackgroundChanged: modeProc.running = true
  Component.onCompleted: modeProc.running = true

  Process {
    id: modeProc
    command: ["omarchy-theme-color", "mode"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.mode = text.trim()
    }
  }

  visible: mode !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.mode === "" ? "" : root.mode === "light" ? "󰃠" : "󰃞"
    tooltipText: root.mode === "light" ? "Light theme (click for dark)" : "Dark theme (click for light)"
    onPressed: function() {
      if (!root.bar) return
      root.bar.run("omarchy-theme-mode-toggle")
    }
  }
}
