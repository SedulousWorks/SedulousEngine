using System;

namespace Sedulous.Render;

/// What a view should show INSTEAD of its final image, which is the viewport's "show me this
/// texture".
///
/// A named graph resource wins over a semantic mode. The compose appends a blit that
/// overwrites the view's sub rectangle, so gizmos and overlays still draw on top. Ephemeral
/// per render, like the post overrides, and never written back to the scene.
class ViewDebugView
{
	/// A render graph resource name. Empty means the final image.
	public String Resource = new .() ~ delete _;
	/// The shader term to show. The resource above wins if both are set.
	public ViewDebugSemantic Semantic = .Off;

	/// The display remap: the value is rescaled from this range into zero to one.
	public float RangeMin = 0.0f;
	public float RangeMax = 1.0f;

	/// Nought for all three channels, then red, green, blue, alpha and luminance.
	public uint8 Channel = 0;

	/// A depth source displays as a normalised view space distance rather than as the
	/// hyperbolic values a depth buffer actually holds, which are unreadable.
	public bool LinearizeDepth = true;
	public float NearZ = 0.1f;
	public float FarZ = 1000.0f;

	public bool IsOff => Resource.IsEmpty && (Semantic == .Off);
}
