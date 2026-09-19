using System;

namespace Sedulous.Core;

/// The depth convention: ONE for every projection the engine builds and every depth it
/// reads. REVERSE-Z: the near plane maps to NDC depth 1, the far plane to 0, a cleared
/// (background) depth is 0, and "nearer" is the LARGER value.
///
/// Everything that would otherwise hard code 0 and 1 or a compare direction names these
/// instead. RHI's Depth maps them to compare functions, the clear value and rasterizer bias
/// signs; Data/Shaders/depth.hlsli is the shader side twin. Keep the three in step. A
/// consumer that reconstructs position through an inverse projection matrix is convention
/// free and needs none of this.
static class Projection
{
	public const bool ReverseZ = true;
	/// What the near plane maps to.
	public const float NdcDepthNear = 1.0f;
	/// What the far plane maps to, and so the clear value.
	public const float NdcDepthFar = 0.0f;

	/// The larger of two NDC depths is the nearer surface.
	[Inline]
	public static bool IsNearer(float depth, float than) => depth > than;

	/// A depth at, or past, the far plane: nothing was drawn there.
	[Inline]
	public static bool IsBackground(float depth) => depth <= NdcDepthFar;

	/// Reverse-Z perspective NDC depth to a positive view space distance, the inverse of
	/// PerspectiveFovRH's z row: d = n f / (ndc (f - n) + n). ndc 1 is n, ndc 0 is f.
	public static float LinearizeDepth(float ndcDepth, float zNear, float zFar)
	{
		let denominator = ndcDepth * (zFar - zNear) + zNear;
		return (denominator > 1.0e-12f) ? (zNear * zFar / denominator) : zFar;
	}

	/// The forward map, for tests and for anything that must place a value at a distance.
	public static float DepthAtDistance(float distance, float zNear, float zFar)
		=> zNear * (zFar - distance) / ((zFar - zNear) * distance);
}
