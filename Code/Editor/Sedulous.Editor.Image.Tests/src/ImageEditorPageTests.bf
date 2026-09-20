using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Image.Tests;

/// The image editor's registration and its headless undo snapshot.
class ImageEditorPageTests
{
	[Test]
	public static void TheFactoryReportsTheImageAssetPrimaryType()
	{
		let factory = scope ImageEditorPageFactory();
		Test.Assert(factory.PrimaryType == typeof(ImageAsset));
	}

	[Test]
	public static void RegisteringRoutesImageAssetToTheFactory()
	{
		let context = scope EditorContext();
		ImageEditor.Register(context);
		let found = context.Pages.FindFactory(typeof(ImageAsset));
		Test.Assert(found != null);
		Test.Assert(found.PrimaryType == typeof(ImageAsset));
	}

	[Test]
	public static void TheSnapshotRoundTripsFileNameAndColorSpace()
	{
		ImagePipeline.RegisterAll();
		let a = scope ImageAsset();
		a.FileName.Set("Textures/rock.png");
		a.ColorSpace = .Linear;
		let blob = scope List<uint8>();
		ImageAssetEdit.Snapshot(a, blob);
		Test.Assert(blob.Count > 0);

		let b = scope ImageAsset();
		Test.Assert(ImageAssetEdit.Apply(b, blob));
		Test.Assert(b.FileName.Value == "Textures/rock.png");
		Test.Assert(b.ColorSpace == .Linear);
		// The same bytes again is a no-op.
		Test.Assert(!ImageAssetEdit.Apply(b, blob));

		Test.Assert(ImageAssetEdit.PixelFormatLabel(.RGBA32F) == "RGBA32F (HDR)");
		Test.Assert(ImageAssetEdit.PixelFormatLabel(.R16F) == "?");
	}
}
