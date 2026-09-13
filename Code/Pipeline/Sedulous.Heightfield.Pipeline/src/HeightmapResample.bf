using System;
using Sedulous.Heightfield;

namespace Sedulous.Heightfield.Pipeline;

/// Fitting an imported heightmap onto the grid.
static class HeightmapResample
{
	/// Bilinearly resamples a single channel sixteen bit source, row major, onto the grid.
	///
	/// The source values ARE the height samples: both quantise onto the same world height
	/// range, so there is nothing to convert between them.
	public static void ResampleR16(uint16* source, uint32 sourceWidth, uint32 sourceHeight,
		Heightfield destination)
	{
		if ((source == null) || (sourceWidth == 0) || (sourceHeight == 0) || destination.IsEmpty)
			return;

		let size = destination.Size;
		let span = (float)(size - 1);
		let lastU = (float)(sourceWidth - 1);
		let lastV = (float)(sourceHeight - 1);

		float Sample(uint32 x, uint32 y)
		{
			let cx = (x < sourceWidth) ? x : sourceWidth - 1;
			let cy = (y < sourceHeight) ? y : sourceHeight - 1;
			return (float)source[(int)cy * (int)sourceWidth + (int)cx];
		}

		for (int32 gz < size)
		{
			let v = (span > 0.0f) ? (float)gz / span * lastV : 0.0f;
			let y0 = (uint32)v;
			let fy = v - (float)y0;
			for (int32 gx < size)
			{
				let u = (span > 0.0f) ? (float)gx / span * lastU : 0.0f;
				let x0 = (uint32)u;
				let fx = u - (float)x0;

				let top = Sample(x0, y0) + (Sample(x0 + 1, y0) - Sample(x0, y0)) * fx;
				let bottom = Sample(x0, y0 + 1) + (Sample(x0 + 1, y0 + 1) - Sample(x0, y0 + 1)) * fx;
				destination.SetSample(gx, gz, (uint16)(top + (bottom - top) * fy + 0.5f));
			}
		}
	}
}
