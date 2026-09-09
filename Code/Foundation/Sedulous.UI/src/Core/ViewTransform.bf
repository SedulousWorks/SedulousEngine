using Sedulous.Core;

namespace Sedulous.UI;

/// A post layout transform, applied when drawing and hit testing.
///
/// It does NOT affect layout: a rotated or scaled view still occupies the box it measured
/// to, so a spinning icon cannot shove its neighbours around.
///
/// Applied in order: translate to the origin, scale, rotate, translate back, then translate.
struct ViewTransform
{
	/// In pixels.
	public Float2 Translation = Float2.Zero;
	/// In radians.
	public float Rotation = 0.0f;
	public Float2 Scale = .(1.0f, 1.0f);
	/// The pivot for rotation and scale, as a fraction of the view's size: (0,0) is the top
	/// left and (0.5,0.5) the centre.
	public Float2 Origin = .(0.5f, 0.5f);

	public this() {}

	/// Whether this transform has no visual effect. Origin is not consulted, because a pivot
	/// alone moves nothing.
	public bool IsIdentity =>
		(Translation.X == 0.0f) && (Translation.Y == 0.0f) && (Rotation == 0.0f)
		&& (Scale.X == 1.0f) && (Scale.Y == 1.0f);

	public static readonly ViewTransform Identity = .();
}
