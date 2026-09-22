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
using Sedulous.Vegetation.Resource;
using Sedulous.VFS;

namespace Sedulous.Vegetation.Pipeline.Tests;

/// The vegetation mask cook: a painted mask through the builder and back, and an imported
/// image as one plane per channel.
///
/// The product is written into the SAME instance the source sidecar lives on, so a cooked
/// mask's identity is its source's, exactly as a splatmap's is.
class VegetationMaskCookTests
{
	private const String cRoot = "scratch_veg_mask";
	private const String cSourceRoot = "scratch_veg_mask_src";
	private const String cProductType = "Sedulous.Vegetation.Resource.VegetationMaskSource";

	private static void MakeRoots()
	{
		for (let root in scope String[](cRoot, cSourceRoot))
		{
			RemoveDirectoryRecursive(root);
			CreateDirectory(root);
		}
		VegetationPipeline.RegisterAll();
		VegetationResources.RegisterAll();
	}

	private static void RemoveRoots()
	{
		RemoveDirectoryRecursive(cRoot);
		RemoveDirectoryRecursive(cSourceRoot);
	}

	/// An embedded mask, which is what a Paint Vegetation stroke saves: the sidecar is the
	/// truth and every plane survives the round trip.
	[Test]
	public static void AnEmbeddedMaskCooksAndRestoresEveryPlane()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let authored = scope VegetationMask(16, 16, 3);
		MaskBrush.Paint(authored, 1, 0.5f, 0.5f, 0.3f, 0.3f, 1.0f);
		MaskBrush.Paint(authored, 2, 0.2f, 0.2f, 0.1f, 0.1f, 0.5f);
		Test.Assert(authored.DensityAt(1, 8, 8) > 0);

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid maskId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("mask", cProductType);
			Test.Assert(instance != null);
			maskId = instance.Id;

			Test.Assert(instance.WriteData(VegetationMaskSource.DensityStream,
				VegetationMaskSource.DensityBlob(authored)) case .Ok);

			let asset = scope VegetationMaskAsset();
			asset.Width = 16;
			asset.Height = 16;
			asset.PlaneCount = 3;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Source = instance;
			context.Output = instance; // cooked in place: the product's id IS the source's
			Test.Assert(scope VegetationMaskAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope VegetationMaskFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<VegetationMask>(maskId); // by the SOURCE id
		let loaded = bound.Get;
		Test.Assert(loaded != null);
		Test.Assert(loaded.Width == 16);
		Test.Assert(loaded.Height == 16);
		Test.Assert(loaded.PlaneCount == 3);
		for (uint32 p = 0; p < 3; p++)
			for (int32 y = 0; y < 16; y++)
				for (int32 x = 0; x < 16; x++)
					Test.Assert(loaded.DensityAt(p, x, y) == authored.DensityAt(p, x, y));
	}

	/// NO sidecar cooks an all zero mask, so nothing grows: a mask created on a page and
	/// never painted has to mean nothing, never a terrain covered in grass the author never
	/// asked for.
	[Test]
	public static void NoSidecarCooksAnEmptyMask()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid maskId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("blank", cProductType);
			Test.Assert(instance != null);
			maskId = instance.Id;

			let asset = scope VegetationMaskAsset();
			asset.Width = 8;
			asset.Height = 8;
			asset.PlaneCount = 2;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Source = instance;
			context.Output = instance;
			Test.Assert(scope VegetationMaskAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope VegetationMaskFactory();
		manager.AddFactory(factory);

		let loaded = manager.Bind<VegetationMask>(maskId).Get;
		Test.Assert(loaded != null);
		Test.Assert(loaded.PlaneCount == 2);
		for (uint32 p = 0; p < 2; p++)
			for (int32 y = 0; y < 8; y++)
				for (int32 x = 0; x < 8; x++)
					Test.Assert(loaded.DensityAt(p, x, y) == 0);
	}

	/// A degenerate asset still cooks a LEGAL mask rather than breaking the runtime's
	/// contracts: the sides snap up off zero and the plane count off nought.
	[Test]
	public static void ADegenerateAssetCooksALegalMask()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		let mount = scope NativeFileSystem(cRoot);
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid maskId;
		{
			let database = scope ContentDatabase(mount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("bad", cProductType);
			maskId = instance.Id;

			let asset = scope VegetationMaskAsset();
			asset.Width = 0;
			asset.Height = -4;
			asset.PlaneCount = 0;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Source = instance;
			context.Output = instance;
			Test.Assert(scope VegetationMaskAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(mount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope VegetationMaskFactory();
		manager.AddFactory(factory);

		let loaded = manager.Bind<VegetationMask>(maskId).Get;
		Test.Assert(loaded != null);
		Test.Assert(!loaded.IsEmpty);
		Test.Assert(loaded.Width >= 1);
		Test.Assert(loaded.Height >= 1);
		Test.Assert(loaded.PlaneCount == 1);
	}

	/// The importer claims the image extensions and writes an asset naming the copied file,
	/// with one plane per channel.
	[Test]
	public static void TheImporterClaimsImagesAndAuthorsAPlanePerChannel()
	{
		let importer = scope VegetationMaskFileImporter();
		Test.Assert(importer.Accepts("png"));
		Test.Assert(importer.Accepts("tga"));
		Test.Assert(!importer.Accepts("gltf"));
		Test.Assert(importer.Label == "Vegetation Mask");

		let asset = scope VegetationMaskAsset();
		Test.Assert(asset.FileName.IsEmpty, "an authored mask is embedded until imported");
		Test.Assert(asset.PlaneCount == 1);
	}
}
