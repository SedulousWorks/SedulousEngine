using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Animation;
using Sedulous.Render;

namespace Sedulous.Editor.Scene;

/// A skeleton as a bone wireframe, parent to joint lines plus joint crosses, into a debug
/// lane. Shared by the skeleton, animation graph and clip preview pages.
static class SkeletonWireframe
{
	/// `worldScratch` is the caller's reusable world pose buffer; it holds every bone's
	/// world matrix afterwards, so a caller can emphasise one joint.
	public static void Draw(DebugDraw draw, Skeleton skeleton, Span<BoneTransform> localPoses, List<Float4x4> worldScratch)
	{
		let boneCount = skeleton.BoneCount;
		if ((boneCount == 0) || (localPoses.Length < boneCount))
			return;
		worldScratch.Count = boneCount;
		skeleton.ComputeWorldPoses(localPoses, .(worldScratch.Ptr, boneCount));
		let boneColor = Color(0.35f, 0.85f, 1.0f, 1.0f);
		for (int32 b < boneCount)
		{
			let bone = skeleton.GetBone(b);
			let pos = JointPosition(worldScratch[b]);
			if ((bone != null) && (bone.ParentIndex >= 0) && (bone.ParentIndex < boneCount))
				draw.DrawLine(JointPosition(worldScratch[bone.ParentIndex]), pos, boneColor);
			draw.DrawCross(pos, 0.02f, boneColor);
		}
	}

	public static Float3 JointPosition(in Float4x4 world) => .(world.M[3][0], world.M[3][1], world.M[3][2]);
}
