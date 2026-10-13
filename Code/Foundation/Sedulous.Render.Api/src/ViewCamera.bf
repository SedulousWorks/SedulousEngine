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

	/// What the projection says about itself, so no builder has to repeat it beside the matrix
	/// (and none can disagree with it): its kind, its planes, and an orthographic view's height in
	/// world units. FarZ above is the depth key's normaliser, set by the camera's builder.
	public bool IsOrthographic => Projection.IsOrthographic;
	public float NearPlane => Projection.ProjectionNearPlane;
	public float FarPlane => Projection.ProjectionFarPlane;
	public float OrthoHeight => (IsOrthographic && (Projection.M[1][1] != 0.0f)) ? (2.0f / Projection.M[1][1]) : 0.0f;

	/// Row vector, so the view applies FIRST.
	public Float4x4 ViewProjection => View * Projection;
}
