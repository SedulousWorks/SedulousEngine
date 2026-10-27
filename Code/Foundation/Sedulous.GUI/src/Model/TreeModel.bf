using System;
using System.Collections;

namespace Sedulous.GUI;

// TreeModel: a concrete hierarchical Model - nodes with a text label and children. Modeled on
// eepp's tree models (role only). Nodes are stored in a flat array; a ModelIndex's InternalId
// is the node's array index, which the tree methods (Index / ParentIndex / RowCount(parent) /
// HasChildren) use to navigate. A removed node keeps its slot (it is detached, not erased), so
// node ids stay stable and a view keeps selection and expansion by id. Each edit tells the
// views the rows it touched under their parent.

class TreeModel : IModel
{
	/// The parent id of a top-level node.
	public const int32 Root = -1;

	private class Node
	{
		public String Text = new .() ~ delete _;
		public String Icon = new .() ~ delete _; // its image's source, or none
		public String IconClass = new .() ~ delete _; // a class on that image
		public int32 Parent = -1;
		public List<int32> Children = new .() ~ delete _;
		/// Detached: its slot kept so ids stay stable.
		public bool Removed = false;
	}

	private List<Node> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private List<int32> mRoots = new .() ~ delete _;

	public this() { }

	// Add a node under `parentId` (Root for a top level node); returns the new node's id.
	public int32 AddNode(int32 parentId, StringView text)
	{
		let id = (int32)mNodes.Count;
		let node = new Node();
		node.Text.Set(text);
		node.Parent = parentId;
		mNodes.Add(node);
		let siblings = SiblingsUnder(parentId);
		siblings.Add(id);
		NotifyRowsInserted(IndexOfNode(parentId), (int32)siblings.Count - 1, 1);
		return id;
	}

	/// Removes a node and what is under it (their ids are not reused).
	public void RemoveNode(int32 nodeId)
	{
		if (!IsLive(nodeId))
			return;
		let parentId = mNodes[nodeId].Parent;
		let parent = IndexOfNode(parentId);
		let row = RowOf(nodeId);
		SiblingsUnder(parentId).RemoveAt(row);
		Detach(nodeId);
		NotifyRowsRemoved(parent, row, 1);
	}

	public void SetText(int32 nodeId, StringView text)
	{
		if (!IsLive(nodeId))
			return;
		mNodes[nodeId].Text.Set(text);
		NotifyRowsChanged(IndexOfNode(mNodes[nodeId].Parent), RowOf(nodeId), 1);
	}

	/// A node's icon: its image's source, and a class on it a sheet styles (empty: none).
	public void SetIcon(int32 nodeId, StringView source, StringView iconClass = default)
	{
		if (!IsLive(nodeId))
			return;
		mNodes[nodeId].Icon.Set(source);
		mNodes[nodeId].IconClass.Set(iconClass);
		NotifyRowsChanged(IndexOfNode(mNodes[nodeId].Parent), RowOf(nodeId), 1);
	}

	/// Moves a node (with what is under it) under `parentId` at `row` (past the end: last).
	/// False when that would put it inside itself.
	public bool MoveNode(int32 nodeId, int32 parentId, int row)
	{
		if (!IsLive(nodeId) || ((parentId != Root) && !IsLive(parentId)) || IsWithin(parentId, nodeId))
			return false;
		Unlink(nodeId);
		let siblings = SiblingsUnder(parentId);
		siblings.Insert(((row < 0) || (row > siblings.Count)) ? siblings.Count : row, nodeId);
		mNodes[nodeId].Parent = parentId;
		NotifyReset();
		return true;
	}

	// === Drops ===
	// Its own nodes move: onto a node (its last child) or beside one; never inside themselves.
	// `text` comes in as a new node.
	public override DropEffect CanDrop(ModelDrop drop, String reason)
	{
		let parent = DropParent(drop);
		if ((drop.Source === this) && !drop.Ids.IsEmpty)
		{
			for (let id in drop.Ids)
			{
				if (IsWithin(parent, (int32)id))
				{
					reason.Set("A node cannot go inside itself");
					return .None;
				}
			}
			return .Move; // a tree moves its nodes (copying a subtree is not taken)
		}
		if ((drop.Payload != null) && (drop.Payload.Type == "text"))
			return .Copy;
		return .None;
	}

	public override bool Drop(ModelDrop drop)
	{
		if (CanDrop(drop, scope String()) == .None)
			return false;
		let parent = DropParent(drop);
		var row = DropRow(drop, parent);
		if ((drop.Source !== this) || drop.Ids.IsEmpty)
		{
			// The payload's string, or its label.
			let value = drop.Payload.Value;
			StringView text = drop.Payload.Label;
			if ((value.VariantType == typeof(String)) && (value.Get<String>() != null))
				text = value.Get<String>();
			let id = AddNode(parent, text);
			MoveNode(id, parent, row);
			return true;
		}
		for (let id in drop.Ids)
		{
			let node = (int32)id;
			// A node moving down within its own parent: the row past it shifts back by one.
			let siblings = SiblingsUnder(parent);
			for (int i = 0; (i < siblings.Count) && (i < row); i++)
			{
				if (siblings[i] == node)
				{
					row--;
					break;
				}
			}
			if (MoveNode(node, parent, row))
				row++;
		}
		return true;
	}

	public void Clear()
	{
		ClearAndDeleteItems!(mNodes);
		mRoots.Clear();
		NotifyReset();
	}

	/// The index of a node (invalid for Root or a removed node).
	public ModelIndex IndexOfNode(int32 nodeId) => IsLive(nodeId) ? MakeModelIndex(RowOf(nodeId), 0, nodeId) : .();

	/// The node's text, a view of the model's (empty for no node).
	public StringView TextOf(int32 nodeId) => ((nodeId >= 0) && (nodeId < mNodes.Count)) ? (StringView)mNodes[nodeId].Text : default;

	public override int ColumnCount() => 1;

	public override int RowCount(ModelIndex parent)
	{
		if (!parent.IsValid)
			return mRoots.Count;
		let id = (int32)parent.InternalId;
		return ((id >= 0) && (id < mNodes.Count)) ? mNodes[id].Children.Count : 0;
	}

	public override ModelIndex Index(int32 row, int32 column, ModelIndex parent)
	{
		let childId = ChildIdAt(parent, row);
		if (childId < 0)
			return .();
		return MakeModelIndex(row, column, childId);
	}

	public override ModelIndex ParentIndex(ModelIndex child)
	{
		let id = (int32)child.InternalId;
		if ((id < 0) || (id >= mNodes.Count))
			return .();
		let parentId = mNodes[id].Parent;
		if (parentId == Root)
			return .(); // top-level: no parent
		return MakeModelIndex(RowOf(parentId), 0, parentId);
	}

	public override bool HasChildren(ModelIndex parent) => RowCount(parent) > 0;

	public override Sedulous.GUI.Variant Data(ModelIndex index, ModelRole role = .Display)
	{
		let id = (int32)index.InternalId;
		if ((id < 0) || (id >= mNodes.Count))
			return .();
		let node = mNodes[id];
		if ((role == .Display) || (role == .Sort))
			return .((StringView)node.Text);
		if ((role == .Icon) && !node.Icon.IsEmpty)
			return .((StringView)node.Icon);
		if ((role == .IconClass) && !node.IconClass.IsEmpty)
			return .((StringView)node.IconClass);
		return .();
	}

	/// The child list a node is under: the top level's for Root.
	private List<int32> SiblingsUnder(int32 parentId) => (parentId == Root) ? mRoots : mNodes[parentId].Children;

	private int32 ChildIdAt(ModelIndex parent, int32 row)
	{
		if (!parent.IsValid)
			return ((row >= 0) && (row < mRoots.Count)) ? mRoots[row] : -1;
		let id = (int32)parent.InternalId;
		if ((id < 0) || (id >= mNodes.Count))
			return -1;
		let children = mNodes[id].Children;
		return ((row >= 0) && (row < children.Count)) ? children[row] : -1;
	}

	// The row index of `nodeId` within its parent's child list (or root list).
	private int32 RowOf(int32 nodeId)
	{
		if ((nodeId < 0) || (nodeId >= mNodes.Count))
			return -1;
		let siblings = SiblingsUnder(mNodes[nodeId].Parent);
		for (int i = 0; i < siblings.Count; i++)
		{
			if (siblings[i] == nodeId)
				return (int32)i;
		}
		return -1;
	}

	private bool IsLive(int32 nodeId) => (nodeId >= 0) && (nodeId < mNodes.Count) && !mNodes[nodeId].Removed;

	/// Marks a node and what is under it removed (their slots kept).
	private void Detach(int32 nodeId)
	{
		let node = mNodes[nodeId];
		node.Removed = true;
		for (let child in node.Children)
			Detach(child);
		node.Children.Clear();
	}

	// Takes a live node out of its parent's children (to be put back elsewhere).
	private void Unlink(int32 nodeId)
	{
		let siblings = SiblingsUnder(mNodes[nodeId].Parent);
		for (int i = 0; i < siblings.Count; i++)
		{
			if (siblings[i] == nodeId)
			{
				siblings.RemoveAt(i);
				break;
			}
		}
	}

	// Whether `nodeId` is `ancestorId` or lies under it.
	private bool IsWithin(int32 nodeId, int32 ancestorId)
	{
		for (var n = nodeId; (n != Root) && IsLive(n); n = mNodes[n].Parent)
		{
			if (n == ancestorId)
				return true;
		}
		return false;
	}

	// The node a drop goes under: onto a node, that node; beside one, its parent.
	private int32 DropParent(ModelDrop drop)
	{
		if (!drop.Index.IsValid)
			return Root;
		let at = (int32)drop.Index.InternalId;
		if (drop.Place == .On)
			return at;
		return IsLive(at) ? mNodes[at].Parent : Root;
	}

	// The row under that parent a drop goes to (past the end when the row it is beside is gone).
	private int DropRow(ModelDrop drop, int32 parent)
	{
		let siblings = SiblingsUnder(parent);
		if (!drop.Index.IsValid || (drop.Place == .On))
			return siblings.Count;
		let row = RowOf((int32)drop.Index.InternalId);
		let at = (drop.Place == .Before) ? row : row + 1;
		return (at < 0) ? siblings.Count : at;
	}
}
