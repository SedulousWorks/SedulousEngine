using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// A contact whose bodies have been resolved back to SCENE ENTITIES.
///
/// A side whose body no longer maps to a live entity arrives as an unassigned handle, which
/// an end event after a body was destroyed produces. Delivered at the physics tick, which is
/// a safe top level rather than something nested inside another call.
struct EntityContact
{
	public ContactKind Kind = .Begin;
	/// BORROWED.
	public Scene Scene = null;
	public EntityHandle A = .();
	public EntityHandle B = .();
	public Float3 Point = .(0, 0, 0);
	public Float3 Normal = .(0, 0, 0);
	public float Speed = 0.0f;

	public this() {}
}
