using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;

namespace Sedulous.Heightfield;

/// A square grid of quantised heights, and the sampling maths over it.
///
/// The SHARED SOURCE OF TRUTH for the terrain renderer, the physics collider and the
/// navigation bake: none of them reads heights through the renderer. Nothing here touches a
/// device, and nothing here knows what terrain is.
///
/// A grid is SQUARE with side S = 64k + 1 (65, 129, 257, ...). That one rule tiles into 64
/// quad chunks that share their edges AND satisfies the square heightfield shape the physics
/// backend wants. The uint16 samples map linearly onto a world Y range over an XZ footprint
/// CENTRED ON THE LOCAL ORIGIN, +Y up; the entity's transform puts it somewhere in the world.
class Heightfield
{
	/// A sample is zero at MinY and 65535 at MaxY.
	public const uint16 MaxSample = 65535;

	private static int64 sNextUid;

	private int32 mSize = 0;
	private Float2 mWorldSize = .(0.0f, 0.0f);
	private float mMinY = 0.0f;
	private float mMaxY = 0.0f;
	private uint64 mVersion = 1;
	private List<uint16> mSamples = new .() ~ delete _;
	/// The per sample cut plane, nought solid and 255 cut, laid out like the heights.
	private List<uint8> mHoles = new .() ~ delete _;
	/// Cut samples, which is every consumer's O(1) "nothing to do here".
	private uint32 mHoleCount = 0;

	/// Unique per INSTANCE, and what a GPU cache keys on.
	///
	/// Never the reference: a freed heightfield's address can be handed to a fresh grid at
	/// the same version, since every fresh grid starts at one, and the cache would then
	/// serve the dead grid's texture.
	public readonly uint64 Uid = (uint64)Interlocked.Increment(ref sNextUid);

	/// An empty grid, which is what a failed build produces.
	public this() {}

	/// A zeroed grid. `size` MUST satisfy IsValidSize; `worldSize` is the XZ footprint and
	/// [minY, maxY] the world Y range the samples span.
	public this(int32 size, Float2 worldSize, float minY, float maxY)
	{
		mSize = size;
		mWorldSize = worldSize;
		mMinY = minY;
		mMaxY = maxY;
		mSamples.Resize((int)size * (int)size);
		mHoles.Resize((int)size * (int)size);
	}

	/// True when `size` is a legal side: 64k + 1, k at least one.
	public static bool IsValidSize(int32 size) => (size >= 65) && (((size - 1) % 64) == 0);

	/// The next legal size at or above `size`, never below 65. What an importer resamples to.
	public static int32 NextValidSize(int32 size)
	{
		if (size <= 65)
			return 65;

		let chunks = (size - 1 + 63) / 64;
		return chunks * 64 + 1;
	}

	public bool IsEmpty => mSize <= 0;
	public int32 Size => mSize;
	public Float2 WorldSize => mWorldSize;
	public float MinY => mMinY;
	public float MaxY => mMaxY;

	/// A monotonic edit generation, starting at one. Bumped after samples are rewritten, so
	/// the GPU caches downstream know to re-upload: the sculpt and regenerate path.
	public uint64 Version => mVersion;
	public void BumpVersion()
	{
		mVersion++;
	}

	// ---- raw samples, with grid indices clamped into the grid ----

	public uint16 GetSample(int32 gx, int32 gz) => mSamples[Index(gx, gz)];
	public void SetSample(int32 gx, int32 gz, uint16 height) => mSamples[Index(gx, gz)] = height;

	public Span<uint16> Samples => .(mSamples.Ptr, mSamples.Count);

	// ---- holes: a per SAMPLE cut ----
	//
	// The ONE rule every consumer applies is Jolt's: a triangle with a cut vertex is gone. The
	// renderer's chunk indices, the physics no collision sample, the nav bake's blocks, the
	// vegetation's placement and the ray query all read this same plane, so a hole cannot mean
	// one thing to the eye and another to a foot.
	//
	// A byte per sample laid out like the heights, and the plane is the cooked form's holes
	// stream. The count is what keeps every consumer's "no holes here" free.

	public bool IsHole(int32 gx, int32 gz) => mHoles[Index(gx, gz)] != 0;

	public void SetHole(int32 gx, int32 gz, bool hole)
	{
		let at = Index(gx, gz);
		if ((mHoles[at] != 0) == hole)
			return;

		mHoles[at] = hole ? 255 : 0;
		if (hole)
			mHoleCount++;
		else
			mHoleCount--;
	}

	public Span<uint8> Holes => .(mHoles.Ptr, mHoles.Count);

	/// Replaces the WHOLE plane, which is what loading the cooked holes stream does. A blob of
	/// any other size is refused and the plane is left as it was.
	public bool SetHoles(Span<uint8> plane)
	{
		if (plane.Length != mHoles.Count)
			return false;

		mHoleCount = 0;
		for (int i < plane.Length)
		{
			mHoles[i] = (plane[i] != 0) ? 255 : 0;
			if (plane[i] != 0)
				mHoleCount++;
		}
		return true;
	}

	public uint32 HoleCount => mHoleCount;
	public bool HasHoles => mHoleCount != 0;

	/// Whether the CELL at cx, cz, which is the quad between the samples cx and cx plus one
	/// and cz and cz plus one, has a cut corner: both of its triangles are then gone.
	///
	/// The indices clamp the way every other accessor's do.
	public bool CellHasHole(int32 cx, int32 cz)
	{
		if (mHoleCount == 0)
			return false;
		return IsHole(cx, cz) || IsHole(cx + 1, cz) || IsHole(cx, cz + 1)
			|| IsHole(cx + 1, cz + 1);
	}

	/// Any cut sample in the INCLUSIVE block, which the coarse level quad and the nav bake's
	/// stride block both ask: a hole never shrinks with distance.
	public bool BlockHasHole(int32 gx0, int32 gz0, int32 gx1, int32 gz1)
	{
		if (mHoleCount == 0)
			return false;

		let x0 = Clamp(gx0, 0, mSize - 1);
		let x1 = Clamp(gx1, 0, mSize - 1);
		let z0 = Clamp(gz0, 0, mSize - 1);
		let z1 = Clamp(gz1, 0, mSize - 1);
		for (int32 gz = z0; gz <= z1; gz++)
		{
			for (int32 gx = x0; gx <= x1; gx++)
			{
				if (mHoles[Index(gx, gz)] != 0)
					return true;
			}
		}
		return false;
	}

	/// The cell a local XZ position lies in, clamped to the grid's cells.
	public void CellOfLocal(float localX, float localZ, out int32 outCx, out int32 outCz)
	{
		let g = WorldToGrid(localX, localZ);
		outCx = Clamp((int32)Floor(g.X), 0, mSize - 2);
		outCz = Clamp((int32)Floor(g.Y), 0, mSize - 2);
	}

	// ---- quantisation ----

	public float SampleToWorldY(float sample) => mMinY + (sample / 65535.0f) * (mMaxY - mMinY);

	public uint16 WorldYToSample(float worldY)
	{
		let range = mMaxY - mMinY;
		let t = (range > 0.0f) ? ((worldY - mMinY) / range) : 0.0f;
		return (uint16)Round(Clamp(t, 0.0f, 1.0f) * 65535.0f);
	}

	// ---- world XZ against grid coordinates, the footprint being centred on the origin ----

	public Float2 WorldToGrid(float worldX, float worldZ)
	{
		let span = (float)(mSize - 1);
		return .((worldX / mWorldSize.X + 0.5f) * span, (worldZ / mWorldSize.Y + 0.5f) * span);
	}

	public Float2 GridToWorld(float gridX, float gridZ)
	{
		let span = (float)(mSize - 1);
		return .((gridX / span - 0.5f) * mWorldSize.X, (gridZ / span - 0.5f) * mWorldSize.Y);
	}

	// ---- height queries, in world Y ----

	/// The height AT a grid point, which is exact rather than interpolated.
	public float GetHeightAtGrid(int32 gx, int32 gz) => SampleToWorldY((float)GetSample(gx, gz));

	/// Bilinear height at a world XZ point. Outside the footprint CLAMPS to the edge rather
	/// than falling away, so a query off the side of the terrain still answers.
	public float GetHeightAt(float worldX, float worldZ)
	{
		if (IsEmpty)
			return 0.0f;

		let grid = WorldToGrid(worldX, worldZ);
		let span = (float)(mSize - 1);
		let cgx = Clamp(grid.X, 0.0f, span);
		let cgz = Clamp(grid.Y, 0.0f, span);
		let last = Max(0, mSize - 2);
		let x0 = Clamp((int32)Floor(cgx), 0, last);
		let z0 = Clamp((int32)Floor(cgz), 0, last);
		let fx = cgx - (float)x0;
		let fz = cgz - (float)z0;

		let h00 = (float)GetSample(x0, z0);
		let h10 = (float)GetSample(x0 + 1, z0);
		let h01 = (float)GetSample(x0, z0 + 1);
		let h11 = (float)GetSample(x0 + 1, z0 + 1);
		let top = h00 + (h10 - h00) * fx;
		let bottom = h01 + (h11 - h01) * fx;
		return SampleToWorldY(top + (bottom - top) * fz);
	}

	/// The unit surface normal in world space, from central differences one cell wide.
	public Float3 GetNormalAt(float worldX, float worldZ)
	{
		if (IsEmpty)
			return .(0.0f, 1.0f, 0.0f);

		let ex = mWorldSize.X / (float)(mSize - 1);
		let ez = mWorldSize.Y / (float)(mSize - 1);
		let dhdx = (GetHeightAt(worldX + ex, worldZ) - GetHeightAt(worldX - ex, worldZ)) / (2.0f * ex);
		let dhdz = (GetHeightAt(worldX, worldZ + ez) - GetHeightAt(worldX, worldZ - ez)) / (2.0f * ez);
		return Normalized(Float3(-dhdx, 1.0f, -dhdz));
	}

	/// The world Y range over an INCLUSIVE grid block, which is what a chunk's bounds are.
	public void CellBounds(int32 gx0, int32 gz0, int32 gx1, int32 gz1, out float outMinY,
		out float outMaxY)
	{
		uint16 lo = MaxSample;
		uint16 hi = 0;
		for (int32 z = gz0; z <= gz1; z++)
		{
			for (int32 x = gx0; x <= gx1; x++)
			{
				let sample = GetSample(x, z);
				lo = (sample < lo) ? sample : lo;
				hi = (sample > hi) ? sample : hi;
			}
		}
		outMinY = SampleToWorldY((float)lo);
		outMaxY = SampleToWorldY((float)hi);
	}

	/// A LOCAL SPACE ray against the surface, answering the nearest hit distance.
	///
	/// A height field march: clip to the grid's box, step by about half a cell, and bisect
	/// wherever the ray drops through the bilinear surface. Robust enough for editor picking,
	/// which is what it is for.
	public bool QueryRay(Float3 origin, Float3 direction, out float outT)
	{
		outT = 0.0f;
		if (IsEmpty)
			return false;

		let dir = Normalized(direction);
		let halfX = mWorldSize.X * 0.5f;
		let halfZ = mWorldSize.Y * 0.5f;
		if (!ClipToAabb(origin, dir, .(-halfX, mMinY, -halfZ), .(halfX, mMaxY, halfZ),
			let t0, let t1))
			return false;

		// Stepped so the HORIZONTAL travel is about half a cell. A near vertical ray has
		// almost none, so it falls back to stepping through the Y range instead.
		let cell = mWorldSize.X / (float)(mSize - 1);
		let horizontalSpeed = Sqrt(dir.X * dir.X + dir.Z * dir.Z);
		let verticalSpeed = Abs(dir.Y);
		let speed = Max(horizontalSpeed, verticalSpeed);
		let step = (speed > 1.0e-6f) ? (0.5f * cell / speed) : (0.5f * cell);

		var tPrevious = t0;
		var gapPrevious = SignedGap(origin, dir, t0);
		// Already at or under the surface where the ray entered the box.
		if ((gapPrevious <= 0.0f) && !HoleAt(origin, dir, t0))
		{
			outT = t0;
			return true;
		}

		for (var t = t0 + step; t <= t1 + step; t += step)
		{
			let tc = Min(t, t1);
			let gap = SignedGap(origin, dir, tc);
			// Crossed the surface between the last step and this one. The previous gap has to
			// be ABOVE for this to be a crossing rather than a march that is still under the
			// field after passing through a cut.
			if ((gapPrevious > 0.0f) && (gap <= 0.0f))
			{
				// Crossed between the last step and this one, so bisect for the crossing.
				var lo = tPrevious;
				var hi = tc;
				for (int i < 12)
				{
					let mid = 0.5f * (lo + hi);
					if (SignedGap(origin, dir, mid) > 0.0f)
						lo = mid;
					else
						hi = mid;
				}
				let hit = 0.5f * (lo + hi);
				// A crossing inside a CUT cell is no surface: the ray passes through to
				// whatever sits below, a cave floor or the physics world, and the march goes
				// on, needing to come back above the field before another crossing counts.
				if (!HoleAt(origin, dir, hit))
				{
					outT = hit;
					return true;
				}
			}

			tPrevious = tc;
			gapPrevious = gap;
			if (tc >= t1)
				break;
		}
		return false;
	}

	/// Whether the cell under the ray point at a distance has a cut corner, and so no surface.
	private bool HoleAt(Float3 origin, Float3 dir, float t)
	{
		if (mHoleCount == 0)
			return false;

		CellOfLocal(origin.X + dir.X * t, origin.Z + dir.Z * t, let cx, let cz);
		return CellHasHole(cx, cz);
	}

	private int Index(int32 gx, int32 gz)
	{
		let cx = Clamp(gx, 0, mSize - 1);
		let cz = Clamp(gz, 0, mSize - 1);
		return (int)cx + (int)cz * (int)mSize;
	}

	/// How far the ray is ABOVE the surface at a distance: positive above, negative below.
	private float SignedGap(Float3 origin, Float3 dir, float t)
	{
		let px = origin.X + dir.X * t;
		let py = origin.Y + dir.Y * t;
		let pz = origin.Z + dir.Z * t;
		return py - GetHeightAt(px, pz);
	}

	/// Slab clip of a ray against a box, answering the overlapping range with t0 at or above
	/// zero.
	private static bool ClipToAabb(Float3 origin, Float3 dir, Float3 lo, Float3 hi, out float t0,
		out float t1)
	{
		t0 = 0.0f;
		t1 = 0.0f;

		var tMin = 0.0f;
		var tMax = FloatMax;
		let originAxes = float[3](origin.X, origin.Y, origin.Z);
		let dirAxes = float[3](dir.X, dir.Y, dir.Z);
		let loAxes = float[3](lo.X, lo.Y, lo.Z);
		let hiAxes = float[3](hi.X, hi.Y, hi.Z);

		for (int axis < 3)
		{
			if (Abs(dirAxes[axis]) < 1.0e-8f)
			{
				// Parallel to this slab, so it either starts inside it or never enters.
				if ((originAxes[axis] < loAxes[axis]) || (originAxes[axis] > hiAxes[axis]))
					return false;
				continue;
			}

			let inverse = 1.0f / dirAxes[axis];
			var tNear = (loAxes[axis] - originAxes[axis]) * inverse;
			var tFar = (hiAxes[axis] - originAxes[axis]) * inverse;
			if (tNear > tFar)
				Swap!(tNear, tFar);

			tMin = Max(tMin, tNear);
			tMax = Min(tMax, tFar);
			if (tMin > tMax)
				return false;
		}

		t0 = tMin;
		t1 = tMax;
		return true;
	}
}
