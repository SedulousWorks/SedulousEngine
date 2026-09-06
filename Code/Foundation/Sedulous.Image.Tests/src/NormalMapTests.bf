using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Image.Tests;

/// The procedural normal maps.
///
/// The invariant that matters across all of them is that Z stays positive: a normal
/// pointing into the surface is not a shape, it lights as a hole, and it is the kind of
/// mistake that survives a visual check on a flat-lit test scene.
class NormalMapTests
{
	/// Encoded, an up normal is (128, 128, 255) and B is at least 128 whenever Z is
	/// positive.
	private const uint8 cNeutralB = 128;

	[Test]
	public static void FlatIsUniformlyNeutral()
	{
		let image = NormalMaps.CreateFlat(8, 8);
		defer delete image;

		for (uint32 y < 8)
		{
			for (uint32 x < 8)
			{
				let pixel = image.GetPixel(x, y);
				Test.Assert(pixel.R == 128, scope $"pixel {x},{y} red");
				Test.Assert(pixel.G == 128);
				Test.Assert(pixel.B == 255, "straight up");
				Test.Assert(pixel.A == 255);
			}
		}
	}

	[Test]
	public static void FlatHonoursTheRequestedFormat()
	{
		let rgb = NormalMaps.CreateFlat(4, 4, .RGB8);
		defer delete rgb;
		Test.Assert(rgb.Format == .RGB8);
		Test.Assert(rgb.GetPixel(0, 0) == Color32(128, 128, 255, 255));

		let bgra = NormalMaps.CreateFlat(4, 4, .BGRA8);
		defer delete bgra;
		Test.Assert(bgra.Format == .BGRA8);
		Test.Assert(bgra.GetPixel(0, 0) == Color32(128, 128, 255, 255), "same colour, other byte order");
	}

	/// EVERY generator keeps Z positive. This is the one property worth checking across
	/// all of them at once, because a single inverted sign anywhere lights as a hole.
	[Test]
	public static void EveryGeneratorKeepsZPositive()
	{
		let images = scope List<Image>();
		defer { for (let image in images) delete image; }

		images.Add(NormalMaps.CreateFlat(16, 16));
		images.Add(NormalMaps.CreateWave(16, 16));
		images.Add(NormalMaps.CreateBrick(32, 32));
		images.Add(NormalMaps.CreateCircularBump(16, 16));
		images.Add(NormalMaps.CreateNoise(16, 16));
		images.Add(NormalMaps.CreateTestPattern(16, 16));

		for (int index < images.Count)
		{
			let image = images[index];
			for (uint32 y < image.Height)
			{
				for (uint32 x < image.Width)
				{
					Test.Assert(image.GetPixel(x, y).B >= cNeutralB,
						scope $"generator {index} at {x},{y} points into the surface");
				}
			}
		}
	}

	/// Every generator produces UNIT normals, to within the precision of an eight bit
	/// channel. A normal that is not unit length scales the lighting rather than steering
	/// it.
	[Test]
	public static void EveryGeneratorProducesUnitNormals()
	{
		let images = scope List<Image>();
		defer { for (let image in images) delete image; }

		images.Add(NormalMaps.CreateWave(16, 16));
		images.Add(NormalMaps.CreateCircularBump(16, 16));
		images.Add(NormalMaps.CreateNoise(16, 16));
		images.Add(NormalMaps.CreateTestPattern(16, 16));

		for (int index < images.Count)
		{
			let image = images[index];
			for (uint32 y < image.Height)
			{
				for (uint32 x < image.Width)
				{
					let pixel = image.GetPixel(x, y);
					let normal = Float3(
						(float)pixel.R / 255.0f * 2.0f - 1.0f,
						(float)pixel.G / 255.0f * 2.0f - 1.0f,
						(float)pixel.B / 255.0f * 2.0f - 1.0f);
					// One channel step is about 1/128 in normal space, so the tolerance is
					// the quantisation and nothing more.
					Test.Assert(Abs(Length(normal) - 1.0f) < 0.03f,
						scope $"generator {index} at {x},{y} has length {Length(normal)}");
				}
			}
		}
	}

	[Test]
	public static void TheWaveVariesInBothAxes()
	{
		let image = NormalMaps.CreateWave(32, 32);
		defer delete image;

		var reds = scope List<uint8>();
		var greens = scope List<uint8>();
		for (uint32 i < 32)
		{
			reds.Add(image.GetPixel(i, 0).R);
			greens.Add(image.GetPixel(0, i).G);
		}

		Test.Assert(Varies(reds), "the wave slopes along X");
		Test.Assert(Varies(greens), "and along Y");
	}

	/// The brick generator is FLAT, and this records that rather than hiding it.
	///
	/// Every normal it builds is (0, 0, positive), which normalises to straight up
	/// whatever the Z was, so mortar and brick face encode the same. Raptor shares the
	/// defect; its test missed it because the truncating encoder made every pixel differ
	/// from neutral, which is all that test asked about. If the generator is ever made
	/// real, this test SHOULD fail, and that is the point of it.
	[Test]
	public static void TheBrickIsCurrentlyFlat()
	{
		let image = NormalMaps.CreateBrick(64, 64, 4, 4);
		defer delete image;

		for (uint32 y < 64)
		{
			for (uint32 x < 64)
			{
				Test.Assert(image.GetPixel(x, y) == Color32(128, 128, 255, 255),
					scope $"pixel {x},{y} is not neutral, so the generator now produces a shape");
			}
		}
	}

	[Test]
	public static void TheCircularBumpVariesAndIsFlatOutside()
	{
		let image = NormalMaps.CreateCircularBump(32, 32);
		defer delete image;

		// A corner is outside the bump radius, so it is flat.
		Test.Assert(image.GetPixel(0, 0) == Color32(128, 128, 255, 255), "flat outside the bump");
		// The exact centre has no slope either.
		Test.Assert(image.GetPixel(16, 16).B >= 250, "and flat at the very centre");

		let ring = scope List<uint8>();
		for (uint32 x < 32)
			ring.Add(image.GetPixel(x, 16).R);
		Test.Assert(Varies(ring), "but sloped in between");
	}

	/// The noise varies across MOST pixels. A hash that stopped mixing would still be
	/// deterministic and still keep Z up, so those two tests alone would not notice.
	[Test]
	public static void NoiseVariesAcrossMostPixels()
	{
		let image = NormalMaps.CreateNoise(32, 32, 0.1f, 0.3f, 999);
		defer delete image;

		var offNeutral = 0;
		for (uint32 y < 32)
		{
			for (uint32 x < 32)
			{
				let pixel = image.GetPixel(x, y);
				if ((pixel.R != 128) || (pixel.G != 128))
					offNeutral++;
			}
		}
		Test.Assert(offNeutral > 512, scope $"only {offNeutral} of 1024 pixels carry any slope");
	}

	/// The same seed gives the same map, which is what makes a procedural placeholder
	/// usable as a reference at all.
	[Test]
	public static void NoiseIsDeterministicForASeed()
	{
		let first = NormalMaps.CreateNoise(16, 16, 0.1f, 0.2f, 4242);
		defer delete first;
		let second = NormalMaps.CreateNoise(16, 16, 0.1f, 0.2f, 4242);
		defer delete second;

		for (uint32 y < 16)
		{
			for (uint32 x < 16)
				Test.Assert(first.GetPixel(x, y) == second.GetPixel(x, y), scope $"pixel {x},{y}");
		}
	}

	[Test]
	public static void DifferentSeedsGiveDifferentNoise()
	{
		let first = NormalMaps.CreateNoise(16, 16, 0.1f, 0.2f, 1);
		defer delete first;
		let second = NormalMaps.CreateNoise(16, 16, 0.1f, 0.2f, 2);
		defer delete second;

		var differences = 0;
		for (uint32 y < 16)
		{
			for (uint32 x < 16)
			{
				if (first.GetPixel(x, y) != second.GetPixel(x, y))
					differences++;
			}
		}
		Test.Assert(differences > 16, scope $"only {differences} of 256 pixels differ");
	}

	/// The test pattern is four distinct quadrants, which is what makes it a test pattern
	/// rather than a texture.
	[Test]
	public static void TheTestPatternHasFourDistinctQuadrants()
	{
		let image = NormalMaps.CreateTestPattern(64, 64);
		defer delete image;

		Test.Assert(image.GetPixel(8, 8) == Color32(128, 128, 255, 255), "top left is flat");

		let topRight = scope List<uint8>();
		let bottomLeft = scope List<uint8>();
		for (uint32 i < 32)
		{
			topRight.Add(image.GetPixel(32 + i, 8).R);
			bottomLeft.Add(image.GetPixel(8, 32 + i).G);
		}
		Test.Assert(Varies(topRight), "top right bumps along X");
		Test.Assert(Varies(bottomLeft), "bottom left bumps along Y");
	}

	[Test]
	public static void ANormalIsBuiltFromNeighbouringHeights()
	{
		// Flat ground has no slope at all.
		let flat = NormalMaps.CalculateNormalFromHeight(1.0f, 1.0f, 1.0f, 1.0f);
		Test.Assert(Abs(flat.X) < 0.0001f);
		Test.Assert(Abs(flat.Y) < 0.0001f);
		Test.Assert(flat.Z > 0.99f);

		// Rising to the right tilts the normal towards negative X.
		let slopeX = NormalMaps.CalculateNormalFromHeight(0.0f, 1.0f, 0.0f, 0.0f);
		Test.Assert(slopeX.X < 0.0f, "leaning away from the rise");
		Test.Assert(slopeX.Z > 0.0f);
		Test.Assert(Abs(Length(slopeX) - 1.0f) < 0.0001f, "and still unit length");

		// Rising downward tilts it towards negative Y.
		let slopeY = NormalMaps.CalculateNormalFromHeight(0.0f, 0.0f, 0.0f, 1.0f);
		Test.Assert(slopeY.Y < 0.0f);
		Test.Assert(slopeY.Z > 0.0f);

		// A larger scale exaggerates the same slope.
		let steeper = NormalMaps.CalculateNormalFromHeight(0.0f, 1.0f, 0.0f, 0.0f, 4.0f);
		Test.Assert(steeper.X < slopeX.X, "a bigger scale is a steeper normal");
	}

	[Test]
	public static void EncodingPutsTheNeutralNormalAtTheMidpoint()
	{
		Test.Assert(NormalMaps.Encode(.(0, 0, 1)) == Color32(128, 128, 255, 255));
		// The extremes land at the ends of the range.
		Test.Assert(NormalMaps.Encode(.(1, 0, 0)).R == 255);
		Test.Assert(NormalMaps.Encode(.(-1, 0, 0)).R == 0);
	}

	/// True when the values are not all the same.
	private static bool Varies(List<uint8> values)
	{
		if (values.Count < 2)
			return false;
		for (int i = 1; i < values.Count; i++)
		{
			if (values[i] != values[0])
				return true;
		}
		return false;
	}
}
