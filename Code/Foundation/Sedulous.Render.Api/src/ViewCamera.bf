using Sedulous.Core;

namespace Sedulous.Render;

/// The camera a view is rendered from.
///
/// The view matrix is the INVERSE of the camera entity's world matrix, and the position is
/// kept beside it because depth sorting and culling both want the eye in world space rather
/// than a matrix to invert again.
struct ViewCamera
{
	public Float4x4 View = .Identity();
	public Float4x4 Projection = .Identity();
	public Float3 Position = .(0, 0, 0);
	/// What a depth key is normalised against.
	public float FarZ = 1000.0f;

	public this() {}

	/// Row vector, so the view applies FIRST.
	public Float4x4 ViewProjection => View * Projection;
}
