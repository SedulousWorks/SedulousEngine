using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Physics.Pipeline.Tests;

/// The collision cook from a mesh to a body that simulates.
///
/// End to end, because a blob that cooks but that the engine refuses is a collider that is
/// simply not there, and only creating a real body says which.
class CollisionShapeCookTests
{
	private const String cSourceRoot = "scratch_physics_pipeline_src";
	private const String cCookedRoot = "scratch_physics_pipeline_out";
	private const String cMeshAssetType = "Sedulous.Geometry.Pipeline.StaticMeshAsset";
	private const String cMeshProductType = "Sedulous.Geometry.StaticMeshSource";
	private const String cShapeProductType = "Sedulous.Physics.Resource.CollisionShapeSource";

	private static void MakeRoots()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
	}

	private static void RemoveRoots()
	{
		RemoveDirectoryRecursive(cSourceRoot);
		RemoveDirectoryRecursive(cCookedRoot);
	}

	private static void Register()
	{
		PhysicsPipeline.RegisterAll();
		PhysicsResources.RegisterAll();
		GeometryPipeline.RegisterAll();
		GeometryResources.RegisterAll();
	}

	/// Both cook kinds produce a shape that loads and drives a real body. A triangle mesh has
	/// to be static; a hull may fall.
	[Test]
	public static void BothCookKindsProduceAShapeABodyCanUse()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let sourceDb = scope ContentDatabase(sourceMount, serializers, "xasset");
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let meshInstance = sourceDb.RootGroup.CreateInstance("cube", cMeshAssetType);
		Test.Assert(meshInstance != null);
		{
			let meshAsset = scope StaticMeshAsset();
			let cube = Primitives.Cube(1.0f);
			defer delete cube;
			StaticMeshSource.FromMesh(cube, meshAsset.Source);
			Test.Assert(MeshAssetStorage.WriteStatic(meshInstance, meshAsset) case .Ok);
		}

		for (let kind in scope CollisionCookKind[](.ConvexHull, .TriangleMesh))
		{
			let asset = scope CollisionShapeAsset();
			asset.SourceMesh = meshInstance.Id;
			asset.Cook = kind;

			let builder = scope CollisionShapeAssetBuilder();
			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.SourceDatabase = sourceDb;
			context.Database = sourceDb;

			// The mesh is a hash chained READ: editing it has to re-cook the shape, because
			// the shape IS the mesh in another form.
			let dependencies = scope AssetDependencies();
			builder.ScanDependencies(asset, context, dependencies);
			Test.Assert(dependencies.Reads.Count == 1);
			Test.Assert(dependencies.Reads[0] == meshInstance.Id);

			let existing = cookedDb.RootGroup.GetInstance("shape");
			let outInstance = (existing != null) ? existing
				: cookedDb.RootGroup.CreateInstance("shape", cShapeProductType);
			context.Output = outInstance;
			Test.Assert(builder.Build(asset, context) case .Ok);

			let manager = scope ResourceManager(cookedDb, null);
			let factory = scope CollisionShapeFactory();
			manager.AddFactory(factory);

			let bound = manager.Bind<CollisionShape>(outInstance.Id);
			let shape = bound.Get;
			Test.Assert(shape != null);
			Test.Assert(shape.Convex == (kind == .ConvexHull));
			Test.Assert(!shape.Blob.IsEmpty);
			Test.Assert(!shape.Outline.IsEmpty);
			Test.Assert((shape.Outline.Count % 3) == 0);

			let world = scope PhysicsWorld();
			let desc = scope BodyDesc();
			desc.Motion = (kind == .ConvexHull) ? MotionKind.Dynamic : MotionKind.Static;
			desc.Layer = (desc.Motion == .Static) ? PhysicsLayer.Static : PhysicsLayer.Dynamic;
			var shapeDesc = ShapeDesc();
			shapeDesc.Kind = .Cooked;
			shapeDesc.Cooked = shape.Bytes;
			desc.Shapes.Add(shapeDesc);
			Test.Assert(world.CreateBody(desc).IsValid);
		}
	}

	/// The cook reads the mesh's cooked PRODUCT, not its authoring envelope.
	///
	/// Which is what the driver hands it: by the time a shape cooks, the mesh it names has
	/// already cooked, and the identity resolves to a StaticMeshSource. Casting to the asset
	/// instead failed every generated collision cook.
	[Test]
	public static void TheCookReadsTheMeshProduct()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let productDb = scope ContentDatabase(sourceMount, serializers, "rasset");
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let meshInstance = productDb.RootGroup.CreateInstance("cube", cMeshProductType);
		Test.Assert(meshInstance != null);
		{
			let meshSource = scope StaticMeshSource();
			let cube = Primitives.Cube(1.0f);
			defer delete cube;
			StaticMeshSource.FromMesh(cube, meshSource);
			Test.Assert(meshInstance.WriteObject(meshSource) case .Ok);
		}

		let asset = scope CollisionShapeAsset();
		asset.SourceMesh = meshInstance.Id;
		asset.Cook = .ConvexHull;

		let outInstance = cookedDb.RootGroup.CreateInstance("shape", cShapeProductType);
		Test.Assert(outInstance != null);

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.SourceDatabase = productDb;
		context.Database = productDb;
		context.Output = outInstance;
		Test.Assert(scope CollisionShapeAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(cookedDb, null);
		let factory = scope CollisionShapeFactory();
		manager.AddFactory(factory);
		let bound = manager.Bind<CollisionShape>(outInstance.Id);
		let shape = bound.Get;
		Test.Assert(shape != null);
		Test.Assert(shape.Convex);
		Test.Assert(!shape.Blob.IsEmpty);
	}

	[Test]
	public static void APhysicalMaterialCooksAndLoads()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let instance = cookedDb.RootGroup.CreateInstance("surface",
			"Sedulous.Physics.Resource.PhysicalMaterialSource");
		Test.Assert(instance != null);

		let asset = scope PhysicalMaterialAsset();
		asset.Friction = 0.9f;
		asset.Restitution = 0.25f;
		asset.Density = 2500.0f;

		let context = scope AssetBuildContext();
		context.Output = instance;
		Test.Assert(scope PhysicalMaterialAssetBuilder().Build(asset, context) case .Ok);

		let manager = scope ResourceManager(cookedDb, null);
		let factory = scope PhysicalMaterialFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<PhysicalMaterial>(instance.Id);
		let material = bound.Get;
		Test.Assert(material != null);
		Test.Assert(Abs(material.Friction - 0.9f) < 0.001f);
		Test.Assert(Abs(material.Restitution - 0.25f) < 0.001f);
		Test.Assert(Abs(material.Density - 2500.0f) < 0.01f);
	}
}
