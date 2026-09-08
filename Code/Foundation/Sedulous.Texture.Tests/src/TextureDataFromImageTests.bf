using System;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Tests;

/// Staging an image for upload.
class TextureDataFromImageTests
{
	[Test]
	public static void AnImageStagesAsItsOwnPixels()
	{
		let image = scope Image(2, 2, .RGBA8);
		let data = TextureData.FromImage(image, .Srgb);

		Test.Assert(data.Width == 2);
		Test.Assert(data.Height == 2);
		Test.Assert(data.Format == .RGBA8UnormSrgb);
		Test.Assert(data.Pixels.Ptr == image.PixelData.Ptr, "no copy is made");
		Test.Assert(data.Size == (uint64)image.PixelData.Length);
		Test.Assert(data.MipLevels == 1);
		Test.Assert(data.DepthOrArrayLayers == 1);
	}

	/// The stated colour space WINS over whatever the image is carrying, because it is the
	/// authoring decision and the image's is whatever the loader defaulted to.
	[Test]
	public static void TheStatedColourSpaceOverridesTheImages()
	{
		let image = scope Image(2, 2, .RGBA8);
		image.SetColorSpace(.Srgb);

		let asData = TextureData.FromImage(image, .Linear);
		Test.Assert(asData.Format == .RGBA8Unorm);

		let asColour = TextureData.FromImage(image, .Srgb);
		Test.Assert(asColour.Format == .RGBA8UnormSrgb);
	}

	/// The convenience overload takes the image at its word, for a source that carried its
	/// colour space through the load.
	[Test]
	public static void TheOverloadTakesTheImageAtItsWord()
	{
		let colour = scope Image(2, 2, .RGBA8);
		colour.SetColorSpace(.Srgb);
		Test.Assert(TextureData.FromImage(colour).Format == .RGBA8UnormSrgb);

		let normals = scope Image(2, 2, .RGBA8);
		normals.SetColorSpace(.Linear);
		Test.Assert(TextureData.FromImage(normals).Format == .RGBA8Unorm);
	}

	/// It stages any ImageData, not just an Image: a view over somebody else's buffer
	/// stages the same way, which is what a cook streaming from a file hands over.
	[Test]
	public static void AnyImageDataStages()
	{
		uint8[16] pixels = .();
		let view = scope OwnedImageData(2, 2, .RGBA8, .(&pixels[0], 16), .Linear);

		let data = TextureData.FromImage(view);
		Test.Assert(data.Format == .RGBA8Unorm);
		Test.Assert(data.Width == 2);
		Test.Assert(data.Size == 16);
	}
}
