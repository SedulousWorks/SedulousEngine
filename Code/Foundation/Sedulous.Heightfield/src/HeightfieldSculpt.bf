using System;
using Sedulous.Core;

namespace Sedulous.Heightfield;

/// The sculpt brushes: pure sample maths, which an editor tool wraps.
///
/// Each brush edits the samples under a WORLD SPACE DISC with a cosine falloff, one at the
/// centre and zero at the rim, clamps into the sample range, bumps the version if anything
/// changed, and reports the grid rectangle it touched. Nothing here needs a device or an
/// editor, so all of it is testable headless.
static class HeightfieldSculpt
{
	/// Raises by up to `strengthWorldY` world units at the centre, or lowers with a negative
	/// strength, falling off to the rim.
	public static HeightfieldRegion Raise(Heightfield field, float worldX, float worldZ,
		float radius, float strengthWorldY)
	{
		let range = field.MaxY - field.MinY;
		let perUnit = (range > 1.0e-6f) ? (65535.0f / range) : 0.0f;

		let region = VisitBrush(field, worldX, worldZ, radius, scope (gx, gz, weight) =>
			{
				let sample = (float)field.GetSample(gx, gz) + strengthWorldY * weight * perUnit;
				field.SetSample(gx, gz, ClampSample(sample));
			});

		if (!region.IsEmpty)
			field.BumpVersion();
		return region;
	}

	/// Pulls toward `targetWorldY` by an `amount` in zero to one, scaled by the falloff.
	public static HeightfieldRegion Flatten(Heightfield field, float worldX, float worldZ,
		float radius, float amount, float targetWorldY)
	{
		let target = (float)field.WorldYToSample(targetWorldY);

		let region = VisitBrush(field, worldX, worldZ, radius, scope (gx, gz, weight) =>
			{
				let sample = (float)field.GetSample(gx, gz);
				field.SetSample(gx, gz, ClampSample(sample + (target - sample) * (weight * amount)));
			});

		if (!region.IsEmpty)
			field.BumpVersion();
		return region;
	}

	/// Pulls each sample toward its three by three neighbourhood average by an `amount` in
	/// zero to one.
	public static HeightfieldRegion Smooth(Heightfield field, float worldX, float worldZ,
		float radius, float amount)
	{
		let size = field.Size;

		let region = VisitBrush(field, worldX, worldZ, radius, scope (gx, gz, weight) =>
			{
				var sum = 0.0f;
				var count = 0;
				for (int32 dz = -1; dz <= 1; dz++)
				{
					for (int32 dx = -1; dx <= 1; dx++)
					{
						let nx = gx + dx;
						let nz = gz + dz;
						if ((nx < 0) || (nx >= size) || (nz < 0) || (nz >= size))
							continue;

						sum += (float)field.GetSample(nx, nz);
						count++;
					}
				}

				let average = (count > 0) ? (sum / (float)count) : 0.0f;
				let sample = (float)field.GetSample(gx, gz);
				field.SetSample(gx, gz, ClampSample(sample + (average - sample) * (weight * amount)));
			});

		if (!region.IsEmpty)
			field.BumpVersion();
		return region;
	}

	/// Visits every grid point inside a world disc with its falloff weight, and reports the
	/// rectangle they span.
	///
	/// The rectangle covers what was ACTUALLY touched rather than the whole clamped scan
	/// box, because the disc's corners are outside it and re-uploading them would be waste.
	private static HeightfieldRegion VisitBrush(Heightfield field, float worldX, float worldZ,
		float radius, delegate void(int32 gx, int32 gz, float weight) apply)
	{
		var region = HeightfieldRegion();
		if (field.IsEmpty || (radius <= 0.0f))
			return region;

		let size = field.Size;
		let worldSize = field.WorldSize;
		let spanX = worldSize.X / (float)(size - 1);
		let spanZ = worldSize.Y / (float)(size - 1);
		let center = field.WorldToGrid(worldX, worldZ);
		let gridRadiusX = radius / ((spanX > 1.0e-6f) ? spanX : 1.0f);
		let gridRadiusZ = radius / ((spanZ > 1.0e-6f) ? spanZ : 1.0f);

		let x0 = Max(0, (int32)Floor(center.X - gridRadiusX));
		let x1 = Min(size - 1, (int32)Ceil(center.X + gridRadiusX));
		let z0 = Max(0, (int32)Floor(center.Y - gridRadiusZ));
		let z1 = Min(size - 1, (int32)Ceil(center.Y + gridRadiusZ));
		let inverseRadius = 1.0f / radius;

		for (int32 gz = z0; gz <= z1; gz++)
		{
			for (int32 gx = x0; gx <= x1; gx++)
			{
				let point = field.GridToWorld((float)gx, (float)gz);
				let dx = point.X - worldX;
				let dz = point.Y - worldZ;
				let distance = Sqrt(dx * dx + dz * dz);
				if (distance >= radius)
					continue;

				// One at the centre, zero at the rim.
				let weight = 0.5f + 0.5f * Cos(Pi * distance * inverseRadius);
				apply(gx, gz, weight);
				region.Add(gx, gz);
			}
		}
		return region;
	}

	/// Rounds into the sample range, so a brush cannot push a sample past the floor or the
	/// ceiling the grid's Y range defines.
	private static uint16 ClampSample(float value) =>
		(uint16)(Clamp(value, 0.0f, 65535.0f) + 0.5f);
}
