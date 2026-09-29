using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The Console panel content: a filter and action toolbar (per-bucket check boxes plus
/// Clear) over a recycled ListView of level-coloured rows, a bounded entry count, and
/// auto-scroll to the newest entry. Fed once per frame by EditorApplication draining the
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
	private Adapter mAdapter ~ delete _;
	private ListView mList;
	/// Borrowed; the toolbar owns them.
	private CheckBox[LogBucket.Count] mFilterBoxes;

	public this()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;

		// The toolbar: level filters plus Clear.
		let toolbar = new FlexLayout();
		toolbar.Direction = .Horizontal;
		toolbar.Spacing = 8.0f;
		toolbar.Padding = .(4, 4);
		StringView[LogBucket.Count] names = .("Debug", "Info", "Warning", "Error");
		for (int i < LogBucket.Count)
		{
			let check = new CheckBox(names[i], true);
			let bucket = (LogBucket)i;
			check.OnCheckedChanged.Add(new [=bucket, =this](b, on) => { SetBucketVisible(bucket, on); });
			mFilterBoxes[i] = check;
			toolbar.AddView(check);
		}
		let clear = new Button("Clear");
		clear.OnClick.Add(new (b) => { Clear(); });
		toolbar.AddView(clear);
		column.AddView(toolbar);

		// The entry list, recycled rows.
		mAdapter = new Adapter(this);
		mList = new EntryList(this);
		mList.ItemHeight.Value = 20.0f;
		mList.Selection.Mode = .Multiple;
		mList.SetAdapter(mAdapter);
		mList.OnItemRightClicked.Add(new [=this](position, x, y) => { ShowContextMenu(x, y); });
		mList.OnBackgroundRightClicked.Add(new [=this](x, y) => { ShowContextMenu(x, y); });
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		column.AddView(mList, grow);

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
		mEntries.Add(entry);

		// Trimming shifts the indices into mEntries, so the filter is rebuilt below, and the
		// selection moves up by the visible rows that went (a trimmed selected row is gone).
		bool trimmed = false;
		int32 trimmedVisible = 0;
		while (mEntries.Count > MaxEntries)
		{
			if (IsBucketVisible(mEntries[0].Bucket))
				trimmedVisible++;
			delete mEntries[0].Text;
			mEntries.RemoveAt(0);
			trimmed = true;
		}

		if (trimmed)
		{
			mList.Selection.ShiftIndices(0, -trimmedVisible);
			RebuildFilter();
		}
		else if (IsBucketVisible(mEntries.Back.Bucket))
		{
			mFiltered.Add(mEntries.Count - 1);
			mAdapter.NotifyDataSetChanged();
		}
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
	}

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
		if (let check = mFilterBoxes[(int)bucket])
			check.IsChecked.SetSilent(visible); // the toolbar follows programmatic calls
		RebuildFilter();
		ScrollToNewest();
	}

	public bool IsBucketVisible(LogBucket bucket) => mVisible[(int)bucket];
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

	private void RebuildFilter()
	{
		mFiltered.Clear();
		for (int i < mEntries.Count)
		{
			if (IsBucketVisible(mEntries[i].Bucket))
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
