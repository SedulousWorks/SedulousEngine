using System;
using Sedulous.Core.IO;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;

namespace Sedulous.Image.IO.Tests;

/// Decoding, against real encoded bytes.
class ImageIOTests
{
	[Test]
	public static void APngDecodesToRgbaWithItsPixels()
	{
		let image = scope Image();
		Test.Assert(ImageIO.LoadImageFromMemory(.(&Fixtures.Rgba2x2Png[0], Fixtures.Rgba2x2Png.Count), image) case .Ok);

		Test.Assert(image.Width == 2);
		Test.Assert(image.Height == 2);
		Test.Assert(image.Format == .RGBA8, "always four channels, whatever the file had");
		Test.Assert(image.ColorSpace == .Srgb, "an ordinary image carries sRGB encoded colour");

		Test.Assert(image.GetPixel(0, 0) == Color32(255, 0, 0, 255), "red");
		Test.Assert(image.GetPixel(1, 0) == Color32(0, 255, 0, 255), "green");
		Test.Assert(image.GetPixel(0, 1) == Color32(0, 0, 255, 255), "blue");
		Test.Assert(image.GetPixel(1, 1) == Color32(255, 255, 255, 128), "and the alpha survived");
	}

	/// A single channel source is expanded to RGBA rather than left narrow, so a caller
	/// never has to branch on what the file happened to contain.
	[Test]
	public static void AGreyscaleSourceStillDecodesToRgba()
	{
		let image = scope Image();
		Test.Assert(ImageIO.LoadImageFromMemory(.(&Fixtures.Gray16_2x1Png[0], Fixtures.Gray16_2x1Png.Count), image) case .Ok);

		Test.Assert(image.Format == .RGBA8);
		Test.Assert(image.Width == 2 && image.Height == 1);

		// 0x1234 taken down to eight bits is 0x12, and the grey is copied across RGB.
		let first = image.GetPixel(0, 0);
		Test.Assert(first.R == first.G && first.G == first.B, "grey");
		Test.Assert(first.A == 255, "opaque");
		Test.Assert(first.R == 0x12, scope $"got {first.R}");
	}

	/// The sixteen bit path keeps FULL precision, which is what a heightmap needs: taken to
	/// eight bits, 256 height steps across a terrain read as terracing.
	[Test]
	public static void TheSixteenBitPathKeepsItsPrecision()
	{
		let image = scope Image();
		Test.Assert(ImageIO.LoadImage16FromMemory(.(&Fixtures.Gray16_2x1Png[0], Fixtures.Gray16_2x1Png.Count), image) case .Ok);

		Test.Assert(image.Format == .R16);
		Test.Assert(image.Width == 2 && image.Height == 1);
		Test.Assert(image.DataSize == 4, "two pixels at two bytes each");
		// Heights are data, so no colour curve is implied.
		Test.Assert(image.ColorSpace == .Linear);

		let values = (uint16*)image.PixelData.Ptr;
		Test.Assert(values[0] == 0x1234, scope $"got 0x{values[0]:X}");
		Test.Assert(values[1] == 0xABCD, scope $"got 0x{values[1]:X}");

		// And the ordinary path would have lost it, which is why this path exists.
		let narrow = scope Image();
		Test.Assert(ImageIO.LoadImageFromMemory(.(&Fixtures.Gray16_2x1Png[0], Fixtures.Gray16_2x1Png.Count), narrow) case .Ok);
		Test.Assert(narrow.GetPixel(0, 0).R == 0x12, "the low byte is gone on the ordinary path");
	}

	[Test]
	public static void MalformedBytesFailRatherThanDecodeGarbage()
	{
		let image = scope Image();
		uint8[8] rubbish = .(1, 2, 3, 4, 5, 6, 7, 8);

		Test.Assert(ImageIO.LoadImageFromMemory(.(&rubbish[0], 8), image) case .Err);
		Test.Assert(ImageIO.LoadImage16FromMemory(.(&rubbish[0], 8), image) case .Err);

		// And stb says why, which is worth surfacing: an unknown format and a corrupt file
		// are the same error code and very different problems.
		let reason = scope String();
		ImageIO.LastFailureReason(reason);
		Test.Assert(!reason.IsEmpty, "stb reported something");
	}

	/// An empty buffer is rejected before stb sees it, rather than being handed a null
	/// pointer with a zero length.
	[Test]
	public static void AnEmptyBufferIsRejected()
	{
		let image = scope Image();
		Test.Assert(ImageIO.LoadImageFromMemory(.(), image) case .Err);
		Test.Assert(ImageIO.LoadImage16FromMemory(.(), image) case .Err);
	}

	/// A file that is not there fails cleanly rather than trapping.
	[Test]
	public static void AMissingFileFails()
	{
		let image = scope Image();
		Test.Assert(ImageIO.LoadImage("./no_such_image_file.png", image) case .Err);
		Test.Assert(ImageIO.LoadImage16("./no_such_image_file.png", image) case .Err);
	}

	/// The round trip: an image written out and read back is the image that went in.
	///
	/// PNG is lossless, so this is an equality check rather than an approximation, and it
	/// is the test that actually proves the writer is wired to the reader.
	[Test]
	public static void APngRoundTripsThroughDisk()
	{
		let path = scope $"scratch_imageio_roundtrip.png";
		defer DeleteFile(path);

		let source = scope Image(4, 3, .RGBA8);
		for (uint32 y < 3)
		{
			for (uint32 x < 4)
				source.SetPixel(x, y, .((uint8)(x * 60), (uint8)(y * 80), 200, (uint8)(255 - x * 10)));
		}

		Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Ok);

		let loaded = scope Image();
		Test.Assert(ImageIO.LoadImage(path, loaded) case .Ok);

		Test.Assert(loaded.Width == 4 && loaded.Height == 3);
		Test.Assert(loaded.Format == .RGBA8);
		for (uint32 y < 3)
		{
			for (uint32 x < 4)
			{
				Test.Assert(loaded.GetPixel(x, y) == source.GetPixel(x, y),
					scope $"pixel {x},{y} changed across the round trip");
			}
		}
	}

	/// Rows come back in the same ORDER, which a vertical flip on write would break while
	/// leaving every other assertion above intact.
	[Test]
	public static void TheRowOrderSurvivesTheRoundTrip()
	{
		let path = scope $"scratch_imageio_rows.png";
		defer DeleteFile(path);

		let source = scope Image(1, 3, .RGBA8);
		source.SetPixel(0, 0, .(10, 0, 0, 255));
		source.SetPixel(0, 1, .(20, 0, 0, 255));
		source.SetPixel(0, 2, .(30, 0, 0, 255));

		Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Ok);

		let loaded = scope Image();
		Test.Assert(ImageIO.LoadImage(path, loaded) case .Ok);
		Test.Assert(loaded.GetPixel(0, 0).R == 10, "the top row is still the top row");
		Test.Assert(loaded.GetPixel(0, 2).R == 30);
	}

	/// Every writable format is actually written, and comes back as an image.
	[Test]
	public static void EveryWritableFormatProducesAReadableFile()
	{
		let source = scope Image(4, 4, .RGB8);
		source.FillColor(.(200, 100, 50, 255));

		for (let format in ImageFileFormat[3](.PNG, .BMP, .JPG))
		{
			let path = scope:: $"scratch_imageio_{format}.img";
			defer:: DeleteFile(path);

			Test.Assert(ImageIO.SaveImage(source, path, format) case .Ok, scope $"writing {format}");

			let loaded = scope:: Image();
			Test.Assert(ImageIO.LoadImage(path, loaded) case .Ok, scope $"reading {format} back");
			Test.Assert(loaded.Width == 4 && loaded.Height == 4, scope $"{format} size");

			// JPEG is lossy, so the colour is only approximately what went in.
			let pixel = loaded.GetPixel(1, 1);
			Test.Assert(Abs((int32)pixel.R - 200) < 12, scope $"{format} red came back {pixel.R}");
			Test.Assert(Abs((int32)pixel.B - 50) < 12, scope $"{format} blue came back {pixel.B}");
		}
	}

	/// A BGR ordered image is CONVERTED before writing rather than refused, since stb
	/// writes bytes in the order it is handed them and would otherwise swap red and blue.
	[Test]
	public static void ABgrImageIsConvertedRatherThanWrittenBackwards()
	{
		let path = scope $"scratch_imageio_bgra.png";
		defer DeleteFile(path);

		let source = scope Image(2, 2, .BGRA8);
		source.FillColor(.(255, 0, 0, 255)); // red, stored blue first

		Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Ok);

		let loaded = scope Image();
		Test.Assert(ImageIO.LoadImage(path, loaded) case .Ok);
		Test.Assert(loaded.GetPixel(0, 0) == Color32(255, 0, 0, 255),
			"still red, not blue with the channels swapped");
	}

	/// A format with no eight bit meaning is refused rather than written as bytes: the
	/// conversion is a look, and choosing it is the caller's decision.
	[Test]
	public static void AFloatImageIsRefusedRatherThanMangled()
	{
		let path = scope $"scratch_imageio_float.png";
		// Cleaned up either side: the assertion below is that the file is ABSENT, and a
		// stray file from any earlier run would fail it for the wrong reason forever.
		DeleteFile(path);
		defer DeleteFile(path);

		let source = scope Image(2, 2, .RGBA32F);
		Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Err);
		Test.Assert(!FileExists(path), "and nothing was written");
	}

	/// An empty image is refused, since there is nothing to write.
	[Test]
	public static void AnEmptyImageIsRefused()
	{
		let path = scope $"scratch_imageio_empty.png";
		defer DeleteFile(path);

		let source = scope Image();
		Test.Assert(ImageIO.SaveImage(source, path, .PNG) case .Err);
		Test.Assert(!FileExists(path), "and nothing was written");
	}

	/// A path that cannot be written fails rather than reporting success.
	[Test]
	public static void AnUnwritablePathFails()
	{
		let source = scope Image(2, 2, .RGBA8);
		Test.Assert(ImageIO.SaveImage(source, "./no_such_dir_here/out.png", .PNG) case .Err);
	}

	/// Loading into an image that already holds something REPLACES it, so a reused image
	/// does not keep the previous contents behind the new ones.
	[Test]
	public static void LoadingReplacesWhateverWasThere()
	{
		let image = scope Image(64, 64, .RGB8);
		image.FillColor(Color32.Red);
		let id = image.InstanceId;

		Test.Assert(ImageIO.LoadImageFromMemory(.(&Fixtures.Rgba2x2Png[0], Fixtures.Rgba2x2Png.Count), image) case .Ok);

		Test.Assert(image.Width == 2, "resized to the decoded image");
		Test.Assert(image.Format == .RGBA8, "and reformatted");
		Test.Assert(image.DataSize == 16);
		Test.Assert(image.InstanceId == id, "in place, so a cache keyed on it still finds it");
	}
}
