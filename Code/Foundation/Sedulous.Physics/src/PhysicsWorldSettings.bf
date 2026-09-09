using Sedulous.Core;

namespace Sedulous.Physics;

/// How a world is brought up.
class PhysicsWorldSettings
{
	/// The most collision groups a body may be assigned to, which is the width of the
	/// matrix below.
	public const int CollisionGroupCount = 32;

	public Float3 Gravity = .(0.0f, -9.81f, 0.0f);

	public uint32 MaxBodies = 4096;
	public uint32 MaxBodyPairs = 4096;
	public uint32 MaxContactConstraints = 2048;

	/// The group matrix: bit j of entry i says group i collides with group j.
	///
	/// A writer keeps it SYMMETRIC and the filter tests both directions anyway, so a matrix
	/// that disagrees with itself refuses the pair rather than deciding by which body was
	/// asked about first. Everything collides with everything by default.
	public uint32[CollisionGroupCount] GroupCollides = .(
		0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
		0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
		0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
		0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
		0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
		0xFFFFFFFF, 0xFFFFFFFF);

	public void CopyFrom(PhysicsWorldSettings other)
	{
		Gravity = other.Gravity;
		MaxBodies = other.MaxBodies;
		MaxBodyPairs = other.MaxBodyPairs;
		MaxContactConstraints = other.MaxContactConstraints;
		GroupCollides = other.GroupCollides;
	}
}
