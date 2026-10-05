using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Model;
using Sedulous.ModelImporter;

namespace Sedulous.ModelImporter.Tests;

/// The node a skeleton hangs from, which the prefab puts skinned meshes under at identity
/// (inverse-kinematics.md P0a): it must be the node the joints hang from, Blender's armature
/// object, not a joint.
class SkeletonParentNodeTests
{
	[Test]
	public static void TheSkeletonsParentNodeIsTheSkinsRootJointsParent()
	{
		let model = scope Model();
		int32 Bone(StringView name, int32 parent)
		{
			let bone = new ModelBone();
			bone.Name.Set(name);
			bone.ParentIndex = parent;
			return model.AddBone(bone);
		}
		let scene = Bone("Scene", -1);
		let armature = Bone("Armature", scene);
		let hips = Bone("Hips", armature);
		let spine = Bone("Spine", hips);
		Bone("Body", armature);

		let map = scope Dictionary<int32, int32>();

		// Joints listed child first: the root is found by its parent, not by its place in the list.
		let skin = scope ModelSkin();
		skin.AddJoint(spine, Float4x4.Identity());
		skin.AddJoint(hips, Float4x4.Identity());
		AnimConvert.BuildBoneToJoint(skin, map);
		Test.Assert(AnimConvert.SkeletonParentNode(model, skin, map) == armature);

		// A root joint at the top of the file has no parent node: the scene root (-1).
		let top = scope ModelSkin();
		top.AddJoint(scene, Float4x4.Identity());
		top.AddJoint(armature, Float4x4.Identity());
		AnimConvert.BuildBoneToJoint(top, map);
		Test.Assert(AnimConvert.SkeletonParentNode(model, top, map) == -1);

		// No joints: unknown (-2), and the prefab keeps the file's placement.
		let empty = scope ModelSkin();
		AnimConvert.BuildBoneToJoint(empty, map);
		Test.Assert(AnimConvert.SkeletonParentNode(model, empty, map) == -2);
	}
}
