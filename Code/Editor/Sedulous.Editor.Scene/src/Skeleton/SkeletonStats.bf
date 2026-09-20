using System;
using System.Collections;
using Sedulous.Animation;

namespace Sedulous.Editor.Scene;

/// The skeleton page's header stats: the name when it has one, the bone count, the root
/// count and the deepest chain.
static class SkeletonStats
{
	/// Appends one entry per stat; the caller owns the strings.
	public static void Lines(Skeleton skeleton, List<String> outLines)
	{
		if (!skeleton.Name.IsEmpty)
			outLines.Add(new String(skeleton.Name));
		outLines.Add(new $"{skeleton.BoneCount} bones");
		int32 roots = 0;
		int32 maxDepth = 0;
		for (int32 i < skeleton.BoneCount)
		{
			let bone = skeleton.GetBone(i);
			if (bone == null)
				continue;
			if (bone.ParentIndex < 0)
				roots++;
			int32 depth = 0;
			var walk = bone;
			while ((walk != null) && (walk.ParentIndex >= 0) && (depth < skeleton.BoneCount))
			{
				depth++;
				walk = skeleton.GetBone(walk.ParentIndex);
			}
			maxDepth = Math.Max(maxDepth, depth);
		}
		outLines.Add(new $"{roots} roots");
		outLines.Add(new $"depth {maxDepth}");
	}
}
