using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Heightfield.Resource;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Heightfield.Pipeline.Tests;

/// The heightfield cook: blank, from an image, and from an authored sculpt.
class HeightfieldCookTests
{
	private const String cSourceRoot = "scratch_heightfield_pipeline_src";
	private const String cCookedRoot = "scratch_heightfield_pipeline_out";
	private const String cProductType = "Sedulous.Heightfield.Resource.HeightfieldSource";

	private static bool Near(float a, float b, float tolerance = 0.001f) => Abs(a - b) <= tolerance;

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
		HeightfieldPipeline.RegisterAll();
		HeightfieldResources.RegisterAll();
	}

	/// Cooks the asset and binds the product, running the delegate with the bound field.
	///
	/// A delegate rather than a return, because everything the case reads BORROWS from the
	/// manager and the database, and both have to outlive the reading.
	private static void CookAndBind(HeightfieldAsset asset, delegate void(Heightfield field) body)
	{
		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("hf", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(scope HeightfieldAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope HeightfieldFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<Heightfield>(id);
		Test.Assert(bound.Get != null);
		body(bound.Get);
	}

	/// The resample lands the source corners exactly and averages between them.
	[Test]
	public static void TheResampleIsBilinearOntoTheGrid()
	{
		let source = scope uint16[](0, 20000, 40000, 60000);
		let field = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		HeightmapResample.ResampleR16(source.Ptr, 2, 2, field);

		Test.Assert(field.GetSample(0, 0) == 0);
		Test.Assert(field.GetSample(64, 0) == 20000);
		Test.Assert(field.GetSample(0, 64) == 40000);
		Test.Assert(field.GetSample(64, 64) == 60000);
		// The centre is the average of the four corners.
		Test.Assert(Abs((int)field.GetSample(32, 32) - 30000) < 300);
	}

	[Test]
	public static void ABlankAssetCooksAFlatGrid()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let asset = scope HeightfieldAsset(); // no file name, so blank
		asset.Size = 65;
		asset.WorldSize = .(64.0f, 64.0f);
		asset.MinY = -2.0f;
		asset.MaxY = 12.0f;

		CookAndBind(asset, scope (field) =>
			{
				Test.Assert(field.Size == 65);
				Test.Assert(Near(field.WorldSize.X, 64.0f));
				Test.Assert(Near(field.MinY, -2.0f));
				Test.Assert(Near(field.MaxY, 12.0f));
				Test.Assert(field.GetSample(10, 10) == 0);
			});
	}

	/// A grid has to be sixty four times a whole number plus one, so an authored size that is
	/// not snaps UP rather than cooking something the sampler cannot index.
	[Test]
	public static void AnInvalidSizeSnapsToTheNextValidOne()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let asset = scope HeightfieldAsset();
		asset.Size = 100;
		asset.WorldSize = .(64.0f, 64.0f);

		CookAndBind(asset, scope (field) => Test.Assert(field.Size == 129));
	}

	/// A heightmap image becomes the grid, keeping the gradient's direction and its extremes.
	[Test]
	public static void AHeightmapImageCooksIntoTheGrid()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		// A grey ramp rising along +X. The loader promotes eight bit samples to sixteen.
		{
			let source = scope Image(8, 8, .R8);
			for (uint32 y < 8)
			{
				for (uint32 x < 8)
				{
					let value = (uint8)(x * 36);
					source.SetPixel(x, y, .(value, value, value, 255));
				}
			}
			let path = scope String();
			PathJoin(cSourceRoot, "ramp.png", path);
			Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Ok);
		}

		let asset = scope HeightfieldAsset();
		asset.FileName.Set("ramp.png");
		asset.Size = 65;
		asset.WorldSize = .(64.0f, 64.0f);
		asset.MinY = 0.0f;
		asset.MaxY = 10.0f;

		CookAndBind(asset, scope (field) =>
			{
				Test.Assert(field.Size == 65);
				Test.Assert(field.GetSample(0, 0) == 0);
				Test.Assert(field.GetSample(64, 0) > field.GetSample(0, 0));
				Test.Assert(field.GetSample(64, 0) > 60000);
				Test.Assert(field.GetSample(32, 0) > field.GetSample(0, 0));
				Test.Assert(field.GetSample(32, 0) < field.GetSample(64, 0));
				// The ramp runs along X only, so every row is the same.
				Test.Assert(field.GetSample(20, 0) == field.GetSample(20, 40));
			});
	}

	/// A hand edited asset with no footprint and a closed height range still has to cook a grid
	/// whose arithmetic is finite, which is the same defensive posture as the size snap.
	[Test]
	public static void DegenerateExtentsSnapToLegalValues()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let asset = scope HeightfieldAsset();
		asset.Size = 65;
		asset.WorldSize = .(0.0f, 0.0f);
		asset.MinY = 5.0f;
		asset.MaxY = 5.0f;

		CookAndBind(asset, scope (field) =>
			{
				Test.Assert(!field.IsEmpty);
				Test.Assert(field.WorldSize.X > 0.0f);
				Test.Assert(field.WorldSize.Y > 0.0f);
				Test.Assert(field.MaxY > field.MinY);
				let height = field.GetHeightAt(0.0f, 0.0f);
				Test.Assert(height == height); // finite rather than not a number
			});
	}

	/// An EMBEDDED asset cooks from the authored sidecar, which is what a sculpt save writes,
	/// and the sidecar is declared so that painting it re-cooks. A file backed asset ignores
	/// it: the file is the truth, and a re-import resets.
	[Test]
	public static void AnEmbeddedAssetCooksFromItsAuthoredSidecar()
	{
		MakeRoots();
		defer { RemoveRoots(); }
		Register();

		let authored = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 10.0f);
		authored.SetSample(10, 12, 4321);
		authored.SetSample(33, 40, 60000);

		let asset = scope HeightfieldAsset(); // no file name, so the sidecar is the truth
		asset.Size = 65;
		asset.WorldSize = .(64.0f, 64.0f);
		asset.MinY = 0.0f;
		asset.MaxY = 10.0f;

		let builder = scope HeightfieldAssetBuilder();
		{
			let dependencies = scope AssetDependencies();
			builder.ScanDependencies(asset, scope AssetBuildContext(), dependencies);
			// Both authored sidecars: a hole stroke has to re-cook as surely as a sculpt.
			Test.Assert(dependencies.SourceStreams.Count == 2);
			Test.Assert(dependencies.SourceStreams[0] == HeightfieldSource.HeightStream);
			Test.Assert(dependencies.SourceStreams[1] == HeightfieldSource.HoleStream);

			let imported = scope HeightfieldAsset();
			imported.FileName.Set("some.png");
			let importedDependencies = scope AssetDependencies();
			builder.ScanDependencies(imported, scope AssetBuildContext(), importedDependencies);
			Test.Assert(importedDependencies.SourceStreams.IsEmpty);
		}

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("hf", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;
			Test.Assert(instance.WriteData(HeightfieldSource.HeightStream,
				HeightfieldSource.HeightBlob(authored)) case .Ok);

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Source = instance; // the authored sidecar lives here
			context.Output = instance;
			Test.Assert(builder.Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope HeightfieldFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<Heightfield>(id);
		let field = bound.Get;
		Test.Assert(field != null);
		Test.Assert(field.GetSample(10, 12) == 4321); // the sculpt survived the cook
		Test.Assert(field.GetSample(33, 40) == 60000);
		Test.Assert(field.GetSample(1, 1) == 0);
	}

	/// The cook STAMPS the product instance with the builder's product type. Naming the runtime
	/// field instead makes the read build the wrong type and the resource never binds.
	[Test]
	public static void TheProductTypeIsTheSourceRecord()
	{
		Test.Assert(scope HeightfieldAssetBuilder().ProductType == typeof(HeightfieldSource));
	}
}
