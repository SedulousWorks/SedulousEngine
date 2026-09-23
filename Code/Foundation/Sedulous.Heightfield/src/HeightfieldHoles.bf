using System;
using Sedulous.Core;

namespace Sedulous.Heightfield;

/// The hole brushes: pure plane maths, which an editor tool wraps.
///
/// A sample is cut or it is solid, so the disc has a HARD edge: every sample inside the
/// radius is marked and none outside it, with no falloff. A half cut sample would have to
/// mean a half removed triangle, and the one rule every consumer applies has no half.
///
/// The version bumps ONCE when anything changed, and the touched rectangle comes back for the
/// stroke's region delta undo and for the renderer's rebuild.
static class HeightfieldHoles
{
	private static HeightfieldRegion Mark(Heightfield field, float worldX, float worldZ,
		float radius, bool cut)
	{
		var changed = false;
		let region = HeightfieldSculpt.VisitBrush(field, worldX, worldZ, radius,
			scope [&] (gx, gz, weight) =>
			{
				if (field.IsHole(gx, gz) != cut)
				{
					field.SetHole(gx, gz, cut);
					changed = true;
				}
			});

		if (changed)
			field.BumpVersion();
		return region;
	}

	/// Cuts every sample inside the disc.
	public static HeightfieldRegion Cut(Heightfield field, float worldX, float worldZ,
		float radius) => Mark(field, worldX, worldZ, radius, true);

	/// Fills, which is to say restores, every sample inside the disc.
	public static HeightfieldRegion Fill(Heightfield field, float worldX, float worldZ,
		float radius) => Mark(field, worldX, worldZ, radius, false);
}
