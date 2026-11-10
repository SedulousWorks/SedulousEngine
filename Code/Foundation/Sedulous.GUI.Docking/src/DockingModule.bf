namespace Sedulous.GUI;

// GUI.Docking: docking: splits, tab groups, drop zones, floating panels in the window and as OS
// windows (through hosting), layouts saved and restored, and its default sheet. foundation.ui's
// counterpart: UI.Toolkit's docking and UI.Application. Docking is the whole feature, so it links
// hosting for its floats' OS windows, where foundation.ui puts them in UI.Application above its
// toolkit.
//
// DockLayout.bf: the layout as data and its operations. DockDocument.bf: the layout as the
// serializer reads and writes it. DockController.bf: the layout and its panels. DockSpace.bf: the
// widget that shows a surface, and docking's sheet and commands. DockArea.bf: the main surface and
// the floating ones over it, in one window. DockHostWindows.bf: the floats in OS windows the host
// opens. Its widgets' reflection is their [GuiReflect] and [GuiProperty]
// attributes (DockSpace's bands and torn tab, what a sheet sets on it).
