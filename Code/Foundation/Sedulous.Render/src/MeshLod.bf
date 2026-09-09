using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Lod;

namespace Sedulous.Render;

/// Choosing a mesh's level of detail for a view.
///
/// Pure maths over the SHARED coverage metric, which the terrain uses too: one formula for
/// everything, so a mesh and a terrain chunk at the same apparent size drop detail together
/// rather than at two different distances.
static class MeshLod
{
	/// A mesh's thresholds, clamped to the levels it actually has: a chain whose coverage
	/// list is longer than its level count would select a level that is not there.
	public static Span<float> MeshThresholds(StaticMesh mesh)
	{
		let count = Min((int)mesh.LodCount, mesh.LodCoverage.Count);
		return .(mesh.LodCoverage.Ptr, count);
	}

	/// The fraction of the viewport's half height this item's bounding sphere spans.
	///
	/// Each unit of bias halves the effective coverage, which is how an item is pushed to
	/// drop detail sooner or held at a finer level than its size alone would give.
	public static float LodCoverageFor(ViewCamera camera, Float3 worldCenter, float worldRadius,
		float lodBias) =>
		LodMath.ProjectedSphereCoverage(camera.View, camera.Projection, worldCenter, worldRadius,
			lodBias);

	/// The level for a coverage. A mesh with no chain is always its only level.
	public static uint32 PickLodLevel(StaticMesh mesh, float coverage)
	{
		if (mesh.LodCount <= 1)
			return 0;
		return LodMath.SelectLevelByCoverage(MeshThresholds(mesh), coverage);
	}

	/// Keeps the LAST level while it is still defensible within a band around the raw pick,
	/// so an item hovering on a threshold does not flicker between two levels every frame.
	public static uint32 ApplyLodHysteresis(StaticMesh mesh, float coverage, uint32 rawSelection,
		uint32 last) =>
		LodMath.ApplyCoverageHysteresis(MeshThresholds(mesh), coverage, rawSelection, last);
}
