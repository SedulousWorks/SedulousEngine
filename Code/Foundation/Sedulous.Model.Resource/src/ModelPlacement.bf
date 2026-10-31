using System;
using System.Collections;

namespace Sedulous.Model.Resource;

/// Where a model's nodes go when it is put into a scene: one rule for the project's model prefab
/// and a host spawning a cooked model at run time.
static class ModelPlacement
{
	/// What SkinnedMeshParent answers when the mesh stays where the file put it.
	public const int32 cSkinnedMeshKeepsPlace = -2;

	/// Where a skinned mesh's node goes when the model is put into a scene. A skin draws in its
	/// skeleton's parent's space (the joints' palette is relative to it), and glTF ignores a
	/// skinned mesh node's own transform: so the mesh's node goes under the skeleton's parent node
	/// at identity (minus one: the model's root, when the skeleton has no parent), and its world IS
	/// the skeleton's model space wherever the file put the mesh node (inverse-kinematics.md P0a).
	/// cSkinnedMeshKeepsPlace when it stays: the parent is not known (data before version 3) or is
	/// the mesh node or below it. The walk up is bounded by the node count (a malformed cycle).
	public static int32 SkinnedMeshParent(Span<ModelNode> nodes, int32 skeletonParentNode, int meshNode)
		=> Walk(nodes.Length, skeletonParentNode, meshNode, scope (i) => nodes[i].ParentIndex);

	/// The same rule over a manifest's node parents (ModelManifestSource.NodeParent), which an
	/// editor thumbnail reads without building the nodes.
	public static int32 SkinnedMeshParent(Span<int32> nodeParents, int32 skeletonParentNode, int meshNode)
		=> Walk(nodeParents.Length, skeletonParentNode, meshNode, scope (i) => nodeParents[i]);

	private static int32 Walk(int nodeCount, int32 skeletonParentNode, int meshNode, delegate int32(int node) parentOf)
	{
		if ((skeletonParentNode < -1) || (skeletonParentNode >= nodeCount))
			return cSkinnedMeshKeepsPlace;
		var node = skeletonParentNode;
		for (int steps = 0; (node >= 0) && (node < nodeCount) && (steps <= nodeCount); steps++)
		{
			if (node == meshNode)
				return cSkinnedMeshKeepsPlace;
			node = parentOf(node);
		}
		return skeletonParentNode;
	}
}
