using System;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The bridge between the docking system and the application, which is what decides whether a
/// floating panel is a REAL window or an overlay drawn inside the main one.
///
/// Implement it on the application and hand it to the dock manager.
///
/// COORDINATES are logical pixels relative to the main window's client area, and sizes are
/// logical pixels, so nothing here needs to know about display scaling.
interface IDockableWindowHost
{
	/// Whether this host can make real windows at all. A web or console host cannot.
	bool SupportsOSWindows();

	/// Whether the windows it makes carry NATIVE chrome.
	///
	/// False, the default, means borderless: the panel draws its own title bar and close button
	/// and the application moves and resizes the window. True hands move, resize and close to
	/// the system, so the docking layer suppresses its own close button and inner resize edges,
	/// and a drag from the panel's header re-docks WITHOUT the window chasing the cursor.
	///
	/// Linux hosts default to chromed, because Wayland punishes application positioned
	/// borderless windows and XWayland blocks dragging one between monitors.
	bool UsesOSChrome() => false;

	/// CONSUMES onCloseRequested, which fires when the system's own close button is used.
	void CreateDockableWindow(View dockableWindow, float width, float height, float x, float y,
		delegate void(View) onCloseRequested = null);

	void DestroyDockableWindow(View dockableWindow);

	void MoveDockableWindow(View dockableWindow, float x, float y);

	void ResizeDockableWindow(View dockableWindow, float x, float y, float width, float height);

	/// The window's current position and size. False when this view is not hosted in one.
	bool TryGetDockableWindowBounds(View dockableWindow, out float x, out float y,
		out float width, out float height);

	/// Where the pointer is on the whole desktop, which a drag between windows needs and a
	/// window relative position cannot give.
	void GetGlobalMousePosition(out float globalX, out float globalY);
}
