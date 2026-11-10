using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// DockArea: floating surfaces within one window, the virtual
// surface host for the web and one-window platforms. The main surface's DockSpace fills it; each
// floating surface of the layout is a DockFloat over it, a Window holding a DockSpace of its own, so
// a float is a whole dock tree that is docked into like the main one. The area keeps the floats
// with the layout as it changes (one made for a surface that came, one ended for a surface that
// went), each at its surface's bounds (this widget's space), and notes back what the user does to a
// window: moved or resized, its bounds; closed, its panels closed as their policies say. A tab
// dragged with Shift held floats: the dock spaces pass the drop on, and the area shows the window
// at the pointer and makes it there. A float dragged by its title bar follows the pointer and docks
// whole where it is let go over a target (the preview the area its content would take); with Shift
// it is only moved; Escape puts it back. The dock keys reach across its surfaces: an arrow past a
// float's edge goes on to the stack beyond it, `dock.next-surface` and `dock.previous-surface` take
// the focus from one surface to the next, and the Move to menu lists every surface's stacks.
//
// Floats as OS windows: given an IDockWindows (a host's), each floating surface is a dock space
// in a window of its own instead, its bounds in screen units; the window's moves, resizes and close
// come back through NoteWindowBounds and CloseFloat. A tab or stack let go outside every window
// floats there; with Shift, at the pointer; Move to's Float, over its stack. No window follows the
// pointer: the system moves a window by its own frame. Going from one to the other converts the
// floats' bounds between the area's units and the screen's.

/// Floats as windows of their own: what a DockArea asks of the host that opens them (a
/// GuiHost's, DockHostWindows). Bounds are in screen units. The host tells the area what the user
/// does to a window: DockArea.NoteWindowBounds, DockArea.CloseFloat.
interface IDockWindows
{
	/// Opens a window for `surface` showing `content` over all of it, at `bounds` where windows
	/// hold the places given them (else of its size, where the system puts it); false when it
	/// opened none. The window's root takes a reference to `content` of its own.
	bool Open(DockSurfaceId surface, Node content, Rectangle bounds, StringView title);
	void Close(DockSurfaceId surface);
	/// Moves and sizes its window (a layout adopted, not the user's move).
	void Place(DockSurfaceId surface, Rectangle bounds);
	void SetTitle(DockSurfaceId surface, StringView title);
	void Raise(DockSurfaceId surface);
	/// Where `local` (in `node`'s space) is on the screen; false where that is not known (Wayland).
	bool ToScreen(Node node, Float2 local, out Float2 screen);
}

/// A floating surface's window (`window.dock-float`): its title its panels', its content a
/// DockSpace showing the surface; closing it closes its panels as their policies say.
[GuiReflect]
class DockFloat : Window
{
	// The area that made it (which holds it).
	private DockArea mArea;
	private DockSurfaceId mSurface;
	private DockSpace mSpace ~ _.ReleaseRef();
	private bool mDragging = false;
	// Where on it the press took it.
	private Float2 mGrab = .(0.0f, 0.0f);
	// Where it was (Escape puts it back).
	private Float2 mDragFrom = .(0.0f, 0.0f);

	public this(DockArea area, DockSurfaceId surface)
	{
		mArea = area;
		mSurface = surface;
		// Its title bar's press is a dock drag of the whole surface.
		let bar = TitleBar;
		bar.DragsItself = false;
		bar.SetDragSource(new (request) => StartTitleDrag(request));
		// When the drag ends the window may be gone (docked away): its title bar, which the drag
		// holds, says whether it is still in one.
		bar.SetOnDragEnd(new (result) =>
			{
				if (let window = bar.Parent as DockFloat)
					window.EndTitleDrag(result);
			});
		mSpace = new DockSpace();
		mSpace.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Percent(100.0f);
				s.Height = LayoutLength.Percent(100.0f);
			});
		Content.AddChild(mSpace);
		SetMinSize(.(160.0f, 100.0f));
	}

	public DockSurfaceId Surface => mSurface;
	public DockSpace Space => mSpace;
	public DockArea Area => mArea;

	/// Its close button's: its panels closed as their policies say.
	public override void RequestClose()
	{
		mArea.CloseFloat(mSurface);
	}

	/// Being dragged by its title bar: it follows the pointer, out of hit tests with all it
	/// holds so the targets under it answer (`.dock-dragging`).
	public bool IsBeingDragged => mDragging;

	/// While it is dragged, nothing of it is under the pointer: the drop is asked of what is below.
	public override Node OverFind(Float2 worldPoint) => mDragging ? null : base.OverFind(worldPoint);

	// Its title bar's drag: the whole surface, the window following the pointer.
	private bool StartTitleDrag(DragRequest request)
	{
		if (request.FromKeyboard)
			return false;
		request.Payload.Type.Set(cDockSurfaceDragType);
		request.Payload.Value.Dispose();
		request.Payload.Value = System.Variant.Create((uint64)mSurface);
		request.Payload.Label.Set(Title);
		request.Payload.Allowed = DropEffectsMove;
		mGrab = request.Press; // the title bar is at the window's top left: the same place
		mDragFrom = Position;
		request.Follow = new (rootAt) => { FollowTo(rootAt); };
		return true;
	}

	private void FollowTo(Float2 rootAt)
	{
		if (!mDragging)
		{
			mDragging = true;
			AddClass("dock-dragging");
			ToFront();
		}
		let at = mArea.ConvertToNodeSpace(rootAt);
		Position = .(at.X - mGrab.X, at.Y - mGrab.Y);
		mArea.RequestLayout();
	}

	private void EndTitleDrag(DragResult result)
	{
		mDragging = false;
		RemoveClass("dock-dragging");
		if (result.Cancelled)
		{
			Position = mDragFrom; // Escape: put back as it was
			mArea.RequestLayout();
		}
		else if (result.Target == null)
			mArea.NoteArranged(this); // let go over nothing (off the area): left there, in reach
	}
}

[GuiReflect]
class DockArea : UIWidget, IDockView, IDockSurroundings
{
	/// A float placed with no bounds of its own (a layout written by hand) takes this size.
	public static readonly Float2 cFloatSize = .(360.0f, 260.0f);
	/// How much of a float's title bar stays in the area however far it is moved.
	public const float cKeepInView = 48.0f;

	// A floating surface in a window of its own.
	private class OsFloat
	{
		public DockSurfaceId Surface = cNoDock;
		/// Its window's root holds it.
		public Panel Content = null ~ _?.ReleaseRef();
		public DockSpace Space = null ~ _?.ReleaseRef();
		public String Title = new .() ~ delete _;
		/// Where its window was put or reported.
		public Rectangle Placed = .(0.0f, 0.0f, 0.0f, 0.0f);
	}

	private struct LastFocused
	{
		public DockSurfaceId Surface;
		public DockNodeId Stack;

		public this(DockSurfaceId surface, DockNodeId stack)
		{
			Surface = surface;
			Stack = stack;
		}
	}

	// A floating surface's id and bounds, as the layout had them.
	private struct FloatingBounds
	{
		public DockSurfaceId Surface;
		public Rectangle Bounds;

		public this(DockSurfaceId surface, Rectangle bounds)
		{
			Surface = surface;
			Bounds = bounds;
		}
	}

	// The layout it shows (borrowed: the controller outlives its views).
	private DockController mController = null;
	private DockSpace mMain ~ _.ReleaseRef();
	private List<DockFloat> mFloats = new .() ~ { for (let window in _) window.ReleaseRef(); delete _; };
	// Floats as windows of their own; not owned.
	private IDockWindows mWindows = null;
	private List<OsFloat> mOsFloats = new .() ~ DeleteContainerAndItems!(_);
	// Where a float asked for would stand.
	private Panel mPreview ~ _.ReleaseRef();
	private Rectangle mPreviewBounds = .(0.0f, 0.0f, 0.0f, 0.0f);
	// The panel it is for.
	private String mFloatPanel = new .() ~ delete _;
	// Or the stack.
	private DockNodeId mFloatStack = cNoDock;
	// A float dragged with Shift: only moved.
	private DockSurfaceId mMoving = cNoDock;
	// Each surface's stack the focus last left.
	private List<LastFocused> mLastFocused = new .() ~ delete _;

	public this()
	{
		Tag = "dockarea";
		ClipChildren = true;
		mMain = new DockSpace();
		AddChild(mMain);
		Placing(mMain);
		mPreview = new Panel();
		mPreview.AddClass("dock-preview");
		mPreview.HitTestVisible = false;
		mPreview.Visible = false;
		AddChild(mPreview);
		OnCommand("dock.next-surface", new (e) => { e.Propagate = !FocusNextSurface(false); });
		OnCommand("dock.previous-surface", new (e) => { e.Propagate = !FocusNextSurface(true); });
	}

	public ~this()
	{
		if (mWindows != null)
			EndFloats(); // its windows close with it
		if (mController != null)
			mController.RemoveView(this);
	}

	/// Shows `controller`'s layout: its main surface, and its floating surfaces over it. The
	/// controller is borrowed and outlives this widget.
	public void Show(DockController controller)
	{
		if (mController != null)
			mController.RemoveView(this);
		mController = controller;
		controller.AddView(this);
		mMain.Show(controller, controller.Layout.MainSurface);
		ShowLayout();
	}

	public DockController Controller => mController;
	/// The main surface's DockSpace.
	public DockSpace MainSpace => mMain;
	public int FloatCount => mFloats.Count;
	public DockFloat GetFloat(int index) => ((index >= 0) && (index < mFloats.Count)) ? mFloats[index] : null;

	/// The window of a floating surface; null for a surface it does not show.
	public DockFloat FloatOf(DockSurfaceId surface)
	{
		for (let window in mFloats)
		{
			if (window.Surface == surface)
				return window;
		}
		return null;
	}

	/// Floats as windows of their own through `windows` (a host's, outliving the area or
	/// taken back first; borrowed), or in the area (null). The floats' bounds are converted between
	/// the area's units and the screen's.
	public void SetWindows(IDockWindows windows)
	{
		if ((Object)windows == (Object)mWindows)
			return;
		let via = (windows != null) ? windows : mWindows;
		Float2 origin = .(0.0f, 0.0f);
		let known = via.ToScreen(this, .(0.0f, 0.0f), out origin);
		EndFloats();
		mWindows = windows;
		if (mController != null)
		{
			let sign = (windows != null) ? 1.0f : -1.0f;
			let floating = scope List<FloatingBounds>();
			for (let surface in mController.Layout.Surfaces)
			{
				if ((surface.Kind == .Floating) && (surface.Bounds.Width > 0.0f) && (surface.Bounds.Height > 0.0f))
					floating.Add(.(surface.Id, surface.Bounds));
			}
			for (let surface in floating)
			{
				var bounds = surface.Bounds;
				if (known)
				{
					bounds.X += sign * origin.X;
					bounds.Y += sign * origin.Y;
				}
				else
				{
					bounds.X = 0.0f; // where the system puts it (its place unknown)
					bounds.Y = 0.0f;
				}
				mController.NoteSurfaceBounds(surface.Surface, bounds);
			}
		}
		ShowLayout();
	}

	public IDockWindows Windows => mWindows;

	/// A floating surface's window was moved or resized by the user (its host's report, in
	/// screen units).
	public void NoteWindowBounds(DockSurfaceId surface, Rectangle bounds)
	{
		if (mController == null)
			return;
		let shown = OsFloatOf(surface);
		if (shown != null)
			shown.Placed = bounds; // where it is: not placed there again
		mController.NoteSurfaceBounds(surface, bounds);
	}

	/// The dock space showing a floating surface in its own window; null when none does.
	public DockSpace WindowSpaceOf(DockSurfaceId surface)
	{
		for (let shown in mOsFloats)
		{
			if (shown.Surface == surface)
				return shown.Space;
		}
		return null;
	}

	/// Its panels closed as their policies say (one that may not close stays, and the window
	/// with it): a float's close button, or its own window's.
	public void CloseFloat(DockSurfaceId surface)
	{
		if (mController == null)
			return;
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		let layout = mController.Layout;
		for (let node in layout.Nodes)
		{
			if (!node.IsStack || (layout.SurfaceOf(node.Id) != surface))
				continue;
			for (let panel in node.Panels)
				panels.Add(new String(panel));
		}
		for (let panel in panels)
			mController.Close(panel);
	}

	/// Where a float of `size` let go at `at` (this widget's space) stands: its title bar under
	/// the pointer, `grab` along it, kept in the area.
	public Rectangle FloatBoundsAt(Float2 at, Float2 size, Float2 grab)
	{
		let place = KeptInView(.(at.X - grab.X, at.Y - grab.Y), size);
		return .(place.X, place.Y, size.X, size.Y);
	}

	// === IDockView ===

	public void ShowLayout()
	{
		if (mController == null)
			return;
		let layout = mController.Layout;
		if (mWindows != null)
		{
			ShowWindows(layout);
			return;
		}
		// The floats whose surfaces went (docked away, emptied) end; their dock spaces leave
		// the controller's views as they do.
		for (int i = mFloats.Count; i > 0; --i)
		{
			if (layout.FindSurface(mFloats[i - 1].Surface) != null)
				continue;
			let gone = mFloats[i - 1];
			mFloats.RemoveAt(i - 1);
			gone.RemoveFromParent();
			gone.ReleaseRef();
		}
		int cascade = 0; // its place among the floats
		for (let surface in layout.Surfaces)
		{
			if (surface.Kind != .Floating)
				continue;
			++cascade;
			var window = FloatOf(surface.Id);
			if (window == null)
			{
				let made = new DockFloat(this, surface.Id);
				made.AddClass("dock-float");
				made.SetOnUserArranged(new () => { NoteArranged(made); });
				AddChild(made);
				mFloats.Add(made); // the made reference, the area's
				window = made;
				Placing(window.Space);
				window.Space.Show(mController, surface.Id);
			}
			var bounds = surface.Bounds;
			if ((bounds.Width <= 0.0f) || (bounds.Height <= 0.0f))
			{
				// None of its own: a cascade from the top left, noted as its own from then.
				let step = 28.0f * (float)(cascade - 1);
				bounds = .(40.0f + step, 40.0f + step, cFloatSize.X, cFloatSize.Y);
				mController.NoteSurfaceBounds(surface.Id, bounds);
			}
			window.Position = .(bounds.X, bounds.Y);
			window.Size = .(bounds.Width, bounds.Height);
			let title = scope String();
			TitleOf(layout, surface.Id, title);
			window.Title = title;
		}
		if (GetChildAt(ChildCount - 1) != mPreview)
			mPreview.ToFront(); // over the floats
		RequestLayout();
	}

	/// Its dock spaces answer.
	public String PanelOf(Node page) => null;

	// === IDockSurroundings ===

	/// What is just past the surface's edge (its window's, for a float) the way `way` goes, level
	/// with the middle of `stack`: the topmost other float there, else the main surface; of it,
	/// the stack there or the one nearest. Past the main surface's edge is outside the area:
	/// nothing (`dock.next-surface` reaches the floats from it).
	public DockNodeId StackBeyond(DockSpace from, DockNodeId stack, DockDirection way)
	{
		let shown = from.WidgetOf(stack);
		let own = FloatShowing(from);
		if ((shown == null) || ((own == null) && (from != mMain)))
			return cNoDock;
		let edge = (own != null) ? own.ScreenBounds : from.ScreenBounds;
		let a = shown.ScreenBounds;
		let past = 2.0f;
		var probe = Float2(a.X + a.Width * 0.5f, a.Y + a.Height * 0.5f);
		switch (way)
		{
		case .Left: probe.X = edge.X - past;
		case .Right: probe.X = edge.X + edge.Width + past;
		case .Up: probe.Y = edge.Y - past;
		case .Down: probe.Y = edge.Y + edge.Height + past;
		}
		// The floats front to back, as they are drawn.
		for (int i = ChildCount; i > 0; --i)
		{
			let window = GetChildAt(i - 1) as DockFloat;
			if ((window != null) && (window != own) && window.Visible && Holds(window.ScreenBounds, probe))
				return window.Space.StackAt(probe);
		}
		return ((own != null) && Holds(mMain.ScreenBounds, probe)) ? mMain.StackAt(probe) : cNoDock;
	}

	public void OtherStacks(DockSpace from, List<DockNodeId> outStacks)
	{
		if (from != mMain)
			mMain.StacksShown(outStacks);
		let spaces = scope List<DockSpace>();
		FloatSpaces(spaces);
		for (let space in spaces)
		{
			if (space != from)
				space.StacksShown(outStacks);
		}
	}

	public bool FocusStackAnywhere(DockNodeId stack)
	{
		NoteFocusedStack();
		if (mMain.FocusStack(stack))
			return true;
		for (let window in mFloats)
		{
			if (window.Space.WidgetOf(stack) == null)
				continue;
			window.AddRef(); // held while it comes to the front
			defer window.ReleaseRef();
			window.ToFront(); // the float it is in comes to the front
			mPreview.ToFront();
			return window.Space.FocusStack(stack);
		}
		for (let shown in mOsFloats)
		{
			if (shown.Space.WidgetOf(stack) == null)
				continue;
			let space = shown.Space;
			space.AddRef(); // held while its window comes to the front
			defer space.ReleaseRef();
			mWindows.Raise(shown.Surface);
			return space.FocusStack(stack);
		}
		return false;
	}

	/// The focus taken to the next surface (`backward`, the one before): the main one, then the
	/// floats as they were made, around; to the stack last focused there, else its first. With
	/// the focus in none of them, to the first (the last). False when there is no other surface.
	public bool FocusNextSurface(bool backward)
	{
		let spaces = scope List<DockSpace>();
		spaces.Add(mMain);
		FloatSpaces(spaces);
		int at = spaces.Count; // none focused
		for (int i < spaces.Count)
		{
			if (spaces[i].FocusedStack != cNoDock)
				at = i;
		}
		let count = spaces.Count;
		for (int step = 1; step <= count; ++step)
		{
			int next = 0;
			if (at == count)
				next = backward ? count - step : step - 1;
			else if (step == count)
				break; // round to where it is
			else
				next = backward ? (at + count - step) % count : (at + step) % count;
			let space = spaces[next];
			var stack = LastFocusedIn(space.Surface);
			if ((stack == cNoDock) || (space.WidgetOf(stack) == null))
			{
				let stacks = scope List<DockNodeId>();
				space.StacksShown(stacks);
				stack = stacks.IsEmpty ? cNoDock : stacks[0];
			}
			if ((stack != cNoDock) && FocusStackAnywhere(stack))
				return true;
		}
		return false;
	}

	/// Where a float being asked for would stand (this widget's space); false when none is.
	public bool GetFloatPreview(out Rectangle outBounds)
	{
		outBounds = .(0.0f, 0.0f, 0.0f, 0.0f);
		if (!mPreview.Visible)
			return false;
		outBounds = mPreviewBounds;
		return true;
	}

	/// Where a panel floated from its stack stands: over the stack, a little in, at most the
	/// stack's size (and at least a usable one).
	public Rectangle FloatBoundsFor(StringView panel)
	{
		let space = SpaceOf(panel);
		let stack = (space != null) ? space.WidgetOf(mController.Layout.StackOf(panel)) : null;
		if (stack == null)
			return .(0.0f, 0.0f, 0.0f, 0.0f); // cascaded
		if (mWindows != null)
		{
			// Its own window over the stack, a little in, on the screen.
			let windowSize = FloatSizeOf(stack.Size);
			Float2 screen = .(0.0f, 0.0f);
			if (mWindows.ToScreen(stack, .(24.0f, 24.0f), out screen))
				return .(screen.X, screen.Y, windowSize.X, windowSize.Y);
			return .(0.0f, 0.0f, windowSize.X, windowSize.Y); // where the system puts it
		}
		let at = stack.ScreenBounds;
		let origin = ConvertToNodeSpace(.(at.X, at.Y));
		let size = FloatSizeOf(.(at.Width, at.Height));
		let place = KeptInView(.(origin.X + 24.0f, origin.Y + 24.0f), size);
		return .(place.X, place.Y, size.X, size.Y);
	}

	// A float asked for (Shift held): the drop the dock spaces passed on lands here, the
	// window at the pointer, its title bar under it.
	protected override void OnDragQuery(DropQuery query)
	{
		if (!DockSpace.AsksToFloat(query))
			return;
		// A float dragged by its title with Shift: only moved, where it is let go.
		let surface = mMain.DraggedSurface(query.Payload);
		if (surface != cNoDock)
		{
			HidePreview();
			mMoving = surface;
			query.Accept(.Move);
			return;
		}
		// A whole stack from its grip, floated as it is.
		let stack = mMain.DraggedStack(query.Payload);
		if (stack != cNoDock)
		{
			let node = mController.Layout.FindNode(stack);
			let stackSize = node.Panels.IsEmpty ? FloatSizeOf(cFloatSize) : FloatSizeFrom(node.Panels[0]);
			let stackBounds = FloatBoundsAt(query.Local, stackSize, .(Math.Min(60.0f, stackSize.X * 0.25f), 14.0f));
			let floated = scope DockLayout();
			floated.Set(mController.Layout);
			let refusal = floated.FloatStack(stack, stackBounds);
			if (!refusal.Ok)
			{
				HidePreview();
				query.Refuse(refusal.Refused);
				return;
			}
			query.Accept(.Move);
			mFloatStack = stack;
			ShowFloatPreview(stackBounds);
			return;
		}
		let panel = mMain.DraggedPanel(query.Payload);
		if (panel == null)
			return;
		let dragged = scope String(panel);
		let after = scope DockLayout();
		after.Set(mController.Layout);
		let size = FloatSizeFrom(dragged);
		let bounds = FloatBoundsAt(query.Local, size, .(Math.Min(60.0f, size.X * 0.25f), 14.0f));
		let refused = after.Float(dragged, bounds);
		if (!refused.Ok)
		{
			HidePreview();
			query.Refuse(refused.Refused);
			return;
		}
		query.Accept(.Move);
		mFloatPanel.Set(dragged);
		ShowFloatPreview(bounds);
	}

	protected override void OnDragLeave(DragEvent e)
	{
		HidePreview();
		mMoving = cNoDock;
	}

	protected override void OnDrop(DragEvent e)
	{
		let moving = mMoving;
		if (moving != cNoDock)
		{
			mMoving = cNoDock;
			let window = FloatOf(moving);
			if (window != null)
				NoteArranged(window); // where it was let go
			return;
		}
		let panel = scope String(mFloatPanel);
		let stack = mFloatStack;
		let bounds = OnScreen(mPreviewBounds); // its own window, where the preview was
		HidePreview();
		if (mController == null)
			return;
		if (stack != cNoDock)
			mController.Edit(scope (layout) => layout.FloatStack(stack, bounds));
		else if (!panel.IsEmpty)
			mController.Edit(scope (layout) => layout.Float(panel, bounds));
	}

	// The main surface fills it; each float at its surface's place (where the pointer has it
	// while it is dragged), kept in view.
	public override void OnLayout()
	{
		let @box = ContentBounds;
		mMain.Arrange(@box);
		if (mPreview.Visible)
			mPreview.Arrange(.(mPreviewBounds.X, mPreviewBounds.Y, mPreviewBounds.Width, mPreviewBounds.Height));
		for (let window in mFloats)
		{
			var place = window.Position;
			let surface = (mController != null) ? mController.Layout.FindSurface(window.Surface) : null;
			if ((surface != null) && !window.IsBeingDragged)
				place = .(surface.Bounds.X, surface.Bounds.Y);
			let at = KeptInView(place, window.Size);
			window.Arrange(.(at.X, at.Y, window.Size.X, window.Size.Y));
		}
	}

	// The window's bounds noted as the user left them: moved back where its title can be taken.
	internal void NoteArranged(DockFloat window)
	{
		if (mController == null)
			return;
		let at = KeptInView(window.Position, window.Size);
		window.Position = at; // let go out of reach: back where its title can be taken
		mController.NoteSurfaceBounds(window.Surface, .(at.X, at.Y, window.Size.X, window.Size.Y));
	}

	// A dock space of the area places its floats as the area does.
	private void Placing(DockSpace space)
	{
		space.SetFloatPlacer(new (panel) => FloatBoundsFor(panel));
		space.Surroundings = this;
		space.SetOnDraggedOutside(new (dragged, result) => { FloatOutside(dragged, result); });
	}

	// The dock spaces of its floats, in the area or in windows of their own, as they were made,
	// appended to `outSpaces`.
	private void FloatSpaces(List<DockSpace> outSpaces)
	{
		for (let window in mFloats)
			outSpaces.Add(window.Space);
		for (let shown in mOsFloats)
			outSpaces.Add(shown.Space);
	}

	private OsFloat OsFloatOf(DockSurfaceId surface)
	{
		for (let shown in mOsFloats)
		{
			if (shown.Surface == surface)
				return shown;
		}
		return null;
	}

	// Bounds in the area made the screen's when its floats are windows of their own (where the
	// screen is not known, of their size where the system puts them).
	private Rectangle OnScreen(Rectangle bounds)
	{
		if (mWindows == null)
			return bounds;
		Float2 screen = .(0.0f, 0.0f);
		if (mWindows.ToScreen(this, .(bounds.X, bounds.Y), out screen))
			return .(screen.X, screen.Y, bounds.Width, bounds.Height);
		return .(0.0f, 0.0f, bounds.Width, bounds.Height);
	}

	// Every float ended, in the area or its window (the layout keeps the surfaces).
	private void EndFloats()
	{
		for (let window in mFloats)
		{
			window.RemoveFromParent();
			window.ReleaseRef();
		}
		mFloats.Clear();
		while (!mOsFloats.IsEmpty)
		{
			let gone = mOsFloats.PopBack(); // held while its window closes
			mWindows.Close(gone.Surface);
			delete gone;
		}
	}

	// Each floating surface in a window of its own: made for a surface that came, closed for one
	// that went, retitled and placed as the layout has it. A window that cannot be opened takes
	// the area back to floats in it.
	private void ShowWindows(DockLayout layout)
	{
		for (int i = mOsFloats.Count; i > 0; --i)
		{
			if (layout.FindSurface(mOsFloats[i - 1].Surface) != null)
				continue;
			let gone = mOsFloats[i - 1];
			mOsFloats.RemoveAt(i - 1);
			mWindows.Close(gone.Surface);
			delete gone;
		}
		int cascade = 0;
		let floating = scope List<DockSurfaceId>();
		for (let surface in layout.Surfaces)
		{
			if (surface.Kind == .Floating)
				floating.Add(surface.Id);
		}
		for (let surfaceId in floating)
		{
			++cascade;
			let surface = layout.FindSurface(surfaceId);
			if (surface == null)
				continue;
			var bounds = surface.Bounds;
			if ((bounds.Width <= 0.0f) || (bounds.Height <= 0.0f))
			{
				// None of its own: a cascade from the area's top left, on the screen.
				let step = 40.0f + 28.0f * (float)(cascade - 1);
				bounds = OnScreen(.(step, step, cFloatSize.X, cFloatSize.Y));
				mController.NoteSurfaceBounds(surfaceId, bounds);
			}
			let title = scope String();
			TitleOf(mController.Layout, surfaceId, title);
			let shown = OsFloatOf(surfaceId);
			if (shown != null)
			{
				if (shown.Title != title)
				{
					shown.Title.Set(title);
					mWindows.SetTitle(surfaceId, title);
				}
				let was = shown.Placed;
				if ((was.X != bounds.X) || (was.Y != bounds.Y) || (was.Width != bounds.Width) || (was.Height != bounds.Height))
				{
					shown.Placed = bounds;
					mWindows.Place(surfaceId, bounds);
				}
				continue;
			}
			let made = new OsFloat();
			made.Surface = surfaceId;
			made.Title.Set(title);
			made.Placed = bounds;
			made.Content = new Panel();
			made.Content.AddClass("dock-window");
			made.Content.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Percent(100.0f);
					s.Height = LayoutLength.Percent(100.0f);
				});
			made.Space = new DockSpace();
			made.Space.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Percent(100.0f);
					s.Height = LayoutLength.Percent(100.0f);
				});
			made.Content.AddChild(made.Space);
			Placing(made.Space);
			made.Space.Show(mController, surfaceId);
			mOsFloats.Add(made);
			if (!mWindows.Open(surfaceId, made.Content, bounds, title))
			{
				mOsFloats.PopBack();
				delete made;
				SetWindows(null); // no window of its own: the floats in the area, all of them
				return;
			}
		}
	}

	// A panel or a stack let go outside every window: floated there, in a window of its own,
	// its title bar under the pointer (where the pointer is not known, where the system puts it).
	private void FloatOutside(DockDragged dragged, DragResult result)
	{
		if ((mWindows == null) || (mController == null) || dragged.IsSurface)
			return; // in the area, outside it is nowhere
		let layout = mController.Layout;
		let first = scope String(dragged.Panel);
		if (dragged.IsStack)
		{
			let node = layout.FindNode(dragged.Stack);
			if ((node != null) && !node.Panels.IsEmpty)
				first.Set(node.Panels[0]);
		}
		let size = first.IsEmpty ? FloatSizeOf(cFloatSize) : FloatSizeFrom(first);
		let bounds = result.ScreenKnown ? Rectangle(result.Screen.X - Math.Min(60.0f, size.X * 0.25f), result.Screen.Y - 14.0f, size.X, size.Y)
			: Rectangle(0.0f, 0.0f, size.X, size.Y);
		let moving = scope DockDragged();
		moving.Set(dragged);
		if (moving.IsStack)
			mController.Edit(scope (edit) => edit.FloatStack(moving.Stack, bounds));
		else
			mController.Edit(scope (edit) => edit.Float(moving.Panel, bounds));
	}

	private DockFloat FloatShowing(DockSpace space)
	{
		for (let window in mFloats)
		{
			if (window.Space == space)
				return window;
		}
		return null;
	}

	// The stack the focus is in noted as its surface's last, for the focus to come back to.
	private void NoteFocusedStack()
	{
		DockSpace focused = (mMain.FocusedStack != cNoDock) ? mMain : null;
		let spaces = scope List<DockSpace>();
		FloatSpaces(spaces);
		for (let space in spaces)
		{
			if ((focused == null) && (space.FocusedStack != cNoDock))
				focused = space;
		}
		if (focused == null)
			return;
		let surface = focused.Surface;
		for (var last in ref mLastFocused)
		{
			if (last.Surface == surface)
			{
				last.Stack = focused.FocusedStack;
				return;
			}
		}
		mLastFocused.Add(.(surface, focused.FocusedStack));
	}

	private DockNodeId LastFocusedIn(DockSurfaceId surface)
	{
		for (let last in mLastFocused)
		{
			if (last.Surface == surface)
				return last.Stack;
		}
		return cNoDock;
	}

	private DockSpace SpaceOf(StringView panel)
	{
		if (mMain.PageOf(panel) != null)
			return mMain;
		let spaces = scope List<DockSpace>();
		FloatSpaces(spaces);
		for (let space in spaces)
		{
			if (space.PageOf(panel) != null)
				return space;
		}
		return null;
	}

	// A float's size from what it came from: no larger than most of the area, no smaller than a
	// window can be used at.
	private Float2 FloatSizeOf(Float2 from)
	{
		let room = Size;
		return .(Math.Clamp(from.X, 200.0f, Math.Max(200.0f, room.X * 0.7f)), Math.Clamp(from.Y, 140.0f, Math.Max(140.0f, room.Y * 0.7f)));
	}

	private Float2 FloatSizeFrom(StringView panel)
	{
		let space = SpaceOf(panel);
		let stack = (space != null) ? space.WidgetOf(mController.Layout.StackOf(panel)) : null;
		return FloatSizeOf((stack != null) ? stack.Size : cFloatSize);
	}

	// The float's preview at `bounds`, over everything.
	private void ShowFloatPreview(Rectangle bounds)
	{
		mPreviewBounds = bounds;
		mPreview.Visible = true;
		mPreview.ToFront();
		RequestLayout();
	}

	private void HidePreview()
	{
		mFloatPanel.Clear();
		mFloatStack = cNoDock;
		if (mPreview.Visible)
			mPreview.Visible = false;
	}

	// A window's place moved so a part of its title bar stays in the area.
	private Float2 KeptInView(Float2 at, Float2 size)
	{
		let room = Size;
		let keep = Math.Min(cKeepInView, size.X);
		return .(Math.Clamp(at.X, keep - size.X, Math.Max(0.0f, room.X - keep)), Math.Clamp(at.Y, 0.0f, Math.Max(0.0f, room.Y - 28.0f)));
	}

	// Its first stack's panel shown, and how many more it holds, appended to `outTitle`.
	private void TitleOf(DockLayout layout, DockSurfaceId surface, String outTitle)
	{
		int count = 0;
		let first = scope String();
		for (let node in layout.Nodes)
		{
			if (!node.IsStack || (layout.SurfaceOf(node.Id) != surface))
				continue;
			if (first.IsEmpty && !node.Panels.IsEmpty)
				first.Set(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]);
			count += node.Panels.Count;
		}
		let description = mController.Describe(first);
		let title = ((description != null) && !description.Title.IsEmpty) ? (StringView)description.Title : (StringView)first;
		outTitle.Append(title);
		if (count > 1)
			outTitle.AppendF(" +{}", count - 1);
	}

	// Whether `r` holds `probe`.
	private static bool Holds(Rect r, Float2 probe)
	{
		return (probe.X >= r.X) && (probe.X < r.X + r.Width) && (probe.Y >= r.Y) && (probe.Y < r.Y + r.Height);
	}
}
