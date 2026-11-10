using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// The picker: one for paths, groups and
// components (an asset slot's is the asset picker, AssetPickerWindow), as the kit draws it (Data/Editor/Picker.xml). A search over the rows, which sit under
// their sections in the order the owner gives them, favourites first in a section of their own; a
// row shows its glyph (its category's tint), its name, what it is, a star when a favourite, and a
// check on the current value. The current value is lit when it opens; Up and Down move the light
// past the section headings while the search keeps the keys, and Enter, a double click or Enter on
// the list picks. The foot says so ("Esc keeps" the current value), and a close at the search's end
// keeps it too: no button sets nothing, so a pick never clears a value by a slip. With nothing to
// pick it says what is missing and offers the owner's next step;
// with nothing matching, it says so and offers to clear the search. A tree request (the groups')
// indents its rows by level in its order, and a search keeps the rows above each match, dimmed, so
// a match reads where it is. It opens as a modal popup in the window's middle.

/// One thing a picker offers.
class PickerItem
{
	/// What a pick answers (a guid's text, a path); unique in a request.
	public String Key = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	/// What it is, dim after the name (a type, a folder): a few words.
	public String Detail = new .() ~ delete _;
	/// A sentence about it, the foot's while its row is lit (a component's).
	public String Description = new .() ~ delete _;
	/// The heading it is listed under.
	public String Section = new .() ~ delete _;
	/// Its icon's source.
	public String Glyph = new .() ~ delete _;
	/// The class tinting it (a category's).
	public String GlyphClass = new .() ~ delete _;
	public bool Favourite = false;
	/// Its level in a tree request, under the item before it one level up.
	public uint32 Depth = 0;
}

/// What a picker is opened with.
class PickerRequest
{
	/// The search's ("Search materials").
	public String Placeholder = new .() ~ delete _;
	/// In their order; each section where its first item is.
	public List<PickerItem> Items = new .() ~ DeleteContainerAndItems!(_);
	/// The current value's key: checked, and lit when it opens.
	public String Current = new .() ~ delete _;
	/// The items a tree (by Depth, in their order): a search keeps where each match is.
	public bool Tree = false;
	/// With nothing to pick ("No materials yet").
	public String EmptyTitle = new .() ~ delete _;
	public String EmptyText = new .() ~ delete _;
	/// The next step it offers then ("Import..."), run after it closes.
	public String EmptyVerb = new .() ~ delete _;
	public delegate void() OnEmptyVerb ~ delete _;
	public delegate void(StringView key) OnPicked ~ delete _;
	/// Adds what can be done where the picker was right-clicked to `menu`: on the item `key`, or in
	/// the space under the items (`key` empty). An empty menu is not shown; null: no menu.
	public delegate void(Sedulous.GUI.Menu menu, StringView key) OnContextMenu ~ delete _;

	/// An item at the end, its texts copied; it is the request's.
	public PickerItem Add(StringView key, StringView name, StringView section = default, StringView detail = default)
	{
		let item = new PickerItem();
		item.Key.Set(key);
		item.Name.Set(name);
		item.Section.Set(section);
		item.Detail.Set(detail);
		Items.Add(item);
		return item;
	}
}

/// One row: an item's glyph, name, detail, favourite star and current check.
class PickerRow : UIWidget
{
	/// A level's indent, in pixels.
	private const uint32 cIndent = 16;

	// Owned by the tree: the row holds its parts and never lets one go.
	private Sedulous.GUI.Panel mIndent;
	private uint32 mIndentLevels = 0;
	private Sedulous.GUI.Image mGlyph;
	private Sedulous.GUI.Label mName;
	private Sedulous.GUI.Label mDetail;
	private Sedulous.GUI.Image mStar;
	private Sedulous.GUI.Image mCheck;
	/// The category class on the glyph now, taken off when the glyph changes.
	private String mGlyphClass = new .() ~ delete _;

	public this()
	{
		AddClass("asset-row");
		mIndent = Part<Sedulous.GUI.Panel>("picker-indent");
		mGlyph = Part<Sedulous.GUI.Image>("row-icon");
		mName = Part<Sedulous.GUI.Label>("row-name");
		mDetail = Part<Sedulous.GUI.Label>("row-kind");
		mStar = Part<Sedulous.GUI.Image>("badge-icon");
		mStar.AddClass("star");
		mStar.Source = "Editor/Icons/star.svg";
		mStar.Tooltip = "Favourite";
		mCheck = Part<Sedulous.GUI.Image>("row-trail");
		mCheck.Source = "Editor/Icons/check.svg";
		mCheck.Tooltip = "The current value";
	}

	/// `context`: a tree's item shown only as where a match is, dimmed.
	public void Show(PickerItem item, bool current, bool context = false)
	{
		mIndentLevels = item.Depth;
		mIndent.Displayed = item.Depth > 0;
		if (item.Depth > 0)
			mIndent.SetInlineStyle("width", scope String()..AppendF("{}px", item.Depth * cIndent));
		if (context)
			AddClass("context");
		else
			RemoveClass("context");
		if (!mGlyphClass.IsEmpty)
			mGlyph.RemoveClass(mGlyphClass);
		mGlyphClass.Set(item.GlyphClass);
		if (!mGlyphClass.IsEmpty)
			mGlyph.AddClass(mGlyphClass);
		mGlyph.Source = item.Glyph;
		mGlyph.Displayed = !item.Glyph.IsEmpty;
		mName.Text = item.Name;
		mDetail.Text = item.Detail;
		mStar.Displayed = item.Favourite;
		mCheck.Displayed = current;
	}

	public StringView ShownName => mName.Text;
	public StringView ShownDetail => mDetail.Text;
	public StringView ShownGlyph => mGlyph.Source;
	public bool ShowsCheck => mCheck.Displayed;
	public bool ShowsStar => mStar.Displayed;
	/// How deep it is indented, in levels; whether it is shown only as where a match is.
	public uint32 Indent => mIndentLevels;
	public bool IsContext => HasClass("context");

	/// A part of class `cls`, the row's: the row takes the pointer, not its parts.
	private T Part<T>(StringView cls) where T : UIWidget, new
	{
		let part = new T();
		part.AddClass(cls);
		part.HitTestVisible = false;
		AddChild(part);
		part.ReleaseRef(); // the tree's reference keeps it
		return part;
	}
}

class Picker
{
	/// Its frame's markup, under the data root.
	public const String cMarkupPath = "Editor/Picker.xml";
	/// The favourites' section, listed first.
	public const String cFavourites = "Favourites";
	private const float cRowEstimate = 26.0f;
	/// A heading's id has it; an item's never does.
	private const ItemId cHeaderBit = (ItemId)1 << 63;

	private struct Row
	{
		public bool Header;
		/// An item's, in the request.
		public int Item;
		/// Its section (a heading's text): the request's string.
		public StringView Section;
		/// A tree's item shown only as where a match is.
		public bool Context;

		public this(bool header, int item, StringView section, bool context = false)
		{
			Header = header;
			Item = item;
			Section = section;
			Context = context;
		}
	}

	/// The shown rows as the list's model: a heading cannot be selected; an id follows the row.
	private class RowModel : IModel
	{
		private Picker mPicker;

		public this(Picker picker) { mPicker = picker; }

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mPicker.mRows.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if (role != .Display)
				return .();
			return .(mPicker.RowText(index.Row));
		}

		public override bool IsSelectable(ModelIndex index) => mPicker.IsItemRow(index.Row);

		public override ItemId IdOf(ModelIndex index)
		{
			if ((index.Row < 0) || (index.Row >= mPicker.mRows.Count))
				return NoItem;
			let row = mPicker.mRows[index.Row];
			let section = (ItemId)row.Section.GetHashCode();
			if (row.Header)
				return section | Picker.cHeaderBit;
			let key = (ItemId)mPicker.mRequest.Items[row.Item].Key.GetHashCode();
			return ((section * 31) ^ key) & ~Picker.cHeaderBit;
		}

		public void Reset() => NotifyReset();
	}

	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	/// Declared first: it goes last, after the model the list it holds borrows.
	private Node mContent ~ _?.ReleaseRef();
	// The frame's: the tree holds them.
	private TextField mSearch = null;
	private ListView mList = null;
	private UIWidget mState = null;
	private Sedulous.GUI.Label mHint = null;
	/// What the keys do, the foot's when the lit item says nothing.
	private String mKeysHint = new .() ~ delete _;
	/// BORROWED: what it opened over, last.
	private SceneRoot mRoot = null;
	/// What it was opened with last; an empty one before.
	private PickerRequest mRequest = new .() ~ delete _;
	private List<Row> mRows = new .() ~ delete _;
	/// The sections in the order each first came, the request's strings.
	private List<StringView> mSections = new .() ~ delete _;
	private RowModel mModel ~ delete _;
	/// A right-click's menu (the request's OnContextMenu), while it is the last one: one reference.
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	private uint32 mListMenuListener = 0;

	/// The picker in `content` (the markup's: `picker-search`, `picker-list`, `picker-state` and
	/// its parts, `picker-hint`, `picker-close`, by id). TAKES OWNERSHIP of a reference to
	/// `content`; null makes a picker that never opens.
	public this(Node content)
	{
		mContent = content;
		mModel = new RowModel(this);
		if (mContent == null)
			return;
		mSearch = Find<TextField>("picker-search");
		mList = Find<ListView>("picker-list");
		mState = Find<UIWidget>("picker-state");
		mHint = Find<Sedulous.GUI.Label>("picker-hint");
		if (mSearch != null)
			mSearch.SetOnTextChanging(new (text) => { Filter(text); });
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.TypeOf = new (index) => IsHeader(index.Row) ? (uint32)1 : 0;
			rows.Create = new (type) => MakeRow(type);
			rows.Bind = new (row, index) => { BindRow(row, index.Row); };
			mList.SetRowFactory(rows);
			mList.EstimatedRowHeight = cRowEstimate;
			mList.Model = mModel;
			mList.SetOnActivated(new (index) => { PickRow(index.Row); });
			mList.SetOnSelectionChanged(new (index) => { ShowHint(); });
			// A right-click's menu, from the request: on an item, or in the space under them.
			mListMenuListener = mList.AddEventListener(.ContextMenu, new (e) =>
				{
					if (mRequest.OnContextMenu == null)
						return;
					let at = ((MouseEvent)e).Position;
					let row = mList.ItemAt(at);
					OpenMenu(IsItemRow(row) ? (StringView)mRequest.Items[mRows[row].Item].Key : default, at);
					e.Handled = true;
				});
		}
		if (let close = CloseButton)
			close.SetOnClick(new () => { Close(); });
		if (let verb = StateVerbButton)
			verb.SetOnClick(new () => { StateVerb(); });
		// Up, Down and Enter before the search takes them.
		mContent.AddEventListener(.KeyDown, new (e) =>
			{
				let key = (KeyEvent)e;
				let code = (KeyCode)key.KeyCode;
				if (key.Modifiers != 0)
					return;
				if ((code == .Down) || (code == .Up))
				{
					Step((code == .Down) ? 1 : -1);
					e.Handled = true;
				}
				else if ((code == .Return) || (code == .KeypadEnter))
				{
					PickLit();
					e.Handled = true;
				}
			}, true);
	}

	/// The content may outlive this: what of the list calls back here goes first.
	public ~this()
	{
		Close();
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mList != null)
		{
			mList.RemoveEventListener(mListMenuListener);
			mList.Model = null;
			mList.SetRowFactory(null);
		}
	}

	/// Opens it over `root` for `request`, in the window's middle whatever asked (every picker the
	/// same: the user, 2026-10-25); the search empty and focused, the current value lit. False with
	/// no frame, a root in no GUI, or one open already. OWNERSHIP of `request` transfers, opened or
	/// not.
	public bool Open(SceneRoot root, PickerRequest request)
	{
		let dispatcher = root.EventDispatcher;
		if ((mContent == null) || (dispatcher == null) || IsOpen)
		{
			delete request;
			return false;
		}
		mRoot = root;
		// The rows view the old request's strings: none are left once it goes.
		mRows.Clear();
		mSections.Clear();
		delete mRequest;
		mRequest = request;
		if (mSearch != null)
		{
			mSearch.Placeholder = mRequest.Placeholder;
			mSearch.Text = default;
		}
		Filter(default);
		let options = new PopupOptions();
		options.Kind = .Auto; // Escape and a press outside close it, keeping the current value
		options.Modal = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.Centered = true;
		dispatcher.OpenPopup(root, mContent, options);
		if (mSearch != null)
			dispatcher.FocusNode = mSearch;
		return true;
	}

	public void Close()
	{
		if (IsOpen)
			mRoot.EventDispatcher.ClosePopup(mContent);
	}

	public bool IsOpen => (mRoot != null) && (mContent != null) && (mRoot.EventDispatcher != null) && mRoot.EventDispatcher.IsPopupOpen(mContent);

	/// Filters for `text`, as typing it in the search does.
	public void SetQuery(StringView text)
	{
		if (mSearch != null)
			mSearch.Text = text;
		Filter(text);
	}

	/// The rows shown, headings included.
	public int RowCount => mRows.Count;
	public bool IsHeader(int32 row) => (row >= 0) && (row < mRows.Count) && mRows[row].Header;

	/// What a shown row says: a heading's section, an item's name; empty past the end.
	public StringView RowText(int32 row)
	{
		if ((row < 0) || (row >= mRows.Count))
			return default;
		let r = mRows[row];
		return r.Header ? r.Section : (StringView)mRequest.Items[r.Item].Name;
	}

	/// A tree's row: how deep it is, and whether it is shown only as where a match is.
	public uint32 RowDepth(int32 row) => IsItemRow(row) ? mRequest.Items[mRows[row].Item].Depth : 0;
	public bool IsContext(int32 row) => IsItemRow(row) && mRows[row].Context;

	/// The lit item's key (Enter's); empty with none.
	public StringView LitKey
	{
		get
		{
			let row = (mList != null) ? mList.SelectedItem : -1;
			return IsItemRow(row) ? (StringView)mRequest.Items[mRows[row].Item].Key : default;
		}
	}

	/// Moves the light `by` items, past the headings; it stays at the ends.
	public void Step(int32 by)
	{
		if ((mList == null) || mRows.IsEmpty)
			return;
		var row = mList.SelectedItem;
		if (row < 0)
		{
			Light(FirstItemFrom(0, 1));
			return;
		}
		let step = (by < 0) ? (int32)-1 : 1;
		for (int32 left = (by < 0) ? -by : by; left > 0; --left)
		{
			let next = FirstItemFrom(row + step, step);
			if (next < 0)
				break;
			row = next;
		}
		Light(row);
	}

	/// Shows the items `items` holds in place of the request's, while it stays open (one was just
	/// made), the search cleared and the item `lit` lit. TAKES the items out of `items`.
	public void Refill(List<PickerItem> items, StringView lit)
	{
		// The rows view the old items' strings: none are left once they go.
		mRows.Clear();
		mSections.Clear();
		ClearAndDeleteItems!(mRequest.Items);
		mRequest.Items.AddRange(items);
		items.Clear();
		SetQuery(default);
		for (int32 row < (int32)mRows.Count)
		{
			if (IsItemRow(row) && (mRequest.Items[mRows[row].Item].Key == lit))
			{
				Light(row);
				break;
			}
		}
	}

	/// The menu a right-click opened, while it is the last one (tests).
	public Sedulous.GUI.Menu ContextMenu => mMenu;

	/// Opens the right-click menu as a right-click on the item `key` (empty: the space under the
	/// items) does, for tests and a keyboard's menu key.
	public void OpenContextMenu(StringView key) => OpenMenu(key, .(0.0f, 0.0f));

	/// The request's menu for `key` at `at` (world space, a pointer's); an empty one is not shown.
	private void OpenMenu(StringView key, Float2 at)
	{
		if ((mRequest.OnContextMenu == null) || (mList == null))
			return;
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		let held = scope String(key); // the request's string, which the menu's verbs may replace
		mRequest.OnContextMenu(mMenu, held);
		if (mMenu.ItemCount > 0)
			mMenu.Open(mList, mList.RootNode.ConvertToNodeSpace(at)); // a menu opens in the root's space
	}

	/// Picks the lit item; with none lit, nothing.
	public void PickLit() => PickRow((mList != null) ? mList.SelectedItem : -1);

	public StringView Hint => (mHint != null) ? mHint.Text : default;
	public Sedulous.GUI.Label HintLabel => mHint;

	/// Whether it shows its state (nothing to pick, nothing matching) instead of rows.
	public bool ShowsState => (mState != null) && mState.Displayed;

	/// What the state says.
	public StringView StateTitle
	{
		get
		{
			let title = Find<Sedulous.GUI.Label>("picker-state-title");
			return (title != null) ? title.Text : default;
		}
	}

	public StringView StateText
	{
		get
		{
			let text = Find<Sedulous.GUI.Label>("picker-state-text");
			return (text != null) ? text.Text : default;
		}
	}

	/// The state's icon's source.
	public StringView StateIcon
	{
		get
		{
			let icon = Find<Sedulous.GUI.Image>("picker-state-icon");
			return (icon != null) ? icon.Source : default;
		}
	}

	/// The frame's: the tree holds them.
	public ListView List => mList;
	public TextField Search => mSearch;
	public Sedulous.GUI.Button CloseButton => Find<Sedulous.GUI.Button>("picker-close");
	public Sedulous.GUI.Button StateVerbButton => Find<Sedulous.GUI.Button>("picker-state-verb");
	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	private bool IsItemRow(int32 row) => (row >= 0) && (row < mRows.Count) && !mRows[row].Header;

	/// The first item row from `row` on in `step`'s direction; -1 when there is none.
	private int32 FirstItemFrom(int32 row, int32 step)
	{
		for (var at = row; (at >= 0) && (at < mRows.Count); at += step)
		{
			if (!mRows[at].Header)
				return at;
		}
		return -1;
	}

	private void Light(int32 row)
	{
		if ((mList != null) && IsItemRow(row))
		{
			mList.SelectedItem = row;
			ShowHint(); // lit from code: the list's own callback does not hear it
		}
	}

	/// The rows for `query` (case folded; a name that starts with it before one that holds it, or
	/// whose detail does), favourites first, then each section in the order it first came.
	private void Filter(StringView query)
	{
		mRows.Clear();
		if (mRequest.Tree)
		{
			FilterTree(query);
			return;
		}
		AddSection(cFavourites, true, query);
		mSections.Clear();
		for (let item in mRequest.Items)
		{
			if (!mSections.Contains(item.Section))
				mSections.Add(item.Section);
		}
		for (let section in mSections)
			AddSection(section, false, query);
		Shown(query);
	}

	/// A tree's rows for `query`: its items in their order, those matching by name and the groups
	/// above each, so a match reads where it is (two of one name under different parents apart).
	/// No sections, no favourites: the tree is the order.
	private void FilterTree(StringView query)
	{
		let count = mRequest.Items.Count;
		let shown = scope bool[count];
		let matched = scope bool[count];
		for (int i < count)
		{
			if (!mRequest.Items[i].Name.Contains(query, true))
				continue;
			matched[i] = shown[i] = true;
			var depth = mRequest.Items[i].Depth;
			for (var up = i - 1; (up >= 0) && (depth > 0); up--)
			{
				if (mRequest.Items[up].Depth < depth)
				{
					shown[up] = true;
					depth = mRequest.Items[up].Depth;
				}
			}
		}
		for (int i < count)
		{
			if (shown[i])
				mRows.Add(.(false, i, default, !query.IsEmpty && !matched[i]));
		}
		Shown(query);
	}

	/// After filtering: the list told, the state shown, the current value lit, else the first match.
	private void Shown(StringView query)
	{
		mModel.Reset();
		ShowState(query);
		int32 lit = -1;
		for (int32 row = 0; (row < mRows.Count) && (lit < 0); row++)
		{
			if (!mRows[row].Header && !mRows[row].Context && IsCurrent(mRequest.Items[mRows[row].Item]))
				lit = row;
		}
		if (mList != null)
			mList.ClearSelection();
		for (int32 row = 0; (row < mRows.Count) && (lit < 0); row++)
		{
			if (!mRows[row].Header && !mRows[row].Context)
				lit = row;
		}
		Light(lit);
	}

	/// A section's matching items under its heading (none: no heading, nor one for the unnamed
	/// section), those whose name starts with `query` first.
	private void AddSection(StringView section, bool favourites, StringView query)
	{
		bool headed = false;
		for (int pass < 2)
		{
			for (int i < mRequest.Items.Count)
			{
				let item = mRequest.Items[i];
				let member = favourites ? item.Favourite : (item.Section == section);
				if (!member || !Matches(item, query) || (Starts(item, query) != (pass == 0)))
					continue;
				if (!headed && !section.IsEmpty)
					mRows.Add(.(true, 0, section));
				headed = true;
				mRows.Add(.(false, i, section));
			}
		}
	}

	private static bool Matches(PickerItem item, StringView query) =>
		item.Name.Contains(query, true) || item.Detail.Contains(query, true);

	private static bool Starts(PickerItem item, StringView query) =>
		query.IsEmpty || item.Name.StartsWith(query, .OrdinalIgnoreCase);

	private bool IsCurrent(PickerItem item) => !mRequest.Current.IsEmpty && (item.Key == mRequest.Current);

	private void ShowState(StringView query)
	{
		let none = mRequest.Items.IsEmpty;
		let unmatched = !none && mRows.IsEmpty;
		if (mList != null)
			mList.Displayed = !none && !unmatched;
		if (mState != null)
			mState.Displayed = none || unmatched;
		if (let icon = Find<Sedulous.GUI.Image>("picker-state-icon"))
			icon.Source = unmatched ? "Editor/Icons/search.svg" : "Editor/Icons/folder-open.svg";
		if (let title = Find<Sedulous.GUI.Label>("picker-state-title"))
		{
			if (unmatched)
				title.Text = scope $"Nothing matches {query}";
			else
				title.Text = mRequest.EmptyTitle;
		}
		if (let text = Find<Sedulous.GUI.Label>("picker-state-text"))
		{
			text.Text = mRequest.EmptyText;
			text.Displayed = none && !mRequest.EmptyText.IsEmpty;
		}
		if (let verb = StateVerbButton)
		{
			verb.Text = unmatched ? "Clear the search" : mRequest.EmptyVerb;
			verb.Displayed = unmatched || (none && (mRequest.OnEmptyVerb != null) && !mRequest.EmptyVerb.IsEmpty);
		}
		if (mHint != null)
		{
			StringView current = default;
			for (let item in mRequest.Items)
			{
				if (IsCurrent(item))
					current = item.Name;
			}
			mKeysHint.Clear();
			if (current.IsEmpty)
				mKeysHint.Append("Enter picks, Esc closes");
			else
				mKeysHint.AppendF("Enter picks, Esc keeps {}", current);
			ShowHint();
		}
	}

	// The foot: the lit item's description where it has one (read as the arrows move), else what
	// the keys do.
	private void ShowHint()
	{
		if (mHint == null)
			return;
		let lit = (mList != null) ? mList.SelectedItem : -1;
		StringView description = IsItemRow(lit) ? (StringView)mRequest.Items[mRows[lit].Item].Description : default;
		if (!description.IsEmpty)
		{
			mHint.Text = description;
			mHint.AddClass("described");
		}
		else
		{
			mHint.Text = mKeysHint;
			mHint.RemoveClass("described");
		}
	}

	/// No match: the search cleared. Nothing to pick: the owner's next step, after it closes.
	private void StateVerb()
	{
		if (!mRequest.Items.IsEmpty)
		{
			SetQuery(default);
			if ((mSearch != null) && (mSearch.EventDispatcher != null))
				mSearch.EventDispatcher.FocusNode = mSearch;
			return;
		}
		let verb = mRequest.OnEmptyVerb;
		mRequest.OnEmptyVerb = null;
		defer delete verb;
		Close();
		if (verb != null)
			verb();
	}

	private void PickRow(int32 row)
	{
		if (IsItemRow(row))
			Pick(mRequest.Items[mRows[row].Item].Key);
	}

	/// It closes first: what is picked may open something of its own (this picker again).
	private void Pick(StringView key)
	{
		let picked = mRequest.OnPicked;
		mRequest.OnPicked = null;
		defer delete picked;
		let chosen = scope String(key); // the request may go as the owner opens another
		Close();
		if (picked != null)
			picked(chosen);
	}

	/// A row's content: a heading's label, or an item's row. A node with one reference, the
	/// row's.
	private Node MakeRow(uint32 type)
	{
		if (type == 1)
		{
			let heading = new Sedulous.GUI.Label();
			heading.AddClass("picker-group");
			return heading;
		}
		return new PickerRow();
	}

	private void BindRow(Node node, int32 row)
	{
		if ((row < 0) || (row >= mRows.Count))
			return;
		let r = mRows[row];
		if (r.Header)
		{
			if (let heading = node as Sedulous.GUI.Label)
				heading.Text = r.Section;
		}
		else if (let shown = node as PickerRow)
		{
			let item = mRequest.Items[r.Item];
			shown.Show(item, IsCurrent(item), r.Context);
		}
	}

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}
}
