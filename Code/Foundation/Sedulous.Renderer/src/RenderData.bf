namespace Sedulous.Renderer;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;

/// Base class for all extracted render data.
///
/// Allocated from RenderContext.FrameAllocator during extraction. Lifetime is one frame —
/// pointers into arena memory become invalid when RenderContext.BeginFrame() is called next.
///
/// Subclasses MUST be trivially destructible: no owned heap data, no user-defined
/// destructors. The FrameAllocator is configured to allow destructors (.Allow mode)
/// but subclasses should avoid them for performance and predictability.
public abstract class RenderData
{
	/// World-space position (used for sorting + distance culling).
	public Vector3 Position;

	/// World-space bounding box (used for frustum culling).
	public BoundingBox Bounds;

	/// Material sort key (hash of material, for grouping draws with same state).
	public uint32 MaterialSortKey;

	/// Explicit sort order (for decals, overlays — lower values first).
	public int32 SortOrder;

	/// Flags.
	public RenderDataFlags Flags;

	/// Precomputed sort key for the category sort pass.
	/// Populated by ExtractedRenderData.SortAndBatch before drawing.
	public uint64 SortKey;
}

/// Render data flags.
public enum RenderDataFlags : uint8
{
	None = 0,
	/// Object is dynamic (transforms may change every frame).
	Dynamic = 1,
	/// Flip triangle winding (mirrored geometry).
	FlipWinding = 2,
	/// Casts shadows.
	CastShadows = 4
}
