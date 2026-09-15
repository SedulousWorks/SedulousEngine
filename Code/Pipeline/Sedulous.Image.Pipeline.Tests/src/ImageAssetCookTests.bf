using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Image.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Image.Pipeline.Tests;

/// The CPU image pipeline: a file on disk, cooked into a product, loaded back through the
/// manager. No device anywhere, since a CPU image never touches one.
class ImageAssetCookTests
{
	private const String cSourceRoot = "scratch_image_pipeline_src";
	private const String cCookedRoot = "scratch_image_pipeline_out";
	private const String cProductType = "Sedulous.Image.Resource.ImageResource";

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

	[Test]
	public static void AnImageFileCooksAndLoadsBackWithItsPixels()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		ImagePipeline.RegisterAll();
		ImageResources.RegisterAll();

		// A KNOWN two by two image, so every byte of the round trip is checkable.
		let path = scope String();
		PathJoin(cSourceRoot, "icon.png", path);
		{
			let source = scope Image(2, 2, .RGBA8);
			let pixels = source.PixelData;
			for (int i < pixels.Length)
				pixels[i] = (uint8)(i * 7);
			Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Ok);
		}

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);

		Guid id;
		{
			let database = scope ContentDatabase(cookedMount, serializers, "rasset");
			let instance = database.RootGroup.CreateInstance("icon", cProductType);
			Test.Assert(instance != null);
			id = instance.Id;

			let asset = scope ImageAsset();
			asset.FileName.Set("icon.png");
			asset.ColorSpace = .Srgb;

			let context = scope AssetBuildContext();
			context.Sources = sourceMount;
			context.Output = instance;
			Test.Assert(scope ImageAssetBuilder().Build(asset, context) case .Ok);
		}

		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let manager = scope ResourceManager(database, null);
		let factory = scope ImageFactory();
		manager.AddFactory(factory);

		let bound = manager.Bind<ImageResource>(id);
		let image = bound.Get;
		Test.Assert(image != null);
		Test.Assert(image.Width == 2);
		Test.Assert(image.Height == 2);
		Test.Assert(image.Format == .RGBA8);
		Test.Assert(image.ColorSpace == .Srgb);

		Test.Assert(image.Pixels.Length == 2 * 2 * 4);
		for (int i < image.Pixels.Length)
			Test.Assert(image.Pixels[i] == (uint8)(i * 7), scope $"byte {i}");

		// The view borrows the resource's own pixels rather than copying them, but the view
		// itself is the caller's.
		let view = image.View();
		defer delete view;
		Test.Assert(view.Width == 2);
		Test.Assert(view.PixelData.Ptr == image.Pixels.Ptr);
	}

	/// A source file that is not there is an ERROR rather than an empty image.
	[Test]
	public static void AMissingSourceFileFailsTheBuild()
	{
		MakeRoots();
		defer { RemoveRoots(); }

		ImagePipeline.RegisterAll();
		ImageResources.RegisterAll();

		let sourceMount = scope NativeFileSystem(cSourceRoot);
		let cookedMount = scope NativeFileSystem(cCookedRoot);
		SerializerFactory serializers = scope (stream, mode) =>
			new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(cookedMount, serializers, "rasset");
		let instance = database.RootGroup.CreateInstance("icon", cProductType);
		Test.Assert(instance != null);

		let asset = scope ImageAsset();
		asset.FileName.Set("does_not_exist.png");

		let context = scope AssetBuildContext();
		context.Sources = sourceMount;
		context.Output = instance;
		Test.Assert(scope ImageAssetBuilder().Build(asset, context) case .Err);
	}
}
