using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// An asset slot's pick, shaped as the assets browser (Raptor's editor-gui spec, ruling 24; the
// mock's asset-picker.xml): the project's groups a tree at its side (Favourites and All first),
// what the chosen group holds of the slot's types beside it as tiles or a list (the last one chosen
// kept with the project), the current value lit, the search over every group while it has text (by
// name or a guid's start, as the browser's; each match saying where it lives). Enter or a double
// click picks; Esc or its close keeps the value (a slot's own clear sets nothing, so a pick can
// never clear it by a slip). A row's menu pins it as a favourite, or unpins it; a whole guid of an
// asset the slot does not take says so. Its cells are the browser's (AssetCell); it opens
// in the window's middle, as every picker does. A type is taken by its full or its short name
// (AssetTypeNames.Matches), and none named, or AssetPickerSlot.cAnyAsset among them, takes any.

/// What an asset slot asks the picker for.
class AssetPickRequest
{
	/// The asset types it takes, by name (full or short); empty: any.
	public List<String> Types = new .() ~ DeleteContainerAndItems!(_);
	/// Its value now (nil: none).
	public Guid Current = .Empty;
	/// A pick (nil: None). OWNED: it goes with the request.
	public delegate void(Guid id) Chosen ~ delete _;
}

/// What the asset picker works over.
class AssetPickerServices
{
	/// The project, the favourites, the project's editor store. Not owned.
	public EditorContext Context = null;
	/// A type's glyph; null: generic ones. Not owned.
	public EditorIcons Icons = null;
	/// An asset's picture (the thumbnails'), null while there is none; null: glyphs only.
	public delegate Sedulous.GUI.Drawable(Guid id) Picture ~ delete _;
}

class AssetPickerWindow
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/AssetPicker.xml";
	private const int cFavourites = 0;
	private const int cAll = 1;
	private const float cTileWidth = 96.0f;
	private const float cTileHeight = 92.0f;

	// A row of the tree, by its node: Favourites, All, or a group.
	private class Source
	{
		public String Name = new .() ~ delete _;
		/// Null: Favourites or All. Reached only while the tree is of the database as it is.
		public Group Group = null;
	}

	// The rows as the list's model, an asset's id its guid's.
	private class RowModel : IModel
	{
		private AssetPickerWindow mOwner;

		public this(AssetPickerWindow owner) { mOwner = owner; }

		public override int RowCount(ModelIndex parent) => (parent.IsValid || !mOwner.RowsLive) ? 0 : mOwner.mRows.Count;
		public override int ColumnCount() => 1;

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			if ((role != .Display) || !mOwner.RowsLive || (index.Row < 0) || (index.Row >= mOwner.mRows.Count))
				return .();
			return .(mOwner.mRows[index.Row].Name);
		}

		public override ItemId IdOf(ModelIndex index)
		{
			if (!mOwner.RowsLive || (index.Row < 0) || (index.Row >= mOwner.mRows.Count))
				return NoItem;
			return IdOfRow(mOwner.mRows[index.Row]);
		}

		public override ModelIndex IndexOfId(ItemId id)
		{
			if (!mOwner.RowsLive)
				return .();
			for (int32 row < (int32)mOwner.mRows.Count)
			{
				if (IdOfRow(mOwner.mRows[row]) == id)
					return Index(row);
			}
			return .();
		}

		public static ItemId IdOfRow(Instance instance)
		{
			var id = instance.Id;
			let words = (uint64*)&id;
			return (words[0] ^ (words[1] * 31)) >> 1;
		}

		public void Reset() => NotifyReset();

		public void Changed()
		{
			if (!mOwner.mRows.IsEmpty)
				NotifyRowsChanged(.(), 0, (int32)mOwner.mRows.Count);
		}
	}

	/// A reference of ours: closed, it leaves the tree, and this keeps it for the next open.
	/// Declared first: it goes last, after the models the list and the tree it holds borrow.
	private Node mContent ~ _?.ReleaseRef();
	private AssetPickerServices mServices ~ delete _;
	/// BORROWED: what it opened over, last.
	private SceneRoot mRoot = null;
	// The frame's: the tree holds them.
	private TextField mSearch = null;
	private TreeView mTree = null;
	private ListView mList = null;
	private Sedulous.GUI.Label mWhere = null;
	private Sedulous.GUI.Label mState = null;
	private Sedulous.GUI.Label mHint = null;
	private TreeModel mGroups = new .() ~ delete _;
	/// By the tree's node.
	private List<Source> mSources = new .() ~ DeleteContainerAndItems!(_);
	private List<Instance> mRows = new .() ~ delete _;
	private RowModel mModel ~ delete _;
	/// What it was opened with last; an empty one before.
	private AssetPickRequest mRequest = new .() ~ delete _;
	private String mQuery = new .() ~ delete _;
	private int mSource = cAll;
	private bool mTiles = false;
	/// The tree being built or selected from code: no choice of the user's.
	private bool mBuilding = false;
	/// The database and revision the tree's groups and the rows were collected at: a group or a
	/// row is reached only while both hold, so a delete while it is open never reaches a freed one.
	private ContentDatabase mTreeDb = null;
	private uint64 mTreeRevision = 0;
	private ContentDatabase mRowsDb = null;
	private uint64 mRowsRevision = 0;
	private uint32 mKeyListener = 0;
	private uint32 mListMenuListener = 0;
	/// A row's menu (a reference of ours).
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	/// The context's thumbnail listener; 0: none.
	private uint64 mThumbnails = 0;

	/// The picker in `content` (the markup's `asset-picker-search`, `asset-picker-tiles`,
	/// `asset-picker-list`, `asset-picker-groups`, `asset-picker-where`, `asset-picker-items`,
	/// `asset-picker-state`, `asset-picker-hint` and `asset-picker-close`, by id). TAKES OWNERSHIP
	/// of `services` and of a reference to `content`; null makes a picker that never opens.
	public this(AssetPickerServices services, Node content)
	{
		mServices = services;
		mContent = content;
		mModel = new RowModel(this);
		if (mContent == null)
			return;
		mSearch = Find<TextField>("asset-picker-search");
		mTree = Find<TreeView>("asset-picker-groups");
		mList = Find<ListView>("asset-picker-items");
		mWhere = Find<Sedulous.GUI.Label>("asset-picker-where");
		mState = Find<Sedulous.GUI.Label>("asset-picker-state");
		mHint = Find<Sedulous.GUI.Label>("asset-picker-hint");
		if (mSearch != null)
			mSearch.SetOnTextChanging(new (text) => { Search(text); });
		if (mTree != null)
		{
			mTree.Model = mGroups;
			mTree.SetOnSelectionChanged(new (index) =>
				{
					if (mBuilding || !index.IsValid)
						return;
					mSource = (int)index.InternalId;
					BuildRows();
				});
		}
		if (mList != null)
		{
			let rows = new RowFactory();
			rows.TypeOf = new (index) => mTiles ? (uint32)0 : (uint32)1;
			rows.Create = new (type) => new AssetCell(type == 0);
			rows.Bind = new (cell, index) => { BindCell(cell, index.Row); };
			mList.SetRowFactory(rows);
			mList.Model = mModel;
			mList.SetOnActivated(new (index) => { PickRow(index.Row); });
			mListMenuListener = mList.AddEventListener(.ContextMenu, new (e) =>
				{
					let at = ((MouseEvent)e).Position;
					ShowRowMenu(mList.ItemAt(at), at);
					e.Handled = true;
				});
		}
		if (let tiles = Find<Sedulous.GUI.Button>("asset-picker-tiles"))
			tiles.SetOnClick(new () => { SetTiles(true); });
		if (let list = Find<Sedulous.GUI.Button>("asset-picker-list"))
			list.SetOnClick(new () => { SetTiles(false); });
		if (let close = CloseButton)
			close.SetOnClick(new () => { Close(); });
		// The arrows and Enter before the search takes them; in tiles Up and Down cross a row.
		mKeyListener = mContent.AddEventListener(.KeyDown, new (e) =>
			{
				let key = (KeyEvent)e;
				let code = (Sedulous.GUI.KeyCode)key.KeyCode;
				if (key.Modifiers != 0)
					return;
				let across = (mTiles && (mList != null)) ? Math.Max(1, mList.ColumnsAcross) : 1;
				if ((code == .Down) || (code == .Up))
				{
					Step((code == .Down) ? across : -across);
					e.Handled = true;
				}
				else if (mTiles && ((code == .Right) || (code == .Left)))
				{
					Step((code == .Right) ? 1 : -1);
					e.Handled = true;
				}
				else if ((code == .Return) || (code == .KeypadEnter))
				{
					PickLit();
					e.Handled = true;
				}
			}, true);
		// A picture that arrives redraws the cells (the one showing it among them).
		if ((mServices.Context != null) && (mServices.Picture != null))
			mThumbnails = mServices.Context.AddThumbnailListener(new (id) =>
				{
					if (IsOpen)
						mModel.Changed();
				});
	}

	/// The content may outlive this: what of it calls back here goes first.
	public ~this()
	{
		Close();
		if (mThumbnails != 0)
			mServices.Context.RemoveThumbnailListener(mThumbnails);
		if (mContent != null)
			mContent.RemoveEventListener(mKeyListener);
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mList != null)
		{
			mList.RemoveEventListener(mListMenuListener);
			mList.Model = null;
			mList.SetRowFactory(null);
		}
		if (mTree != null)
			mTree.Model = null;
	}

	/// A row's menu at `at` (world space, a pointer's): Pin as Favourite, or Unpin Favourite. No
	/// row, or no context: none.
	public void ShowRowMenu(int32 row, Float2 at)
	{
		if ((mList == null) || (mServices.Context == null) || (row < 0) || (row >= mRows.Count))
			return;
		let id = mRows[row].Id;
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		mMenu.AddItem(mServices.Context.IsFavorite(id) ? "Unpin Favourite" : "Pin as Favourite", new [=this, =id] () =>
			{
				mServices.Context.ToggleFavorite(id);
				if ((mSource == cFavourites) && mQuery.IsEmpty)
					BuildRows(); // it joins or leaves the rows
				else
					mModel.Changed(); // its star
			});
		mMenu.Open(mList, mList.RootNode.ConvertToNodeSpace(at)); // a menu opens in the root's space
	}

	/// The row menu, while it is open.
	public Sedulous.GUI.Menu RowMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// Opens it over `root` for `request`, in the window's middle: the current value's group
	/// chosen (else All) and its row lit, the search empty and focused, tiles or a list as it was
	/// left. False with no frame, no project, a root in no GUI, or one open already. OWNERSHIP of
	/// `request` transfers, opened or not.
	public bool Open(SceneRoot root, AssetPickRequest request)
	{
		let dispatcher = root.EventDispatcher;
		let db = Sources();
		if ((mContent == null) || (dispatcher == null) || IsOpen || (db == null))
		{
			delete request;
			return false;
		}
		mRoot = root;
		delete mRequest;
		mRequest = request;
		mQuery.Clear();
		mTiles = StoredTiles();
		let noun = Noun(.. scope .());
		if (mSearch != null)
		{
			mSearch.Placeholder = scope String()..AppendF("Search {}", Lowered(noun, .. scope .()));
			mSearch.Text = default;
		}
		BuildTree();
		let current = mRequest.Current.IsNil ? null : db.GetInstance(mRequest.Current);
		mSource = cAll;
		if (current != null)
		{
			for (int i < mSources.Count)
			{
				if (mSources[i].Group === current.OwningGroup)
					mSource = i;
			}
		}
		SelectSource(mSource);
		ShowLayout();
		BuildRows();
		if (mHint != null)
		{
			if (current != null)
				mHint.Text = scope String()..AppendF("Enter picks, Esc keeps {}", current.Name);
			else
				mHint.Text = "Enter picks, Esc closes";
		}
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

	/// Tiles or a list, kept with the project for the next pick.
	public void SetTiles(bool tiles)
	{
		mTiles = tiles;
		let context = mServices.Context;
		if (let store = (context != null) ? context.ProjectEditorSettings : null)
		{
			store.Section<EditorAssetBrowserSettings>().PickerGridMode = tiles;
			store.MarkChanged<EditorAssetBrowserSettings>();
			context.RequestProjectEditorSettingsSave();
		}
		ShowLayout();
	}

	/// Searches every group for `text` (as typing it); empty: the chosen group again.
	public void Search(StringView text)
	{
		if (mQuery == text)
			return;
		mQuery.Set(text);
		if ((mSearch != null) && (mSearch.Text != text))
			mSearch.Text = text;
		BuildRows();
	}

	/// Chooses the group whose tree row reads `name` (as a click on it); false when none does.
	public bool ChooseSource(StringView name)
	{
		for (int i < mSources.Count)
		{
			if (mSources[i].Name == name)
			{
				mSource = i;
				SelectSource(i);
				BuildRows();
				return true;
			}
		}
		return false;
	}

	/// Picks the lit row; with none lit, nothing.
	public void PickLit() => PickRow((mList != null) ? mList.SelectedItem : -1);

	/// Moves the light `by` rows, kept within them.
	public void Step(int32 by)
	{
		if ((mList == null) || mRows.IsEmpty || !RowsLive)
			return;
		let lit = mList.SelectedItem;
		Light((lit < 0) ? 0 : Math.Clamp(lit + by, 0, (int32)mRows.Count - 1));
	}

	/// Whether an asset of type `typeName` (full or short) is one `types` takes.
	public static bool Takes(StringView typeName, Span<String> types)
	{
		for (let type in types)
		{
			if (type == AssetPickerSlot.cAnyAsset)
				return true;
		}
		return types.IsEmpty || AssetPickerSlot.Accepts(types, typeName);
	}

	// === What it shows (for tests) ===

	public Node Content => mContent;
	public bool ShowsTiles => mTiles;
	public ListView List => mList;
	public Sedulous.GUI.Button CloseButton => Find<Sedulous.GUI.Button>("asset-picker-close");

	/// The tree's rows by name, in order ("Favourites | All Materials | Content | Props").
	public void Groups(String outText)
	{
		for (let source in mSources)
		{
			if (!outText.IsEmpty)
				outText.Append(" | ");
			outText.Append(source.Name);
		}
	}

	/// The rows shown by name, in order ("Wood | Wool").
	public void Rows(String outText)
	{
		if (!RowsLive)
			return;
		for (let row in mRows)
		{
			if (!outText.IsEmpty)
				outText.Append(" | ");
			outText.Append(row.Name);
		}
	}

	public StringView Where => (mWhere != null) ? mWhere.Text : default;
	public StringView Hint => (mHint != null) ? mHint.Text : default;
	public StringView StateText => ((mState != null) && mState.Displayed) ? mState.Text : default;

	public StringView LitName
	{
		get
		{
			let lit = (mList != null) ? mList.SelectedItem : -1;
			return (RowsLive && (lit >= 0) && (lit < mRows.Count)) ? (StringView)mRows[lit].Name : default;
		}
	}

	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private ContentDatabase Sources()
	{
		let project = (mServices.Context != null) ? mServices.Context.Project : null;
		return (project != null) ? project.SourceDb : null;
	}

	/// The tree's groups are of the database as it is now.
	private bool TreeLive
	{
		get
		{
			let db = Sources();
			return (db != null) && (db === mTreeDb) && (db.Revision == mTreeRevision);
		}
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

	private bool StoredTiles()
	{
		let context = mServices.Context;
		if (let store = (context != null) ? context.ProjectEditorSettings : null)
		{
			if (let section = store.Find<EditorAssetBrowserSettings>())
				return section.PickerGridMode;
		}
		return false;
	}

	/// The Beef type an asset type name names, full or short (a short one by an asset of it in
	/// the project); null when none does.
	private Type TypeOf(StringView typeName)
	{
		let context = mServices.Context;
		if (context == null)
			return null;
		if (let type = context.Pages.ResolveType(typeName))
			return type;
		let db = Sources();
		if (db == null)
			return null;
		let pending = scope List<Group>();
		pending.Add(db.RootGroup);
		while (!pending.IsEmpty)
		{
			let group = pending.PopBack();
			for (let instance in group.Instances)
			{
				if (AssetTypeNames.Matches(instance.TypeName, typeName))
					return context.Pages.ResolveType(instance.TypeName);
			}
			for (let child in group.Groups)
				pending.Add(child);
		}
		return null;
	}

	/// What an asset type is called to the user, appended: its [DisplayName], else its short
	/// name.
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

	// What the slot takes, plural, by its type's display name ("Materials", "Meshes"); more than
	// one type, or any, "Assets". Appended.
	private void Noun(String outNoun)
	{
		if ((mRequest.Types.Count != 1) || (mRequest.Types[0] == AssetPickerSlot.cAnyAsset))
		{
			outNoun.Append("Assets");
			return;
		}
		let name = KindOf(mRequest.Types[0], .. scope .());
		if (name.EndsWith("s") || name.EndsWith("x") || name.EndsWith("sh") || name.EndsWith("ch"))
		{
			outNoun.AppendF("{}es", name);
			return;
		}
		let before = (name.Length >= 2) ? name[name.Length - 2] : 'a';
		let vowel = (before == 'a') || (before == 'e') || (before == 'i') || (before == 'o') || (before == 'u');
		if (name.EndsWith("y") && !vowel) // "Body", "Bodies"; "Key", "Keys"
		{
			outNoun.AppendF("{}ies", StringView(name, 0, name.Length - 1));
			return;
		}
		outNoun.AppendF("{}s", name);
	}

	private static void Lowered(StringView text, String outText)
	{
		outText.Append(text);
		outText.ToLower();
	}

	/// Where `group` is as the user reads it ("Content", "Content/Models/Town"), appended.
	private static void ShownPath(Group group, String outPath)
	{
		outPath.Append(AssetsView.cTopGroup);
		if (group.Parent == null)
			return;
		outPath.Append('/');
		outPath.Append(group.GetPath(.. scope .())); // GetPath clears what it is given
	}

	// Favourites, All, then the project's groups (the top one Content), every one open.
	private void BuildTree()
	{
		if (mTree == null)
			return;
		mBuilding = true;
		mGroups.Clear();
		ClearAndDeleteItems!(mSources);
		AddSource(mGroups.AddNode(TreeModel.Root, "Favourites"), "Editor/Icons/star.svg", "Favourites", null);
		let all = scope String()..AppendF("All {}", Noun(.. scope .()));
		AddSource(mGroups.AddNode(TreeModel.Root, all), "Editor/Icons/layers.svg", all, null);
		let db = Sources();
		if (db != null)
			AddGroup(db.RootGroup, TreeModel.Root);
		mTreeDb = db;
		mTreeRevision = (db != null) ? db.Revision : 0;
		for (int node < mSources.Count)
			mTree.SetIdExpanded((ItemId)node, true);
		mBuilding = false;
	}

	private void AddSource(int32 node, StringView icon, StringView name, Group group)
	{
		mGroups.SetIcon(node, icon);
		while (mSources.Count <= node)
			mSources.Add(new Source());
		mSources[node].Name.Set(name);
		mSources[node].Group = group;
	}

	private void AddGroup(Group group, int32 parent)
	{
		let name = (group.Parent == null) ? (StringView)AssetsView.cTopGroup : group.Name;
		let node = mGroups.AddNode(parent, name);
		AddSource(node, "Editor/Icons/folder.svg", name, group);
		for (let child in group.Groups)
			AddGroup(child, node);
	}

	private void SelectSource(int source)
	{
		if (mTree == null)
			return;
		let building = mBuilding;
		mBuilding = true; // a selection from code is no choice
		for (int32 item < (int32)mTree.GetItemCount())
		{
			if (mTree.GetItemIndex(item).InternalId == source)
				mTree.SelectedItem = item; // every group is open: each is an item
		}
		mBuilding = building;
	}

	// What the chosen source holds of the slot's types, in the groups' order; a search's matches
	// from every group; then the count and the state. A group the database has moved on from is
	// never reached: All in its place.
	private void BuildRows()
	{
		mRows.Clear();
		let db = Sources();
		if (db != null)
		{
			let group = (TreeLive && (mSource >= 0) && (mSource < mSources.Count)) ? mSources[mSource].Group : null;
			if (!mQuery.IsEmpty || (mSource == cAll) || ((mSource != cFavourites) && (group == null)))
				Collect(db.RootGroup, true);
			else if ((mSource == cFavourites) && (mServices.Context != null))
			{
				for (let id in mServices.Context.Favorites)
				{
					let instance = db.GetInstance(id);
					if ((instance != null) && Takes(instance.TypeName, mRequest.Types))
						mRows.Add(instance);
				}
			}
			else
				Collect(group, false);
		}
		mRowsDb = db;
		mRowsRevision = (db != null) ? db.Revision : 0;
		mModel.Reset();
		// The current value lit when it is shown, else the first row.
		int32 lit = mRows.IsEmpty ? -1 : 0;
		for (int32 i < (int32)mRows.Count)
		{
			if (mRows[i].Id == mRequest.Current)
				lit = i;
		}
		if (lit >= 0)
			Light(lit);
		let noun = Lowered(Noun(.. scope .()), .. scope .());
		if (mWhere != null)
		{
			let @where = scope String();
			if (!mQuery.IsEmpty)
				@where.AppendF("In every group  ·  {} {}", mRows.Count, noun);
			else if (mSource < mSources.Count)
				@where.AppendF("{}  ·  {} {}", mSources[mSource].Name, mRows.Count, noun);
			else
				@where.AppendF("{} {}", mRows.Count, noun);
			mWhere.Text = @where;
		}
		if (mState != null)
		{
			mState.Displayed = mRows.IsEmpty;
			if (let other = WrongTypeNamed())
				mState.Text = scope String()..AppendF("'{}' is a {}, which this slot does not take.", other.Name, KindOf(other.TypeName, .. scope .()));
			else if (!mQuery.IsEmpty)
				mState.Text = scope String()..AppendF("No {} match \"{}\".", noun, mQuery);
			else if (mSource == cFavourites)
				mState.Text = scope String()..AppendF("No favourite {}: star one in the Assets panel.", noun);
			else
				mState.Text = scope String()..AppendF("No {} here.", noun);
		}
	}

	// The asset a search's whole guid names when the slot does not take its type; else null.
	private Instance WrongTypeNamed()
	{
		let db = Sources();
		if (db == null)
			return null;
		if (!AssetFilter.AsGuid(mQuery, let id))
			return null;
		let named = db.GetInstance(id);
		return ((named != null) && !Takes(named.TypeName, mRequest.Types)) ? named : null;
	}

	private void Collect(Group group, bool deep)
	{
		for (let instance in group.Instances)
		{
			if (Takes(instance.TypeName, mRequest.Types) && (mQuery.IsEmpty || AssetFilter.Matches(instance, mQuery)))
				mRows.Add(instance);
		}
		if (deep)
		{
			for (let child in group.Groups)
				Collect(child, true);
		}
	}

	// Rows from more than one group say where each lives.
	private bool RowsSayWhere => !mQuery.IsEmpty || (mSource == cAll) || (mSource == cFavourites);

	private void BindCell(Node node, int32 index)
	{
		let cell = node as AssetCell;
		if ((cell == null) || !RowsLive || (index < 0) || (index >= mRows.Count))
			return;
		let instance = mRows[index];
		AssetCell.Shown shown = default;
		shown.Name = instance.Name;
		let kind = KindOf(instance.TypeName, .. scope .());
		if (RowsSayWhere)
		{
			kind.Append(" in ");
			ShownPath(instance.OwningGroup, kind);
		}
		shown.Kind = kind;
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
		shown.HidesStateColumns = true; // a pick asks neither its cook nor its export
		shown.Favourite = (mServices.Context != null) && mServices.Context.IsFavorite(instance.Id);
		if (mServices.Picture != null)
			shown.Picture = mServices.Picture(instance.Id); // a tile's, and a row's small
		cell.Show(shown);
		// Hovered, the whole of where it lives (a row's is cut to fit) and what it is.
		let tip = scope String();
		ShownPath(instance.OwningGroup, tip);
		tip.AppendF("/{} ({})", instance.Name, KindOf(instance.TypeName, .. scope .()));
		cell.Tooltip = tip;
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
		Check("asset-picker-tiles", mTiles);
		Check("asset-picker-list", !mTiles);
	}

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

	private void Light(int32 row)
	{
		if ((mList == null) || (row < 0))
			return;
		mList.SelectedItem = row; // scrolled into view
	}

	private void PickRow(int32 row)
	{
		if (RowsLive && (row >= 0) && (row < mRows.Count))
			Pick(mRows[row].Id);
	}

	private void Pick(Guid id)
	{
		let chosen = mRequest.Chosen;
		mRequest.Chosen = null; // ours until it has answered
		Close();
		if (chosen != null)
			chosen(id);
		delete chosen;
	}
}
