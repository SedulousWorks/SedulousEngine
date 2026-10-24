namespace Sedulous.GUI;

// GUI.Docking: docking: splits, tab groups, drop zones, floating panels in the window and as OS
// windows (through hosting), layouts saved and restored, and its default sheet. foundation.ui's
// counterpart: UI.Toolkit's docking and UI.Application. Round three of the GUI's evolution
// (Specs/gui-lab-evolution-3.md): D, after its survey. Docking is the whole feature (ruling 3), so it
// links hosting for its floats' OS windows (D6), where foundation.ui puts them in UI.Application
// above its toolkit.
//
// DockLayout.bf (D1): the layout as data and its operations. DockDocument.bf (D2): the layout as the
// serializer reads and writes it. DockController.bf (D3): the layout and its panels. DockSpace.bf
// (D3): the widget that shows a surface, and docking's sheet and commands. DockArea.bf (D5): the main
// surface and the floating ones over it, in one window. DockHostWindows.bf (D6): the floats in OS
// windows the host opens. Its widgets' reflection is their [GuiReflect] and [GuiProperty]
// attributes (DockSpace's bands and torn tab, what a sheet sets on it).
