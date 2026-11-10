using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

// The scene as its hierarchy shows it, a GUI tree model built from the live scene, for the
// hierarchy and the entity picker alike (the picker is the
// hierarchy's tree in a picker's frame). The scene is the top row (node 0); under it the roots in
// list order, each one's children depth first; each entity by its first component's type icon (a
// plain entity the generic one), a prefab's members and inactive entities marked as such. With a
// search, an entity shows when its subtree holds a match, so a match keeps what holds it. A row's
// id is its entity's guid (the scene's row a fixed one), so what is open and selected survives each
// build. It is read only; the hierarchy's own model adds rename and drops.

class SceneTreeModel : IModel
{
	/// The scene's row: an id no entity's guid gives (they are masked apart from it).
	public const ItemId cSceneRowId = 0x5ce4e0000000001UL;

	public class Row
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

	/// By node id.
	private List<Row> mRows = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<ItemId, Guid> mEntityOfId = new .() ~ delete _;
	private String mFilter = new .() ~ delete _;
	/// Borrowed for a build.
	private EditorIcons mIcons = null;

	/// The rows from `scene`, its own row reading `sceneName` by `sceneIcon`, the entities by
	/// `icons`' type icons (null: none), only what `filter` keeps (empty: all). It does not tell
	/// the view: the owner opens what it wants open, then calls Reset.
	public void Build(Sedulous.Scene.Scene scene, StringView sceneName, StringView sceneIcon, EditorIcons icons, StringView filter)
	{
		ClearAndDeleteItems!(mRows);
		mEntityOfId.Clear();
		mFilter.Set(filter);
		mIcons = icons;
		let top = new Row();
		top.Name.Set(sceneName);
		top.Icon.Set(sceneIcon);
		mRows.Add(top);
		// Roots in list order (the order reordering keeps and saving writes), then each one's
		// children depth first; with a search, an entity whose subtree holds a match.
		for (var r = scene.FirstRoot; r.IsAssigned; r = scene.GetNextSibling(r))
		{
			if (SubtreeMatches(scene, r))
				AddEntity(scene, r, 0);
		}
		mIcons = null;
	}

	public void Reset() => NotifyReset();

	/// The rows as built, by node id.
	public List<Row> Rows => mRows;

	/// The entity of a model node (nil: the scene's row, or none).
	public Guid EntityOfNode(int64 node) => ((node >= 0) && (node < mRows.Count)) ? mRows[(int)node].Entity : .();

	/// The entity of a row id (nil: the scene's row, or none).
	public Guid EntityOfId(ItemId id) => mEntityOfId.TryGetValue(id, let entity) ? entity : .();

	/// An entity's row id from its guid, masked apart from the scene's row.
	public static ItemId IdOfEntity(Guid entity)
	{
		if (entity.IsNil)
			return cSceneRowId;
		var id = entity;
		let words = (uint64*)&id;
		return (words[0] ^ (words[1] * 31)) & ~cSceneRowId;
	}

	/// The model index of `entity` (nil: the scene's row); invalid when it is not shown.
	public ModelIndex IndexOf(Guid entity)
	{
		for (int32 node < (int32)mRows.Count)
		{
			if (mRows[node].Entity == entity)
				return MakeModelIndex(mRows[node].RowInParent, 0, node);
		}
		return .();
	}

	// === IModel ===

	public override int RowCount(ModelIndex parent)
	{
		if (!parent.IsValid)
			return mRows.IsEmpty ? 0 : 1;
		let node = parent.InternalId;
		return ((node >= 0) && (node < mRows.Count)) ? mRows[(int)node].Children.Count : 0;
	}

	public override int ColumnCount() => 1;

	public override ModelIndex Index(int32 row, int32 column, ModelIndex parent)
	{
		if (!parent.IsValid)
			return ((row == 0) && !mRows.IsEmpty) ? MakeModelIndex(0, column, 0) : .();
		let node = parent.InternalId;
		if ((node < 0) || (node >= mRows.Count))
			return .();
		let children = mRows[(int)node].Children;
		return ((row >= 0) && (row < children.Count)) ? MakeModelIndex(row, column, children[row]) : .();
	}

	public override ModelIndex ParentIndex(ModelIndex child)
	{
		let node = child.InternalId;
		if ((node <= 0) || (node >= mRows.Count))
			return .();
		let parent = mRows[(int)node].Parent;
		return (parent >= 0) ? MakeModelIndex(mRows[parent].RowInParent, 0, parent) : .();
	}

	public override ItemId IdOf(ModelIndex index)
	{
		if (!index.IsValid)
			return NoItem;
		return IdOfEntity(EntityOfNode(index.InternalId));
	}

	public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
	{
		let node = index.InternalId;
		if ((node < 0) || (node >= mRows.Count))
			return .();
		let row = mRows[(int)node];
		switch (role)
		{
		case .Display, .Sort: return .(row.Name);
		case .Icon: return row.Icon.IsEmpty ? .() : .(row.Icon);
		case .IconClass: return row.IconClass.IsEmpty ? .() : .(row.IconClass);
		case .RowClass: return row.Classes.IsEmpty ? .() : .(row.Classes);
		default: return .();
		}
	}

	// === Underneath ===

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
		IconOf(scene, e, row);
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
	private void IconOf(Sedulous.Scene.Scene scene, EntityHandle e, Row row)
	{
		if (mIcons == null)
			return;
		scene.ForEachManager(scope [&](manager) =>
			{
				if (!row.Icon.IsEmpty || (manager.ComponentType == null) || !manager.HasComponent(e))
					return;
				let icon = mIcons.For(manager.ComponentType, "");
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
}
