using Sedulous.Core;

namespace Sedulous.Physics;

/// One contact, buffered during a step and drained after it.
struct ContactEvent
{
	public ContactKind Kind = .Begin;
	public BodyId BodyA = .();
	public BodyId BodyB = .();
	public uint64 UserA = 0;
	public uint64 UserB = 0;

	/// The contact geometry, which only a Begin or a TriggerEnter carries: an End has no
	/// manifold to read it from. Both are world space, and the normal points from B toward A.
	public Float3 Point = .(0, 0, 0);
	public Float3 Normal = .(0, 0, 0);

	/// The impact's APPROACH SPEED: the magnitude of the two bodies' relative velocity along
	/// the contact normal, which is how hard they met.
	///
	/// Deliberately NOT a solver impulse. Jolt does not surface the true impulse cleanly as a
	/// contact is added, so approach speed is the honest measure rather than a guess dressed
	/// up as one.
	public float Speed = 0.0f;

	public this() {}
}
