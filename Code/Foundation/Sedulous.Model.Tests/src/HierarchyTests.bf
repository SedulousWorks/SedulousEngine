using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.Model.Tests;

/// The bone hierarchy, the animation channels, and the model's own containers.
class HierarchyTests
{
	private static bool Near(float a, float b, float tolerance = 0.0001f) => Abs(a - b) <= tolerance;

	private static ModelBone Bone(StringView name, int32 index, int32 parent)
	{
		let bone = new ModelBone();
		bone.Name.Set(name);
		bone.Index = index;
		bone.ParentIndex = parent;
		return bone;
	}

	/// The hierarchy is REBUILT from parent indices, because an importer sets those as it
	/// reads nodes and cannot link a child to a parent it has not reached yet.
	[Test]
	public static void TheHierarchyIsBuiltFromParentIndices()
	{
		let model = scope Model();
		model.AddBone(Bone("root", 0, -1));
		model.AddBone(Bone("spine", 1, 0));
		model.AddBone(Bone("armL", 2, 1));
		model.AddBone(Bone("armR", 3, 1));

		model.BuildBoneHierarchy();

		Test.Assert(model.RootBoneIndex == 0);
		Test.Assert(model.Bones[0].Children.Length == 1, "root has the spine");
		Test.Assert(model.Bones[1].Children.Length == 2, "and the spine has both arms");
		Test.Assert(model.Bones[2].Children.Length == 0);
		Test.Assert(model.Bones[1].Children[0].Name == "armL", "in the order they were added");
		Test.Assert(model.Bones[1].Children[1].Name == "armR");
	}

	/// Rebuilding does not accumulate: the children are cleared first, so calling it twice
	/// gives the same tree rather than a doubled one.
	[Test]
	public static void RebuildingTheHierarchyDoesNotAccumulate()
	{
		let model = scope Model();
		model.AddBone(Bone("root", 0, -1));
		model.AddBone(Bone("child", 1, 0));

		model.BuildBoneHierarchy();
		model.BuildBoneHierarchy();
		model.BuildBoneHierarchy();

		Test.Assert(model.Bones[0].Children.Length == 1, "still one child, not three");
	}

	/// A parent index past the end of the bone list is bad data. It is treated as a root
	/// rather than followed, so a malformed file gives a flat skeleton instead of reading
	/// out of range.
	[Test]
	public static void AParentIndexOutsideTheListIsNotFollowed()
	{
		let model = scope Model();
		model.AddBone(Bone("root", 0, -1));
		model.AddBone(Bone("orphan", 1, 99));

		model.BuildBoneHierarchy();

		Test.Assert(model.Bones[0].Children.Length == 0, "nothing was attached to the root");
		Test.Assert(model.Bones[1].Children.Length == 0);
	}

	/// Clearing children does NOT delete them: the model owns every bone, and the tree is
	/// only its shape.
	[Test]
	public static void ClearingChildrenDoesNotDestroyThem()
	{
		let model = scope Model();
		model.AddBone(Bone("root", 0, -1));
		model.AddBone(Bone("child", 1, 0));
		model.BuildBoneHierarchy();

		model.Bones[0].ClearChildren();
		Test.Assert(model.Bones[0].Children.Length == 0);
		// The bone is still there, and still usable.
		Test.Assert(model.Bones[1].Name == "child");
		Test.Assert(model.GetBone("child") != null);
	}

	/// The local transform is scale, then rotate, then translate. Any other order scales
	/// along rotated axes or rotates about the wrong point.
	[Test]
	public static void TheLocalTransformIsScaleThenRotateThenTranslate()
	{
		let bone = scope ModelBone();
		bone.Translation = .(10, 0, 0);
		bone.Scale = .(2, 2, 2);
		bone.Rotation = Quaternion.Identity;
		bone.UpdateLocalTransform();

		// A point at (1,0,0) scales to (2,0,0) then translates to (12,0,0). Translating
		// first would scale the translation too and give (22,0,0).
		let moved = TransformPoint(.(1, 0, 0), bone.LocalTransform);
		Test.Assert(Near(moved.X, 12.0f), scope $"got {moved.X}");

		// Row vector convention: the translation is in the last ROW, unscaled.
		Test.Assert(Near(bone.LocalTransform.M[3][0], 10.0f));
		Test.Assert(Near(bone.LocalTransform.M[0][0], 2.0f), "and the scale is on the diagonal");
	}

	/// The composition order under NON-UNIFORM scale, checked independently.
	///
	/// Scale then rotate is not the same as rotate then scale once the scale differs per
	/// axis, and that is the case the uniform test above cannot tell apart. The expected
	/// point is built by applying the three steps to the point itself rather than by
	/// calling ToMatrix again, so this does not just restate the implementation.
	[Test]
	public static void NonUniformScaleIsAppliedBeforeTheRotation()
	{
		let bone = scope ModelBone();
		bone.Translation = .(1, -2, 3);
		bone.Scale = .(2, 3, 4);
		bone.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), HalfPi);
		bone.UpdateLocalTransform();

		let point = Float3(1, 1, 1);
		let actual = TransformPoint(point, bone.LocalTransform);

		// Scale, then rotate, then translate, done directly to the point.
		let scaled = Float3(point.X * bone.Scale.X, point.Y * bone.Scale.Y, point.Z * bone.Scale.Z);
		let rotated = RotateVector(bone.Rotation, scaled);
		let expected = rotated + bone.Translation;

		Test.Assert(Near(actual.X, expected.X, 0.001f), scope $"x: {actual.X} against {expected.X}");
		Test.Assert(Near(actual.Y, expected.Y, 0.001f), scope $"y: {actual.Y} against {expected.Y}");
		Test.Assert(Near(actual.Z, expected.Z, 0.001f), scope $"z: {actual.Z} against {expected.Z}");

		// And the other order really would differ, so the test is telling them apart.
		let rotatedFirst = RotateVector(bone.Rotation, point);
		let thenScaled = Float3(rotatedFirst.X * bone.Scale.X, rotatedFirst.Y * bone.Scale.Y,
			rotatedFirst.Z * bone.Scale.Z) + bone.Translation;
		Test.Assert(!Near(expected.X, thenScaled.X, 0.001f) || !Near(expected.Z, thenScaled.Z, 0.001f),
			"the two orders agree here, so this fixture cannot distinguish them");
	}

	[Test]
	public static void AnIdentityBoneTransformsNothing()
	{
		let bone = scope ModelBone();
		bone.UpdateLocalTransform();

		let point = Float3(3, 4, 5);
		let moved = TransformPoint(point, bone.LocalTransform);
		Test.Assert(Near(moved.X, 3.0f) && Near(moved.Y, 4.0f) && Near(moved.Z, 5.0f));
	}

	[Test]
	public static void LookupByNameFindsWhatWasAdded()
	{
		let model = scope Model();

		let mesh = new ModelMesh();
		mesh.Name.Set("body");
		model.AddMesh(mesh);

		let material = new ModelMaterial();
		material.Name.Set("steel");
		model.AddMaterial(material);

		model.AddBone(Bone("hips", 0, -1));

		let animation = new ModelAnimation();
		animation.Name.Set("walk");
		model.AddAnimation(animation);

		Test.Assert(model.GetMesh("body") === mesh);
		Test.Assert(model.GetMaterial("steel") === material);
		Test.Assert(model.GetBone("hips") != null);
		Test.Assert(model.GetAnimation("walk") === animation);

		Test.Assert(model.GetMesh("missing") == null);
		Test.Assert(model.GetMaterial("missing") == null);
		Test.Assert(model.GetBone("missing") == null);
		Test.Assert(model.GetAnimation("missing") == null);
	}

	[Test]
	public static void ModelBoundsSpanEveryMesh()
	{
		let model = scope Model();

		let first = new ModelMesh();
		first.Bounds = .(.(-1, -1, -1), .(1, 1, 1));
		model.AddMesh(first);

		let second = new ModelMesh();
		second.Bounds = .(.(0, 0, 0), .(5, 2, 3));
		model.AddMesh(second);

		model.CalculateBounds();

		Test.Assert(Near(model.Bounds.Min.X, -1.0f));
		Test.Assert(Near(model.Bounds.Max.X, 5.0f), "the union, not the last one");
		Test.Assert(Near(model.Bounds.Max.Y, 2.0f));

		let empty = scope Model();
		empty.CalculateBounds();
		Test.Assert(empty.Bounds.Min == Float3.Zero, "no meshes is empty bounds, not infinite ones");
	}

	// ---- animation ----

	[Test]
	public static void AChannelInterpolatesBetweenItsKeyframes()
	{
		let channel = scope AnimationChannel();
		channel.Path = .Translation;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(2.0f, .(10, 0, 0, 0));

		Test.Assert(Near(channel.Sample(0.0f).X, 0.0f));
		Test.Assert(Near(channel.Sample(1.0f).X, 5.0f), "halfway between");
		Test.Assert(Near(channel.Sample(2.0f).X, 10.0f));
	}

	/// Sampling outside the range CLAMPS. A clip sampled past its end holds its last pose
	/// rather than carrying on.
	[Test]
	public static void SamplingOutsideTheRangeClamps()
	{
		let channel = scope AnimationChannel();
		channel.AddKeyframe(1.0f, .(3, 0, 0, 0));
		channel.AddKeyframe(2.0f, .(7, 0, 0, 0));

		Test.Assert(Near(channel.Sample(-100.0f).X, 3.0f), "before the first key");
		Test.Assert(Near(channel.Sample(100.0f).X, 7.0f), "after the last");
	}

	/// Step holds each value until the next key, with no blending at all.
	[Test]
	public static void StepInterpolationDoesNotBlend()
	{
		let channel = scope AnimationChannel();
		channel.Interpolation = .Step;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(1.0f, .(10, 0, 0, 0));

		Test.Assert(Near(channel.Sample(0.5f).X, 0.0f), "still the first value");
		Test.Assert(Near(channel.Sample(0.99f).X, 0.0f));
		Test.Assert(Near(channel.Sample(1.0f).X, 10.0f), "and it changes at the key");
	}

	/// A rotation channel SLERPS. Interpolating a quaternion's four numbers separately
	/// leaves the unit sphere, and the pose shears rather than turning.
	[Test]
	public static void ARotationChannelStaysAUnitQuaternion()
	{
		let channel = scope AnimationChannel();
		channel.Path = .Rotation;

		// A quarter turn about Y, and its opposite.
		let quarter = Quaternion.FromAxisAngle(.(0, 1, 0), HalfPi);
		channel.AddKeyframe(0.0f, .(0, 0, 0, 1));
		channel.AddKeyframe(1.0f, .(quarter.X, quarter.Y, quarter.Z, quarter.W));

		for (int i <= 10)
		{
			let sample = channel.Sample((float)i / 10.0f);
			let length = Sqrt(sample.X * sample.X + sample.Y * sample.Y
				+ sample.Z * sample.Z + sample.W * sample.W);
			Test.Assert(Near(length, 1.0f, 0.001f), scope $"at {i} the quaternion had length {length}");
		}
	}

	[Test]
	public static void ADegenerateChannelIsHarmless()
	{
		let empty = scope AnimationChannel();
		Test.Assert(empty.Sample(0.5f) == Float4.Zero, "nothing to sample");

		let single = scope AnimationChannel();
		single.AddKeyframe(5.0f, .(1, 2, 3, 4));
		Test.Assert(single.Sample(0.0f) == Float4(1, 2, 3, 4), "one key answers everywhere");
		Test.Assert(single.Sample(100.0f) == Float4(1, 2, 3, 4));
	}

	/// The duration is DERIVED from the keys, so a clip whose declared length disagrees
	/// with its own content still plays all of it.
	[Test]
	public static void TheDurationComesFromTheLatestKeyframe()
	{
		let animation = scope ModelAnimation();

		let first = new AnimationChannel();
		first.AddKeyframe(0.0f, .Zero);
		first.AddKeyframe(1.5f, .Zero);
		animation.AddChannel(first);

		let second = new AnimationChannel();
		second.AddKeyframe(0.0f, .Zero);
		second.AddKeyframe(3.25f, .Zero);
		animation.AddChannel(second);

		// A THIRD channel that ends EARLIER than the second. Keeping the maximum is not the
		// same as keeping the last value seen, and channels in ascending order cannot tell
		// those apart.
		let third = new AnimationChannel();
		third.AddKeyframe(0.0f, .Zero);
		third.AddKeyframe(0.5f, .Zero);
		animation.AddChannel(third);

		animation.Duration = 99.0f; // whatever the file claimed
		animation.CalculateDuration();

		Test.Assert(Near(animation.Duration, 3.25f), scope $"got {animation.Duration}");
		Test.Assert(animation.ChannelCount == 3);
	}

	[Test]
	public static void AnAnimationWithNoKeyframesHasNoDuration()
	{
		let animation = scope ModelAnimation();
		animation.AddChannel(new AnimationChannel());
		animation.CalculateDuration();
		Test.Assert(animation.Duration == 0.0f);
	}

	/// A skin's joints and inverse bind matrices are PARALLEL, which is why they are added
	/// together: one without the other cannot pose anything.
	[Test]
	public static void ASkinKeepsItsJointsAndMatricesParallel()
	{
		let skin = scope ModelSkin();
		skin.Name.Set("body");

		skin.AddJoint(3, Float4x4.Translation(.(1, 0, 0)));
		skin.AddJoint(7, Float4x4.Translation(.(0, 2, 0)));

		Test.Assert(skin.JointCount == 2);
		Test.Assert(skin.Joints.Length == skin.InverseBindMatrices.Length);
		Test.Assert(skin.Joints[0] == 3);
		Test.Assert(skin.Joints[1] == 7);
		Test.Assert(Near(skin.InverseBindMatrices[0].M[3][0], 1.0f));
		Test.Assert(Near(skin.InverseBindMatrices[1].M[3][1], 2.0f));
	}

	[Test]
	public static void ATextureCopiesTheDataItIsGiven()
	{
		let texture = scope ModelTexture();
		Test.Assert(!texture.HasEmbeddedData);
		Test.Assert(texture.DataSize == 0);

		uint8[4] png = .(0x89, 0x50, 0x4E, 0x47);
		texture.SetData(.(&png[0], 4));

		Test.Assert(texture.HasEmbeddedData);
		Test.Assert(texture.DataSize == 4);
		Test.Assert(texture.Data[0] == 0x89);

		// A copy, so changing the source afterwards does not change the texture.
		png[0] = 0;
		Test.Assert(texture.Data[0] == 0x89, "it kept its own copy");

		texture.SetData(.());
		Test.Assert(!texture.HasEmbeddedData, "clearing it works");
	}
}
