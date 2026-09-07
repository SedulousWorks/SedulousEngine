using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Image.Tests;

/// The ImageData family: the abstract base every consumer takes, the plain owning buffer,
/// and the borrowed view.
class ImageDataTests
{
	[Test]
	public static void AnOwnedImageCopiesWhatItIsGiven()
	{
		uint8[16] pixels = default;
		for (int i < 16)
			pixels[i] = (uint8)i;

		let image = scope OwnedImageData(2, 2, .RGBA8, .(&pixels[0], 16));
		Test.Assert(image.Width == 2 && image.Height == 2);
		Test.Assert(image.Format == .RGBA8);
		Test.Assert(image.ColorSpace == .Srgb, "sRGB unless told otherwise");
		Test.Assert(image.PixelData.Length == 16);
		Test.Assert(image.PixelData[0] == 0);
		Test.Assert(image.PixelData[4] == 4);

		// A copy, so writing through the source afterwards changes nothing here.
		pixels[4] = 99;
		Test.Assert(image.PixelData[4] == 4);
	}

	/// The other constructor takes the buffer itself, which is what a producer that just
	/// built one wants: no second copy of a whole image it is about to drop.
	[Test]
	public static void AnOwnedImageCanAdoptABufferOutright()
	{
		let pixels = new List<uint8>();
		pixels.Resize(8);
		pixels[0] = 255;
		pixels[7] = 128;

		let image = scope OwnedImageData(2, 1, .RGBA8, pixels);
		Test.Assert(image.Width == 2 && image.Height == 1);
		Test.Assert(image.PixelData.Length == 8);
		Test.Assert(image.PixelData[0] == 255);
		Test.Assert(image.PixelData[7] == 128);

		// Adopted, not copied: the image is now the only owner and frees it.
		Test.Assert(image.PixelData.Ptr == pixels.Ptr);
	}

	[Test]
	public static void AnOwnedImageCarriesSingleChannelDataToo()
	{
		let pixels = new List<uint8>();
		pixels.Resize(4);
		let image = scope OwnedImageData(2, 2, .R8, pixels);
		Test.Assert(image.Format == .R8);
		Test.Assert(image.PixelData.Length == 4);
		Test.Assert(image.DataSize == 4);
	}

	/// DataSize is what the dimensions and format IMPLY, which a short buffer does not
	/// change. A consumer comparing the two is how a truncated decode gets caught.
	[Test]
	public static void DataSizeDescribesTheFormatNotTheBuffer()
	{
		let truncated = new List<uint8>();
		truncated.Resize(3);
		let image = scope OwnedImageData(4, 4, .RGBA8, truncated);
		Test.Assert(image.DataSize == 64);
		Test.Assert(image.PixelData.Length == 3, "and the buffer is still what it is");
	}

	[Test]
	public static void AColorSpaceCanBeStatedAndChanged()
	{
		let image = scope OwnedImageData(1, 1, .RGBA8, .(), .Linear);
		Test.Assert(image.ColorSpace == .Linear, "a normal map is not sRGB");
		image.SetColorSpace(.Srgb);
		Test.Assert(image.ColorSpace == .Srgb);
	}

	/// A GPU cache keyed on identity MUST check this and not the reference alone: after a
	/// delete the allocator can hand a NEW image the SAME address, and a pointer-only key
	/// then serves the dead image's texture.
	[Test]
	public static void EveryConstructionMintsANewIdentity()
	{
		uint8[4] pixels = .(1, 2, 3, 4);

		let first = scope OwnedImageData(1, 1, .RGBA8, .(&pixels[0], 4));
		let second = scope OwnedImageData(1, 1, .RGBA8, .(&pixels[0], 4));

		Test.Assert(first.InstanceId != 0);
		Test.Assert(first.InstanceId != second.InstanceId, "identical content, different identity");

		// Across the whole family, not per type: the cache holds ImageData, so two
		// different kinds must not collide either.
		let borrowed = scope ImageDataRef(1, 1, .RGBA8, &pixels[0], 4);
		let rich = scope Image(1, 1, .RGBA8);
		Test.Assert(borrowed.InstanceId != first.InstanceId);
		Test.Assert(rich.InstanceId != borrowed.InstanceId);
	}

	[Test]
	public static void ABorrowedViewPointsAtSomeoneElsesPixels()
	{
		uint8[4] pixels = .(10, 20, 30, 40);

		let view = scope ImageDataRef(1, 1, .RGBA8, &pixels[0], 4);
		Test.Assert(view.Width == 1 && view.Height == 1);
		Test.Assert(view.PixelData.Length == 4);
		Test.Assert(view.PixelData[2] == 30);

		// Borrowed, so a change at the source is visible through the view.
		pixels[2] = 77;
		Test.Assert(view.PixelData[2] == 77);
	}

	/// A texture whose pixels live only on the GPU still has to describe itself, so a view
	/// with no data at all is a legitimate thing rather than a broken one.
	[Test]
	public static void ABorrowedViewCanHaveNoPixelsAtAll()
	{
		let gpuOnly = scope ImageDataRef(256, 128, .BGRA8);
		Test.Assert(gpuOnly.Width == 256 && gpuOnly.Height == 128);
		Test.Assert(gpuOnly.Format == .BGRA8);
		Test.Assert(gpuOnly.PixelData.Length == 0);
		Test.Assert(gpuOnly.PixelData.Ptr == null);

		let empty = scope ImageDataRef();
		Test.Assert(empty.Width == 0 && empty.PixelData.Length == 0);
	}

	/// The point of the base class: a consumer takes ImageData and never learns which kind
	/// it was handed.
	[Test]
	public static void EveryKindAnswersThroughTheCommonBase()
	{
		uint8[4] pixels = .(1, 2, 3, 4);
		let images = scope List<ImageData>();
		images.Add(scope OwnedImageData(1, 1, .RGBA8, .(&pixels[0], 4)));
		images.Add(scope ImageDataRef(1, 1, .RGBA8, &pixels[0], 4));
		images.Add(scope Image(1, 1, .RGBA8));

		for (let image in images)
		{
			Test.Assert(image.Width == 1 && image.Height == 1);
			Test.Assert(image.Format == .RGBA8);
			Test.Assert(image.PixelData.Length == 4);
		}
	}
}
