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
	{
		if ((skeletonParentNode < -1) || (skeletonParentNode >= nodes.Length))
			return cSkinnedMeshKeepsPlace;
		var node = skeletonParentNode;
		for (int steps = 0; (node >= 0) && (node < nodes.Length) && (steps <= nodes.Length); steps++)
		{
			if (node == meshNode)
				return cSkinnedMeshKeepsPlace;
			node = nodes[node].ParentIndex;
		}
		return skeletonParentNode;
	}
}
