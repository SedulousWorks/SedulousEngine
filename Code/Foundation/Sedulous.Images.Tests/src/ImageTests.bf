using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Images.Tests;

class ImageTests
{
	[Test]
	static void TestImageCreation()
	{
		let image = new Image(64, 64, .RGBA8);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);
		Test.Assert(image.Format == .RGBA8);
		Test.Assert(image.PixelCount == 64 * 64);
		Test.Assert(image.DataSize == 64 * 64 * 4);
	}

	[Test]
	static void TestImageCreationWithData()
	{
		uint8[] data = new .[4 * 4]; // 2x2 RGBA
		defer delete data;

		// Set first pixel to red
		data[0] = 255; data[1] = 0; data[2] = 0; data[3] = 255;
		// Set second pixel to green
		data[4] = 0; data[5] = 255; data[6] = 0; data[7] = 255;

		let image = new Image(2, 2, .RGBA8, data);
		defer delete image;

		let pixel0 = image.GetPixel(0, 0);
		Test.Assert(pixel0.R == 255 && pixel0.G == 0 && pixel0.B == 0 && pixel0.A == 255);

		let pixel1 = image.GetPixel(1, 0);
		Test.Assert(pixel1.R == 0 && pixel1.G == 255 && pixel1.B == 0 && pixel1.A == 255);
	}

	[Test]
	static void TestImageCopy()
	{
		let original = new Image(4, 4, .RGBA8);
		defer delete original;
		original.SetPixel(0, 0, Color.Red);
		original.SetPixel(1, 1, Color.Lime);

		let copy = new Image(original);
		defer delete copy;

		Test.Assert(copy.Width == original.Width);
		Test.Assert(copy.Height == original.Height);
		Test.Assert(copy.Format == original.Format);

		let pixel00 = copy.GetPixel(0, 0);
		Test.Assert(pixel00.R == 255 && pixel00.G == 0 && pixel00.B == 0);

		let pixel11 = copy.GetPixel(1, 1);
		Test.Assert(pixel11.R == 0 && pixel11.G == 255 && pixel11.B == 0);
	}

	[Test]
	static void TestGetSetPixel()
	{
		let image = new Image(8, 8, .RGBA8);
		defer delete image;

		// Test setting and getting various colors
		image.SetPixel(0, 0, Color.Red);
		image.SetPixel(1, 0, Color.Lime);
		image.SetPixel(2, 0, Color.Blue);
		image.SetPixel(3, 0, Color.White);
		image.SetPixel(4, 0, Color.Black);
		image.SetPixel(5, 0, Color(128, 64, 32, 200));

		let red = image.GetPixel(0, 0);
		Test.Assert(red.R == 255 && red.G == 0 && red.B == 0 && red.A == 255);

		let green = image.GetPixel(1, 0);
		Test.Assert(green.R == 0 && green.G == 255 && green.B == 0 && green.A == 255);

		let blue = image.GetPixel(2, 0);
		Test.Assert(blue.R == 0 && blue.G == 0 && blue.B == 255 && blue.A == 255);

		let white = image.GetPixel(3, 0);
		Test.Assert(white.R == 255 && white.G == 255 && white.B == 255 && white.A == 255);

		let black = image.GetPixel(4, 0);
		Test.Assert(black.R == 0 && black.G == 0 && black.B == 0 && black.A == 255);

		let custom = image.GetPixel(5, 0);
		Test.Assert(custom.R == 128 && custom.G == 64 && custom.B == 32 && custom.A == 200);
	}

	[Test]
	static void TestGetPixelOutOfBounds()
	{
		let image = new Image(4, 4, .RGBA8);
		defer delete image;

		// Out of bounds should return black
		let outOfBounds = image.GetPixel(10, 10);
		Test.Assert(outOfBounds == Color.Black);
	}

	[Test]
	static void TestSetPixelOutOfBounds()
	{
		let image = new Image(4, 4, .RGBA8);
		defer delete image;

		// Should not crash when setting out of bounds
		image.SetPixel(100, 100, Color.Red);

		// Verify no corruption of valid pixels
		image.SetPixel(0, 0, Color.Lime);
		let pixel = image.GetPixel(0, 0);
		Test.Assert(pixel.R == 0 && pixel.G == 255 && pixel.B == 0);
	}

	[Test]
	static void TestClear()
	{
		let image = new Image(4, 4, .RGBA8);
		defer delete image;

		// Set some pixels first
		image.SetPixel(0, 0, Color.Red);
		image.SetPixel(1, 1, Color.Green);

		// Clear with blue
		image.Clear(Color.Blue);

		// All pixels should be blue now
		for (uint32 y = 0; y < 4; y++)
		{
			for (uint32 x = 0; x < 4; x++)
			{
				let pixel = image.GetPixel(x, y);
				Test.Assert(pixel.R == 0 && pixel.G == 0 && pixel.B == 255 && pixel.A == 255);
			}
		}
	}

	[Test]
	static void TestFillColor()
	{
		let image = new Image(4, 4, .RGBA8);
		defer delete image;

		let testColor = Color(100, 150, 200, 250);
		image.FillColor(testColor);

		for (uint32 y = 0; y < 4; y++)
		{
			for (uint32 x = 0; x < 4; x++)
			{
				let pixel = image.GetPixel(x, y);
				Test.Assert(pixel.R == 100 && pixel.G == 150 && pixel.B == 200 && pixel.A == 250);
			}
		}
	}

	[Test]
	static void TestFlipVertical()
	{
		let image = new Image(2, 4, .RGBA8);
		defer delete image;

		// Set top row red, bottom row blue
		image.SetPixel(0, 0, Color.Red);
		image.SetPixel(1, 0, Color.Red);
		image.SetPixel(0, 3, Color.Blue);
		image.SetPixel(1, 3, Color.Blue);

		image.FlipVertical();

		// After flip, top should be blue, bottom should be red
		let topLeft = image.GetPixel(0, 0);
		Test.Assert(topLeft.B == 255 && topLeft.R == 0);

		let bottomLeft = image.GetPixel(0, 3);
		Test.Assert(bottomLeft.R == 255 && bottomLeft.B == 0);
	}

	[Test]
	static void TestFlipHorizontal()
	{
		let image = new Image(4, 2, .RGBA8);
		defer delete image;

		// Set left column red, right column blue
		image.SetPixel(0, 0, Color.Red);
		image.SetPixel(0, 1, Color.Red);
		image.SetPixel(3, 0, Color.Blue);
		image.SetPixel(3, 1, Color.Blue);

		image.FlipHorizontal();

		// After flip, left should be blue, right should be red
		let left = image.GetPixel(0, 0);
		Test.Assert(left.B == 255 && left.R == 0);

		let right = image.GetPixel(3, 0);
		Test.Assert(right.R == 255 && right.B == 0);
	}

	[Test]
	static void TestConvertFormat()
	{
		let rgba = new Image(4, 4, .RGBA8);
		defer delete rgba;

		rgba.SetPixel(0, 0, Color.Red);
		rgba.SetPixel(1, 0, Color.Green);
		rgba.SetPixel(2, 0, Color.Blue);
		rgba.SetPixel(3, 0, Color(100, 150, 200, 255));

		// Convert to RGB8
		let rgb = rgba.ConvertFormat(.RGB8).Value;
		defer delete rgb;

		Test.Assert(rgb.Format == .RGB8);
		Test.Assert(rgb.Width == 4 && rgb.Height == 4);

		let red = rgb.GetPixel(0, 0);
		Test.Assert(red.R == 255 && red.G == 0 && red.B == 0);

		let custom = rgb.GetPixel(3, 0);
		Test.Assert(custom.R == 100 && custom.G == 150 && custom.B == 200);
	}

	[Test]
	static void TestConvertSameFormat()
	{
		let original = new Image(4, 4, .RGBA8);
		defer delete original;
		original.SetPixel(0, 0, Color.Red);

		let converted = original.ConvertFormat(.RGBA8).Value;
		defer delete converted;

		Test.Assert(converted.Format == .RGBA8);
		let pixel = converted.GetPixel(0, 0);
		Test.Assert(pixel.R == 255 && pixel.G == 0 && pixel.B == 0);
	}

	[Test]
	static void TestHasAlpha()
	{
		let rgba = new Image(4, 4, .RGBA8);
		defer delete rgba;
		Test.Assert(rgba.HasAlpha());

		let rgb = new Image(4, 4, .RGB8);
		defer delete rgb;
		Test.Assert(!rgb.HasAlpha());

		let r8 = new Image(4, 4, .R8);
		defer delete r8;
		Test.Assert(!r8.HasAlpha());

		let bgra = new Image(4, 4, .BGRA8);
		defer delete bgra;
		Test.Assert(bgra.HasAlpha());
	}

	[Test]
	static void TestGetChannelCount()
	{
		let r8 = new Image(4, 4, .R8);
		defer delete r8;
		Test.Assert(r8.GetChannelCount() == 1);

		let rg8 = new Image(4, 4, .RG8);
		defer delete rg8;
		Test.Assert(rg8.GetChannelCount() == 2);

		let rgb8 = new Image(4, 4, .RGB8);
		defer delete rgb8;
		Test.Assert(rgb8.GetChannelCount() == 3);

		let rgba8 = new Image(4, 4, .RGBA8);
		defer delete rgba8;
		Test.Assert(rgba8.GetChannelCount() == 4);
	}

	[Test]
	static void TestGetBytesPerPixel()
	{
		Test.Assert(Image.GetBytesPerPixel(.R8) == 1);
		Test.Assert(Image.GetBytesPerPixel(.RG8) == 2);
		Test.Assert(Image.GetBytesPerPixel(.RGB8) == 3);
		Test.Assert(Image.GetBytesPerPixel(.RGBA8) == 4);
		Test.Assert(Image.GetBytesPerPixel(.BGR8) == 3);
		Test.Assert(Image.GetBytesPerPixel(.BGRA8) == 4);
		Test.Assert(Image.GetBytesPerPixel(.R32F) == 4);
		Test.Assert(Image.GetBytesPerPixel(.RGBA32F) == 16);
	}

	[Test]
	static void TestRGB8Format()
	{
		let image = new Image(4, 4, .RGB8);
		defer delete image;

		image.SetPixel(0, 0, Color(100, 150, 200, 255));
		let pixel = image.GetPixel(0, 0);

		// RGB8 should preserve RGB, alpha should be 255
		Test.Assert(pixel.R == 100 && pixel.G == 150 && pixel.B == 200 && pixel.A == 255);
	}

	[Test]
	static void TestBGR8Format()
	{
		let image = new Image(4, 4, .BGR8);
		defer delete image;

		image.SetPixel(0, 0, Color(100, 150, 200, 255));
		let pixel = image.GetPixel(0, 0);

		// BGR8 should correctly swap channels
		Test.Assert(pixel.R == 100 && pixel.G == 150 && pixel.B == 200);
	}

	[Test]
	static void TestBGRA8Format()
	{
		let image = new Image(4, 4, .BGRA8);
		defer delete image;

		image.SetPixel(0, 0, Color(100, 150, 200, 128));
		let pixel = image.GetPixel(0, 0);

		Test.Assert(pixel.R == 100 && pixel.G == 150 && pixel.B == 200 && pixel.A == 128);
	}

	[Test]
	static void TestR8Format()
	{
		let image = new Image(4, 4, .R8);
		defer delete image;

		// Set a color - should be averaged to grayscale
		image.SetPixel(0, 0, Color(90, 120, 150, 255)); // Average = 120
		let pixel = image.GetPixel(0, 0);

		// R8 stores grayscale, returns it in all RGB channels
		Test.Assert(pixel.R == pixel.G && pixel.G == pixel.B);
		Test.Assert(pixel.A == 255);
	}
}
