using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// What a scene level physics query answers.
///
/// EXPLICIT rather than stored: a query returns one of these and the caller keeps it, so
/// there is no last-hit state on the system to go stale between two queries. Hit is false on
/// a miss, and every other field is then meaningless rather than zero-meaningful.
///
/// It holds the entity handle outright: there is no facade between the query and the
/// caller to need a packed form unpacked on demand.
[Scriptable(.AllPublic)]
struct PhysicsHit
{
	public bool Hit = false;
	/// The entity the struck body belongs to, or Invalid when the body carried none.
	public EntityHandle Entity = .Invalid;
	/// World units to the hit; -1 on a miss.
	public float Distance = -1.0f;
	public Float3 Position = .(0, 0, 0);
	/// Zero for an overlap query, which has no contact surface to report.
	public Float3 Normal = .(0, 0, 0);
	/// The material slot of the struck face on a cooked triangle mesh, 0 otherwise.
	public int32 Surface = 0;
	/// The physical material of the struck body, its rigid body's Material: what it is made
	/// of, for a game deciding how a step on it sounds (the game maps the id to its sounds). Nil
	/// on a miss, for a body without a material, and for one that is not a rigid body.
	public Guid Material = Guid();

	public this() {}
}
