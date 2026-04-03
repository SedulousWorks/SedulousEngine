using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Geometry;
using Sedulous.Models;
using Sedulous.Animation;

namespace Sedulous.Geometry.Tooling;

/// Converts Model animations to runtime AnimationClip format.
static class AnimationConverter
{
	/// Converts a ModelAnimation to an AnimationClip, remapping bone indices using the provided mapping.
	/// The nodeToBoneMapping converts node indices (from animation channels) to skeleton bone indices.
	public static AnimationClip Convert(ModelAnimation modelAnim, int32[] nodeToBoneMapping)
	{
		if (modelAnim == null)
			return null;

		let clip = new AnimationClip(modelAnim.Name, modelAnim.Duration);

		for (let modelChannel in modelAnim.Channels)
		{
			// Remap target bone from node index to skeleton bone index
			let nodeIdx = modelChannel.TargetBone;
			if (nodeToBoneMapping == null || nodeIdx < 0 || nodeIdx >= nodeToBoneMapping.Count)
				continue;

			let boneIdx = nodeToBoneMapping[nodeIdx];
			if (boneIdx < 0)
				continue;  // This node is not a skin joint, skip

			InterpolationMode interpolation;
			switch (modelChannel.Interpolation)
			{
			case .Linear: interpolation = .Linear;
			case .Step: interpolation = .Step;
			case .CubicSpline: interpolation = .CubicSpline;
			}

			switch (modelChannel.Path)
			{
			case .Translation:
				let track = clip.GetOrCreatePositionTrack(boneIdx);
				track.Interpolation = interpolation;
				for (let keyframe in modelChannel.Keyframes)
					track.AddKeyframe(keyframe.Time, .(keyframe.Value.X, keyframe.Value.Y, keyframe.Value.Z));

			case .Rotation:
				let track = clip.GetOrCreateRotationTrack(boneIdx);
				track.Interpolation = interpolation;
				for (let keyframe in modelChannel.Keyframes)
					track.AddKeyframe(keyframe.Time, Quaternion(keyframe.Value.X, keyframe.Value.Y, keyframe.Value.Z, keyframe.Value.W));

			case .Scale:
				let track = clip.GetOrCreateScaleTrack(boneIdx);
				track.Interpolation = interpolation;
				for (let keyframe in modelChannel.Keyframes)
					track.AddKeyframe(keyframe.Time, .(keyframe.Value.X, keyframe.Value.Y, keyframe.Value.Z));

			case .Weights:
				continue;  // Morph targets not supported yet
			}
		}

		return clip;
	}

	/// Converts all animations from a Model, remapping bone indices using the provided mapping.
	/// Caller owns the returned list and its contents.
	public static List<AnimationClip> ConvertAll(Model model, int32[] nodeToBoneMapping)
	{
		if (model == null)
			return null;

		let clips = new List<AnimationClip>();

		for (let modelAnim in model.Animations)
		{
			let clip = Convert(modelAnim, nodeToBoneMapping);
			if (clip != null)
				clips.Add(clip);
		}

		return clips;
	}
}
