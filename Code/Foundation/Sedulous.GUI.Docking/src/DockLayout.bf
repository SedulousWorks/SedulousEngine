using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// DockLayout: a dock layout as plain data (D1 of Specs/gui-lab-evolution-3.md).
//
// The layout is data, not widgets: what the dock widgets show is reconciled from it, a drop's
// preview is an operation run on a copy of it, and it is tested without a GUI. Surfaces are the
// main window's and each floating window's, each a whole tree (a floating window can be docked
// into, and docks whole: its panels as a stack's tabs, or its tree beside a stack or along an
// edge). Nodes live in one table by stable id: a split has an axis, children and their weights (a
// share each, summing to one), a stack its panels (by registered id, never by title), the active
// one and its flags. The main surface has one central stack (the documents' area), kept when it is
// empty. A panel closed keeps its last place, to be shown there again.
//
// An operation either does what it says or refuses with its reason and changes nothing; none falls
// back to doing something else (zed's split of the first pane when its target is gone). After each,
// the layout is normalized: a stack left empty goes (not the central one), a split left with one
// child gives way to it, a split inside a split of the same axis is merged into it, weights sum to
// one, a floating surface left empty goes. A child that goes gives its share to its neighbours, the
// rest keeping theirs (zed set them all equal again).

typealias DockNodeId = uint32;
typealias DockSurfaceId = uint32;

static
{
	/// No node, no surface.
	public const uint32 cNoDock = 0;

	/// What a stack allows (DockNode.Flags).
	/// The main surface's documents area: kept when empty.
	public const uint32 DockStackCentral = 1 << 0;
	/// No panel tabs into it or leaves it.
	public const uint32 DockStackLocked = 1 << 1;
	/// Nothing docks beside it.
	public const uint32 DockStackNoSplit = 1 << 2;
	/// One panel, no more tabs into it.
	public const uint32 DockStackNoTabs = 1 << 3;

	public static DockAxis AxisOf(DockSide side) => ((side == .Start) || (side == .End)) ? .Horizontal : .Vertical;
	public static bool IsBefore(DockSide side) => (side == .Start) || (side == .Top);
}

enum DockAxis : uint8
{
	/// Side by side, from the inline start.
	case Horizontal;
	/// One above another.
	case Vertical;
}

/// Where beside a stack (or at a surface's edge) a panel goes: the inline start or end, the top
/// or the bottom.
enum DockSide : uint8
{
	case Start;
	case End;
	case Top;
	case Bottom;
}

enum DockNodeKind : uint8
{
	case Split;
	case Stack;
}

class DockNode
{
	public DockNodeId Id = cNoDock;
	/// cNoDock: a surface's root.
	public DockNodeId Parent = cNoDock;
	public DockNodeKind Kind = .Stack;
	// A split's.
	public DockAxis Axis = .Horizontal;
	public List<DockNodeId> Children = new .() ~ delete _;
	/// A share each, summing to one.
	public List<float> Weights = new .() ~ delete _;
	// A stack's.
	public List<String> Panels = new .() ~ DeleteContainerAndItems!(_);
	public uint32 Active = 0;
	public uint32 Flags = 0;

	public bool IsStack => Kind == .Stack;
	public bool Has(uint32 flag) => (Flags & flag) != 0;

	public void Set(DockNode other)
	{
		Id = other.Id;
		Parent = other.Parent;
		Kind = other.Kind;
		Axis = other.Axis;
		Children.Clear();
		Children.AddRange(other.Children);
		Weights.Clear();
		Weights.AddRange(other.Weights);
		ClearAndDeleteItems!(Panels);
		for (let panel in other.Panels)
			Panels.Add(new String(panel));
		Active = other.Active;
		Flags = other.Flags;
	}
}

enum DockSurfaceKind : uint8
{
	case Main;
	case Floating;
}

class DockSurface
{
	public DockSurfaceId Id = cNoDock;
	public DockSurfaceKind Kind = .Main;
	public DockNodeId Root = cNoDock;
	/// A floating one's, in logical units on its screen.
	public Rectangle Bounds = .(0.0f, 0.0f, 0.0f, 0.0f);
	/// The screen it was on (by name).
	public String Screen = new .() ~ delete _;
	/// That screen's scale.
	public float Scale = 1.0f;
	/// A stack shown alone over the surface.
	public DockNodeId Maximized = cNoDock;

	public void Set(DockSurface other)
	{
		Id = other.Id;
		Kind = other.Kind;
		Root = other.Root;
		Bounds = other.Bounds;
		Screen.Set(other.Screen);
		Scale = other.Scale;
		Maximized = other.Maximized;
	}
}

/// Where a panel was: its stack and its place among its tabs, and the panels about it then (to
/// find a place near them when the stack is gone).
class DockPlace
{
	public DockSurfaceId Surface = cNoDock;
	public DockNodeId Stack = cNoDock;
	public uint32 Index = 0;
	public List<String> Neighbours = new .() ~ DeleteContainerAndItems!(_);

	public void Set(DockPlace other)
	{
		Surface = other.Surface;
		Stack = other.Stack;
		Index = other.Index;
		ClearAndDeleteItems!(Neighbours);
		for (let neighbour in other.Neighbours)
			Neighbours.Add(new String(neighbour));
	}
}

class DockHidden
{
	public String Panel = new .() ~ delete _;
	public DockPlace Last = new .() ~ delete _;

	public void Set(DockHidden other)
	{
		Panel.Set(other.Panel);
		Last.Set(other.Last);
	}
}

/// A registered panel's place when a restored layout does not name it: a tab of the central
/// stack, or a stack of its own along the main surface's `Side` with `Share` of it. `Panel` is a
/// view of the id, which its owner (the panel's description) keeps.
struct DockDefault
{
	public StringView Panel = default;
	public bool Central = false;
	public DockSide Side = .End;
	public float Share = 0.25f;

	public this() { }

	public this(StringView panel, bool central, DockSide side, float share)
	{
		Panel = panel;
		Central = central;
		Side = side;
		Share = share;
	}
}

/// What an operation did: nothing refused, or its reason. A reason is a literal's text, so the
/// outcome outlives whatever refused.
struct DockOutcome
{
	public StringView Refused = default;

	public this() { }

	public bool Ok => Refused.IsEmpty;

	public static DockOutcome Refuse(StringView why)
	{
		var outcome = DockOutcome();
		outcome.Refused = why;
		return outcome;
	}
}

class DockLayout
{
	internal List<DockNode> mNodes = new .() ~ DeleteContainerAndItems!(_);
	internal List<DockSurface> mSurfaces = new .() ~ DeleteContainerAndItems!(_);
	internal List<DockHidden> mHidden = new .() ~ DeleteContainerAndItems!(_);
	internal DockNodeId mNextNode = 1;
	internal DockSurfaceId mNextSurface = 1;

	/// A main surface holding its central stack, empty.
	public this()
	{
		let central = MakeNode(.Stack);
		central.Flags = DockStackCentral;
		let main = new DockSurface();
		main.Id = mNextSurface++;
		main.Kind = .Main;
		main.Root = central.Id;
		mSurfaces.Add(main);
	}

	/// This layout made a copy of `other` (a drop's preview runs on one).
	public void Set(DockLayout other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(mNodes);
		for (let node in other.mNodes)
		{
			let copy = new DockNode();
			copy.Set(node);
			mNodes.Add(copy);
		}
		ClearAndDeleteItems!(mSurfaces);
		for (let surface in other.mSurfaces)
		{
			let copy = new DockSurface();
			copy.Set(surface);
			mSurfaces.Add(copy);
		}
		ClearAndDeleteItems!(mHidden);
		for (let hidden in other.mHidden)
		{
			let copy = new DockHidden();
			copy.Set(hidden);
			mHidden.Add(copy);
		}
		mNextNode = other.mNextNode;
		mNextSurface = other.mNextSurface;
	}

	// === What it holds ===

	public List<DockSurface> Surfaces => mSurfaces;

	public DockSurface FindSurface(DockSurfaceId id)
	{
		for (let surface in mSurfaces)
		{
			if (surface.Id == id)
				return surface;
		}
		return null;
	}

	public DockSurfaceId MainSurface => mSurfaces.IsEmpty ? cNoDock : mSurfaces[0].Id;

	public List<DockNode> Nodes => mNodes;

	public DockNode FindNode(DockNodeId id)
	{
		for (let node in mNodes)
		{
			if (node.Id == id)
				return node;
		}
		return null;
	}

	public DockNodeId CentralStack
	{
		get
		{
			for (let node in mNodes)
			{
				if (node.IsStack && node.Has(DockStackCentral))
					return node.Id;
			}
			return cNoDock;
		}
	}

	/// The stack a panel is docked in; cNoDock when it is not.
	public DockNodeId StackOf(StringView panel)
	{
		for (let node in mNodes)
		{
			if (!node.IsStack)
				continue;
			for (let p in node.Panels)
			{
				if (p == panel)
					return node.Id;
			}
		}
		return cNoDock;
	}

	public List<DockHidden> Hidden => mHidden;

	public DockHidden FindHidden(StringView panel)
	{
		for (let hidden in mHidden)
		{
			if (hidden.Panel == panel)
				return hidden;
		}
		return null;
	}

	/// The surface a node is in (through its parents to a root).
	public DockSurfaceId SurfaceOf(DockNodeId id)
	{
		var node = FindNode(id);
		while ((node != null) && (node.Parent != cNoDock))
			node = FindNode(node.Parent);
		if (node != null)
		{
			for (let surface in mSurfaces)
			{
				if (surface.Root == node.Id)
					return surface.Id;
			}
		}
		return cNoDock;
	}

	// === What it does ===
	// Each operation that takes a panel out of a stack or the hidden list first copies the id it
	// is given: the caller's view may be of a string the layout is about to let go.

	/// A panel not docked yet (or hidden) as a tab of `stack`, at `index` (past the end: last),
	/// and made its active one.
	public DockOutcome InsertTab(StringView panel, DockNodeId stack, int32 index = -1)
	{
		let id = scope String(panel);
		var refused = CanEnter(id);
		if (!refused.Ok)
			return refused;
		refused = CanTabInto(stack);
		if (!refused.Ok)
			return refused;
		Unhide(id);
		PlaceTab(id, stack, index);
		Normalize();
		return .();
	}

	/// A panel not docked yet (or hidden) in a stack of its own beside `stack`, taking `share`
	/// of the room `stack` had.
	public DockOutcome InsertBeside(StringView panel, DockNodeId stack, DockSide side, float share = 0.5f)
	{
		let id = scope String(panel);
		var refused = CanEnter(id);
		if (!refused.Ok)
			return refused;
		refused = CanDockBeside(stack);
		if (!refused.Ok)
			return refused;
		Unhide(id);
		PlaceBeside(id, stack, side, share);
		Normalize();
		return .();
	}

	/// A panel not docked yet (or hidden) in a stack of its own along a whole surface's edge,
	/// taking `share` of the surface.
	public DockOutcome InsertAtEdge(StringView panel, DockSurfaceId surface, DockSide side, float share = 0.25f)
	{
		let id = scope String(panel);
		let refused = CanEnter(id);
		if (!refused.Ok)
			return refused;
		if (FindSurface(surface) == null)
			return DockOutcome.Refuse("no such surface");
		Unhide(id);
		PlaceAtEdge(id, surface, side, share);
		Normalize();
		return .();
	}

	/// A docked panel moved to a tab of `stack` (its own: to another place among its tabs).
	public DockOutcome MoveToTab(StringView panel, DockNodeId stack, int32 index = -1)
	{
		let id = scope String(panel);
		var refused = CanLeave(id);
		if (!refused.Ok)
			return refused;
		let from = StackOf(id);
		if (from != stack)
		{
			refused = CanTabInto(stack);
			if (!refused.Ok)
				return refused;
		}
		if ((from == stack) && (index >= 0))
		{
			// Reordered among its own tabs: the index is where it ends up.
			let node = FindNode(stack);
			let at = IndexIn(node, id);
			let moved = node.Panels[(int)at];
			node.Panels.RemoveAt((int)at);
			node.Panels.Insert(Math.Min((int)index, node.Panels.Count), moved);
			node.Active = IndexIn(node, id);
			return .();
		}
		TakeOut(id);
		PlaceTab(id, stack, index);
		Normalize();
		return .();
	}

	/// A docked panel moved into a stack of its own beside `stack`.
	public DockOutcome MoveBeside(StringView panel, DockNodeId stack, DockSide side, float share = 0.5f)
	{
		let id = scope String(panel);
		var refused = CanLeave(id);
		if (!refused.Ok)
			return refused;
		refused = CanDockBeside(stack);
		if (!refused.Ok)
			return refused;
		if ((StackOf(id) == stack) && (FindNode(stack).Panels.Count == 1))
			return DockOutcome.Refuse("a panel alone in its stack cannot go beside itself");
		TakeOut(id);
		PlaceBeside(id, stack, side, share);
		Normalize();
		return .();
	}

	/// A docked panel moved to a whole surface's edge.
	public DockOutcome MoveToEdge(StringView panel, DockSurfaceId surface, DockSide side, float share = 0.25f)
	{
		let id = scope String(panel);
		let refused = CanLeave(id);
		if (!refused.Ok)
			return refused;
		if (FindSurface(surface) == null)
			return DockOutcome.Refuse("no such surface");
		let from = FindNode(StackOf(id));
		if ((from.Panels.Count == 1) && (from.Parent == cNoDock) && (SurfaceOf(from.Id) == surface))
			return DockOutcome.Refuse("a surface's only panel cannot go to its own edge");
		TakeOut(id);
		PlaceAtEdge(id, surface, side, share);
		Normalize();
		return .();
	}

	/// A panel (docked, hidden or new) in a floating surface of its own at `bounds`; `made` is
	/// that surface.
	public DockOutcome Float(StringView panel, Rectangle bounds, DockSurfaceId* made = null)
	{
		if (panel.IsEmpty)
			return DockOutcome.Refuse("a panel needs an id");
		let id = scope String(panel);
		if (StackOf(id) != cNoDock)
		{
			let refused = CanLeave(id);
			if (!refused.Ok)
				return refused;
			TakeOut(id);
		}
		Unhide(id);
		let stack = MakeNode(.Stack);
		stack.Panels.Add(new String(id));
		let surface = new DockSurface();
		surface.Id = mNextSurface++;
		surface.Kind = .Floating;
		surface.Root = stack.Id;
		surface.Bounds = bounds;
		mSurfaces.Add(surface);
		if (made != null)
			*made = surface.Id;
		Normalize();
		return .();
	}

	// === A floating surface docked whole (D5) ===

	/// Every panel of floating `surface` as tabs of `stack`, in its stacks' order (the float's
	/// active panel active there); the surface goes.
	public DockOutcome DockSurfaceInto(DockSurfaceId surface, DockNodeId stack)
	{
		var refused = CanDockWhole(surface, stack);
		if (!refused.Ok)
			return refused;
		refused = CanTabInto(stack);
		if (!refused.Ok)
			return refused;
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		let active = scope String();
		CollectPanels(FindSurface(surface).Root, panels, active);
		if (FindNode(stack).Has(DockStackNoTabs) && (panels.Count > 1))
			return DockOutcome.Refuse("that stack holds one panel");
		let stacks = scope List<DockNodeId>();
		StacksOf(surface, stacks);
		for (let id in stacks)
		{
			if (FindNode(id).Has(DockStackLocked))
				return DockOutcome.Refuse("a stack in it is locked");
		}
		for (let panel in panels)
		{
			TakeOut(panel);
			PlaceTab(panel, stack, -1);
		}
		let into = FindNode(stack);
		into.Active = IndexIn(into, active);
		Normalize(); // the emptied surface goes
		return .();
	}

	/// Floating `surface`'s whole tree beside `stack`, taking `share` of its room; the surface goes.
	public DockOutcome DockSurfaceBeside(DockSurfaceId surface, DockNodeId stack, DockSide side, float share = 0.5f)
	{
		var refused = CanDockWhole(surface, stack);
		if (!refused.Ok)
			return refused;
		refused = CanDockBeside(stack);
		if (!refused.Ok)
			return refused;
		let root = Lift(surface);
		PlaceNodeBeside(root, stack, side, share);
		Normalize();
		return .();
	}

	/// Floating `surface`'s whole tree along the edge of surface `into`; the floating one goes.
	public DockOutcome DockSurfaceAtEdge(DockSurfaceId surface, DockSurfaceId into, DockSide side, float share = 0.25f)
	{
		let from = FindSurface(surface);
		if ((from == null) || (from.Kind != .Floating))
			return DockOutcome.Refuse("not a floating surface");
		if (FindSurface(into) == null)
			return DockOutcome.Refuse("no such surface");
		if (into == surface)
			return DockOutcome.Refuse("a surface cannot dock into itself");
		let root = Lift(surface);
		PlaceNodeAtEdge(root, into, side, share);
		Normalize();
		return .();
	}

	// === A stack moved whole (its strip's grip) ===

	/// Every panel of `stack` as tabs of `into` at `index` (-1: last), in order, its active panel
	/// active there; the emptied stack goes (the central one stays, empty).
	public DockOutcome MoveStackInto(DockNodeId stack, DockNodeId into, int32 index = -1)
	{
		var refused = CanMoveStack(stack);
		if (!refused.Ok)
			return refused;
		if (stack == into)
			return DockOutcome.Refuse("a stack cannot go into itself");
		refused = CanTabInto(into);
		if (!refused.Ok)
			return refused;
		let from = FindNode(stack);
		if (FindNode(into).Has(DockStackNoTabs) && (from.Panels.Count > 1))
			return DockOutcome.Refuse("that stack holds one panel");
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		for (let panel in from.Panels)
			panels.Add(new String(panel));
		let active = scope String(panels[Math.Min((int)from.Active, panels.Count - 1)]);
		let intoCount = (int32)FindNode(into).Panels.Count;
		int32 at = (index < 0) ? intoCount : Math.Min(index, intoCount);
		for (let panel in panels)
		{
			TakeOut(panel);
			PlaceTab(panel, into, at++);
		}
		let target = FindNode(into);
		target.Active = IndexIn(target, active);
		Normalize();
		return .();
	}

	/// `stack` beside `target`, taking `share` of its room (a float it was all of goes).
	public DockOutcome MoveStackBeside(DockNodeId stack, DockNodeId target, DockSide side, float share = 0.5f)
	{
		var refused = CanMoveStack(stack);
		if (!refused.Ok)
			return refused;
		if (stack == target)
			return DockOutcome.Refuse("a stack cannot go beside itself");
		refused = CanDockBeside(target);
		if (!refused.Ok)
			return refused;
		PlaceNodeBeside(TakeStack(stack), target, side, share);
		Normalize();
		return .();
	}

	/// `stack` along the whole edge of `surface`.
	public DockOutcome MoveStackToEdge(DockNodeId stack, DockSurfaceId surface, DockSide side, float share = 0.25f)
	{
		let refused = CanMoveStack(stack);
		if (!refused.Ok)
			return refused;
		let into = FindSurface(surface);
		if (into == null)
			return DockOutcome.Refuse("no such surface");
		if (into.Root == stack)
			return DockOutcome.Refuse("a surface's only stack cannot go to its own edge");
		PlaceNodeAtEdge(TakeStack(stack), surface, side, share);
		Normalize();
		return .();
	}

	/// `stack` in a floating surface of its own at `bounds`; `made` is that surface.
	public DockOutcome FloatStack(DockNodeId stack, Rectangle bounds, DockSurfaceId* made = null)
	{
		let refused = CanMoveStack(stack);
		if (!refused.Ok)
			return refused;
		let from = FindSurface(SurfaceOf(stack));
		if ((from.Kind == .Floating) && (from.Root == stack))
			return DockOutcome.Refuse("it floats alone already");
		let moved = TakeStack(stack);
		let surface = new DockSurface();
		surface.Id = mNextSurface++;
		surface.Kind = .Floating;
		surface.Root = moved;
		surface.Bounds = bounds;
		mSurfaces.Add(surface);
		if (made != null)
			*made = surface.Id;
		Normalize();
		return .();
	}

	/// A docked panel closed: no longer docked, its place kept to show it there again.
	public DockOutcome Close(StringView panel)
	{
		let id = scope String(panel);
		let refused = CanLeave(id);
		if (!refused.Ok)
			return refused;
		let stackId = StackOf(id);
		let stack = FindNode(stackId);
		let hidden = new DockHidden();
		hidden.Panel.Set(id);
		hidden.Last.Surface = SurfaceOf(stackId);
		hidden.Last.Stack = stackId;
		hidden.Last.Index = IndexIn(stack, id);
		for (let other in stack.Panels)
		{
			if (other != id)
				hidden.Last.Neighbours.Add(new String(other));
		}
		if (hidden.Last.Neighbours.IsEmpty)
			NeighboursBeside(stackId, hidden.Last.Neighbours); // alone: those in the stack beside it
		TakeOut(id);
		mHidden.Add(hidden);
		Normalize();
		return .();
	}

	/// A closed panel shown again where it was: among its stack's tabs; that stack gone, beside
	/// a neighbour from then; none of them docked, in the central stack.
	public DockOutcome Show(StringView panel)
	{
		let hidden = FindHidden(panel);
		if (hidden == null)
			return DockOutcome.Refuse((StackOf(panel) != cNoDock) ? "it is docked" : "it was never closed");
		let id = scope String(panel);
		// Its place copied: the insert lets the hidden entry go.
		let last = scope DockPlace();
		last.Set(hidden.Last);
		let stack = FindNode(last.Stack);
		if ((stack != null) && stack.IsStack && CanTabInto(last.Stack).Ok)
			return InsertTab(id, last.Stack, (int32)last.Index);
		for (let neighbour in last.Neighbours)
		{
			let near = StackOf(neighbour);
			if ((near != cNoDock) && CanDockBeside(near).Ok)
				return InsertBeside(id, near, .End);
		}
		let central = CentralStack;
		if (central != cNoDock)
			return InsertTab(id, central);
		return DockOutcome.Refuse("there is nowhere to show it");
	}

	/// A closed panel's place let go: it is no longer remembered.
	public DockOutcome Forget(StringView panel)
	{
		if (FindHidden(panel) == null)
			return DockOutcome.Refuse("it is not closed");
		let id = scope String(panel);
		Unhide(id);
		return .();
	}

	/// A docked panel made its stack's active tab.
	public DockOutcome Activate(StringView panel)
	{
		let stack = StackOf(panel);
		if (stack == cNoDock)
			return DockOutcome.Refuse("it is not docked");
		let node = FindNode(stack);
		node.Active = IndexIn(node, panel);
		return .();
	}

	/// A split's children's shares (any scale; one each).
	public DockOutcome SetWeights(DockNodeId split, Span<float> weights)
	{
		let node = FindNode(split);
		if ((node == null) || node.IsStack)
			return DockOutcome.Refuse("not a split");
		if (weights.Length != node.Children.Count)
			return DockOutcome.Refuse("a share for each child");
		for (int i < weights.Length)
			node.Weights[i] = Math.Max(weights[i], 0.0f);
		Normalize();
		return .();
	}

	/// A stack shown alone over its surface (cNoDock on a surface: none).
	public DockOutcome Maximize(DockNodeId stack)
	{
		let node = FindNode(stack);
		if ((node == null) || !node.IsStack)
			return DockOutcome.Refuse("not a stack");
		FindSurface(SurfaceOf(stack)).Maximized = stack;
		return .();
	}

	public DockOutcome Restore(DockSurfaceId surface)
	{
		let found = FindSurface(surface);
		if (found == null)
			return DockOutcome.Refuse("no such surface");
		found.Maximized = cNoDock;
		return .();
	}

	public DockOutcome SetStackFlags(DockNodeId stack, uint32 flags)
	{
		let node = FindNode(stack);
		if ((node == null) || !node.IsStack)
			return DockOutcome.Refuse("not a stack");
		if (node.Has(DockStackCentral) != ((flags & DockStackCentral) != 0))
			return DockOutcome.Refuse("the central stack is the layout's own");
		node.Flags = flags;
		return .();
	}

	/// A floating surface's place and screen (what a host reports when the layout is taken).
	public DockOutcome SetSurfaceBounds(DockSurfaceId surface, Rectangle bounds, StringView screen, float scale)
	{
		let found = FindSurface(surface);
		if (found == null)
			return DockOutcome.Refuse("no such surface");
		found.Bounds = bounds;
		let name = scope String(screen); // it may be a view of the surface's own
		found.Screen.Set(name);
		found.Scale = scale;
		return .();
	}

	/// `read` (a layout restored from text) made this one, if it holds together; refused with
	/// what does not, this one unchanged. A panel it names that is not registered stays, a
	/// placeholder for when it is; one registered (in `known`) that it names nowhere goes to its
	/// default place; a floating surface off every one of `screens` (logical units; none: no
	/// check) comes back onto the first, no larger than it. `read` itself is left as it is: a copy
	/// of it is adopted.
	public DockOutcome Adopt(DockLayout read, Span<DockDefault> known, Span<Rectangle> screens = default)
	{
		let broken = read.Broken();
		if (!broken.IsEmpty)
			return DockOutcome.Refuse(broken);
		let taken = scope DockLayout();
		taken.Set(read);
		for (let panel in known)
		{
			if ((taken.StackOf(panel.Panel) != cNoDock) || (taken.FindHidden(panel.Panel) != null))
				continue;
			let placed = panel.Central ? taken.InsertTab(panel.Panel, taken.CentralStack)
				: taken.InsertAtEdge(panel.Panel, taken.MainSurface, panel.Side, panel.Share);
			if (!placed.Ok)
				return placed;
		}
		if (!screens.IsEmpty)
		{
			for (let surface in taken.mSurfaces)
			{
				if (surface.Kind != .Floating)
					continue;
				bool on = false;
				for (let screen in screens)
				{
					on = on || ((surface.Bounds.X < screen.X + screen.Width) && (surface.Bounds.X + surface.Bounds.Width > screen.X) &&
						(surface.Bounds.Y < screen.Y + screen.Height) && (surface.Bounds.Y + surface.Bounds.Height > screen.Y));
				}
				if (on)
					continue;
				let first = screens[0];
				surface.Bounds.Width = Math.Min(surface.Bounds.Width, first.Width);
				surface.Bounds.Height = Math.Min(surface.Bounds.Height, first.Height);
				surface.Bounds.X = first.X + (first.Width - surface.Bounds.Width) * 0.5f;
				surface.Bounds.Y = first.Y + (first.Height - surface.Bounds.Height) * 0.5f;
			}
		}
		Swap(taken);
		return .();
	}

	/// Whether it holds together: every node in one place in one surface's tree, splits of two
	/// or more children whose shares sum to one and none of its own axis inside it, no empty stack
	/// but the central one, which is in the main surface, a panel in one stack at most and never
	/// also hidden, a floating surface never empty. `why` (when given) is told what does not, for a
	/// test.
	public bool CheckInvariants(String why = null)
	{
		let broken = Broken();
		if (broken.IsEmpty)
			return true;
		if (why != null)
			why.Set(broken);
		return false;
	}

	// What does not hold together (a literal's text); empty when it all does.
	private StringView Broken()
	{
		if (mSurfaces.IsEmpty || (mSurfaces[0].Kind != .Main))
			return "the main surface is not first";
		for (let node in mNodes)
		{
			if ((node.Id == cNoDock) || (node.Id >= mNextNode))
				return "a node's id past the next one made"; // a new one would collide
		}
		for (let surface in mSurfaces)
		{
			if ((surface.Id == cNoDock) || (surface.Id >= mNextSurface))
				return "a surface's id past the next one made";
		}
		let seen = scope List<DockNodeId>();
		// Views of the nodes' own panels: nothing changes while it looks.
		let panels = scope List<StringView>();
		for (let surface in mSurfaces)
		{
			let root = FindNode(surface.Root);
			if ((root == null) || (root.Parent != cNoDock))
				return "a surface's root is missing or has a parent";
			let todo = scope List<DockNodeId>();
			todo.Add(root.Id);
			int surfacePanels = 0;
			while (!todo.IsEmpty)
			{
				let id = todo.PopBack();
				for (let s in seen)
				{
					if (s == id)
						return "a node is in two places";
				}
				seen.Add(id);
				let node = FindNode(id);
				if (node == null)
					return "a child is missing";
				if (node.IsStack)
				{
					if (node.Panels.IsEmpty && !node.Has(DockStackCentral))
						return "an empty stack";
					if (!node.Panels.IsEmpty && (node.Active >= (uint32)node.Panels.Count))
						return "an active tab past the end";
					for (let panel in node.Panels)
					{
						for (let p in panels)
						{
							if (p == panel)
								return "a panel docked twice";
						}
						panels.Add(panel);
						++surfacePanels;
					}
					continue;
				}
				if ((node.Children.Count < 2) || (node.Weights.Count != node.Children.Count))
					return "a split of fewer than two, or shares not one each";
				float sum = 0.0f;
				for (int c < node.Children.Count)
				{
					sum += node.Weights[c];
					let child = FindNode(node.Children[c]);
					if ((child == null) || (child.Parent != id))
						return "a child's parent is not its split";
					if (!child.IsStack && (child.Axis == node.Axis))
						return "a split inside a split of its axis";
					todo.Add(child.Id);
				}
				if (Math.Abs(sum - 1.0f) > 1.0e-3f)
					return "shares that do not sum to one";
			}
			if ((surface.Kind == .Floating) && (surfacePanels == 0))
				return "an empty floating surface";
		}
		if (seen.Count != mNodes.Count)
			return "a node in no surface";
		let central = CentralStack;
		if ((central == cNoDock) || (SurfaceOf(central) != MainSurface))
			return "the central stack is not in the main surface";
		for (let hidden in mHidden)
		{
			for (let p in panels)
			{
				if (p == hidden.Panel)
					return "a panel both docked and hidden";
			}
		}
		return default;
	}

	// === Checks ===

	private DockOutcome CanEnter(StringView panel)
	{
		if (panel.IsEmpty)
			return DockOutcome.Refuse("a panel needs an id");
		if (StackOf(panel) != cNoDock)
			return DockOutcome.Refuse("it is docked already: move it");
		return .();
	}

	private DockOutcome CanLeave(StringView panel)
	{
		let stack = StackOf(panel);
		if (stack == cNoDock)
			return DockOutcome.Refuse("it is not docked");
		if (FindNode(stack).Has(DockStackLocked))
			return DockOutcome.Refuse("its stack is locked");
		return .();
	}

	private DockOutcome CanTabInto(DockNodeId stack)
	{
		let node = FindNode(stack);
		if ((node == null) || !node.IsStack)
			return DockOutcome.Refuse("not a stack");
		if (node.Has(DockStackLocked))
			return DockOutcome.Refuse("that stack is locked");
		if (node.Has(DockStackNoTabs) && !node.Panels.IsEmpty)
			return DockOutcome.Refuse("that stack holds one panel");
		return .();
	}

	// A floating surface, docked whole at `stack` of another surface.
	private DockOutcome CanDockWhole(DockSurfaceId surface, DockNodeId stack)
	{
		let from = FindSurface(surface);
		if ((from == null) || (from.Kind != .Floating))
			return DockOutcome.Refuse("not a floating surface");
		if (FindNode(stack) == null)
			return DockOutcome.Refuse("no such stack");
		if (SurfaceOf(stack) == surface)
			return DockOutcome.Refuse("a surface cannot dock into itself");
		return .();
	}

	// A stack picked up whole: one there, with panels, not locked.
	private DockOutcome CanMoveStack(DockNodeId stack)
	{
		let node = FindNode(stack);
		if ((node == null) || !node.IsStack)
			return DockOutcome.Refuse("not a stack");
		if (node.Panels.IsEmpty)
			return DockOutcome.Refuse("the stack is empty");
		if (node.Has(DockStackLocked))
			return DockOutcome.Refuse("its stack is locked");
		return .();
	}

	private DockOutcome CanDockBeside(DockNodeId stack)
	{
		let node = FindNode(stack);
		if ((node == null) || !node.IsStack)
			return DockOutcome.Refuse("not a stack");
		if (node.Has(DockStackNoSplit))
			return DockOutcome.Refuse("nothing docks beside that stack");
		return .();
	}

	// === Changes (Normalize after) ===

	// A node of the table's (it owns it).
	private DockNode MakeNode(DockNodeKind kind)
	{
		let node = new DockNode();
		node.Id = mNextNode++;
		node.Kind = kind;
		mNodes.Add(node);
		return node;
	}

	private static uint32 IndexIn(DockNode stack, StringView panel)
	{
		for (int i < stack.Panels.Count)
		{
			if (stack.Panels[i] == panel)
				return (uint32)i;
		}
		return 0;
	}

	private void Unhide(StringView panel)
	{
		for (int i < mHidden.Count)
		{
			if (mHidden[i].Panel == panel)
			{
				let gone = mHidden[i];
				mHidden.RemoveAt(i);
				delete gone;
				return;
			}
		}
	}

	// Out of its stack, which may be left empty until Normalize.
	private void TakeOut(StringView panel)
	{
		let stack = FindNode(StackOf(panel));
		let at = IndexIn(stack, panel);
		let gone = stack.Panels[(int)at];
		stack.Panels.RemoveAt((int)at);
		delete gone;
		if ((stack.Active > at) || (stack.Active >= (uint32)stack.Panels.Count))
			stack.Active = (stack.Active > 0) ? stack.Active - 1 : 0;
	}

	private void PlaceTab(StringView panel, DockNodeId stackId, int32 index)
	{
		let stack = FindNode(stackId);
		let at = (index < 0) ? stack.Panels.Count : Math.Min((int)index, stack.Panels.Count);
		stack.Panels.Insert(at, new String(panel));
		stack.Active = (uint32)at;
	}

	// A new stack holding `panel`, `share` of `targetId`'s room, on `side` of it.
	private void PlaceBeside(StringView panel, DockNodeId targetId, DockSide side, float share)
	{
		let made = MakeNode(.Stack);
		made.Panels.Add(new String(panel));
		PlaceNodeBeside(made.Id, targetId, side, share);
	}

	// Node `madeId` (a root of none) `share` of `targetId`'s room, on `side` of it.
	private void PlaceNodeBeside(DockNodeId madeId, DockNodeId targetId, DockSide side, float share)
	{
		var share;
		share = Math.Clamp(share, 0.05f, 0.95f);
		let target = FindNode(targetId);
		let axis = AxisOf(side);
		let parent = FindNode(target.Parent);
		if ((parent != null) && (parent.Axis == axis))
		{
			// A sibling in the split it is in: its share parted between them.
			int at = 0;
			while (parent.Children[at] != targetId)
				++at;
			let had = parent.Weights[at];
			parent.Weights[at] = had * (1.0f - share);
			let place = IsBefore(side) ? at : at + 1;
			parent.Children.Insert(place, madeId);
			parent.Weights.Insert(place, had * share);
			FindNode(madeId).Parent = parent.Id;
			return;
		}
		Wrap(targetId, madeId, axis, IsBefore(side), share);
	}

	// A new stack holding `panel` along the whole surface's edge.
	private void PlaceAtEdge(StringView panel, DockSurfaceId surfaceId, DockSide side, float share)
	{
		let made = MakeNode(.Stack);
		made.Panels.Add(new String(panel));
		PlaceNodeAtEdge(made.Id, surfaceId, side, share);
	}

	// Node `madeId` (a root of none) along the whole surface's edge.
	private void PlaceNodeAtEdge(DockNodeId madeId, DockSurfaceId surfaceId, DockSide side, float share)
	{
		var share;
		share = Math.Clamp(share, 0.05f, 0.95f);
		let axis = AxisOf(side);
		let root = FindNode(FindSurface(surfaceId).Root);
		if (!root.IsStack && (root.Axis == axis))
		{
			for (int w < root.Weights.Count)
				root.Weights[w] *= 1.0f - share;
			let place = IsBefore(side) ? 0 : root.Children.Count;
			root.Children.Insert(place, madeId);
			root.Weights.Insert(place, share);
			FindNode(madeId).Parent = root.Id;
			return;
		}
		Wrap(root.Id, madeId, axis, IsBefore(side), share);
	}

	// `targetId` and `madeId` in a new split of `axis` where `targetId` was, `madeId` first when
	// `before`, with `share` of the room.
	private void Wrap(DockNodeId targetId, DockNodeId madeId, DockAxis axis, bool before, float share)
	{
		let split = MakeNode(.Split);
		let splitId = split.Id;
		split.Axis = axis;
		let target = FindNode(targetId);
		split.Parent = target.Parent;
		let parent = FindNode(target.Parent);
		if (parent != null)
		{
			for (int c < parent.Children.Count)
			{
				if (parent.Children[c] == targetId)
					parent.Children[c] = splitId;
			}
		}
		else
		{
			for (let surface in mSurfaces)
			{
				if (surface.Root == targetId)
					surface.Root = splitId;
			}
		}
		split.Children.Add(before ? madeId : targetId);
		split.Children.Add(before ? targetId : madeId);
		split.Weights.Add(before ? share : 1.0f - share);
		split.Weights.Add(before ? 1.0f - share : share);
		FindNode(targetId).Parent = splitId;
		FindNode(madeId).Parent = splitId;
	}

	// Removes child `index` from `split`, its share to its neighbours in proportion to theirs.
	private static void RemoveChild(DockNode split, int index)
	{
		let gone = split.Weights[index];
		split.Children.RemoveAt(index);
		split.Weights.RemoveAt(index);
		let before = (index > 0) ? split.Weights[index - 1] : 0.0f;
		let after = (index < split.Weights.Count) ? split.Weights[index] : 0.0f;
		let both = before + after;
		if (index > 0)
			split.Weights[index - 1] += (both > 0.0f) ? gone * before / both : gone;
		if (index < split.Weights.Count)
			split.Weights[index] += (both > 0.0f) ? gone * after / both : ((index > 0) ? 0.0f : gone);
	}

	private void Erase(DockNodeId id)
	{
		for (int i < mNodes.Count)
		{
			if (mNodes[i].Id == id)
			{
				let gone = mNodes[i];
				mNodes.RemoveAt(i);
				delete gone;
				return;
			}
		}
	}

	// Detaches `id` from where it is (its parent, or its surface: a floating surface goes; the
	// main one is never left without a root, since its central stack is never removed).
	private void Detach(DockNodeId id)
	{
		let node = FindNode(id);
		let parent = FindNode(node.Parent);
		if (parent != null)
		{
			for (int i < parent.Children.Count)
			{
				if (parent.Children[i] == id)
				{
					RemoveChild(parent, i);
					break;
				}
			}
			return;
		}
		for (int i < mSurfaces.Count)
		{
			if ((mSurfaces[i].Root == id) && (mSurfaces[i].Kind == .Floating))
			{
				let gone = mSurfaces[i];
				mSurfaces.RemoveAt(i);
				delete gone;
				return;
			}
		}
	}

	// Puts `childId` where `splitId` was (in its parent, with its share; or as a surface's root).
	private void Replace(DockNodeId splitId, DockNodeId childId)
	{
		let split = FindNode(splitId);
		let parentId = split.Parent;
		let parent = FindNode(parentId);
		if (parent != null)
		{
			for (int c < parent.Children.Count)
			{
				if (parent.Children[c] == splitId)
					parent.Children[c] = childId;
			}
		}
		else
		{
			for (let surface in mSurfaces)
			{
				if (surface.Root == splitId)
					surface.Root = childId;
			}
		}
		FindNode(childId).Parent = parentId;
	}

	// A stack taken from where it is, the root of none now, to be placed (a float it was all of
	// goes). The central stack stays where it is, emptied: a new stack takes its panels and goes.
	private DockNodeId TakeStack(DockNodeId stack)
	{
		if (FindNode(stack).Has(DockStackCentral))
		{
			let made = MakeNode(.Stack);
			let central = FindNode(stack);
			// The strings themselves move: the made stack owns them now.
			made.Panels.AddRange(central.Panels);
			made.Active = central.Active;
			central.Panels.Clear();
			central.Active = 0;
			return made.Id;
		}
		Detach(stack);
		FindNode(stack).Parent = cNoDock;
		return stack;
	}

	// A floating surface's root taken off it (the root of none now) and the surface gone.
	private DockNodeId Lift(DockSurfaceId surface)
	{
		let root = FindSurface(surface).Root;
		Detach(root); // a floating surface's root: the surface goes
		FindNode(root).Parent = cNoDock;
		return root;
	}

	// The panels under `id`, in order (stacks depth first), appended to `outPanels` as strings the
	// caller owns, and the first stack's active one in `active`.
	private void CollectPanels(DockNodeId id, List<String> outPanels, String active)
	{
		let node = FindNode(id);
		if (node == null)
			return;
		if (node.IsStack)
		{
			if (active.IsEmpty && !node.Panels.IsEmpty)
				active.Set(node.Panels[Math.Min((int)node.Active, node.Panels.Count - 1)]);
			for (let panel in node.Panels)
				outPanels.Add(new String(panel));
			return;
		}
		for (let child in node.Children)
			CollectPanels(child, outPanels, active);
	}

	private void StacksOf(DockSurfaceId surface, List<DockNodeId> outStacks)
	{
		for (let node in mNodes)
		{
			if (node.IsStack && (SurfaceOf(node.Id) == surface))
				outStacks.Add(node.Id);
		}
	}

	// This layout and `other` trade what they hold.
	private void Swap(DockLayout other)
	{
		Swap!(mNodes, other.mNodes);
		Swap!(mSurfaces, other.mSurfaces);
		Swap!(mHidden, other.mHidden);
		Swap!(mNextNode, other.mNextNode);
		Swap!(mNextSurface, other.mNextSurface);
	}

	private void Normalize()
	{
		for (bool changed = true; changed;)
		{
			changed = false;
			for (int i = 0; (i < mNodes.Count) && !changed; ++i)
			{
				let node = mNodes[i];
				if (node.IsStack)
				{
					// An empty stack goes, but the central one.
					if (node.Panels.IsEmpty && !node.Has(DockStackCentral))
					{
						let emptied = node.Id;
						Detach(emptied);
						Erase(emptied);
						changed = true;
					}
					continue;
				}
				let id = node.Id;
				if (node.Children.Count <= 1)
				{
					// A split of one gives way to it (of none, goes).
					if (node.Children.Count == 1)
						Replace(id, node.Children[0]);
					else
						Detach(id);
					Erase(id);
					changed = true;
					continue;
				}
				// A split of its own axis inside it: its children merged in, sharing its share.
				for (int c < node.Children.Count)
				{
					let child = FindNode(node.Children[c]);
					if ((child == null) || child.IsStack || (child.Axis != node.Axis))
						continue;
					let childId = child.Id;
					let grand = scope List<DockNodeId>();
					grand.AddRange(child.Children);
					let shares = scope List<float>();
					shares.AddRange(child.Weights);
					float sum = 0.0f;
					for (let share in shares)
						sum += share;
					let had = node.Weights[c];
					node.Children.RemoveAt(c);
					node.Weights.RemoveAt(c);
					for (int g < grand.Count)
					{
						node.Children.Insert(c + g, grand[g]);
						node.Weights.Insert(c + g, (sum > 0.0f) ? had * shares[g] / sum : had / (float)grand.Count);
						FindNode(grand[g]).Parent = id;
					}
					Erase(childId);
					changed = true;
					break;
				}
			}
		}
		// Shares summing to one; actives within their stacks; maximized stacks still there.
		for (let node in mNodes)
		{
			if (node.IsStack)
			{
				if (node.Active >= (uint32)node.Panels.Count)
					node.Active = node.Panels.IsEmpty ? 0 : (uint32)(node.Panels.Count - 1);
				continue;
			}
			float sum = 0.0f;
			for (let weight in node.Weights)
				sum += weight;
			for (int w < node.Weights.Count)
				node.Weights[w] = (sum > 0.0f) ? node.Weights[w] / sum : 1.0f / (float)node.Weights.Count;
		}
		for (let surface in mSurfaces)
		{
			if ((surface.Maximized != cNoDock) && (SurfaceOf(surface.Maximized) != surface.Id))
				surface.Maximized = cNoDock;
		}
	}

	// The panels of the stacks beside `stack` (its split's other children), appended to
	// `outPanels` as strings the caller owns.
	private void NeighboursBeside(DockNodeId stack, List<String> outPanels)
	{
		let node = FindNode(stack);
		let parent = (node != null) ? FindNode(node.Parent) : null;
		if (parent == null)
			return;
		for (let sibling in parent.Children)
		{
			if (sibling == stack)
				continue;
			// The stacks in the sibling's subtree, nearest first: enough to find a place near.
			let todo = scope List<DockNodeId>();
			todo.Add(sibling);
			while (!todo.IsEmpty)
			{
				let at = FindNode(todo[0]);
				todo.RemoveAt(0);
				if (at == null)
					continue;
				if (at.IsStack)
				{
					for (let panel in at.Panels)
						outPanels.Add(new String(panel));
				}
				else
				{
					for (let child in at.Children)
						todo.Add(child);
				}
			}
		}
	}
}
