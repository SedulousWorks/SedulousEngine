using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.Shell;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Application;

/// The docking system's host, implemented on the runtime's multi window graphics host.
///
/// A dock manager's floating panels become REAL OS windows: each gets a [[RenderWindow]] from
/// the application host and its own [[RootView]] attached to the shared [[UIHost]], OS chromed
/// on Linux and borderless with application drawn chrome elsewhere.
///
/// Assign it once and the docking layer needs to know nothing about windows:
///   dockManager.DockableWindowHost = host;
///
/// This is the ONLY UI module that pulls in the toolkit, which is what keeps docking out of
/// games (they never link it) and out of the toolkit free shell and runtime layers.
class RuntimeDockableWindowHost : IDockableWindowHost
{
	private class Entry
	{
		/// BORROWED: the root view owns it.
		public View View = null;
		/// BORROWED: the application host owns it.
		public RenderWindow Window = null;
		/// OWNED.
		public RootView Root = null;
		/// OWNED.
		public delegate void(View) OnClose = null;

		public ~this()
		{
			if (Root != null)
				Root.ReleaseRef();

			if (OnClose != null)
				delete OnClose;
		}
	}

	/// BORROWED.
	private IApplicationHost mHost;
	/// BORROWED: the application owns it.
	private UIHost mUIHost;
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	// Drag follow state: the OS window being dragged and where the cursor sat on it at grab.
	private RenderWindow mDragWindow = null;
	private float mDragOffsetX = 0.0f;
	private float mDragOffsetY = 0.0f;

	/// An explicit chrome ruling, for a test or a user setting. Unset means the platform
	/// default.
	private bool? mOSChromeOverride = null;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUIHost = uiHost;
	}

	public bool SupportsOSWindows() => true;

	public bool UsesOSChrome()
	{
		if (mOSChromeOverride.HasValue)
			return mOSChromeOverride.Value;

		if ((mHost != null) && (mHost.Shell != null) && (mHost.Shell.MainWindow != null))
			return DockableChromePolicy.PrefersOSChrome(mHost.Shell.MainWindow.Native.System);

		return false;
	}

	public void SetOSChromeOverride(bool value) => mOSChromeOverride = value;

	/// CONSUMES onCloseRequested.
	public void CreateDockableWindow(View dockableWindow, float width, float height, float x,
		float y, delegate void(View) onCloseRequested = null)
	{
		if ((dockableWindow == null) || (mHost == null))
		{
			if (onCloseRequested != null)
				delete onCloseRequested;

			return;
		}

		MainOrigin(var mainX, var mainY);

		// A chromed window shows a real title bar, so the panel's title has to reach the shell.
		let title = scope String("Panel");
		if (let floatingWindow = dockableWindow as DockableWindow)
		{
			if ((floatingWindow.Panel != null) && !floatingWindow.Panel.Title.IsEmpty)
				title.Set(floatingWindow.Panel.Title);
		}

		WindowSettings settings = .();
		settings.Title = title;
		settings.Width = (uint32)Math.Max(width, 1.0f);
		settings.Height = (uint32)Math.Max(height, 1.0f);
		settings.Positioned = true;
		settings.X = mainX + (int32)x;
		settings.Y = mainY + (int32)y;
		// Borderless: the panel draws its own title bar. Chromed: the system provides the title
		// bar, the close button and the resize borders.
		settings.Borderless = !UsesOSChrome();
		settings.Resizable = true;

		let window = mHost.OpenWindow(settings, RenderWindowDesc());
		if (window == null)
		{
			if (onCloseRequested != null)
				delete onCloseRequested;

			return;
		}

		// The window's root view OWNS the dockable window view; the dock manager keeps only a
		// borrowed reference to it.
		let root = new RootView();
		root.AddView(dockableWindow);
		mUIHost.AttachWindow(window, root);

		let entry = new Entry();
		entry.View = dockableWindow;
		entry.Window = window;
		entry.Root = root;
		entry.OnClose = onCloseRequested;
		mEntries.Add(entry);
	}

	public void DestroyDockableWindow(View dockableWindow)
	{
		for (int i < mEntries.Count)
		{
			if (mEntries[i].View != dockableWindow)
				continue;

			let window = mEntries[i].Window;
			// A LOGICAL detach: the payload stays alive for the window's own teardown.
			mUIHost.DetachWindow(window);
			// Deferred: the render window's destructor waits for the GPU before freeing it.
			mHost.CloseWindow(window);

			delete mEntries[i];
			mEntries.RemoveAt(i);
			return;
		}
	}

	public void MoveDockableWindow(View dockableWindow, float x, float y)
	{
		let entry = Find(dockableWindow);
		if (entry == null)
			return;

		MainOrigin(var mainX, var mainY);
		// ATOMIC: a per axis write races on an asynchronous window system.
		entry.Window.Window.SetPosition(mainX + (int32)x, mainY + (int32)y);
	}

	public void ResizeDockableWindow(View dockableWindow, float x, float y, float width,
		float height)
	{
		let entry = Find(dockableWindow);
		if (entry == null)
			return;

		MainOrigin(var mainX, var mainY);
		entry.Window.Window.SetPosition(mainX + (int32)x, mainY + (int32)y);
		entry.Window.Window.SetSize((uint32)Math.Max(width, 1.0f), (uint32)Math.Max(height, 1.0f));
	}

	public bool TryGetDockableWindowBounds(View dockableWindow, out float x, out float y,
		out float width, out float height)
	{
		x = 0.0f;
		y = 0.0f;
		width = 0.0f;
		height = 0.0f;

		let entry = Find(dockableWindow);
		if (entry == null)
			return false;

		MainOrigin(var mainX, var mainY);
		let window = entry.Window.Window;
		x = (float)(window.X - mainX);
		y = (float)(window.Y - mainY);
		width = (float)window.Width;
		height = (float)window.Height;
		return true;
	}

	public void GetGlobalMousePosition(out float globalX, out float globalY)
	{
		globalX = 0.0f;
		globalY = 0.0f;

		if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.Input == null) ||
			(mHost.Shell.Input.Mouse == null))
			return;

		globalX = mHost.Shell.Input.Mouse.GlobalX;
		globalY = mHost.Shell.Input.Mouse.GlobalY;
	}

	/// Per frame work for floating windows. Call once from the application's update.
	///
	/// A borderless float has no window manager title bar to drag, and the dock manager leaves
	/// OS window movement to the application, so the window is moved HERE: while a panel drag
	/// out of one of our windows is running, the window follows the desktop global cursor so
	/// the grab point stays under it.
	public void Tick()
	{
		// Native close button clicks join the toolkit's own close flow. Only a chromed window
		// has one, but matching every frame is harmless: the shell posts the event per window
		// id, and an id that is not ours never matches.
		DispatchCloseRequests();

		let dragDrop = mUIHost.Context.DragDrop;
		if (dragDrop == null)
			return;

		// Under OS chrome the float must NOT chase the cursor during a re-dock drag, which is
		// exactly the application driven move Wayland punishes. The drag adorner is the in
		// flight visual instead, and the window stays where the system put it.
		if (UsesOSChrome())
		{
			mDragWindow = null;
			return;
		}

		if (!dragDrop.IsDragging)
		{
			mDragWindow = null;
			return;
		}

		// Latch the window and the grab offset ONCE, when the drag begins. The offset is how
		// far the cursor sat from the window's top left at grab, and holding it fixed is what
		// pins the grab point to the window as it follows.
		if (mDragWindow == null)
			LatchDragWindow(dragDrop.CurrentDragData);

		if (mDragWindow == null)
			return;

		GetGlobalMousePosition(var globalX, var globalY);
		mDragWindow.Window.SetPosition((int32)(globalX - mDragOffsetX),
			(int32)(globalY - mDragOffsetY));
	}

	private void LatchDragWindow(DragData dragData)
	{
		let panelDrag = dragData as DockPanelDragData;
		if ((panelDrag == null) || (panelDrag.SourceWindow == null))
			return;

		let entry = Find(panelDrag.SourceWindow);
		if (entry == null)
			return;

		GetGlobalMousePosition(var globalX, var globalY);
		mDragWindow = entry.Window;
		mDragOffsetX = globalX - (float)entry.Window.Window.X;
		mDragOffsetY = globalY - (float)entry.Window.Window.Y;
	}

	private Entry Find(View view)
	{
		for (let entry in mEntries)
		{
			if (entry.View == view)
				return entry;
		}

		return null;
	}

	/// Delivers this frame's per window close requests to the matching callbacks.
	///
	/// A callback normally tears its own entry down, so the matches are COLLECTED first and
	/// each entry is re-found before its callback runs: an earlier one may already have removed
	/// it.
	private void DispatchCloseRequests()
	{
		if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.WindowManager == null))
			return;

		let closing = scope List<View>();
		for (let event in mHost.Shell.WindowManager.Events)
		{
			if (event.Type != .CloseRequested)
				continue;

			for (let entry in mEntries)
			{
				if (entry.Window.Window.Id == event.WindowId)
				{
					closing.Add(entry.View);
					break;
				}
			}
		}

		for (let view in closing)
		{
			let entry = Find(view);
			if ((entry != null) && (entry.OnClose != null))
				entry.OnClose(view);
		}
	}

	/// The main window's top left on the desktop. Every dockable window position is relative to
	/// it, so a float lands where the layout asked whatever the main window's own position is.
	private void MainOrigin(out int32 x, out int32 y)
	{
		x = 0;
		y = 0;

		if ((mHost == null) || (mHost.Shell == null) || (mHost.Shell.MainWindow == null))
			return;

		x = mHost.Shell.MainWindow.X;
		y = mHost.Shell.MainWindow.Y;
	}
}
