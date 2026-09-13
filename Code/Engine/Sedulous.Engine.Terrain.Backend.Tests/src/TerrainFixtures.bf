using System;
using Sedulous.Core;
using Sedulous.Heightfield;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// The grids the probes render. The CALLER owns what comes back.
static class TerrainFixtures
{
	/// A radial dome: highest at the centre, falling to nothing at the rim, so the normals
	/// vary and the shading has something to vary with.
	public static Heightfield MakeDome()
	{
		const int32 cSide = 129;
		let grid = new Heightfield(cSide, .(130.0f, 130.0f), 0.0f, 30.0f);

		let centre = (float)(cSide - 1) * 0.5f;
		for (int32 z = 0; z < cSide; z++)
		{
			for (int32 x = 0; x < cSide; x++)
			{
				let dx = ((float)x - centre) / centre;
				let dz = ((float)z - centre) / centre;
				let r = Math.Min(Math.Sqrt(dx * dx + dz * dz), 1.0f);
				// One at the centre, nought at the rim.
				let height = Math.Cos(r * 3.14159265f) * 0.5f + 0.5f;
				grid.SetSample(x, z, (uint16)(height * 65535.0f));
			}
		}
		return grid;
	}

	/// A wall a few cells wide spanning Z, on otherwise low ground: something to cast a
	/// shadow across flat terrain.
	public static Heightfield MakeRidge()
	{
		const int32 cSide = 257;
		let grid = new Heightfield(cSide, .(256.0f, 256.0f), 0.0f, 60.0f);

		let centre = (cSide - 1) / 2;
		for (int32 z = 0; z < cSide; z++)
		{
			for (int32 x = 0; x < cSide; x++)
			{
				let wall = (x >= centre - 3) && (x <= centre + 3);
				grid.SetSample(x, z, (uint16)((wall ? 0.92f : 0.05f) * 65535.0f));
			}
		}
		return grid;
	}

	/// Flat ground at a constant mid height: a clean canvas for the colour checks, where any
	/// variation in the result came from the material rather than the shape.
	public static Heightfield MakeFlat()
	{
		const int32 cSide = 129;
		let grid = new Heightfield(cSide, .(130.0f, 130.0f), 0.0f, 30.0f);

		for (int32 z = 0; z < cSide; z++)
		{
			for (int32 x = 0; x < cSide; x++)
				grid.SetSample(x, z, (uint16)(0.3f * 65535.0f));
		}
		return grid;
	}
}
