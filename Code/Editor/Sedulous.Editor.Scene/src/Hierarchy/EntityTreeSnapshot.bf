using System;
using System.Collections;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// A pre-order snapshot of a scene's entity tree, filtered by name or guid (SearchFilter):
/// what a tree adapter reads rows from without touching the live scene mid layout. A node's
/// id is its index; an entity shows when it or anything beneath it matches the filter, so a
/// match keeps its path.
class EntityTreeSnapshot
{
	public List<HierarchyNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> Roots = new .() ~ delete _;
	public String Filter = new .() ~ delete _;

	public int Count => Nodes.Count;

	/// Rebuilds from the scene's current tree. `unnamed` labels an entity with no name.
	public void Rebuild(Sedulous.Scene.Scene scene, StringView unnamed = default)
	{
		ClearAndDeleteItems(Nodes);
		Roots.Clear();
		for (var r = scene.FirstRoot; r.IsAssigned; r = scene.GetNextSibling(r))
		{
			if (SubtreeMatches(scene, r))
				Roots.Add(AddNode(scene, r, 0, unnamed));
		}
	}

	public Guid GuidOfNode(int32 nodeId)
		=> ((nodeId >= 0) && (nodeId < Nodes.Count)) ? Nodes[nodeId].Id : Guid();

	/// The node holding an entity, or -1.
	public int32 IndexOf(Guid entity)
	{
		for (int32 i < (int32)Nodes.Count)
		{
			if (Nodes[i].Id == entity)
				return i;
		}
		return -1;
	}

	public bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < Nodes.Count);

	private bool SubtreeMatches(Sedulous.Scene.Scene scene, EntityHandle e)
	{
		if (SearchFilter.NameOrGuidMatches(scene.GetEntityName(e), scene.GetEntityId(e), Filter))
			return true;
		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
		{
			if (SubtreeMatches(scene, c))
				return true;
		}
		return false;
	}

	private int32 AddNode(Sedulous.Scene.Scene scene, EntityHandle e, int32 depth, StringView unnamed)
	{
		let nodeId = (int32)Nodes.Count;
		let node = new HierarchyNode();
		node.Id = scene.GetEntityId(e);
		node.Name.Set(scene.GetEntityName(e));
		if (node.Name.IsEmpty)
			node.Name.Set(unnamed);
		node.Depth = depth;
		Nodes.Add(node);

		for (var c = scene.GetFirstChild(e); c.IsAssigned; c = scene.GetNextSibling(c))
		{
			if (!SubtreeMatches(scene, c))
				continue;
			let child = AddNode(scene, c, depth + 1, unnamed);
			Nodes[nodeId].Children.Add(child);
		}
		return nodeId;
	}
}
