using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// What a ray found on a solid surface, in world space.
struct SceneRayHit
{
	public float Distance = 0.0f;
	public Float3 Position = .(0, 0, 0);
	public Float3 Normal = .(0, 1, 0);

	public this() {}
}

/// A system that can answer a ray against the scene's solid surfaces (physics: its bodies,
/// triggers never). Lets a system that does not depend on the one owning the surfaces ask what
/// is there: foot IK finds the ground under a foot through it.
interface ISceneRayQuery
{
	/// The closest solid hit along unit `direction` from `origin` within `maxDistance`, among
	/// the collision groups in `groupMask` (bit g is group g). False on a miss.
	bool CastRay(Float3 origin, Float3 direction, float maxDistance, uint32 groupMask, out SceneRayHit outHit);
}
