using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

// The Assets panel (Raptor's editor-gui spec, 5.2, layer 7), over its markup
// (Data/Editor/Assets.gml) as the mock draws it: the project's source content, the content database
// the truth. The group tree on the left (folders, Content at the top); the toolbar's breadcrumb
// where it is; the group's subgroups then its assets on the right, as tiles or a list (kept per
// project), each by its type's glyph (its category's tint; a tile's thumbnail in its place once
// there is one, drawn again when it arrives), its name, what it is, its cook badge and a star when
// a favourite. The search looks in every group, by name or a guid's start, each match saying
// where it is; a whole guid selects its asset. The type filter keeps one type. With nothing to
// show it says what is so and offers the way on (clear the search, show every type).
// Enter or a double click opens an asset or enters a group; Reveal shows an asset where it lives.
// A drag of the selection carries its assets (AssetDrag) to a slot; dropped on a group's row, a
// group in the tree or a breadcrumb segment, they move into that group (AssetOperations.MoveTo),
// the drag saying "Move into ..." over a group, or why not (all there already, a name taken there).
// It builds again when the database's shape moves, however the change came, and when a cook moves
// the badges.
//
// Its verbs are AssetOperations', the ones an agent's delete takes too: an asset's menu (open,
// rename, duplicate, copy its guid or path, pin it, always export it; cook, rebuild or delete the
// selection holding it), a group's row's, and the shown group's (New from the creators, New
// Group, Import... of files picked with the OS's dialog, cook or rebuild it, or all at the top).
// Delete asks first, naming what goes. F2 or the menus' Rename edit a row's name or a tree group's
// in place, through their models: a refused name says why and keeps the edit open.

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
	/// Rename, duplicate, delete, cook; null: no menus and no edits in place. Borrowed.
	public AssetOperations Operations;
	/// An asset's picture (the thumbnails'), borrowed, null while there is none; unset: glyphs
	/// only. A picture that arrives later is told through the context's thumbnail listeners.
	/// Owned.
	public delegate Sedulous.GUI.Drawable(Guid id) Picture ~ delete _;
	/// Runs a creator into a group (File > New's create-and-open); unset: no New menu. Owned.
	public delegate void(AssetCreator creator, Group group) Create ~ delete _;
	/// Asks for files to import into a group (the OS's picker); unset: no Import.... Owned.
	public delegate void(Group group) Import ~ delete _;
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

		/// A row's name is edited in place (F2, the menu's Rename): the asset or group renamed.
		public override bool IsEditable(ModelIndex index) =>
			(mView.mServices.Operations != null) && mView.RowsLive && (index.Row >= 0) && (index.Row < mView.mRows.Count);

		/// False, the edit kept open, when the name is refused (said).
		public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value) =>
			(index.Row >= 0) && mView.RenameRow(index.Row, value.AsString);

		/// Assets dropped onto a group's row move into it; between rows is no move.
		public override DropEffect CanDrop(ModelDrop drop, String reason)
		{
			let group = (drop.Place == .On) ? mView.RowGroup(drop.Index.Row) : null;
			return ((group != null) && (drop.Payload != null) && mView.CanTake(drop.Payload, group, reason)) ? .Move : .None;
		}

		public override bool Drop(ModelDrop drop)
		{
			let group = (drop.Place == .On) ? mView.RowGroup(drop.Index.Row) : null;
			return (group != null) && (drop.Payload != null) && mView.Take(drop.Payload, group);
		}

		public void Reset() => NotifyReset();

		public void Changed()
		{
			if (!mView.mRows.IsEmpty)
				NotifyRowsChanged(.(), 0, (int32)mView.mRows.Count);
		}
	}

	/// The group tree's model: a group (not the top one) renamed in place; assets dropped onto a
	/// group move into it. TreeModel's own drops (its nodes moved, text made a node) are replaced:
	/// the tree is the database's, changed only through it.
	private class GroupTreeModel : TreeModel
	{
		private AssetsView mView;

		public this(AssetsView view) { mView = view; }

		public override bool IsEditable(ModelIndex index)
		{
			let group = mView.TreeGroupAt(index);
			return (mView.mServices.Operations != null) && (group != null) && (group.Parent != null);
		}

		/// False, the edit kept open, when the name is refused (said).
		public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value)
		{
			let group = mView.TreeGroupAt(index);
			return (group != null) && mView.RenameGroup(group, value.AsString);
		}

		public override DropEffect CanDrop(ModelDrop drop, String reason)
		{
			let group = (drop.Place == .On) ? mView.TreeGroupAt(drop.Index) : null;
			return ((group != null) && (drop.Payload != null) && mView.CanTake(drop.Payload, group, reason)) ? .Move : .None;
		}

		public override bool Drop(ModelDrop drop)
		{
			let group = (drop.Place == .On) ? mView.TreeGroupAt(drop.Index) : null;
			return (group != null) && (drop.Payload != null) && mView.Take(drop.Payload, group);
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
	/// The open menu (the type filter's, a row's, the group's), while it is ours.
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	/// The last delete asked about, while it is ours (a test answers it).
	private Sedulous.GUI.MessageBox mConfirm = null ~ _?.ReleaseRef();
	// The menus' and the Delete key's listeners on the list, the tree and the state.
	private uint32 mListMenuListener = 0;
	private uint32 mListKeyListener = 0;
	private uint32 mTreeMenuListener = 0;
	private uint32 mTreeKeyListener = 0;
	private uint32 mStateMenuListener = 0;
	/// The context's thumbnail listener; 0: none.
	private uint64 mPictureListener = 0;
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
	private GroupTreeModel mGroupModel ~ delete _;
	private RowModel mModel ~ delete _;

	/// Over its frame `content` (the markup's: its parts by id). OWNERSHIP of `services` and of
	/// a reference to `content` transfers; null content shows nothing.
	public this(AssetsViewServices services, Node content)
	{
		mServices = services;
		mContent = content;
		mModel = new RowModel(this);
		mGroupModel = new GroupTreeModel(this);
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
			// The group it shows (a right press has selected the one under it); Delete deletes it.
			mTreeMenuListener = mTree.AddEventListener(.ContextMenu, new (e) =>
				{
					if ((mServices.Operations != null) && (mCurrent != null) && Contains(mCurrent))
						ShowGroupMenu(mTree, ((MouseEvent)e).Position, mCurrent, true);
					e.Handled = true;
				});
			mTreeKeyListener = mTree.AddEventListener(.KeyDown, new (e) =>
				{
					let key = (KeyEvent)e;
					// The tree's own: an edit's field keeps its Delete.
					if ((e.Target === mTree) && ((KeyCode)key.KeyCode == .Delete) && (key.Modifiers == 0) && (mCurrent != null) && Contains(mCurrent))
					{
						ConfirmDeleteGroup(mCurrent);
						e.Handled = true;
					}
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
			// A row's menu, or the group's where no row is; Delete asks to delete the selection.
			mListMenuListener = mList.AddEventListener(.ContextMenu, new (e) =>
				{
					let at = ((MouseEvent)e).Position;
					ShowMenuAt(mList, at, mList.ItemAt(at));
					e.Handled = true;
				});
			mListKeyListener = mList.AddEventListener(.KeyDown, new (e) =>
				{
					let key = (KeyEvent)e;
					// The list's own: an edit's field keeps its Delete.
					if ((e.Target === mList) && ((KeyCode)key.KeyCode == .Delete) && (key.Modifiers == 0))
					{
						DeleteSelection();
						e.Handled = true;
					}
				});
		}
		if (let state = Find<UIWidget>("assets-state"))
		{
			mStateMenuListener = state.AddEventListener(.ContextMenu, new [=this, =state] (e) =>
				{
					ShowMenuAt(state, ((MouseEvent)e).Position, -1);
					e.Handled = true;
				});
		}
		mCrumbs = Find<BreadcrumbBar>("assets-crumbs");
		if (mCrumbs != null)
		{
			mCrumbs.SetOnNavigate(new (item) =>
				{
					if (let group = GroupAt(item.Id))
						Navigate(group);
				});
			// Assets dropped on a segment (the current one takes none) move up into that group.
			mCrumbs.SetSegmentDropTypes(AssetDrag.cType);
			mCrumbs.SetOnSegmentDrop(new (item, payload, effect) =>
				{
					if (let group = GroupAt(item.Id))
						Take(payload, group);
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
		// A picture that arrives redraws the cells (the one showing it among them).
		if ((mServices.Context != null) && (mServices.Picture != null))
			mPictureListener = mServices.Context.AddThumbnailListener(new (id) => { mModel.Changed(); });
	}

	/// The panel may hold the content past this view: what of it calls back here goes first.
	public ~this()
	{
		if (mPictureListener != 0)
			mServices.Context.RemoveThumbnailListener(mPictureListener);
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		// An open question would answer into a gone view.
		if ((mConfirm != null) && mConfirm.IsOpen)
			mConfirm.Close();
		if (mList != null)
		{
			if (mList.IsEditing)
				mList.EndEdit(false); // its commit would reach the models going
			mList.RemoveEventListener(mListMenuListener);
			mList.RemoveEventListener(mListKeyListener);
			mList.Model = null;
			mList.SetRowFactory(null);
			mList.SetOnActivated(null);
			mList.SetOnDragPayload(null);
		}
		if (mTree != null)
		{
			if (mTree.IsEditing)
				mTree.EndEdit(false);
			mTree.RemoveEventListener(mTreeMenuListener);
			mTree.RemoveEventListener(mTreeKeyListener);
			mTree.Model = null;
			mTree.SetOnSelectionChanged(null);
		}
		if (let state = Find<UIWidget>("assets-state"))
			state.RemoveEventListener(mStateMenuListener);
		if (mCrumbs != null)
		{
			mCrumbs.SetOnNavigate(null);
			mCrumbs.SetOnSegmentDrop(null);
		}
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
	/// The open menu (the type filter's, a row's, the group's), for a test.
	public Sedulous.GUI.Menu OpenMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;
	/// The delete asked about while it is open, for a test.
	public Sedulous.GUI.MessageBox OpenConfirm => ((mConfirm != null) && mConfirm.IsOpen) ? mConfirm : null;

	/// The menu `row` would show (-1: the group's own), opened at the list's corner.
	public void ShowMenuFor(int32 row)
	{
		if (mList != null)
			ShowMenuAt(mList, mList.ConvertToWorldSpace(.(4.0f, 4.0f)), row);
	}

	/// Asks to delete the selected assets, else the selected group's row (Delete).
	public void DeleteSelection()
	{
		if ((mServices.Operations == null) || (mList == null) || !RowsLive)
			return;
		let selected = scope List<Instance>();
		SelectedAssets(selected);
		if (!selected.IsEmpty)
		{
			let ids = scope List<Guid>();
			for (let instance in selected)
				ids.Add(instance.Id);
			ConfirmDelete(ids);
			return;
		}
		if (let group = RowGroup(mList.SelectedItem))
			ConfirmDeleteGroup(group);
	}

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
			if (mServices.Picture != null)
				shown.Picture = mServices.Picture(instance.Id);
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
		NewMenu();
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

	// === The verbs: renames from the models' edits, the menus, the confirmations ===

	/// A row's new name, from the list's edit: false (said) when it is refused.
	private bool RenameRow(int row, StringView name)
	{
		let ops = mServices.Operations;
		if ((ops == null) || !RowsLive || (row < 0) || (row >= mRows.Count))
			return false;
		if (let group = mRows[row].Group)
			return RenameGroup(group, name);
		let why = scope String();
		if (ops.Rename(mRows[row].Instance.Id, name, why))
			return true;
		Warn(why);
		return false;
	}

	/// A group's new name, from a row's or the tree's edit: false (said) when it is refused.
	private bool RenameGroup(Group group, StringView name)
	{
		let ops = mServices.Operations;
		if (ops == null)
			return false;
		let why = scope String();
		if (ops.RenameGroup(group, name, why))
			return true;
		Warn(why);
		return false;
	}

	private void Warn(StringView text)
	{
		if (mServices.Context != null)
			mServices.Context.Notify(.Warning, text);
	}

	/// The tree is of the database as it is now: its groups are reached only while it is.
	private bool TreeLive
	{
		get
		{
			let db = Sources();
			return (db != null) && (db === mDb) && (db.Revision == mDbRevision);
		}
	}

	/// The group a tree node shows, while the tree is live; null otherwise.
	private Group TreeGroupAt(ModelIndex index)
	{
		if (!TreeLive)
			return null;
		let node = index.InternalId;
		return ((node >= 0) && (node < mTreeGroups.Count)) ? mTreeGroups[(int)node] : null;
	}

	private Instance FindAsset(Guid id)
	{
		let db = Sources();
		return (db != null) ? db.GetInstance(id) : null;
	}

	private void OpenAsset(Guid id)
	{
		if (let instance = FindAsset(id))
		{
			if (mServices.Open != null)
				mServices.Open(instance);
		}
	}

	/// The menu a new one replaces closed and let go; the new one is mMenu.
	private Sedulous.GUI.Menu NewMenu()
	{
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		return mMenu;
	}

	/// A menu's action on `group`, which finds it again by its path when it runs (gone by then:
	/// nothing). TAKES OWNERSHIP of `act`.
	private delegate void() OnGroup(Group group, delegate void(Group found) act)
	{
		let path = group.GetPath(.. new .());
		return new [=this, =path, =act] () =>
			{
				if (let found = GroupAt(path))
					act(found);
			} ~ { delete path; delete act; };
	}

	/// A row's menu at `at` (in the root's space), or the shown group's where no row is.
	private void ShowMenuAt(Node owner, Float2 at, int32 row)
	{
		if ((mServices.Operations == null) || (Sources() == null))
			return;
		if (RowsLive && (row >= 0) && (row < mRows.Count))
		{
			if (let group = mRows[row].Group)
				ShowGroupMenu(owner, at, group, false, mRows[row].Id);
			else
				ShowAssetMenu(owner, at, row);
		}
		else if ((mCurrent != null) && Contains(mCurrent))
			ShowGroupMenu(owner, at, mCurrent, true);
	}

	// An asset's: what acts on one (open, rename, duplicate, copy, pin, export) on it, what acts on
	// many (cook, rebuild, delete) on the selection holding it, else on it alone.
	private void ShowAssetMenu(Node owner, Float2 at, int32 row)
	{
		let id = mRows[row].Instance.Id;
		let rowId = mRows[row].Id;
		let targets = scope List<Guid>();
		let selected = scope List<Instance>();
		SelectedAssets(selected);
		for (let instance in selected)
			targets.Add(instance.Id);
		if (!targets.Contains(id))
		{
			targets.Clear();
			targets.Add(id);
		}
		let ops = mServices.Operations;
		let menu = NewMenu();
		menu.AddItem("Open", new [=this, =id] () => { OpenAsset(id); });
		menu.AddSeparator();
		menu.AddItem("Rename", new [=this, =rowId] () => { BeginRename(rowId); }).Shortcut = "F2";
		menu.AddItem("Duplicate", new [=ops, =id] () => { ops.Duplicate(id); });
		menu.AddSeparator();
		// The OS clipboard: the guid as a script writes it (hyphened, no braces) and the content
		// path, for pasting into scripts and docs.
		menu.AddItem("Copy GUID", new [=this, =id] () => { CopyText(id.ToString(.. scope .(), 'D'), "GUID"); });
		menu.AddItem("Copy Path", new [=this, =id] () =>
			{
				if (let instance = FindAsset(id))
					CopyText(instance.GetPath(.. scope .()), "path");
			});
		let favourite = (mServices.Context != null) && mServices.Context.IsFavorite(id);
		menu.AddItem(favourite ? "Unpin Favourite" : "Pin as Favourite", new [=this, =id] () =>
			{
				if (mServices.Context != null)
					mServices.Context.ToggleFavorite(id);
				mModel.Changed(); // its star
			});
		let always = menu.AddItem("Always Export", new [=ops, =id] () => { ops.ToggleAlwaysExport(id); });
		always.Checkable = true;
		always.SetCheckedSilently(ops.IsAlwaysExported(id));
		menu.AddSeparator();
		let count = targets.Count;
		let cooks = new List<Guid>(targets.GetEnumerator());
		menu.AddItem((count == 1) ? "Cook" : scope:: $"Cook {count} Assets", new [=ops, =cooks] () => { ops.Cook(cooks, false); } ~ delete cooks);
		let rebuilds = new List<Guid>(targets.GetEnumerator());
		menu.AddItem((count == 1) ? "Rebuild" : scope:: $"Rebuild {count} Assets", new [=ops, =rebuilds] () => { ops.Cook(rebuilds, true); } ~ delete rebuilds);
		menu.AddSeparator();
		let deletes = new List<Guid>(targets.GetEnumerator());
		menu.AddItem((count == 1) ? "Delete..." : scope:: $"Delete {count} Assets...", new [=this, =deletes] () => { ConfirmDelete(deletes); } ~ delete deletes).Shortcut = "Del";
		menu.Open(owner, at);
	}

	// A group's: a row's, or the one shown (`shown`), which also makes new things in it. The top
	// group is neither renamed, flagged nor deleted, and cooks everything.
	private void ShowGroupMenu(Node owner, Float2 at, Group group, bool shown, ItemId rowId = NoItem)
	{
		let ops = mServices.Operations;
		let menu = NewMenu();
		let top = group.Parent == null;
		if (shown)
		{
			AddNewMenu(menu, group);
			menu.AddItem("New Group", OnGroup(group, new (into) =>
				{
					if (let made = mServices.Operations.CreateGroup(into))
					{
						Rebuild(); // the tree shows it
						Navigate(made);
					}
				}));
			if (mServices.Import != null)
				menu.AddItem("Import...", OnGroup(group, new (into) => { mServices.Import(into); }));
			menu.AddSeparator();
		}
		else
		{
			menu.AddItem("Open", OnGroup(group, new (found) => { Navigate(found); }));
			menu.AddSeparator();
		}
		if (!top)
		{
			menu.AddItem("Rename", OnGroup(group, new [=this, =rowId] (found) => { BeginRenameGroup(found, rowId); })).Shortcut = "F2";
			let always = menu.AddItem("Always Export Its Contents", OnGroup(group, new [=ops] (found) => { ops.ToggleAlwaysExport(found); }));
			always.Checkable = true;
			always.SetCheckedSilently(ops.IsAlwaysExported(group));
			menu.AddSeparator();
			menu.AddItem("Cook Group", OnGroup(group, new [=ops] (found) => { ops.CookGroup(found, false); }));
			menu.AddItem("Rebuild Group", OnGroup(group, new [=ops] (found) => { ops.CookGroup(found, true); }));
			menu.AddSeparator();
			menu.AddItem("Delete Group...", OnGroup(group, new (found) => { ConfirmDeleteGroup(found); }));
		}
		else
		{
			menu.AddItem("Cook All", new [=ops] () => { ops.CookAll(false); });
			menu.AddItem("Rebuild All", new [=ops] () => { ops.CookAll(true); });
		}
		menu.Open(owner, at);
	}

	// New: every creator into the group, those of no category first, then a submenu per category.
	private void AddNewMenu(Sedulous.GUI.Menu menu, Group group)
	{
		let context = mServices.Context;
		if ((mServices.Create == null) || (context == null))
			return;
		let create = menu.AddSubMenu("New");
		let into = group.GetPath(.. scope .());
		EditorAssetCreation.AddCreatorItems(create, context.Creators, true, scope [=this, =into] (sub, creator, inCategory) =>
			{
				let path = new String(into);
				sub.AddItem(creator.Label, new [=this, =creator, =path] () =>
					{
						let found = GroupAt(path);
						if ((found != null) && (mServices.Create != null))
							mServices.Create(creator, found);
					} ~ delete path);
			});
	}

	/// Edits the name of the row `rowId` names in place, once the menu that asked has closed (its
	/// close gives the focus back to the list, which would end an edit begun before it).
	private void BeginRename(ItemId rowId)
	{
		Later(new [=this, =rowId] () =>
			{
				if ((mList == null) || !RowsLive)
					return;
				for (int32 row < (int32)mRows.Count)
				{
					if (mRows[row].Id != rowId)
						continue;
					mList.SelectedItem = row;
					mList.BeginEdit(row);
					return;
				}
			});
	}

	/// A group's row in place (`rowId`), else its node in the tree, once the menu has closed.
	private void BeginRenameGroup(Group group, ItemId rowId)
	{
		if (rowId != NoItem)
		{
			BeginRename(rowId);
			return;
		}
		let path = group.GetPath(.. new .());
		Later(new [=this, =path] () =>
			{
				let found = GroupAt(path);
				if ((mTree == null) || (found == null) || !TreeLive)
					return;
				for (int node < mTreeGroups.Count)
				{
					if (mTreeGroups[node] !== found)
						continue;
					for (int32 item < (int32)mTree.GetItemCount())
					{
						if (mTree.GetItemIndex(item).InternalId == node)
							mTree.BeginEdit(item);
					}
				}
			} ~ delete path);
	}

	/// `work` at the GUI's next drain; at once in no GUI. TAKES OWNERSHIP of `work`.
	private void Later(delegate void() work)
	{
		let queue = (mContent != null) ? mContent.MutationQueue : null;
		if (queue == null)
		{
			defer delete work;
			work();
			return;
		}
		queue.Enqueue(work);
	}

	private void CopyText(StringView text, StringView what)
	{
		let dispatcher = (mContent != null) ? mContent.EventDispatcher : null;
		if (mServices.Context != null)
			mServices.Context.CopyText((dispatcher != null) ? dispatcher.Clipboard : null, text, what);
	}

	// Asks first, naming what goes and what follows; Delete deletes. Borrows `ids`.
	private void ConfirmDelete(Span<Guid> ids)
	{
		let ops = mServices.Operations;
		if (ids.IsEmpty || (ops == null))
			return;
		let one = ids.Length == 1;
		let names = ops.Names(ids, .. scope .());
		let message = scope String();
		message.AppendF("Delete {}? {} source {} and cooked {} go, and {} open pages close.", names, one ? "Its" : "Their",
			one ? "file" : "files", one ? "product" : "products", one ? "its" : "their");
		let targets = new List<Guid>();
		targets.AddRange(ids);
		Confirm(one ? "Delete Asset" : scope:: $"Delete {ids.Length} Assets", message,
			new [=ops, =targets] () => { ops.Delete(targets); } ~ delete targets);
	}

	private void ConfirmDeleteGroup(Group group)
	{
		if ((group.Parent == null) || (mServices.Operations == null))
			return;
		let count = AssetOperations.CountAssets(group);
		let message = scope String();
		if (count == 0)
			message.AppendF("Delete the empty group {}?", group.Name);
		else if (count == 1)
			message.AppendF("Delete the group {} and the asset in it? Its source file and cooked product go, and its open page closes.", group.Name);
		else
			message.AppendF("Delete the group {} and the {} assets in it? Their source files and cooked products go, and their open pages close.", group.Name, count);
		// What shows it moves to its parent before it goes.
		Confirm("Delete Group", message, OnGroup(group, new (found) =>
			{
				mServices.Operations.DeleteGroup(found, new (next) => { Navigate(next); });
			}));
	}

	/// Asks `title` with `message`, Cancel or Delete; Delete runs `yes`. Nothing when there is no
	/// GUI to ask over, or a question is open already. TAKES OWNERSHIP of `yes`.
	private void Confirm(StringView title, StringView message, delegate void() yes)
	{
		let root = (mContent != null) ? mContent.RootNode : null;
		if (!(root is SceneRoot) || ((mConfirm != null) && mConfirm.IsOpen))
		{
			delete yes;
			return;
		}
		if (mConfirm != null)
			mConfirm.ReleaseRef();
		let question = new Sedulous.GUI.MessageBox();
		mConfirm = question;
		question.Configure(title, message, .Ok);
		question.ClearButtons();
		question.AddButton("Cancel", "cancel", .Cancel);
		question.AddButton("Delete", "delete", .Destructive);
		question.AddEventListener(.Changed, new [=question, =yes] (e) =>
			{
				if (question.ResultName == "delete")
					yes();
			} ~ delete yes);
		question.OpenModal(root);
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

	/// Whether the assets a drag carries can move into `group`: when they can, "Move into" and the
	/// group's name set into `outWhy`; when not, why (nothing when it carries no assets).
	private bool CanTake(DragPayload payload, Group group, String outWhy)
	{
		outWhy.Clear();
		let ops = mServices.Operations;
		let ids = scope List<Guid>();
		if ((ops == null) || !DraggedIds(payload, ids) || !ops.CanMove(ids, group, outWhy))
			return false;
		outWhy.AppendF("Move into {}", (group.Parent == null) ? (StringView)cTopGroup : group.Name);
		return true;
	}

	/// Moves the assets a drag carries into `group`; false, nothing moved, when CanTake refuses.
	private bool Take(DragPayload payload, Group group)
	{
		if (!CanTake(payload, group, scope .()))
			return false;
		let ids = scope List<Guid>();
		DraggedIds(payload, ids);
		mServices.Operations.MoveTo(ids, group);
		return true;
	}

	/// The guids of the assets `payload` carries, in order, added to `outIds`; false when it
	/// carries none.
	private static bool DraggedIds(DragPayload payload, List<Guid> outIds)
	{
		let assets = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(assets); }
		if (!AssetDrag.ReadAll(payload, assets))
			return false;
		for (let asset in assets)
			outIds.Add(asset.Id);
		return true;
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
