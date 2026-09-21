using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Image;

/// Procedural normal maps, for placeholders and for making a lighting problem visible
/// while the real art does not exist yet.
///
/// A normal is encoded into RGB as (n * 0.5 + 0.5) * 255, so the neutral up normal
/// (0, 0, 1) becomes (128, 128, 255). Every generator here keeps Z positive: a normal
/// pointing INTO the surface is not a shape, it is a bug that lights as a hole.
///
/// THE CALLER OWNS every image returned.
static class NormalMaps
{
	public static Image CreateFlat(uint32 width = 256, uint32 height = 256, PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		image.FillColor(.(128, 128, 255, 255));
		return image;
	}

	public static Image CreateWave(uint32 width = 256, uint32 height = 256,
		float frequencyX = 8.0f, float frequencyY = 6.0f, float amplitude = 0.3f,
		PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				let fx = (float)x / (float)width;
				let fy = (float)y / (float)height;

				// The height field, and the same field one texel right and one down, so
				// the slope comes from finite differences rather than an analytic
				// derivative that would have to be kept in step with the field.
				let here = Sin(fx * Pi * frequencyX) * amplitude
					+ Sin(fy * Pi * frequencyY) * amplitude * 0.7f;
				let right = Sin((fx + 1.0f / (float)width) * Pi * frequencyX) * amplitude
					+ Sin(fy * Pi * frequencyY) * amplitude * 0.7f;
				let down = Sin(fx * Pi * frequencyX) * amplitude
					+ Sin((fy + 1.0f / (float)height) * Pi * frequencyY) * amplitude * 0.7f;

				image.SetPixel(x, y, Encode(Normalized(Float3(
					-(right - here) * 20.0f, -(down - here) * 20.0f, 1.0f))));
			}
		}
		return image;
	}

	/// Brickwork.
	///
	/// NOTE: this produces a FLAT map. Every normal it builds is of the form
	/// (0, 0, positive), and normalising that gives (0, 0, 1) whatever the Z was, so the
	/// mortar and the brick faces encode identically. A test phrased as "every pixel differs
	/// from neutral" would not catch it under a truncating encoder, which is how it survived.
	///
	/// Kept as is rather than quietly redesigned: making it real means deriving the normal
	/// from the height field by finite differences, the way CreateWave does, and that is a
	/// change to what the engine draws.
	public static Image CreateBrick(uint32 width = 256, uint32 height = 256,
		uint32 bricksX = 8, uint32 bricksY = 4, float mortarDepth = 0.3f,
		PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		let brickWidth = (bricksX > 0) ? (width / bricksX) : width;
		let brickHeight = (bricksY > 0) ? (height / bricksY) : height;
		if ((brickWidth == 0) || (brickHeight == 0))
			return image;

		let mortarWidth = ((brickWidth / 16) > 2) ? (brickWidth / 16) : 2;

		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				let row = y / brickHeight;
				// Alternate rows are offset by half a brick, which is what makes it read
				// as brickwork rather than a grid.
				let shifted = ((row % 2) == 1) ? ((x + brickWidth / 2) % width) : x;

				let localX = shifted % brickWidth;
				let localY = y % brickHeight;
				let inMortar = (localY < mortarWidth) || (localY >= (brickHeight - mortarWidth))
					|| (localX < mortarWidth) || (localX >= (brickWidth - mortarWidth));

				Float3 normal;
				if (inMortar)
				{
					normal = .(0.0f, 0.0f, 1.0f - mortarDepth * 2.0f);
				}
				else
				{
					// A little variation across the face, so a brick is not a flat card.
					let variation = Sin((float)localX * 0.2f) * Sin((float)localY * 0.15f) * 0.1f;
					normal = .(0.0f, 0.0f, 1.0f + variation);
				}
				image.SetPixel(x, y, Encode(Normalized(normal)));
			}
		}
		return image;
	}

	public static Image CreateCircularBump(uint32 width = 256, uint32 height = 256,
		float bumpHeight = 0.5f, float falloff = 2.0f, PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		let centerX = (float)width * 0.5f;
		let centerY = (float)height * 0.5f;
		let smaller = (width < height) ? width : height;
		let maxRadius = (float)smaller * 0.4f;

		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				let dx = (float)x - centerX;
				let dy = (float)y - centerY;
				let distance = Sqrt(dx * dx + dy * dy);

				var normal = Float3(0.0f, 0.0f, 1.0f);
				// Outside the bump, and exactly at its centre, the surface is flat. The
				// centre needs saying because the slope there divides by the distance.
				if ((distance < maxRadius) && (distance > 0.001f))
				{
					let normalised = distance / maxRadius;
					let slope = -falloff * Pow(1.0f - normalised, falloff - 1.0f)
						* bumpHeight * 3.0f / maxRadius;
					normal = Normalized(Float3((dx / distance) * slope, (dy / distance) * slope, 1.0f));
				}
				image.SetPixel(x, y, Encode(normal));
			}
		}
		return image;
	}

	public static Image CreateNoise(uint32 width = 256, uint32 height = 256, float scale = 0.1f,
		float amplitude = 0.2f, int32 seed = 12345, PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);

		let heights = scope List<float>();
		heights.Resize((int)width * (int)height);

		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				var noise = 0.0f;
				var frequency = scale;
				var octaveAmplitude = amplitude;

				for (int32 octave < 4)
				{
					let fx = (float)x * frequency;
					let fy = (float)y * frequency;
					let ix = (int32)fx;
					let iy = (int32)fy;
					let fracX = fx - (float)ix;
					let fracY = fy - (float)iy;

					let a = HashToFloat(seed + ix + iy * 1000 + octave * 10000);
					let b = HashToFloat(seed + (ix + 1) + iy * 1000 + octave * 10000);
					let c = HashToFloat(seed + ix + (iy + 1) * 1000 + octave * 10000);
					let d = HashToFloat(seed + (ix + 1) + (iy + 1) * 1000 + octave * 10000);

					// Smoothstep on the fraction, so the lattice does not show as a grid.
					let smoothX = fracX * fracX * (3.0f - 2.0f * fracX);
					let smoothY = fracY * fracY * (3.0f - 2.0f * fracY);

					noise += Lerp(Lerp(a, b, smoothX), Lerp(c, d, smoothX), smoothY) * octaveAmplitude;
					frequency *= 2.0f;
					octaveAmplitude *= 0.5f;
				}
				heights[(int)y * (int)width + (int)x] = noise;
			}
		}

		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				// Neighbours are edge CLAMPED. Sampling x - 1 at x == 0 would wrap an
				// unsigned index to four billion and read far outside the buffer.
				let left = (x > 0) ? (x - 1) : 0;
				let right = ((x + 1) < width) ? (x + 1) : (width - 1);
				let up = (y > 0) ? (y - 1) : 0;
				let down = ((y + 1) < height) ? (y + 1) : (height - 1);

				let dx = heights[(int)y * (int)width + (int)right] - heights[(int)y * (int)width + (int)left];
				let dy = heights[(int)down * (int)width + (int)x] - heights[(int)up * (int)width + (int)x];
				image.SetPixel(x, y, Encode(Normalized(Float3(-dx * 8.0f, -dy * 8.0f, 1.0f))));
			}
		}
		return image;
	}

	/// Four quadrants: flat, bumps along X, bumps along Y, and a circular feature. Made to
	/// be looked at, so a lighting or tangent problem shows up as an obviously wrong
	/// quadrant rather than a subtly wrong surface.
	public static Image CreateTestPattern(uint32 width = 256, uint32 height = 256,
		PixelFormat format = .RGBA8)
	{
		let image = new Image(width, height, format);
		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				let fx = (float)x / (float)width;
				let fy = (float)y / (float)height;

				Float3 normal;
				if ((fx < 0.5f) && (fy < 0.5f))
				{
					normal = .(0.0f, 0.0f, 1.0f);
				}
				else if ((fx >= 0.5f) && (fy < 0.5f))
				{
					normal = Normalized(Float3(Sin(fx * Pi * 16.0f) * 0.5f, 0.0f, 1.0f));
				}
				else if ((fx < 0.5f) && (fy >= 0.5f))
				{
					normal = Normalized(Float3(0.0f, Sin(fy * Pi * 16.0f) * 0.5f, 1.0f));
				}
				else
				{
					let dx = fx - 0.75f;
					let dy = fy - 0.75f;
					let distance = Sqrt(dx * dx + dy * dy);
					if (distance < 0.2f)
					{
						let angle = Atan2(dy, dx);
						normal = Normalized(Float3(Cos(angle) * 0.3f, Sin(angle) * 0.3f, 1.0f));
					}
					else
					{
						normal = .(0.0f, 0.0f, 1.0f);
					}
				}
				image.SetPixel(x, y, Encode(normal));
			}
		}
		return image;
	}

	/// A normal from four neighbouring heights, which is how a heightmap becomes a normal
	/// map.
	public static Float3 CalculateNormalFromHeight(float left, float right, float up, float down,
		float scale = 1.0f)
	{
		return Normalized(Float3(-(right - left) * scale, -(down - up) * scale, 1.0f));
	}

	/// Encodes a unit normal into RGB, opaque.
	///
	/// ROUNDED, not truncated. Truncating puts the neutral normal at 127 rather than the
	/// 128 the encoding documents, because (0 * 0.5 + 0.5) * 255 is 127.5. That is half a
	/// channel of bias on every axis, and it also makes any test phrased as "this pixel
	/// differs from neutral" pass for every pixel of every map. Core's Color32 rounds for
	/// the same reason.
	public static Color32 Encode(Float3 normal)
	{
		return .(Channel(normal.X), Channel(normal.Y), Channel(normal.Z), 255);
	}

	private static uint8 Channel(float component)
		=> (uint8)(Clamp(component * 0.5f + 0.5f, 0.0f, 1.0f) * 255.0f + 0.5f);

	/// An integer hash to a float in [-1, 1], for value noise.
	///
	/// Wrapping operators throughout: the mixing RELIES on overflow, and plain arithmetic
	/// would trap wherever overflow checks are on.
	private static float HashToFloat(int32 value)
	{
		var hash = (uint32)value;
		hash = hash &* 1103515245 &+ 12345;
		hash = (hash >> 16) ^ hash;
		hash = hash &* 0x85EBCA6B;
		hash = (hash >> 13) ^ hash;
		return ((float)(hash & 0x7FFFFFFF) / (float)0x7FFFFFFF) * 2.0f - 1.0f;
	}
}
