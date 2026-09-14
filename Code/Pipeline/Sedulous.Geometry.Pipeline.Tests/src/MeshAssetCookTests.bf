using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Geometry.Pipeline.Tests;

/// The mesh cook, and the sidecar split it writes through.
class MeshAssetCookTests
{
	private const String cRoot = "scratch_geometry_pipeline";
	private const String cStaticProduct = "Sedulous.Geometry.StaticMeshSource";
	private const String cSkinnedProduct = "Sedulous.Geometry.SkinnedMeshSource";
	private const String cStaticAsset = "Sedulous.Geometry.Pipeline.StaticMeshAsset";

	private static void MakeRoot()
	{
		RemoveDirectoryRecursive(cRoot);
		CreateDirectory(cRoot);
		GeometryPipeline.RegisterAll();
		GeometryResources.RegisterAll();
	}

	[Test]
	public static void AStaticMeshCooksIntoItsSource()
	{
		MakeRoot();
		defer { RemoveDirectoryRecursive(cRoot); }

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("cube", cStaticProduct);
			Test.Assert(instance != null);
			id = instance.Id;

			let cube = Primitives.Cube(1.0f);
			defer delete cube;

			let asset = scope StaticMeshAsset();
			MeshImporter.Import(cube, asset);

			let builder = scope StaticMeshAssetBuilder();
			Test.Assert(builder.AssetType == typeof(StaticMeshAsset));
			let context = scope AssetBuildContext();
			context.Output = instance;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let object = database.ReadObject(id);
		Test.Assert(object != null);
		let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as StaticMeshSource;
		Test.Assert(cooked != null);
		defer delete cooked;

		// A cube is twenty four vertices, because the six faces do not share normals.
		Test.Assert(cooked.VertexBlob.Count == 24 * sizeof(StaticMeshVertex));
		Test.Assert(cooked.IndexData.Count == 36);
		Test.Assert(cooked.SubStart.Count == 1);
	}

	[Test]
	public static void ASkinnedMeshCooksWithItsParallelStream()
	{
		MakeRoot();
		defer { RemoveDirectoryRecursive(cRoot); }

		let mount = scope NativeFileSystem(cRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("skinned", cSkinnedProduct);
			Test.Assert(instance != null);
			id = instance.Id;

			let mesh = scope SkinnedMesh();
			mesh.SkeletonIndex = 4;
			mesh.Vertices.Add(StaticMeshVertex());
			mesh.Vertices.Add(StaticMeshVertex());
			var bind = VertexSkinning();
			bind.Joints[1] = 9;
			mesh.Skinning.Add(bind);
			mesh.Skinning.Add(bind);

			let asset = scope SkinnedMeshAsset();
			MeshImporter.Import(mesh, asset);

			let context = scope AssetBuildContext();
			context.Output = instance;
			Test.Assert(scope SkinnedMeshAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let object = database.ReadObject(id);
		Test.Assert(object != null);
		let cooked = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as SkinnedMeshSource;
		Test.Assert(cooked != null);
		defer delete cooked;

		Test.Assert(cooked.VertexBlob.Count == 2 * sizeof(StaticMeshVertex));
		Test.Assert(cooked.SkinningBlob.Count == 2 * sizeof(VertexSkinning));
		Test.Assert(cooked.SkeletonIndex == 4);
	}

	/// The envelope no longer scales with the geometry.
	///
	/// The incident behind the split: an imported scene wrote a 170 megabyte text envelope,
	/// vertex arrays and all, and every project open parsed the whole thing to read three
	/// header fields. The bulk now travels in a binary sidecar beside it.
	[Test]
	public static void TheEnvelopeStaysTinyAndTheSidecarCarriesTheGeometry()
	{
		MakeRoot();
		defer { RemoveDirectoryRecursive(cRoot); }

		let mount = scope NativeFileSystem(cRoot);
		// TEXT on purpose: the envelope's size is only a question worth asking in the format
		// that made it one.
		SerializerFactory serializers = scope (stream, mode) =>
			new XmlSerializerContext(stream, mode);

		Guid id;
		var authoredBytes = 0;
		{
			let database = scope ContentDatabase(mount, serializers, "xasset");
			let instance = database.RootGroup.CreateInstance("sphere", cStaticAsset);
			Test.Assert(instance != null);
			id = instance.Id;

			let sphere = Primitives.Sphere(1.0f, 32, 32); // real bulk
			defer delete sphere;

			let asset = scope StaticMeshAsset();
			MeshImporter.Import(sphere, asset);
			authoredBytes = asset.Source.VertexBlob.Count;
			Test.Assert(authoredBytes > 0);
			Test.Assert(MeshAssetStorage.WriteStatic(instance, asset) case .Ok);
		}

		{
			let envelope = mount.Open("sphere.xasset", .Read);
			Test.Assert(envelope != null);
			defer delete envelope;
			Test.Assert(envelope.Size() < (4 * 1024)); // inline, this sphere was half a megabyte
		}

		let database = scope ContentDatabase(mount, serializers, "xasset");
		let instance = database.GetInstance(id);
		Test.Assert(instance != null);

		let object = instance.ReadObject();
		Test.Assert(object != null);
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
			as StaticMeshAsset;
		Test.Assert(asset != null);
		defer delete asset;

		Test.Assert(asset.Source.VertexBlob.IsEmpty); // the envelope carries no bulk
		Test.Assert(MeshAssetStorage.EnsureStaticLoaded(instance, asset) case .Ok);
		Test.Assert(asset.Source.VertexBlob.Count == authoredBytes);

		// And the BUILD loads the sidecar itself, given only the envelope's read.
		let outInstance = database.RootGroup.CreateInstance("sphere_cooked", cStaticProduct);
		Test.Assert(outInstance != null);

		let freshObject = instance.ReadObject();
		Test.Assert(freshObject != null);
		let fresh = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(freshObject))
			as StaticMeshAsset;
		Test.Assert(fresh != null);
		defer delete fresh;

		let context = scope AssetBuildContext();
		context.Source = instance;
		context.Output = outInstance;
		Test.Assert(scope StaticMeshAssetBuilder().Build(fresh, context) case .Ok);
	}
}
