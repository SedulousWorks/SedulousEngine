using System;
using Sedulous.Core;

namespace Sedulous.Physics;

/// One shape. A body carries one or more, and more than one is a compound.
struct ShapeDesc
{
	/// A height sample with NO surface, which is Jolt's own no collision value: every triangle
	/// touching it is not collidable, and that is the terrain holes rule.
	public const float NoCollisionHeight = 3.402823466e38f;

	public ShapeKind Kind = .Box;

	/// Box.
	public Float3 HalfExtents = .(0.5f, 0.5f, 0.5f);
	/// Sphere and capsule.
	public float Radius = 0.5f;
	/// Capsule: the cylinder's half length, not counting the caps.
	public float HalfHeight = 0.5f;

	/// Where a compound's child sits.
	public Float3 LocalPosition = .(0, 0, 0);
	public Quaternion LocalRotation = Quaternion.Identity;

	/// Cooked: a blob from CookConvexHull or CookTriangleMesh. It is SELF DESCRIBING, so
	/// nothing here says which it is. A hull may be dynamic; a triangle mesh must be static
	/// or kinematic.
	///
	/// BORROWED, and only read while the body is created.
	public Span<uint8> Cooked = default;

	/// The shape's own scale, for cooked geometry authored at unit scale. One is none. A
	/// triangle mesh takes any scale; a hull takes a roughly uniform one.
	public Float3 Scale = .(1, 1, 1);

	/// Plane: dot(normal, p) + distance = 0, with the NEGATIVE half space solid. It is
	/// infinite in principle but only collidable within this much of the shape's origin, so
	/// keep it as tight as the scene allows: it is broad phase cost. Static or kinematic
	/// only.
	public Float3 PlaneNormal = .(0, 1, 0);
	public float PlaneDistance = 0.0f;
	public float PlaneHalfExtent = 1000.0f;

	/// Heightfield: a SQUARE grid of world Y heights, row major, spanning HeightWorldSize
	/// over XZ and centred on the shape's origin.
	///
	/// The sample count is passed through as it is: Jolt pads it to its own block size with
	/// no collision values, and the footprint stays exactly the size asked for. BORROWED,
	/// like the cooked blob. Static or kinematic only.
	public Span<float> HeightSamples = default;
	public uint32 HeightSampleCount = 0;
	public Float2 HeightWorldSize = .(0, 0);

	public this() {}
}
