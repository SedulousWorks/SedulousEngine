namespace Sedulous.Renderer;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Base render data — a flat, scene-independent description of something to render.
/// Produced by component managers during extraction, consumed by render passes.
/// No entity/component/scene types — just data the renderer needs.
struct RenderData
{
	/// World-space position (used for sorting, culling).
	public Vector3 Position;

	/// World-space bounding box (used for frustum culling).
	public BoundingBox Bounds;

	/// Material sort key (hash of material, for grouping draws with same state).
	public uint32 MaterialSortKey;

	/// Explicit sort order (for decals, overlays — lower values first).
	public int32 SortOrder;

	/// Flags.
	public RenderDataFlags Flags;
}

/// Render data flags.
enum RenderDataFlags : uint8
{
	None = 0,
	/// Object is dynamic (transforms may change every frame).
	Dynamic = 1,
	/// Flip triangle winding (mirrored geometry).
	FlipWinding = 2,
	/// Casts shadows.
	CastShadows = 4
}
