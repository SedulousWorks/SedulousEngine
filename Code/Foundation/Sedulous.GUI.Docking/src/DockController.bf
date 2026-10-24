using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// DockController: a layout and the panels it places (D3 of Specs/gui-lab-evolution-3.md).
//
// Panels are registered by id with a description: the title and icon their tab shows, a factory
// for their content, what closing them does, whether they can be closed, and where they go when a
// restored layout does not place them. The controller owns each panel's content once made, so a
// panel moved to another stack or window, or hidden, keeps it (foundation.ui's port destroyed a
// panel that had no id on close and crashed reaching it after). Closing a panel follows its policy:
// Hide keeps its content and its place, Rebuild lets its content go and keeps its place (the
// factory makes it again when shown), Destroy lets both go.
//
// The layout changes through the controller, which tells every DockSpace showing it to show it
// again. What the user already did in the widgets (a separator dragged, a tab chosen or dragged to
// another place in its strip) is noted into the layout quietly: the widgets already show it.

enum DockClosePolicy : uint8
{
	/// Content kept, place kept.
	case Hide;
	/// Content let go, place kept: made again when shown.
	case Rebuild;
	/// Content and place let go.
	case Destroy;
}

class DockPanelDescription
{
	public String Id = new .() ~ delete _;
	/// Its tab's text (the id when empty).
	public String Title = new .() ~ delete _;
	/// Its tab's icon, by path.
	public String Icon = new .() ~ delete _;
	/// Makes its content: a node with a reference the controller takes.
	public delegate Node() Factory = null ~ delete _;
	public DockClosePolicy Close = .Hide;
	public bool Closable = true;
	/// Where it goes when a restored layout does not place it (its Panel: the id, set when it
	/// registers).
	public DockDefault Default = .();
}

/// What shows a controller's layout: told to show it again when it changed.
interface IDockView
{
	void ShowLayout();
	/// The panel a page it shows is for (its own string); null for a page it does not show.
	String PanelOf(Node page);
}

/// Where a dragged panel goes when dropped (D4): into a stack's strip at a tab's place, into a
/// stack (its middle), beside a stack (its edge band) or along a whole surface's edge.
enum DockDropKind : uint8
{
	case Tab;
	case Middle;
	case Beside;
	case Edge;
}

struct DockDrop
{
	public DockDropKind Kind = .Middle;
	/// Tab, Middle, Beside: the stack dropped on.
	public DockNodeId Stack = cNoDock;
	/// Edge: the surface.
	public DockSurfaceId Surface = cNoDock;
	/// Tab: its place among the stack's tabs, as they are now.
	public int32 Index = -1;
	/// Beside, Edge.
	public DockSide Side = .Start;

	public this() { }

	public this(DockDropKind kind, DockNodeId stack, DockSurfaceId surface, int32 index, DockSide side)
	{
		Kind = kind;
		Stack = stack;
		Surface = surface;
		Index = index;
		Side = side;
	}
}

/// What a dock drag carries: a docked panel (a tab torn out), a whole floating surface (a float
/// dragged by its title, D5) or a whole stack (its strip's grip).
class DockDragged
{
	public String Panel = new .() ~ delete _;
	public DockSurfaceId Surface = cNoDock;
	public DockNodeId Stack = cNoDock;

	public this() { }

	public this(StringView panel, DockSurfaceId surface = cNoDock, DockNodeId stack = cNoDock)
	{
		Panel.Set(panel);
		Surface = surface;
		Stack = stack;
	}

	public bool IsSurface => Surface != cNoDock;
	public bool IsStack => Stack != cNoDock;

	public void Set(DockDragged other)
	{
		Panel.Set(other.Panel);
		Surface = other.Surface;
		Stack = other.Stack;
	}

	public void Clear()
	{
		Panel.Clear();
		Surface = cNoDock;
		Stack = cNoDock;
	}
}

static
{
	/// The drag type of a whole floating surface; its value the surface's id (a uint64).
	public const String cDockSurfaceDragType = "gui/dock-surface";
	/// The drag type of a whole stack; its value the stack's id (a uint64).
	public const String cDockStackDragType = "gui/dock-stack";

	/// A docked panel dropped: the move it is, done on `layout` (a copy, to preview it and say why
	/// not, or the controller's).
	public static DockOutcome ApplyDrop(DockLayout layout, StringView panel, DockDrop drop)
	{
		switch (drop.Kind)
		{
		case .Tab:
			var index = drop.Index;
			// Among its own tabs: counted with it where it is, so a place past it is one less.
			let stack = layout.FindNode(drop.Stack);
			if ((stack != null) && (layout.StackOf(panel) == drop.Stack))
			{
				for (int i < stack.Panels.Count)
				{
					if ((stack.Panels[i] == panel) && (index > (int32)i))
						--index;
				}
			}
			return layout.MoveToTab(panel, drop.Stack, index);
		case .Middle: return layout.MoveToTab(panel, drop.Stack);
		case .Beside: return layout.MoveBeside(panel, drop.Stack, drop.Side);
		case .Edge: return layout.MoveToEdge(panel, drop.Surface, drop.Side);
		}
	}

	/// A drop of what a drag carries: a panel as above; a floating surface docked whole (into the
	/// stack over its strip or its middle, beside it, along the surface's edge); a stack moved whole
	/// the same ways (at a tab's place over a strip).
	public static DockOutcome ApplyDrop(DockLayout layout, DockDragged dragged, DockDrop drop)
	{
		if (dragged.IsStack)
		{
			switch (drop.Kind)
			{
			case .Tab: return layout.MoveStackInto(dragged.Stack, drop.Stack, drop.Index);
			case .Middle: return layout.MoveStackInto(dragged.Stack, drop.Stack);
			case .Beside: return layout.MoveStackBeside(dragged.Stack, drop.Stack, drop.Side);
			case .Edge: return layout.MoveStackToEdge(dragged.Stack, drop.Surface, drop.Side);
			}
		}
		if (!dragged.IsSurface)
			return ApplyDrop(layout, dragged.Panel, drop);
		switch (drop.Kind)
		{
		case .Tab, .Middle: return layout.DockSurfaceInto(dragged.Surface, drop.Stack);
		case .Beside: return layout.DockSurfaceBeside(dragged.Surface, drop.Stack, drop.Side);
		case .Edge: return layout.DockSurfaceAtEdge(dragged.Surface, drop.Surface, drop.Side);
		}
	}

	/// The panels a drag carries, as `layout` has them (a surface's, in its stacks' order),
	/// appended to `outPanels` as strings the caller owns.
	public static void PanelsOf(DockLayout layout, DockDragged dragged, List<String> outPanels)
	{
		if (dragged.IsStack)
		{
			let stack = layout.FindNode(dragged.Stack);
			if (stack != null)
			{
				for (let panel in stack.Panels)
					outPanels.Add(new String(panel));
			}
			return;
		}
		if (!dragged.IsSurface)
		{
			outPanels.Add(new String(dragged.Panel));
			return;
		}
		for (let node in layout.Nodes)
		{
			if (!node.IsStack || (layout.SurfaceOf(node.Id) != dragged.Surface))
				continue;
			for (let panel in node.Panels)
				outPanels.Add(new String(panel));
		}
	}
}

class DockController
{
	// Content a factory made, kept with its panel's id.
	private class Made
	{
		public String Panel = new .() ~ delete _;
		public Node Content = null ~ _?.ReleaseRef();
	}

	private DockLayout mLayout = new .() ~ delete _;
	private List<DockPanelDescription> mPanels = new .() ~ DeleteContainerAndItems!(_);
	private List<Made> mContents = new .() ~ DeleteContainerAndItems!(_);
	// The views showing it (not owned: each takes itself out as it goes).
	private List<IDockView> mViews = new .() ~ delete _;
	// A pass of ShowEverywhere is on.
	private bool mShowing = false;
	// The layout changed during it.
	private bool mShowAgain = false;
	// The view it is at.
	private int mShowAt = 0;

	/// A panel the layout may place; false when its id is empty or taken. OWNERSHIP of
	/// `description` transfers (one refused is deleted).
	public bool Register(DockPanelDescription description)
	{
		if (description.Id.IsEmpty || (Describe(description.Id) != null))
		{
			delete description;
			return false;
		}
		description.Default.Panel = description.Id;
		mPanels.Add(description);
		ShowEverywhere(); // a placeholder for it may show it now
		return true;
	}

	public DockPanelDescription Describe(StringView panel)
	{
		for (let description in mPanels)
		{
			if (description.Id == panel)
				return description;
		}
		return null;
	}

	/// The layout, to read; it changes through Edit and the controller's other calls.
	public DockLayout Layout => mLayout;

	/// Changes the layout through `edit` (borrowed); when it did something, every view shows it.
	public DockOutcome Edit(delegate DockOutcome(DockLayout layout) edit)
	{
		let outcome = edit(mLayout);
		if (outcome.Ok)
			ShowEverywhere();
		return outcome;
	}

	/// Closes a docked panel as its description says.
	public DockOutcome Close(StringView panel)
	{
		let description = Describe(panel);
		if ((description != null) && !description.Closable)
			return DockOutcome.Refuse("it cannot be closed");
		let id = scope String(panel);
		let outcome = mLayout.Close(id);
		if (!outcome.Ok)
			return outcome;
		let policy = (description != null) ? description.Close : DockClosePolicy.Hide;
		if (policy != .Hide)
			ForgetContent(id);
		if (policy == .Destroy)
			mLayout.Forget(id);
		ShowEverywhere();
		return outcome;
	}

	/// Shows a registered panel: where it was closed, else at its default place.
	public DockOutcome Show(StringView panel)
	{
		if (mLayout.StackOf(panel) != cNoDock)
			return DockOutcome.Refuse("it is docked");
		let id = scope String(panel);
		if (mLayout.FindHidden(id) != null)
			return Edit(scope (layout) => layout.Show(id));
		let description = Describe(id);
		if (description == null)
			return DockOutcome.Refuse("it is not registered");
		let place = description.Default;
		return Edit(scope (layout) =>
			{
				return place.Central ? layout.InsertTab(id, layout.CentralStack)
					: layout.InsertAtEdge(id, layout.MainSurface, place.Side, place.Share);
			});
	}

	/// A restored layout taken (DockLayout.Adopt with the registered panels' default places);
	/// `read` is left as it is.
	public DockOutcome Adopt(DockLayout read, Span<Rectangle> screens = default)
	{
		let defaults = scope List<DockDefault>();
		for (let description in mPanels)
			defaults.Add(description.Default);
		let outcome = mLayout.Adopt(read, defaults, screens);
		if (outcome.Ok)
			ShowEverywhere();
		return outcome;
	}

	/// A registered panel's content: made by its factory the first time it is asked for, kept
	/// after; null for a panel not registered (or one whose factory makes none). The controller
	/// keeps it: a caller that holds on to it takes a reference of its own.
	public Node Content(StringView panel)
	{
		for (let made in mContents)
		{
			if (made.Panel == panel)
				return made.Content;
		}
		let description = Describe(panel);
		if ((description == null) || (description.Factory == null))
			return null;
		let content = description.Factory();
		if (content != null)
		{
			let made = new Made();
			made.Panel.Set(panel);
			made.Content = content; // the factory's reference, the controller's now
			mContents.Add(made);
		}
		return content;
	}

	/// Whether a panel's content is made (and kept).
	public bool HasContent(StringView panel)
	{
		for (let made in mContents)
		{
			if (made.Panel == panel)
				return true;
		}
		return false;
	}

	// === What the widgets already show, noted quietly ===

	public void NoteWeights(DockNodeId split, Span<float> weights) { mLayout.SetWeights(split, weights); }
	public void NoteActive(StringView panel) { mLayout.Activate(panel); }
	public void NoteTabPlace(StringView panel, DockNodeId stack, int32 index) { mLayout.MoveToTab(panel, stack, index); }

	public void NoteSurfaceBounds(DockSurfaceId surface, Rectangle bounds)
	{
		let found = mLayout.FindSurface(surface);
		if (found != null)
			mLayout.SetSurfaceBounds(surface, bounds, found.Screen, found.Scale);
	}

	/// The panel a page some view shows is for (a dragged tab's); null when none shows it. The
	/// view's string.
	public String PanelShownBy(Node page)
	{
		for (let view in mViews)
		{
			let panel = view.PanelOf(page);
			if (panel != null)
				return panel;
		}
		return null;
	}

	// === The views ===

	public void AddView(IDockView view)
	{
		for (let known in mViews)
		{
			if ((Object)known == (Object)view)
				return;
		}
		mViews.Add(view);
	}

	public void RemoveView(IDockView view)
	{
		for (int i < mViews.Count)
		{
			if ((Object)mViews[i] != (Object)view)
				continue;
			mViews.RemoveAt(i);
			if (mShowing && (i <= mShowAt))
				--mShowAt; // the pass goes on with the view that took its place
			return;
		}
	}

	private void ForgetContent(StringView panel)
	{
		for (int i < mContents.Count)
		{
			if (mContents[i].Panel != panel)
				continue;
			let made = mContents[i];
			mContents.RemoveAt(i);
			made.Content.RemoveFromParent();
			delete made;
			return;
		}
	}

	// Each view shows the layout. A view may make or end others as it does (a floating surface's
	// window and its dock space): one made joins the pass, one ended leaves it; a change asked
	// for during the pass runs it again after.
	private void ShowEverywhere()
	{
		if (mShowing)
		{
			mShowAgain = true;
			return;
		}
		mShowing = true;
		repeat
		{
			mShowAgain = false;
			for (mShowAt = 0; mShowAt < mViews.Count; ++mShowAt)
				mViews[mShowAt].ShowLayout();
		}
		while (mShowAgain);
		mShowing = false;
	}
}
