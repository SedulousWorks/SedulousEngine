namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// Post-layout transform applied during drawing and hit testing. Does not affect layout.
/// Components are applied in order: translate to origin, scale, rotate, translate back, then translate.
public struct ViewTransform
{
	/// Translation offset (pixels).
	public Vector2 Translation;

	/// Rotation angle (radians).
	public float Rotation;

	/// Scale factors. Default (1, 1).
	public Vector2 Scale = .(1, 1);

	/// Transform origin as a fraction of the view's size (0,0 = top-left, 0.5,0.5 = center).
	/// The origin is the pivot point for rotation and scale.
	public Vector2 Origin = .(0.5f, 0.5f);

	/// Returns true if this transform is the identity (no visual effect).
	public bool IsIdentity =>
		Translation.X == 0 && Translation.Y == 0 &&
		Rotation == 0 &&
		Scale.X == 1 && Scale.Y == 1;

	/// Identity transform (no effect).
	public static readonly ViewTransform Identity = .();
}
