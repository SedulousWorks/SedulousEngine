namespace Sedulous.Render;

/// The frame's fixed budgets.
///
/// The renderer's rings are sized to these, and the pipeline fills degenerate entries rather
/// than exceeding one: a budget that silently grew would reallocate mid frame.
static class RenderLimits
{
	/// Atlas tiles for local shadows per frame. A spot takes one tile, a point light six.
	public const uint32 MaxLocalShadowTiles = 16;
	/// Local shadow entries across every scene in the frame.
	public const uint32 MaxLocalShadowEntries = 64;
	/// Reflection probes per frame, which bounds both the prefiltered slices and the
	/// metadata buffer.
	public const uint32 MaxReflectionProbes = 16;
}
