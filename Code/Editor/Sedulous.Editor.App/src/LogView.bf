using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// The Console panel (Raptor's editor-gui spec, 5.2, layer 1). Its frame is markup
/// (Data/Editor/Console.gml): a chip per level (Info, holding the debug and trace lines too,
/// Warnings, Errors) with how many lines it holds, on showing them; a search matching anywhere in
/// a line ignoring case, cleared by its x; Clear; then the lines on a virtualised list, each its
/// time since the editor started and `[Category] message` in its level's colour. The newest line
/// is followed until the user scrolls up, and again once they are back at the bottom. Rows select
/// as any list's do (click, Ctrl, Shift, Ctrl+A); Ctrl+C or the menu's Copy puts the selected
/// lines on the clipboard, oldest first, one per line. The entries are capped (the oldest
/// trimmed); a selection is by entry, so it survives a trim. Fed once a frame from the editor's
/// log buffer (EditorApplication.DrainLog).
class LogView
{
	/// Its frame under the data root.
	public const String cMarkupPath = "Editor/Console.gml";
	/// The cap on the lines kept; the oldest are trimmed.
	public const int cMaxEntries = 1000;
	/// This near the bottom counts as at it: a new line is followed.
	private const float cFollowSlack = 4.0f;

	private class Entry
	{
		public LogLevel Level = .Information;
		/// "[Category] message", or the message alone without a category.
		public String Text = new .() ~ delete _;
		public TimeSpan Time;
		/// Its own while lines come and go around it: the list's id for its row.
		public ItemId Id;
	}

	/// The shown lines as the list's model: a row's id its entry's, so a selection follows it.
	private class LineModel : IModel
	{
		private LogView mView;

		public this(LogView view) { mView = view; }

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mView.mShown.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if ((role != .Display) || (index.Row < 0) || (index.Row >= mView.mShown.Count))
				return .();
			return .((StringView)mView.mEntries[mView.mShown[index.Row]].Text);
		}

		public override ItemId IdOf(ModelIndex index)
		{
			if ((index.Row < 0) || (index.Row >= mView.mShown.Count))
				return NoItem;
			return mView.mEntries[mView.mShown[index.Row]].Id;
		}

		/// The shown lines are in entry order and the ids rise with it: a binary search, so a
		/// large selection pruned after a trim or a filter does not walk every row per id.
		public override ModelIndex IndexOfId(ItemId id)
		{
			int low = 0;
			int high = mView.mShown.Count - 1;
			while (low <= high)
			{
				let mid = (low + high) / 2;
				let at = mView.mEntries[mView.mShown[mid]].Id;
				if (at == id)
					return Index((int32)mid);
				if (at < id)
					low = mid + 1;
				else
					high = mid - 1;
			}
			return .();
		}

		public void Inserted(int32 row) => NotifyRowsInserted(.(), row, 1);
		public void Reset() => NotifyReset();
	}

	/// A reference of ours; the panel showing it takes its own. Declared first: it goes last,
	/// after the model the list it holds borrows.
	private Node mContent ~ _?.ReleaseRef();
	/// Borrowed; the content's.
	private ListView mList = null;
	/// Borrowed; the content's.
	private Sedulous.GUI.Button[LogBucket.Count] mChips;
	private uint32 mKeyListener = 0;
	private uint32 mMenuListener = 0;
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// The entries shown, by their place in mEntries.
	private List<int> mShown = new .() ~ delete _;
	/// The lines each level holds now.
	private int[LogBucket.Count] mCounts;
	private bool[LogBucket.Count] mVisible = .(true, true, true);
	/// What a line must contain to show; empty shows every line.
	private String mSearch = new .() ~ delete _;
	private ItemId mNextId = 1;
	private delegate void(int lines) mOnCopied = null ~ delete _;
	private LineModel mModel ~ delete _;

	/// Over its frame `content` (the markup's: its parts by id). TAKES OWNERSHIP of a reference
	/// to `content`; null shows nothing.
	public this(Node content)
	{
		mContent = content;
		mModel = new LineModel(this);
		if (mContent == null)
			return;
		mList = Find<ListView>("console-list");
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.Create = new (type) => MakeRow();
			rows.Bind = new (row, index) => { BindRow(row, index); };
			mList.SetRowFactory(rows);
			mList.Model = mModel;
			// Ctrl+C before the list's own keys; the menu's Copy, Select All and Clear.
			mKeyListener = mList.AddEventListener(.KeyDown, new (e) =>
				{
					let key = (KeyEvent)e;
					if (((KeyCode)key.KeyCode == .C) && (key.Modifiers == KeyModCtrl))
					{
						CopySelection();
						e.Handled = true;
					}
				}, true);
			mMenuListener = mList.AddEventListener(.ContextMenu, new (e) =>
				{
					ShowMenu(((MouseEvent)e).Position);
					e.Handled = true;
				});
		}
		StringView[LogBucket.Count] chips = .("console-info", "console-warnings", "console-errors");
		for (int i < LogBucket.Count)
		{
			mChips[i] = Find<Sedulous.GUI.Button>(chips[i]);
			if (mChips[i] != null)
			{
				let bucket = (LogBucket)i;
				mChips[i].SetOnClick(new [=this, =bucket]() => { SetBucketVisible(bucket, !IsBucketVisible(bucket)); });
			}
		}
		if (let search = Find<TextField>("console-search"))
			search.SetOnTextChanging(new (text) => { SetSearch(text); });
		if (let clearSearch = Find<Sedulous.GUI.Button>("console-clear-search"))
		{
			clearSearch.SetOnClick(new () =>
				{
					if (let field = Find<TextField>("console-search"))
						field.Text = "";
					SetSearch("");
				});
		}
		if (let clear = Find<Sedulous.GUI.Button>("console-clear"))
			clear.SetOnClick(new () => { Clear(); });
		ShowChrome();
	}

	/// The panel may hold the content past this view: what of the list calls back here goes
	/// first.
	public ~this()
	{
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mList != null)
		{
			mList.RemoveEventListener(mKeyListener);
			mList.RemoveEventListener(mMenuListener);
			mList.Model = null;
			mList.SetRowFactory(null);
		}
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// Told how many lines a copy put on the clipboard (the application's notice). TAKES
	/// OWNERSHIP of `copied`.
	public void SetOnCopied(delegate void(int lines) copied)
	{
		delete mOnCopied;
		mOnCopied = copied;
	}

	/// One line, at the end; the oldest go past the cap. `time` is when it was written, since
	/// the editor started.
	public void AddEntry(LogLevel level, StringView category, StringView message, TimeSpan time = default)
	{
		let follow = IsAtBottom();
		let entry = new Entry();
		entry.Level = level;
		if (category.IsEmpty)
			entry.Text.Set(message);
		else
			entry.Text.AppendF("[{}] {}", category, message);
		entry.Time = time;
		entry.Id = mNextId++;
		mCounts[(int)LogBucket.Of(level)]++;
		mEntries.Add(entry);
		bool reset = false;
		while (mEntries.Count > cMaxEntries)
		{
			let oldest = mEntries[0];
			mCounts[(int)LogBucket.Of(oldest.Level)]--;
			mEntries.RemoveAt(0);
			delete oldest;
			reset = true;
		}
		if (reset)
			Refilter(); // the places in mEntries moved
		else if (Shows(entry))
		{
			mShown.Add(mEntries.Count - 1);
			mModel.Inserted((int32)mShown.Count - 1);
		}
		ShowChrome();
		if (follow && (mList != null) && !mShown.IsEmpty)
			mList.ScrollToItem((int32)mShown.Count - 1);
	}

	public void Clear()
	{
		ClearAndDeleteItems(mEntries);
		for (var count in ref mCounts)
			count = 0;
		Refilter();
		ShowChrome();
	}

	public int EntryCount => mEntries.Count;
	public int ShownCount => mShown.Count;
	/// The lines a level holds now (shown or not).
	public int CountOf(LogBucket bucket) => mCounts[(int)bucket];
	/// A shown line's text ("[Category] message"); empty past the end.
	public StringView ShownText(int row) => ((row >= 0) && (row < mShown.Count)) ? (StringView)mEntries[mShown[row]].Text : default;
	/// A shown line's time as its row shows it (hh:mm:ss); empty past the end.
	public void ShownTime(int row, String outText)
	{
		if ((row >= 0) && (row < mShown.Count))
			TimeText(mEntries[mShown[row]].Time, outText);
	}

	public bool IsBucketVisible(LogBucket bucket) => mVisible[(int)bucket];

	public void SetBucketVisible(LogBucket bucket, bool visible)
	{
		if (mVisible[(int)bucket] == visible)
			return;
		mVisible[(int)bucket] = visible;
		Refilter();
		ShowChrome();
	}

	/// Shows only the lines holding `text`, ignoring case (the category is part of a line);
	/// empty shows them all. The search field calls it as the user types.
	public void SetSearch(StringView text)
	{
		if (mSearch == text)
			return;
		mSearch.Set(text);
		Refilter();
		ShowChrome();
	}

	public StringView Search => mSearch;

	/// The selected lines, oldest first, one per line.
	public void SelectedText(String outText)
	{
		if (mList == null)
			return;
		for (int row < mShown.Count)
		{
			if (!mList.IsItemSelected((int32)row))
				continue;
			if (!outText.IsEmpty)
				outText.Append('\n');
			outText.Append(mEntries[mShown[row]].Text);
		}
	}

	/// The selected lines on the system clipboard; nothing selected copies nothing.
	public void CopySelection()
	{
		let text = SelectedText(.. scope .());
		let dispatcher = (mContent != null) ? mContent.EventDispatcher : null;
		if (text.IsEmpty || (dispatcher == null) || (dispatcher.Clipboard == null))
			return;
		dispatcher.Clipboard.SetText(text);
		if (mOnCopied != null)
			mOnCopied(mList.SelectionCount);
	}

	/// The list (its selection, for a test).
	public ListView List => mList;
	/// The menu the list's context menu opened while it is open, else null.
	public Sedulous.GUI.Menu OpenMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	/// Whether a line passes the level chips and the search.
	private bool Shows(Entry entry) =>
		mVisible[(int)LogBucket.Of(entry.Level)] && (mSearch.IsEmpty || entry.Text.Contains(mSearch, true));

	private void Refilter()
	{
		mShown.Clear();
		for (int i < mEntries.Count)
		{
			if (Shows(mEntries[i]))
				mShown.Add(i);
		}
		mModel.Reset();
	}

	/// At the bottom, or with nothing to scroll: a new line is followed.
	private bool IsAtBottom()
	{
		if (mList == null)
			return true;
		return mList.ScrollOffset.Y >= mList.ScrollRange.Y - cFollowSlack;
	}

	/// The chips' counts and states, the search's x, the empty line.
	private void ShowChrome()
	{
		StringView[LogBucket.Count] names = .("Info", "Warnings", "Errors");
		for (int i < LogBucket.Count)
		{
			let chip = mChips[i];
			if (chip == null)
				continue;
			let count = mCounts[i];
			if (count == 0)
				chip.Text = names[i];
			else if (count > 9999)
				chip.Text = scope $"{names[i]} 9999+"; // the count stays exact; the chip's width does not grow
			else
				chip.Text = scope $"{names[i]} {count}";
			if (mVisible[i])
				chip.AddClass("checked");
			else
				chip.RemoveClass("checked");
		}
		if (let clearSearch = Find<Sedulous.GUI.Button>("console-clear-search"))
			clearSearch.Visible = !mSearch.IsEmpty; // keeps its place: the field does not jump
		if (let empty = Find<Sedulous.GUI.Label>("console-empty"))
		{
			empty.Displayed = mShown.IsEmpty;
			empty.Text = mEntries.IsEmpty ? "No messages yet." : "No line matches.";
		}
	}

	/// A row: its time, then its text. A node with one reference, the row's.
	private Node MakeRow()
	{
		let row = new Sedulous.GUI.Panel();
		row.AddClass("log-row");
		let time = new Sedulous.GUI.Label();
		time.AddClass("log-time");
		time.AddClass("mono");
		row.AddChild(time);
		time.ReleaseRef(); // the row's reference keeps it
		let text = new Sedulous.GUI.Label();
		text.AddClass("log-text");
		row.AddChild(text);
		text.ReleaseRef();
		return row;
	}

	private void BindRow(Node node, ModelIndex index)
	{
		let row = node as UIWidget;
		if ((row == null) || (index.Row < 0) || (index.Row >= mShown.Count) || (row.ChildCount < 2))
			return;
		let entry = mEntries[mShown[index.Row]];
		if (let time = row.GetChildAt(0) as Sedulous.GUI.Label)
			time.Text = TimeText(entry.Time, .. scope .());
		if (let text = row.GetChildAt(1) as Sedulous.GUI.Label)
			text.Text = entry.Text;
		// Its level's colour, the sheet's: info lines in the text colour.
		row.RemoveClass("debug");
		row.RemoveClass("warning");
		row.RemoveClass("error");
		if ((entry.Level == .Trace) || (entry.Level == .Debug))
			row.AddClass("debug");
		else if (entry.Level == .Warning)
			row.AddClass("warning");
		else if (LogBucket.Of(entry.Level) == .Error)
			row.AddClass("error");
	}

	/// hh:mm:ss since the editor started.
	private static void TimeText(TimeSpan time, String outText)
	{
		let seconds = (int64)time.TotalSeconds;
		outText.AppendF("{:D2}:{:D2}:{:D2}", seconds / 3600, (seconds / 60) % 60, seconds % 60);
	}

	private void ShowMenu(Float2 at)
	{
		if (mList == null)
			return;
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		let copy = mMenu.AddItem("Copy", new () => { CopySelection(); });
		copy.Shortcut = "Ctrl+C";
		copy.Enabled = mList.SelectionCount > 0;
		mMenu.AddItem("Select All", new () => { mList.SelectAll(); });
		mMenu.AddSeparator();
		mMenu.AddItem("Clear", new () => { Clear(); });
		mMenu.Open(mList, at);
	}
}
