using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Materials.Resource;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Resource;
using Sedulous.Texture.Resource;
using Sedulous.VFS;

namespace Sedulous.ModelImporter.Tests;

/// The direct cook: a loaded model straight into cooked resources, and back out through the
/// resource system.
///
/// The chain end to end, because each half can be right on its own and still not meet: a
/// converter that writes a mesh the factory cannot read passes every converter case there is.
class ModelCookTests
{
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public ContentDatabase Database ~ delete _;
		public ResourceManager Manager ~ delete _;

		public ModelFactory Models = new .() ~ delete _;
		public StaticMeshFactory Meshes = new .() ~ delete _;
		public SkinnedMeshFactory Skinned = new .() ~ delete _;
		public SkeletonFactory Skeletons = new .() ~ delete _;
		public AnimationClipFactory Clips = new .() ~ delete _;

		private String mRoot = new .() ~ delete _;

		public this(StringView root)
		{
			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);

			ModelResources.RegisterAll();
			GeometryResources.RegisterAll();
			AnimationResources.RegisterAll();
			MaterialResources.RegisterAll();
			TextureResources.RegisterAll();

			Mount = new NativeFileSystem(mRoot);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "asset");
			Manager = new ResourceManager(Database, null);

			Manager.AddFactory(Models);
			Manager.AddFactory(Meshes);
			Manager.AddFactory(Skinned);
			Manager.AddFactory(Skeletons);
			Manager.AddFactory(Clips);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}
	}

	/// A cooked model binds back as a hierarchy whose meshes carry real geometry, whose
	/// skinned mesh is skinned, and whose clips have a duration.
	///
	/// No material or texture factory here on purpose: a model resolves what it can and
	/// leaves the rest empty, so the geometry half of the chain is measured on its own.
	[Test]
	public static void ACookedModelBindsBackAsItsHierarchy()
	{
		let fixture = scope Fixture("scratch_model_cook");

		let model = scope Model();
		ModelFixture.Character(model);

		let cooked = ModelCook.Cook(model, fixture.Database, "Character");
		Test.Assert(cooked case .Ok(let manifestId));
		Test.Assert(manifestId != Guid.Empty);

		let bound = fixture.Manager.Bind<ModelResource>(manifestId);
		let resource = bound.Get;
		Test.Assert(resource != null);

		Test.Assert(resource.Nodes.Count == 4);
		Test.Assert(resource.Meshes.Count == 2);
		Test.Assert(resource.MeshSkinned[0]);
		Test.Assert(!resource.MeshSkinned[1]);

		// Every node that names a mesh resolves to one with geometry in it.
		var sawMesh = false;
		for (let node in resource.Nodes)
		{
			if ((node.MeshIndex < 0) || (node.MeshIndex >= resource.Meshes.Count))
				continue;
			let mesh = resource.Mesh(node.MeshIndex);
			Test.Assert(mesh != null);
			Test.Assert(mesh.VertexCount > 0);
			Test.Assert(mesh.IndexCount > 0);
			sawMesh = true;
		}
		Test.Assert(sawMesh);

		// The skin came through as a skeleton with bones, and its clip has a length.
		Test.Assert(resource.Skeleton.Get != null);
		Test.Assert(resource.Skeleton.Get.BoneCount > 0);
		Test.Assert(resource.Animations.Count == 1);
		Test.Assert(resource.Animations[0].Get != null);
		Test.Assert(resource.Animations[0].Get.Duration > 0.0f);
	}

	/// A mesh, a texture and a material of one name all cook (3ds Max exports name them alike).
	///
	/// The direct cook named meshes, clips, the skeleton and the manifest without making them
	/// unique: a mesh called as its texture was handed the texture's instance and the model came
	/// without its body.
	[Test]
	public static void AMeshATextureAndAMaterialOfOneNameAllCook()
	{
		let fixture = scope Fixture("scratch_model_cook_names");

		let model = scope Model();
		ModelFixture.Character(model);
		// The occlusion texture has no file, so its cooked name is its own: give the first mesh
		// and the material the same.
		Test.Assert((model.Textures.Length > 1) && model.Textures[1].Uri.IsEmpty);
		let shared = scope String(model.Textures[1].Name);
		model.Meshes[0].Name.Set(shared);
		model.Materials[0].Name.Set(shared);

		let cooked = ModelCook.Cook(model, fixture.Database, "Character");
		Test.Assert(cooked case .Ok(let manifestId));
		let bound = fixture.Manager.Bind<ModelResource>(manifestId);
		let resource = bound.Get;
		Test.Assert(resource != null);
		Test.Assert(resource.Meshes.Count == model.Meshes.Length);
		for (int i < resource.Meshes.Count)
		{
			let mesh = resource.Mesh(i);
			Test.Assert(mesh != null, "every mesh cooked as its own instance");
			Test.Assert(mesh.VertexCount > 0);
		}
		// And the texture kept its instance, a texture still.
		let texture = fixture.Database.RootGroup.GetInstance(scope $"Character.{shared}");
		Test.Assert((texture != null) && (texture.TypeName == "Sedulous.Texture.Resource.TextureResource"));
	}

	/// Each mesh keeps its material slots, the materials its submeshes index.
	///
	/// A cooked submesh's material index is a position in its mesh's own slots, and the bound
	/// model dropped them, so a runtime user (the samples) bound the model's whole list to every
	/// mesh and drew the Quaternius character's face and eyes in the wrong materials. The model
	/// keeps them now, and MeshMaterialIndices gives the model's material each slot is.
	[Test]
	public static void EachMeshKeepsItsMaterialSlotsTheMaterialsItsSubmeshesIndex()
	{
		let dataRoot = FindDataRoot(.. scope String());
		if (dataRoot.IsEmpty)
			return;
		let path = PathJoin(dataRoot, "Samples/Models/QuaterniusCharacter/glTF/Character.gltf", .. scope .());

		let fixture = scope Fixture("scratch_model_slots");
		let model = scope Model();
		Test.Assert(ModelFileLoad.Load(path, model) == .Ok, "the character loaded");
		let cooked = ModelCook.Cook(model, fixture.Database, "Character");
		Test.Assert(cooked case .Ok(let manifestId));

		let resource = fixture.Manager.Bind<ModelResource>(manifestId).Get;
		Test.Assert(resource != null);
		Test.Assert(resource.MeshSlotStart.Count == resource.Meshes.Count, "a slot run per mesh");

		// Every mesh's submeshes index within its own list, and its list names the model's
		// materials.
		var sawSeveral = false;
		let indices = scope List<int32>();
		for (int m < resource.Meshes.Count)
		{
			let mesh = resource.Mesh(m);
			Test.Assert(mesh != null);
			resource.MeshMaterialIndices(m, indices);
			Test.Assert(!indices.IsEmpty);
			sawSeveral |= indices.Count > 1;
			for (let index in indices)
				Test.Assert((index >= 0) && (index < resource.Materials.Count));
			for (let sub in mesh.SubMeshes)
				Test.Assert(sub.MaterialIndex < indices.Count, "a submesh indexes within its mesh's list");
		}
		Test.Assert(sawSeveral, "the character's body draws several of its materials");
	}
}
