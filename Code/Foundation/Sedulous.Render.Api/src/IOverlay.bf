namespace Sedulous.Render;

/// What both overlay tiers have in common: where they sit in the draw order.
///
/// Separate from the two tiers so ONE registry serves both, which is what keeps the ordering
/// rule in a single place rather than in two copies that can drift.
interface IOverlay
{
	/// Lower draws first, so a higher order is nearer the front.
	int32 OverlayOrder => 0;
}
