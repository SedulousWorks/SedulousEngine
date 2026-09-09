using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Animation.Resource;

/// The cooked WIRE for a skeleton: PER BONE PARALLEL ARRAYS, so the serializer never nests.
[Serializable]
class SkeletonSource
{
	public String Name = new .() ~ delete _;

	public List<String> BoneName = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> ParentIndex = new .() ~ delete _;
	public List<Float3> Translation = new .() ~ delete _;
	public List<Quaternion> Rotation = new .() ~ delete _;
	public List<Float3> Scale = new .() ~ delete _;
	public List<Float4x4> InverseBindPose = new .() ~ delete _;

	/// Captures a runtime skeleton, which is the cooking half.
	public static void FromSkeleton(Skeleton skeleton, SkeletonSource outSource)
	{
		outSource.Name.Set(skeleton.Name);
		ClearAndDeleteItems!(outSource.BoneName);
		outSource.ParentIndex.Clear();
		outSource.Translation.Clear();
		outSource.Rotation.Clear();
		outSource.Scale.Clear();
		outSource.InverseBindPose.Clear();

		for (let bone in skeleton.Bones)
		{
			outSource.BoneName.Add(new String(bone.Name));
			outSource.ParentIndex.Add(bone.ParentIndex);
			outSource.Translation.Add(bone.LocalBindPose.Position);
			outSource.Rotation.Add(bone.LocalBindPose.Rotation);
			outSource.Scale.Add(bone.LocalBindPose.Scale);
			outSource.InverseBindPose.Add(bone.InverseBindPose);
		}
	}

	/// Rebuilds a skeleton IN PLACE, so a hot reload keeps every reference to it valid.
	///
	/// The parent array is what says how many bones there are: it is the one field every
	/// bone must have, and a name or a transform missing from a short array falls back
	/// rather than truncating the skeleton.
	public void FillSkeleton(Skeleton skeleton)
	{
		let count = (int32)ParentIndex.Count;
		skeleton.ClearForReload(count);
		skeleton.Name.Set(Name);

		for (int i = 0; i < count; i++)
		{
			let bone = skeleton.Bones[i];
			bone.Index = (int32)i;
			bone.ParentIndex = ParentIndex[i];
			if (i < BoneName.Count)
				bone.Name.Set(BoneName[i]);

			bone.LocalBindPose = .(
				(i < Translation.Count) ? Translation[i] : Float3(0, 0, 0),
				(i < Rotation.Count) ? Rotation[i] : Quaternion.Identity,
				(i < Scale.Count) ? Scale[i] : Float3(1, 1, 1));

			if (i < InverseBindPose.Count)
				bone.InverseBindPose = InverseBindPose[i];
		}

		// The lookups and the hierarchy are DERIVED rather than stored: they are a function
		// of the parents, and a stored copy would be a second thing to keep in agreement.
		skeleton.BuildNameMap();
		skeleton.FindRootBones();
		skeleton.BuildChildIndices();
	}
}
