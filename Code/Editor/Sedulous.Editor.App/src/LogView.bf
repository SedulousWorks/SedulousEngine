using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The Console panel content: a header row (a chip per level with its colour, its name and how
/// many lines it holds, on showing them; a search field matching anywhere in a line ignoring
/// case, which an x clears; a Clear icon) over a recycled ListView of level-coloured rows, a
/// bounded entry count, and auto-scroll to the newest entry. Fed once per frame by EditorApplication draining the
/// EditorLogBuffer. Rows select like any list (click, Ctrl click, Shift click, Ctrl+A), and
/// Ctrl+C or the context menu's Copy puts the selected rows on the clipboard, one per line.
class LogView : ViewGroup
{
	private struct Entry
	{
		public LogBucket Bucket = .Info;
		public String Text = null;
	}

	/// A recycled row is one Label; bind sets the text and the level colour.
	private class Adapter : ListAdapterBase
	{
		private LogView mOwner;

		public this(LogView owner) { mOwner = owner; }

		public override int32 ItemCount => (int32)mOwner.mFiltered.Count;

		public override View CreateView(int32 viewType)
		{
			let label = new Label();
			label.FontSize.Value = 12.0f;
			return label;
		}

		public override void BindView(View view, int32 position)
		{
			let label = view as Label;
			if (label == null)
				return;
			let entry = mOwner.mEntries[mOwner.mFiltered[position]];
			label.SetText(entry.Text);
			label.TextColor.Value = BucketColor(entry.Bucket);
		}
	}

	/// The entry list: Ctrl+C copies the selection and Ctrl+A selects every row, with or
	/// without a selection to start from.
	private class EntryList : ListView
	{
		private LogView mOwner;

		public this(LogView owner) { mOwner = owner; }

		public override void OnKeyDown(KeyEventArgs e)
		{
			if (e.Modifiers.HasFlag(.Ctrl) && !e.Modifiers.HasFlag(.Alt))
			{
				if (e.Key == .C)
				{
					mOwner.CopySelection();
					e.Handled = true;
					return;
				}
				if (e.Key == .A)
				{
					mOwner.SelectAll();
					e.Handled = true;
					return;
				}
			}
			base.OnKeyDown(e);
		}
	}

	/// Says a copy happened (the app's toast): the number of lines copied. Owned.
	public delegate void(int lines) OnCopied ~ delete _;

	/// True while the newest entry is kept in view.
	public bool AutoScroll = true;
	/// The cap on retained entries; the oldest are trimmed.
	public int MaxEntries = 1000;

	private List<Entry> mEntries = new .() ~ { for (var e in _) delete e.Text; delete _; };
	/// Indices into mEntries passing the filter.
	private List<int> mFiltered = new .() ~ delete _;
	private bool[LogBucket.Count] mVisible = .(true, true, true, true);
	/// What a line must contain to show; empty shows every line.
	private String mSearch = new .() ~ delete _;
	/// Borrowed; the toolbar owns it.
	private EditText mSearchEdit;
	private Adapter mAdapter ~ delete _;
	private ListView mList;
	/// Borrowed; the header owns them.
	private ToggleButton[LogBucket.Count] mChips;
	/// Borrowed; each chip owns its own.
	private Label[LogBucket.Count] mCountLabels;
	private Label[LogBucket.Count] mNameLabels;
	/// The lines each level holds now.
	private int[LogBucket.Count] mCounts;
	/// Borrowed; the header owns it.
	private IconButton mClearSearch;

	public this()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;

		// The header row: [level chips] ........ [search: icon, field, x] [clear].
		let toolbar = new FlexLayout();
		toolbar.Direction = .Horizontal;
		toolbar.Spacing = 4.0f;
		toolbar.Padding = .(6, 3);
		toolbar.AlignItems = .Center;
		var center = LayoutStyle();
		center.AlignSelf = .Center;
		for (int i < LogBucket.Count)
			toolbar.AddView(MakeLevelChip((LogBucket)i), center);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		toolbar.AddView(new View(), grow); // the gap
		// The shared icons are null before they are initialised (tests): a reference is taken
		// for the view that holds one.
		let searchIcon = EditorIcons.Search;
		if (searchIcon != null)
			searchIcon.AddRef();
		let magnifier = new DrawableView(searchIcon, 14.0f, 14.0f);
		magnifier.KeepAspect = true;
		toolbar.AddView(magnifier, center);
		mSearchEdit = new EditText();
		mSearchEdit.SetPlaceholder("Filter lines");
		mSearchEdit.TooltipText.Set("Show only the lines containing this (any case)");
		mSearchEdit.OnTextChanged.Add(new [=this](edit) => { SetSearch(edit.Text); });
		{
			// It grows with the panel up to a comfortable width and gives way in a narrow one,
			// so the header never runs past the panel's edge.
			var field = LayoutStyle();
			field.FlexGrow = 1.0f;
			field.MinWidth = Unit.Dp(80.0f);
			field.MaxWidth = Unit.Dp(260.0f);
			field.AlignSelf = .Center;
			toolbar.AddView(mSearchEdit, field);
		}
		mClearSearch = new IconButton(EditorIcons.Close, 10.0f);
		mClearSearch.TooltipText.Set("Clear the filter");
		mClearSearch.Visibility = .Hidden; // keeps its place: no jump
		mClearSearch.OnClick.Add(new [=this](b) =>
			{
				mSearchEdit.SetText("");
				SetSearch("");
			});
		toolbar.AddView(mClearSearch, center);
		let clear = new IconButton(EditorIcons.Remove, 16.0f);
		clear.TooltipText.Set("Clear the console");
		clear.OnClick.Add(new [=this](b) => { Clear(); });
		toolbar.AddView(clear, center);
		{
			var row = LayoutStyle();
			row.Width = SizeSpec.Match();
			row.Height = SizeSpec.Fixed(Unit.Dp(28.0f));
			column.AddView(toolbar, row);
		}
		{
			// A hairline under the header (the theme's separator), so it reads as chrome.
			var line = LayoutStyle();
			line.Width = SizeSpec.Match();
			column.AddView(new Separator(), line);
		}
		UpdateCounts();

		// The entry list, recycled rows.
		mAdapter = new Adapter(this);
		mList = new EntryList(this);
		mList.ItemHeight.Value = 20.0f;
		mList.Padding = .(8, 4); // the lines off the panel's edges and the header
		mList.Selection.Mode = .Multiple;
		mList.SetAdapter(mAdapter);
		mList.OnItemRightClicked.Add(new [=this](position, x, y) => { ShowContextMenu(x, y); });
		mList.OnBackgroundRightClicked.Add(new [=this](x, y) => { ShowContextMenu(x, y); });
		var fill = LayoutStyle();
		fill.FlexGrow = 1.0f;
		column.AddView(mList, fill);

		AddView(column);
	}

	public ~this()
	{
		mList.SetAdapter(null);
	}

	public void AddEntry(LogLevel level, StringView category, StringView message)
	{
		var entry = Entry();
		entry.Bucket = LogBucket.Of(level);
		entry.Text = new String();
		entry.Text.Append("[");
		entry.Text.Append(category);
		entry.Text.Append("] ");
		entry.Text.Append(message);
		mCounts[(int)entry.Bucket]++;
		mEntries.Add(entry);

		// Trimming shifts the indices into mEntries, so the filter is rebuilt below, and the
		// selection moves up by the visible rows that went (a trimmed selected row is gone).
		bool trimmed = false;
		int32 trimmedVisible = 0;
		while (mEntries.Count > MaxEntries)
		{
			if (Shows(mEntries[0]))
				trimmedVisible++;
			mCounts[(int)mEntries[0].Bucket]--;
			delete mEntries[0].Text;
			mEntries.RemoveAt(0);
			trimmed = true;
		}

		if (trimmed)
		{
			mList.Selection.ShiftIndices(0, -trimmedVisible);
			RebuildFilter();
		}
		else if (Shows(mEntries.Back))
		{
			mFiltered.Add(mEntries.Count - 1);
			mAdapter.NotifyDataSetChanged();
		}
		UpdateCounts();
		ScrollToNewest();
	}

	public void Clear()
	{
		for (var e in mEntries)
			delete e.Text;
		mEntries.Clear();
		mFiltered.Clear();
		mList.Selection.ClearSelection();
		mAdapter.NotifyDataSetChanged();
		for (var count in ref mCounts)
			count = 0;
		UpdateCounts();
	}

	/// A level's chip in the header (on shows its lines), and the count it shows.
	public ToggleButton LevelChip(LogBucket bucket) => mChips[(int)bucket];
	public int LevelCount(LogBucket bucket) => mCounts[(int)bucket];
	public StringView LevelCountText(LogBucket bucket) =>
		(mCountLabels[(int)bucket] != null) ? mCountLabels[(int)bucket].Text.Value : default;
	/// The search field's clear button, shown only while the field holds text.
	public IconButton ClearSearchButton => mClearSearch;

	/// Selects every visible row.
	public void SelectAll()
	{
		if (!mFiltered.IsEmpty)
			mList.Selection.SelectRange(0, (int32)mFiltered.Count - 1);
	}

	public int SelectedCount => mList.Selection.SelectedCount;
	/// The entry list: the selection, and the keys it takes (the tests drive both).
	public ListView List => mList;

	/// The selected rows' text, oldest first, one per line.
	public void SelectedText(String outText)
	{
		let positions = scope List<int32>();
		for (let position in mList.Selection.SelectedPositions)
		{
			if (position < mFiltered.Count)
				positions.Add(position);
		}
		positions.Sort();
		for (let position in positions)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			outText.Append(mEntries[mFiltered[position]].Text);
		}
	}

	/// Puts the selected rows on the system clipboard; nothing selected copies nothing.
	public void CopySelection()
	{
		let text = SelectedText(.. scope .());
		if (text.IsEmpty || (Context == null) || (Context.Clipboard == null))
			return;
		if ((Context.Clipboard.SetText(text) case .Ok) && (OnCopied != null))
			OnCopied(SelectedCount);
	}

	private void ShowContextMenu(float localX, float localY)
	{
		if (Context == null)
			return;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();
		let count = SelectedCount;
		menu.AddItem((count > 1) ? scope $"Copy {count} Lines" : "Copy", new [=this]() => { CopySelection(); }, count > 0);
		menu.AddItem("Select All", new [=this]() => { SelectAll(); }, !mFiltered.IsEmpty);
		menu.AddSeparator();
		menu.AddItem("Clear", new [=this]() => { Clear(); });
		let at = mList.LocalToScreen(.(localX, localY));
		menu.Show(Context, at.X, at.Y);
	}

	public void SetBucketVisible(LogBucket bucket, bool visible)
	{
		mVisible[(int)bucket] = visible;
		// A filter change re-numbers the rows, so the selection goes.
		mList.Selection.ClearSelection();
		if (let chip = mChips[(int)bucket])
		{
			chip.IsChecked.SetSilent(visible); // the header follows programmatic calls
			chip.Invalidate();
		}
		UpdateCounts(); // an off level's chip dims
		RebuildFilter();
		ScrollToNewest();
	}

	public bool IsBucketVisible(LogBucket bucket) => mVisible[(int)bucket];

	/// Shows only the lines containing `text`, ignoring case; empty shows them all. The search
	/// box calls it as the user types.
	public void SetSearch(StringView text)
	{
		if (mSearch == text)
			return;
		mSearch.Set(text);
		if (mClearSearch != null)
			mClearSearch.Visibility = mSearch.IsEmpty ? .Hidden : .Visible;
		// The rows re-number, so the selection goes.
		mList.Selection.ClearSelection();
		RebuildFilter();
		ScrollToNewest();
	}

	public StringView Search => mSearch;

	/// Whether a line passes the level filters and the search.
	private bool Shows(Entry entry) =>
		IsBucketVisible(entry.Bucket) && (mSearch.IsEmpty || entry.Text.Contains(mSearch, true));
	public int EntryCount => mEntries.Count;
	public int VisibleEntryCount => mFiltered.Count;
	public StringView VisibleEntryText(int visibleIndex) => mEntries[mFiltered[visibleIndex]].Text;

	/// Fills the available space: the default ViewGroup measure wraps to children, which
	/// would collapse the virtualised list. The single child column fills us.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		for (int i < ChildCount)
			GetChildAt(i).Measure(constraints);
		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
			GetChildAt(i).Layout(0, 0, width, height);
	}

	private static Color BucketColor(LogBucket bucket)
	{
		switch (bucket)
		{
		case .Debug: return .(150.0f / 255.0f, 150.0f / 255.0f, 150.0f / 255.0f, 1.0f);
		case .Info: return .(80.0f / 255.0f, 180.0f / 255.0f, 255.0f / 255.0f, 1.0f);
		case .Warning: return .(255.0f / 255.0f, 200.0f / 255.0f, 50.0f / 255.0f, 1.0f);
		default: return .(255.0f / 255.0f, 80.0f / 255.0f, 80.0f / 255.0f, 1.0f);
		}
	}

	/// A level's chip: a dot in the level's row colour, its name and its line count; a toggle,
	/// on while its lines show, dimmed off.
	private ToggleButton MakeLevelChip(LogBucket bucket)
	{
		StringView[LogBucket.Count] names = .("Debug", "Info", "Warning", "Error");
		StringView[LogBucket.Count] tips = .("Show debug and trace lines", "Show info lines", "Show warnings", "Show errors");
		let i = (int)bucket;
		let content = new FlexLayout();
		content.Direction = .Horizontal;
		content.Spacing = 5.0f;
		content.AlignItems = .Center;
		content.AddView(new DrawableView(new RoundedRectDrawable(BucketColor(bucket), 4.0f), 8.0f, 8.0f));
		let name = new Label(names[i]);
		name.FontSize.Value = 12.0f;
		content.AddView(name);
		mNameLabels[i] = name;
		let count = new Label("0");
		count.FontSize.Value = 11.0f;
		count.TextColor.Value = Color(0.6f, 0.6f, 0.62f, 1.0f);
		content.AddView(count);
		mCountLabels[i] = count;

		let chip = new ToggleButton();
		chip.SetContent(content);
		chip.SetStyle(.Padding, Thickness(7.0f, 2.0f));
		// A quiet pill rather than the theme's accent toggle: outlined when off, a soft fill
		// when on, a touch lighter under the pointer.
		Drawable Pill(float fill, float border) =>
			new RoundedRectDrawable(Color(1.0f, 1.0f, 1.0f, fill), 9.0f, Color(1.0f, 1.0f, 1.0f, border), 1.0f);
		let look = new StateListDrawable();
		look.Set(.Normal, Pill(0.0f, 0.10f));
		look.Set(.Hover, Pill(0.05f, 0.14f));
		look.Set(.Checked, Pill(0.10f, 0.16f));
		look.Set(.Checked | .Hover, Pill(0.14f, 0.20f));
		// A checked toggle draws its CheckedBackground first (the theme's accent): this pill
		// too. The style takes a reference for each property it is set on.
		look.AddRef();
		chip.SetStyle(.Background, look);
		chip.SetStyle(.CheckedBackground, look);
		chip.TooltipText.Set(tips[i]);
		chip.IsChecked.SetSilent(mVisible[i]);
		chip.OnCheckedChanged.Add(new [=this, =bucket](b, on) => { SetBucketVisible(bucket, on); });
		mChips[i] = chip;
		return chip;
	}

	/// Each chip's count, the lines its level holds now (capped in the text, not the count),
	/// quieter for an empty or hidden level, and its name dimmed when the level is hidden.
	private void UpdateCounts()
	{
		for (int i < LogBucket.Count)
		{
			if (let label = mCountLabels[i])
			{
				let text = (mCounts[i] > 9999) ? scope String("9999+") : scope $"{mCounts[i]}";
				if (label.Text.Value != text)
					label.SetText(text);
				label.TextColor.Value = ((mCounts[i] == 0) || !mVisible[i]) ? Color(0.45f, 0.45f, 0.47f, 1.0f) : Color(0.72f, 0.72f, 0.74f, 1.0f);
			}
			if (let name = mNameLabels[i])
				name.TextColor.Value = mVisible[i] ? Color(0.9f, 0.9f, 0.92f, 1.0f) : Color(0.5f, 0.5f, 0.52f, 1.0f);
		}
	}

	private void RebuildFilter()
	{
		mFiltered.Clear();
		for (int i < mEntries.Count)
		{
			if (Shows(mEntries[i]))
				mFiltered.Add(i);
		}
		mAdapter.NotifyDataSetChanged();
	}

	private void ScrollToNewest()
	{
		if (AutoScroll && !mFiltered.IsEmpty)
			mList.ScrollToPosition((int32)mFiltered.Count - 1);
	}
}
