using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Navigation;
using Sedulous.Navigation.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Navigation.Pipeline.Tests;

/// A baked zone from the bake to a query: the blob into an asset, cooked into a product, bound
/// through the factory, and pathed across.
///
/// The whole chain in one case on purpose. A blob that survives the cook but arrives unreadable
/// is a zone nothing can walk, and only the query at the end says which.
class NavigationZoneCookTests
{
	private const String cSourceRoot = "scratch_nav_pipeline_src";
	private const String cCookedRoot = "scratch_nav_pipeline_out";
	private const String cAssetType = "Sedulous.Navigation.Pipeline.NavigationZoneAsset";
	private const String cProductType = "Sedulous.Navigation.Resource.NavigationZoneSource";

	/// A twenty by twenty ground quad on the zero plane, wound so both triangles are walkable.
	private static void GroundSoup(List<Float3> outVertices, List<uint32> outIndices)
	{
		outVertices.Add(.(-10, 0, -10));
		outVertices.Add(.(10, 0, -10));
		outVertices.Add(.(10, 0, 10));
		outVertices.Add(.(-10, 0, 10));
		outIndices.AddRange(scope uint32[](0, 3, 2, 0, 2, 1));
	}

	[Test]
	public static void ABakedZoneCooksAndPathsAcross()
	{
		for (let root in scope String[](cSourceRoot, cCookedRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		defer
		{
			RemoveDirectoryRecursive(cSourceRoot);
			RemoveDirectoryRecursive(cCookedRoot);
		}

		NavigationPipeline.RegisterAll();
		NavigationResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let sourceDb = scope ContentDatabase(sourceMount, serializers, "xasset");
		let cookedDb = scope ContentDatabase(cookedMount, serializers, "rasset");

		let vertices = scope List<Float3>();
		let indices = scope List<uint32>();
		GroundSoup(vertices, indices);

		let blob = scope List<uint8>();
		Test.Assert(NavigationMeshBuilder.Build(vertices, indices, .(), blob) case .Ok);
		Test.Assert(!blob.IsEmpty);

		let zoneInstance = sourceDb.RootGroup.CreateInstance("zone", cAssetType);
		Test.Assert(zoneInstance != null);
		{
			let asset = scope NavigationZoneAsset();
			asset.NavMeshBlob.AddRange(blob);
			Test.Assert(NavigationZoneStorage.Write(zoneInstance, asset) case .Ok);
		}

		// The envelope alone carries NO blob. It is a text capable format, and a navmesh in it
		// would be megabytes of encoded bytes every project open has to parse.
		{
			let object = zoneInstance.ReadObject();
			Test.Assert(object != null);
			let readBack = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as NavigationZoneAsset;
			Test.Assert(readBack != null);
			defer delete readBack;

			Test.Assert(readBack.NavMeshBlob.IsEmpty);
			Test.Assert(NavigationZoneStorage.EnsureNavMeshLoaded(zoneInstance, readBack) case .Ok);
			Test.Assert(readBack.NavMeshBlob.Count == blob.Count); // the sidecar has it
		}

		let outInstance = cookedDb.RootGroup.CreateInstance("zone", cProductType);
		Test.Assert(outInstance != null);
		{
			let asset = scope NavigationZoneAsset();
			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Database = sourceDb;
			context.Source = zoneInstance; // the sidecar lives on the source instance
			context.Output = outInstance;

			let builder = scope NavigationZoneAssetBuilder();

			// The baked sidecar IS the build's input, so the recipe has to cover it: the
			// envelope carries nothing, and a re-bake would otherwise not dirty the cook.
			let dependencies = scope AssetDependencies();
			builder.ScanDependencies(asset, context, dependencies);
			Test.Assert(dependencies.SourceStreams.Count == 1);
			Test.Assert(dependencies.SourceStreams[0] == "navmesh");

			Test.Assert(builder.Build(asset, context) case .Ok);

			let object = outInstance.ReadObject();
			Test.Assert(object != null);
			let product = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object))
				as NavigationZoneSource;
			Test.Assert(product != null);
			defer delete product;
			Test.Assert(product.NavMeshBlob.Count == blob.Count);
		}

		let manager = scope ResourceManager(cookedDb, null);
		let factory = scope NavigationZoneFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<NavigationZoneResource>(outInstance.Id);
		let zone = bound.Get;
		Test.Assert(zone != null);
		Test.Assert(zone.IsValid);

		let query = scope NavigationMeshQuery(zone.Mesh);
		Test.Assert(query.IsValid);
		let path = scope NavigationPath();
		Test.Assert(query.FindPath(.(-8, 0, 0), .(8, 0, 0), path) case .Ok);
		Test.Assert(path.Complete);
	}
}
