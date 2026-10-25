using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.GUI;

// ListBox: a scrollable, single-selection list of text items. Modeled on eepp's UIListBox (role
// only). Built by composition on the existing pieces: it scrolls itself (`overflow-y: auto`), its
// content one ListBoxItem (a selectable Label) per entry, stacked by index. Clicking a row selects
// it; when focused, Up/Down move the selection and scroll it into view. Scrolling brings the
// scrollbar / wheel / clipping for free. Virtualized item rendering (for very large lists) is a
// follow-up - here every item is a real row widget.

static
{
	/// A list's items written as one text, '|' between them (markup's `items="Apple|Banana"`), each
	/// trimmed, appended to `outItems` (views into `text`); empty text, no items.
	public static void SplitItems(StringView text, List<StringView> outItems)
	{
		int start = 0;
		for (int i = 0; i <= text.Length; ++i)
		{
			if ((i == text.Length) || (text[i] == '|'))
			{
				let item = ParseUtil.Trim(text.Substring(start, i - start));
				if ((item.Length != 0) || (i < text.Length))
					outItems.Add(item);
				start = i + 1;
			}
		}
	}

	/// `items` as one text, '|' between them, appended to `outText`.
	public static void JoinItems(Span<String> items, String outText)
	{
		for (int i = 0; i < items.Length; ++i)
		{
			if (i > 0)
				outText.Append('|');
			outText.Append(items[i]);
		}
	}
}

// One selectable row. Internal to the ListBox; a Label tagged "listboxitem", so a sheet can style
// its rows (`listboxitem:hover`) apart from the labels around the list.
class ListBoxItem : Label
{
	private int32 mIndex = -1;
	private bool mSelected = false;
	private Color mHighlight = .(0.24f, 0.40f, 0.62f, 1.0f);
	private PartStyle mSelectionStyle = new .() ~ delete _;
	private delegate void(int32 index) mOnPicked ~ delete _;

	public this()
	{
		Tag = "listboxitem";
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			SetTextAlignment(.Start, .Middle);
		}
	}

	public int32 Index
	{
		get => mIndex;
		set => mIndex = value;
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnPicked(delegate void(int32 index) callback)
	{
		delete mOnPicked;
		mOnPicked = callback;
	}

	public bool SelectedRow
	{
		get => mSelected;
		set
		{
			if (value == mSelected)
				return;
			mSelected = value;
			Invalidate();
		}
	}

	public Color HighlightColor
	{
		get => mHighlight;
		set
		{
			mHighlight = value;
			Invalidate();
		}
	}

	/// The list's listbox::selection style, which a selected row draws under its text (a copy is
	/// taken).
	public void SetSelectionStyle(PartStyle style)
	{
		mSelectionStyle.Set(style);
		Invalidate();
	}

	protected override void OnMouseClick(MouseEvent e)
	{
		e.Handled = true;
		if (mOnPicked != null)
			mOnPicked(mIndex);
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (mSelected)
			mSelectionStyle.Draw(ctx, LocalBounds, FilledBox(mHighlight, scope NodeBox()));
		base.OnDraw(ctx, localBounds);
	}
}

[GuiReflect(true), Scriptable]
class ListBox : UIWidget
{
	// Non-owning (its children).
	private List<ListBoxItem> mItems = new .() ~ delete _;
	private float mItemHeight = 24.0f;
	private int32 mSelected = -1;
	private Color mPanelColor = .(0.13f, 0.14f, 0.17f, 1.0f);
	private Color mHighlightColor = .(0.24f, 0.40f, 0.62f, 1.0f);
	private delegate void(int32 index) mOnChanged ~ delete _;
	private delegate void(int32 index) mOnActivated ~ delete _;
	// What ItemsText last wrote.
	private String mItemsText = new .() ~ delete _;

	public this()
	{
		Tag = "listbox";
		AccessRoleName = "list"; // what a screen reader takes it for
		TabFocusable = true;
		// Its rows stacked in a column, as wide as the list, scrolling when they overflow it.
		using (StyleWriteScope(this)) // its own values, which a sheet returns to
		{
			EditLayoutStyle(scope (s) => { s.OverflowY = .Auto; });
			TextColor = .(0.88f, 0.90f, 0.94f, 1.0f);
		}
	}

	public float ItemHeight
	{
		get => mItemHeight;
		set
		{
			mItemHeight = Math.Max(1.0f, value);
			for (let item in mItems)
				item.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(mItemHeight); });
		}
	}

	public void AddItem(StringView text)
	{
		let item = new ListBoxItem();
		item.Text = text;
		ShareTextStyle(item);
		item.HighlightColor = mHighlightColor;
		item.SetSelectionStyle(GetPartStyle("selection"));
		using (StyleWriteScope(item)) // its own values, which a sheet returns to
		{
			item.Padding = .(8.0f, 0.0f, 8.0f, 0.0f);
			item.Index = (int32)mItems.Count;
			item.SetOnPicked(new (index) =>
				{
					SelectedIndex = index;
					if (mOnActivated != null)
						mOnActivated(index);
				});
			item.EditLayoutStyle(scope (s) => { s.Height = LayoutLength.Px(mItemHeight); });
			AddChild(item);
			mItems.Add(item);
		}
		item.ReleaseRef(); // the tree's reference keeps it
	}

	public void Clear()
	{
		RemoveAllChildren();
		mItems.Clear();
		mSelected = -1;
	}

	public int ItemCount => mItems.Count;

	/// The items as one text, '|' between them (markup's and a sheet's `items`).
	[GuiProperty("items"), Scriptable]
	public StringView ItemsText
	{
		get
		{
			mItemsText.Clear();
			for (int i = 0; i < mItems.Count; ++i)
			{
				if (i > 0)
					mItemsText.Append('|');
				mItemsText.Append(mItems[i].Text);
			}
			return mItemsText;
		}
		set
		{
			let text = scope String(value); // the items are views into it
			Clear();
			let items = scope List<StringView>();
			SplitItems(text, items);
			for (let item in items)
				AddItem(item);
		}
	}

	public StringView GetItem(int index) => (index < mItems.Count) ? mItems[index].Text : default;

	public int32 SelectedIndex
	{
		get => mSelected;
		set
		{
			if ((value < -1) || (value >= (int32)mItems.Count))
				return;
			if (value == mSelected)
				return;
			if (mSelected >= 0)
				mItems[mSelected].SelectedRow = false;
			mSelected = value;
			if (mSelected >= 0)
			{
				mItems[mSelected].SelectedRow = true;
				ScrollToItem(mSelected);
			}
			if (mOnChanged != null)
				mOnChanged(mSelected);
		}
	}

	/// OWNERSHIP of `callback` transfers.
	public void SetOnSelectionChanged(delegate void(int32 index) callback)
	{
		delete mOnChanged;
		mOnChanged = callback;
	}

	/// An item chosen, not just selected: clicked, or Return, Space or a pad's South on the list.
	/// OWNERSHIP of `callback` transfers.
	public void SetOnItemActivated(delegate void(int32 index) callback)
	{
		delete mOnActivated;
		mOnActivated = callback;
	}

	// Theming: listbox::selection = the row-selection highlight (its text style reaches the rows).
	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("selection");
	}

	// Opaque so the list (and a dropdown built on it) paints over whatever is behind it, unless a
	// sheet gives it a fill of its own (a theme's).
	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (!BoxFills)
			ctx.VG.FillRect(.(localBounds.X, localBounds.Y, localBounds.Width, localBounds.Height), mPanelColor);
		base.OnDraw(ctx, localBounds);
	}

	// Its rows draw the selection in listbox::selection's style.
	protected override void OnPartStyleChange(StringView part)
	{
		if (part == "selection")
		{
			for (let item in mItems)
				item.SetSelectionStyle(GetPartStyle(part));
		}
	}

	// Its items show its font and colour (a sheet's inheritance gives them the same).
	protected override void OnTextStyleChange()
	{
		for (let item in mItems)
			ShareTextStyle(item);
	}

	protected override bool OnActivate()
	{
		if ((mSelected < 0) || (mOnActivated == null))
			return false;
		mOnActivated(mSelected);
		return true;
	}

	protected override void OnKeyDown(KeyEvent e)
	{
		if (e.Target != this)
			return;
		switch ((KeyCode)e.KeyCode)
		{
		// An arrow at the list's end is given back (focus moves on).
		case .Down:
			if (!mItems.IsEmpty && (mSelected < (int32)mItems.Count - 1))
			{
				SelectedIndex = mSelected + 1;
				e.Handled = true;
			}
		case .Up:
			if (!mItems.IsEmpty && (mSelected > 0))
			{
				SelectedIndex = mSelected - 1;
				e.Handled = true;
			}
		case .Home:
			if (!mItems.IsEmpty)
				SelectedIndex = 0;
			e.Handled = true;
		case .End:
			if (!mItems.IsEmpty)
				SelectedIndex = (int32)mItems.Count - 1;
			e.Handled = true;
		default:
			break;
		}
	}

	// Scrolls by the least that shows row `index` (from its index: the rows may not be laid out yet).
	private void ScrollToItem(int32 index)
	{
		let top = (float)index * mItemHeight;
		let bottom = top + mItemHeight;
		let viewH = ContentBounds.Height;
		let off = ScrollOffset;
		if (top < off.Y)
			ScrollOffset = .(off.X, top);
		else if (bottom > off.Y + viewH)
			ScrollOffset = .(off.X, bottom - viewH);
	}
}
