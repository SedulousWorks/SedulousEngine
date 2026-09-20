using System;
using System.Collections;
using Sedulous.Animation;

namespace Sedulous.Editor.Scene;

/// A skeleton's bone hierarchy as a node table for a tree adapter, node id = bone index.
/// Rebuilt from the cooked product; a bone whose parent is out of range is a root.
class SkeletonTreeSnapshot
{
	public List<BoneNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> Roots = new .() ~ delete _;

	public bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < Nodes.Count);

	public void Rebuild(Skeleton skeleton)
	{
		ClearAndDeleteItems!(Nodes);
		Roots.Clear();
		if (skeleton == null)
			return;
		let boneCount = skeleton.BoneCount;
		for (int32 i < boneCount)
			Nodes.Add(new BoneNode());
		for (int32 i < boneCount)
		{
			let node = Nodes[i];
			node.BoneIndex = i;
			let bone = skeleton.GetBone(i);
			let parent = (bone != null) ? bone.ParentIndex : -1;
			// Parents precede children in a cooked skeleton, so the parent's depth is final.
			if ((parent >= 0) && (parent < boneCount) && (parent != i))
			{
				node.Depth = Nodes[parent].Depth + 1;
				Nodes[parent].Children.Add(i);
			}
			else
			{
				node.Depth = 0;
				Roots.Add(i);
			}
		}
	}
}
