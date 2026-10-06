using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Scene;

/// An upright capsule of static content, in world space: from `Foot` up `Height` (the whole
/// capsule, foot to the top of its cap; the cylinder between the caps is Height - 2 Radius, at
/// least 0), `Radius` round, in physics collision group `Group`. A tree's trunk.
struct StaticCapsule
{
	public Float3 Foot = .(0, 0, 0);
	public float Radius = 0.0f;
	public float Height = 0.0f;
	public uint8 Group = 0;

	public this() {}
}

/// A system whose static content should be solid without an entity per piece (vegetation: a
/// forest's trunks): physics asks it for capsules when it builds its bodies, so neither domain
/// links the other (Raptor's Specs/vegetation-colliders.md).
interface IStaticColliderSource
{
	/// Appends the capsules this system's static content stands on the world as. False when its
	/// content is not ready yet (a resource still resolving): nothing is appended, and physics
	/// asks again later.
	bool CollectStaticCapsules(Scene scene, List<StaticCapsule> outCapsules);
}
