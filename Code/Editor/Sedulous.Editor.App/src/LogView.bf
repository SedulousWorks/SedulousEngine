namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Scrollable log view with level-based color coding and auto-scroll.
/// Uses ListView with adapter for view recycling.
class LogView : ViewGroup
{
	/// Log severity level.
	public enum LogLevel
	{
		Debug,
		Info,
		Warning,
		Error
	}

	public struct LogEntry
	{
		public String Message;
		public LogLevel Level;
	}

	private List<LogEntry> mEntries = new .() ~ { for (var e in _) delete e.Message; delete _; };
	private List<int32> mFilteredIndices = new .() ~ delete _;
	private int32 mMaxEntries = 1000;
	private bool mAutoScroll = true;
	private float mFontSize = 12;
	private float mItemHeight = 20;
	private bool mShowDebug = true;
	private bool mShowInfo = true;
	private bool mShowWarning = true;
	private bool mShowError = true;

	private ListView mListView;
	private LogAdapter mAdapter;

	public bool AutoScroll { get => mAutoScroll; set => mAutoScroll = value; }
	public int EntryCount => mEntries.Count;
	public int VisibleEntryCount => mFilteredIndices.Count;

	public this()
	{
		mAdapter = new LogAdapter(this);
		mListView = new ListView();
		mListView.ItemHeight.Value = mItemHeight;
		mListView.Adapter = mAdapter;
		AddView(mListView);
	}

	public ~this()
	{
		mListView.Adapter = null;
		delete mAdapter;
	}

	/// Add a log entry.
	public void AddEntry(LogLevel level, StringView message)
	{
		LogEntry entry;
		entry.Message = new String(message);
		entry.Level = level;
		mEntries.Add(entry);

		TrimEntries();

		if (PassesFilter(level))
		{
			mFilteredIndices.Add((int32)(mEntries.Count - 1));
			mAdapter.NotifyDataSetChanged();

			if (mAutoScroll && mFilteredIndices.Count > 0)
				mListView.ScrollToPosition((int32)(mFilteredIndices.Count - 1));
		}
	}

	/// Clear all entries.
	public void Clear()
	{
		for (var e in mEntries)
			delete e.Message;
		mEntries.Clear();
		mFilteredIndices.Clear();
		mAdapter.NotifyDataSetChanged();
	}

	public LogEntry GetFilteredEntry(int32 filteredIndex)
	{
		if (filteredIndex >= 0 && filteredIndex < mFilteredIndices.Count)
		{
			let actualIndex = mFilteredIndices[filteredIndex];
			if (actualIndex >= 0 && actualIndex < mEntries.Count)
				return mEntries[actualIndex];
		}
		return .() { Message = null, Level = .Info };
	}

	public Color32 GetLevelColor(LogLevel level)
	{
		switch (level)
		{
		case .Debug:   return .(150, 150, 150, 255);
		case .Info:    return .(80, 180, 255, 255);
		case .Warning: return .(255, 200, 50, 255);
		case .Error:   return .(255, 80, 80, 255);
		}
	}

	private bool PassesFilter(LogLevel level)
	{
		switch (level)
		{
		case .Debug:   return mShowDebug;
		case .Info:    return mShowInfo;
		case .Warning: return mShowWarning;
		case .Error:   return mShowError;
		}
	}

	private void RebuildFilteredList()
	{
		mFilteredIndices.Clear();
		for (int32 i = 0; i < mEntries.Count; i++)
		{
			if (PassesFilter(mEntries[i].Level))
				mFilteredIndices.Add(i);
		}
		mAdapter.NotifyDataSetChanged();
	}

	private void TrimEntries()
	{
		if (mEntries.Count <= mMaxEntries) return;

		let removeCount = mEntries.Count - mMaxEntries;
		for (int i = 0; i < removeCount; i++)
			delete mEntries[i].Message;
		mEntries.RemoveRange(0, removeCount);
		RebuildFilteredList();
	}

	// === Layout ===

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let w = constraints.ConstrainWidth(200);
		let h = constraints.ConstrainHeight(100);
		mListView.Measure(BoxConstraints.Tight(w, h));
		MeasuredSize = .(w, h);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mListView.Layout(0, 0, width, height);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bg = ResolveStyleColor(.Background, .(25, 27, 35, 255));
		ctx.VG.FillRect(.(0, 0, Width, Height), bg);
		DrawChildren(ctx);
	}

	/// Simple colored rectangle view for the log level indicator strip.
	private class ColorStrip : View
	{
		public Color32 StripColor;

		public override void OnDraw(UIDrawContext ctx)
		{
			ctx.VG.FillRect(.(0, 0, Width, Height), StripColor);
		}

		protected override void OnMeasure(BoxConstraints constraints)
		{
			MeasuredSize = .(constraints.ConstrainWidth(4), constraints.ConstrainHeight(20));
		}
	}

	/// Adapter for the LogView's ListView.
	private class LogAdapter : ListAdapterBase
	{
		private LogView mOwner;

		public this(LogView owner) { mOwner = owner; }

		public override int32 ItemCount => (int32)mOwner.mFilteredIndices.Count;

		public override View CreateView(int32 viewType)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 4;

			// Color indicator strip
			row.AddView(new ColorStrip(), new FlexLayout.LayoutParams() {
				Width = .Fixed(.Px(4)), Height = .Match
			});

			// Message text
			let label = new Label();
			label.FontSize.Value = mOwner.mFontSize;
			label.VAlign.Value = .Middle;
			row.AddView(label, new FlexLayout.LayoutParams() {
				Height = .Match, Grow = 1
			});

			return row;
		}

		public override void BindView(View view, int32 position)
		{
			if (let row = view as FlexLayout)
			{
				let entry = mOwner.GetFilteredEntry(position);
				let color = mOwner.GetLevelColor(entry.Level);

				if (row.ChildCount >= 2)
				{
					if (let indicator = row.GetChildAt(0) as ColorStrip)
						indicator.StripColor = color;

					if (let label = row.GetChildAt(1) as Label)
					{
						if (entry.Message != null)
							label.SetText(entry.Message);
						else
							label.SetText("");
					}
				}
			}
		}
	}
}
