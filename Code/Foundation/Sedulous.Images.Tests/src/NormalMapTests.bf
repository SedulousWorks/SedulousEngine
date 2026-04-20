using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Images.Tests;

class NormalMapTests
{
	// Normal map neutral color (pointing straight up): (128, 128, 255)
	const uint8 NeutralX = 128;
	const uint8 NeutralY = 128;
	const uint8 NeutralZ = 255;

	[Test]
	static void TestCreateFlatNormalMap()
	{
		let image = Image.CreateFlatNormalMap(32, 32);
		defer delete image;

		Test.Assert(image.Width == 32);
		Test.Assert(image.Height == 32);
		Test.Assert(image.Format == .RGBA8);

		// All pixels should be the neutral normal (0, 0, 1) encoded as (128, 128, 255)
		for (uint32 y = 0; y < 32; y++)
		{
			for (uint32 x = 0; x < 32; x++)
			{
				let pixel = image.GetPixel(x, y);
				Test.Assert(pixel.R == NeutralX);
				Test.Assert(pixel.G == NeutralY);
				Test.Assert(pixel.B == NeutralZ);
				Test.Assert(pixel.A == 255);
			}
		}
	}

	[Test]
	static void TestCreateFlatNormalMapWithFormat()
	{
		let image = Image.CreateFlatNormalMap(16, 16, .RGB8);
		defer delete image;

		Test.Assert(image.Format == .RGB8);

		let pixel = image.GetPixel(8, 8);
		Test.Assert(pixel.R == NeutralX && pixel.G == NeutralY && pixel.B == NeutralZ);
	}

	[Test]
	static void TestCreateWaveNormalMap()
	{
		let image = Image.CreateWaveNormalMap(64, 64, 4.0f, 4.0f, 0.3f);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);

		// Wave normal map should have variation in X and Y normals
		bool hasXVariation = false;
		bool hasYVariation = false;

		for (uint32 y = 0; y < 64; y++)
		{
			for (uint32 x = 0; x < 64; x++)
			{
				let pixel = image.GetPixel(x, y);

				// Check for variation from neutral
				if (Math.Abs((int)pixel.R - NeutralX) > 5)
					hasXVariation = true;
				if (Math.Abs((int)pixel.G - NeutralY) > 5)
					hasYVariation = true;

				// Z component should always be positive (pointing generally up)
				Test.Assert(pixel.B >= 128);
			}
		}

		Test.Assert(hasXVariation);
		Test.Assert(hasYVariation);
	}

	[Test]
	static void TestCreateBrickNormalMap()
	{
		let image = Image.CreateBrickNormalMap(64, 64, 4, 2, 0.3f);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);

		// Brick normal map should have some variation
		bool hasVariation = false;

		for (uint32 y = 0; y < 64; y++)
		{
			for (uint32 x = 0; x < 64; x++)
			{
				let pixel = image.GetPixel(x, y);

				// Check for any variation from neutral
				if (pixel.R != NeutralX || pixel.G != NeutralY || pixel.B != NeutralZ)
					hasVariation = true;

				// Ensure valid normal map values (B should be positive)
				Test.Assert(pixel.B >= 128);
			}
		}

		Test.Assert(hasVariation);
	}

	[Test]
	static void TestCreateCircularBumpNormalMap()
	{
		let image = Image.CreateCircularBumpNormalMap(64, 64, 0.5f, 2.0f);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);

		// Check that the image has some variation (bump exists)
		bool hasVariation = false;
		for (uint32 y = 0; y < 64; y++)
		{
			for (uint32 x = 0; x < 64; x++)
			{
				let pixel = image.GetPixel(x, y);
				if (pixel.R != NeutralX || pixel.G != NeutralY)
				{
					hasVariation = true;
					break;
				}
			}
			if (hasVariation) break;
		}
		Test.Assert(hasVariation);

		// Z should always be positive
		for (uint32 y = 0; y < 64; y++)
		{
			for (uint32 x = 0; x < 64; x++)
			{
				let pixel = image.GetPixel(x, y);
				Test.Assert(pixel.B >= 128);
			}
		}
	}

	[Test]
	static void TestCreateNoiseNormalMap()
	{
		let image = Image.CreateNoiseNormalMap(64, 64, 0.1f, 0.2f, 12345);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);

		// Noise normal map should have variation throughout
		bool hasVariation = false;
		int variationCount = 0;

		for (uint32 y = 0; y < 64; y++)
		{
			for (uint32 x = 0; x < 64; x++)
			{
				let pixel = image.GetPixel(x, y);

				if (pixel.R != NeutralX || pixel.G != NeutralY)
				{
					hasVariation = true;
					variationCount++;
				}

				// Z should always be positive
				Test.Assert(pixel.B >= 128);
			}
		}

		Test.Assert(hasVariation);
		// Most pixels should have some variation in a noise map
		Test.Assert(variationCount > 64 * 64 / 2);
	}

	[Test]
	static void TestCreateNoiseNormalMapDeterministic()
	{
		// Same seed should produce same results
		let image1 = Image.CreateNoiseNormalMap(32, 32, 0.1f, 0.2f, 42);
		defer delete image1;

		let image2 = Image.CreateNoiseNormalMap(32, 32, 0.1f, 0.2f, 42);
		defer delete image2;

		for (uint32 y = 0; y < 32; y++)
		{
			for (uint32 x = 0; x < 32; x++)
			{
				let p1 = image1.GetPixel(x, y);
				let p2 = image2.GetPixel(x, y);

				Test.Assert(p1.R == p2.R && p1.G == p2.G && p1.B == p2.B);
			}
		}
	}

	[Test]
	static void TestCreateNoiseNormalMapDifferentSeeds()
	{
		// Different seeds should produce different results
		let image1 = Image.CreateNoiseNormalMap(32, 32, 0.1f, 0.2f, 100);
		defer delete image1;

		let image2 = Image.CreateNoiseNormalMap(32, 32, 0.1f, 0.2f, 200);
		defer delete image2;

		bool hasDifference = false;
		for (uint32 y = 0; y < 32 && !hasDifference; y++)
		{
			for (uint32 x = 0; x < 32 && !hasDifference; x++)
			{
				let p1 = image1.GetPixel(x, y);
				let p2 = image2.GetPixel(x, y);

				if (p1.R != p2.R || p1.G != p2.G || p1.B != p2.B)
					hasDifference = true;
			}
		}

		Test.Assert(hasDifference);
	}

	[Test]
	static void TestCreateTestPatternNormalMap()
	{
		let image = Image.CreateTestPatternNormalMap(64, 64);
		defer delete image;

		Test.Assert(image.Width == 64);
		Test.Assert(image.Height == 64);

		// Test pattern should have different behaviors in different quadrants
		// Check that there is variation across the image
		bool hasXVariation = false;
		bool hasYVariation = false;

		for (uint32 y = 0; y < 64; y++)
		{
			for (uint32 x = 0; x < 64; x++)
			{
				let pixel = image.GetPixel(x, y);

				if (pixel.R != NeutralX)
					hasXVariation = true;
				if (pixel.G != NeutralY)
					hasYVariation = true;

				// Z should always be positive
				Test.Assert(pixel.B >= 128);
			}
		}

		Test.Assert(hasXVariation);
		Test.Assert(hasYVariation);
	}

	[Test]
	static void TestCalculateNormalFromHeight()
	{
		// Flat surface (all same height)
		let flatNormal = Image.CalculateNormalFromHeight(0.5f, 0.5f, 0.5f, 0.5f);
		Test.Assert(Math.Abs(flatNormal.X) < 0.01f);
		Test.Assert(Math.Abs(flatNormal.Y) < 0.01f);
		Test.Assert(flatNormal.Z > 0.99f);

		// Slope to the right (heightR > heightL)
		let rightSlope = Image.CalculateNormalFromHeight(0.0f, 1.0f, 0.5f, 0.5f);
		Test.Assert(rightSlope.X < 0); // Normal points left (against the slope)
		Test.Assert(rightSlope.Z > 0);

		// Slope down (heightD > heightU)
		let downSlope = Image.CalculateNormalFromHeight(0.5f, 0.5f, 0.0f, 1.0f);
		Test.Assert(downSlope.Y < 0); // Normal points up (against the slope)
		Test.Assert(downSlope.Z > 0);
	}

	[Test]
	static void TestNormalMapZAlwaysPositive()
	{
		// All normal map creation methods should produce normals with Z >= 0.5 (B >= 128)
		let images = scope Image[6];

		images[0] = Image.CreateFlatNormalMap(16, 16);
		images[1] = Image.CreateWaveNormalMap(16, 16);
		images[2] = Image.CreateBrickNormalMap(16, 16);
		images[3] = Image.CreateCircularBumpNormalMap(16, 16);
		images[4] = Image.CreateNoiseNormalMap(16, 16);
		images[5] = Image.CreateTestPatternNormalMap(16, 16);

		for (let img in images)
		{
			for (uint32 y = 0; y < 16; y++)
			{
				for (uint32 x = 0; x < 16; x++)
				{
					let pixel = img.GetPixel(x, y);
					Test.Assert(pixel.B >= 128); // Z component always positive
				}
			}
			delete img;
		}
	}
}
