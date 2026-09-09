using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Model.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Model.Resource.Tests;

/// A cooked manifest assembled into a runtime model, with every leaf resolved through the
/// manager.
class ModelResourceTests
{
	private const String cModelTypeName = "Sedulous.Model.Resource.ModelManifestSource";
	private const String cMeshTypeName = "Sedulous.Geometry.StaticMeshSource";
	private const String cSkeletonTypeName = "Sedulous.Animation.Resource.SkeletonSource";
	private const String cClipTypeName = "Sedulous.Animation.Resource.AnimationClipSource";

	/// A scratch database and the factories a model's build reaches through.
	///
	/// The mesh, skeleton and clip factories are all here, because the point of the model
	/// factory is partly the EDGES it records mid build: a fixture missing them would test
	/// the model in isolation from everything it depends on.
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public SerializableRegistry Serializables = new .() ~ delete _;
		public ContentDatabase Database ~ delete _;
		public ResourceManager Manager ~ delete _;

		public ModelFactory Models = new .() ~ delete _;
		public StaticMeshFactory Meshes = new .() ~ delete _;
		public SkeletonFactory Skeletons = new .() ~ delete _;
		public AnimationClipFactory Clips = new .() ~ delete _;

		private String mRoot = new .() ~ delete _;

		public this(StringView root)
		{
			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);

			ModelResources.RegisterAll(Serializables);
			GeometryResources.RegisterAll(Serializables);
			AnimationResources.RegisterAll(Serializables);

			Mount = new NativeFileSystem(mRoot);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
			Manager = new ResourceManager(Database, null);

			ModelResources.AddFactories(Manager, Models);
			Manager.AddFactory(Meshes);
			Manager.AddFactory(Skeletons);
			Manager.AddFactory(Clips);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}

		public Guid CookMesh(StringView name)
		{
			let mesh = Primitives.Cube(1.0f);
			defer delete mesh;

			let record = scope StaticMeshSource();
			StaticMeshSource.FromMesh(mesh, record);

			let instance = Database.RootGroup.CreateInstance(name, cMeshTypeName);
			instance.WriteObject(record).IgnoreError();
			return instance.Id;
		}

		public Guid CookSkeleton(StringView name)
		{
			let skeleton = scope Skeleton(2);
			skeleton.Bones[0].ParentIndex = -1;
			skeleton.Bones[0].Name.Set("root");
			skeleton.Bones[1].ParentIndex = 0;
			skeleton.Bones[1].Name.Set("child");
			skeleton.BuildNameMap();
			skeleton.FindRootBones();
			skeleton.BuildChildIndices();
			skeleton.ComputeInverseBindPoses();

			let record = scope SkeletonSource();
			SkeletonSource.FromSkeleton(skeleton, record);

			let instance = Database.RootGroup.CreateInstance(name, cSkeletonTypeName);
			instance.WriteObject(record).IgnoreError();
			return instance.Id;
		}

		public Guid CookClip(StringView name)
		{
			let clip = scope AnimationClip(name, 1.0f, true);
			clip.GetOrCreatePositionTrack(0).AddKeyframe(0.0f, .(0, 0, 0));
			clip.GetOrCreatePositionTrack(0).AddKeyframe(1.0f, .(0, 1, 0));

			let record = scope AnimationClipSource();
			AnimationClipSource.FromClip(clip, record);

			let instance = Database.RootGroup.CreateInstance(name, cClipTypeName);
			instance.WriteObject(record).IgnoreError();
			return instance.Id;
		}

		public Guid CookModel(StringView name, ModelManifestSource record)
		{
			let instance = Database.RootGroup.CreateInstance(name, cModelTypeName);
			instance.WriteObject(record).IgnoreError();
			return instance.Id;
		}
	}

	/// The hierarchy survives the flattening, and every leaf id resolves.
	[Test]
	public static void AManifestAssemblesIntoAModelWithItsLeavesResolved()
	{
		let fixture = scope Fixture("scratch_model_resource");

		let record = scope ModelManifestSource();
		record.MeshGuid.Add(fixture.CookMesh("body"));
		record.MeshSkinned.Add(false);
		record.MeshMaterial.Add(-1);
		record.CollisionGuid.Add(.());

		record.SkeletonGuid = fixture.CookSkeleton("rig");
		record.AnimationGuid.Add(fixture.CookClip("walk"));

		// A root that draws nothing, and a child that draws the mesh: a hierarchy carries
		// pivots as well as geometry.
		record.NodeName.Add(new String("root"));
		record.NodeParent.Add(-1);
		record.NodeTranslation.Add(.(0, 0, 0));
		record.NodeRotation.Add(Quaternion.Identity);
		record.NodeScale.Add(.(1, 1, 1));
		record.NodeMesh.Add(-1);

		record.NodeName.Add(new String("body"));
		record.NodeParent.Add(0);
		record.NodeTranslation.Add(.(0, 2, 0));
		record.NodeRotation.Add(Quaternion.Identity);
		record.NodeScale.Add(.(1, 1, 1));
		record.NodeMesh.Add(0);

		record.BoundsMin = .(-1, -1, -1);
		record.BoundsMax = .(1, 1, 1);

		let model = fixture.Manager.Bind<ModelResource>(fixture.CookModel("hero", record));
		Test.Assert(model.Get != null);
		Test.Assert(model.State == .Ready);

		Test.Assert(model.Get.Nodes.Count == 2);
		Test.Assert(model.Get.Nodes[0].Name == "root");
		Test.Assert(model.Get.Nodes[0].ParentIndex == -1);
		Test.Assert(model.Get.Nodes[0].MeshIndex == -1);
		Test.Assert(model.Get.Nodes[1].Name == "body");
		Test.Assert(model.Get.Nodes[1].ParentIndex == 0);
		Test.Assert(model.Get.Nodes[1].MeshIndex == 0);
		Test.Assert(model.Get.Nodes[1].LocalTransform.Position == Float3(0, 2, 0));

		Test.Assert(model.Get.Meshes.Count == 1);
		Test.Assert(model.Get.Mesh(0) != null, "the mesh id resolved");
		Test.Assert(!model.Get.Mesh(0).IsSkinned);

		Test.Assert(model.Get.Skeleton.Get != null);
		Test.Assert(model.Get.Skeleton.Get.FindBone("child") == 1);

		Test.Assert(model.Get.Animations.Count == 1);
		Test.Assert(model.Get.Animations[0].Get != null);

		Test.Assert(model.Get.BoundsMin == Float3(-1, -1, -1));
		Test.Assert(model.Get.BoundsMax == Float3(1, 1, 1));
	}

	/// A model with NO skin binds no skeleton, and a nil id in any list is a gap rather than
	/// an error.
	[Test]
	public static void ANilIdIsAGapRatherThanAFailure()
	{
		let fixture = scope Fixture("scratch_model_gaps");

		let record = scope ModelManifestSource();
		record.NodeName.Add(new String("root"));
		record.NodeParent.Add(-1);
		record.NodeTranslation.Add(.(0, 0, 0));
		record.NodeRotation.Add(Quaternion.Identity);
		record.NodeScale.Add(.(1, 1, 1));
		record.NodeMesh.Add(-1);
		// Left nil: no skin.
		record.AnimationGuid.Add(.());

		let model = fixture.Manager.Bind<ModelResource>(fixture.CookModel("prop", record));
		Test.Assert(model.Get != null);
		Test.Assert(model.Get.Nodes.Count == 1);
		Test.Assert(model.Get.Skeleton.Get == null);
		Test.Assert(model.Get.Animations.IsEmpty, "a nil clip id is skipped, not bound to null");
		Test.Assert(model.Get.Mesh(0) == null, "and an index naming nothing answers nothing");
		Test.Assert(model.Get.MaterialForMesh(0) == null);
	}

	/// A short parallel array falls back rather than truncating the hierarchy: the PARENT
	/// array is what says how many nodes there are.
	[Test]
	public static void AShortArrayFallsBackRatherThanTruncating()
	{
		let fixture = scope Fixture("scratch_model_short");

		let record = scope ModelManifestSource();
		record.NodeParent.Add(-1);
		record.NodeParent.Add(0);
		record.NodeParent.Add(1);
		// Only the first node is named and placed.
		record.NodeName.Add(new String("root"));
		record.NodeTranslation.Add(.(5, 0, 0));

		let model = fixture.Manager.Bind<ModelResource>(fixture.CookModel("partial", record));
		Test.Assert(model.Get != null);
		Test.Assert(model.Get.Nodes.Count == 3, "every node the parents named");
		Test.Assert(model.Get.Nodes[0].Name == "root");
		Test.Assert(model.Get.Nodes[1].Name.IsEmpty);
		Test.Assert(model.Get.Nodes[2].ParentIndex == 1);
		// The identity transform, not whatever was next in the short array.
		Test.Assert(model.Get.Nodes[1].LocalTransform.Position == Float3(0, 0, 0));
		Test.Assert(model.Get.Nodes[1].LocalTransform.Scale == Float3(1, 1, 1));
	}

	/// Something else stored under the type name is not a manifest rather than a manifest that
	/// failed to read.
	[Test]
	public static void ARecordOfTheWrongTypeBuildsNothing()
	{
		let fixture = scope Fixture("scratch_model_mismatch");
		let id = fixture.CookMesh("body");

		let model = fixture.Manager.Bind<ModelResource>(id);
		Test.Assert(model.Get == null);
	}
}
