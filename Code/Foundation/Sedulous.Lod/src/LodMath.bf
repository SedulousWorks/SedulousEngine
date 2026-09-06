using System;
using Sedulous.Core;

namespace Sedulous.Lod;

/// Level of detail selection maths, shared by every LOD system in the engine.
///
/// Mesh chains and terrain chunk geo-mipmapping both delegate here, so there is exactly
/// one coverage formula, one threshold walk and one hysteresis rule rather than a
/// slightly different version per system.
///
/// Pure functions over Core maths: no RHI and no render types, since a camera arrives as
/// a pair of plain matrices. That is what makes LOD selection testable headless.
///
/// A leaf of its own rather than part of Core, because LOD is a DOMAIN concept and Core
/// must not know about it.
static class LodMath
{
	/// The fraction of the viewport half height that a bounding sphere's radius spans.
	///
	/// projection.M[1][1] scales both projection kinds, being cot(fovY/2) for perspective
	/// and 2/height for orthographic. M[3][3] is what tells them apart: perspective
	/// divides by view space depth, orthographic has no depth term at all.
	///
	/// bias halves the result per unit, following the usual LOD bias semantics, and zero
	/// means none.
	public static float ProjectedSphereCoverage(Float4x4 view, Float4x4 projection,
		Float3 worldCenter, float worldRadius, float bias = 0.0f)
	{
		let proj11 = projection.M[1][1];

		float coverage;
		if (projection.M[3][3] != 0.0f)
		{
			// Orthographic: screen size does not change with distance.
			coverage = worldRadius * proj11;
		}
		else
		{
			let viewCenter = TransformPoint(worldCenter, view);
			// Forward is -z. Clamped away from zero so something at or behind the eye
			// produces a huge finite coverage rather than a division by zero.
			let depth = ((-viewCenter.Z) > 0.001f) ? (-viewCenter.Z) : 0.001f;
			coverage = worldRadius * proj11 / depth;
		}

		if (bias != 0.0f)
			coverage *= Pow(2.0f, -bias);

		return coverage;
	}

	/// The descending threshold walk: level l takes over while coverage is below
	/// thresholds[l]. Index 0 is 1.0 by convention and unused, since level 0 is the
	/// fallback when nothing coarser applies.
	///
	/// A non descending tail STOPS the walk rather than being interpreted: malformed
	/// thresholds select a level that is too fine, which costs performance, instead of one
	/// that is too coarse, which is visible.
	public static uint32 SelectLevelByCoverage(Span<float> thresholds, float coverage)
	{
		uint32 selected = 0;
		for (int level = 1; level < thresholds.Length; level++)
		{
			if (coverage >= thresholds[level])
				break;
			selected = (uint32)level;
		}
		return selected;
	}

	/// Hysteresis: keep the previous level while it is still selectable anywhere inside a
	/// coverage window of plus or minus band.
	///
	/// Without it, something sitting exactly on a threshold flickers between two levels
	/// every frame as its coverage jitters. A level that has fallen outside the window
	/// loses immediately, so a stale one is never pinned.
	public static uint32 ApplyCoverageHysteresis(Span<float> thresholds, float coverage,
		uint32 rawSelection, uint32 last, float band = 0.05f)
	{
		let finest = SelectLevelByCoverage(thresholds, coverage * (1.0f + band));
		let coarsest = SelectLevelByCoverage(thresholds, coverage * (1.0f - band));
		return ((last >= finest) && (last <= coarsest)) ? last : rawSelection;
	}
}
