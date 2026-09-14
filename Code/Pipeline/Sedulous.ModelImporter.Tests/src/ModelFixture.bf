using System;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.ModelImporter.Tests;

/// Whole models built by hand, standing in for the files an import is dropped.
///
/// Built rather than loaded because the importer takes a PREPARED model in its two phase path
/// anyway: the fan out reads a loaded model, never a file, so a fixture that states its own
/// contents measures exactly what the fan out does with them.
static class ModelFixture
{
	/// A skinned character with a static prop beside it: two textures, one material, two
	/// meshes, a skin, a clip and a node per mesh.
	///
	/// Everything one import can produce, in one model, so a case can assert what landed and
	/// what did not without a different fixture per question.
	public static void Character(Model model)
	{
		model.Name.Set("character");

		// The first image's authored name DISAGREES with its file, which is the shape a
		// well known texture library ships and the reason naming prefers the file stem.
		model.AddTexture(MeshFixture.Gray(180, "authored_name_lies", "textures/Texture.png"));
		model.AddTexture(MeshFixture.Gray(90, "Occlusion"));

		let material = new ModelMaterial();
		material.Name.Set("Skin");
		material.BaseColorTextureIndex = 0;
		material.OcclusionTextureIndex = 1;
		material.BaseColorFactor = .(1, 1, 1, 1);
		model.AddMaterial(material);

		let body = MeshFixture.SkinnedTriangle("Body", 0.0f, 1);
		body.AddPart(.(0, 3, 0));
		model.AddMesh(body);

		let prop = MeshFixture.Row("Prop", 10.0f, 3, scope uint32[](0, 1, 2));
		prop.AddPart(.(0, 3, 0));
		model.AddMesh(prop);

		let root = new ModelBone();
		root.Name.Set("Root");
		model.AddBone(root);

		let joint = new ModelBone();
		joint.Name.Set("Joint");
		joint.ParentIndex = 0;
		model.AddBone(joint);

		let bodyNode = new ModelBone();
		bodyNode.Name.Set("BodyNode");
		bodyNode.ParentIndex = 0;
		bodyNode.MeshIndex = 0;
		model.AddBone(bodyNode);

		let propNode = new ModelBone();
		propNode.Name.Set("PropNode");
		propNode.ParentIndex = 0;
		propNode.MeshIndex = 1;
		model.AddBone(propNode);

		let skin = new ModelSkin();
		skin.Name.Set("Armature");
		skin.AddJoint(0, Float4x4.Identity());
		skin.AddJoint(1, Float4x4.Identity());
		model.AddSkin(skin);

		let animation = new ModelAnimation();
		animation.Name.Set("Idle");
		let channel = new AnimationChannel();
		channel.TargetBone = 1;
		channel.Path = .Translation;
		channel.AddKeyframe(0.0f, .(0, 0, 0, 0));
		channel.AddKeyframe(1.0f, .(0, 1, 0, 0));
		animation.AddChannel(channel);
		animation.CalculateDuration();
		model.AddAnimation(animation);

		model.CalculateBounds();
	}

	/// Two meshes where the LEVEL comes FIRST and the base second, which is the order that
	/// once shifted every manifest slot after it.
	public static void LevelBeforeBase(Model model)
	{
		let level = MeshFixture.Row("Part_LOD1", 0.0f, 3, scope uint32[](0, 1, 2));
		level.AddPart(.(0, 3, 0));
		model.AddMesh(level);

		let @base = MeshFixture.Row("Part", 0.0f, 3, scope uint32[](0, 1, 2));
		@base.AddPart(.(0, 3, 0));
		model.AddMesh(@base);

		let node = new ModelBone();
		node.Name.Set("PartNode");
		node.MeshIndex = 1; // the BASE, by MODEL index
		model.AddBone(node);

		model.CalculateBounds();
	}
}
