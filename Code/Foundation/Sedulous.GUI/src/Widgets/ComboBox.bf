using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;

namespace Sedulous.GUI;

// ComboBox: a control that shows the current selection and, when clicked, drops down a list of
// choices. Modeled on eepp's UIDropDownList (role only), built by composition: the dropdown is a
// ListBox opened as an auto popup: it stays the combo box's child while open, in the top layer,
// placed below it (above when there is more room there, shrunk to the room), so a press outside
// or Escape closes it. Picking an item sets the selection and closes the dropdown.
//
// The keyboard and the pad: Return, Space, a pad's South or Alt+Down open it with the list focused
// on the current item, where the arrows move and Return picks; closed, Up and Down step the
// selection (given back past the first and the last, so focus moves on), and a letter or a digit
// selects the next item starting with it.
//
// With nothing selected (-1: none yet, or the values it stands for differ, a property grid's
// mixed state) it shows its placeholder in the placeholder's colour.

[GuiReflect(true)]
class ComboBox : UIWidget
{
	private List<String> mItems = new .() ~ DeleteContainerAndItems!(_);
	private Sedulous.GUI.Text mText = new .() ~ delete _;
	// Its child while open; kept here while closed.
	private ListBox mDropdown = null ~ _?.ReleaseRef();
	private int32 mSelected = -1;
	private float mItemHeight = 24.0f;
	private float mDropdownMaxHeight = 160.0f;
	private Color mBoxColor = .(0.18f, 0.20f, 0.25f, 1.0f);
	private Color mArrowColor = .(0.75f, 0.80f, 0.86f, 1.0f);
	// A text field's.
	private Color mPlaceholderColor = .(0.55f, 0.58f, 0.62f, 1.0f);
	private String mPlaceholder = new .() ~ delete _;
	private delegate void(int32 index) mOnChanged ~ delete _;
	// What bindings reading the selection follow.
	private Observable mSelectedChanged = new .() ~ delete _;
	// What ItemsText last wrote.
	private String mItemsText = new .() ~ delete _;

	public this()
	{
		Tag = "combobox";
		AccessRoleName = "combobox"; // what a screen reader takes it for
		TabFocusable = true;
		mText.SetAlignment(.Start, .Middle);
	}

	public void AddItem(StringView text)
	{
		mItems.Add(new String(text));
		if (mDropdown != null)
			mDropdown.AddItem(text);
		RequestLayout(); // as wide as its widest item
	}

	public int ItemCount => mItems.Count;

	/// The items as one text, '|' between them (markup's and a sheet's `items`).
	[GuiProperty("items")]
	public StringView ItemsText
	{
		get
		{
			mItemsText.Clear();
			JoinItems(mItems, mItemsText);
			return mItemsText;
		}
		set
		{
			let text = scope String(value); // the items are views into it
			ClearAndDeleteItems!(mItems);
			if (mDropdown != null)
				mDropdown.Clear();
			let items = scope List<StringView>();
			SplitItems(text, items);
			for (let item in items)
				AddItem(item);
			// The old selection is gone with its item: none shows.
			if (mSelected != -1)
			{
				mSelected = -1;
				ShowSelection();
				mSelectedChanged.Notify();
				Invalidate();
			}
		}
	}

	/// The selected item's index, or -1 (markup's and a sheet's `selected`; a read a binding
	/// follows). Set, it selects `index`, or none with -1.
	[GuiProperty("selected", .TwoWay)]
	public int32 SelectedIndex
	{
		get
		{
			mSelectedChanged.Track();
			return mSelected;
		}
		set
		{
			if ((value < -1) || (value >= (int32)mItems.Count))
				return;
			if (value == mSelected)
				return;
			mSelected = value;
			ShowSelection();
			Invalidate();
			mSelectedChanged.Notify();
			if (mOnChanged != null)
				mOnChanged(value);
		}
	}

	public StringView SelectedText => ((mSelected >= 0) && (mSelected < (int32)mItems.Count)) ? (StringView)mItems[mSelected] : default;

	/// The user picked `index` (the keys, type-ahead, the dropdown): as SelectedIndex's setter,
	/// and a `change` event when it changed, as a slider's or a field's.
	public void SelectByUser(int32 index)
	{
		let was = mSelected;
		SelectedIndex = index;
		if (mSelected != was)
			SendEvent(scope Event(.Changed, this));
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnSelectionChanged(delegate void(int32 index) callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	public bool IsOpen
	{
		get
		{
			let dispatcher = (mDropdown != null) ? mDropdown.EventDispatcher : null;
			return (dispatcher != null) && dispatcher.IsPopupOpen(mDropdown);
		}
	}

	/// The dropdown list (built on first open).
	public ListBox Dropdown => mDropdown;

	public void SetItemHeight(float height)
	{
		mItemHeight = height;
	}

	/// What shows while nothing is selected (`placeholder`).
	[GuiProperty("placeholder", .Translatable)]
	public StringView Placeholder
	{
		get => mPlaceholder;
		set
		{
			mPlaceholder.Set(value);
			ShowSelection();
		}
	}

	public Color PlaceholderColor
	{
		get => mPlaceholderColor;
		set
		{
			mPlaceholderColor = value;
			ShowSelection();
		}
	}

	/// Its widest item and the arrow beside it, one line of its font tall.
	public override Float2 MeasureContent(Float2 available)
	{
		float widest = 0.0f;
		let font = Font;
		if (font != null)
		{
			for (let item in mItems)
				widest = Math.Max(widest, font.Font.MeasureString(item));
		}
		return .(widest + 24.0f, (font != null) ? font.Font.Metrics.LineHeight : 20.0f);
	}

	/// The selection's baseline, where it draws it.
	public override float BaselineAt(Float2 size)
	{
		let c = Chrome;
		return mText.FirstBaseline(.(c.Left, c.Top, Math.Max(0.0f, size.X - c.TotalHorizontal - 16.0f), Math.Max(0.0f, size.Y - c.TotalVertical)));
	}

	// Its selection draws in its text style; the arrow is the text's colour; the dropdown takes
	// its font.
	protected override void OnTextStyleChange()
	{
		let style = GetTextStyle();
		mText.Font = Font;
		mText.SetFontSelection(FontService, style.FontFamily, style.Selection);
		mText.Direction = TextDirectionFor();
		ShowSelection();
		mArrowColor = TextColor;
		if (mDropdown != null)
			ShareTextStyle(mDropdown, false);
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		e.Handled = true;
		if (IsOpen)
			CloseDropdown();
		else
			OpenDropdown();
	}

	protected override bool OnActivate()
	{
		OpenDropdown();
		return IsOpen;
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if ((e.Target != this) || mItems.IsEmpty)
			return;
		let key = (KeyCode)e.KeyCode;
		if ((key == .Down) && (e.Modifiers == KeyModAlt))
		{
			e.Handled = true;
			OpenDropdown();
			return;
		}
		if (e.Modifiers != 0)
			return;
		let last = (int32)mItems.Count - 1;
		if ((key == .Down) && (mSelected < last))
		{
			SelectByUser(mSelected + 1);
			e.Handled = true;
		}
		else if ((key == .Up) && (mSelected > 0))
		{
			SelectByUser(mSelected - 1);
			e.Handled = true;
		}
		else if (KeyTypesText(key))
			e.Handled = true; // its text arrives next, for type-ahead
	}

	// Typed text (through the keyboard layout and an IME): the next item after the selection
	// starting with its first character, round the end.
	public override bool WantsTextInput => IsTreeEnabled && !mItems.IsEmpty;

	protected override void OnTextInput(TextInputEvent e)
	{
		if ((e.Target != this) || mItems.IsEmpty || (e.Text.Length == 0))
			return;
		int end = 0;
		DecodeCodepoint(e.Text, ref end);
		let typed = e.Text.Substring(0, end);
		e.Handled = true;
		let count = (int32)mItems.Count;
		for (int32 n = 1; n <= count; ++n)
		{
			let i = (mSelected + n + count) % count;
			if (StartsWithIgnoringCase(mItems[i], typed))
			{
				SelectByUser(i);
				break;
			}
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		// A visible box so it reads as a control even unstyled; a sheet's fill (a theme's) replaces it.
		if (!BoxFills)
			ctx.VG.FillRect(.(localBounds.X, localBounds.Y, localBounds.Width, localBounds.Height), mBoxColor);
		let b = ContentBounds;
		let rtl = IsRightToLeft; // the arrow at the inline end
		// Selection text (leaving room for the arrow).
		mText.Draw(ctx, Rect.MirroredIn(.(b.X, b.Y, Math.Max(0.0f, b.Width - 16.0f), b.Height), b, rtl));
		// A small down-arrow.
		let aw = 8.0f;
		let ah = 5.0f;
		let ax = Rect.MirroredIn(.(b.X + b.Width - aw - 4.0f, 0.0f, aw, 0.0f), b, rtl).X;
		let ay = b.Y + (b.Height - ah) * 0.5f;
		let pb = scope PathBuilder();
		pb.MoveTo(ax, ay);
		pb.LineTo(ax + aw, ay);
		pb.LineTo(ax + aw * 0.5f, ay + ah);
		pb.Close();
		let path = pb.ToPath();
		ctx.VG.FillPath(path, mArrowColor);
		delete path;
	}

	// The selected item in the text's colour, or the placeholder in its own.
	private void ShowSelection()
	{
		let none = (mSelected < 0) || (mSelected >= (int32)mItems.Count);
		mText.SetString(none ? (StringView)mPlaceholder : (StringView)mItems[mSelected]);
		mText.Color = none ? mPlaceholderColor : TextColor;
		Invalidate();
	}

	private void BuildDropdown()
	{
		if (mDropdown != null)
			return;
		mDropdown = new ListBox();
		ShareTextStyle(mDropdown, false);
		mDropdown.ItemHeight = mItemHeight;
		for (let item in mItems)
			mDropdown.AddItem(item);
		mDropdown.SetOnItemActivated(new (index) => { OnPicked(index); });
	}

	private void OpenDropdown()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher == null) || mItems.IsEmpty)
			return;
		BuildDropdown();
		let h = Math.Min((float)mItems.Count * mItemHeight, mDropdownMaxHeight);
		mDropdown.Size = .(Size.X, h);
		if (mSelected >= 0)
			mDropdown.SelectedIndex = mSelected; // the current item lit, in view
		let options = new PopupOptions();
		options.Anchor = this;
		options.Placement.Side = .Below;
		options.TakesFocus = true; // the list: the arrows move, Return picks; focus back on close
		dispatcher.OpenPopup(this, mDropdown, options);
	}

	private void CloseDropdown()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher != null) && (mDropdown != null))
			dispatcher.ClosePopup(mDropdown);
	}

	private void OnPicked(int32 index)
	{
		SelectByUser(index);
		CloseDropdown();
	}
}
