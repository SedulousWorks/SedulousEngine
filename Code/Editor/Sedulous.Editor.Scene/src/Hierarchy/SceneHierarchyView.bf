using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// The entity tree inside a scene page, one per page (everything scene-scoped is the page's), on
// the GUI's TreeView (Raptor's editor-gui spec, 5.3, layer 3). Its model is built again from the
// live scene when the scene's revision moves, so every edit, undo and redo shows; a row's id is
// its entity's guid, so the selection and what is open survive each build.
//   - The scene is the top row (ruling 12: its settings are the scene selected); each entity by
//     its first component's type icon, a prefab's members and inactive entities marked as such.
//   - The selection is the page's, shared with the viewport both ways, several at once.
//   - A double-click frames the entity; F2 renames in place; dragging a row onto another
//     reparents it, between two reorders it, onto the scene's row makes it a root.
//   - The row menu, the background menu, the add button and Delete are the scene editor's
//     actions over the page, one path, so they are refused visibly while it simulates.
//   - The search keeps a match's ancestors; a whole guid selects that entity and opens its way.
//   - A dragged row carries its entities, for an entity slot; a prefab dropped in is spawned,
//     under the row it lands on.

/// What a drag of entities carries (a hierarchy's rows), for an entity slot to take.
///
/// The value is one text, the guids one to a line, where Raptor carries a list of strings: a
/// payload's Variant frees only the object it owns, so a list would leak its texts (AssetDrag's
/// reason).
static class EntityDrag
{
	public const String cType = "scene/entity";

	/// Fills `outPayload` with what dragging `entities` carries, labelled by `name` (the first's)
	/// or their count.
	public static void Payload(Span<Guid> entities, StringView name, DragPayload outPayload)
	{
		let text = scope String();
		for (let id in entities)
		{
			id.ToString(text, 'D');
			text.Append('\n');
		}
		outPayload.Type.Set(cType);
		outPayload.Value.Dispose();
		outPayload.Value = TextVariant(text);
		outPayload.Label.Clear();
		if (entities.Length == 1)
			outPayload.Label.Append(name);
		else
			outPayload.Label.AppendF("{} entities", entities.Length);
		outPayload.Allowed = DropEffectsLink | DropEffectsMove;
	}

	/// The entities `payload` carries, appended to `outEntities`; false when it carries none.
	public static bool Read(DragPayload payload, List<Guid> outEntities)
	{
		if ((payload.Type != cType) || !IsText(payload.Value))
			return false;
		let count = outEntities.Count;
		for (let line in TextOf(payload.Value).Split('\n', .RemoveEmptyEntries))
		{
			if (Guid.Parse(line) case .Ok(let id))
				outEntities.Add(id);
		}
		return outEntities.Count > count;
	}
}

/// What a hierarchy asks of its page. The hooks are its own; the rest is borrowed.
class SceneHierarchyServices
{
	public EditorContext Context = null;
	/// The page its actions run over.
	public EditorPage Page = null;
	/// The entities' type icons; null: none.
	public EditorIcons Icons = null;
	/// The top row's icon.
	public String SceneIcon = new .() ~ delete _;
	/// The top row's text.
	public delegate StringView() SceneName ~ delete _;
	/// A double-click frames an entity.
	public delegate void(Guid entity) Frame ~ delete _;
	/// A prefab dropped in, under `parent` (nil: the scene's root); false when it was not.
	public delegate bool(Guid prefab, Guid parent) SpawnPrefab ~ delete _;
}

class SceneHierarchyView
{
	/// The scene's row: an id no entity's guid gives (they are masked apart from it).
	private const ItemId cSceneRowId = 0x5ce4e0000000001UL;

	// The tree's model over the rows as built: the scene's row (node 0), its entities under it.
	// A row's id is its entity's guid (the scene's row a fixed one), so the view keeps what is
	// open and selected across builds; a build tells the view once.
	private class Model : IModel
	{
		private SceneHierarchyView mView;

		public this(SceneHierarchyView view) { mView = view; }

		public override int RowCount(ModelIndex parent)
		{
			if (!parent.IsValid)
				return mView.mRows.IsEmpty ? 0 : 1;
			let node = parent.InternalId;
			return ((node >= 0) && (node < mView.mRows.Count)) ? mView.mRows[(int)node].Children.Count : 0;
		}

		public override int ColumnCount() => 1;

		public override ModelIndex Index(int32 row, int32 column, ModelIndex parent)
		{
			if (!parent.IsValid)
				return ((row == 0) && !mView.mRows.IsEmpty) ? MakeModelIndex(0, column, 0) : .();
			let node = parent.InternalId;
			if ((node < 0) || (node >= mView.mRows.Count))
				return .();
			let children = mView.mRows[(int)node].Children;
			return ((row >= 0) && (row < children.Count)) ? MakeModelIndex(row, column, children[row]) : .();
		}

		public override ModelIndex ParentIndex(ModelIndex child)
		{
			let node = child.InternalId;
			if ((node <= 0) || (node >= mView.mRows.Count))
				return .();
			let parent = mView.mRows[(int)node].Parent;
			return (parent >= 0) ? MakeModelIndex(mView.mRows[parent].RowInParent, 0, parent) : .();
		}

		public override ItemId IdOf(ModelIndex index)
		{
			if (!index.IsValid)
				return NoItem;
			return IdOfEntity(mView.EntityOfNode(index.InternalId));
		}

		public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
		{
			let node = index.InternalId;
			if ((node < 0) || (node >= mView.mRows.Count))
				return .();
			let row = mView.mRows[(int)node];
			switch (role)
			{
			case .Display, .Sort: return .(row.Name);
			case .Icon: return row.Icon.IsEmpty ? .() : .(row.Icon);
			case .IconClass: return row.IconClass.IsEmpty ? .() : .(row.IconClass);
			case .RowClass: return row.Classes.IsEmpty ? .() : .(row.Classes);
			default: return .();
			}
		}

		/// An entity's name is edited in place (F2, the menu's Rename); the scene's row is not.
		public override bool IsEditable(ModelIndex index) => !mView.EntityOfNode(index.InternalId).IsNil;

		/// The rename, one undo; refused for an empty name.
		public override bool SetData(ModelIndex index, Sedulous.GUI.Variant value)
		{
			let entity = mView.EntityOfNode(index.InternalId);
			let name = value.AsString;
			if (entity.IsNil || name.IsEmpty)
				return false;
			mView.mEdit.RenameEntity(entity, name);
			return true;
		}

		public override DropEffect CanDrop(ModelDrop drop, String reason)
		{
			Guid parent;
			Guid before;
			if (!mView.DropTarget(drop, out parent, out before))
				return .None;
			// The hierarchy's own rows move: never inside themselves.
			if ((drop.Source === this) && !drop.Ids.IsEmpty)
			{
				for (let id in drop.Ids)
				{
					let entity = mView.EntityOfId(id);
					if (entity.IsNil)
					{
						reason.Set("The scene stays where it is");
						return .None;
					}
					if (!parent.IsNil && mView.mEdit.IsSelfOrAncestor(parent, entity))
					{
						reason.Set("An entity cannot go inside itself");
						return .None;
					}
				}
				return .Move;
			}
			// Prefabs from the assets: an instance of each, there.
			let assets = scope List<AssetDrag>();
			defer { ClearAndDeleteItems!(assets); }
			if ((drop.Payload != null) && (mView.mServices.SpawnPrefab != null) && AssetDrag.ReadAll(drop.Payload, assets))
			{
				for (let asset in assets)
				{
					if (!AssetTypeNames.Matches(asset.TypeName, "PrefabDocument"))
					{
						reason.Set("Only a prefab goes into the scene");
						return .None;
					}
				}
				return .Copy;
			}
			return .None;
		}

		public override bool Drop(ModelDrop drop)
		{
			if (CanDrop(drop, scope .()) == .None)
				return false;
			mView.DropTarget(drop, let parent, let before);
			let edit = mView.mEdit;
			if ((drop.Source === this) && !drop.Ids.IsEmpty)
			{
				// What moves, read before the first move builds nothing (the rows are as dropped).
				let moved = scope List<Guid>();
				for (let id in drop.Ids)
					moved.Add(mView.EntityOfId(id));
				for (let entity in moved)
				{
					if ((entity == before) || (entity == parent))
						continue;
					if (!before.IsNil || parent.IsNil)
						edit.MoveEntityBefore(entity, before); // nil before a root: the end of the roots
					else
						edit.ReparentEntity(entity, parent); // the end of the parent's children
				}
				return true;
			}
			let assets = scope List<AssetDrag>();
			defer { ClearAndDeleteItems!(assets); }
			AssetDrag.ReadAll(drop.Payload, assets);
			var spawned = false;
			for (let asset in assets)
				spawned = mView.mServices.SpawnPrefab(asset.Id, parent) || spawned;
			return spawned;
		}

		public void Reset() => NotifyReset();
	}

	private class Row
	{
		/// Nil: the scene's row.
		public Guid Entity;
		public int32 Parent = -1;
		public int32 RowInParent = 0;
		public List<int32> Children = new .() ~ delete _;
		public String Name = new .() ~ delete _;
		/// "member", "inactive".
		public String Classes = new .() ~ delete _;
		public String Icon = new .() ~ delete _;
		public String IconClass = new .() ~ delete _;
	}

	private SceneEditContext mEdit;
	private SceneHierarchyServices mServices ~ delete _;
	private Model mModel ~ delete _;
	/// By node id.
	private List<Row> mRows = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<ItemId, Guid> mEntityOfId = new .() ~ delete _;
	/// Rows built with children before: one new to children opens.
	private HashSet<ItemId> mKnown = new .() ~ delete _;
	private TreeView mTree = null;
	private TextField mSearch = null;
	private Sedulous.GUI.Button mClear = null;
	/// The add button.
	private PageActionBar mBar = null ~ delete _;
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();
	private uint32 mMenuListener = 0;
	private uint32 mKeyListener = 0;
	private String mFilter = new .() ~ delete _;
	private uint64 mRevision = uint64.MaxValue;
	private bool mSyncing = false;
	private bool mBuilt = false;
	/// The first build is done: what gains children from now on opens.
	private bool mOpened = false;

	/// The hierarchy over `edit`'s scene in `pane` (the markup's `hierarchy-tree`,
	/// `hierarchy-search`, `hierarchy-clear`, `hierarchy-add`, by id). `edit` and `pane` are
	/// borrowed and outlive it; `services` it takes.
	public this(SceneEditContext edit, SceneHierarchyServices services, Node pane)
	{
		mEdit = edit;
		mServices = services;
		mModel = new Model(this);
		mTree = Find<TreeView>(pane, "hierarchy-tree");
		mSearch = Find<TextField>(pane, "hierarchy-search");
		mClear = Find<Sedulous.GUI.Button>(pane, "hierarchy-clear");
		if ((mServices.Context != null) && (mServices.Page != null))
		{
			mBar = new PageActionBar(mServices.Context.Actions, mServices.Page);
			mBar.Bind(Find<ButtonBase>(pane, "hierarchy-add"), SceneActionIds.EntityCreate);
		}
		if (mSearch != null)
			mSearch.SetOnTextChanging(new (text) => { Search(text); });
		if (mClear != null)
		{
			mClear.Visible = false;
			mClear.SetOnClick(new () =>
				{
					if (mSearch != null)
						mSearch.Text = "";
					Search("");
				});
		}
		if (mTree != null)
		{
			mTree.SelectionMode = .Multi;
			mTree.Model = mModel;
			mTree.SetOnSelectionChanged(new (index) => { SyncSelectionFromTree(); });
			mTree.SetOnActivated(new (index) =>
				{
					let entity = EntityOfNode(index.InternalId);
					if (!entity.IsNil && (mServices.Frame != null))
						mServices.Frame(entity);
				});
			mTree.DragType = EntityDrag.cType;
			mTree.SetOnDragPayload(new (payload, ids) =>
				{
					let entities = scope List<Guid>();
					for (let id in ids)
					{
						let entity = EntityOfId(id);
						if (!entity.IsNil)
							entities.Add(entity);
					}
					if (!entities.IsEmpty)
						DragOf(entities, payload);
				});
			mMenuListener = mTree.AddEventListener(.ContextMenu, new (e) =>
				{
					let at = ((MouseEvent)e).Position;
					ShowMenu(mTree.ItemAt(at), at);
					e.Handled = true;
				});
			mKeyListener = mTree.AddEventListener(.KeyDown, new (e) =>
				{
					let key = (KeyEvent)e;
					// The tree's own: an edit's field keeps its Delete.
					if (((KeyCode)key.KeyCode == .Delete) && (key.Modifiers == 0) && !mTree.IsEditing)
					{
						RunAction(SceneActionIds.EntityDelete);
						e.Handled = true;
					}
				});
		}
		// The page's selection into the tree (a viewport pick, a marquee, an undo).
		delete mEdit.EntitySelection.OnChanged;
		mEdit.EntitySelection.OnChanged = new () =>
			{
				if (!mSyncing)
					SyncSelectionToTree();
			};
		Refresh();
	}

	/// Lets the selection, the tree and the pane's controls go, before the scene does.
	public ~this()
	{
		DeleteAndNullify!(mEdit.EntitySelection.OnChanged);
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mTree != null)
		{
			mTree.RemoveEventListener(mMenuListener);
			mTree.RemoveEventListener(mKeyListener);
			mTree.SetOnSelectionChanged(null);
			mTree.SetOnActivated(null);
			mTree.SetOnDragPayload(null);
			mTree.Model = null;
		}
		if (mSearch != null)
			mSearch.SetOnTextChanging(null);
		if (mClear != null)
			mClear.SetOnClick(null);
	}

	/// Once a frame: built again when the scene changed; the add button as its action is now.
	public void Refresh()
	{
		if (!mBuilt || (mEdit.Scene.Revision != mRevision))
		{
			mRevision = mEdit.Scene.Revision;
			Build();
		}
		if (mBar != null)
			mBar.Sync();
	}

	/// The search, as typing it does.
	public void Search(StringView text)
	{
		if ((mFilter == text) && mBuilt)
			return;
		mFilter.Set(text);
		if (mClear != null)
			mClear.Visible = !mFilter.IsEmpty;
		// A whole guid asks for that entity: shown with its way open, selected and scrolled to.
		let scene = mEdit.Scene;
		let whole = SearchFilter.FilterAsGuid(mFilter, let wanted) && scene.IsValid(scene.FindEntity(wanted));
		Build();
		if (whole)
		{
			OpenWayTo(wanted);
			mEdit.EntitySelection.Set(wanted);
		}
	}

	/// The in-place rename of an entity's row (F2, the menu's Rename).
	public void BeginRename(Guid entity)
	{
		if (mTree == null)
			return;
		OpenWayTo(entity);
		let item = ItemOf(entity);
		if (item >= 0)
			mTree.BeginEdit(item);
	}

	/// The menu of the row at item `item` (-1: the background's) at `at`, where the press was.
	public void ShowMenu(int32 item, Float2 at)
	{
		if ((mTree == null) || (mServices.Context == null))
			return;
		let actions = mServices.Context.Actions;
		let page = mServices.Page;
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		let entity = EntityAt(item);
		if (entity.IsNil)
		{
			// The scene's row or the background: what makes a root.
			actions.AppendActionItems(mMenu, page, SceneActionIds.EntityCreate, SceneActionIds.EntitySpawnPrefab, SceneActionIds.EntityPaste);
		}
		else
		{
			// A press on a row not selected selects it alone first, so the actions act on it.
			if (!mEdit.EntitySelection.Contains(entity))
				mEdit.EntitySelection.Set(entity);
			actions.AppendActionItems(mMenu, page, SceneActionIds.EntityCreateChild);
			mMenu.AddItem("Rename", new [=this, =entity] () => { BeginRename(entity); }).Shortcut = "F2";
			mMenu.AddItem("Copy ID", new [=this, =entity] () =>
				{
					let dispatcher = mTree.EventDispatcher;
					if (mServices.Context != null)
						mServices.Context.CopyText((dispatcher != null) ? dispatcher.Clipboard : null, entity.ToString(.. scope .(), 'D'), "entity ID");
				});
			mMenu.AddSeparator();
			actions.AppendActionItems(mMenu, page, SceneActionIds.EntityDuplicate, SceneActionIds.EntityCreatePrefab,
				SceneActionIds.EntitySpawnPrefabAsChild, SceneActionIds.EntitySpawnPrefab);
			if (actions.IsEnabled(SceneActionIds.PrefabApply, page))
			{
				mMenu.AddSeparator();
				actions.AppendActionItems(mMenu, page, SceneActionIds.PrefabApply, SceneActionIds.PrefabRevert);
			}
			mMenu.AddSeparator();
			actions.AppendActionItems(mMenu, page, SceneActionIds.EntityCopy, SceneActionIds.EntityPasteAsChild);
			mMenu.AddSeparator();
			actions.AppendActionItems(mMenu, page, SceneActionIds.EntityDelete);
		}
		mMenu.Open(mTree, at);
	}

	// === For tests ===

	public TreeView Tree => mTree;

	/// The shown rows' texts in order, the scene's first, nested by two spaces a level, joined
	/// by " | ", into `outText`.
	public void Rows(String outText)
	{
		if (mTree == null)
			return;
		let text = scope String();
		for (int32 item < (int32)mTree.GetItemCount())
		{
			if (!outText.IsEmpty)
				outText.Append(" | ");
			for (int32 depth = mTree.ItemDepth(item); depth > 0; depth--)
				outText.Append("  ");
			text.Clear();
			mTree.GetItemText(item, text);
			outText.Append(text);
		}
	}

	/// The entity of shown item `item` (nil: the scene's row, or none).
	public Guid EntityAt(int32 item)
	{
		if ((mTree == null) || (item < 0) || (item >= (int32)mTree.GetItemCount()))
			return .();
		return EntityOfNode(mTree.GetItemIndex(item).InternalId);
	}

	/// The item showing `entity`; -1 when it is not shown.
	public int32 ItemOf(Guid entity)
	{
		if ((mTree == null) || entity.IsNil)
			return -1;
		for (int32 item < (int32)mTree.GetItemCount())
		{
			if (EntityAt(item) == entity)
				return item;
		}
		return -1;
	}

	public Sedulous.GUI.Menu OpenMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	/// What a drag of `entities` carries, into `outPayload`.
	public void DragOf(Span<Guid> entities, DragPayload outPayload)
	{
		let scene = mEdit.Scene;
		let first = entities.IsEmpty ? EntityHandle() : scene.FindEntity(entities[0]);
		EntityDrag.Payload(entities, first.IsAssigned ? scene.GetEntityName(first) : "", outPayload);
	}

	/// Whether `drop` would be taken, and takes it (what a drag ending on the tree does).
	public bool CanTake(ModelDrop drop) => mModel.CanDrop(drop, scope .()) != .None;
	public bool Take(ModelDrop drop) => CanTake(drop) && mModel.Drop(drop);

	/// The model index of `entity` (nil: the scene's row).
	public ModelIndex IndexOf(Guid entity)
	{
		for (int32 node < (int32)mRows.Count)
		{
			if (mRows[node].Entity == entity)
				return MakeModelIndex(mRows[node].RowInParent, 0, node);
		}
		return .();
	}

	// === Underneath ===

	private void Build()
	{
		mBuilt = true;
		ClearAndDeleteItems!(mRows);
		mEntityOfId.Clear();
		let scene = mEdit.Scene;
		let top = new Row();
		top.Name.Set((mServices.SceneName != null) ? mServices.SceneName() : scene.Name);
		top.Icon.Set(mServices.SceneIcon);
		mRows.Add(top);
		// Roots in list order (the order reordering keeps and saving writes), then each one's
		// children depth first; with a search, an entity whose subtree holds a match.
		for (var r = scene.FirstRoot; r.IsAssigned; r = scene.GetNextSibling(r))
		{
			if (SubtreeMatches(scene, r))
				AddEntity(scene, r, 0);
		}
		// The scene's row is always open. The scene opens with its top level shown (a model's
		// skeleton stays closed); after that an entity seen with children for the first time
		// opens (what an edit makes shows), and one the user closed stays closed.
		if (mTree != null)
		{
			mTree.SetIdExpanded(cSceneRowId, true);
			let first = !mOpened;
			mOpened = true;
			for (let row in mRows)
			{
				if (row.Entity.IsNil || row.Children.IsEmpty)
					continue;
				let id = IdOfEntity(row.Entity);
				if (mKnown.Add(id) && !first)
					mTree.SetIdExpanded(id, true);
			}
			// A search opens every way to its matches.
			if (!mFilter.IsEmpty)
			{
				for (let row in mRows)
				{
					if (!row.Entity.IsNil && !row.Children.IsEmpty)
						mTree.SetIdExpanded(IdOfEntity(row.Entity), true);
				}
			}
		}
		mModel.Reset();
		SyncSelectionToTree();
	}

	private void AddEntity(Sedulous.Scene.Scene scene, EntityHandle e, int32 parent)
	{
		let node = (int32)mRows.Count;
		let row = new Row();
		row.Entity = scene.GetEntityId(e);
		row.Parent = parent;
		row.RowInParent = (int32)mRows[parent].Children.Count;
		row.Name.Set(scene.GetEntityName(e));
		if (row.Name.IsEmpty)
			row.Name.Set("(unnamed)");
		// A prefab's members read apart; an entity that is not active, with what is under it, dims.
		if (PrefabOverrides.FindMember(scene, row.Entity, let member))
			row.Classes.Set("member");
		if (!scene.IsEffectivelyActive(e))
		{
			if (!row.Classes.IsEmpty)
				row.Classes.Append(' ');
			row.Classes.Append("inactive");
		}
		IconOf(e, row);
		mEntityOfId[IdOfEntity(row.Entity)] = row.Entity;
		mRows[parent].Children.Add(node);
		mRows.Add(row);
		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
		{
			if (SubtreeMatches(scene, c))
				AddEntity(scene, c, node);
		}
	}

	/// An entity by its first component that has an icon of its own; a plain entity by the
	/// generic one.
	private void IconOf(EntityHandle e, Row row)
	{
		if (mServices.Icons == null)
			return;
		mEdit.Scene.ForEachManager(scope [&](manager) =>
			{
				if (!row.Icon.IsEmpty || (manager.ComponentType == null) || !manager.HasComponent(e))
					return;
				let icon = mServices.Icons.For(manager.ComponentType, "");
				row.Icon.Set(icon.Source);
				row.IconClass.Set(icon.Class);
			});
		if (row.Icon.IsEmpty)
			row.Icon.Set("Editor/Icons/cube.svg");
	}

	private bool SubtreeMatches(Sedulous.Scene.Scene scene, EntityHandle e)
	{
		if (mFilter.IsEmpty || SearchFilter.NameOrGuidMatches(scene.GetEntityName(e), scene.GetEntityId(e), mFilter))
			return true;
		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
		{
			if (SubtreeMatches(scene, c))
				return true;
		}
		return false;
	}

	/// A drop's target: the entity it goes under (nil: a root) and the sibling it goes before
	/// (nil: last); false when the row it names is gone.
	private bool DropTarget(ModelDrop drop, out Guid parent, out Guid before)
	{
		parent = .();
		before = .();
		if (!drop.Index.IsValid)
			return true; // below the rows: the end of the roots
		let target = EntityOfNode(drop.Index.InternalId);
		if (target.IsNil || (drop.Place == .On))
		{
			parent = target; // onto an entity: under it; onto the scene's row: a root
			return true;
		}
		let scene = mEdit.Scene;
		let e = scene.FindEntity(target);
		if (!scene.IsValid(e))
			return false;
		let up = scene.GetParent(e);
		parent = scene.IsValid(up) ? scene.GetEntityId(up) : .();
		if (drop.Place == .Before)
			before = target;
		else
		{
			let next = scene.GetNextSibling(e);
			before = scene.IsValid(next) ? scene.GetEntityId(next) : .();
		}
		return true;
	}

	private void SyncSelectionToTree()
	{
		if (mTree == null)
			return;
		let ids = scope List<ItemId>();
		for (let entity in mEdit.EntitySelection.Items)
			ids.Add(IdOfEntity(entity));
		mSyncing = true;
		mTree.SetSelectedIds(ids);
		mSyncing = false;
	}

	private void SyncSelectionFromTree()
	{
		if (mSyncing || (mTree == null))
			return;
		let ids = scope List<ItemId>();
		mTree.GetSelectedIds(ids);
		let entities = scope List<Guid>();
		for (let id in ids)
		{
			let entity = EntityOfId(id);
			if (!entity.IsNil)
				entities.Add(entity);
		}
		mSyncing = true;
		if (entities.IsEmpty)
			mEdit.EntitySelection.Clear(); // the scene's row, or nothing: no entity
		else
			mEdit.EntitySelection.Set(entities);
		mSyncing = false;
	}

	private void OpenWayTo(Guid entity)
	{
		if (mTree == null)
			return;
		let scene = mEdit.Scene;
		for (var e = scene.GetParent(scene.FindEntity(entity)); scene.IsValid(e); e = scene.GetParent(e))
			mTree.SetIdExpanded(IdOfEntity(scene.GetEntityId(e)), true);
	}

	private void RunAction(StringView id)
	{
		if (mServices.Context == null)
			return;
		// Refused (while simulating, say): said, not swallowed.
		if (mServices.Context.Actions.Execute(id, mServices.Page) case .Err(let error))
		{
			if (error == .NotSupported)
				mServices.Context.SetStatus("Not while the scene simulates: stop it first.");
		}
	}

	private Guid EntityOfNode(int64 node) => ((node >= 0) && (node < mRows.Count)) ? mRows[(int)node].Entity : .();

	private Guid EntityOfId(ItemId id) => mEntityOfId.TryGetValue(id, let entity) ? entity : .();

	/// An entity's row id from its guid, masked apart from the scene's row.
	private static ItemId IdOfEntity(Guid entity)
	{
		if (entity.IsNil)
			return cSceneRowId;
		var id = entity;
		let words = (uint64*)&id;
		return (words[0] ^ (words[1] * 31)) & ~cSceneRowId;
	}

	private static T Find<T>(Node under, StringView id) where T : Node
	{
		let pending = scope List<Node>();
		pending.Add(under);
		while (!pending.IsEmpty)
		{
			let node = pending.PopBack();
			if (let widget = node as UIWidget)
			{
				if (widget.Id == id)
					return node as T;
			}
			for (int i < node.ChildCount)
				pending.Add(node.GetChildAt(i));
		}
		return null;
	}
}
