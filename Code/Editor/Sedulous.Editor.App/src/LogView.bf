using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The Console panel content: a filter and action toolbar (per-bucket check boxes plus
/// Clear) over a recycled ListView of level-coloured rows, a bounded entry count, and
/// auto-scroll to the newest entry. Fed once per frame by EditorApplication draining the
/// EditorLogBuffer.
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
		mList = new ListView();
		mList.ItemHeight.Value = 20.0f;
		mList.SetAdapter(mAdapter);
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

		// Trimming shifts the indices into mEntries, so the filter is rebuilt below.
		bool trimmed = false;
		while (mEntries.Count > MaxEntries)
		{
			delete mEntries[0].Text;
			mEntries.RemoveAt(0);
			trimmed = true;
		}

		if (trimmed)
		{
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
		mAdapter.NotifyDataSetChanged();
	}

	public void SetBucketVisible(LogBucket bucket, bool visible)
	{
		mVisible[(int)bucket] = visible;
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
