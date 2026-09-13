namespace Sedulous.Physics.Pipeline;

/// What kind of shape a mesh is cooked into.
enum CollisionCookKind : uint8
{
	/// A simplified hull, which a dynamic body can use.
	ConvexHull = 0,
	/// The exact static geometry, carrying a material slot per face.
	TriangleMesh,
}
