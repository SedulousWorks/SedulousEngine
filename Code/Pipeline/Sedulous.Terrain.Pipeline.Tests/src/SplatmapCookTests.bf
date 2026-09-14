using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.VFS;

namespace Sedulous.Terrain.Pipeline.Tests;

/// The splatmap cook: a painted raster through the builder and back.
///
/// The product is written into the SAME instance the source sidecars live on, so a cooked
/// splatmap's identity is its source's. Everything the terrain resolves rests on that: it
/// names the splatmap by one id and expects the cooked raster to answer to it.
class SplatmapCookTests
{
	private const String cRoot = "scratch_terrain_splat";
	private const String cSourceRoot = "scratch_terrain_splat_src";
	private const String cProductType = "Sedulous.Terrain.Resource.SplatWeightsSource";

	private static void MakeRoots()
	{
		for (let root in scope String[](cRoot, cSourceRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		TerrainPipeline.RegisterAll();
		TerrainResources.RegisterAll();
	}

	private static void RemoveRoots()
	{
		RemoveDirectoryRecursive(cRoot);
		RemoveDirectoryRecursive(cSourceRoot);
	}

	/// Both rasters survive: the weights AND the slot indices, which together are what a top of
	/// the stack model means. Restoring one without the other would place every weight on the
	/// wrong layer.
	[Test]
	public static void BothRastersCookAndRestoreIdentically()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let authored = scope SplatWeights(16, 16);
		SplatBrush.Paint(authored, 0.5f, 0.5f, 0.3f, 0.3f, 5, 1.0f);
		Test.Assert(authored.WeightOfLayer(8, 8, 5) > 0);

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid splatId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("splat", cProductType);
			Test.Assert(instance != null);
			splatId = instance.Id;

			Test.Assert(instance.WriteData(SplatWeightsSource.WeightStream,
				SplatWeightsSource.WeightBlob(authored)) case .Ok);
			Test.Assert(instance.WriteData(SplatWeightsSource.IndexStream,
				SplatWeightsSource.IndexBlob(authored)) case .Ok);

			let asset = scope SplatmapAsset();
			asset.Width = 16;
			asset.Height = 16;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Source = instance;
			context.Output = instance; // cooked in place: the product's id IS the source's
			Test.Assert(scope SplatmapAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope SplatWeightsFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<SplatWeights>(splatId); // by the SOURCE id
		let loaded = bound.Get;
		Test.Assert(loaded != null);
		Test.Assert(loaded.Width == 16);
		Test.Assert(loaded.Height == 16);
		Test.Assert(loaded.WeightOfLayer(8, 8, 5) == authored.WeightOfLayer(8, 8, 5));
		Test.Assert(loaded.SlotIndex(8, 8, 0) == authored.SlotIndex(8, 8, 0));
		Test.Assert(loaded.BaseWeight(0, 0) == 255); // an untouched corner is pure base
	}

	/// NO sidecars cook an all zero raster, which reads as pure base everywhere.
	///
	/// Zero rather than seeded: seeding layer nought would paint a terrain the author never
	/// painted, and a blank splatmap has to mean blank.
	[Test]
	public static void NoSidecarsCookPureBase()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid splatId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("splat", cProductType);
			Test.Assert(instance != null);
			splatId = instance.Id;

			let asset = scope SplatmapAsset();
			asset.Width = 8;
			asset.Height = 8;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Source = instance;
			context.Output = instance;
			Test.Assert(scope SplatmapAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope SplatWeightsFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<SplatWeights>(splatId);
		let loaded = bound.Get;
		Test.Assert(loaded != null);
		Test.Assert(loaded.Width == 8);
		Test.Assert(loaded.BaseWeight(4, 4) == 255);
		Test.Assert(loaded.SlotWeight(4, 4, 0) == 0);
	}

	/// A source carrying only the WEIGHTS is broken, and the cook refuses it rather than
	/// guessing a layout: a guess would place real weights on arbitrary layers.
	[Test]
	public static void AWeightsOnlySidecarFailsTheCook()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("splat", cProductType);
		Test.Assert(instance != null);

		let weights = scope List<uint8>();
		weights.Count = 8 * 8 * 4;
		for (int i < weights.Count)
			weights[i] = 100;
		Test.Assert(instance.WriteData(SplatWeightsSource.WeightStream, weights) case .Ok);

		let asset = scope SplatmapAsset();
		asset.Width = 8;
		asset.Height = 8;

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Source = instance;
		context.Output = instance;
		Test.Assert(scope SplatmapAssetBuilder().Build(asset, context) case .Err);
	}

	/// An imported image is a FIXED layer raster: red is the base's share and the other three
	/// channels are palette nought to two, converted into the top of the stack form.
	[Test]
	public static void AnImportedImageDecodesAsAFixedLayerRaster()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		{
			let authored = scope Image(4, 2, .RGBA8);
			let pixels = authored.PixelData;
			for (int t < 8)
			{
				pixels[t * 4 + 0] = 128; // half base
				pixels[t * 4 + 1] = 127; // half palette nought
				pixels[t * 4 + 2] = 0;
				pixels[t * 4 + 3] = 0;
			}
			let path = scope String();
			PathJoin(cSourceRoot, "splat.png", path);
			Test.Assert(ImageIO.SaveImage(authored, path, .PNG) case .Ok);
		}

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid splatId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("s", cProductType);
			Test.Assert(instance != null);
			splatId = instance.Id;

			let asset = scope SplatmapAsset();
			asset.FileName.Set("splat.png");

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(scope SplatmapAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope SplatWeightsFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<SplatWeights>(splatId);
		let loaded = bound.Get;
		Test.Assert(loaded != null);
		Test.Assert(loaded.Width == 4); // the image's NATIVE size, with no resampling
		Test.Assert(loaded.Height == 2);
		Test.Assert(loaded.WeightOfLayer(1, 1, 0) >= 126);
		Test.Assert(loaded.WeightOfLayer(1, 1, 0) <= 128);
		Test.Assert(loaded.BaseWeight(1, 1) >= 126);
		Test.Assert(loaded.BaseWeight(1, 1) <= 129);
	}

	/// The cook STAMPS the product with the builder's product type, so it has to be the stored
	/// record rather than the runtime object: naming the runtime one makes the read build a
	/// type the factory cannot use, and the resource never binds.
	[Test]
	public static void TheProductTypesAreTheStoredRecords()
	{
		Test.Assert(scope TerrainAssetBuilder().ProductType == typeof(TerrainSource));
		Test.Assert(scope SplatmapAssetBuilder().ProductType == typeof(SplatWeightsSource));
	}
}
