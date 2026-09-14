using System;
using Sedulous.Core;
using Sedulous.Heightfield;

namespace Samples.TerrainPlayground;

/// Filling a grid with one of the playground's shapes.
static class HeightfieldShapes
{
	/// Rewrites every sample and BUMPS THE VERSION, which is what makes the height texture and
	/// the chunk models re-upload: the grid changing in memory is not a thing the GPU notices.
	public static void Generate(Heightfield grid, TerrainType type, float amplitude,
		float frequency)
	{
		let size = grid.Size;
		let centre = (float)(size - 1) * 0.5f;

		for (int32 z < size)
		{
			for (int32 x < size)
			{
				let fx = (float)x;
				let fz = (float)z;
				let dx = (fx - centre) / centre; // minus one to one, from the centre out
				let dz = (fz - centre) / centre;
				let radius = Math.Min(Math.Sqrt(dx * dx + dz * dz), 1.0f);

				var height = 0.0f;
				switch (type)
				{
				case .Hills:
					// Layered sines, which give a landscape that rolls rather than repeats.
					height = 0.5f
						+ 0.25f * Math.Sin(fx * frequency) * Math.Cos(fz * frequency)
						+ 0.15f * Math.Sin(fx * frequency * 2.3f + 1.7f)
						+ 0.10f * Math.Cos(fz * frequency * 3.1f);
				case .Dome:
					height = Math.Cos(radius * 1.5707963f); // one at the centre, nought at the rim
				case .Ripple:
					height = 0.5f + 0.5f * Math.Sin(radius * 20.0f * frequency) * (1.0f - radius);
				case .Plateau:
					height = Math.Clamp(1.5f - radius * 2.2f, 0.0f, 1.0f); // flat top, sloped skirt
				}

				height = Math.Clamp(height * amplitude, 0.0f, 1.0f);
				grid.SetSample(x, z, (uint16)(height * 65535.0f));
			}
		}

		grid.BumpVersion();
	}
}
