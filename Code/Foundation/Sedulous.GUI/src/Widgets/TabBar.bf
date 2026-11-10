using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// TabBar: a strip of tabs, Godot's TabBar split from the container that shows pages (TabView),
// each tab a real element as zed's and eepp's are: the button core with its text and icon parts
// and a close part. A press selects a tab (`:checked` styles it); the arrows, Home and End move
// along the strip, Ctrl+Tab and Ctrl+Shift+Tab (and Ctrl+Page Down and Up) cycle round it.
// Closing is a request: the close part or a middle click reports `tabclose` (a TabEvent), and the
// tab goes unless a listener takes the event; which tabs show their close part is the bar's
// policy (never, the selected one, the hovered and selected ones, all). With `reorderable`, a tab
// dragged across a neighbour's midpoint changes places with it. In a strip of a `group` a tab
// moved past the drag threshold, any way, is a drag at once (type `gui/tab`) that the group's
// strips take, its own too (a reorder when it is `reorderable`), a mark showing where it would
// land; between tab views its page goes with it. Tabs past the strip's end scroll it (the wheel
// turns it, a selected tab is scrolled to), and a button at its end lists them all (shown while
// they overflow, or always: `list-display`); with `close-all`, a part past it asks to close every
// closable tab.
//
// A change the user makes reports `change`; code's report only to bindings, as a button's do.

/// Which tabs show their close part.
enum TabCloseDisplay : uint8
{
	/// None: tabs close from code alone.
	Never,
	/// The selected tab's.
	Selected,
	/// The selected tab's and the hovered one's.
	Hover,
	/// Every closable tab's.
	Always,
}

/// When the strip's list button shows.
enum TabListDisplay : uint8
{
	/// While the tabs overflow the strip.
	Overflow,
	/// Always (a strip whose button does more than list: docking's).
	Always,
}

static
{
	/// A cross in `color` filling `area` (the close parts').
	public static void DrawTabCross(DrawContext ctx, Rect area, Color color)
	{
		let s = Math.Min(area.Width, area.Height) * 0.5f;
		let cx = area.X + area.Width * 0.5f;
		let cy = area.Y + area.Height * 0.5f;
		let cross = scope PathBuilder();
		cross.MoveTo(cx - s, cy - s);
		cross.LineTo(cx + s, cy + s);
		cross.MoveTo(cx + s, cy - s);
		cross.LineTo(cx - s, cy + s);
		let path = cross.ToPath();
		ctx.VG.StrokePath(path, color, StrokeStyle(1.5f, .Round, .Round));
		delete path;
	}
}

/// A tab's close part (`tab > close`): a cross in its text colour.
[GuiReflect]
class TabCloseButton : ButtonBase
{
	public this()
	{
		Tag = "close";
		TabFocusable = false; // the keyboard closes from the tab, not a stop of its own
	}

	public override Float2 MeasureContent(Float2 available) => .(10.0f, 10.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		DrawTabCross(ctx, ContentBounds, TextColor);
	}

	// A press on it is its own: the tab under it neither selects nor starts a drag.
	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button == .Left)
			e.Handled = true;
	}
}

/// One tab: the button core's text and icon, and a close part.
[GuiReflect(true)]
class Tab : ButtonBase
{
	/// Points a press moves before it reorders.
	private const float cDragThreshold = 4.0f;

	private TabCloseButton mClose ~ _.ReleaseRef();
	// What it shows (a TabView's page), not owned.
	private Node mPage = null;
	private bool mClosable = true;
	private bool mSelected = false;
	// A left press on it, not yet released.
	private bool mPressing = false;
	// That press moved far enough to reorder.
	private bool mDragging = false;
	private float mPressX = 0.0f;
	// The bar told it was torn out, told again when the drag ends (a reference held).
	private TabBar mTornFrom = null ~ _?.ReleaseRef();

	public this()
	{
		Tag = "tab";
		AccessRoleName = "tab"; // what a screen reader takes it for
		mClose = new TabCloseButton();
		mClose.Displayed = false;
		mClose.SetOnClick(new () =>
			{
				let bar = Bar;
				if (bar != null)
					bar.RequestClose(bar.IndexOf(this));
			});
		AddChild(mClose); // after its icon and text
		// Torn out (by the pointer or `drag.pick`): its bar hears it, and again when the drag ends.
		AddEventListener(.DragStart, new (e) =>
			{
				let bar = Bar;
				if ((bar == null) || (TabBar.DraggedTab(((DragEvent)e).Payload) != this))
					return;
				bar.AddRef();
				if (mTornFrom != null)
					mTornFrom.ReleaseRef();
				mTornFrom = bar;
				bar.TellTorn(this, true);
			});
	}

	/// It can be closed (its close part shown as the bar's policy says, a middle click).
	[GuiProperty("closable")]
	public bool Closable
	{
		get => mClosable;
		set
		{
			mClosable = value;
			UpdateClose();
		}
	}

	public bool IsSelected => mSelected;
	public override bool IsCurrentInGroup => mSelected;
	public TabCloseButton ClosePart => mClose;

	/// The bar it is in (null when it is in none).
	public TabBar Bar
	{
		get
		{
			let strip = Parent;
			return (strip != null) ? (strip.Parent as TabBar) : null;
		}
	}

	/// What it shows (a TabView's page), not owned.
	public Node Page
	{
		get => mPage;
		set => mPage = value;
	}

	public override uint32 WidgetStates => mSelected ? WidgetStateChecked : WidgetStateNone;

	// In a reorderable strip of no group its press reorders it: a drag from what holds it is not
	// offered. In a group's strip the press is the drag's, which it gives.
	public override bool OwnsPressDrag(Float2 local)
	{
		let bar = Bar;
		return (bar != null) && bar.Reorderable && bar.Group.IsEmpty;
	}

	// A drag resting on it selects it (Godot's switch on drag hover).
	protected override bool OnDragHoverOpen(Float2 local)
	{
		let bar = Bar;
		if ((bar == null) || mSelected)
			return false;
		bar.SelectByUser(bar.IndexOf(this));
		return true;
	}

	/// In a strip of a group: the pointer's drag past the threshold, held where it was pressed,
	/// or picked up from the keyboard (`drag.pick`).
	protected override bool OnDragRequested(DragRequest request)
	{
		let bar = Bar;
		if ((bar == null) || bar.Group.IsEmpty)
			return false;
		FillTabPayload(request.Payload);
		if (!request.FromKeyboard)
		{
			request.GrabOffset = request.Press; // its ghost held where the press took it
			request.HasGrabOffset = true;
		}
		return true;
	}

	/// The drag a tab torn out of its strip is: its value a weak reference to it, which resolves
	/// while it lives.
	public void FillTabPayload(DragPayload payload)
	{
		payload.Type.Set("gui/tab");
		payload.Value.Dispose();
		payload.Value = System.Variant.Create(TakeElementRef());
		payload.Label.Set(Text);
		payload.Allowed = DropEffectsMove;
	}

	/// A torn tab's ghost: its title in a `dragpreview.tab`, its own size (held where it was
	/// grabbed, so it does not jump beside the pointer).
	public override Node CreateDragPreview(DragPayload payload)
	{
		let ghost = base.CreateDragPreview(payload);
		if (let widget = ghost as UIWidget)
		{
			widget.AddClass("tab");
			let size = Size;
			using (StyleWriteScope(widget))
			{
				widget.EditLayoutStyle(scope (s) =>
					{
						s.Width = LayoutLength.Px(size.X);
						s.Height = LayoutLength.Px(size.Y);
					});
			}
		}
		return ghost;
	}

	protected override bool OnActivate()
	{
		let bar = Bar;
		if (bar != null)
			bar.SelectByUser(bar.IndexOf(this));
		return true;
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		let bar = Bar;
		if (bar == null)
			return;
		if (e.Button == .Middle)
		{
			// A middle click closes it (as a browser's tabs do), where its policy shows a close.
			if (mClosable && (bar.CloseDisplay != .Never))
				bar.RequestClose(bar.IndexOf(this));
			e.Handled = true;
			return;
		}
		if (e.Button != .Left)
			return;
		e.Handled = true;
		RequestFocus();
		bar.SelectByUser(bar.IndexOf(this));
		mPressing = true;
		mDragging = false;
		mPressX = e.Position.X;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		let bar = Bar;
		// A group's strip: the dispatcher's drag past its threshold (OnDragRequested), not this.
		if (!mPressing || (bar == null) || !bar.Reorderable || !bar.Group.IsEmpty)
			return;
		if (!mDragging && (Math.Abs(e.Position.X - mPressX) < cDragThreshold))
			return;
		if (!mDragging)
		{
			mDragging = true;
			AddClass("dragging");
		}
		bar.DragTab(this, e.Position);
	}

	protected override void OnMouseUp(MouseEvent e)
	{
		base.OnMouseUp(e);
		EndDrag();
	}

	protected override void OnPointerCancel(MouseEvent e)
	{
		base.OnPointerCancel(e);
		EndDrag();
	}

	protected override void OnPointerCaptureLost()
	{
		EndDrag();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let bar = Bar;
		if ((bar == null) || (e.Modifiers != 0))
			return;
		let at = bar.IndexOf(this);
		int32 to = -1;
		switch ((KeyCode)e.KeyCode)
		{
		// Along the strip as it runs: right to left, Left goes on to the next tab.
		case .Left, .Right:
			to = at + InlineStep((KeyCode)e.KeyCode);
		case .Home:
			to = 0;
		case .End:
			to = bar.TabCount - 1;
		default:
			return;
		}
		// The arrows stop at the ends (navigation then leaves the strip); Home and End always land.
		let target = bar.GetTab(to);
		if (target == null)
			return;
		bar.SelectByUser(to);
		target.RequestFocus();
		e.Handled = true;
	}

	protected override void OnDragEnd(DragResult result)
	{
		let from = mTornFrom;
		mTornFrom = null; // the reference moves to `from`
		if (from != null)
		{
			from.TellTorn(this, false);
			from.TellDragEnded(this, result);
			from.ReleaseRef();
		}
	}

	protected override void OnPointerStateChange()
	{
		base.OnPointerStateChange();
		UpdateClose(); // the hover policy shows it while hovered
	}

	internal void SetSelectedState(bool selected)
	{
		if (selected == mSelected)
			return;
		mSelected = selected;
		MarkStyleStateDirty(StateChecked);
		UpdateClose();
		Invalidate();
	}

	internal void UpdateClose()
	{
		let bar = Bar;
		let display = (bar != null) ? bar.CloseDisplay : TabCloseDisplay.Never;
		// Shown or not by the policy, the part keeps its room while the tab is closable, so a
		// hovered tab does not grow.
		mClose.Displayed = mClosable && (display != .Never);
		let shown = (display == .Always) || ((display == .Selected) && mSelected) ||
			((display == .Hover) && (mSelected || Hovered));
		mClose.Visible = shown;
		if (bar != null)
			bar.UpdateCloseAll(); // its closability may be what changed
	}

	private void EndDrag()
	{
		mPressing = false;
		if (mDragging)
		{
			mDragging = false;
			RemoveClass("dragging");
		}
	}
}

// The row the tabs are in: it scrolls across, its bar hidden.
[GuiReflect]
class TabStrip : Panel
{
	// Its parent, which owns it.
	private TabBar mBar;

	public this(TabBar bar)
	{
		mBar = bar;
		Tag = "tabstrip";
		AccessRoleName = "tablist"; // what a screen reader takes it for
		FocusGroup = true; // one Tab stop, the selected tab; the arrows move between tabs
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Stretch;
					s.ColumnGap = 2.0f;
					s.Grow = 1.0f;
					s.MinWidth = LayoutLength.Px(0.0f); // narrower than its tabs: it scrolls
					s.OverflowX = .Scroll;
					s.BarWidth = .None;
				});
		}
	}

	public override void OnChildrenChanged()
	{
		mBar.TabsChanged();
	}
}

// The button at the strip's end that lists every tab (shown while they overflow, or always).
[GuiReflect]
class TabListButton : ButtonBase
{
	public this()
	{
		Tag = "tablist";
		TabFocusable = false; // the arrows and Ctrl+Tab reach every tab already
	}

	public override Float2 MeasureContent(Float2 available) => .(12.0f, 12.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		DrawDisclosure(ctx, ContentBounds, true, TextColor, IsRightToLeft);
	}
}

// The button past the list button that closes every closable tab (`closeall`, with `close-all`;
// shown while one is closable).
[GuiReflect]
class TabCloseAllButton : ButtonBase
{
	public this()
	{
		Tag = "closeall";
		TabFocusable = false; // the keyboard closes tab by tab
	}

	public override Float2 MeasureContent(Float2 available) => .(10.0f, 10.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		DrawTabCross(ctx, ContentBounds, TextColor);
	}
}

[GuiReflect(true)]
class TabBar : UIWidget
{
	private TabStrip mStrip ~ _.ReleaseRef();
	private TabListButton mList ~ _.ReleaseRef();
	private TabCloseAllButton mCloseAllPart ~ _.ReleaseRef();
	private Menu mMenu = null ~ _?.ReleaseRef();
	// A child of the strip, which owns it.
	private Tab mSelected = null;
	// The tabs as they were (to tell which left), not owned.
	private List<Tab> mKnown = new .() ~ delete _;
	// What bindings reading the selection follow.
	private Observable mSelectedChanged = new .() ~ delete _;
	private TabCloseDisplay mCloseDisplay = .Never;
	private TabListDisplay mListDisplay = .Overflow;
	private bool mCloseAll = false;
	private bool mReorderable = false;
	// A selection asked for before its tab was there.
	private int32 mPendingSelect = -1;
	// Where the selected tab is (removed, the one after it takes its place).
	private int32 mSelectedAt = 0;
	private delegate void(int32 index) mOnSelected ~ delete _;
	private delegate void(int32 index) mOnSelectionChanged ~ delete _;
	private delegate void(int32 from, int32 to) mOnMoved ~ delete _;
	private delegate void(Tab tab) mOnRemoved ~ delete _;
	private delegate void(int32 index) mCloseHandler ~ delete _;
	private String mGroup = new .() ~ delete _;
	private int32 mDropIndex = -1;
	private delegate void(Node page, int32 index) mPageAdopter ~ delete _;
	private delegate void(DropQuery query, Tab tab, int32 index) mOnTabOffered ~ delete _;
	private delegate void(Tab tab, int32 index) mTabTaker ~ delete _;
	private delegate void(Tab tab, bool torn) mOnTabTorn ~ delete _;
	private delegate void(Tab tab, DragResult result) mOnTabDragEnded ~ delete _;

	public this()
	{
		Tag = "tabbar";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Stretch;
				});
		}
		mStrip = new TabStrip(this);
		AddChild(mStrip);
		mList = new TabListButton();
		mList.Displayed = false;
		mList.SetOnClick(new () => { OpenTabList(); });
		AddChild(mList);
		mCloseAllPart = new TabCloseAllButton();
		mCloseAllPart.Displayed = false;
		mCloseAllPart.SetOnClick(new () => { CloseAll(); });
		AddChild(mCloseAllPart);
	}

	// === Tabs ===

	/// Adds a tab with `text` at `index` (past the end: last); the first tab is selected.
	public Tab InsertTab(int32 index, StringView text)
	{
		let tab = new Tab();
		tab.Text = text;
		mStrip.AddChildAt(tab, (index < 0) ? mStrip.ChildCount : Math.Min((int)index, mStrip.ChildCount));
		mSelectedAt = Math.Max(0, IndexOf(mSelected)); // placed after it was added, before the selection perhaps
		tab.ReleaseRef(); // the strip's reference keeps it
		return tab;
	}

	public Tab AddTab(StringView text) => InsertTab(-1, text);

	/// Removes a tab; were it selected, the one after it is (else the one before).
	public void RemoveTab(int32 index)
	{
		let tab = GetTab(index);
		if (tab != null)
			mStrip.RemoveChild(tab);
	}

	public int32 TabCount => (int32)mStrip.ChildCount;

	public Tab GetTab(int32 index) => ((index >= 0) && (index < TabCount)) ? (mStrip.GetChildAt(index) as Tab) : null;

	public int32 IndexOf(Tab tab)
	{
		let at = (tab != null) ? mStrip.GetChildIndex(tab) : cInvalidIndex;
		return (at == cInvalidIndex) ? -1 : (int32)at;
	}

	/// Moves a tab to `to` (code's: reports only to the moved callback).
	public void MoveTab(int32 from, int32 to)
	{
		let tab = GetTab(from);
		if ((tab == null) || (to < 0) || (to >= TabCount) || (to == from))
			return;
		mStrip.SetChildIndex(tab, to);
		mSelectedAt = Math.Max(0, IndexOf(mSelected));
		if (mOnMoved != null)
			mOnMoved(from, to);
	}

	// === Selection ===

	/// The selected tab's index (-1: none), a read a binding records. Set from code: no events.
	/// An index past the tabs waits for them (markup's `selected` is read before its tabs are
	/// made).
	[GuiProperty("selected", .TwoWay)]
	public int32 SelectedIndex
	{
		get
		{
			mSelectedChanged.Track();
			return IndexOf(mSelected);
		}
		set
		{
			mPendingSelect = (value >= TabCount) ? value : -1;
			if (mPendingSelect < 0)
				Select(GetTab(value), false);
		}
	}

	public Tab SelectedTab => mSelected;

	/// Selects as the user does: reports `change` when it changes.
	public void SelectByUser(int32 index)
	{
		Select(GetTab(index), true);
	}

	/// Moves the selection by `step` round the strip (Ctrl+Tab's), as the user does.
	public void CycleSelection(int32 step)
	{
		let count = TabCount;
		if (count == 0)
			return;
		let from = Math.Max(0, IndexOf(mSelected));
		SelectByUser(((from + step) % count + count) % count);
		if ((mSelected != null) && IsFocusWithin)
			mSelected.RequestFocus();
	}

	// === Closing ===

	/// Which tabs show their close part.
	public TabCloseDisplay CloseDisplay
	{
		get => mCloseDisplay;
		set
		{
			mCloseDisplay = value;
			for (int32 i = 0; i < TabCount; ++i)
				GetTab(i).UpdateClose();
		}
	}

	/// "never", "selected", "hover" or "always" (markup's and a sheet's `close-display`).
	[GuiProperty("close-display")]
	public StringView CloseDisplayName
	{
		get => TabBarDetail.sCloseDisplayNames[(int)mCloseDisplay];
		set
		{
			var display = TabCloseDisplay.Never;
			for (int i = 0; i < 4; ++i)
			{
				if (ParseUtil.Trim(value) == TabBarDetail.sCloseDisplayNames[i])
					display = (TabCloseDisplay)i;
			}
			CloseDisplay = display;
		}
	}

	/// Asks to close every closable tab, last first, each as its close part does (what the
	/// close-all part does). By place, not by tab: an owner may make its tabs again after each
	/// close (docking does), and those before the one closed keep their places.
	public void CloseAll()
	{
		AddRef(); // an owner may let it go on the way
		for (int32 i = TabCount; i-- > 0;)
		{
			if ((i < TabCount) && GetTab(i).Closable)
				RequestClose(i);
		}
		ReleaseRef();
	}

	/// A part past the list button closes every closable tab (markup's and a sheet's
	/// `close-all`), shown while one is closable.
	[GuiProperty("close-all")]
	public bool ShowsCloseAll
	{
		get => mCloseAll;
		set
		{
			mCloseAll = value;
			UpdateCloseAll();
		}
	}

	public Node CloseAllPart => mCloseAllPart;

	/// Asks to close a tab, as its close part does: `tabclose` is reported, and unless a listener
	/// takes it, the tab goes. (A TabView takes the request over.)
	public void RequestClose(int32 index)
	{
		let tab = GetTab(index);
		if ((tab == null) || !tab.Closable)
			return;
		if (mCloseHandler != null)
		{
			mCloseHandler(index);
			return;
		}
		let request = scope TabEvent(.TabClose, this, index);
		SendEvent(request);
		if (!request.Handled)
			RemoveTab(index);
	}

	// === Reordering ===

	/// A tab dragged across a neighbour's midpoint changes places with it (in a group's strip,
	/// dropped back into the strip at a new place).
	[GuiProperty("reorderable")]
	public bool Reorderable
	{
		get => mReorderable;
		set => mReorderable = value;
	}

	// === Between strips ===

	/// Strips of one group take each other's tabs (torn out and dropped); empty: none.
	[GuiProperty("group")]
	public StringView Group
	{
		get => mGroup;
		set => mGroup.Set(value);
	}

	/// Where a tab dropped here would go, while a drag of one is over the strip (-1: none).
	public int32 DropIndex => mDropIndex;

	/// Whether it takes a dragged tab (a torn-out tab of its group), and puts the mark at
	/// `index`; what a TabView asks for a drop anywhere over it.
	public bool OfferTab(DropQuery query, int32 index)
	{
		let tab = DraggedTab(query.Payload);
		let from = (tab != null) ? tab.Bar : null;
		if ((from == null) || mGroup.IsEmpty || (from.Group != Group) || ((from == this) && !mReorderable))
			return false;
		query.Accept(.Move);
		query.Place = index;
		if (mOnTabOffered != null)
		{
			mOnTabOffered(query, tab, index);
			if (query.Refused)
			{
				SetDropIndex(-1);
				return true; // answered: the walk ends with the reason
			}
			if (query.Effect == .None)
			{
				SetDropIndex(-1);
				return false; // passed on: what holds the strip is asked
			}
		}
		SetDropIndex(index);
		return true;
	}

	/// Clears the mark (the drag left).
	public void ClearTabMark()
	{
		SetDropIndex(-1);
	}

	/// Takes the dragged tab at the marked place.
	public void DropTab(DragPayload payload)
	{
		let tab = DraggedTab(payload);
		let from = (tab != null) ? tab.Bar : null;
		let index = mDropIndex;
		SetDropIndex(-1);
		if ((from == null) || (index < 0))
			return;
		tab.AddRef();
		defer tab.ReleaseRef();
		if (mTabTaker != null)
		{
			mTabTaker(tab, index);
			return;
		}
		if (from == this)
		{
			// Within the strip: before the tab at `index` (its own place counted out).
			let at = IndexOf(tab);
			MoveTab(at, (index > at) ? index - 1 : index);
			SelectByUser(IndexOf(tab));
			return;
		}
		let page = tab.Page;
		if ((page != null) && (mPageAdopter != null))
		{
			// Between tab views: the page moves, and its view makes its tab here.
			page.AddRef();
			page.RemoveFromParent(); // its old view lets the tab go with it
			mPageAdopter(page, index);
			SelectByUser(Math.Min(index, TabCount - 1));
			page.ReleaseRef();
			return;
		}
		// Between bars: the tab itself moves.
		mStrip.AddChildAt(tab, Math.Min(index, TabCount));
		SelectByUser(IndexOf(tab));
	}

	/// Takes the page of a tab dropped here from another view (a TabView's): the page goes to it
	/// at an index, and its tab comes with it. OWNERSHIP of `adopter` transfers.
	public void SetPageAdopter(delegate void(Node page, int32 index) adopter)
	{
		delete mPageAdopter;
		mPageAdopter = adopter;
	}

	/// Asked when a tab of its group is offered at `index` (accepted already): it may refuse it,
	/// saying why, pass it on (its effect set back to none: what holds the strip is asked), or say
	/// what the drop would do (the query's Reason). An owner that keeps where tabs are elsewhere
	/// (docking) answers with its own rules. OWNERSHIP of `offered` transfers.
	public void SetOnTabOffered(delegate void(DropQuery query, Tab tab, int32 index) offered)
	{
		delete mOnTabOffered;
		mOnTabOffered = offered;
	}

	/// Takes a dropped tab over: the bar moves nothing, the taker does (`index` counted with every
	/// tab where it is, the dropped one too when it is this bar's). OWNERSHIP of `taker`
	/// transfers.
	public void SetTabTaker(delegate void(Tab tab, int32 index) taker)
	{
		delete mTabTaker;
		mTabTaker = taker;
	}

	/// A tab of its own was torn out as a drag (`torn`), or that drag ended, dropped or not (the
	/// tab may be in another bar by then): an owner may hide or dim it meanwhile. A tab not
	/// displayed is no place for a drop. OWNERSHIP of `torn` transfers.
	public void SetOnTabTorn(delegate void(Tab tab, bool torn) torn)
	{
		delete mOnTabTorn;
		mOnTabTorn = torn;
	}

	/// How the drag of a tab torn out of it ended (after it hears the tab is no longer torn): an
	/// owner that does something with a tab let go outside every window (docking floats it).
	/// OWNERSHIP of `ended` transfers.
	public void SetOnTabDragEnded(delegate void(Tab tab, DragResult result) ended)
	{
		delete mOnTabDragEnded;
		mOnTabDragEnded = ended;
	}

	// === Callbacks ===

	/// The user selected a tab (the `change` event's). OWNERSHIP of `callback` transfers.
	public void SetOnSelected(delegate void(int32 index) callback)
	{
		delete mOnSelected;
		mOnSelected = callback;
	}

	/// Each change of the selection, the user's or code's (what shows a tab's page follows it).
	/// OWNERSHIP of `callback` transfers.
	public void SetOnSelectionChanged(delegate void(int32 index) callback)
	{
		delete mOnSelectionChanged;
		mOnSelectionChanged = callback;
	}

	/// A tab moved, by a drag or MoveTab. OWNERSHIP of `callback` transfers.
	public void SetOnTabMoved(delegate void(int32 from, int32 to) callback)
	{
		delete mOnMoved;
		mOnMoved = callback;
	}

	/// A tab left the bar (closed, or removed by code). OWNERSHIP of `callback` transfers.
	public void SetOnTabRemoved(delegate void(Tab tab) callback)
	{
		delete mOnRemoved;
		mOnRemoved = callback;
	}

	/// Takes close requests over (a TabView's): the bar then neither reports nor closes.
	/// OWNERSHIP of `handler` transfers.
	public void SetCloseHandler(delegate void(int32 index) handler)
	{
		delete mCloseHandler;
		mCloseHandler = handler;
	}

	public Node Strip => mStrip;
	public Node ListButton => mList;

	/// When the list button shows: while the tabs overflow (the default) or always.
	public TabListDisplay ListDisplay
	{
		get => mListDisplay;
		set
		{
			mListDisplay = value;
			RequestLayout();
		}
	}

	/// "overflow" or "always" (markup's and a sheet's `list-display`).
	[GuiProperty("list-display")]
	public StringView ListDisplayName
	{
		get => (mListDisplay == .Always) ? "always" : "overflow";
		set => ListDisplay = (ParseUtil.Trim(value) == "always") ? .Always : .Overflow;
	}

	/// The menu of every tab, while it is open (null otherwise).
	public Menu TabListMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// Markup's children are its tabs.
	public override Node ChildHost => mStrip;

	/// Lists every tab in a menu below the list button; picking one selects it.
	public void OpenTabList()
	{
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		for (int32 i = 0; i < TabCount; ++i)
		{
			let at = i;
			mMenu.AddCheckItem(GetTab(i).Text, GetTab(i) == mSelected, new (on) => { SelectByUser(at); });
		}
		mMenu.OpenBelow(this, mList);
	}

	// Its tabs and its menu write in its font.
	protected override void OnTextStyleChange()
	{
		for (int32 i = 0; i < TabCount; ++i)
			ShareTextStyle(GetTab(i), false);
	}

	// The list button shows while the tabs overflow the strip (or always).
	public override void OnLayout()
	{
		LayoutChildren();
		let shown = (mListDisplay == .Always) || (mStrip.ScrollRange.X > 0.5f);
		if (shown == mList.Displayed)
			return;
		mList.Displayed = shown;
		LayoutChildren();
		if (mSelected != null)
			mStrip.ScrollIntoView(mSelected);
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		let step = CycleStep(e);
		if (step == 0)
			return;
		CycleSelection(step);
		e.Handled = true;
	}

	// A torn-out tab of its group: taken, the mark where it would land.
	protected override void OnDragQuery(DropQuery query)
	{
		OfferTab(query, InsertionIndex(query.Local));
	}

	protected override void OnDragLeave(DragEvent e)
	{
		SetDropIndex(-1);
	}

	protected override void OnDrop(DragEvent e)
	{
		DropTab(e.Payload);
	}

	// The mark between the tabs where a dropped tab would land.
	protected override void OnDrawAbove(DrawContext ctx)
	{
		if (mDropIndex < 0)
			return;
		let part = GetPartStyle("drop-indicator");
		let color = part.HasBackground ? part.Box.BackgroundColor : Color(0.31f, 0.61f, 1.0f, 1.0f);
		// At the inline start of the tab it would go before, else past the last one's end.
		let rtl = IsRightToLeft;
		float x = 0.0f;
		let at = GetTab(mDropIndex);
		let last = GetTab(TabCount - 1);
		if (at != null)
		{
			let r = at.ScreenBounds;
			x = ConvertToNodeSpace(.(rtl ? r.X + r.Width : r.X, 0.0f)).X;
		}
		else if (last != null)
		{
			let r = last.ScreenBounds;
			x = ConvertToNodeSpace(.(rtl ? r.X : r.X + r.Width, 0.0f)).X;
		}
		ctx.VG.FillRect(.(x - 1.0f, 0.0f, 2.0f, Size.Y), color);
	}

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("drop-indicator");
	}

	/// The dragged tab a payload carries (a `gui/tab` drag), while it lives; else null.
	internal static Tab DraggedTab(DragPayload payload)
	{
		if ((payload.Type != "gui/tab") || (payload.Value.VariantType != typeof(Node.ElementRef)))
			return null;
		let weak = payload.Value.Get<Node.ElementRef>();
		return (weak.Table != null) ? (weak.Table.Resolve(weak.Slot, weak.Generation) as Tab) : null;
	}

	// Ctrl+Tab and Ctrl+Page Down: on; Ctrl+Shift+Tab and Ctrl+Page Up: back (0: neither).
	internal static int32 CycleStep(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if ((key == .Tab) && (e.Modifiers == KeyModCtrl))
			return 1;
		if ((key == .Tab) && (e.Modifiers == (KeyModCtrl | KeyModShift)))
			return -1;
		if ((e.Modifiers == KeyModCtrl) && ((key == .PageDown) || (key == .PageUp)))
			return (key == .PageDown) ? 1 : -1;
		return 0;
	}

	// The close-all part shows while it is asked for and a tab is closable.
	internal void UpdateCloseAll()
	{
		bool any = false;
		for (int32 i = 0; (i < TabCount) && !any; ++i)
			any = GetTab(i).Closable;
		mCloseAllPart.Displayed = mCloseAll && any;
	}

	// A tab of its own torn out, or back (Tab's, which tells it).
	internal void TellTorn(Tab tab, bool torn)
	{
		if (mOnTabTorn != null)
			mOnTabTorn(tab, torn);
	}

	internal void TellDragEnded(Tab tab, DragResult result)
	{
		if (mOnTabDragEnded != null)
			mOnTabDragEnded(tab, result);
	}

	// The strip's tabs changed: new ones take its font, a removed selection moves on, and each
	// that left is reported (a removed tab is still alive here: the strip holds it across this
	// call).
	internal void TabsChanged()
	{
		let gone = scope List<Tab>();
		for (let known in mKnown)
		{
			if (IndexOf(known) < 0)
				gone.Add(known);
		}
		mKnown.Clear();
		for (int32 i = 0; i < TabCount; ++i)
		{
			let tab = GetTab(i);
			mKnown.Add(tab);
			ShareTextStyle(tab, false);
			tab.UpdateClose();
		}
		UpdateCloseAll();
		if ((mSelected != null) && (IndexOf(mSelected) < 0))
		{
			mSelected.SetSelectedState(false);
			mSelected = null;
			let next = Math.Min(mSelectedAt, TabCount - 1);
			if (next >= 0)
				Select(GetTab(next), false);
			else
			{
				mSelectedChanged.Notify();
				if (mOnSelectionChanged != null)
					mOnSelectionChanged(-1);
			}
		}
		else if ((mPendingSelect >= 0) && (mPendingSelect < TabCount))
		{
			let pending = mPendingSelect;
			mPendingSelect = -1;
			Select(GetTab(pending), false);
		}
		else if ((mSelected == null) && (TabCount > 0) && (mPendingSelect < 0))
			Select(GetTab(0), false); // none asked for yet (one asked for waits: its page is not shown, nor built, on the way)
		else if (mSelected != null)
			mSelectedAt = IndexOf(mSelected); // a tab added before it moved it
		if (mOnRemoved != null)
		{
			for (let tab in gone)
				mOnRemoved(tab);
		}
	}

	// A drag of `tab` with the pointer at `world`: past a neighbour's midpoint, they change places.
	internal void DragTab(Tab tab, Float2 world)
	{
		let x = tab.ConvertToNodeSpace(world).X; // in the tab's space, which moves with it
		let at = IndexOf(tab);
		let next = GetTab(at + 1);
		let previous = GetTab(at - 1);
		float Midpoint(Tab other) => other.Position.X - tab.Position.X + other.Size.X * 0.5f;
		// (Until the strip lays out again the two keep their old places, and the test after a
		// move is against the new neighbour's, so a tab never changes back on the same move.)
		// The next tab is toward the inline end: the left in right to left.
		let way = IsRightToLeft ? -1.0f : 1.0f;
		if ((next != null) && (way * x > way * Midpoint(next)))
			MoveTab(at, at + 1);
		else if ((previous != null) && (way * x < way * Midpoint(previous)))
			MoveTab(at, at - 1);
	}

	private void Select(Tab tab, bool byUser)
	{
		if (tab == mSelected)
			return;
		if (mSelected != null)
			mSelected.SetSelectedState(false);
		mSelected = tab;
		if (tab != null)
		{
			mSelectedAt = IndexOf(tab);
			tab.SetSelectedState(true);
			mStrip.ScrollIntoView(tab);
		}
		mSelectedChanged.Notify();
		let index = IndexOf(tab);
		if (mOnSelectionChanged != null)
			mOnSelectionChanged(index);
		if (!byUser)
			return;
		if (mOnSelected != null)
			mOnSelected(index);
		SendEvent(scope Event(.Changed, this));
	}

	private void SetDropIndex(int32 index)
	{
		if (index == mDropIndex)
			return;
		mDropIndex = index;
		Invalidate();
	}

	// Where a tab dropped at `local` (the bar's space) would go: before the first tab whose
	// middle lies past it toward the inline end.
	private int32 InsertionIndex(Float2 local)
	{
		let world = ConvertToWorldSpace(local);
		let way = IsRightToLeft ? -1.0f : 1.0f;
		for (int32 i = 0; i < TabCount; ++i)
		{
			if (!GetTab(i).Displayed)
				continue; // hidden (torn out): counted, but no place of its own
			let r = GetTab(i).ScreenBounds;
			if (way * world.X < way * (r.X + r.Width * 0.5f))
				return i;
		}
		return TabCount;
	}
}

/// What TabBar.bf keeps out of the public surface.
internal static class TabBarDetail
{
	/// By TabCloseDisplay.
	public static String[4] sCloseDisplayNames = .("never", "selected", "hover", "always");
}
