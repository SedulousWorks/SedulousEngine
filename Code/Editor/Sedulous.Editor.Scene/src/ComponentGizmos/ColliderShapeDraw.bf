using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Heightfield;

namespace Sedulous.Editor.Scene;

/// A collider's shape parameters, gathered from whichever component carries them.
struct ColliderShapeDraw
{
	public ShapeKind Shape = .Box;
	public Float3 HalfExtents = .(0.5f, 0.5f, 0.5f);
	public float Radius = 0.5f;
	public float HalfHeight = 0.5f;
	public float PlaneHalfExtent = 1000.0f;
	public CollisionShape Cooked = null;
	public Heightfield Heightfield = null;

	public this() {}
}
