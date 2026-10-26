using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The tool bar. Its buttons name commands (the core's command model, as menus and shortcuts do): a
// command's label, icon, checked state and availability reach them, so one command greys its
// button, its menu item and its keys at once (ezEngine, Lumix and Zero feed all three from one
// registry). A tool button shows its icon (its text too when asked, or when it has no icon); its
// tooltip is its label, the keys that run it here, and, while its command is disabled, why.
//
// The bar lays its items out in a row (or a column) itself, so it knows what each wants whether or
// not it shows: what does not fit goes into an overflow menu at the end, the items of lowest
// overflow priority first, then from the end (zed shrinks its bars and clips their start, which the
// survey counts against it). An item that cannot be a menu row (a field, a combo) never goes; a
// separator shows only between items that show. A spacer (any item that grows) takes what is left.
// The bar is one focus group: Tab enters it once, the arrows move along it. It shows and hides its
// items itself (visibility); an application takes one out with Displayed = false.

/// A tool button: an icon (and its text where asked) for a command or a click.
[GuiReflect(true)]
class ToolButton : Button
{
	private String mShortcut = new .() ~ delete _;
	private String mReason = new .() ~ delete _;
	// What TooltipText last built.
	private String mTip = new .() ~ delete _;
	private int32 mPriority = 0;
	private bool mShowsText = false;
	private bool mIconFromCommand = false;

	public this()
	{
		Tag = "toolbutton";
	}

	/// Whether its text shows beside its icon (`shows-text`); without an icon it always does.
	[GuiProperty("shows-text")]
	public bool ShowsText
	{
		get => mShowsText;
		set
		{
			mShowsText = value;
			UpdateParts();
		}
	}

	/// Which items leave a full bar first (`overflow-priority`): the lowest, then the last.
	[GuiProperty("overflow-priority")]
	public int32 OverflowPriority
	{
		get => mPriority;
		set
		{
			mPriority = value;
			if (let parent = Parent)
				parent.RequestLayout();
		}
	}

	/// What it is called: its text, else its command's label (its tooltip's first line, and its row
	/// in the overflow menu).
	public StringView Label => Text;
	/// The keys that run its command where it is ("Ctrl+S"); empty with none.
	public StringView Shortcut => mShortcut;
	/// Why its command is disabled, while it is; empty otherwise.
	public StringView DisabledReason => mReason;

	/// Its own tooltip where it has one; else its label, its keys and why it is disabled.
	public override StringView TooltipText
	{
		get
		{
			let own = base.TooltipText;
			if (own.Length != 0)
				return own;
			mTip.Clear();
			BuildTip(mTip); // its label as it is now
			return mTip;
		}
	}

	public override void OnBoundCommandText(StringView label, StringView icon, StringView shortcut)
	{
		base.OnBoundCommandText(label, icon, shortcut);
		mShortcut.Set(shortcut);
		// Its command's icon where it has none of its own.
		if ((icon.Length != 0) && ((IconPart == null) || mIconFromCommand))
		{
			Icon = scope String(icon);
			mIconFromCommand = true;
			UpdateParts();
		}
	}

	public override void OnBoundCommandState(BoundCommandState state)
	{
		base.OnBoundCommandState(state);
		mReason.Set(state.Reason);
	}

	// A part came or went (its icon, its text): whether its text shows follows.
	public override void OnChildrenChanged()
	{
		base.OnChildrenChanged();
		UpdateParts();
	}

	private void UpdateParts()
	{
		if (let text = TextPart)
			text.Displayed = mShowsText || (IconPart == null);
	}

	private void BuildTip(String tip)
	{
		tip.Append(Label);
		if (mShortcut.Length != 0)
		{
			tip.Append(" (");
			tip.Append(mShortcut);
			tip.Append(")");
		}
		if (mReason.Length != 0)
		{
			tip.Append("\n");
			tip.Append(mReason);
		}
	}
}

/// The arrow a menu button draws at its end: a part (`arrow`), hit as its button.
[GuiReflect]
class ToolMenuArrow : UIWidget
{
	private bool mDivided = false;

	public this()
	{
		Tag = "arrow";
		HitTestVisible = false;
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) => { s.Shrink = 0.0f; });
		}
	}

	/// Whether a line sets it apart (a split button's: the arrow is a button of its own).
	public bool Divided
	{
		get => mDivided;
		set
		{
			mDivided = value;
			Invalidate();
		}
	}

	public override Float2 MeasureContent(Float2 available) => .(mDivided ? 14.0f : 10.0f, 10.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let color = TextColor;
		let cx = localBounds.X + localBounds.Width * (mDivided ? 0.6f : 0.5f);
		let cy = localBounds.Y + localBounds.Height * 0.5f;
		let arrow = scope PathBuilder();
		arrow.MoveTo(cx - 3.5f, cy - 1.5f);
		arrow.LineTo(cx + 3.5f, cy - 1.5f);
		arrow.LineTo(cx, cy + 2.5f);
		arrow.Close();
		let path = arrow.ToPath();
		ctx.VG.FillPath(path, color);
		delete path;
		if (mDivided)
		{
			var line = color;
			line.A *= 0.4f;
			let x = IsRightToLeft ? localBounds.X + localBounds.Width - 1.0f : localBounds.X;
			ctx.VG.FillRect(Rect(x, localBounds.Y + 2.0f, 1.0f, Math.Max(0.0f, localBounds.Height - 4.0f)).ToRectangle(), line);
		}
	}
}

/// A tool button with a menu: a drop-down (a click opens its menu) or, split, a button whose arrow
/// opens its menu while the rest runs its command. Markup's children are its menu's.
[GuiReflect(true)]
class ToolMenuButton : ToolButton
{
	private ToolMenuArrow mArrow ~ _.ReleaseRef();
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	private bool mSplit = false;

	public this()
	{
		Tag = "toolmenubutton";
		mArrow = new ToolMenuArrow();
		AddChild(mArrow);
	}

	/// Split (`split`): the arrow opens the menu and the rest runs the button's command or click.
	[GuiProperty("split")]
	public bool IsSplit
	{
		get => mSplit;
		set
		{
			mSplit = value;
			mArrow.Divided = value;
		}
	}

	/// Its menu (made when first asked for).
	public Sedulous.GUI.Menu Menu
	{
		get
		{
			if (mMenu == null)
			{
				mMenu = new Sedulous.GUI.Menu();
				mMenu.SetAutoWidth(true);
			}
			return mMenu;
		}
	}

	/// Its menu while it is open, else null.
	public Sedulous.GUI.Menu GetOpenMenu() => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;
	public Node ArrowPart => mArrow;

	/// Opens its menu below `anchor` (itself, or the overflow button it went into).
	public void OpenMenu(Node anchor)
	{
		let menu = this.Menu;
		ShareTextStyle(menu, false);
		menu.OpenBelow(this, anchor);
	}

	public void OpenMenu() => OpenMenu(this);

	public override Node ChildHost => this.Menu.ChildHost;

	protected override void OnMouseClick(MouseEvent e)
	{
		if (!mSplit || OnArrow(e.Position))
		{
			e.Handled = true;
			OpenMenu();
			return;
		}
		base.OnMouseClick(e);
	}

	// Return, Space, South: a drop-down opens; a split button runs, and Down opens it.
	protected override bool OnActivate()
	{
		if (!mSplit)
		{
			OpenMenu();
			return true;
		}
		return base.OnActivate();
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if ((e.Modifiers == 0) && ((KeyCode)e.KeyCode == .Down))
		{
			OpenMenu();
			e.Handled = true;
			return;
		}
		base.OnKeyDown(e);
	}

	private bool OnArrow(Float2 world)
	{
		let p = mArrow.ConvertToNodeSpace(world);
		let size = mArrow.Size;
		// The arrow's whole end of the button, padding and all.
		let slack = 4.0f;
		return (p.X >= -slack) && (p.X <= size.X + slack);
	}
}

/// The button at a full bar's end listing what did not fit (`overflow`).
[GuiReflect]
class ToolBarOverflow : Button
{
	private bool mVertical = false;

	public this()
	{
		Tag = "overflow";
		TabFocusable = true;
	}

	public override Float2 MeasureContent(Float2 available) => .(12.0f, 12.0f);

	// Two chevrons toward the bar's end (down in a column).
	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let c = ContentBounds;
		let color = TextColor;
		let cx = c.X + c.Width * 0.5f;
		let cy = c.Y + c.Height * 0.5f;
		let column = mVertical;
		let dir = column ? 1.0f : (IsRightToLeft ? -1.0f : 1.0f);
		let chevrons = scope PathBuilder();
		for (int32 i = 0; i < 2; ++i)
		{
			let o = ((float)i * 4.0f - 2.0f) * dir;
			if (column)
			{
				chevrons.MoveTo(cx - 3.5f, cy + o - 1.5f);
				chevrons.LineTo(cx, cy + o + 1.5f);
				chevrons.LineTo(cx + 3.5f, cy + o - 1.5f);
			}
			else
			{
				chevrons.MoveTo(cx + o - 1.5f * dir, cy - 3.5f);
				chevrons.LineTo(cx + o + 1.5f * dir, cy);
				chevrons.LineTo(cx + o - 1.5f * dir, cy + 3.5f);
			}
		}
		let path = chevrons.ToPath();
		ctx.VG.StrokePath(path, color, StrokeStyle(1.25f, .Round, .Round));
		delete path;
	}
}

/// A bar of tool buttons, menu buttons, separators, spacers and any other widget.
[GuiReflect(true)]
class ToolBar : UIWidget
{
	private struct Item
	{
		public Node Node;
		public Float2 Size;
		public bool Shown;

		public this(Node node, Float2 size, bool shown)
		{
			Node = node;
			Size = size;
			Shown = shown;
		}
	}

	private ToolBarOverflow mOverflow ~ _.ReleaseRef();
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	// Not owned: the bar's children.
	private List<Node> mHidden = new .() ~ delete _;
	private bool mVertical = false;

	public this()
	{
		Tag = "toolbar";
		AccessRoleName = "group"; // the core has no tool bar role yet
		FocusGroup = true;
		using (StyleWriteScope(this))
		{
			EditLayoutStyle(scope (s) =>
				{
					s.Direction = .Row; // its separators stand up
					s.ColumnGap = 2.0f;
					s.RowGap = 2.0f;
					s.AlignItems = .Center;
					// Never held at its items' length: what does not fit overflows (across, its
					// content's minimum holds).
					s.MinWidth = LayoutLength.Px(0.0f);
				});
			Padding = Thickness(4.0f, 2.0f, 4.0f, 2.0f);
		}
		mOverflow = new ToolBarOverflow();
		mOverflow.Visible = false;
		mOverflow.SetOnClick(new () => { OpenOverflow(); });
		AddChild(mOverflow);
	}

	/// Its items run down (`orientation: vertical`) rather than along.
	public bool IsVertical
	{
		get => mVertical;
		set
		{
			mVertical = value;
			mOverflow.[Friend]mVertical = value;
			KeepDirection();
			RequestLayout();
		}
	}

	[GuiProperty("orientation")]
	public StringView OrientationName
	{
		get => IsVertical ? "vertical" : "horizontal";
		set => IsVertical = ParseUtil.Trim(value) == "vertical";
	}

	/// The items that did not fit, in bar order (what the overflow menu lists).
	public Span<Node> Overflowed => mHidden;
	public Node OverflowButton => mOverflow;
	/// The overflow menu, while it is open.
	public Sedulous.GUI.Menu OverflowMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// Lists what did not fit in a menu below the overflow button: a command's item for a button
	/// bound to one (its checked state too), a click's for one with a click, a menu button's opening
	/// its menu there; separators between the groups.
	public void OpenOverflow()
	{
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		bool pendingSeparator = false;
		bool any = false;
		for (let node in mHidden)
		{
			if (IsSeparator(node))
			{
				pendingSeparator = any;
				continue;
			}
			if (pendingSeparator)
				mMenu.AddSeparator();
			pendingSeparator = false;
			any = true;
			AddOverflowRow(node);
		}
		mMenu.OpenBelow(this, mOverflow);
	}

	public override Float2 MeasureContent(Float2 available)
	{
		// Along: every item that shows now (what it asks while it fits); across: the tallest.
		let column = IsVertical;
		let gap = column ? LayoutStyle.RowGap : LayoutStyle.ColumnGap;
		float along = 0.0f;
		float across = 0.0f;
		int count = 0;
		for (int i = 0; i < ChildCount; ++i)
		{
			let child = GetChildAt(i);
			if (!IsItem(child))
				continue;
			// Each as it would be with nothing in its way: a bar is never narrower across than its
			// widest item, whatever its container offers (a flex row's minimum asks).
			let size = Natural(child, .(cUnbounded, cUnbounded));
			along += column ? size.Y : size.X;
			across = Math.Max(across, column ? size.X : size.Y);
			++count;
		}
		if (count > 1)
			along += gap * (float)(count - 1);
		return column ? Float2(across, along) : Float2(along, across);
	}

	// Its items, laid out by itself: what fits shows, the rest goes to the overflow menu.
	public override void OnLayout()
	{
		KeepDirection();
		let content = ContentBounds;
		let column = IsVertical;
		let room = column ? content.Height : content.Width;
		let gap = column ? LayoutStyle.RowGap : LayoutStyle.ColumnGap;
		let avail = Float2(column ? content.Width : cUnbounded, column ? cUnbounded : content.Height);

		let items = scope List<Item>();
		for (int i = 0; i < ChildCount; ++i)
		{
			let child = GetChildAt(i);
			if (!IsItem(child))
				continue;
			items.Add(Item(child, Natural(child, avail), true));
		}
		float Along(Float2 s) => column ? s.Y : s.X;
		// What the shown items take, separators only between shown items.
		float Used(bool withOverflow)
		{
			float total = 0.0f;
			int count = 0;
			for (int i = 0; i < items.Count; ++i)
			{
				if (items[i].Shown && (!IsSeparator(items[i].Node) || SeparatorShows(items, i)))
				{
					total += Along(items[i].Size);
					++count;
				}
			}
			if (withOverflow)
			{
				total += Along(Natural(mOverflow, avail));
				++count;
			}
			return (count > 1) ? total + gap * (float)(count - 1) : total;
		}
		// Hide the lowest priority first, the last of a priority first, until what shows fits.
		let hiding = Used(false) > room + 0.5f;
		while (hiding && (Used(true) > room + 0.5f))
		{
			int pick = -1;
			for (int i = 0; i < items.Count; ++i)
			{
				if (!items[i].Shown || !CanOverflow(items[i].Node))
					continue;
				if ((pick < 0) || (Priority(items[i].Node) <= Priority(items[pick].Node)))
					pick = i;
			}
			if (pick < 0)
				break; // what is left cannot go
			items[pick].Shown = false;
		}

		// A separator shows only between shown items; one left out is a break between groups in the
		// overflow menu.
		let shows = scope List<bool>();
		for (int i = 0; i < items.Count; ++i)
			shows.Add(items[i].Shown && (!IsSeparator(items[i].Node) || SeparatorShows(items, i)));
		mHidden.Clear();
		for (int i = 0; i < items.Count; ++i)
		{
			items[i].Shown = shows[i];
			if (!shows[i])
				mHidden.Add(items[i].Node);
		}
		let overflowing = HasHiddenItem();

		// Spacers share what is left.
		float grow = 0.0f;
		for (let item in items)
		{
			if (item.Shown)
				grow += item.Node.LayoutStyle.Grow;
		}
		let left = Math.Max(0.0f, room - Used(overflowing));

		let reverse = !column && IsRightToLeft;
		float at = 0.0f;
		// An item's slot takes its margins (its natural size has them); its box sits inside them.
		// Across, it stretches only when it has no size of its own there (a separator a sheet
		// makes shorter than the bar), and is centred otherwise.
		void Place(Node node, Float2 size, float extent)
		{
			let s = node.LayoutStyle;
			let m = s.Margin;
			let crossBefore = column ? m.Left : m.Top;
			let crossMargins = column ? m.TotalHorizontal : m.TotalVertical;
			let crossRoom = Math.Max(0.0f, (column ? content.Width : content.Height) - crossMargins);
			let stretch = (s.AlignSelf == .Stretch) && (column ? s.Width : s.Height).IsAuto;
			let cross = stretch ? crossRoom : Math.Min(Math.Max(0.0f, (column ? size.X : size.Y) - crossMargins), crossRoom);
			let crossAt = crossBefore + (crossRoom - cross) * 0.5f;
			Rect r;
			if (column)
				r = .(content.X + crossAt, content.Y + at + m.Top, cross, Math.Max(0.0f, extent - m.TotalVertical));
			else
			{
				let slot = reverse ? content.X + content.Width - at - extent : content.X + at;
				r = .(slot + m.Left, content.Y + crossAt, Math.Max(0.0f, extent - m.TotalHorizontal), cross);
			}
			node.Arrange(r);
			at += extent + gap;
		}
		for (let item in items)
		{
			item.Node.Visible = item.Shown;
			if (!item.Shown)
			{
				item.Node.Arrange(.(content.X, content.Y, 0.0f, 0.0f));
				continue;
			}
			var extent = Along(item.Size);
			if ((grow > 0.0f) && (item.Node.LayoutStyle.Grow > 0.0f))
				extent += left * item.Node.LayoutStyle.Grow / grow;
			Place(item.Node, item.Size, extent);
		}
		mOverflow.Visible = overflowing;
		if (overflowing)
		{
			// At the bar's end, whatever is left before it.
			let size = Natural(mOverflow, avail);
			at = room - Along(size);
			Place(mOverflow, size, Along(size));
		}
		else
			mOverflow.Arrange(.(content.X, content.Y, 0.0f, 0.0f));
	}

	private bool SeparatorShows(List<Item> items, int at)
	{
		// Only between two shown items that are not separators, and not after another shown one.
		bool before = false;
		for (int i = at - 1; i >= 0; i--)
		{
			if (!items[i].Shown)
				continue;
			if (IsSeparator(items[i].Node))
				return false; // the one before shows (or is itself left out): one break is enough
			before = true;
			break;
		}
		if (!before)
			return false;
		for (int i = at + 1; i < items.Count; ++i)
		{
			if (items[i].Shown && !IsSeparator(items[i].Node))
				return true;
		}
		return false;
	}

	// One of its items: displayed and in its flow. Not its overflow button, nor a popup it opened
	// (the overflow menu is its child while open, in the top layer), nor what stands out of the
	// flow.
	private bool IsItem(Node node)
	{
		return (node != mOverflow) && node.Displayed && !node.InTopLayer && (node.LayoutStyle.Placement != .Absolute);
	}

	private bool HasHiddenItem()
	{
		for (let node in mHidden)
		{
			if (!IsSeparator(node))
				return true;
		}
		return false;
	}

	private static bool IsSeparator(Node node) => node is Separator;

	// A row of a menu can stand for it: a tool button (a menu button among them) or a separator.
	private static bool CanOverflow(Node node) => (node is ToolButton) || IsSeparator(node);

	private static int32 Priority(Node node)
	{
		let button = node as ToolButton;
		return (button != null) ? button.OverflowPriority : 0;
	}

	// Its border box with its margins, as it would be with nothing in its way.
	private static Float2 Natural(Node node, Float2 available)
	{
		var constraints = LayoutConstraints();
		constraints.Max = available;
		let size = node.Measure(constraints);
		let m = node.LayoutStyle.Margin;
		return .(size.X + m.TotalHorizontal, size.Y + m.TotalVertical);
	}

	private void AddOverflowRow(Node node)
	{
		let button = node as ToolButton;
		if (button == null)
			return;
		if (let menuButton = button as ToolMenuButton)
		{
			if (!menuButton.IsSplit)
			{
				// Its menu opens where it went: below the overflow button.
				menuButton.AddRef();
				let row = mMenu.AddItem(button.Label, new [=this, =menuButton] () => { menuButton.OpenMenu(mOverflow); } ~ menuButton.ReleaseRef());
				row.Enabled = button.IsTreeEnabled;
				return;
			}
		}
		if (button.HasCommand)
		{
			let row = new MenuItem();
			row.Checkable = button.IsToggle;
			row.Command = button.Command; // its label, keys, state: the command's
			let own = button.Text;
			if (own.Length != 0)
				row.Text = own;
			mMenu.AdoptItem(row);
			row.ReleaseRef(); // the menu's reference keeps it
			return;
		}
		button.AddRef();
		let clickRow = mMenu.AddItem(button.Label, new [=button] () => { button.HandleActivate(); } ~ button.ReleaseRef());
		clickRow.Enabled = button.IsTreeEnabled;
	}

	// Its flex direction follows its orientation, pinned as code's: its separators read it to stand
	// up or lie across. Its orientation is the truth, since a restyle (its `orientation` set from
	// markup under the sheet's hand) returns an unpinned direction to its default.
	private void KeepDirection()
	{
		let wanted = mVertical ? FlexDirection.Column : FlexDirection.Row;
		if (LayoutStyle.Direction == wanted)
			return;
		let style = scope Sedulous.GUI.LayoutStyle();
		style.Set(LayoutStyle);
		style.Direction = wanted;
		// Along, it gives way (what does not fit overflows); across, its content's minimum holds.
		style.MinWidth = mVertical ? LayoutLength() : LayoutLength.Px(0.0f);
		style.MinHeight = mVertical ? LayoutLength.Px(0.0f) : LayoutLength();
		LayoutStyle = style;
		for (int i = 0; i < ChildCount; ++i)
		{
			if (IsSeparator(GetChildAt(i)))
				GetChildAt(i).RequestLayout(); // its thickness lies along the other axis now
		}
	}
}
