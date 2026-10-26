using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Menu (PopupMenu): a floating vertical list of rows - a context menu or a menu dropped from a
// menu bar. Modeled on eepp's UIMenu/UIPopUpMenu family (role only). Open() shows it as an auto
// popup, a child of what opened it, in the top layer, so a press outside or Escape closes it.
// Rows come in a small hierarchy mirroring eepp:
//   MenuRow          - base row (height + hover-notify hook)
//     MenuSeparator  - a non-interactive divider line
//     MenuItem       - an activatable row: text + optional check mark / icon / shortcut column
//       MenuSubItem  - an item that opens a nested submenu on hover or click
//
// A submenu is a popup of its item: open, it is the item's child, so the menus holding it are its
// ancestors and the popup stack's nesting rules give the chain for free (a press inside any open
// menu of the chain closes only the menus deeper than it; opening another item's submenu closes
// the open one; closing a menu closes what it holds). It is placed right of its item, flipped
// left at the root's edge. Activating a leaf item closes the whole chain from its root menu.
// While the pointer heads for an open submenu across other rows (inside the triangle from where
// it was to the submenu's near edge, Godot's safe area), the submenu stays open; if the pointer
// rests there a moment, the row under it takes over.
//
// In markup a Menu holds MenuItems (`text`, `shortcut`, `checkable`, `checked`, a `command`),
// MenuSeparators and nested Menus (its `text` the submenu item's); an item reports `activate`.
// A menu is not shown until opened: one in a page waits there for a `context-menu` naming it.

// === Row base ===============================================================
// A row in a menu. Reports its preferred height and, on hover, notifies the owning menu
// (which uses it to open/close submenus). Selectable rows are the ones keyboard navigation
// and activation consider.
abstract class MenuRow : UIWidget
{
	private delegate void() mOnHovered ~ delete _;

	public abstract float RowHeight { get; }
	public virtual bool IsSelectable => false;

	/// Called whenever the pointer enters it - the menu wires this. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnHovered(delegate void() callback)
	{
		delete mOnHovered;
		mOnHovered = callback;
	}

	protected override void OnMouseEnter(MouseEvent e)
	{
		if (mOnHovered != null)
			mOnHovered();
	}
}

// === Separator =============================================================
[GuiReflect(true)]
class MenuSeparator : MenuRow
{
	private float mHeight = 9.0f;
	private Color mLine = .(0.32f, 0.34f, 0.40f, 1.0f);

	public this()
	{
		Tag = "menuseparator";
		AccessRoleName = "separator"; // what a screen reader takes it for
	}

	public override float RowHeight => mHeight;

	public Color LineColor
	{
		get => mLine;
		set
		{
			mLine = value;
			Invalidate();
		}
	}

	// Theming part: menuseparator::line.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("line");
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let b = LocalBounds;
		let y = b.Y + b.Height * 0.5f;
		GetPartStyle("line").Draw(ctx, .(b.X + 8.0f, y, Math.Max(0.0f, b.Width - 16.0f), 1.0f), FilledBox(mLine, scope NodeBox()));
	}
}

// === Activatable item ======================================================
[GuiReflect(true), Scriptable]
class MenuItem : MenuRow
{
	/// The inline-start column (check / icon).
	protected const float cGutter = 22.0f;
	/// The inline-end column (shortcut end / submenu arrow).
	protected const float cRightPad = 14.0f;
	/// Between a label and its shortcut.
	protected const float cShortcutGap = 24.0f;

	private Sedulous.GUI.Text mText = new .() ~ delete _;
	// Its access key.
	private char32 mMnemonic = '\0';
	private int mMnemonicStart = 0;
	private int mMnemonicEnd = 0;
	private Sedulous.GUI.Text mShortcut = new .() ~ delete _;
	private Drawable mIcon = null ~ _?.ReleaseRef();
	private bool mCheckable = false;
	private bool mChecked = false;
	private float mRowHeight = 26.0f;
	private Color mHighlight = .(0.24f, 0.40f, 0.62f, 1.0f);
	private Color mCheckColor = .(0.88f, 0.90f, 0.94f, 1.0f);
	private delegate void() mOnPicked ~ delete _;
	private delegate void() mOnActivated ~ delete _;
	private delegate void(bool on) mOnToggled ~ delete _;
	private delegate void() mOnWidthChanged ~ delete _;
	// Its text, its shortcut: its command's (OnBoundCommandText).
	private bool mTextFromCommand = false;
	private bool mShortcutFromCommand = false;

	public this()
	{
		Tag = "menuitem";
		AccessRoleName = "menuitem"; // what a screen reader takes it for
		TabFocusable = true; // the keyboard and the pad walk the items (a disabled one is skipped)
		mText.SetAlignment(.Start, .Middle);
		mShortcut.SetAlignment(.End, .Middle);
	}

	/// A screen reader may press it.
	public override bool AccessActivates => true;

	// === Content ===

	/// Its text as it shows (the `&` taken out); set, an `&` marks its access key (`&Open`: O),
	/// `&&` an ampersand.
	[GuiProperty("", .Translatable, "name"), Scriptable]
	public StringView Text
	{
		get => mText.GetString();
		set
		{
			let mnemonic = scope Sedulous.GUI.Mnemonic();
			ParseMnemonic(value, mnemonic);
			mMnemonic = mnemonic.Key;
			mMnemonicStart = mnemonic.Start;
			mMnemonicEnd = mnemonic.End;
			mText.SetString(mnemonic.Shown);
			Invalidate();
			WidthMayHaveChanged();
		}
	}

	public override char32 Mnemonic => mMnemonic;
	// Focused, it takes typed text for its menu (type-ahead and access keys, Menu.OnTextInput).
	public override bool WantsTextInput => IsTreeEnabled;

	public StringView Shortcut
	{
		get => mShortcut.GetString();
		set
		{
			mShortcut.SetString(value);
			Invalidate();
			WidthMayHaveChanged();
		}
	}

	/// Its icon (null: none). It takes a reference of its own: the caller keeps its.
	public void SetIcon(Drawable icon)
	{
		if (icon != null)
			icon.AddRef();
		if (mIcon != null)
			mIcon.ReleaseRef();
		mIcon = icon;
		Invalidate();
	}

	public Drawable Icon => mIcon;

	public Color HighlightColor
	{
		get => mHighlight;
		set => mHighlight = value;
	}

	public void SetRowHeight(float height)
	{
		mRowHeight = Math.Max(1.0f, height);
	}

	// Checkable state (a leading check mark).
	[GuiProperty("checkable"), Scriptable]
	public bool Checkable
	{
		get => mCheckable;
		set
		{
			mCheckable = value;
			Invalidate();
		}
	}

	/// Set, it calls the toggle callback when it changes.
	[GuiProperty("checked"), Scriptable]
	public bool Checked
	{
		get => mChecked;
		set
		{
			if (mChecked == value)
				return;
			mChecked = value;
			MarkStyleStateDirty(StateChecked);
			Invalidate();
			if (mOnToggled != null)
				mOnToggled(mChecked);
		}
	}

	public override uint32 WidgetStates => (mCheckable && mChecked) ? WidgetStateChecked : WidgetStateNone;

	/// Sets the checked state without the callback (init).
	public void SetCheckedSilently(bool on)
	{
		if (on != mChecked)
			MarkStyleStateDirty(StateChecked);
		mChecked = on;
		Invalidate();
	}

	public override void OnBoundCommandState(BoundCommandState state)
	{
		Enabled = state.Available;
		if (mCheckable)
			SetCheckedSilently(state.Checked);
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnToggled(delegate void(bool on) callback)
	{
		delete mOnToggled;
		mOnToggled = callback;
	}

	// An item bound to a command shows its label where it has no text of its own, its keys
	// where it has no shortcut of its own, and its icon.
	public override void OnBoundCommandText(StringView label, StringView icon, StringView shortcut)
	{
		if ((Text.Length == 0) || mTextFromCommand)
		{
			Text = label;
			mTextFromCommand = true;
		}
		if ((Shortcut.Length == 0) || mShortcutFromCommand)
		{
			Shortcut = shortcut;
			mShortcutFromCommand = true;
		}
		if (icon.Length != 0)
		{
			let resources = ResourceProvider;
			if (resources != null)
			{
				let picture = PictureDrawable(resources, icon); // an SVG drawn as paths, at any size
				if (picture != null)
				{
					SetIcon(picture);
					picture.ReleaseRef();
				}
			}
		}
	}

	// Markup: its text and shortcut exactly as written.
	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name == "text")
			Text = value;
		else if (name == "shortcut")
			Shortcut = value;
		else
			return base.SetMarkupAttribute(name, value);
		return true;
	}

	/// The user's action (run before the menu closes). OWNERSHIP of `callback` transfers.
	public void SetOnPicked(delegate void() callback)
	{
		delete mOnPicked;
		mOnPicked = callback;
	}

	/// The menu installs this: its text, shortcut or text style changed, so its width may have (a
	/// shortcut an action menu fills in as it opens, a font that arrives). OWNERSHIP of `callback`
	/// transfers.
	public void SetOnWidthChanged(delegate void() callback)
	{
		delete mOnWidthChanged;
		mOnWidthChanged = callback;
	}

	/// The menu installs this to close the whole chain after activation. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnActivated(delegate void() callback)
	{
		delete mOnActivated;
		mOnActivated = callback;
	}

	public override float RowHeight => mRowHeight;
	public override bool IsSelectable => true;

	/// Preferred width for auto-sizing: gutter + text + shortcut column + right pad.
	public float PreferredWidth
	{
		get
		{
			let textW = mText.Measure().X;
			let shortcutW = (mShortcut.GetString().Length > 0) ? mShortcut.Measure().X + cShortcutGap : 0.0f;
			return cGutter + textW + shortcutW + cRightPad;
		}
	}

	// Theming: menuitem::highlight (the lit row's background); text via the hook below.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("highlight");
	}

	/// Lit: focused, or (a submenu item) with its submenu open. Not hovered as such: the pointer
	/// moves the focus to the row it enters, so the pointer and the keys share one highlight
	/// (two rows lit at once, the keys' and the pointer's, was ambiguous).
	public virtual bool IsLit => IsFocused;

	// Its label and shortcut draw in its text style.
	protected override void OnTextStyleChange()
	{
		let style = GetTextStyle();
		mText.Font = Font;
		mText.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mShortcut.Font = Font;
		mShortcut.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mText.Direction = TextDirectionFor();
		mShortcut.Direction = TextDirectionFor();
		mText.Color = TextColor;
		mShortcut.Color = TextColor;
		WidthMayHaveChanged(); // a font that arrives widens it
	}

	// Its menu measures again.
	protected void WidthMayHaveChanged()
	{
		if (mOnWidthChanged != null)
			mOnWidthChanged();
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		e.Handled = true;
		Activate();
	}

	// Return, Space, a pad's South: as a click.
	protected override bool OnActivate()
	{
		Activate();
		return true;
	}

	/// Runs the item: toggles (if checkable), fires the user's action, then closes the chain.
	protected virtual void Activate()
	{
		// Its action may end the menu and what holds it (the menu's own close runs after it):
		// they live until it is done.
		let keep = scope List<Node>();
		for (var n = (Node)this; n != null; n = n.Parent)
		{
			n.AddRef();
			keep.Add(n);
		}
		defer
		{
			for (let n in keep)
				n.ReleaseRef();
		}
		if (HasCommand)
			RunBoundCommand(); // a bound command decides its own checked state
		else if (mCheckable)
			Checked = !mChecked;
		if (mOnPicked != null)
			mOnPicked();
		// A script's `activate`: it bubbles (through the menu to what opened it), so one
		// listener hears a whole menu's items, the event's id saying which.
		let activated = scope ItemEvent(.ItemActivate, this, -1, ModelIndex());
		RouteEvent(activated);
		if (mOnActivated != null)
			mOnActivated();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let b = LocalBounds;
		if (IsLit)
			GetPartStyle("highlight").Draw(ctx, b, FilledBox(mHighlight, scope NodeBox()));
		let rtl = IsRightToLeft; // the gutter at the inline start, the pad at the end

		// The gutter: a check mark (if checked) else an icon (if set).
		if (mCheckable && mChecked)
		{
			DrawCheck(ctx, b, rtl);
		}
		else if (mIcon != null)
		{
			let s = Math.Max(0.0f, Math.Max(0.0f, cGutter - 8.0f));
			mIcon.Draw(ctx, Rect.MirroredIn(.(b.X + 4.0f, b.Y + (b.Height - s) * 0.5f, s, s), b, rtl));
		}

		// Text + shortcut share the inner rect (opposite alignments, which follow the direction).
		let inner = Rect.MirroredIn(.(b.X + cGutter, b.Y, Math.Max(0.0f, b.Width - cGutter - cRightPad), b.Height), b, rtl);
		if (mMnemonicEnd > mMnemonicStart) // its access key underlined while access keys show
		{
			let shown = AreMnemonicsShown;
			mText.SetUnderline(shown ? mMnemonicStart : 0, shown ? mMnemonicEnd : 0);
		}
		// The label keeps out of the shortcut's column: squeezed, it ends in an ellipsis before the
		// shortcut rather than running under it.
		var label = inner;
		if (mShortcut.GetString().Length > 0)
		{
			let column = Math.Min(inner.Width, mShortcut.Measure().X + cShortcutGap);
			label.Width = Math.Max(0.0f, inner.Width - column);
			if (rtl)
				label.X = inner.X + column;
		}
		mText.Draw(ctx, label);
		if (mShortcut.GetString().Length > 0)
			mShortcut.Draw(ctx, inner);
	}

	// Draws a check mark stroked inside the gutter (a check is not mirrored, only placed).
	private void DrawCheck(DrawContext ctx, Rect b, bool rtl)
	{
		let cx = Rect.MirroredX(b.X + cGutter * 0.5f, b, rtl);
		let cy = b.Y + b.Height * 0.5f;
		let pb = scope PathBuilder();
		pb.MoveTo(cx - 4.0f, cy);
		pb.LineTo(cx - 1.0f, cy + 3.5f);
		pb.LineTo(cx + 5.0f, cy - 4.0f);
		let path = pb.ToPath();
		ctx.VG.StrokePath(path, mCheckColor, StrokeStyle(1.6f));
		delete path;
	}
}

// === Submenu item ==========================================================
// An item that owns a nested Menu, shown to its right on hover or click. It never closes the
// chain itself; hovering/clicking it asks the owning menu to open the submenu (wired by the
// menu when the item is added).
class MenuSubItem : MenuItem
{
	// Not owned: the Menu holds it.
	private Menu mSubMenu = null;
	private delegate void(bool fromKeys) mOnOpen ~ delete _;
	private Color mArrowColor = .(0.80f, 0.84f, 0.90f, 1.0f);

	public this()
	{
		Tag = "menusubmenu";
		// The arrow toward where its submenu opens, the inline end (menu.right in the menu key
		// context, or menu.left in right to left), opens it and goes in.
		OnCommand(cMenuRightCommand, new (command) => { Across(true, ref command); });
		OnCommand(cMenuLeftCommand, new (command) => { Across(false, ref command); });
	}

	public Menu SubMenu
	{
		get => mSubMenu;
		set => mSubMenu = value;
	}

	public void Across(bool right, ref CommandEvent e)
	{
		if (right != IsRightToLeft)
			OnActivate();
		else
			e.Propagate = true;
	}

	/// The menu installs this to open the submenu; true from the keys (its first item then takes
	/// focus). OWNERSHIP of `callback` transfers.
	public void SetOnOpenSubMenu(delegate void(bool fromKeys) callback)
	{
		delete mOnOpen;
		mOnOpen = callback;
	}

	public Color ArrowColor => mArrowColor;

	/// Lit while its submenu is open too (focus has gone into it).
	public override bool IsLit => base.IsLit || ((mSubMenu != null) && mSubMenu.IsOpen);

	// A click opens it (open, never close); Return, Space or Right open it and go in (its first
	// item takes focus).
	protected override void Activate()
	{
		if (mOnOpen != null)
			mOnOpen(false);
	}

	protected override bool OnActivate()
	{
		if (mOnOpen != null)
			mOnOpen(true);
		return true;
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		// An arrow in the inline-end pad, pointing toward where the submenu opens.
		let b = LocalBounds;
		let rtl = IsRightToLeft;
		let aw = 5.0f;
		let ah = 8.0f;
		let ax = b.X + b.Width - aw - 6.0f;
		let ay = b.Y + (b.Height - ah) * 0.5f;
		let pb = scope PathBuilder();
		pb.MoveTo(Rect.MirroredX(ax, b, rtl), ay);
		pb.LineTo(Rect.MirroredX(ax, b, rtl), ay + ah);
		pb.LineTo(Rect.MirroredX(ax + aw, b, rtl), ay + ah * 0.5f);
		pb.Close();
		let path = pb.ToPath();
		ctx.VG.FillPath(path, mArrowColor);
		delete path;
	}
}

// A menu's scroll arrow: at its top or its bottom while its items do not fit the window; the
// pointer resting on it scrolls them at a steady speed (Windows's and macOS's menus).
class MenuScrollArrow : UIWidget
{
	/// Points a second.
	private const float cSpeed = 360.0f;

	private bool mUp;
	private bool mLive = true;
	private bool mTicking = false;
	private Color mFace = .(0.16f, 0.17f, 0.21f, 1.0f);
	private Color mArrow = .(0.80f, 0.84f, 0.90f, 1.0f);
	private delegate void(float delta) mOnScroll ~ delete _;

	public this(bool up)
	{
		mUp = up;
		Tag = "menuscroll";
		TabFocusable = false;
		AccessHidden = true; // a screen reader's keys scroll the menu as they move
	}

	/// OWNERSHIP of `scroll` transfers.
	public void SetOnScroll(delegate void(float delta) scroll)
	{
		delete mOnScroll;
		mOnScroll = scroll;
	}

	public void SetColors(Color face, Color arrow)
	{
		mFace = face;
		mArrow = arrow;
		Invalidate();
	}

	/// Whether it can scroll further its way (dimmed at the end).
	public bool Live
	{
		get => mLive;
		set
		{
			if (value == mLive)
				return;
			mLive = value;
			Invalidate();
		}
	}

	protected override void OnPointerStateChange()
	{
		base.OnPointerStateChange();
		if (!Hovered || mTicking)
			return;
		mTicking = true;
		let tick = new TickAction(new (elapsed) =>
			{
				if (!Hovered)
				{
					mTicking = false;
					return false;
				}
				if (mOnScroll != null)
					mOnScroll((mUp ? -cSpeed : cSpeed) * (float)elapsed.TotalSeconds);
				return true;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		ctx.VG.FillRect(.(localBounds.X, localBounds.Y, localBounds.Width, localBounds.Height), mFace);
		let cx = localBounds.X + localBounds.Width * 0.5f;
		let cy = localBounds.Y + localBounds.Height * 0.5f;
		let w = 5.0f;
		let h = 3.0f;
		let pb = scope PathBuilder();
		pb.MoveTo(cx - w, mUp ? cy + h : cy - h);
		pb.LineTo(cx + w, mUp ? cy + h : cy - h);
		pb.LineTo(cx, mUp ? cy - h : cy + h);
		pb.Close();
		var arrow = mArrow;
		arrow.A *= mLive ? 1.0f : 0.35f;
		let path = pb.ToPath();
		ctx.VG.FillPath(path, arrow);
		delete path;
	}
}

// === Menu ==================================================================
[GuiReflect(true), Scriptable]
class Menu : UIWidget
{
	/// Seconds a resting pointer waits before switching.
	private const double cSafeAreaGrace = 0.3;
	// Scrolling, when its items do not fit the window.
	private const float cArrowHeight = 16.0f;
	/// Kept from the window's top and bottom.
	private const float cScreenMargin = 8.0f;
	/// Points a wheel notch turns.
	private const float cWheelStep = 40.0f;

	// Its width, its items' height, and the height it keeps: taller than the window holds (less
	// a margin), it keeps to the window and scrolls its items between two arrows, rather than
	// running off the window's edge.
	private struct Extent
	{
		public float Width = 0.0f;
		public float Content = 0.0f;
		public float Height = 0.0f;
		public bool Scrolls = false;

		public this() { }
	}

	private String mTitle = new .() ~ delete _;
	// Its row in the menu holding it (not owned), when a submenu.
	private MenuSubItem mRow = null;
	// Where markup's children land, then taken in.
	private Node mMarkupHost = null ~ _?.ReleaseRef();
	private bool mAdopting = false;
	// Rows, owned as children.
	private List<MenuRow> mRows = new .() ~ delete _;
	// Keeps submenus alive (their items' children only while open): a reference each.
	private List<Menu> mOwnedSubMenus = new .() ~ { for (let m in _) m.ReleaseRef(); delete _; };
	// Typed text.
	private TypeAheadSearch mTypeAhead = new .() ~ delete _;
	private bool mAutoWidth = true; // a fixed default cut long items and ran labels under shortcuts
	// The safe area toward an open submenu: the pointer's last two places, a hover deferred.
	private Float2 mPointerAt = .(0.0f, 0.0f);
	private bool mPointerKnown = false;
	// Not owned: one of its rows.
	private MenuRow mDeferredRow = null;
	private double mDeferredFor = 0.0;
	private bool mDeferring = false;
	private float mWidth = 160.0f; // SetWidth's
	private float mItemHeight = 26.0f;
	private bool mScrolls = false;
	private float mScroll = 0.0f;
	private MenuScrollArrow mScrollUp = null ~ _?.ReleaseRef();
	private MenuScrollArrow mScrollDown = null ~ _?.ReleaseRef();
	private Color mPanelColor = .(0.16f, 0.17f, 0.21f, 1.0f);
	private delegate void(PopupCloseReason reason) mOnClosed ~ delete _;
	private delegate void(Menu menu) mOnOpening ~ delete _;

	public this()
	{
		Tag = "menu";
		AccessRoleName = "menu"; // what a screen reader takes it for
		// Open, it takes focus (itself: no item lit until a key or the pointer picks one), and
		// up and down go round its items.
		TabFocusable = true;
		NavScope = .Wrap;
		Displayed = false; // shown when opened (one in a page waits there, unseen)
		// Its keys are bindings in the menu key context: a game remaps them like any.
		KeyContext = cMenuKeyContext;
		OnCommand(cMenuDownCommand, new (command) => { Step(1); });
		OnCommand(cMenuUpCommand, new (command) => { Step(-1); });
		// Return and Space by default: the focused item runs (or its submenu opens).
		OnCommand(cMenuActivateCommand, new (command) =>
			{
				let d = EventDispatcher;
				let focus = (d != null) ? d.FocusNode : null;
				if ((focus == null) || !HoldsRow(focus) || !focus.IsTreeEnabled || !focus.HandleActivate())
					command.Propagate = true;
			});
		// The arrow toward the inline start (Left, Right in right to left) in a submenu closes it,
		// focus going back to its item; in a menu of a bar, either goes on to the bar (which
		// moves along it).
		OnCommand(cMenuLeftCommand, new (command) => { Across(false, ref command); });
		OnCommand(cMenuRightCommand, new (command) => { Across(true, ref command); });
		SetBox(FilledBox(mPanelColor, scope NodeBox())); // its own face, which a sheet's (a theme's) replaces
		// Taller than the window, its items scroll: the wheel turns them.
		AddEventListener(.MouseWheel, new (e) =>
			{
				if (!mScrolls)
					return;
				ScrollBy(-((WheelEvent)e).Delta.Y * cWheelStep);
				e.Handled = true;
			});
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			TextColor = .(0.88f, 0.90f, 0.94f, 1.0f);
		}
	}

	/// Whether its items are taller than the window holds, so they scroll.
	public bool Scrolls => mScrolls;
	/// How far its items are scrolled, in points (0: the first at the top).
	public float ItemScroll => mScroll;

	public void ScrollBy(float delta)
	{
		if (delta == 0.0f)
			return;
		mScroll += delta;
		Relayout();
		Invalidate();
	}

	public void SetWidth(float width)
	{
		mWidth = Math.Max(1.0f, width);
		mAutoWidth = false;
		Relayout();
	}

	public void SetItemHeight(float height)
	{
		mItemHeight = Math.Max(1.0f, height);
		ApplyItemHeights();
		Relayout();
	}

	/// Sizes the menu to its widest item, its label and its shortcut both (the default; SetWidth
	/// gives it a width of its own instead).
	public void SetAutoWidth(bool enabled)
	{
		mAutoWidth = enabled;
		Relayout();
	}

	/// Adds a plain activatable item. Activating runs `action`, then closes the whole chain.
	/// OWNERSHIP of `action` transfers.
	public MenuItem AddItem(StringView text, delegate void() action)
	{
		let item = new MenuItem();
		item.Text = text;
		item.SetOnPicked(action);
		AddItemNode(item, item);
		item.ReleaseRef(); // the tree's reference keeps it
		return item;
	}

	/// Adds a checkable item. Activating toggles it (calling `onToggled`) and closes the chain.
	/// OWNERSHIP of `onToggled` transfers.
	public MenuItem AddCheckItem(StringView text, bool on, delegate void(bool on) onToggled)
	{
		let item = new MenuItem();
		item.Text = text;
		item.Checkable = true;
		item.SetCheckedSilently(on);
		item.SetOnToggled(onToggled);
		AddItemNode(item, item);
		item.ReleaseRef(); // the tree's reference keeps it
		return item;
	}

	/// Adds a horizontal separator (a non-interactive divider).
	public void AddSeparator()
	{
		let sep = new MenuSeparator();
		AdoptSeparator(sep);
		sep.ReleaseRef(); // the tree's reference keeps it
	}

	/// Takes `sep` as a row (the tree takes a reference: the caller keeps its).
	public void AdoptSeparator(MenuSeparator sep)
	{
		sep.SetOnHovered(new () => { OnRowHovered(sep); });
		AddChild(sep);
		mRows.Add(sep);
		Relayout();
	}

	/// Adds a submenu item; returns the (empty) child Menu to populate. The child is owned by
	/// this menu and shown to the item's right on hover/click.
	public Menu AddSubMenu(StringView text)
	{
		let sub = new Menu();
		AdoptSubMenu(sub, text);
		sub.ReleaseRef(); // this menu's reference keeps it
		return sub;
	}

	/// Takes `sub` as the submenu of a new item titled `text` (markup's nested Menu). It takes a
	/// reference of its own: the caller keeps its.
	public Menu AdoptSubMenu(Menu sub, StringView text)
	{
		let item = new MenuSubItem();
		item.Text = text;
		ShareTextStyle(sub, false);
		sub.SetItemHeight(mItemHeight);
		item.SubMenu = sub;
		sub.mRow = item; // its title, set later (a script's `add` then `title`), names the row
		item.SetOnOpenSubMenu(new (fromKeys) => { OpenSubMenuFor(item, fromKeys); });
		AddItemNode(item, item);
		item.ReleaseRef(); // the tree's reference keeps it
		sub.AddRef();
		mOwnedSubMenus.Add(sub); // keep the submenu alive
		return sub;
	}

	/// Takes an item made elsewhere (markup's MenuItem).
	public void AdoptItem(MenuItem item)
	{
		AddItemNode(item, item);
	}

	/// Its title: a menu bar's button, or a submenu's item (markup's `text`).
	public StringView Title
	{
		get => mTitle;
		set
		{
			let title = scope String(value);
			mTitle.Set(title);
			if (mRow != null)
				mRow.Text = title; // the row in the menu that holds it
		}
	}

	public override bool SetMarkupAttribute(StringView name, StringView value)
	{
		if (name != "text")
			return base.SetMarkupAttribute(name, value);
		Title = value;
		return true;
	}

	/// Markup's children are its items; a menu given items there sizes to its widest.
	public override Node ChildHost
	{
		get
		{
			if (mMarkupHost == null)
			{
				mMarkupHost = new MarkupChildHost(new (host) => { AdoptMarkupChildren(host); });
				mAutoWidth = true;
			}
			return mMarkupHost;
		}
	}

	/// The rows markup gave it, taken in (its MarkupChildHost calls it).
	public void AdoptMarkupChildren(Node host)
	{
		if (mAdopting)
			return;
		mAdopting = true;
		while (host.ChildCount != 0)
		{
			let child = host.GetChildAt(0);
			child.AddRef(); // held across its move
			host.RemoveChild(child);
			if (let sub = child as Menu)
				AdoptSubMenu(sub, sub.Title);
			else if (let sep = child as MenuSeparator)
				AdoptSeparator(sep);
			else if (let item = child as MenuItem)
				AdoptItem(item);
			child.ReleaseRef();
		}
		mAdopting = false;
	}

	public int ItemCount
	{
		get
		{
			int n = 0;
			for (let row in mRows)
			{
				if (row.IsSelectable)
					++n;
			}
			return n;
		}
	}

	public int RowCount => mRows.Count;

	[Scriptable]
	public bool IsOpen
	{
		get
		{
			let d = EventDispatcher;
			return (d != null) && d.IsPopupOpen(this);
		}
	}

	/// The open submenu of one of its items, or null.
	public Menu CurrentSubMenu
	{
		get
		{
			for (let row in mRows)
			{
				let sub = row as MenuSubItem;
				if ((sub != null) && (sub.SubMenu != null) && sub.SubMenu.IsOpen)
					return sub.SubMenu;
			}
			return null;
		}
	}

	/// Told when this menu closes, and why. A MenuBar uses it to clear its "open menu" state.
	/// OWNERSHIP of `callback` transfers.
	public void SetOnClosed(delegate void(PopupCloseReason reason) callback)
	{
		delete mOnClosed;
		mOnClosed = callback;
	}

	/// Told each time just before it opens (a submenu too): an owner refreshes its items then, so
	/// what they show (enabled, checked) is true as the user sees them. OWNERSHIP of `callback`
	/// transfers.
	public void SetOnOpening(delegate void(Menu menu) callback)
	{
		delete mOnOpening;
		mOnOpening = callback;
	}

	/// Closes this menu (and the submenus it holds) if it is open.
	[Scriptable]
	public new void Close()
	{
		let d = EventDispatcher;
		if (d != null)
			d.ClosePopup(this);
	}

	/// Shows the menu as a popup of `owner` at `position` (in the root's space): a context
	/// menu at the pointer, below it and toward the owner's inline end, above it where it does
	/// not fit, slid back in from the edges.
	public void Open(Node owner, Float2 position)
	{
		let options = new PopupOptions();
		options.AnchorRect = .(position.X, position.Y, 0.0f, 0.0f);
		options.HasAnchorRect = true;
		options.TakesFocus = true; // the keyboard and the pad work in it; focus comes back on close
		OpenAs(owner, options);
	}

	/// Opens it at a point in the root's space, as a popup of what holds it (a menu a script
	/// added); whether it opened. `OpenAt` to a script.
	[Scriptable, ScriptName("OpenAt")]
	public bool OpenAtPoint(float x, float y)
	{
		let owner = (Parent != null) ? Parent : RootNode;
		if ((owner == null) || (owner == this))
			return false;
		let options = new PopupOptions();
		options.AnchorRect = .(x, y, 0.0f, 0.0f);
		options.HasAnchorRect = true;
		options.TakesFocus = true;
		options.ReturnHome = true; // a script's menu: back where it waits, to open again
		OpenAs(owner, options);
		return IsOpen;
	}

	/// Focuses its first item that can take it (a menu opened from the keyboard or the pad).
	public void FocusFirstItem()
	{
		FocusItem(0, 1);
	}

	/// Shows the menu as a popup of `owner`, against `anchor` (a menu bar's button: below it).
	public void OpenBelow(Node owner, Node anchor)
	{
		let options = new PopupOptions();
		options.Anchor = anchor;
		options.Placement.Side = .Below;
		options.TakesFocus = true;
		OpenAs(owner, options);
	}

	/// Opens it below `anchor`, as that node's popup (a script's menu: back where it waits once
	/// closed, to open again); whether it opened. `OpenBelow` to a script.
	[Scriptable, ScriptName("OpenBelow")]
	public bool OpenBelowNode(Node anchor)
	{
		if (anchor == null)
			return false;
		let options = new PopupOptions();
		options.Anchor = anchor;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 0.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.ReturnHome = true;
		OpenAs(anchor, options);
		return IsOpen;
	}

	// Its items take its font and colour.
	protected override void OnTextStyleChange()
	{
		for (let row in mRows)
		{
			if (let it = row as MenuItem)
				ShareTextStyle(it);
		}
	}

	public override void OnSizeChange()
	{
		Relayout();
	}

	// Typed text in it (its items ask for it while focused): a character that is one item's
	// access key runs that item, as a desktop's menus do; else the focus goes to the next item
	// whose text starts with what was typed (TypeAheadSearch).
	protected override void OnTextInput(TextInputEvent e)
	{
		if (!HoldsRow(e.Target) || (e.Text.Length == 0))
			return;
		e.Handled = true;
		int end = 0;
		let typed = SimpleLowerCase((char32)DecodeCodepoint(e.Text, ref end));
		MenuItem keyed = null;
		int keys = 0;
		for (let row in mRows)
		{
			let it = row as MenuItem;
			if ((it != null) && it.IsTreeEnabled && (it.Mnemonic == typed))
			{
				keyed = it;
				keys++;
			}
		}
		if ((keys == 1) && (end == e.Text.Length))
		{
			keyed.RequestFocus();
			keyed.HandleActivate();
			return;
		}
		let d = EventDispatcher;
		int32 current = -1;
		for (int i = 0; i < mRows.Count; i++)
		{
			if (mRows[i].IsFocusWithin)
				current = (int32)i;
		}
		let found = mTypeAhead.Find(e.Text, (d != null) ? d.Time : 0.0f, (int32)mRows.Count, current, scope (i, outText) =>
			{
				let it = mRows[i] as MenuItem;
				if ((it != null) && it.IsSelectable && it.IsTreeEnabled)
					outText.Append(it.Text);
			});
		if (found >= 0)
			FocusItem(found, 1);
	}

	// Measured as it lays itself out: its rows' width, and the height it keeps (a popup fitting
	// its content asks this, so a menu that scrolls is placed at the height it shows).
	public override Float2 MeasureContent(Float2 available)
	{
		let extent = MeasureItems();
		return .(extent.Width, extent.Height);
	}

	// Whether `node` is one of its rows.
	private bool HoldsRow(Node node)
	{
		for (let row in mRows)
		{
			if (row == node)
				return true;
		}
		return false;
	}

	// Up and down go round the items (from the menu itself: the first or the last).
	private void Step(int32 step)
	{
		int32 at = -1;
		for (int i = 0; i < mRows.Count; ++i)
		{
			if (mRows[i].IsFocusWithin)
				at = (int32)i;
		}
		FocusItem((at < 0) ? ((step > 0) ? 0 : (int32)mRows.Count - 1) : at + step, step);
	}

	// Focuses the first item from `start` going `step` (round the end) that can take focus.
	private bool FocusItem(int32 start, int32 step)
	{
		let count = (int32)mRows.Count;
		for (int32 n = 0; n < count; ++n)
		{
			let i = ((start + n * step) % count + count) % count;
			let row = mRows[i];
			if (row.IsSelectable && row.IsTreeEnabled && row.TabFocusable)
			{
				ScrollRowIntoView(row);
				row.RequestFocus();
				return true;
			}
		}
		return false;
	}

	// The arrow toward the inline start in a submenu closes it; in a menu of a bar, either goes
	// on to the bar.
	private void Across(bool right, ref CommandEvent e)
	{
		if ((right == IsRightToLeft) && (Parent is MenuSubItem))
			Close();
		else
			e.Propagate = true;
	}

	private void AddItemNode(Node node, MenuRow row)
	{
		if (let it = row as MenuItem)
		{
			ShareTextStyle(it);
			it.SetRowHeight(mItemHeight);
			it.SetOnActivated(new () => { RootMenu().Close(); });
			it.SetOnWidthChanged(new () => { Relayout(); });
		}
		row.SetOnHovered(new () => { OnRowHovered(row); });
		if (mScrollUp != null) // before the scroll arrows, which stay over the items
			AddChildAt(node, GetChildIndex(mScrollUp));
		else
			AddChild(node);
		mRows.Add(row);
		Relayout();
	}

	private void ApplyItemHeights()
	{
		for (let row in mRows)
		{
			if (let it = row as MenuItem)
				it.SetRowHeight(mItemHeight);
		}
	}

	private Extent MeasureItems()
	{
		var e = Extent();
		e.Width = mWidth;
		if (mAutoWidth)
		{
			float widest = 1.0f;
			for (let row in mRows)
			{
				if (let it = row as MenuItem)
					widest = Math.Max(widest, it.PreferredWidth);
			}
			e.Width = widest;
		}
		for (let row in mRows)
			e.Content += row.RowHeight;
		let root = RootNode;
		let room = ((root != null) && (root != this) && (root.Size.Y > 0.0f))
			? root.Size.Y - 2.0f * cScreenMargin - Chrome.TotalVertical
			: 0.0f;
		e.Scrolls = (room > 2.0f * cArrowHeight + mItemHeight) && (e.Content > room);
		e.Height = e.Scrolls ? room : e.Content;
		return e;
	}

	private void Relayout()
	{
		let extent = MeasureItems();
		// Its padding and border (its chrome): its rows and arrows inside them, its size theirs
		// added (a sheet's padding insets a lit row from the menu's rounded edge).
		let inset = Chrome;
		// Being placed (a popup shrunk to the room beside its anchor), it keeps the height it was
		// given and scrolls within it; else the height it measures.
		let placed = IsBeingPlaced && (Size.Y > 0.0f);
		let width = extent.Width;
		let content = extent.Content;
		let height = placed ? Math.Min(Math.Max(0.0f, Size.Y - inset.TotalVertical), extent.Content) : extent.Height;
		mScrolls = placed ? ((content > height + 0.5f) && (height > 2.0f * cArrowHeight + mItemHeight)) : extent.Scrolls;
		let top = mScrolls ? cArrowHeight : 0.0f;
		let view = height - 2.0f * top;
		mScroll = mScrolls ? Math.Clamp(mScroll, 0.0f, Math.Max(0.0f, content - view)) : 0.0f;
		var y = inset.Top + top - mScroll;
		for (let row in mRows)
		{
			let h = row.RowHeight;
			row.Position = .(inset.Left, y);
			row.Size = .(width, h);
			y += h;
		}
		if (mScrolls && (mScrollUp == null))
		{
			mScrollUp = new MenuScrollArrow(true);
			mScrollDown = new MenuScrollArrow(false);
			mScrollUp.SetOnScroll(new (delta) => { ScrollBy(delta); });
			mScrollDown.SetOnScroll(new (delta) => { ScrollBy(delta); });
			AddChild(mScrollUp); // last: over the items, hit before them
			AddChild(mScrollDown);
		}
		if (mScrollUp != null)
		{
			MenuScrollArrow[2] arrows = .(mScrollUp, mScrollDown);
			for (let arrow in arrows)
			{
				arrow.Displayed = mScrolls;
				arrow.SetColors(mPanelColor, TextColor);
			}
			mScrollUp.Position = .(inset.Left, inset.Top);
			mScrollUp.Size = .(width, cArrowHeight);
			mScrollUp.Live = mScroll > 0.0f;
			mScrollDown.Position = .(inset.Left, inset.Top + height - cArrowHeight);
			mScrollDown.Size = .(width, cArrowHeight);
			mScrollDown.Live = mScroll < content - view;
		}
		ClipChildren = mScrolls;
		// Sized by its items without pinning the size (as Size's setter does): a popup that fits
		// its content measures it again each pass, and a pinned size would hold a stale height.
		let outerWidth = width + inset.TotalHorizontal;
		let outerHeight = height + inset.TotalVertical;
		if ((Size.X != outerWidth) || (Size.Y != outerHeight))
			Arrange(.(Position.X, Position.Y, outerWidth, outerHeight));
	}

	// Scrolls so `row` shows whole between the arrows (a key moved to it).
	private void ScrollRowIntoView(MenuRow row)
	{
		if (!mScrolls)
			return;
		float y = 0.0f;
		for (let r in mRows)
		{
			if (r == row)
				break;
			y += r.RowHeight;
		}
		let view = Size.Y - Chrome.TotalVertical - 2.0f * cArrowHeight;
		if (y < mScroll)
			mScroll = y;
		else if (y + row.RowHeight > mScroll + view)
			mScroll = y + row.RowHeight - view;
		else
			return;
		Relayout();
		Invalidate();
	}

	// OWNERSHIP of `options` transfers.
	private void OpenAs(Node owner, PopupOptions options)
	{
		let dispatcher = owner.EventDispatcher;
		if ((dispatcher == null) || IsOpen)
		{
			delete options;
			return;
		}
		if (mOnOpening != null)
			mOnOpening(this);
		Displayed = true;
		Relayout();
		options.FitContent = true; // sized as it measures, again when a font arrives
		options.OnClosed = new (reason) =>
			{
				Displayed = false; // one gone back to where it waits is unseen there
				if (mOnClosed != null)
					mOnClosed(reason);
			};
		dispatcher.OpenPopup(owner, this, options);
	}

	// === Submenus ===
	// Opens `item`'s submenu as its popup, right of it (left at the root's edge); the stack
	// closes another item's open submenu, which this one's owner is not inside. It takes focus
	// (given back to the item when it closes); from the keys its first item is lit.
	private void OpenSubMenuFor(MenuSubItem item, bool fromKeys)
	{
		let sub = item.SubMenu;
		if (sub == null)
			return;
		if (sub.IsOpen)
		{
			if (fromKeys)
				sub.FocusFirstItem();
			return;
		}
		// Just outside this menu (past its padding and border on that side, which hold the row
		// in), its first row level with the row (lined up by its content).
		let inset = Chrome;
		let options = new PopupOptions();
		options.Anchor = item;
		options.Placement.Side = .InlineEnd;
		options.Placement.Gap = item.IsRightToLeft ? inset.Left : inset.Right;
		options.Placement.AlignContent = true;
		options.TakesFocus = true;
		sub.OpenAs(item, options);
		if (fromKeys)
			sub.FocusFirstItem();
	}

	// The pointer over it, in the root's space: where it was is the safe area's apex.
	protected override void OnMouseMove(MouseEvent e)
	{
		let root = RootNode;
		mPointerAt = (root != null) ? root.ConvertToNodeSpace(e.Position) : e.Position;
		mPointerKnown = true;
	}

	// A row was hovered: an open submenu of another row closes (unless the pointer is heading
	// for it: then a moment later, if it rests on this row); a submenu row opens its own; an
	// item takes focus, so the keys go on from where the pointer is, and a row that cannot (a
	// separator, a disabled item) gives it to the menu, lighting none.
	private void OnRowHovered(MenuRow row)
	{
		let open = CurrentSubMenu;
		if ((open != null) && (open.Parent != row) && HeadingFor(open))
		{
			DeferHover(row);
			return;
		}
		mDeferredRow = null;
		if ((open != null) && (open.Parent != row))
			open.Close();
		if (row.IsSelectable && row.IsTreeEnabled)
			row.RequestFocus();
		else if (IsFocusWithin)
			RequestFocus();
		if (let sub = row as MenuSubItem)
			OpenSubMenuFor(sub, false);
	}

	// Whether the pointer, from where this menu last saw it to where it is now (the hover comes
	// before the move reaches the menu), is inside the triangle from there to the open
	// submenu's near edge.
	private bool HeadingFor(Menu sub)
	{
		let d = EventDispatcher;
		var root = (Node)this;
		while (root.Parent != null)
			root = root.Parent;
		if (!mPointerKnown || (d == null))
			return false;
		let apex = mPointerAt;
		let p = root.ConvertToNodeSpace(d.MousePosition);
		let sp = sub.Position;
		let ss = sub.Size;
		let edgeX = (sp.X >= Position.X + Size.X * 0.5f) ? sp.X : sp.X + ss.X; // the side facing this menu
		let b = Float2(edgeX, sp.Y);
		let c = Float2(edgeX, sp.Y + ss.Y);
		float Side(Float2 from, Float2 to, Float2 q) => (to.X - from.X) * (q.Y - from.Y) - (to.Y - from.Y) * (q.X - from.X);
		let d1 = Side(apex, b, p);
		let d2 = Side(b, c, p);
		let d3 = Side(c, apex, p);
		let negative = (d1 < 0.0f) || (d2 < 0.0f) || (d3 < 0.0f);
		let positive = (d1 > 0.0f) || (d2 > 0.0f) || (d3 > 0.0f);
		return !(negative && positive) && ((p.X != apex.X) || (p.Y != apex.Y));
	}

	// The hover on `row` counts after a moment, if the pointer is still on it and has not
	// reached the submenu.
	private void DeferHover(MenuRow row)
	{
		mDeferredRow = row;
		mDeferredFor = 0.0;
		if (mDeferring || (ActionManager == null))
			return;
		mDeferring = true;
		let tick = new TickAction(new (elapsed) =>
			{
				if (mDeferredRow == null)
				{
					mDeferring = false;
					return false;
				}
				mDeferredFor += elapsed.TotalSeconds;
				if (mDeferredFor < cSafeAreaGrace)
					return true;
				let waited = mDeferredRow;
				mDeferredRow = null;
				mDeferring = false;
				if (waited.Hovered)
				{
					mPointerKnown = false; // resting: no heading
					OnRowHovered(waited);
				}
				return false;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	// The outermost menu holding this one (a submenu's parents up the tree).
	private Menu RootMenu()
	{
		var root = this;
		for (var n = Parent; n != null; n = n.Parent)
		{
			if (let m = n as Menu)
				root = m;
		}
		return root;
	}
}
