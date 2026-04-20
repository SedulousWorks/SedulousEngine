using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Images.Tests;

class ImageFactoryTests
{
	[Test]
	static void TestCreateSolidColor()
	{
		let image = Image.CreateSolidColor(32, 32, Color.Red);
		defer delete image;

		Test.Assert(image.Width == 32);
		Test.Assert(image.Height == 32);
		Test.Assert(image.Format == .RGBA8);

		// Check all pixels are red
		for (uint32 y = 0; y < 32; y++)
		{
			for (uint32 x = 0; x < 32; x++)
			{
				let pixel = image.GetPixel(x, y);
				Test.Assert(pixel.R == 255 && pixel.G == 0 && pixel.B == 0 && pixel.A == 255);
			}
		}
	}

	[Test]
	static void TestCreateSolidColorWithFormat()
	{
		let image = Image.CreateSolidColor(16, 16, Color.Lime, .RGB8);
		defer delete image;

		Test.Assert(image.Format == .RGB8);

		let pixel = image.GetPixel(0, 0);
		Test.Assert(pixel.R == 0 && pixel.G == 255 && pixel.B == 0);
	}

	[Test]
	static void TestCreateSolidColorCustom()
	{
		let customColor = Color(100, 150, 200, 250);
		let image = Image.CreateSolidColor(8, 8, customColor);
		defer delete image;

		let pixel = image.GetPixel(4, 4);
		Test.Assert(pixel.R == 100 && pixel.G == 150 && pixel.B == 200 && pixel.A == 250);
	}

	[Test]
	static void TestCreateCheckerboard()
	{
		let image = Image.CreateCheckerboard(64, Color.White, Color.Black, 32);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);

		// Top-left check should be color1 (white)
		let topLeft = image.GetPixel(0, 0);
		Test.Assert(topLeft.R == 255 && topLeft.G == 255 && topLeft.B == 255);

		// Next check should be color2 (black)
		let topRight = image.GetPixel(32, 0);
		Test.Assert(topRight.R == 0 && topRight.G == 0 && topRight.B == 0);

		// Bottom-left should be black (second row)
		let bottomLeft = image.GetPixel(0, 32);
		Test.Assert(bottomLeft.R == 0 && bottomLeft.G == 0 && bottomLeft.B == 0);

		// Bottom-right should be white
		let bottomRight = image.GetPixel(32, 32);
		Test.Assert(bottomRight.R == 255 && bottomRight.G == 255 && bottomRight.B == 255);
	}

	[Test]
	static void TestCreateCheckerboardSmallChecks()
	{
		let image = Image.CreateCheckerboard(16, Color.Red, Color.Blue, 4);
		defer delete image;

		// First check is red
		let check0 = image.GetPixel(0, 0);
		Test.Assert(check0.R == 255 && check0.B == 0);

		// Second check is blue
		let check1 = image.GetPixel(4, 0);
		Test.Assert(check1.R == 0 && check1.B == 255);

		// Third check is red (row 0, column 2)
		let check2 = image.GetPixel(8, 0);
		Test.Assert(check2.R == 255 && check2.B == 0);
	}

	[Test]
	static void TestCreateGradient()
	{
		let image = Image.CreateGradient(32, 64, Color.White, Color.Black);
		defer delete image;

		Test.Assert(image.Width == 32);
		Test.Assert(image.Height == 64);

		// Top should be white (or close to it)
		let top = image.GetPixel(16, 0);
		Test.Assert(top.R == 255 && top.G == 255 && top.B == 255);

		// Bottom should be black (or close to it)
		let bottom = image.GetPixel(16, 63);
		Test.Assert(bottom.R == 0 && bottom.G == 0 && bottom.B == 0);

		// Middle should be gray-ish
		let middle = image.GetPixel(16, 32);
		Test.Assert(middle.R > 100 && middle.R < 155);
	}

	[Test]
	static void TestCreateGradientColorful()
	{
		let image = Image.CreateGradient(16, 16, Color.Red, Color.Blue);
		defer delete image;

		// Top should be red
		let top = image.GetPixel(8, 0);
		Test.Assert(top.R == 255 && top.B == 0);

		// Bottom should be blue
		let bottom = image.GetPixel(8, 15);
		Test.Assert(bottom.R == 0 && bottom.B == 255);
	}

	[Test]
	static void TestCreateGradientHorizontalUniformity()
	{
		let image = Image.CreateGradient(32, 8, Color.Black, Color.White);
		defer delete image;

		// All pixels in a row should be the same color (horizontal uniformity)
		let row4Left = image.GetPixel(0, 4);
		let row4Middle = image.GetPixel(16, 4);
		let row4Right = image.GetPixel(31, 4);

		Test.Assert(row4Left.R == row4Middle.R && row4Middle.R == row4Right.R);
		Test.Assert(row4Left.G == row4Middle.G && row4Middle.G == row4Right.G);
		Test.Assert(row4Left.B == row4Middle.B && row4Middle.B == row4Right.B);
	}
}
