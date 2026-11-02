using System;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Scale and up axis applied to a loaded model before its import fans out: each root node's
/// transform, and the keys of the clips that move a root node, so its meshes, skeleton and clips
/// all come in scaled and turned. A skinned mesh follows its skeleton's root.
static class ModelImportFrame
{
	/// The turn that brings `up` to the engine's Y.
	public static Quaternion TurnFor(ModelUpAxis up)
		=> (up == .Z) ? Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -HalfPi) : Quaternion.Identity;

	/// Applies `scale` and `up` to `model`; nothing when they are 1 and Y. A scale of zero or less
	/// (a field typed over) is taken as 1: a model scaled to nothing imports nothing useful.
	public static void Apply(Model model, float scale, ModelUpAxis up)
	{
		let factor = (scale > 0.0f) ? scale : 1.0f;
		if ((factor == 1.0f) && (up == .Y))
			return;
		let turn = TurnFor(up);
		let bones = model.Bones;
		for (let bone in bones)
		{
			if ((bone == null) || (bone.ParentIndex >= 0))
				continue;
			bone.Translation = RotateVector(turn, bone.Translation) * factor;
			bone.Rotation = turn * bone.Rotation;
			bone.Scale = bone.Scale * factor;
			bone.UpdateLocalTransform();
		}
		for (let clip in model.Animations)
		{
			if (clip == null)
				continue;
			for (let channel in clip.Channels)
			{
				if ((channel == null) || (channel.TargetBone < 0) || (channel.TargetBone >= bones.Length)
					|| (bones[channel.TargetBone].ParentIndex >= 0))
				{
					continue;
				}
				let keys = channel.Keyframes;
				for (int k < keys.Length)
				{
					let value = keys[k].Value;
					switch (channel.Path)
					{
					case .Translation:
						let moved = RotateVector(turn, .(value.X, value.Y, value.Z)) * factor;
						keys[k].Value = .(moved.X, moved.Y, moved.Z, value.W);
					case .Rotation:
						let turned = turn * Quaternion(value.X, value.Y, value.Z, value.W);
						keys[k].Value = .(turned.X, turned.Y, turned.Z, turned.W);
					case .Scale:
						keys[k].Value = .(value.X * factor, value.Y * factor, value.Z * factor, value.W);
					default:
					}
				}
			}
		}
		model.CalculateBounds();
	}
}
