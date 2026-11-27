import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui

// The layout of the focused workspace, by name (dwindle, master, scrolling,
// floating), drawn by WidgetButton like the bar's other text, at its body
// size. A click runs Omarchy's toggle, the one on SUPER + L. Floating is not a
// Hyprland layout, so the mode is read the way
// omarchy-hyprland-workspace-layout-current reads it: the workspace's file
// the toggle writes, else the default layout's file, else the tiledLayout
// Hyprland reports.
BarWidget {
  id: root
  moduleName: "josemiguelo.workspace-layout"

  readonly property var workspace: Hyprland.focusedWorkspace
  readonly property int workspaceId: workspace ? workspace.id : -1
  readonly property string tiledLayout: {
    var ipc = workspace ? workspace.lastIpcObject : null
    return ipc && ipc.tiledLayout ? String(ipc.tiledLayout) : ""
  }
  readonly property string modesDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/workspace-layouts"
  property string savedMode: ""
  property string defaultMode: ""
  // Named workspaces (negative ids) have no mode file.
  readonly property string layout: tiledLayout === "" ? "" : workspaceId >= 1 ? (savedMode || defaultMode || tiledLayout) : tiledLayout

  function modeIn(text, key) {
    var match = String(text || "").match(new RegExp(key + ' = "([a-z]*)"'))
    return match ? match[1] : ""
  }

  FileView {
    id: modeFile
    path: root.workspaceId >= 1 ? root.modesDir + "/" + root.workspaceId + ".lua" : ""
    watchChanges: true
    printErrors: false
    onLoaded: root.savedMode = root.modeIn(text(), "mode")
    onLoadFailed: root.savedMode = ""
    onFileChanged: reload()
  }

  FileView {
    id: defaultFile
    path: root.modesDir + "/default.lua"
    watchChanges: true
    printErrors: false
    onLoaded: root.defaultMode = root.modeIn(text(), "default")
    onLoadFailed: root.defaultMode = ""
    onFileChanged: reload()
  }

  // A workspace rule changing the layout raises no Hyprland event, and a mode
  // file the toggle creates or deletes is not one a watch sees, so both are
  // re-read on a short interval: a request on Hyprland's socket and two small
  // file reads, not a process.
  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      Hyprland.refreshWorkspaces()
      if (modeFile.path !== "") modeFile.reload()
      defaultFile.reload()
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event && event.name ? String(event.name) : ""
      if (name === "workspace" || name === "focusedmon" || name === "configreloaded") Hyprland.refreshWorkspaces()
    }
  }

  Timer {
    id: afterToggle
    interval: 150
    onTriggered: {
      Hyprland.refreshWorkspaces()
      if (modeFile.path !== "") modeFile.reload()
    }
  }

  visible: layout !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.layout
    tooltipText: root.workspace ? "Workspace " + root.workspace.name + ": " + root.layout + " (click cycles)" : ""
    onPressed: function() {
      if (!root.bar) return
      root.bar.run("omarchy-hyprland-workspace-layout-toggle")
      afterToggle.restart()
    }
  }
}
