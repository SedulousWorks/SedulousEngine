namespace Sedulous.VG.Renderer;

/// What one Render DID with the commands it was handed: how many dispatched, and how many
/// were SKIPPED because the pipeline the command needed was never built.
///
/// A skip is not a failure but a deliberate refusal: a stale batch's winding fans, or a box
/// shadow's quadrant quads, would both draw as flat colour under a substitute pipeline, so
/// not drawing them is the correct outcome. Counting them is what makes that decision
/// testable without looking at pixels.
struct VGRenderStats
{
	public int32 Drawn = 0;
	public int32 Skipped = 0;

	public this() {}
}
