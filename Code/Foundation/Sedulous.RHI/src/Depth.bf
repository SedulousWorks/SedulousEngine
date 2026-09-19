using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// The engine's depth convention in RHI terms. [Projection] says WHICH way depth runs,
/// reverse-Z with near at 1 and far at 0; this says what that means for a pipeline: which
/// compare function is "nearer", what a depth clear is, and which way a rasterizer bias
/// pushes. Every depth-stencil state, sampler compare and clear in the engine names one
/// of these rather than a literal, so the convention lives in one place (three, with the
/// shader twin Data/Shaders/depth.hlsli).
static class Depth
{
	/// Pass when the fragment is strictly nearer than the stored depth: a depth prepass, an
	/// opaque pass with no prepass.
	public static CompareFunction Nearer => Projection.ReverseZ ? .Greater : .Less;

	/// Pass when the fragment is nearer OR at the stored depth: the forward pass after a
	/// prepass (equal depth is the same surface), transparents and overlays against opaque
	/// depth, the sky at the far plane against a cleared background, and a shadow sampler's
	/// "lit when the receiver is at or nearer than the occluder".
	public static CompareFunction NearerOrEqual => Projection.ReverseZ ? .GreaterEqual : .LessEqual;

	/// Pass when the fragment is strictly farther; the inverse of Nearer, rarely wanted.
	public static CompareFunction Farther => Projection.ReverseZ ? .Less : .Greater;

	/// What a depth attachment clears to: the far plane, so the first fragment anywhere wins.
	public const float ClearValue = Projection.NdcDepthFar;

	/// A rasterizer depth bias pushing a fragment AWAY from the viewer: a shadow caster away
	/// from the light, so the receiver reads as nearer and acne goes. The hardware adds the
	/// bias to the depth value, so under reverse-Z "away" is a smaller value and the sign
	/// flips.
	public static int32 BiasAwayFromViewer(int32 units) => Projection.ReverseZ ? -units : units;
	public static float SlopeBiasAwayFromViewer(float scale) => Projection.ReverseZ ? -scale : scale;
}
