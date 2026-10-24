using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The breadcrumb bar: where a view is, as segments from its root to the current one, each carrying
// its target (an id the application gets back), so the application keeps no table beside it (doriax
// pairs a name with its path). A click navigates on release; the last segment is the current one,
// shown so and inert. When the segments do not fit, the current one and as many before it as fit
// stay, filled from the end, and the rest fold into a "…" button whose menu lists them (doriax). One
// tab stop: Left and Right move along it (mirrored right to left, where its segments run right to
// left and its chevrons turn), Return navigates. Given a children callback, each chevron opens a
// menu of what lies in the segment before it (Down on a segment too), a child chosen navigated to
// (Explorer's). The segments but the current take drops of the application's types (doriax).
// Opt-in, a click on the bar's empty end makes it a field holding the current item's id (the path),
// Return giving the text to the application, Escape or focus leaving putting the segments back.
// History (back, forward, up) is the view's that holds it, as in every bar surveyed.

/// One segment of a breadcrumb bar: what it shows and what navigating to it means. A class: it owns
/// its text; Set copies another into it.
class BreadcrumbItem
{
	/// What the application gets back (a folder's path, a node's id).
	public String Id = new .() ~ delete _;
	/// What it shows.
	public String Text = new .() ~ delete _;
	/// Shown on hover (the full path); empty: none.
	public String Tooltip = new .() ~ delete _;
	/// An icon's path, loaded as a button's; empty: none.
	public String Icon = new .() ~ delete _;

	public this() { }

	public this(StringView id, StringView text)
	{
		Id.Set(id);
		Text.Set(text);
	}

	public this(StringView id, StringView text, StringView tooltip)
	{
		Id.Set(id);
		Text.Set(text);
		Tooltip.Set(tooltip);
	}

	public this(StringView id, StringView text, StringView tooltip, StringView icon)
	{
		Id.Set(id);
		Text.Set(text);
		Tooltip.Set(tooltip);
		Icon.Set(icon);
	}

	public void Set(BreadcrumbItem other)
	{
		Id.Set(other.Id);
		Text.Set(other.Text);
		Tooltip.Set(other.Tooltip);
		Icon.Set(other.Icon);
	}
}

/// A segment: a button with the item's text and icon (`crumb`; the current one `.current`).
[GuiReflect]
class BreadcrumbSegment : Button
{
	// The bar that holds it.
	private BreadcrumbBar mBar = null;
	private int mIndex = 0;

	public this()
	{
		Tag = "crumb";
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Shrink = 0.0f;
					s.MinWidth = LayoutLength.Px(0.0f);
				});
		}
	}

	/// Whether it is the current segment, to a screen reader (its description).
	[GuiProperty("", .None, "description")]
	public StringView AccessDescription => HasClass("current") ? "current" : "";

	// A drop of the bar's types, on a segment but the current.
	protected override void OnDragQuery(DropQuery query)
	{
		if ((mBar != null) && mBar.[Friend]TakesDrop(mIndex, query.Payload.Type))
			query.Accept();
	}

	protected override void OnDrop(DragEvent e)
	{
		if (mBar != null)
			mBar.[Friend]Dropped(mIndex, e);
	}
}

/// The mark between two segments (`crumbseparator`): a chevron toward the current one; given a
/// children callback, a button opening the menu of what lies in the segment before it (`.menu`).
[GuiReflect]
class BreadcrumbSeparator : Button
{
	private int mOwner = 0;

	public this()
	{
		Tag = "crumbseparator";
		TabFocusable = false; // its menu opens from the keys by Down on the segment
		HitTestVisible = false;
		MirrorOnRtl = true; // drawn pointing right; right to left, it points left
	}

	public override Float2 MeasureContent(Float2 available) => .(8.0f, 10.0f);

	/// The segment whose children its menu lists.
	public int Owner => mOwner;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let c = ContentBounds;
		let cx = c.X + c.Width * 0.5f;
		let cy = c.Y + c.Height * 0.5f;
		let chevron = scope PathBuilder();
		chevron.MoveTo(cx - 1.5f, cy - 3.5f);
		chevron.LineTo(cx + 2.0f, cy);
		chevron.LineTo(cx - 1.5f, cy + 3.5f);
		let path = chevron.ToPath();
		ctx.VG.StrokePath(path, TextColor, StrokeStyle(1.25f, .Round, .Round));
		delete path;
	}
}

[GuiReflect(true)]
class BreadcrumbBar : UIWidget
{
	private List<BreadcrumbItem> mItems = new .() ~ DeleteContainerAndItems!(_);
	private List<BreadcrumbSegment> mSegments = new .() ~ { for (let s in _) s.ReleaseRef(); delete _; };
	// [i - 1]: before segment i.
	private List<BreadcrumbSeparator> mSeparators = new .() ~ { for (let s in _) s.ReleaseRef(); delete _; };
	private Button mOverflow ~ _.ReleaseRef();
	private BreadcrumbSeparator mOverflowSeparator ~ _.ReleaseRef();
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	// The path, while it is edited.
	private TextField mField ~ _?.ReleaseRef();
	// The item that takes Tab (one of its children, not held).
	private Node mRoving = null;
	private int mFolded = 0;
	private bool mPathEditable = false;
	private bool mEditingPath = false;
	private String mDropTypes = new .() ~ delete _;
	// What the open chevron's menu lists.
	private List<BreadcrumbItem> mChildren = new .() ~ DeleteContainerAndItems!(_);
	private delegate void(BreadcrumbItem item) mOnNavigate ~ delete _;
	private delegate void(BreadcrumbItem of, List<BreadcrumbItem> children) mOnChildren ~ delete _;
	private delegate void(BreadcrumbItem item, DragPayload payload, DropEffect effect) mOnDrop ~ delete _;
	private delegate void(StringView text) mOnPathSubmitted ~ delete _;

	public this()
	{
		Tag = "breadcrumbbar";
		AccessRoleName = "group"; // the core has no navigation role yet
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row;
					s.AlignItems = .Center;
					s.ColumnGap = 2.0f;
					s.MinWidth = LayoutLength.Px(0.0f); // never held at its segments' length: they fold
				});
			Padding = Thickness(4.0f, 2.0f, 4.0f, 2.0f);
		}
		mOverflow = new Button();
		mOverflow.Tag = "crumboverflow";
		mOverflow.Visible = false;
		mOverflow.SetOnClick(new () => { OpenOverflow(); });
		AddChild(mOverflow);
		mOverflowSeparator = MakeSeparator();
		mOverflowSeparator.Visible = false;
	}

	/// Its segments, from the root to the current one (the last); copies kept.
	public void SetItems(Span<BreadcrumbItem> items)
	{
		for (let segment in mSegments)
		{
			RemoveChild(segment);
			segment.ReleaseRef();
		}
		for (let separator in mSeparators)
		{
			RemoveChild(separator);
			separator.ReleaseRef();
		}
		mSegments.Clear();
		mSeparators.Clear();
		ClearAndDeleteItems!(mItems);
		mRoving = null;
		if (mEditingPath)
			EndPathEdit(false);
		for (int i = 0; i < items.Length; ++i)
		{
			let item = items[i];
			let copy = new BreadcrumbItem();
			copy.Set(item);
			mItems.Add(copy);
			if (i > 0)
			{
				let separator = MakeSeparator();
				separator.[Friend]mOwner = i - 1;
				mSeparators.Add(separator);
			}
			let segment = new BreadcrumbSegment();
			segment.[Friend]mBar = this;
			segment.[Friend]mIndex = i;
			segment.Text = item.Text;
			if (let text = segment.TextPart)
			{
				text.TextOverflow = .Ellipsis; // the current one, when even it does not fit
				text.EditLayoutStyle(scope (s) => { s.MinWidth = LayoutLength.Px(0.0f); });
			}
			if (!item.Icon.IsEmpty)
				segment.Icon = item.Icon;
			segment.Tooltip = item.Tooltip;
			if (i + 1 == items.Length)
				segment.AddClass("current");
			let index = i;
			segment.SetOnClick(new () => { Navigate(index); });
			AddChild(segment);
			mSegments.Add(segment);
		}
		RequestLayout();
	}

	/// Its segments from a `/` path: each folder's id the path up to it. A leading `/` is a segment
	/// of its own (the root), as is a drive (`C:`); empty parts are skipped.
	public void SetPath(StringView path)
	{
		let items = scope List<BreadcrumbItem>();
		defer { ClearAndDeleteItems!(items); }
		int at = 0;
		if ((path.Length != 0) && (path[0] == '/'))
		{
			items.Add(new BreadcrumbItem("/", "/", "/"));
			at = 1;
		}
		while (at < path.Length)
		{
			var end = at;
			while ((end < path.Length) && (path[end] != '/'))
				++end;
			if (end > at)
			{
				let upTo = path.Substring(0, end);
				items.Add(new BreadcrumbItem(upTo, path.Substring(at, end - at), upTo));
			}
			at = end + 1;
		}
		SetItems(items);
	}

	public int ItemCount => mItems.Count;
	public BreadcrumbItem ItemAt(int index) => mItems[index];

	/// Told the item navigated to (a segment clicked, chosen from the overflow menu, or Return).
	/// OWNERSHIP of `callback` transfers.
	public void SetOnNavigate(delegate void(BreadcrumbItem item) callback)
	{
		delete mOnNavigate;
		mOnNavigate = callback;
	}

	/// Navigates to segment `index` (as a click does); false for the current one or none.
	public bool Navigate(int index)
	{
		if ((index < 0) || (index + 1 >= mItems.Count))
			return false; // the current segment is where it is
		if (mOnNavigate != null)
		{
			let item = scope BreadcrumbItem(); // the callback may set new items
			item.Set(mItems[index]);
			mOnNavigate(item);
		}
		return true;
	}

	/// Gives the children of an item (what its chevron's menu lists, appended as new items the bar
	/// deletes): with it, the chevrons are buttons; without (the default), marks. OWNERSHIP of
	/// `callback` transfers.
	public void SetOnChildren(delegate void(BreadcrumbItem of, List<BreadcrumbItem> children) callback)
	{
		delete mOnChildren;
		mOnChildren = callback;
		let menus = mOnChildren != null;
		void Show(BreadcrumbSeparator separator)
		{
			separator.HitTestVisible = menus;
			if (menus)
				separator.AddClass("menu");
			else
				separator.RemoveClass("menu");
		}
		Show(mOverflowSeparator);
		for (let separator in mSeparators)
			Show(separator);
	}

	/// Opens the menu of segment `index`'s children below `anchor` (its chevron, else itself);
	/// choosing one navigates to it. False with no callback or no children.
	public bool OpenChildren(int index, Node anchor)
	{
		if ((mOnChildren == null) || (index < 0) || (index >= mItems.Count))
			return false;
		ClearAndDeleteItems!(mChildren);
		mOnChildren(mItems[index], mChildren);
		if (mChildren.IsEmpty)
			return false;
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		for (int i = 0; i < mChildren.Count; ++i)
		{
			let child = i;
			mMenu.AddItem(mChildren[i].Text, new () =>
				{
					if ((mOnNavigate != null) && (child < mChildren.Count))
					{
						let picked = scope BreadcrumbItem();
						picked.Set(mChildren[child]);
						mOnNavigate(picked);
					}
				});
		}
		mMenu.OpenBelow(this, anchor);
		return true;
	}

	/// The menu open now: the overflow's or a chevron's.
	public Sedulous.GUI.Menu GetOpenMenu() => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// Segments but the current take drops whose type is among `types` (space-separated).
	public void SetSegmentDropTypes(StringView types)
	{
		mDropTypes.Set(types);
	}

	/// Told a drop on a segment: its item, what was dropped and with what effect. OWNERSHIP of
	/// `callback` transfers.
	public void SetOnSegmentDrop(delegate void(BreadcrumbItem item, DragPayload payload, DropEffect effect) callback)
	{
		delete mOnDrop;
		mOnDrop = callback;
	}

	/// Whether a click on its empty end edits the path as text (off by default).
	public bool IsPathEditable
	{
		get => mPathEditable;
		set => mPathEditable = value;
	}

	/// Told the text typed when Return ends the edit (the application navigates, or not).
	/// OWNERSHIP of `callback` transfers.
	public void SetOnPathSubmitted(delegate void(StringView text) callback)
	{
		delete mOnPathSubmitted;
		mOnPathSubmitted = callback;
	}

	/// Makes it a field holding the current item's id, all selected.
	public void BeginPathEdit()
	{
		if (mEditingPath)
			return;
		if (mField == null)
		{
			mField = new TextField();
			mField.AddClass("path");
			mField.SetOnSubmit(new (text) => { EndPathEdit(true); });
			mField.AddEventListener(.FocusLost, new (e) =>
				{
					// Elsewhere, the segments come back; not to the field's own context menu.
					let menu = mField.ContextMenu;
					if ((menu != null) && menu.IsOpen)
						return;
					EndPathEdit(false);
				});
			AddChild(mField);
		}
		mEditingPath = true;
		mField.Text = mItems.IsEmpty ? StringView() : (StringView)mItems.Back.Id;
		mField.Displayed = true;
		mField.SelectAll();
		mField.RequestFocus();
		RequestLayout();
	}

	/// Ends the edit: with `submit`, the text goes to the application.
	public void EndPathEdit(bool submit)
	{
		if (!mEditingPath)
			return;
		mEditingPath = false;
		let typed = scope String(mField.Text);
		let hadFocus = mField.IsFocused;
		mField.Displayed = false;
		RequestLayout();
		if (hadFocus && (mRoving != null))
		{
			mRoving.Visible = true; // hidden while the field showed; the layout places it
			mRoving.RequestFocus();
		}
		if (submit && (mOnPathSubmitted != null))
			mOnPathSubmitted(typed);
	}

	public bool IsEditingPath => mEditingPath;
	public TextField PathField => mField;

	/// The segments, from the root.
	public BreadcrumbSegment SegmentAt(int index) => mSegments[index];
	/// The separator before segment `index` (from 1).
	public BreadcrumbSeparator SeparatorBefore(int index) => mSeparators[index - 1];
	/// How many segments, from the root, folded into the overflow menu (0: all show).
	public int FoldedCount => mFolded;
	public Button OverflowButton => mOverflow;

	/// Lists the folded segments below the "…" button; choosing one navigates to it.
	public void OpenOverflow()
	{
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		for (int i = 0; i < mFolded; ++i)
		{
			let index = i;
			mMenu.AddItem(mItems[i].Text, new () => { Navigate(index); });
		}
		mMenu.OpenBelow(this, mOverflow);
	}

	public override Float2 MeasureContent(Float2 available)
	{
		// Every segment and separator as it would be with nothing in its way (what it asks while all
		// fit), as tall as the tallest.
		let gap = LayoutStyle.ColumnGap;
		float along = 0.0f;
		float across = 0.0f;
		int count = 0;
		void Add(Node node)
		{
			let size = Natural(node);
			along += size.X;
			across = Math.Max(across, size.Y);
			++count;
		}
		for (int i = 0; i < mSegments.Count; ++i)
		{
			if (i > 0)
				Add(mSeparators[i - 1]);
			Add(mSegments[i]);
		}
		if (count > 1)
			along += gap * (float)(count - 1);
		return .(along, across);
	}

	// Its segments, laid out by itself: from the end, as many as fit; the rest folded.
	public override void OnLayout()
	{
		let content = ContentBounds;
		let gap = LayoutStyle.ColumnGap;
		let count = mSegments.Count;
		void Hide(Node node)
		{
			node.Visible = false;
			node.Arrange(.(content.X, content.Y, 0.0f, 0.0f));
		}
		if (mEditingPath)
		{
			// The field over the whole bar, the segments away.
			Hide(mOverflow);
			Hide(mOverflowSeparator);
			for (let segment in mSegments)
				Hide(segment);
			for (let separator in mSeparators)
				Hide(separator);
			mField.Arrange(content);
			return;
		}
		let segments = scope List<Float2>();
		let separators = scope List<Float2>();
		for (int i = 0; i < count; ++i)
		{
			segments.Add(Natural(mSegments[i]));
			if (i > 0)
				separators.Add(Natural(mSeparators[i - 1]));
		}
		// "…" where the font draws it, else three full stops (a baked atlas may lack it).
		mOverflow.Text = EllipsisFor(mOverflow.Font);
		let overflow = Natural(mOverflow);
		let overflowSeparator = Natural(mOverflowSeparator);
		// What segments `first` to the last take, with the "…" and its separator before them when
		// any fold.
		float Used(int first)
		{
			float total = 0.0f;
			int items = 0;
			for (int i = first; i < count; ++i)
			{
				if (i > first)
				{
					total += separators[i - 1].X;
					++items;
				}
				total += segments[i].X;
				++items;
			}
			if (first > 0)
			{
				total += overflow.X + overflowSeparator.X;
				items += 2;
			}
			return (items > 1) ? total + gap * (float)(items - 1) : total;
		}
		int first = 0;
		while ((count > 0) && (first + 1 < count) && (Used(first) > content.Width + 0.5f))
			++first;
		mFolded = first;

		let reverse = IsRightToLeft;
		float at = 0.0f;
		void Place(Node node, Float2 size, float extent)
		{
			let height = Math.Min(size.Y, content.Height);
			let y = content.Y + (content.Height - height) * 0.5f;
			let x = reverse ? content.X + content.Width - at - extent : content.X + at;
			node.Arrange(.(x, y, Math.Max(0.0f, extent), height));
			at += extent + gap;
		}
		let folding = first > 0;
		mOverflowSeparator.[Friend]mOwner = (first > 0) ? first - 1 : 0;
		mOverflow.Visible = folding;
		mOverflowSeparator.Visible = folding;
		if (folding)
		{
			Place(mOverflow, overflow, overflow.X);
			Place(mOverflowSeparator, overflowSeparator, overflowSeparator.X);
		}
		else
		{
			Hide(mOverflow);
			Hide(mOverflowSeparator);
		}
		for (int i = 0; i < count; ++i)
		{
			if (i > 0)
			{
				let separator = mSeparators[i - 1];
				if (i > first)
				{
					separator.Visible = true;
					Place(separator, separators[i - 1], separators[i - 1].X);
				}
				else
					Hide(separator);
			}
			let segment = mSegments[i];
			if (i < first)
			{
				Hide(segment);
				continue;
			}
			segment.Visible = true;
			// The current one, alone and still too long, takes what is left (its text cut short).
			let extent = (i + 1 == count) ? Math.Min(segments[i].X, content.Width - at) : segments[i].X;
			Place(segment, segments[i], extent);
		}
		KeepTabStop();
	}

	// The one tab stop goes where focus went among its items.
	public override void OnDescendantFocused(Node focused)
	{
		base.OnDescendantFocused(focused);
		let stops = scope List<Node>();
		Stops(stops);
		for (let item in stops)
		{
			if (item == focused)
			{
				mRoving = item;
				KeepTabStop();
				return;
			}
		}
	}

	// A click on its empty end edits the path, where it may.
	protected override void OnMouseClick(MouseEvent e)
	{
		if ((e.Target != this) || (e.Button != .Left) || !mPathEditable || mEditingPath)
			return;
		e.Handled = true;
		BeginPathEdit();
	}

	// Left and Right (the other way right to left), Home and End move along its items; Down opens a
	// segment's children; Escape leaves the path's edit.
	protected override void OnKeyDown(KeyEvent e)
	{
		let key = (KeyCode)e.KeyCode;
		if (mEditingPath)
		{
			if ((key == .Escape) && (e.Modifiers == 0))
			{
				EndPathEdit(false);
				e.Handled = true;
			}
			return;
		}
		if (e.Modifiers != 0)
			return;
		if (key == .Down)
		{
			for (int i = 0; i < mSegments.Count; ++i)
			{
				if (mSegments[i].IsFocused)
				{
					Node anchor = ((i + 1 < mSegments.Count) && mSeparators[i].Visible) ? (Node)mSeparators[i] : (Node)mSegments[i];
					if (OpenChildren(i, anchor))
						e.Handled = true;
					return;
				}
			}
			return;
		}
		let stops = scope List<Node>();
		Stops(stops);
		if (stops.IsEmpty)
			return;
		int at = stops.Count;
		for (int i = 0; i < stops.Count; ++i)
		{
			if (stops[i].IsFocused)
				at = i;
		}
		if (at == stops.Count)
			return;
		int next = at;
		let step = InlineStep(key);
		if (step != 0)
		{
			if ((step < 0) && (at > 0))
				next = at - 1;
			else if ((step > 0) && (at + 1 < stops.Count))
				next = at + 1;
		}
		else if (key == .Home)
			next = 0;
		else if (key == .End)
			next = stops.Count - 1;
		else
			return;
		e.Handled = true;
		if (next != at)
			stops[next].RequestFocus();
	}

	private BreadcrumbSeparator MakeSeparator()
	{
		let separator = new BreadcrumbSeparator();
		separator.SetOnClick(new () => { OpenChildren(separator.[Friend]mOwner, separator); });
		if (mOnChildren != null)
		{
			separator.HitTestVisible = true;
			separator.AddClass("menu");
		}
		AddChild(separator);
		return separator;
	}

	// Whether segment `index` takes a drop of `type`: the bar's types, not the current one.
	private bool TakesDrop(int index, StringView type)
	{
		if ((index + 1 >= mItems.Count) || mDropTypes.IsEmpty)
			return false;
		var rest = ParseUtil.Trim(mDropTypes);
		while (rest.Length != 0)
		{
			int end = 0;
			while ((end < rest.Length) && (rest[end] != ' '))
				++end;
			if (rest.Substring(0, end) == type)
				return true;
			rest = ParseUtil.Trim(rest.Substring(end, rest.Length - end));
		}
		return false;
	}

	private void Dropped(int index, DragEvent e)
	{
		if ((mOnDrop != null) && (index >= 0) && (index < mItems.Count))
		{
			let item = scope BreadcrumbItem();
			item.Set(mItems[index]);
			mOnDrop(item, e.Payload, e.Effect);
		}
	}

	// What the keys move along, in order: the "…" while segments fold, then the shown segments.
	private void Stops(List<Node> outStops)
	{
		if (mFolded > 0)
			outStops.Add(mOverflow);
		for (int i = mFolded; i < mSegments.Count; ++i)
			outStops.Add(mSegments[i]);
	}

	// One of its items takes Tab: the one focus was last on, else the current segment.
	private void KeepTabStop()
	{
		let stops = scope List<Node>();
		Stops(stops);
		bool held = false;
		for (let item in stops)
			held = held || (item == mRoving);
		if (!held)
			mRoving = stops.IsEmpty ? null : stops.Back;
		mOverflow.TabFocusable = mOverflow == mRoving;
		for (let segment in mSegments)
			segment.TabFocusable = segment == mRoving;
	}

	// Its border box with its margins, as it would be with nothing in its way, a whole number of
	// pixels across: placed on the pixel grid, a fraction short would cut its text with an ellipsis.
	private static Float2 Natural(Node node)
	{
		var constraints = LayoutConstraints();
		constraints.Max = .(cUnbounded, cUnbounded);
		let size = node.Measure(constraints);
		let m = node.LayoutStyle.Margin;
		return .(Ceil(size.X + m.TotalHorizontal), size.Y + m.TotalVertical);
	}
}
