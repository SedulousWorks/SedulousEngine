using Sedulous.Core;

namespace Sedulous.Physics;

/// A PRIMITIVE volume to sweep or overlap with.
///
/// Sphere, box and capsule only: cooked, plane and heightfield are body shapes rather than
/// query shapes. Convex, so it needs no mass or density.
struct QueryShape
{
	public ShapeKind Kind = .Sphere;
	/// Sphere and capsule.
	public float Radius = 0.5f;
	/// Box.
	public Float3 HalfExtents = .(0.5f, 0.5f, 0.5f);
	/// Capsule: the cylinder's half length.
	public float HalfHeight = 0.5f;

	public this() {}
}
