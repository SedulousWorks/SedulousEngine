using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// The Assets panel (Raptor's editor-gui spec, 5.2, layer 7), over its markup
// (Data/Editor/Assets.gml) as the mock draws it: the project's source content, the content database
// the truth. The group tree on the left (folders, Content at the top); the toolbar's breadcrumb
// where it is; the group's subgroups then its assets on the right, as tiles or a list (kept per
// project), each by its type's glyph (its category's tint), its name, what it is, its cook badge
// and a star when a favourite. The search looks in every group, by name or a guid's start, each
// match saying where it is; a whole guid selects its asset. The type filter keeps one type. With
// nothing to show it says what is so and offers the way on (clear the search, show every type).
// Enter or a double click opens an asset or enters a group; Reveal shows an asset where it lives.
// A drag of the selection carries its assets (AssetDrag) to a slot. It builds again when the
// database's shape moves, however the change came, and when a cook moves the badges.

/// What the Assets panel works over.
class AssetsViewServices
{
	/// The project, the favourites, the project's editor store, and the page registry that knows
	/// an asset's type by the name its instance stores. Borrowed.
	public EditorContext Context;
	/// The badges; null: none. Borrowed.
	public EditorCookService Cook;
	/// A type's glyph; null: generic ones. Borrowed.
	public EditorIcons Icons;
	/// An asset opened (its page). Owned.
	public delegate void(Instance instance) Open ~ delete _;
}

class AssetsView
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/Assets.gml";
	/// What the top group is called: it has no name of its own.
	public const String cTopGroup = "Content";
	private const float cTileWidth = 96.0f;
	private const float cTileHeight = 92.0f;
	/// A group's row id has it; an asset's never does. The bit above it is kept clear on both.
	private const ItemId cGroupBit = (ItemId)1 << 62;
	private const ItemId cIdBits = ~(cGroupBit | (cGroupBit << 1));

	/// A shown row: a subgroup's or an asset's, with the list's id for it.
	private struct Row
	{
		public Group Group;
		public Instance Instance;
		public ItemId Id;

		public this(Group group, Instance instance)
		{
			Group = group;
			Instance = instance;
			Id = AssetsView.IdOf(group, instance);
		}
	}

	/// A type the filter offers: its name as instances store it, and what it is called.
	private class TypeChoice
	{
		public String Name = new .() ~ delete _;
		public String Kind = new .() ~ delete _;
	}

	/// The rows as the list's model: an asset's id from its guid, a group's from its path, so a
	/// selection follows them through a rebuild.
	private class RowModel : IModel
	{
		private AssetsView mView;

		public this(AssetsView view) { mView = view; }

		public override int RowCount(ModelIndex parent) => parent.IsValid ? 0 : mView.mRows.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if ((role != .Display) || (index.Row < 0))
				return .();
			return .(mView.RowName(index.Row));
		}

		public override ItemId IdOf(ModelIndex index)
		{
			if ((index.Row < 0) || (index.Row >= mView.mRows.Count))
				return NoItem;
			return mView.mRows[index.Row].Id;
		}

		public override ModelIndex IndexOfId(ItemId id)
		{
			for (int32 row < (int32)mView.mRows.Count)
			{
				if (mView.mRows[row].Id == id)
					return Index(row);
			}
			return .();
		}

		public void Reset() => NotifyReset();

		public void Changed()
		{
			if (!mView.mRows.IsEmpty)
				NotifyRowsChanged(.(), 0, (int32)mView.mRows.Count);
		}
	}

	/// A reference of ours; the panel showing it takes its own. Declared first: it goes last,
	/// after the models the list and the tree it holds borrow.
	private Node mContent ~ _?.ReleaseRef();
	private AssetsViewServices mServices ~ delete _;
	// The content's: the tree holds them.
	private TreeView mTree = null;
	private ListView mList = null;
	private BreadcrumbBar mCrumbs = null;
	/// The type filter's, while it is ours.
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	/// The database it shows (the project's), and the group: compared, reached only while the
	/// database's revision says they are still there.
	private ContentDatabase mDb = null;
	private Group mCurrent = null;
	/// The revision it built at; none yet, so the first Refresh builds.
	private uint64 mDbRevision = uint64.MaxValue;
	private uint64 mCookRevision = 0;
	/// The database and revision the rows were collected at: a row is reached only while both
	/// hold, so a delete between a write and the next Refresh never reaches a freed instance.
	private ContentDatabase mRowsDb = null;
	private uint64 mRowsRevision = 0;
	private String mSearch = new .() ~ delete _;
	/// The type kept (as instances store its name, or its short name); empty: every type.
	private String mType = new .() ~ delete _;
	private bool mTiles = true;
	private List<Row> mRows = new .() ~ delete _;
	/// By the tree's node id.
	private List<Group> mTreeGroups = new .() ~ delete _;
	private TreeModel mGroupModel = new .() ~ delete _;
	private RowModel mModel ~ delete _;

	/// Over its frame `content` (the markup's: its parts by id). OWNERSHIP of `services` and of
	/// a reference to `content` transfers; null content shows nothing.
	public this(AssetsViewServices services, Node content)
	{
		mServices = services;
		mContent = content;
		mModel = new RowModel(this);
		if (mContent == null)
			return;
		mTree = Find<TreeView>("assets-groups");
		if (mTree != null)
		{
			mTree.Model = mGroupModel;
			// The user's choice only: a selection from code reports nothing.
			mTree.SetOnSelectionChanged(new (index) =>
				{
					let node = index.InternalId;
					if ((node >= 0) && (node < mTreeGroups.Count))
						Navigate(mTreeGroups[(int)node]);
				});
		}
		mList = Find<ListView>("assets-content");
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.TypeOf = new (index) => mTiles ? (uint32)0 : (uint32)1;
			rows.Create = new (type) => new AssetCell(type == 0);
			rows.Bind = new (cell, index) => { BindCell(cell, index.Row); };
			mList.SetRowFactory(rows);
			mList.Model = mModel;
			mList.SetOnActivated(new (index) => { OpenRow(index.Row); });
			mList.DragType = AssetDrag.cType;
			mList.SetOnDragPayload(new (payload, ids) => { DragPayloadFor(payload, ids); });
		}
		mCrumbs = Find<BreadcrumbBar>("assets-crumbs");
		if (mCrumbs != null)
		{
			mCrumbs.SetOnNavigate(new (item) =>
				{
					if (let group = GroupAt(item.Id))
						Navigate(group);
				});
		}
		if (let search = Find<TextField>("assets-search"))
			search.SetOnTextChanging(new (text) => { Search(text); });
		OnClick("assets-clear-search", new () => { SetSearch(""); });
		OnClick("assets-types", new () => { ShowTypeMenu(); });
		OnClick("assets-tiles", new () => { SetTiles(true); });
		OnClick("assets-list", new () => { SetTiles(false); });
		OnClick("assets-state-verb", new () => { StateVerb(); });
		ShowLayout();
	}

	/// The panel may hold the content past this view: what of it calls back here goes first.
	public ~this()
	{
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mList != null)
		{
			mList.Model = null;
			mList.SetRowFactory(null);
			mList.SetOnActivated(null);
			mList.SetOnDragPayload(null);
		}
		if (mTree != null)
		{
			mTree.Model = null;
			mTree.SetOnSelectionChanged(null);
		}
		if (mCrumbs != null)
			mCrumbs.SetOnNavigate(null);
		if (let search = Find<TextField>("assets-search"))
			search.SetOnTextChanging(null);
		StringView[?] buttons = .("assets-clear-search", "assets-types", "assets-tiles", "assets-list", "assets-state-verb");
		for (let id in buttons)
			OnClick(id, null);
	}

	/// Its frame. Ours: a caller that keeps it takes a reference.
	public Node Content => mContent;

	/// Once a frame: builds again when the project, its database's shape or the badges moved.
	public void Refresh()
	{
		let db = Sources();
		let revision = (db != null) ? db.Revision : 0;
		let cooked = (mServices.Cook != null) ? mServices.Cook.Revision : 0;
		if ((db !== mDb) || (revision != mDbRevision))
			Rebuild();
		else if (cooked != mCookRevision)
		{
			mCookRevision = cooked;
			mModel.Changed(); // the badges
		}
	}

	/// Builds the tree and the content again from the database, keeping where it is, the
	/// selection and the scroll where they still are.
	public void Rebuild()
	{
		let db = Sources();
		if (db !== mDb)
		{
			// Another project (or none): back to its top, as it opens, in its own view.
			mDb = db;
			mCurrent = null;
			mSearch.Clear();
			mType.Clear();
			if (let search = Find<TextField>("assets-search"))
				search.Text = "";
			ShowTypeButton();
			LoadTiles();
		}
		mDbRevision = (db != null) ? db.Revision : 0;
		mCookRevision = (mServices.Cook != null) ? mServices.Cook.Revision : 0;
		if ((mCurrent == null) || !Contains(mCurrent))
			mCurrent = (db != null) ? db.RootGroup : null;
		BuildTree();
		BuildRows();
	}

	// === Where it is ===

	/// The group it shows; null without a project.
	public Group CurrentGroup => mCurrent;

	/// Shows `group`'s content (the search cleared), its tree row selected, the breadcrumb
	/// following.
	public void Navigate(Group group)
	{
		if (!Contains(group))
			return;
		mCurrent = group;
		if (!mSearch.IsEmpty)
		{
			mSearch.Clear();
			if (let search = Find<TextField>("assets-search"))
				search.Text = "";
		}
		SelectTreeGroup(group);
		BuildRows();
	}

	/// Shows the asset `id` where it lives: its group (the search and the type filter cleared),
	/// it selected and in view. False when the project has no such asset.
	public bool Reveal(Guid id)
	{
		let db = Sources();
		let instance = (db != null) ? db.GetInstance(id) : null;
		if (instance == null)
			return false;
		mType.Clear();
		ShowTypeButton();
		Navigate(instance.OwningGroup);
		for (int row < mRows.Count)
		{
			if ((mRows[row].Instance === instance) && (mList != null))
				mList.SelectedItem = (int32)row;
		}
		return true;
	}

	// === What it shows ===

	/// Looks in every group for assets whose name holds `text` (any case) or whose guid starts
	/// with it (AssetFilter); a whole guid selects its asset. Empty shows the group again.
	public void SetSearch(StringView text)
	{
		if (let search = Find<TextField>("assets-search"))
			search.Text = text;
		Search(text);
	}

	public StringView SearchText => mSearch;

	/// Keeps only the assets of the type named `typeName` (in full, as instances store it, or
	/// short: AssetTypeNames.Matches); empty: every type.
	public void SetTypeFilter(StringView typeName)
	{
		mType.Set(typeName);
		ShowTypeButton();
		BuildRows();
	}

	public StringView TypeFilter => mType;

	/// Tiles or a list, kept with the project.
	public void SetTiles(bool tiles)
	{
		if (mTiles == tiles)
			return;
		mTiles = tiles;
		let context = mServices.Context;
		if (let store = (context != null) ? context.ProjectEditorSettings : null)
		{
			store.Section<EditorAssetBrowserSettings>().GridMode = tiles;
			store.MarkChanged<EditorAssetBrowserSettings>();
			context.RequestProjectEditorSettingsSave();
		}
		ShowLayout();
	}

	public bool ShowsTiles => mTiles;

	/// The rows shown, by their place: a group's or an asset's.
	public int RowCount => RowsLive ? mRows.Count : 0;

	public StringView RowName(int row)
	{
		if (!RowsLive || (row < 0) || (row >= mRows.Count))
			return default;
		return (mRows[row].Group != null) ? mRows[row].Group.Name : mRows[row].Instance.Name;
	}

	public Group RowGroup(int row) => (RowsLive && (row >= 0) && (row < mRows.Count)) ? mRows[row].Group : null;
	public Instance RowAsset(int row) => (RowsLive && (row >= 0) && (row < mRows.Count)) ? mRows[row].Instance : null;

	/// Opens an asset's page, or enters a group (Enter, a double click).
	public void OpenRow(int32 row)
	{
		if (!RowsLive || (row < 0) || (row >= mRows.Count))
			return;
		if (let group = mRows[row].Group)
			Navigate(group);
		else if ((mRows[row].Instance != null) && (mServices.Open != null))
			mServices.Open(mRows[row].Instance);
	}

	/// The selected assets, in their order (groups left out), added to `outAssets`.
	public void SelectedAssets(List<Instance> outAssets)
	{
		if ((mList == null) || !RowsLive)
			return;
		for (int row < mRows.Count)
		{
			if ((mRows[row].Instance != null) && mList.IsItemSelected((int32)row))
				outAssets.Add(mRows[row].Instance);
		}
	}

	public bool ShowsState
	{
		get
		{
			let state = Find<UIWidget>("assets-state");
			return (state != null) && state.Displayed;
		}
	}

	public StringView StateTitle
	{
		get
		{
			let title = Find<Sedulous.GUI.Label>("assets-state-title");
			return (title != null) ? title.Text : default;
		}
	}

	public ListView List => mList;
	public TreeView Tree => mTree;
	public BreadcrumbBar Crumbs => mCrumbs;
	/// The type filter's menu while it is open, for a test.
	public Sedulous.GUI.Menu TypeMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	// === Underneath ===

	/// A row's id: an asset's from its guid, a group's from its path, with the group bit.
	private static ItemId IdOf(Group group, Instance instance)
	{
		if (group != null)
		{
			let path = group.GetPath(.. scope .());
			return ((ItemId)path.GetHashCode() & cIdBits) | cGroupBit;
		}
		var id = instance.Id;
		let words = (uint64*)&id;
		return (words[0] ^ (words[1] * 31)) & cIdBits;
	}

	private ContentDatabase Sources()
	{
		let context = mServices.Context;
		let project = (context != null) ? context.Project : null;
		return (project != null) ? project.SourceDb : null;
	}

	/// The rows are of the database as it is now.
	private bool RowsLive
	{
		get
		{
			let db = Sources();
			return (db === mRowsDb) && ((db == null) || (db.Revision == mRowsRevision));
		}
	}

	/// Whether `group` is in the project's tree now (compared, never reached until found).
	private bool Contains(Group group)
	{
		let db = Sources();
		if ((db == null) || (group == null))
			return false;
		let pending = scope List<Group>();
		pending.Add(db.RootGroup);
		while (!pending.IsEmpty)
		{
			let at = pending.PopBack();
			if (at === group)
				return true;
			for (let child in at.Groups)
				pending.Add(child);
		}
		return false;
	}

	/// A group by its breadcrumb id (its path; empty: the top).
	private Group GroupAt(StringView path)
	{
		let db = Sources();
		var group = (db != null) ? db.RootGroup : null;
		int at = 0;
		while ((group != null) && (at < path.Length))
		{
			var end = at;
			while ((end < path.Length) && (path[end] != '/'))
				end++;
			group = group.GetGroup(path.Substring(at, end - at));
			at = end + 1;
		}
		return group;
	}

	/// Where `group` is as the user reads it ("Content", "Content/Models/Town"), appended.
	private static void ShownPath(Group group, String outPath)
	{
		outPath.Append(cTopGroup);
		if (group.Parent == null)
			return;
		outPath.Append('/');
		outPath.Append(group.GetPath(.. scope .()));
	}

	/// The Beef type an instance's type name names; null when none does.
	private Type TypeOf(StringView typeName)
	{
		let context = mServices.Context;
		return (context != null) ? context.Pages.ResolveType(typeName) : null;
	}

	/// What a type is called to the user, appended: its [DisplayName], else its short name.
	private void KindOf(StringView typeName, String outKind)
	{
		if (let type = TypeOf(typeName))
		{
			if (type.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
			{
				outKind.Append(shown.Name);
				return;
			}
		}
		outKind.Append(AssetTypeNames.Short(typeName));
	}

	private void Search(StringView text)
	{
		if (mSearch == text)
			return;
		mSearch.Set(text);
		BuildRows();
	}

	private bool Matches(Instance instance)
	{
		if (!mType.IsEmpty && !AssetTypeNames.Matches(instance.TypeName, mType))
			return false;
		return mSearch.IsEmpty || AssetFilter.Matches(instance, mSearch);
	}

	// The group tree: a node per group, the top one Content, all open.
	private void BuildTree()
	{
		if (mTree == null)
			return;
		mGroupModel.Clear();
		mTreeGroups.Clear();
		if (let db = Sources())
			AddTreeGroup(db.RootGroup, TreeModel.Root);
		for (int node < mTreeGroups.Count)
			mTree.SetIdExpanded((ItemId)node, true);
		if (mCurrent != null)
			SelectTreeGroup(mCurrent);
	}

	private void AddTreeGroup(Group group, int32 parent)
	{
		let node = mGroupModel.AddNode(parent, (group.Parent == null) ? (StringView)cTopGroup : group.Name);
		mGroupModel.SetIcon(node, "Editor/Icons/folder.svg");
		while (mTreeGroups.Count <= node)
			mTreeGroups.Add(null);
		mTreeGroups[node] = group;
		for (let child in group.Groups)
			AddTreeGroup(child, node);
	}

	/// Its tree row selected; from code, so no navigation follows.
	private void SelectTreeGroup(Group group)
	{
		if (mTree == null)
			return;
		for (int node < mTreeGroups.Count)
		{
			if (mTreeGroups[node] !== group)
				continue;
			for (int32 item < (int32)mTree.GetItemCount())
			{
				if (mTree.GetItemIndex(item).InternalId == node)
					mTree.SelectedItem = item; // every group is open: each is an item
			}
		}
	}

	// The content: the group's subgroups, then its assets; a search's matches from every group;
	// then the breadcrumb and the state.
	private void BuildRows()
	{
		mRows.Clear();
		let db = Sources();
		if ((db != null) && (mCurrent != null))
		{
			if (!mSearch.IsEmpty)
				CollectMatches(db.RootGroup);
			else
			{
				if (mType.IsEmpty)
				{
					for (let child in mCurrent.Groups)
						mRows.Add(.(child, null));
				}
				for (let instance in mCurrent.Instances)
				{
					if (Matches(instance))
						mRows.Add(.(null, instance));
				}
			}
		}
		mRowsDb = db;
		mRowsRevision = (db != null) ? db.Revision : 0;
		mModel.Reset();
		// A whole guid typed or pasted names one asset: it is selected, so Enter opens it.
		if ((mList != null) && AssetFilter.AsGuid(mSearch, let typed))
		{
			for (int row < mRows.Count)
			{
				if ((mRows[row].Instance != null) && (mRows[row].Instance.Id == typed))
				{
					mList.SelectedItem = (int32)row;
					break;
				}
			}
		}
		if (let clear = Find<Sedulous.GUI.Button>("assets-clear-search"))
			clear.Visible = !mSearch.IsEmpty; // keeps its place: the field does not jump
		ShowCrumbs();
		ShowState();
	}

	private void CollectMatches(Group group)
	{
		for (let instance in group.Instances)
		{
			if (Matches(instance))
				mRows.Add(.(null, instance));
		}
		for (let child in group.Groups)
			CollectMatches(child);
	}

	private void ShowCrumbs()
	{
		if (mCrumbs == null)
			return;
		let chain = scope List<Group>();
		for (var at = mCurrent; at != null; at = at.Parent)
			chain.Add(at);
		let items = scope List<BreadcrumbItem>();
		defer { ClearAndDeleteItems!(items); }
		for (int i = chain.Count; i > 0; i--)
		{
			let group = chain[i - 1];
			let item = new BreadcrumbItem();
			group.GetPath(item.Id);
			item.Text.Set((group.Parent == null) ? (StringView)cTopGroup : group.Name);
			ShownPath(group, item.Tooltip);
			items.Add(item);
		}
		mCrumbs.SetItems(items);
	}

	private void ShowState()
	{
		let none = mRows.IsEmpty;
		if (mList != null)
			mList.Displayed = !none;
		if (let state = Find<UIWidget>("assets-state"))
			state.Displayed = none;
		if (!none)
			return;
		StringView icon = "Editor/Icons/folder-open.svg";
		let title = scope String();
		StringView text = default;
		StringView verb = default;
		if (Sources() == null)
			title.Set("No project is open");
		else if (!mSearch.IsEmpty)
		{
			icon = "Editor/Icons/search.svg";
			title.AppendF("Nothing matches {}", mSearch);
			verb = "Clear the search";
		}
		else if (!mType.IsEmpty)
		{
			icon = "Editor/Icons/filter.svg";
			title.Append("No ");
			KindOf(mType, title);
			title.Append(" here");
			verb = "Show every type";
		}
		else
		{
			title.Append("Nothing in ");
			if (mCurrent != null)
				ShownPath(mCurrent, title);
			else
				title.Append(cTopGroup);
			title.Append(" yet");
			text = "Create an asset or import files into it.";
		}
		if (let image = Find<Sedulous.GUI.Image>("assets-state-icon"))
			image.Source = icon;
		if (let label = Find<Sedulous.GUI.Label>("assets-state-title"))
			label.Text = title;
		if (let label = Find<Sedulous.GUI.Label>("assets-state-text"))
		{
			label.Text = text;
			label.Displayed = !text.IsEmpty;
		}
		if (let button = Find<Sedulous.GUI.Button>("assets-state-verb"))
		{
			button.Text = verb;
			button.Displayed = !verb.IsEmpty;
		}
	}

	private void StateVerb()
	{
		if (!mSearch.IsEmpty)
			SetSearch("");
		else if (!mType.IsEmpty)
			SetTypeFilter("");
	}

	// The cell for a row, as it shows now.
	private void BindCell(Node node, int32 index)
	{
		let cell = node as AssetCell;
		if ((cell == null) || !RowsLive || (index < 0) || (index >= mRows.Count))
			return;
		let row = mRows[index];
		var shown = AssetCell.Shown();
		let kind = scope String();
		if (row.Group != null)
		{
			shown.Group = true;
			shown.Glyph = "Editor/Icons/folder.svg";
			shown.Name = row.Group.Name; // its folder says what it is
		}
		else
		{
			let instance = row.Instance;
			shown.Name = instance.Name;
			KindOf(instance.TypeName, kind);
			if (!mSearch.IsEmpty)
			{
				kind.Append(" in ");
				ShownPath(instance.OwningGroup, kind);
			}
			if (mServices.Icons != null)
			{
				if (let type = TypeOf(instance.TypeName))
				{
					let icon = mServices.Icons.For(type, "Asset");
					shown.Glyph = icon.Source;
					shown.GlyphClass = icon.Class;
				}
			}
			if (shown.Glyph.IsEmpty)
				shown.Glyph = "Editor/Icons/file.svg";
			shown.Favourite = (mServices.Context != null) && mServices.Context.IsFavorite(instance.Id);
			if (mServices.Cook != null)
			{
				switch (mServices.Cook.BadgeFor(instance))
				{
				case .Cooked:
					shown.Badge = "Cooked";
					shown.BadgeClass = "success";
				case .Missing:
					shown.Badge = "Stale";
					shown.BadgeClass = "warning";
				case .Failed:
					shown.Badge = "Failed";
					shown.BadgeClass = "danger";
				case .NoBuilder:
				}
			}
		}
		shown.Kind = kind;
		cell.Show(shown);
	}

	// Tiles or a list, the toggles saying which.
	private void ShowLayout()
	{
		if (mList != null)
		{
			mList.LayoutMode = mTiles ? .Grid : .List;
			if (mTiles)
			{
				mList.CellWidth = cTileWidth;
				mList.CellHeight = cTileHeight;
				mList.RemoveClass("asset-list");
				mList.AddClass("asset-tiles");
			}
			else
			{
				mList.RemoveClass("asset-tiles");
				mList.AddClass("asset-list");
			}
			mModel.Reset(); // the rows' kind follows
		}
		Check("assets-tiles", mTiles);
		Check("assets-list", !mTiles);
		if (let clear = Find<Sedulous.GUI.Button>("assets-clear-search"))
			clear.Visible = !mSearch.IsEmpty;
	}

	// The project's saved choice (tiles when it saved none).
	private void LoadTiles()
	{
		bool tiles = true;
		let context = mServices.Context;
		if (let store = (context != null) ? context.ProjectEditorSettings : null)
		{
			if (let section = store.Find<EditorAssetBrowserSettings>())
				tiles = section.GridMode;
		}
		mTiles = tiles;
		ShowLayout();
	}

	/// The type filter's button: checked while it keeps a type, its tooltip saying which.
	private void ShowTypeButton()
	{
		let types = Find<Sedulous.GUI.Button>("assets-types");
		if (types == null)
			return;
		if (mType.IsEmpty)
		{
			types.RemoveClass("checked");
			types.Tooltip = "Filter by type";
			return;
		}
		types.AddClass("checked");
		let tooltip = scope String("Showing ");
		KindOf(mType, tooltip);
		tooltip.Append(" only");
		types.Tooltip = tooltip;
	}

	// The type filter: every type the project's assets have, by what each is called (then by
	// name, where two are called alike).
	private void ShowTypeMenu()
	{
		let anchor = Find<Sedulous.GUI.Button>("assets-types");
		let db = Sources();
		if ((anchor == null) || (db == null))
			return;
		let choices = scope List<TypeChoice>();
		defer { ClearAndDeleteItems!(choices); }
		let pending = scope List<Group>();
		pending.Add(db.RootGroup);
		while (!pending.IsEmpty)
		{
			let group = pending.PopBack();
			for (let instance in group.Instances)
			{
				bool known = false;
				for (let offered in choices)
					known = known || (offered.Name == instance.TypeName);
				if (known)
					continue;
				let made = new TypeChoice();
				made.Name.Set(instance.TypeName);
				KindOf(instance.TypeName, made.Kind);
				choices.Add(made);
			}
			for (let child in group.Groups)
				pending.Add(child);
		}
		choices.Sort(scope (a, b) =>
			{
				let byKind = String.Compare(a.Kind, b.Kind, false);
				return (byKind != 0) ? byKind : String.Compare(a.Name, b.Name, false);
			});
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		let every = mMenu.AddItem("Every type", new () => { SetTypeFilter(""); });
		every.Checkable = true;
		every.SetCheckedSilently(mType.IsEmpty);
		mMenu.AddSeparator();
		for (let choice in choices)
		{
			let typeName = new String(choice.Name);
			let item = mMenu.AddItem(choice.Kind, new [=this, =typeName] () => { SetTypeFilter(typeName); } ~ delete typeName);
			item.Checkable = true;
			item.SetCheckedSilently(!mType.IsEmpty && AssetTypeNames.Matches(choice.Name, mType));
		}
		mMenu.OpenBelow(anchor, anchor);
	}

	// A drag of the selection carries its assets (a group's row carries none).
	private void DragPayloadFor(DragPayload payload, Span<ItemId> ids)
	{
		if (!RowsLive)
			return;
		let assets = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(assets); }
		for (let id in ids)
		{
			for (let row in mRows)
			{
				if ((row.Instance != null) && (row.Id == id))
					assets.Add(new AssetDrag(row.Instance.Id, row.Instance.TypeName, row.Instance.Name));
			}
		}
		if (!assets.IsEmpty)
			AssetDrag.Payload(assets, payload);
	}

	/// The frame's button `id` runs `click` (null: nothing). OWNERSHIP of `click` transfers.
	private void OnClick(StringView id, delegate void() click)
	{
		if (let button = Find<Sedulous.GUI.Button>(id))
			button.SetOnClick(click);
		else
			delete click;
	}

	/// The frame's button `id` checked or not.
	private void Check(StringView id, bool on)
	{
		if (let button = Find<Sedulous.GUI.Button>(id))
		{
			if (on)
				button.AddClass("checked");
			else
				button.RemoveClass("checked");
		}
	}

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}
}
