using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// DockHostWindows: a DockArea's floats as OS windows (D6 of Specs/gui-lab-evolution-3.md), on the
// GUI's host. Each floating surface's content goes in a root of the host's GUI, in a window the host
// opens for it (through the application's opener), with the platform's own frame (the user's
// ruling): the system moves, sizes and snaps it. Where the shell's windows hold the places given
// them, a window opens at its surface's bounds and is placed again when the layout moves it; where
// they do not (Wayland), it opens of its size where the system puts it. What the user does to a
// window comes back to the area: moved or resized, its bounds (on screen); its close button, its
// panels closed as their policies say.

class DockHostWindows : IDockWindows
{
	// A float's window, by its root.
	private class Shown
	{
		public DockSurfaceId Surface = cNoDock;
		public SceneRoot Root = null ~ _?.ReleaseRef();
	}

	// Both borrowed: they outlive it.
	private GuiHost mHost;
	private DockArea mArea;
	private List<Shown> mWindows = new .() ~ DeleteContainerAndItems!(_);
	private delegate void(SceneRoot root) mOnRootMade ~ delete _;
	private uint32 mListener = 0;

	/// The floats of `area` in windows `host` opens; both outlive it. Give it to the area with
	/// DockArea.SetWindows, and take it back (SetWindows(null)) before it goes.
	public this(GuiHost host, DockArea area)
	{
		mHost = host;
		mArea = area;
		mListener = host.AddWindowEventListener(new (root, event) => { Heard(root, event); });
	}

	public ~this()
	{
		mHost.RemoveWindowEventListener(mListener);
		while (!mWindows.IsEmpty)
			Close(mWindows.Back.Surface);
	}

	/// Whether it opens windows at all (an opener, and a shell that opens more than one): an
	/// application gives the area its floats as windows only then.
	public bool CanOpen => mHost.CanOpenWindows;

	/// Told of each window's root as it is made, before its window opens: an application styles
	/// it as the page the area is on (a sheet scoped to that page reaches no other root).
	/// OWNERSHIP of `made` transfers.
	public void SetOnRootMade(delegate void(SceneRoot root) made)
	{
		delete mOnRootMade;
		mOnRootMade = made;
	}

	/// The root a floating surface's window shows (its own); null when it shows none.
	public SceneRoot RootOf(DockSurfaceId surface)
	{
		for (let shown in mWindows)
		{
			if (shown.Surface == surface)
				return shown.Root;
		}
		return null;
	}

	public bool Open(DockSurfaceId surface, Node content, Rectangle bounds, StringView title)
	{
		let root = new SceneRoot(mHost.Context);
		root.AddChild(content);
		if (mOnRootMade != null)
			mOnRootMade(root);
		let text = scope String(title);
		var settings = Sedulous.Shell.WindowSettings();
		settings.Title = text;
		settings.Width = (uint32)Math.Max(1.0f, bounds.Width);
		settings.Height = (uint32)Math.Max(1.0f, bounds.Height);
		settings.Positioned = mHost.PlacesWindows;
		settings.X = (int32)bounds.X;
		settings.Y = (int32)bounds.Y;
		settings.Resizable = true;
		if (mHost.OpenWindow(root, settings) == null)
		{
			root.RemoveAllChildren(); // its content goes back to the area
			root.ReleaseRef();
			return false;
		}
		let shown = new Shown();
		shown.Surface = surface;
		shown.Root = root; // the made reference, its Shown's
		mWindows.Add(shown);
		return true;
	}

	public void Close(DockSurfaceId surface)
	{
		for (int i < mWindows.Count)
		{
			if (mWindows[i].Surface != surface)
				continue;
			let shown = mWindows[i];
			mWindows.RemoveAt(i);
			mHost.CloseWindow(shown.Root);
			shown.Root.RemoveAllChildren(); // the content may show again (in the area)
			delete shown;
			return;
		}
	}

	public void Place(DockSurfaceId surface, Rectangle bounds)
	{
		let window = WindowOf(surface);
		if (window == null)
			return;
		if (mHost.PlacesWindows)
			window.SetPosition((int32)bounds.X, (int32)bounds.Y);
		window.SetSize((uint32)Math.Max(1.0f, bounds.Width), (uint32)Math.Max(1.0f, bounds.Height));
	}

	public void SetTitle(DockSurfaceId surface, StringView title)
	{
		let window = WindowOf(surface);
		if (window != null)
			window.SetTitle(title);
	}

	public void Raise(DockSurfaceId surface)
	{
		let window = WindowOf(surface);
		if (window != null)
			window.Raise();
	}

	public bool ToScreen(Node node, Float2 local, out Float2 screen)
	{
		screen = .(0.0f, 0.0f);
		let root = node.RootNode as SceneRoot;
		return (root != null) && mHost.ToScreen(root, node.ConvertToWorldSpace(local), out screen);
	}

	private Sedulous.Shell.IWindow WindowOf(DockSurfaceId surface)
	{
		let root = RootOf(surface);
		let window = (root != null) ? mHost.WindowFor(root) : null;
		return (window != null) ? window.Window : null;
	}

	// A window's event, by its root: a float's window moved or resized, or its close asked for.
	private void Heard(SceneRoot root, Sedulous.Shell.WindowEvent event)
	{
		DockSurfaceId surface = cNoDock;
		for (let shown in mWindows)
		{
			if (shown.Root == root)
				surface = shown.Surface;
		}
		if (surface == cNoDock)
			return; // not a float's
		switch (event.Type)
		{
		case .Moved, .Resized:
			let window = WindowOf(surface);
			if (window != null)
			{
				let placed = mHost.PlacesWindows; // else its place is not known
				mArea.NoteWindowBounds(surface, .(placed ? (float)window.X : 0.0f, placed ? (float)window.Y : 0.0f,
					(float)window.Width, (float)window.Height));
			}
		case .CloseRequested:
			mArea.CloseFloat(surface); // its panels as their policies say; the window goes with the surface
		default:
			break;
		}
	}
}
