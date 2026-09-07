namespace Sedulous.RHI;

/// Which winding, in the final clip space, counts as the front of a triangle.
///
/// This interacts with the clip space Y direction: a backend that flips Y also flips the
/// apparent winding, which is why NeedsClipSpaceYFlip exists rather than being folded in
/// here.
enum FrontFace : uint32
{
	CCW,
	CW
}
