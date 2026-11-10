using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// DockSpace: the widget that shows one surface of a controller's layout.
//
// Its widgets are made from the layout, each kept by the id of the node it shows, so showing the
// layout again changes only what changed: a split is the core's Splitter,
// a stack a TabView whose strip's group is `dock`, each panel a page whose content the controller
// makes the first time its tab is shown. A panel the layout names that is not registered shows a
// placeholder, filled when it is. A maximized stack is shown alone. What the user does in the
// widgets goes back into the layout: a separator dragged, a tab chosen or dragged to another place,
// a tab's close (through the controller, which closes it as its description says).
//
// Docking's default sheet (DockingSheetCSS) styles them through the theme's tokens: a theme or an
// application restyles docking by setting `--dock-*`.

static
{
	/// Docking's default sheet, written against the theme's tokens (an application puts it after the
	/// theme in its user agent sheet).
	public static StringView DockingSheetCSS() => DockSpaceDetail.cCss;

	/// Docking's commands: `dock.focus-*` and `dock.move-*` (left, right, up, down) focus the stack
	/// that way, or move the focused stack's panel into it (past the surface's edge into what lies
	/// beyond it, in a DockArea; else along that edge); `dock.maximize` shows the focused stack alone
	/// or all again; `dock.close` closes its panel; `dock.move-to` opens the menu of where it may go
	/// (what a tab's context menu opens too, with Close); `dock.float` floats it. A DockSpace takes
	/// them for the stack the focus is in. `dock.next-surface` and `dock.previous-surface` take the
	/// focus to a DockArea's next surface (its main one, then its floats), to the stack last focused
	/// there.
	///
	/// None is bound to a key: docking is the pointer's (a drag, Shift to float), and the keys a
	/// desktop leaves free differ (Ctrl+Alt and an arrow is GNOME's, Ctrl+Alt is AltGr on many
	/// layouts). The keyboard's way in is a tab's context menu (Shift+F10, the Menu key), which is
	/// Move to, and `drag.pick` (Ctrl+Shift+D); an application binds these where it wants keys, or
	/// shows them in a menu.
	public static void DefineDockingCommands(GUIContext context)
	{
		for (let named in DockSpaceDetail.sCommands)
		{
			if (context.Commands.Find(named.Id) == null)
				context.DefineCommand(named.Id).Label = named.Label;
		}
	}
}

/// What a tab torn out of its stack leaves while it is dragged (DockSpace.TornTab).
enum DockTornTab : uint8
{
	/// It stays, dimmed (the default).
	case Dim;
	/// Its strip closes up, a neighbour's panel shown.
	case Close;
}

/// A way on the screen, for the directional commands.
enum DockDirection : uint8
{
	case Left;
	case Right;
	case Up;
	case Down;
}

/// What a DockSpace's keys and its Move to menu reach past its own surface: the other surfaces
/// shown with it (a DockArea's main surface and its floats).
interface IDockSurroundings
{
	/// The stack of another surface past `stack`'s surface the way `way` goes (what lies just
	/// beyond its edge there); cNoDock when none does.
	DockNodeId StackBeyond(DockSpace from, DockNodeId stack, DockDirection way);
	/// The stacks the other surfaces show, for the Move to menu, appended to `outStacks`.
	void OtherStacks(DockSpace from, List<DockNodeId> outStacks);
	/// Focuses a stack any of them shows (its chosen tab); false when none does.
	bool FocusStackAnywhere(DockNodeId stack);
}

/// A stack as a DockSpace shows it: a TabView whose drops are the layout's to decide (its
/// middle tabs a dragged panel in, an edge band puts it beside).
[GuiReflect]
class DockStack : TabView
{
	// The space that made it (which holds it).
	private DockSpace mSpace;
	private DockNodeId mNode;

	public this(DockSpace space, DockNodeId node)
	{
		mSpace = space;
		mNode = node;
		using (StyleWriteScope(this))
		{
			// Its splitter gives it the room the user left it: a panel wider or taller than that
			// wraps or is clipped here, never spilling onto its neighbours.
			EditLayoutStyle(scope (s) =>
				{
					s.OverflowX = .Hidden;
					s.OverflowY = .Hidden;
				});
			// A closable panel's close part on the chosen tab and the one hovered (as Visual
			// Studio's and Godot's docks show it), and a middle click closes one; a sheet's
			// `close-display` says otherwise.
			Bar.CloseDisplay = .Hover;
			// Its strip's end, as Dear ImGui's: the list button always (clicked it lists the tabs,
			// dragged it carries the stack), and past it a cross closing every closable tab.
			Bar.ListDisplay = .Always;
			Bar.ShowsCloseAll = true;
		}
	}

	/// The layout's node it shows.
	public DockNodeId LayoutNode => mNode;
	public DockSpace Space => mSpace;

	// A stack's drops: the surface's band is the DockSpace's (left for the walk to reach it), the
	// rest the stack's own edge bands and middle.
	protected override void OnDragQuery(DropQuery query)
	{
		let dragged = scope DockDragged();
		if (!mSpace.Dragged(query.Payload, dragged) || DockSpace.AsksToFloat(query))
			return; // a drag of another kind (not the layout's), or a float asked for (the area's)
		var drop = DockDrop(.Middle, mNode, cNoDock, -1, .Start);
		// The keyboard aims at no band (the focus's middle is no aim): into the stack it is in.
		if (!query.FromKeyboard && (!mSpace.DropAt(mSpace.FromNode(this, query.Local), mNode, out drop) || (drop.Kind == .Edge)))
			return;
		mSpace.Offer(this, query, dragged, drop);
	}

	protected override void OnDragLeave(DragEvent e)
	{
		mSpace.Withdraw(this);
	}

	protected override void OnDrop(DragEvent e)
	{
		mSpace.TakeOffer(this);
	}

	// The focus came into it: its chosen panel is the active one.
	public override void OnDescendantFocused(Node focused)
	{
		base.OnDescendantFocused(focused);
		mSpace.NoteFocused(mNode);
	}

	// A tab's context menu: where its panel may go.
	protected override void OnContextMenu(MouseEvent e)
	{
		for (var n = e.Target; (n != null) && (n != this); n = n.Parent)
		{
			let tab = n as Tab;
			if ((tab == null) || (tab.Bar != Bar))
				continue;
			let page = tab.Page;
			let panel = (page != null) ? mSpace.PanelOf(page) : null;
			if (panel != null)
			{
				let moving = scope String(panel);
				e.Handled = mSpace.OpenMoveTo(moving, tab, tab.RootNode.ConvertToNodeSpace(e.Position)) != null; // the pointer's world point, in root space
			}
			return;
		}
	}
}

[GuiReflect]
class DockSpace : UIWidget, IDockView
{
	// A panel's page, as a stack shows it.
	private class Page
	{
		public String Panel = new .() ~ delete _;
		public TabPage Widget = null ~ _?.ReleaseRef();
		/// Made for a registered panel, not a placeholder.
		public bool Registered = false;

		/// It takes a reference to `widget` of its own.
		public this(StringView panel, TabPage widget, bool registered)
		{
			Panel.Set(panel);
			widget.AddRef();
			Widget = widget;
			Registered = registered;
		}
	}

	// The widget of a node of the layout, kept by its id.
	private class Shown
	{
		public DockNodeId Id = cNoDock;
		public DockNodeKind Kind = .Stack;
		public UIWidget Widget = null ~ _?.ReleaseRef();
		/// A stack's, by panel.
		public List<Page> Pages = new .() ~ DeleteContainerAndItems!(_);
		public bool Used = false;
	}

	// The layout it shows (borrowed: the controller outlives its views).
	private DockController mController = null;
	private DockSurfaceId mSurface = cNoDock;
	private List<Shown> mShown = new .() ~ DeleteContainerAndItems!(_);
	private float mEdgeBand = 64.0f;
	private float mSurfaceBand = 20.0f;
	private DockTornTab mTornTab = .Dim;
	private delegate Rectangle(StringView panel) mFloatPlacer ~ delete _;
	// Its DockArea's (not owned; the area holds this).
	private IDockSurroundings mSurroundings = null;
	private Panel mPreview = null ~ _?.ReleaseRef();
	private Menu mMoveMenu = null ~ _?.ReleaseRef();
	private Rect mPreviewBounds = .();
	private delegate void(DockDragged dragged, DragResult result) mOnDraggedOutside ~ delete _;
	// What offered the drop shown (not owned; compared only).
	private Node mOfferOwner = null;
	private DockDragged mOfferDragged = new .() ~ delete _;
	private DockDrop mOfferDrop = .();
	private bool mOfferValid = false;

	public this()
	{
		Tag = "dockspace";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Column;
					s.AlignItems = .Stretch;
				});
		}
		for (let d in DockSpaceDetail.sDirectional)
		{
			let way = d.Way;
			if (d.Move)
				OnCommand(d.Id, new (e) => { e.Propagate = !MoveFocused(way).Ok; });
			else
				OnCommand(d.Id, new (e) => { e.Propagate = !FocusToward(way); });
		}
		OnCommand("dock.maximize", new (e) => { e.Propagate = !ToggleMaximized().Ok; });
		OnCommand("dock.close", new (e) => { e.Propagate = !CloseFocused().Ok; });
		OnCommand("dock.move-to", new (e) => { e.Propagate = OpenMoveToFocused() == null; });
		OnCommand("dock.float", new (e) => { e.Propagate = !FloatFocused().Ok; });
	}

	public ~this()
	{
		if (mController != null)
			mController.RemoveView(this);
	}

	/// Shows `surface` of `controller`'s layout, now and whenever it changes. The controller is
	/// borrowed and outlives this widget.
	public void Show(DockController controller, DockSurfaceId surface)
	{
		if (mController != null)
			mController.RemoveView(this);
		mController = controller;
		mSurface = surface;
		controller.AddView(this);
		ShowLayout();
	}

	public DockSurfaceId Surface => mSurface;

	/// The widget showing a node (a Splitter or a TabView); null when it shows none.
	public UIWidget WidgetOf(DockNodeId node)
	{
		for (let shown in mShown)
		{
			if (shown.Id == node)
				return shown.Widget;
		}
		return null;
	}

	/// The page showing a panel; null when none does.
	public TabPage PageOf(StringView panel)
	{
		for (let shown in mShown)
		{
			for (let page in shown.Pages)
			{
				if (page.Panel == panel)
					return page.Widget;
			}
		}
		return null;
	}

	public String PanelOf(Node page)
	{
		for (let shown in mShown)
		{
			for (let p in shown.Pages)
			{
				if (p.Widget == page)
					return p.Panel;
			}
		}
		return null;
	}

	// === The keyboard's moves ===

	/// The stack the focus is in, among those this widget shows; cNoDock when it is in none.
	public DockNodeId FocusedStack
	{
		get
		{
			let d = EventDispatcher;
			for (var n = (d != null) ? d.FocusNode : null; n != null; n = n.Parent)
			{
				let stack = n as DockStack;
				if ((stack != null) && (stack.Space == this))
					return stack.LayoutNode;
			}
			return cNoDock;
		}
	}

	/// The stack shown nearest `stack` the way `way` goes (overlapping it across); cNoDock when
	/// none is.
	public DockNodeId StackToward(DockNodeId stack, DockDirection way)
	{
		let from = WidgetOf(stack);
		if (from == null)
			return cNoDock;
		let a = from.ScreenBounds;
		DockNodeId best = cNoDock;
		float bestGap = 0.0f;
		float bestOverlap = 0.0f;
		for (let shown in mShown)
		{
			if ((shown.Kind != .Stack) || (shown.Id == stack) || !Holds(shown.Widget))
				continue;
			let b = shown.Widget.ScreenBounds;
			let across = (way == .Left) || (way == .Right);
			float gap = 0.0f;
			switch (way)
			{
			case .Left: gap = a.X - (b.X + b.Width);
			case .Right: gap = b.X - (a.X + a.Width);
			case .Up: gap = a.Y - (b.Y + b.Height);
			case .Down: gap = b.Y - (a.Y + a.Height);
			}
			let overlap = across ? Math.Min(a.Y + a.Height, b.Y + b.Height) - Math.Max(a.Y, b.Y)
				: Math.Min(a.X + a.Width, b.X + b.Width) - Math.Max(a.X, b.X);
			if ((gap < -1.0f) || (overlap <= 0.0f))
				continue; // not that way, or not beside it
			if ((best == cNoDock) || (gap < bestGap - 0.5f) || ((gap <= bestGap + 0.5f) && (overlap > bestOverlap)))
			{
				best = shown.Id;
				bestGap = gap;
				bestOverlap = overlap;
			}
		}
		return best;
	}

	/// The stack this widget shows at `screenPoint`, or the one nearest it; cNoDock when it shows
	/// none.
	public DockNodeId StackAt(Float2 screenPoint)
	{
		DockNodeId best = cNoDock;
		float bestDistance = 0.0f;
		for (let shown in mShown)
		{
			if ((shown.Kind != .Stack) || !Holds(shown.Widget))
				continue;
			let b = shown.Widget.ScreenBounds;
			let dx = Math.Max(0.0f, Math.Max(b.X - screenPoint.X, screenPoint.X - (b.X + b.Width)));
			let dy = Math.Max(0.0f, Math.Max(b.Y - screenPoint.Y, screenPoint.Y - (b.Y + b.Height)));
			let distance = dx * dx + dy * dy;
			if ((best == cNoDock) || (distance < bestDistance))
			{
				best = shown.Id;
				bestDistance = distance;
			}
		}
		return best;
	}

	/// The stacks this widget shows (a maximized one alone), in the layout's order, appended to
	/// `outStacks`.
	public void StacksShown(List<DockNodeId> outStacks)
	{
		for (let shown in mShown)
		{
			if ((shown.Kind == .Stack) && Holds(shown.Widget))
				outStacks.Add(shown.Id);
		}
	}

	/// A stack's chosen tab focused; false when this widget shows none of it.
	public bool FocusStack(DockNodeId stack)
	{
		let view = WidgetOf(stack) as TabView;
		if ((view == null) || !Holds(view))
			return false;
		let tab = view.Bar.SelectedTab;
		if (tab == null)
			return false;
		tab.RequestFocus();
		return true;
	}

	/// What its keys and Move to menu reach past its own surface (a DockArea sets it; borrowed);
	/// none, they stay in it.
	public IDockSurroundings Surroundings
	{
		get => mSurroundings;
		set => mSurroundings = value;
	}

	/// Focuses the stack the way `way` goes from the focused one (its chosen tab), past the
	/// surface's edge into the surroundings when none of its own is; false when there is none.
	public bool FocusToward(DockDirection way)
	{
		let from = FocusedStack;
		let to = StackToward(from, way);
		if (to != cNoDock)
			return FocusStack(to);
		let beyond = ((from != cNoDock) && (mSurroundings != null)) ? mSurroundings.StackBeyond(this, from, way) : cNoDock;
		return (beyond != cNoDock) && mSurroundings.FocusStackAnywhere(beyond);
	}

	/// The focused stack's chosen panel moved the way `way` goes: into the stack there, else into
	/// the stack beyond the surface's edge (the surroundings'), else along that edge. The focus
	/// goes with it.
	public DockOutcome MoveFocused(DockDirection way)
	{
		let stack = FocusedStack;
		let node = (stack != cNoDock) ? mController.Layout.FindNode(stack) : null;
		if ((node == null) || node.Panels.IsEmpty)
			return DockOutcome.Refuse("no stack is focused");
		let panel = scope String(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]);
		AddRef(); // a float this empties ends with the edit
		defer ReleaseRef();
		var to = StackToward(stack, way);
		if ((to == cNoDock) && (mSurroundings != null))
			to = mSurroundings.StackBeyond(this, stack, way);
		let drop = (to != cNoDock) ? DockDrop(.Middle, to, cNoDock, -1, .Start) : DockDrop(.Edge, cNoDock, mSurface, -1, SideOf(way));
		let outcome = mController.Edit(scope (layout) => ApplyDrop(layout, panel, drop));
		if (outcome.Ok)
			FocusLanded(mController.Layout.StackOf(panel));
		return outcome;
	}

	/// The focused stack shown alone, or every stack again when one is.
	public DockOutcome ToggleMaximized()
	{
		let surface = (mController != null) ? mController.Layout.FindSurface(mSurface) : null;
		if (surface == null)
			return DockOutcome.Refuse("no surface is shown");
		if (surface.Maximized != cNoDock)
		{
			let was = surface.Maximized;
			let restored = mController.Edit(scope (layout) => layout.Restore(mSurface));
			FocusStack(was);
			return restored;
		}
		let stack = FocusedStack;
		if (stack == cNoDock)
			return DockOutcome.Refuse("no stack is focused");
		let outcome = mController.Edit(scope (layout) => layout.Maximize(stack));
		FocusStack(stack);
		return outcome;
	}

	/// Closes the focused stack's chosen panel (as its description says).
	public DockOutcome CloseFocused()
	{
		let stack = FocusedStack;
		let node = (stack != cNoDock) ? mController.Layout.FindNode(stack) : null;
		if ((node == null) || node.Panels.IsEmpty)
			return DockOutcome.Refuse("no stack is focused");
		let panel = scope String(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]);
		return mController.Close(panel);
	}

	// === Floating ===

	/// A drag asks for a float rather than a dock: Shift held (the pointer's; the keyboard drops
	/// where the focus is).
	public static bool AsksToFloat(DropQuery query)
	{
		return !query.FromKeyboard && ((query.Modifiers & KeyModShift) != 0);
	}

	/// Told of a panel or a stack dragged from here and let go outside every window (a DockArea
	/// floats it there, in OS windows). OWNERSHIP of `handler` transfers.
	public void SetOnDraggedOutside(delegate void(DockDragged dragged, DragResult result) handler)
	{
		delete mOnDraggedOutside;
		mOnDraggedOutside = handler;
	}

	/// Where a panel floated from here (the menu, `dock.float`) stands: what the area it is in
	/// says (a DockArea sets it); none, a float placed where the area cascades them. OWNERSHIP of
	/// `placer` transfers.
	public void SetFloatPlacer(delegate Rectangle(StringView panel) placer)
	{
		delete mFloatPlacer;
		mFloatPlacer = placer;
	}

	/// A panel docked here floated into a surface of its own.
	public DockOutcome FloatPanel(StringView panel)
	{
		if (mController == null)
			return DockOutcome.Refuse("it shows no layout");
		let bounds = (mFloatPlacer != null) ? mFloatPlacer(panel) : Rectangle(0.0f, 0.0f, 0.0f, 0.0f);
		let moving = scope String(panel);
		return mController.Edit(scope (layout) => layout.Float(moving, bounds));
	}

	/// The focused stack's chosen panel floated.
	public DockOutcome FloatFocused()
	{
		let stack = FocusedStack;
		let node = (stack != cNoDock) ? mController.Layout.FindNode(stack) : null;
		if ((node == null) || node.Panels.IsEmpty)
			return DockOutcome.Refuse("no stack is focused");
		let panel = scope String(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]);
		return FloatPanel(panel);
	}

	// === The "Move to" menu ===

	/// Opens the menu of the places `panel` may go, at `at` (root space) for `owner`: into each
	/// other stack, beside one (on each side), its own and then the surroundings', along the
	/// surface's edges, floated; a place the layout refuses is shown disabled. Then Close (disabled
	/// for a panel that cannot be closed). Null when the panel is not docked here; the menu is
	/// this widget's.
	public Menu OpenMoveTo(StringView panel, Node owner, Float2 at)
	{
		if ((mController == null) || (mController.Layout.SurfaceOf(mController.Layout.StackOf(panel)) != mSurface))
			return null;
		let layout = mController.Layout;
		let from = layout.StackOf(panel);
		if (mMoveMenu != null)
			mMoveMenu.ReleaseRef();
		mMoveMenu = new Menu();
		let menu = mMoveMenu;
		let moving = scope String(panel);

		// One place: shown disabled when the layout refuses it (tried on a copy).
		void AddPlace(Menu target, StringView text, DockDrop drop)
		{
			let after = scope DockLayout();
			after.Set(mController.Layout);
			let can = ApplyDrop(after, moving, drop).Ok;
			let id = new String(moving);
			let item = target.AddItem(text, new () =>
				{
					AddRef(); // a float this empties ends with the edit
					defer ReleaseRef();
					if (mController.Edit(scope (edited) => ApplyDrop(edited, id, drop)).Ok)
						FocusLanded(mController.Layout.StackOf(id));
				} ~ { delete id; });
			item.Enabled = can;
		}

		DockDirection[4] ways = .(.Left, .Right, .Up, .Down);
		String[4] besideNames = .("Left", "Right", "Above", "Below");
		String[4] edgeNames = .("Left", "Right", "Top", "Bottom");
		let into = menu.AddSubMenu("Into");
		let beside = menu.AddSubMenu("Beside");
		// Its own stacks, then the other surfaces' (named for where they are).
		let stacks = scope List<DockNodeId>();
		StacksShown(stacks);
		let own = stacks.Count;
		if (mSurroundings != null)
			mSurroundings.OtherStacks(this, stacks);
		for (int s < stacks.Count)
		{
			let stack = stacks[s];
			let surface = (s < own) ? null : layout.FindSurface(layout.SurfaceOf(stack));
			let floating = (surface != null) && (surface.Kind == .Floating);
			let name = scope String();
			StackName(stack, name);
			if (s >= own)
				name.Append(floating ? " (floating)" : " (main)");
			if (stack != from)
				AddPlace(into, name, DockDrop(.Middle, stack, cNoDock, -1, .Start));
			let sides = beside.AddSubMenu(name);
			for (int i < 4)
				AddPlace(sides, besideNames[i], DockDrop(.Beside, stack, cNoDock, -1, SideOf(ways[i])));
		}
		let edge = menu.AddSubMenu("Along the Edge");
		for (int i < 4)
			AddPlace(edge, edgeNames[i], DockDrop(.Edge, cNoDock, mSurface, -1, SideOf(ways[i])));
		{
			let after = scope DockLayout();
			after.Set(layout);
			let can = after.Float(moving, .(0.0f, 0.0f, 0.0f, 0.0f)).Ok;
			let id = new String(moving);
			let item = menu.AddItem("Float", new () => { FloatPanel(id); } ~ { delete id; });
			item.Enabled = can;
		}
		menu.AddSeparator();
		{
			let description = mController.Describe(moving);
			let id = new String(moving);
			let item = menu.AddItem("Close", new () =>
				{
					AddRef(); // a float this empties ends with the close
					defer ReleaseRef();
					mController.Close(id);
				} ~ { delete id; });
			item.Enabled = (description == null) || description.Closable;
		}
		menu.Open(owner, at);
		return mMoveMenu;
	}

	/// The "Move to" menu for the focused stack's chosen panel, below its tab.
	public Menu OpenMoveToFocused()
	{
		let stack = FocusedStack;
		let node = (stack != cNoDock) ? mController.Layout.FindNode(stack) : null;
		let view = WidgetOf(stack) as TabView;
		let tab = (view != null) ? view.Bar.SelectedTab : null;
		if ((node == null) || node.Panels.IsEmpty || (tab == null))
			return null;
		let panel = scope String(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]);
		return OpenMoveTo(panel, tab, tab.ConvertToRootSpace(.(0.0f, tab.Size.Y)));
	}

	/// The menu last opened (open or not); null before one is.
	public Menu MoveMenu => mMoveMenu;

	// === Drops ===

	/// How far into a stack its edge band reaches (a third of it at most); the sheet's
	/// `edge-band`, the theme's `--dock-edge`.
	[GuiProperty("edge-band")]
	public float EdgeBand
	{
		get => mEdgeBand;
		set => mEdgeBand = Math.Max(0.0f, value);
	}

	/// How far into the surface its own edge band reaches (`surface-band`, `--dock-surface-edge`);
	/// over a strip along the edge, its outer third (the rest is the strip's).
	[GuiProperty("surface-band")]
	public float SurfaceBand
	{
		get => mSurfaceBand;
		set => mSurfaceBand = Math.Max(0.0f, value);
	}

	/// What a tab torn out of its stack leaves while it is dragged (`torn-tab`, the theme's
	/// `--dock-torn-tab`): `dim` (the default), it stays where it is, dimmed; `close`, its strip
	/// closing up and its stack showing a neighbour's panel. Nothing moves in the layout until the
	/// drop, and a drag that ends without one shows the stack as it was. A stack's only tab, or a
	/// tab picked up from the keyboard (the focus stays on it), is dimmed either way.
	public DockTornTab TornTab
	{
		get => mTornTab;
		set => mTornTab = value;
	}

	/// "dim" or "close" (a sheet's `torn-tab`).
	[GuiProperty("torn-tab")]
	public StringView TornTabName
	{
		get => (mTornTab == .Close) ? "close" : "dim";
		set => mTornTab = (value == "close") ? .Close : .Dim;
	}

	/// The docked panel a drag carries (a torn-out tab of a page some view of the controller
	/// shows); null for anything else. The view's string.
	public String DraggedPanel(DragPayload payload)
	{
		if ((mController == null) || (payload.Type != "gui/tab"))
			return null;
		let tab = TabBar.DraggedTab(payload);
		let page = (tab != null) ? tab.Page : null;
		return (page != null) ? mController.PanelShownBy(page) : null;
	}

	/// The floating surface a drag carries whole (a float dragged by its title); cNoDock for
	/// anything else.
	public DockSurfaceId DraggedSurface(DragPayload payload)
	{
		if ((mController == null) || (payload.Type != cDockSurfaceDragType) || (payload.Value.VariantType != typeof(uint64)))
			return cNoDock;
		let surface = mController.Layout.FindSurface((DockSurfaceId)payload.Value.Get<uint64>());
		return ((surface != null) && (surface.Kind == .Floating)) ? surface.Id : cNoDock;
	}

	/// The stack a drag carries whole (its strip's grip dragged); cNoDock for anything else.
	public DockNodeId DraggedStack(DragPayload payload)
	{
		if ((mController == null) || (payload.Type != cDockStackDragType) || (payload.Value.VariantType != typeof(uint64)))
			return cNoDock;
		let stack = mController.Layout.FindNode((DockNodeId)payload.Value.Get<uint64>());
		return ((stack != null) && stack.IsStack) ? stack.Id : cNoDock;
	}

	/// What a dock drag carries (a panel, a floating surface or a stack), into `outDragged`; false
	/// for any other drag.
	public bool Dragged(DragPayload payload, DockDragged outDragged)
	{
		outDragged.Clear();
		let panel = DraggedPanel(payload);
		if (panel != null)
		{
			outDragged.Panel.Set(panel);
			return true;
		}
		let stack = DraggedStack(payload);
		if (stack != cNoDock)
		{
			outDragged.Stack = stack;
			return true;
		}
		outDragged.Surface = DraggedSurface(payload);
		return outDragged.Surface != cNoDock;
	}

	/// The drop a point means (in this widget's space), over `stack` (cNoDock: over none): the
	/// surface's edge within its band, else the stack's edge within its band, else its middle;
	/// false when it means none.
	public bool DropAt(Float2 at, DockNodeId stack, out DockDrop drop, float surfaceShare = 1.0f)
	{
		drop = .();
		let bounds = ScreenBounds;
		let w = bounds.Width;
		let h = bounds.Height;
		DockSide side = .Start;
		if (NearestEdge(at, .(0.0f, 0.0f, w, h), Math.Min(mSurfaceBand, Math.Min(w, h) / 3.0f) * surfaceShare, out side))
		{
			drop = DockDrop(.Edge, cNoDock, mSurface, -1, side);
			return true;
		}
		let widget = (stack != cNoDock) ? WidgetOf(stack) : null;
		if (widget == null)
			return false;
		let sb = widget.ScreenBounds;
		let r = Rect(sb.X - bounds.X, sb.Y - bounds.Y, sb.Width, sb.Height);
		if (NearestEdge(at, r, Math.Min(mEdgeBand, Math.Min(r.Width, r.Height) / 3.0f), out side))
			drop = DockDrop(.Beside, stack, cNoDock, -1, side);
		else
			drop = DockDrop(.Middle, stack, cNoDock, -1, .Start);
		return true;
	}

	/// Where the preview of the drop being offered stands (this widget's space); false when none
	/// shows.
	public bool GetPreviewBounds(out Rect outBounds)
	{
		outBounds = .();
		if ((mPreview == null) || !mPreview.Visible)
			return false;
		outBounds = mPreviewBounds;
		return true;
	}

	/// The layout shown again: the widgets of nodes still there kept and brought in step, those of
	/// nodes gone let go.
	public void ShowLayout()
	{
		if (mController == null)
			return;
		let layout = mController.Layout;
		let surface = layout.FindSurface(mSurface);
		for (let shown in mShown)
			shown.Used = false;
		UIWidget top = null;
		if (surface != null)
		{
			top = Build((surface.Maximized != cNoDock) ? surface.Maximized : surface.Root);
			Keep(surface.Root); // a stack maximized: the rest kept for its restore
		}
		let shownNow = ((ChildCount > 0) && (GetChildAt(0) != mPreview)) ? GetChildAt(0) : null;
		if (shownNow != top)
		{
			if (shownNow != null)
				RemoveChild(shownNow);
			if (top != null)
			{
				// The space's size, never its content's: a stack holding a long tree or a tall page
				// clips it rather than growing the split past the space.
				top.EditLayoutStyle(scope (s) =>
					{
						s.Grow = 1.0f;
						s.MinWidth = LayoutLength.Px(0.0f);
						s.MinHeight = LayoutLength.Px(0.0f);
					});
				if (top.Parent != null)
					top.RemoveFromParent();
				AddChildAt(top, 0); // under the preview
			}
		}
		for (int i = mShown.Count; i > 0; --i)
		{
			let shown = mShown[i - 1];
			if (shown.Used)
				continue;
			if (shown.Widget != null)
				shown.Widget.RemoveFromParent();
			mShown.RemoveAt(i - 1);
			delete shown;
		}
	}

	protected override void OnDragQuery(DropQuery query)
	{
		// Reached over a separator, or past a stack that left it the surface's band.
		let dragged = scope DockDragged();
		DockDrop drop = .();
		if (Dragged(query.Payload, dragged) && !query.FromKeyboard && !AsksToFloat(query) && DropAt(query.Local, cNoDock, out drop))
			Offer(this, query, dragged, drop);
	}

	protected override void OnDragLeave(DragEvent e)
	{
		Withdraw(this);
	}

	protected override void OnDrop(DragEvent e)
	{
		TakeOffer(this);
	}

	// A point in `node`'s space, in this widget's.
	internal Float2 FromNode(Node node, Float2 local)
	{
		let space = ScreenBounds;
		let from = node.ScreenBounds;
		return .(local.X + from.X - space.X, local.Y + from.Y - space.Y);
	}

	// A drop offered by `owner` (a stack, its strip, or this widget): tried on a copy of the
	// layout, refused with the layout's reason, or accepted with the preview where the panel
	// would be.
	internal void Offer(Node owner, DropQuery query, DockDragged dragged, DockDrop drop)
	{
		let after = scope DockLayout();
		after.Set(mController.Layout);
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		PanelsOf(after, dragged, panels); // where they are now
		let outcome = ApplyDrop(after, dragged, drop);
		mOfferOwner = owner;
		if (!outcome.Ok)
		{
			mOfferValid = false;
			mOfferDragged.Clear();
			query.Refuse(outcome.Refused);
			HidePreview();
			return;
		}
		query.Accept(.Move);
		mOfferDragged.Set(dragged);
		mOfferDrop = drop;
		mOfferValid = true;
		// Where what it carries would stand: its stacks' bounds together, in this surface.
		Rect at = .();
		bool any = false;
		for (let panel in panels)
		{
			Rect each = .();
			if (!BoundsIn(after, after.StackOf(panel), out each))
				continue;
			if (!any)
				at = each;
			else
			{
				let right = Math.Max(at.X + at.Width, each.X + each.Width);
				let bottom = Math.Max(at.Y + at.Height, each.Y + each.Height);
				at.X = Math.Min(at.X, each.X);
				at.Y = Math.Min(at.Y, each.Y);
				at.Width = right - at.X;
				at.Height = bottom - at.Y;
			}
			any = true;
		}
		if (any)
			ShowPreview(at);
		else
			HidePreview(); // it would go to another surface
	}

	internal void Withdraw(Node owner)
	{
		if (mOfferOwner != owner)
			return; // another took the drag over already
		mOfferOwner = null;
		mOfferValid = false;
		mOfferDragged.Clear();
		HidePreview();
	}

	internal void TakeOffer(Node owner)
	{
		let valid = (mOfferOwner == owner) && mOfferValid;
		let dragged = scope DockDragged();
		dragged.Set(mOfferDragged);
		let drop = mOfferDrop;
		mOfferOwner = null;
		mOfferValid = false;
		mOfferDragged.Clear();
		HidePreview();
		if (valid && (mController != null))
			mController.Edit(scope (layout) => ApplyDrop(layout, dragged, drop));
		// A stack carried by its grip is dimmed while it goes; dropped, it is shown again where the
		// drop left it. Moved, its widgets left the tree and came back, and its grip may never hear
		// the drag end.
		if (dragged.IsStack)
		{
			let stack = WidgetOf(dragged.Stack);
			if (stack != null)
				stack.RemoveClass("dock-torn");
		}
	}

	// The focus went into a stack this space shows.
	internal void NoteFocused(DockNodeId stack)
	{
		if (mController != null)
			mController.NoteFocused(stack);
	}

	// A tab of `stack` torn out (`torn`) or its drag over: closed up or dimmed meanwhile, then
	// shown again and the stack's panel as the layout has it (where the drop left it).
	private void NoteTorn(DockNodeId stack, Tab tab, bool torn)
	{
		let shown = Find(stack);
		let view = (shown != null) ? shown.Widget as TabView : null;
		if (!torn)
		{
			tab.Displayed = true;
			tab.RemoveClass("dock-torn");
			if (view == null)
				return;
			view.RemoveClass("dock-torn");
			let node = (mController != null) ? mController.Layout.FindNode(stack) : null;
			if ((node != null) && (node.Kind == .Stack) && !node.Panels.IsEmpty)
				view.SelectedIndex = (int32)Math.Min((int)node.Active, node.Panels.Count - 1);
			return;
		}
		if (view == null)
			return;
		let bar = view.Bar;
		let d = EventDispatcher;
		let keyboard = (d != null) && d.IsKeyboardDrag;
		if (bar.TabCount <= 1)
		{
			view.AddClass("dock-torn"); // its stack goes with it: dimmed whole
			return;
		}
		if ((mTornTab == .Dim) || keyboard)
		{
			tab.AddClass("dock-torn");
			return;
		}
		// Closed up: a neighbour's panel shown in its place (the view's selection, not the layout's).
		let at = bar.IndexOf(tab);
		if (bar.SelectedIndex == at)
			view.SelectedIndex = (at + 1 < bar.TabCount) ? at + 1 : at - 1;
		tab.Displayed = false;
	}

	// A drag of the whole stack from its grip: the pointer's (the keyboard moves a stack's panels
	// by its tab menu), of a stack that has panels.
	private bool StartStackDrag(DockNodeId stack, DragRequest request)
	{
		let node = (mController != null) ? mController.Layout.FindNode(stack) : null;
		if (request.FromKeyboard || (node == null) || !node.IsStack || node.Panels.IsEmpty)
			return false;
		request.Payload.Type.Set(cDockStackDragType);
		request.Payload.Value.Dispose();
		request.Payload.Value = System.Variant.Create((uint64)stack);
		request.Payload.Label.Clear();
		StackName(stack, request.Payload.Label);
		request.Payload.Allowed = DropEffectsMove;
		return true;
	}

	// The stack holding `grip` dimmed while it is carried (the grip's ancestors asked: a drop may
	// have moved it into another widget, or let it go).
	private static void DimStackOf(Node grip, bool dim)
	{
		for (var n = grip; n != null; n = n.Parent)
		{
			let stack = n as DockStack;
			if (stack == null)
				continue;
			if (dim)
				stack.AddClass("dock-torn");
			else
				stack.RemoveClass("dock-torn");
			return;
		}
	}

	private Shown Find(DockNodeId node)
	{
		for (let shown in mShown)
		{
			if (shown.Id == node)
				return shown;
		}
		return null;
	}

	// The widgets of `id` and its descendants that are made stay, shown or not.
	private void Keep(DockNodeId id)
	{
		let node = mController.Layout.FindNode(id);
		if (node == null)
			return;
		let shown = Find(id);
		if (shown != null)
			shown.Used = true;
		for (let child in node.Children)
			Keep(child);
	}

	// The widget for `id`, made or kept, brought in step with the layout (its Shown's).
	private UIWidget Build(DockNodeId id)
	{
		let node = mController.Layout.FindNode(id);
		if (node == null)
			return null;
		var shown = Find(id);
		if ((shown != null) && (shown.Kind != node.Kind))
		{
			shown.Widget.RemoveFromParent();
			shown.Widget.ReleaseRef();
			shown.Widget = null;
			shown.Kind = node.Kind;
		}
		if (shown == null)
		{
			shown = new Shown();
			shown.Id = id;
			shown.Kind = node.Kind;
			mShown.Add(shown);
		}
		shown.Used = true;
		if (node.IsStack)
			return BuildStack(id);
		return BuildSplit(id);
	}

	private UIWidget BuildSplit(DockNodeId id)
	{
		if (Find(id).Widget == null)
		{
			let made = new Splitter();
			made.SetOnResized(new () =>
				{
					let shares = scope List<float>();
					made.GetWeights(shares);
					mController.NoteWeights(id, shares);
				});
			Find(id).Widget = made;
		}
		// The node's parts copied: its children are built first.
		let node = mController.Layout.FindNode(id);
		let axis = node.Axis;
		let childIds = scope List<DockNodeId>();
		childIds.AddRange(node.Children);
		let weights = scope List<float>();
		weights.AddRange(node.Weights);
		let children = scope List<UIWidget>();
		for (let child in childIds)
			children.Add(Build(child));
		let splitter = (Splitter)Find(id).Widget;
		splitter.Axis = (axis == .Vertical) ? .Vertical : .Horizontal;
		// Its panes, in order (the handles between them are the splitter's own).
		bool inOrder = splitter.PaneCount == children.Count;
		for (int i = 0; inOrder && (i < children.Count); ++i)
			inOrder = splitter.GetPane(i) == children[i];
		if (!inOrder)
		{
			while (splitter.PaneCount > 0)
				splitter.RemoveChild(splitter.GetPane(splitter.PaneCount - 1));
			for (let child in children)
			{
				if (child.Parent != null)
					child.RemoveFromParent();
				splitter.AddChild(child);
			}
		}
		// Its shares, unless they are what it shows already (a drag just noted them).
		let now = scope List<float>();
		splitter.GetWeights(now);
		bool same = now.Count == weights.Count;
		for (int i = 0; same && (i < now.Count); ++i)
			same = Math.Abs(now[i] - weights[i]) < 1.0e-4f;
		if (!same)
			splitter.SetWeights(weights);
		return Find(id).Widget;
	}

	private UIWidget BuildStack(DockNodeId id)
	{
		if (Find(id).Widget == null)
		{
			let made = new DockStack(this, id);
			made.AddClass("dock-stack");
			// Its strip: a tab dropped there is the layout's move too.
			let bar = made.Bar;
			bar.SetOnTabOffered(new (query, tab, index) =>
				{
					if (AsksToFloat(query))
					{
						query.Effect = .None; // passed on: a float, the area's
						return;
					}
					let dragged = scope DockDragged();
					if (!Dragged(query.Payload, dragged))
					{
						query.Refuse("it is not a docked panel");
						return;
					}
					// The outer third of the surface's band wins over a strip along the surface's
					// edge; the rest of the strip is the strip's (a tab moved along it reorders).
					var drop = DockDrop(.Tab, id, cNoDock, index, .Start);
					DockDrop edge = .();
					if (!query.FromKeyboard && DropAt(FromNode(bar, query.Local), cNoDock, out edge, 1.0f / 3.0f))
						drop = edge;
					Offer(bar, query, dragged, drop);
				});
			bar.SetTabTaker(new (tab, index) => { TakeOffer(bar); });
			// A whole stack over the strip goes in as tabs (the bar asks only of tabs); the outer
			// third of the surface's band wins, as for a tab.
			bar.SetOnDragQuery(new (query) =>
				{
					let dragged = scope DockDragged();
					if (AsksToFloat(query) || !Dragged(query.Payload, dragged) || !dragged.IsStack)
						return;
					var drop = DockDrop(.Middle, id, cNoDock, -1, .Start);
					DockDrop edge = .();
					if (DropAt(FromNode(bar, query.Local), cNoDock, out edge, 1.0f / 3.0f))
						drop = edge;
					Offer(bar, query, dragged, drop);
				});
			bar.AddEventListener(.Drop, new (e) =>
				{
					if (DraggedStack(((DragEvent)e).Payload) != cNoDock)
						TakeOffer(bar);
				});
			// Its grip: the list button, dragged, carries the whole stack (dimmed meanwhile).
			let grip = bar.ListButton;
			grip.SetDragSource(new (request) => StartStackDrag(id, request));
			grip.AddEventListener(.DragStart, new (e) => { DimStackOf(grip, true); });
			grip.SetOnDragEnd(new (result) =>
				{
					DimStackOf(grip, false);
					if (result.Outside && (mOnDraggedOutside != null))
					{
						AddRef();
						defer ReleaseRef();
						let dragged = scope DockDragged(default, cNoDock, id);
						mOnDraggedOutside(dragged, result);
					}
				});
			bar.SetOnTabTorn(new (tab, torn) => { NoteTorn(id, tab, torn); });
			// A tab let go outside every window: its panel, to whoever floats it there.
			bar.SetOnTabDragEnded(new (tab, result) =>
				{
					if (!result.Outside || (mOnDraggedOutside == null))
						return;
					let page = tab.Page;
					let panel = (page != null) ? PanelOf(page) : null;
					if (panel == null)
						return;
					let dragged = scope DockDragged(panel, cNoDock, cNoDock);
					AddRef(); // the float it makes may end this space's surface
					defer ReleaseRef();
					mOnDraggedOutside(dragged, result);
				});
			bar.AddEventListener(.DragLeave, new (e) => { Withdraw(bar); });
			made.Group = "dock";
			made.Reorderable = true;
			let stackView = made;
			made.SetOnSelected(new (index) => { NoteActive(id, stackView, index); });
			made.SetOnPageMoved(new (to) => { NoteMoved(id, stackView, to); });
			made.Bar.SetCloseHandler(new (index) => { CloseTab(id, stackView, index); });
			Find(id).Widget = made;
		}
		// The node's parts copied: making pages may show one, and its content come.
		let node = mController.Layout.FindNode(id);
		let central = node.Has(DockStackCentral);
		let active = node.Active;
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		for (let panel in node.Panels)
			panels.Add(new String(panel));
		let shown = Find(id);
		let view = (TabView)shown.Widget;
		if (central)
			view.AddClass("dock-central");
		// Its pages: one a panel, in the panels' order; a panel gone takes its page with it.
		let pages = new List<Page>();
		for (let panel in panels)
		{
			let registered = mController.Describe(panel) != null;
			TabPage page = null;
			for (let had in shown.Pages)
			{
				if ((had.Panel == panel) && (had.Registered || !registered)) // a placeholder whose panel came is made again
					page = had.Widget;
			}
			if (page != null)
			{
				ShowDescription(page, panel); // its title or tab classes may have changed
				pages.Add(new Page(panel, page, registered));
			}
			else
			{
				page = MakePage(panel);
				pages.Add(new Page(panel, page, registered));
				page.ReleaseRef(); // its Page's reference keeps it
			}
		}
		bool inOrder = view.PageCount == (int32)pages.Count;
		for (int i = 0; inOrder && (i < pages.Count); ++i)
			inOrder = view.GetPage((int32)i) == pages[i].Widget;
		if (!inOrder)
		{
			while (view.PageCount > 0)
				view.RemovePage(view.PageCount - 1);
			// The active tab chosen before the pages come, so the first to come is not shown
			// (and its content made) on the way.
			view.SelectedIndex = (int32)active;
			for (let page in pages)
			{
				if (page.Widget.Parent != null)
					page.Widget.RemoveFromParent();
				view.AddPage(page.Widget);
			}
		}
		DeleteContainerAndItems!(shown.Pages);
		shown.Pages = pages;
		if (!panels.IsEmpty && (view.SelectedIndex != (int32)active))
			view.SelectedIndex = (int32)active;
		return shown.Widget;
	}

	// A panel's page: its title, icon and close from its description; its content made when its
	// tab is first shown, or a placeholder for a panel not registered. The caller releases it.
	private TabPage MakePage(StringView panel)
	{
		let page = new TabPage();
		ShowDescription(page, panel);
		let controller = mController;
		let id = new String(panel);
		page.SetContentFactory(new (into) =>
			{
				var content = controller.Content(id);
				bool placeholder = false;
				if (content == null)
				{
					let label = new Label();
					label.AddClass("dock-placeholder");
					label.Text = scope String()..AppendF("{} is not available", id);
					content = label;
					placeholder = true;
				}
				if (content.Parent != null)
					content.RemoveFromParent(); // it was shown elsewhere
				into.AddChild(content);
				if (placeholder)
					content.ReleaseRef(); // the page's reference keeps it
			} ~ { delete id; });
		return page;
	}

	// A page's tab as its panel's description has it now.
	private void ShowDescription(TabPage page, StringView panel)
	{
		let description = mController.Describe(panel);
		let title = ((description != null) && !description.Title.IsEmpty) ? (StringView)description.Title : panel;
		if (page.Title != title)
			page.Title = title;
		if ((description != null) && (page.Icon != description.Icon))
			page.Icon = description.Icon;
		page.Closable = (description == null) || description.Closable;
		let classes = (description != null) ? (StringView)description.TabClasses : "";
		if (page.TabClasses != classes)
			page.TabClasses = classes;
	}

	// The panel of a stack's page at `index` (its Page's string); null when none.
	private String PanelAt(DockNodeId stack, TabView view, int32 index)
	{
		let page = view.GetPage(index);
		for (let shown in mShown)
		{
			if (shown.Id != stack)
				continue;
			for (let p in shown.Pages)
			{
				if (p.Widget == page)
					return p.Panel;
			}
		}
		return null;
	}

	private void NoteActive(DockNodeId stack, TabView view, int32 index)
	{
		let panel = PanelAt(stack, view, index);
		if (panel != null)
			mController.NoteActive(panel);
	}

	private void NoteMoved(DockNodeId stack, TabView view, int32 to)
	{
		let panel = PanelAt(stack, view, to);
		if (panel == null)
			return;
		let moved = scope String(panel);
		mController.NoteTabPlace(moved, stack, to);
		// The pages' order is the strip's now: kept so, without showing the layout again.
		let shown = Find(stack);
		if (shown == null)
			return;
		let ordered = new List<Page>();
		for (int32 i = 0; i < view.PageCount; ++i)
		{
			for (let p in shown.Pages)
			{
				if (p.Widget == view.GetPage(i))
				{
					ordered.Add(p);
					break;
				}
			}
		}
		for (let p in shown.Pages)
		{
			if (!ordered.Contains(p))
				delete p;
		}
		delete shown.Pages;
		shown.Pages = ordered;
	}

	private void CloseTab(DockNodeId stack, TabView view, int32 index)
	{
		let panel = PanelAt(stack, view, index);
		if (panel == null)
			return;
		let closing = scope String(panel); // the close lets its page go
		mController.Close(closing);
	}

	private bool Holds(Node node)
	{
		for (var n = node; n != null; n = n.Parent)
		{
			if (n == this)
				return true;
		}
		return false;
	}

	// The stack a panel moved to focused, here or in the surroundings. A float the move emptied
	// has left the tree still holding its old widgets: only the surface it shows is asked of it.
	private bool FocusLanded(DockNodeId stack)
	{
		if ((mController.Layout.SurfaceOf(stack) == mSurface) && FocusStack(stack))
			return true;
		return (mSurroundings != null) && mSurroundings.FocusStackAnywhere(stack);
	}

	// The side a way goes to, as the surface runs (right to left: left is its end).
	private DockSide SideOf(DockDirection way)
	{
		let rtl = IsRightToLeft;
		switch (way)
		{
		case .Left: return rtl ? .End : .Start;
		case .Right: return rtl ? .Start : .End;
		case .Up: return .Top;
		case .Down: return .Bottom;
		}
	}

	// A stack as the menu names it: its panels' titles, appended to `outName`.
	private void StackName(DockNodeId stack, String outName)
	{
		let start = outName.Length;
		let node = mController.Layout.FindNode(stack);
		if (node != null)
		{
			for (let panel in node.Panels)
			{
				let description = mController.Describe(panel);
				let title = ((description != null) && !description.Title.IsEmpty) ? (StringView)description.Title : (StringView)panel;
				if (outName.Length != start)
					outName.Append(", ");
				outName.Append(title);
			}
		}
		if (outName.Length == start)
			outName.Append("(empty)");
	}

	// The side of `r` whose band of `band` holds `at`, nearest first; false when none does.
	private bool NearestEdge(Float2 at, Rect r, float band, out DockSide side)
	{
		side = .Start;
		if ((band <= 0.0f) || (at.X < r.X) || (at.Y < r.Y) || (at.X > r.X + r.Width) || (at.Y > r.Y + r.Height))
			return false;
		let left = at.X - r.X;
		let right = r.X + r.Width - at.X;
		let top = at.Y - r.Y;
		let bottom = r.Y + r.Height - at.Y;
		let nearest = Math.Min(Math.Min(left, right), Math.Min(top, bottom));
		if (nearest > band)
			return false;
		let rtl = IsRightToLeft;
		if (nearest == left)
			side = rtl ? .End : .Start;
		else if (nearest == right)
			side = rtl ? .Start : .End;
		else
			side = (nearest == top) ? .Top : .Bottom;
		return true;
	}

	// Where `node` stands in `layout`'s surface as this widget would show it: the shares of each
	// split from its root (the separators' room left out).
	private bool BoundsIn(DockLayout layout, DockNodeId node, out Rect outBounds)
	{
		outBounds = .();
		let surface = layout.FindSurface(mSurface);
		if ((surface == null) || (node == cNoDock) || (layout.SurfaceOf(node) != mSurface))
			return false;
		let bounds = ScreenBounds;
		let whole = Rect(0.0f, 0.0f, bounds.Width, bounds.Height);
		if (surface.Maximized != cNoDock)
		{
			outBounds = whole;
			return node == surface.Maximized;
		}
		return BoundsUnder(layout, surface.Root, node, whole, out outBounds);
	}

	private bool BoundsUnder(DockLayout layout, DockNodeId at, DockNodeId node, Rect r, out Rect outBounds)
	{
		outBounds = .();
		if (at == node)
		{
			outBounds = r;
			return true;
		}
		let split = layout.FindNode(at);
		if ((split == null) || split.IsStack)
			return false;
		let vertical = split.Axis == .Vertical;
		let mirrored = !vertical && IsRightToLeft;
		let extent = vertical ? r.Height : r.Width;
		float from = 0.0f;
		for (int i < split.Children.Count)
		{
			let size = extent * split.Weights[i];
			var part = r;
			if (vertical)
			{
				part.Y = r.Y + from;
				part.Height = size;
			}
			else
			{
				part.X = mirrored ? r.X + r.Width - from - size : r.X + from;
				part.Width = size;
			}
			if (BoundsUnder(layout, split.Children[i], node, part, out outBounds))
				return true;
			from += size;
		}
		return false;
	}

	private void ShowPreview(Rect at)
	{
		if (mPreview == null)
		{
			mPreview = new Panel();
			mPreview.AddClass("dock-preview");
			mPreview.HitTestVisible = false; // the drag sees what is under it
			AddChild(mPreview);
		}
		mPreviewBounds = at;
		mPreview.EditLayoutStyle(scope (s) =>
			{
				s.Placement = .Absolute;
				s.Left = LayoutLength.Px(at.X);
				s.Top = LayoutLength.Px(at.Y);
				s.Width = LayoutLength.Px(at.Width);
				s.Height = LayoutLength.Px(at.Height);
			});
		mPreview.Visible = true;
	}

	private void HidePreview()
	{
		if (mPreview != null)
			mPreview.Visible = false;
	}
}

/// What DockSpace.bf keeps out of the public surface: the sheet's text and the commands' names.
internal static class DockSpaceDetail
{
	public struct NamedCommand
	{
		public String Id;
		public String Label;

		public this(String id, String label)
		{
			Id = id;
			Label = label;
		}
	}

	public struct DirectionalCommand
	{
		public String Id;
		public DockDirection Way;
		public bool Move;

		public this(String id, DockDirection way, bool move)
		{
			Id = id;
			Way = way;
			Move = move;
		}
	}

	public static NamedCommand[14] sCommands = .(
		.("dock.focus-left", "Focus the Stack to the Left"),
		.("dock.focus-right", "Focus the Stack to the Right"),
		.("dock.focus-up", "Focus the Stack Above"),
		.("dock.focus-down", "Focus the Stack Below"),
		.("dock.move-left", "Move the Panel Left"),
		.("dock.move-right", "Move the Panel Right"),
		.("dock.move-up", "Move the Panel Up"),
		.("dock.move-down", "Move the Panel Down"),
		.("dock.maximize", "Maximize the Stack"),
		.("dock.close", "Close the Panel"),
		.("dock.move-to", "Move the Panel To..."),
		.("dock.float", "Float the Panel"),
		.("dock.next-surface", "Focus the Next Dock Surface"),
		.("dock.previous-surface", "Focus the Previous Dock Surface"));

	public static DirectionalCommand[8] sDirectional = .(
		.("dock.focus-left", .Left, false), .("dock.focus-right", .Right, false),
		.("dock.focus-up", .Up, false), .("dock.focus-down", .Down, false),
		.("dock.move-left", .Left, true), .("dock.move-right", .Right, true),
		.("dock.move-up", .Up, true), .("dock.move-down", .Down, true));

	public const String cCss = """
		            dockspace { background-color: var(--dock-background, var(--surface)); }
		            tabview.dock-stack { background-color: var(--dock-stack-background, var(--panel)); }
		            tabview.dock-central { background-color: var(--dock-central-background, var(--surface)); }
		            label.dock-placeholder { color: var(--dock-placeholder, var(--muted)); padding: 16px; }
		            dockspace { edge-band: var(--dock-edge, 64px); surface-band: var(--dock-surface-edge, 20px);
		                        torn-tab: var(--dock-torn-tab, dim); }
		            tab.dock-torn, tabview.dock-torn { opacity: var(--dock-torn-opacity, 0.45); }
		            tabview.dock-stack tablist, tabview.dock-stack closeall { color: var(--dock-strip-button, var(--text-dim)); }
		            tabview.dock-stack tablist:hover, tabview.dock-stack closeall:hover {
		                background-color: var(--dock-strip-button-hover, var(--control-hover));
		            }
		            window.dock-float.dock-dragging { opacity: var(--dock-dragging-opacity, 0.6); }
		            panel.dock-preview {
		                background-color: var(--dock-preview, rgba(80, 150, 255, 0.25));
		                border: 2px solid var(--dock-preview-border, var(--accent));
		                border-radius: 4px;
		            }
		""";
}
