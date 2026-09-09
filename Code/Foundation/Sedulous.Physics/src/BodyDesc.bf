using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Physics;

/// What one body asks for.
///
/// A class rather than a value, because it OWNS its shape list; every other desc in this
/// module is a plain value.
class BodyDesc
{
	public MotionKind Motion = .Dynamic;
	public PhysicsLayer Layer = .Dynamic;

	/// One or more. More than one is a compound.
	public List<ShapeDesc> Shapes = new .() ~ delete _;

	public Float3 Position = .(0, 0, 0);
	public Quaternion Rotation = Quaternion.Identity;

	/// Kilograms per cubic metre, which is the backend's own convention.
	public float Density = 1000.0f;
	public float Friction = 0.5f;
	public float Restitution = 0.0f;
	public float LinearDamping = 0.05f;
	public float AngularDamping = 0.05f;

	/// A sensor, which forces the Trigger layer.
	public bool IsTrigger = false;

	/// Continuous collision, so a fast small DYNAMIC body stops tunnelling through thin
	/// geometry. Opt in, since it costs an extra cast per fast body per step.
	public bool ContinuousCollision = false;

	/// An explicit mass in kilograms for a DYNAMIC body, which is how a light looking prop
	/// shoves hard. Nought or less derives it from the density; above nought overrides the
	/// scalar mass while the inertia stays density derived.
	public float MassOverride = 0.0f;

	/// The designer collision group, nought to thirty one. A pair collides only when the
	/// world's matrix allows it BOTH ways. The semantic layer rules still apply on top.
	public uint8 Group = 0;

	/// The scene entity's reverse map.
	public uint64 UserData = 0;
}
