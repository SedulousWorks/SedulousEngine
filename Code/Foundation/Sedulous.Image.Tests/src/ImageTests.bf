using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Image.Tests;

/// The CPU side image: formats, pixel access, and the manipulation the tools rely on.
class ImageTests
{
	[Test]
	public static void EveryFormatReportsItsSizeAndChannels()
	{
		Test.Assert(PixelFormats.BytesPerPixel(.R8) == 1);
		Test.Assert(PixelFormats.BytesPerPixel(.RG8) == 2);
		Test.Assert(PixelFormats.BytesPerPixel(.RGB8) == 3);
		Test.Assert(PixelFormats.BytesPerPixel(.BGR8) == 3);
		Test.Assert(PixelFormats.BytesPerPixel(.RGBA8) == 4);
		Test.Assert(PixelFormats.BytesPerPixel(.BGRA8) == 4);
		Test.Assert(PixelFormats.BytesPerPixel(.R16) == 2);
		Test.Assert(PixelFormats.BytesPerPixel(.RGBA32F) == 16);

		Test.Assert(PixelFormats.ChannelCount(.R8) == 1);
		Test.Assert(PixelFormats.ChannelCount(.RG16F) == 2);
		Test.Assert(PixelFormats.ChannelCount(.BGR8) == 3);
		Test.Assert(PixelFormats.ChannelCount(.RGBA32F) == 4);

		Test.Assert(PixelFormats.HasAlpha(.RGBA8));
		Test.Assert(PixelFormats.HasAlpha(.BGRA8));
		Test.Assert(!PixelFormats.HasAlpha(.RGB8));
		Test.Assert(!PixelFormats.HasAlpha(.R16));
	}

	/// Bytes per pixel and channel count agree with each other for every 8 bit format: a
	/// three channel byte format is three bytes.
	[Test]
	public static void SizeAndChannelCountAgreeForByteFormats()
	{
		for (let format in PixelFormat[6](.R8, .RG8, .RGB8, .RGBA8, .BGR8, .BGRA8))
		{
			Test.Assert(PixelFormats.BytesPerPixel(format) == PixelFormats.ChannelCount(format),
				scope $"{format} disagrees with itself");
		}
	}

	[Test]
	public static void ANewImageIsSizedAndCleared()
	{
		let image = scope Image(4, 3, .RGBA8);
		Test.Assert(image.Width == 4);
		Test.Assert(image.Height == 3);
		Test.Assert(image.Format == .RGBA8);
		Test.Assert(image.PixelCount == 12);
		Test.Assert(image.DataSize == 48);
		Test.Assert(image.PixelData.Length == 48);
		Test.Assert(image.HasAlpha);
		Test.Assert(image.ChannelCount == 4);

		// Alpha bearing, so cleared means transparent rather than opaque black.
		Test.Assert(image.GetPixel(0, 0) == Color32.Transparent);
	}

	[Test]
	public static void PixelsRoundTripThroughEveryByteFormat()
	{
		let colour = Color32(10, 20, 30, 40);

		for (let format in PixelFormat[4](.RGB8, .RGBA8, .BGR8, .BGRA8))
		{
			let image = scope Image(2, 2, format);
			image.SetPixel(1, 1, colour);
			let read = image.GetPixel(1, 1);

			Test.Assert(read.R == colour.R, scope $"{format} red");
			Test.Assert(read.G == colour.G, scope $"{format} green");
			Test.Assert(read.B == colour.B, scope $"{format} blue");
			// A format without alpha reads back opaque, which is the honest answer.
			let expectedAlpha = PixelFormats.HasAlpha(format) ? colour.A : 255;
			Test.Assert(read.A == expectedAlpha, scope $"{format} alpha");
			// And it did not smear into the neighbours.
			Test.Assert(image.GetPixel(0, 0) != colour, scope $"{format} bled");
		}
	}

	/// A single channel format keeps the AVERAGE of the colour channels, so a grey written
	/// through a colour reads back as the grey it looked like.
	[Test]
	public static void ASingleChannelFormatStoresTheAverage()
	{
		let image = scope Image(1, 1, .R8);
		image.SetPixel(0, 0, .(30, 60, 90, 255));

		let read = image.GetPixel(0, 0);
		Test.Assert(read.R == 60, scope $"got {read.R}");
		Test.Assert((read.R == read.G) && (read.G == read.B), "it reads back as a grey");
		Test.Assert(read.A == 255);
	}

	/// Out of bounds access is ordinary, not exceptional: a sampler asks about pixels
	/// outside the image all the time.
	[Test]
	public static void OutOfBoundsAccessIsHarmless()
	{
		let image = scope Image(2, 2, .RGBA8);
		image.FillColor(Color32.White);

		Test.Assert(image.GetPixel(2, 0) == Color32.Black, "past the right edge");
		Test.Assert(image.GetPixel(0, 2) == Color32.Black);
		Test.Assert(image.GetPixel(1000, 1000) == Color32.Black);

		image.SetPixel(5, 5, Color32.Red);
		image.SetPixel(0, 99, Color32.Red);
		Test.Assert(image.GetPixel(0, 0) == Color32.White, "and nothing inside was touched");
	}

	[Test]
	public static void ClearDependsOnWhetherTheFormatHasAlpha()
	{
		let withAlpha = scope Image(2, 2, .RGBA8);
		withAlpha.FillColor(Color32.Red);
		withAlpha.Clear();
		Test.Assert(withAlpha.GetPixel(0, 0) == Color32.Transparent);

		let without = scope Image(2, 2, .RGB8);
		without.FillColor(Color32.Red);
		without.Clear();
		Test.Assert(without.GetPixel(0, 0) == Color32.Black, "no alpha to clear to, so zero");

		without.Clear(Color32.Green);
		Test.Assert(without.GetPixel(1, 1) == Color32.Green, "clearing to a colour fills it");
	}

	/// A source shorter than the image fills what it can and clears the rest, rather than
	/// leaving whatever the buffer happened to contain.
	[Test]
	public static void ReplacingWithAShortSourceClearsTheRemainder()
	{
		let image = scope Image(2, 2, .RGBA8);
		image.FillColor(Color32.White);

		uint8[8] partial = .(1, 2, 3, 4, 5, 6, 7, 8); // two pixels of the four
		image.ReplaceData(2, 2, .RGBA8, .(&partial[0], 8));

		Test.Assert(image.GetPixel(0, 0) == Color32(1, 2, 3, 4), "the supplied part landed");
		Test.Assert(image.GetPixel(0, 1) == Color32(0, 0, 0, 0), "and the rest was cleared");
		Test.Assert(image.GetPixel(1, 1) == Color32(0, 0, 0, 0));
	}

	/// Replacing in place keeps the object, which is what makes a hot reload invisible to
	/// everything holding a reference.
	[Test]
	public static void ReplacingKeepsTheSameInstance()
	{
		let image = scope Image(2, 2, .RGBA8);
		let id = image.InstanceId;

		image.ReplaceData(4, 1, .RGB8, .());

		Test.Assert(image.InstanceId == id, "the same object, so a cache keyed on it still hits");
		Test.Assert(image.Width == 4);
		Test.Assert(image.Height == 1);
		Test.Assert(image.Format == .RGB8);
		Test.Assert(image.DataSize == 12);
	}

	/// Every constructed image gets its own id. A GPU cache must check it: after a delete
	/// the allocator can hand a new image the same address, and a pointer-only key would
	/// then serve the dead image's texture.
	[Test]
	public static void EveryImageGetsItsOwnInstanceId()
	{
		let first = scope Image(1, 1, .RGBA8);
		let second = scope Image(1, 1, .RGBA8);
		let view = scope ImageDataRef(1, 1);

		Test.Assert(first.InstanceId != second.InstanceId);
		Test.Assert(second.InstanceId != view.InstanceId);
		Test.Assert(first.InstanceId != view.InstanceId);
	}

	[Test]
	public static void FlippingVerticallyReversesTheRows()
	{
		let image = scope Image(2, 3, .RGBA8);
		for (uint32 y < 3)
		{
			for (uint32 x < 2)
				image.SetPixel(x, y, .((uint8)y, 0, 0, 255));
		}

		image.FlipVertical();

		Test.Assert(image.GetPixel(0, 0).R == 2);
		Test.Assert(image.GetPixel(1, 1).R == 1, "the middle row stayed put");
		Test.Assert(image.GetPixel(0, 2).R == 0);

		image.FlipVertical();
		Test.Assert(image.GetPixel(0, 0).R == 0, "flipping twice is the identity");
	}

	[Test]
	public static void FlippingHorizontallyReversesTheColumns()
	{
		let image = scope Image(3, 2, .RGBA8);
		for (uint32 y < 2)
		{
			for (uint32 x < 3)
				image.SetPixel(x, y, .((uint8)x, 0, 0, 255));
		}

		image.FlipHorizontal();

		Test.Assert(image.GetPixel(0, 0).R == 2);
		Test.Assert(image.GetPixel(1, 0).R == 1);
		Test.Assert(image.GetPixel(2, 1).R == 0);

		image.FlipHorizontal();
		Test.Assert(image.GetPixel(0, 0).R == 0, "and back again");
	}

	[Test]
	public static void ConvertingFormatKeepsTheVisibleColours()
	{
		let source = scope Image(2, 2, .RGBA8);
		source.SetPixel(0, 0, .(255, 0, 0, 255));
		source.SetPixel(1, 0, .(0, 255, 0, 255));
		source.SetPixel(0, 1, .(0, 0, 255, 255));
		source.SetPixel(1, 1, .(10, 20, 30, 255));

		let converted = source.ConvertFormat(.BGRA8);
		defer delete converted;

		Test.Assert(converted.Format == .BGRA8);
		Test.Assert(converted.Width == 2);
		for (uint32 y < 2)
		{
			for (uint32 x < 2)
			{
				Test.Assert(converted.GetPixel(x, y) == source.GetPixel(x, y),
					scope $"pixel {x},{y} changed colour across the conversion");
			}
		}

		// The bytes really are in the other order underneath.
		Test.Assert(converted.PixelData[0] == 0, "blue first in BGRA");
		Test.Assert(converted.PixelData[2] == 255, "red third");
	}

	/// Converting to a format WITHOUT alpha drops it, which is the honest outcome rather
	/// than a silent success.
	[Test]
	public static void ConvertingToAFormatWithoutAlphaDropsIt()
	{
		let source = scope Image(1, 1, .RGBA8);
		source.SetPixel(0, 0, .(10, 20, 30, 40));

		let converted = source.ConvertFormat(.RGB8);
		defer delete converted;

		Test.Assert(converted.GetPixel(0, 0) == Color32(10, 20, 30, 255));
		Test.Assert(!converted.HasAlpha);
	}

	/// A float format image is zeroed like any other. It reports alpha, so a clear that
	/// routed through the colour fill would write nothing for it: a half float has no 8 bit
	/// channel meaning, and the buffer would keep whatever it started with.
	[Test]
	public static void AFloatFormatImageIsStillZeroed()
	{
		for (let format in PixelFormat[3](.RGBA32F, .RGBA16F, .R32F))
		{
			let image = scope Image(4, 4, format);
			Test.Assert(image.DataSize == image.PixelData.Length);
			Test.Assert(image.DataSize > 0);

			// Put real bytes in first. A fresh buffer starts zeroed anyway, so clearing one
			// proves nothing; the question is whether Clear can clear data that is there.
			let filled = scope List<uint8>();
			filled.Resize(image.DataSize);
			for (int i < filled.Count)
				filled[i] = 0xAB;
			image.ReplaceData(4, 4, format, .(filled.Ptr, filled.Count));
			Test.Assert(image.PixelData[0] == 0xAB, scope $"{format} did not take the data");

			image.Clear();
			for (int i < image.PixelData.Length)
				Test.Assert(image.PixelData[i] == 0, scope $"{format} byte {i} survived the clear");
		}
	}

	[Test]
	public static void TheCheckerboardAlternates()
	{
		let image = Image.CreateCheckerboard(8, Color32.White, Color32.Black, 2);
		defer delete image;

		Test.Assert(image.Width == 8);
		Test.Assert(image.GetPixel(0, 0) == Color32.White);
		Test.Assert(image.GetPixel(2, 0) == Color32.Black, "the next check along");
		Test.Assert(image.GetPixel(0, 2) == Color32.Black, "and the next one down");
		Test.Assert(image.GetPixel(2, 2) == Color32.White, "diagonally is the same colour");
		Test.Assert(image.GetPixel(1, 1) == Color32.White, "within a check it does not change");
	}

	/// A zero check size would divide by zero. Clamped, so a bad argument gives a fine
	/// checkerboard rather than a crash.
	[Test]
	public static void AZeroCheckSizeIsClamped()
	{
		let image = Image.CreateCheckerboard(4, Color32.White, Color32.Black, 0);
		defer delete image;

		Test.Assert(image.Width == 4);
		Test.Assert(image.GetPixel(0, 0) == Color32.White);
		Test.Assert(image.GetPixel(1, 0) == Color32.Black, "every pixel alternates");
	}

	[Test]
	public static void TheGradientRunsBetweenItsEnds()
	{
		let image = Image.CreateGradient(2, 5, Color32.Black, Color32.White);
		defer delete image;

		Test.Assert(image.GetPixel(0, 0) == Color32.Black, "the top is the first colour");
		Test.Assert(image.GetPixel(0, 4).R >= 254, "and the bottom is the second");

		// Monotonic in between, which is what makes it a gradient rather than a pattern.
		var previous = image.GetPixel(0, 0).R;
		for (uint32 y = 1; y < 5; y++)
		{
			let here = image.GetPixel(0, y).R;
			Test.Assert(here >= previous, scope $"row {y} went backwards");
			previous = here;
		}
	}

	/// A single row gradient must not divide by zero on the height minus one.
	[Test]
	public static void ASingleRowGradientIsHarmless()
	{
		let image = Image.CreateGradient(4, 1, Color32.Black, Color32.White);
		defer delete image;

		Test.Assert(image.Height == 1);
		Test.Assert(image.GetPixel(0, 0) == Color32.Black, "one row is the first colour");
	}

	[Test]
	public static void SolidColourFillsEveryPixel()
	{
		let image = Image.CreateSolidColor(3, 3, .(1, 2, 3, 4));
		defer delete image;

		for (uint32 y < 3)
		{
			for (uint32 x < 3)
				Test.Assert(image.GetPixel(x, y) == Color32(1, 2, 3, 4), scope $"pixel {x},{y}");
		}
	}
}
