using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// The Console panel. Its frame is markup
/// (Data/Editor/Console.xml): a chip per level (Debug, holding the trace lines too, Info,
/// Warnings, Errors, holding the critical ones) with how many lines it holds, on showing them; a
/// search matching anywhere in a line ignoring case, cleared by its x; Clear; then the lines on a
/// virtualised list, each its time since the editor started and `[Category] message` in its
/// level's colour. The newest line is followed until the user scrolls up, and again once they
/// are back at the bottom. Rows select as any list's do (click, Ctrl, Shift, Ctrl+A); Ctrl+C or
/// the menu's Copy puts the selected lines on the clipboard, oldest first, one per line. The
/// entries are capped (the oldest trimmed); a selection is by entry, so it survives a trim. Fed
/// once a frame from the editor's log buffer (EditorApplication.DrainLog). A line's references (a
/// file at a line, an asset) that something can follow show as underlined links: a click on one
/// follows it, and a double click on the line follows its first reference, opening what a click
/// only selects.
class LogView
{
	/// Its frame under the data root.
	public const String cMarkupPath = "Editor/Console.xml";
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
		/// Those that can be followed, their parts in Text.
		public List<LogReference> References = new .() ~ DeleteContainerAndItems!(_);
		/// Text with its references as links; empty when none has a part.
		public String Markup = new .() ~ delete _;
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
	private bool[LogBucket.Count] mVisible = .(true, true, true, true);
	/// What a line must contain to show; empty shows every line.
	private String mSearch = new .() ~ delete _;
	private ItemId mNextId = 1;
	private delegate void(int lines) mOnCopied = null ~ delete _;
	private delegate bool(LogReference reference) mCanFollow = null ~ delete _;
	private delegate void(LogReference reference, bool open) mFollow = null ~ delete _;
	/// Each row's text label (the list keeps them while the view lives) and the entry it shows now.
	private List<(Sedulous.GUI.Label Label, ItemId Entry)> mBound = new .() ~ delete _;
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
			// A double click (or Enter) on a line follows its first reference.
			mList.SetOnActivated(new (index) =>
				{
					if (index.Row >= 0)
						FollowFirst(index.Row);
				});
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
		StringView[LogBucket.Count] chips = .("console-debug", "console-info", "console-warnings", "console-errors");
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
			mList.SetOnActivated(null);
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

	/// What follows a reference (the context's handlers): whether one can, and following it
	/// (`open`: a double click). Unset: references show as text. TAKES OWNERSHIP of both.
	public void SetFollow(delegate bool(LogReference reference) canFollow, delegate void(LogReference reference, bool open) follow)
	{
		delete mCanFollow;
		delete mFollow;
		mCanFollow = canFollow;
		mFollow = follow;
	}

	/// One line, at the end; the oldest go past the cap. `time` is when it was written, since
	/// the editor started. `references` are the line's (borrowed), their parts in `message`.
	public void AddEntry(LogLevel level, StringView category, StringView message, TimeSpan time = default,
		Span<LogReference> references = default)
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
		let shift = entry.Text.Length - message.Length; // the category before the message
		for (let reference in references)
		{
			if ((mCanFollow == null) || !mCanFollow(reference))
				continue;
			let shown = reference.Clone();
			if (shown.Length > 0)
				shown.Start += shift;
			entry.References.Add(shown);
		}
		LinkMarkup(entry.Text, entry.References, entry.Markup);
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

	/// A shown line's rich text with its references as links; empty when it shows plain.
	public StringView ShownMarkup(int row) => ((row >= 0) && (row < mShown.Count)) ? (StringView)mEntries[mShown[row]].Markup : default;

	/// A shown line's references that can be followed, their parts in its text.
	public Span<LogReference> ShownReferences(int row) => ((row >= 0) && (row < mShown.Count)) ? mEntries[mShown[row]].References : default;

	/// Follows a shown line's reference `index` (its link's click, or with `open` a double click).
	public bool FollowReference(int row, int index, bool open)
	{
		if ((row < 0) || (row >= mShown.Count) || (mFollow == null))
			return false;
		let entry = mEntries[mShown[row]];
		if ((index < 0) || (index >= entry.References.Count))
			return false;
		mFollow(entry.References[index], open);
		return true;
	}

	/// Follows a shown line's first reference, opening it (the line's double click).
	public bool FollowFirst(int row) => FollowReference(row, 0, true);

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
		StringView[LogBucket.Count] names = .("Debug", "Info", "Warnings", "Errors");
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
		// A click on a reference's link follows it; the row is found by the entry it shows.
		text.AddEventListener(.Link, new [=this, =text] (e) =>
			{
				let link = (LinkEvent)e;
				e.Handled = true;
				if (!(int32.Parse(link.Link) case .Ok(let index)))
					return;
				for (let bound in mBound)
				{
					if (bound.Label != text)
						continue;
					for (int shownRow < mShown.Count)
					{
						if (mEntries[mShown[shownRow]].Id == bound.Entry)
							FollowReference(shownRow, index, false);
					}
				}
			});
		row.AddChild(text);
		text.ReleaseRef();
		return row;
	}

	/// `text` as rich markup into `outMarkup`, each reference's part a link named by its index;
	/// nothing when none has a part.
	private static void LinkMarkup(StringView text, List<LogReference> references, String outMarkup)
	{
		bool any = false;
		for (let reference in references)
			any |= (reference.Length > 0) && ((reference.Start + reference.Length) <= text.Length);
		if (!any)
			return;
		int at = 0;
		for (int i < references.Count)
		{
			let reference = references[i];
			if ((reference.Length == 0) || (reference.Start < at) || ((reference.Start + reference.Length) > text.Length))
				continue;
			AppendPlain(StringView(text, at, reference.Start - at), outMarkup);
			outMarkup.AppendF("[u][link={}]", i);
			AppendPlain(StringView(text, reference.Start, reference.Length), outMarkup);
			outMarkup.Append("[/link][/u]");
			at = reference.Start + reference.Length;
		}
		AppendPlain(StringView(text, at), outMarkup);
	}

	/// Text as markup: a '[' doubled, so it reads as itself.
	private static void AppendPlain(StringView piece, String outMarkup)
	{
		for (let c in piece)
		{
			if (c == '[')
				outMarkup.Append('[');
			outMarkup.Append(c);
		}
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
		{
			text.Rich = !entry.Markup.IsEmpty;
			text.Text = entry.Markup.IsEmpty ? entry.Text : entry.Markup;
			bool known = false;
			for (var bound in ref mBound)
			{
				if (bound.Label == text)
				{
					bound.Entry = entry.Id;
					known = true;
				}
			}
			if (!known)
				mBound.Add((text, entry.Id));
		}
		// Its level's colour, the sheet's: info lines in the text colour.
		row.RemoveClass("debug");
		row.RemoveClass("warning");
		row.RemoveClass("error");
		if (LogBucket.Of(entry.Level) == .Debug)
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
		mMenu.Open(mList, mList.RootNode.ConvertToNodeSpace(at)); // `at` is a pointer's, in world space
	}
}
