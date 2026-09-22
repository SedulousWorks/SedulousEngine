using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Vegetation.Resource;

/// The painted vegetation mask.
///
/// Density planes of one byte per texel, nought growing nothing and 255 the layer's full
/// density, over the terrain's nought to one footprint uv, plane major in one blob. A layer
/// with Mask placement names its plane and the scatter reads the density at each candidate.
///
/// The per object uid and version drive the scatter cache invalidation, exactly as the splat
/// raster's do: a cache keys by those, never by the pointer.
class VegetationMask
{
	/// The largest plane count a mask carries; a colour import yields one plane per channel.
	public const uint32 cMaxPlanes = 16;

	private static int64 sNextUid;

	/// Unique per OBJECT, so a cache can key by it.
	public readonly uint64 Uid = (uint64)Interlocked.Increment(ref sNextUid);

	private int32 mWidth = 0;
	private int32 mHeight = 0;
	private uint32 mPlaneCount = 1;
	private uint64 mVersion = 1;
	private List<uint8> mDensities = new .() ~ delete _;

	public this() {}

	/// Allocates the planes all zero: nothing grows until it is painted.
	public this(int32 width, int32 height, uint32 planeCount)
	{
		mWidth = width;
		mHeight = height;
		mPlaneCount = (planeCount == 0) ? 1 : Math.Min(planeCount, cMaxPlanes);
		if ((width > 0) && (height > 0))
			mDensities.Resize(PlaneBytes * (int)mPlaneCount);
	}

	public bool IsEmpty => (mWidth <= 0) || (mHeight <= 0);
	public int32 Width => mWidth;
	public int32 Height => mHeight;
	public uint32 PlaneCount => mPlaneCount;
	public int PlaneBytes => (int)mWidth * (int)mHeight;

	/// Bumped by every brush operation and by a load, so the scatter cache regrows.
	public uint64 Version => mVersion;
	public void BumpVersion() => mVersion++;

	/// Every plane, plane major.
	public Span<uint8> Densities => .(mDensities.Ptr, mDensities.Count);

	/// One plane's raster, row major; empty for a plane out of range.
	public Span<uint8> Plane(uint32 plane)
	{
		if ((plane >= mPlaneCount) || IsEmpty)
			return .();
		return .(mDensities.Ptr + PlaneBytes * (int)plane, PlaneBytes);
	}

	/// The density of a plane at a texel, nought outside the raster or the planes.
	public uint8 DensityAt(uint32 plane, int32 x, int32 y)
	{
		if ((plane >= mPlaneCount) || IsEmpty || (x < 0) || (y < 0) || (x >= mWidth)
			|| (y >= mHeight))
			return 0;
		return mDensities[PlaneBytes * (int)plane + (int)y * (int)mWidth + (int)x];
	}

	/// Writes one texel of a plane; a plane or a texel out of range is ignored.
	public void SetDensity(uint32 plane, int32 x, int32 y, uint8 density)
	{
		if ((plane >= mPlaneCount) || IsEmpty || (x < 0) || (y < 0) || (x >= mWidth)
			|| (y >= mHeight))
			return;
		mDensities[PlaneBytes * (int)plane + (int)y * (int)mWidth + (int)x] = density;
	}

	/// The density at a footprint uv, nought to one, as a share: nearest texel, clamped.
	public float ShareAt(uint32 plane, float u, float v)
	{
		if ((plane >= mPlaneCount) || IsEmpty)
			return 0.0f;

		let cu = Clamp(u, 0.0f, 1.0f);
		let cv = Clamp(v, 0.0f, 1.0f);
		let x = (int32)(cu * (float)(mWidth - 1) + 0.5f);
		let y = (int32)(cv * (float)(mHeight - 1) + 0.5f);
		return (float)DensityAt(plane, x, y) / 255.0f;
	}
}

/// The inclusive texel rectangle a brush operation touched: the region delta undo and the
/// chunk regrow both read it.
struct MaskRegion
{
	public int32 MinX = int32.MaxValue;
	public int32 MinY = int32.MaxValue;
	public int32 MaxX = -1;
	public int32 MaxY = -1;

	public this() {}

	public bool IsEmpty => (MaxX < MinX) || (MaxY < MinY);
	public int32 Width => IsEmpty ? 0 : (MaxX - MinX + 1);
	public int32 Height => IsEmpty ? 0 : (MaxY - MinY + 1);

	public void Add(int32 x, int32 y) mut
	{
		MinX = Math.Min(MinX, x);
		MinY = Math.Min(MinY, y);
		MaxX = Math.Max(MaxX, x);
		MaxY = Math.Max(MaxY, y);
	}
}

/// The brush operations over a mask plane, on the splat brush's elliptical kernel.
static class MaskBrush
{
	/// Visits every texel inside the WORLD circle, whose uv radii differ per axis, handing
	/// the callback the falloff scaled strength. The core fraction is the flat inner share of
	/// the radius: full strength inside it, a cosine skirt outside.
	private static void Visit(VegetationMask mask, float uvX, float uvY, float uvRadiusX,
		float uvRadiusY, float amount, float coreFraction, delegate void(int32 x, int32 y, float t) fn)
	{
		let w = mask.Width;
		let h = mask.Height;
		let cx = uvX * (float)w;
		let cy = uvY * (float)h;
		let rx = uvRadiusX * (float)w;
		let ry = uvRadiusY * (float)h;
		let x0 = Math.Max(0, (int32)Math.Floor(cx - rx));
		let x1 = Math.Min(w - 1, (int32)Math.Ceiling(cx + rx));
		let y0 = Math.Max(0, (int32)Math.Floor(cy - ry));
		let y1 = Math.Min(h - 1, (int32)Math.Ceiling(cy + ry));
		let invRx = 1.0f / uvRadiusX;
		let invRy = 1.0f / uvRadiusY;
		let core = Clamp(coreFraction, 0.0f, 0.95f);

		for (int32 y = y0; y <= y1; y++)
		{
			for (int32 x = x0; x <= x1; x++)
			{
				let du = (((float)x + 0.5f) / (float)w - uvX) * invRx;
				let dv = (((float)y + 0.5f) / (float)h - uvY) * invRy;
				let dist = Sqrt(du * du + dv * dv); // nought at the centre, one at the rim
				if (dist >= 1.0f)
					continue;

				let fall = (dist <= core)
					? 1.0f
					: 0.5f + 0.5f * Cos(Math.PI_f * (dist - core) / (1.0f - core));
				let t = Clamp(amount * fall, 0.0f, 1.0f);
				if (t > 0.0f)
					fn(x, y, t);
			}
		}
	}

	private static bool Usable(VegetationMask mask, uint32 plane, float uvRadiusX, float uvRadiusY,
		float amount)
	{
		return !mask.IsEmpty && (plane < mask.PlaneCount) && (uvRadiusX > 0.0f)
			&& (uvRadiusY > 0.0f) && (amount > 0.0f);
	}

	/// Paints a plane over a world space brush disc: each texel rises toward 255 by the
	/// stamp's strength, so repeated full strength painting converges there. Bumps the
	/// version when anything changed and answers the touched rect, empty for a no op.
	public static MaskRegion Paint(VegetationMask mask, uint32 plane, float uvX, float uvY,
		float uvRadiusX, float uvRadiusY, float amount, float coreFraction = 0.5f)
	{
		var region = MaskRegion();
		if (!Usable(mask, plane, uvRadiusX, uvRadiusY, amount))
			return region;

		let px = mask.Plane(plane);
		let w = mask.Width;
		var changed = false;
		Visit(mask, uvX, uvY, uvRadiusX, uvRadiusY, amount, coreFraction,
			scope [&](x, y, t) =>
			{
				let at = (int)y * (int)w + (int)x;
				let d = px[at];
				let raised = (float)d + t * (255.0f - (float)d);
				let q = (uint8)Math.Min(255.0f, raised + 0.5f);
				if (q != d)
				{
					px[at] = q;
					changed = true;
					region.Add(x, y);
				}
			});

		if (changed)
			mask.BumpVersion();
		return region;
	}

	/// Erases a plane over the disc: each texel fades toward nought, so repeated full
	/// strength erasing reaches it.
	public static MaskRegion Erase(VegetationMask mask, uint32 plane, float uvX, float uvY,
		float uvRadiusX, float uvRadiusY, float amount, float coreFraction = 0.5f)
	{
		var region = MaskRegion();
		if (!Usable(mask, plane, uvRadiusX, uvRadiusY, amount))
			return region;

		let px = mask.Plane(plane);
		let w = mask.Width;
		var changed = false;
		Visit(mask, uvX, uvY, uvRadiusX, uvRadiusY, amount, coreFraction,
			scope [&](x, y, t) =>
			{
				let at = (int)y * (int)w + (int)x;
				let d = px[at];
				let faded = (float)d * (1.0f - t);
				// A full strength erase lands on exactly nought: rounding to nearest would
				// otherwise leave a one behind at a tiny remainder.
				let q = (uint8)(faded + 0.5f);
				if (q != d)
				{
					px[at] = q;
					changed = true;
					region.Add(x, y);
				}
			});

		if (changed)
			mask.BumpVersion();
		return region;
	}

	/// Smooths a plane over the disc: each texel moves toward its neighbourhood mean by the
	/// stamp's strength, computed from a SNAPSHOT of the disc so the blur never feeds on
	/// itself within one stamp.
	public static MaskRegion Smooth(VegetationMask mask, uint32 plane, float uvX, float uvY,
		float uvRadiusX, float uvRadiusY, float amount, float coreFraction = 0.5f)
	{
		var region = MaskRegion();
		if (!Usable(mask, plane, uvRadiusX, uvRadiusY, amount))
			return region;

		let w = mask.Width;
		let h = mask.Height;
		let px = mask.Plane(plane);

		// The snapshot the means are read from.
		let before = scope List<uint8>();
		before.AddRange(px);

		var changed = false;
		Visit(mask, uvX, uvY, uvRadiusX, uvRadiusY, amount, coreFraction,
			scope [&](x, y, t) =>
			{
				var sum = 0;
				var count = 0;
				for (int32 ny = Math.Max(0, y - 1); ny <= Math.Min(h - 1, y + 1); ny++)
				{
					for (int32 nx = Math.Max(0, x - 1); nx <= Math.Min(w - 1, x + 1); nx++)
					{
						sum += (int)before[(int)ny * (int)w + (int)nx];
						count++;
					}
				}
				if (count == 0)
					return;

				let at = (int)y * (int)w + (int)x;
				let mean = (float)sum / (float)count;
				let d = (float)before[at];
				let q = (uint8)Clamp(d + (mean - d) * t + 0.5f, 0.0f, 255.0f);
				if (q != px[at])
				{
					px[at] = q;
					changed = true;
					region.Add(x, y);
				}
			});

		if (changed)
			mask.BumpVersion();
		return region;
	}
}
