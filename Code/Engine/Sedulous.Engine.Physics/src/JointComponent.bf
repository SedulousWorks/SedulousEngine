using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// A joint on THIS entity's body.
///
/// How the other end resolves: an explicit entity when one is named, otherwise the nearest
/// ANCESTOR carrying a body, and the WORLD when there is no such ancestor. The hierarchy is
/// the fallback rather than a stored id because a prefab's ids are remapped per instance,
/// which would leave every copy pointing at the template.
[SerializableComponent("physics.Joint")]
[DisplayName("Joint")]
[Category("Physics")]
[Scriptable]
struct JointComponent : ISerializable
{
	[Scriptable]
	public JointKind Kind = .Fixed;
	/// Empty means the nearest ancestor body, or the world.
	[Scriptable]
	public EntityRef TargetEntity = .();

	/// The pivot, in THIS entity's space.
	[Scriptable]
	public Float3 LocalAnchor = .(0.0f, 0.0f, 0.0f);
	/// The hinge or slider axis, in THIS entity's space.
	[Scriptable]
	public Float3 LocalAxis = .(0.0f, 1.0f, 0.0f);

	/// A minimum above the maximum means UNLIMITED, which is why the defaults look inverted.
	[Scriptable]
	public float LimitMin = 1.0f;
	[Scriptable]
	public float LimitMax = -1.0f;

	/// Negative means the distance the bodies started at.
	[Scriptable]
	public float MinDistance = -1.0f;
	[Scriptable]
	public float MaxDistance = -1.0f;

	[Scriptable]
	public bool MotorEnabled = false;
	/// Radians a second for a hinge, metres a second for a slider.
	[Scriptable]
	public float MotorTargetVelocity = 0.0f;
	/// The torque or force cap.
	[Scriptable]
	public float MotorLimit = 1.0e6f;

	// ---- runtime ----

	public JointId Joint = .();
	/// The effective active state this domain last reconciled against.
	public bool SimActive = false;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("kind");
		SerializeEnum(ar, ref Kind);
		SerializeValue(ar, "targetEntity", ref TargetEntity.Id);
		ar.Key("localAnchor");
		Sedulous.Core.Serialization.Serialize(ar, ref LocalAnchor);
		ar.Key("localAxis");
		Sedulous.Core.Serialization.Serialize(ar, ref LocalAxis);
		SerializeValue(ar, "limitMin", ref LimitMin);
		SerializeValue(ar, "limitMax", ref LimitMax);
		SerializeValue(ar, "minDistance", ref MinDistance);
		SerializeValue(ar, "maxDistance", ref MaxDistance);
		SerializeValue(ar, "motorEnabled", ref MotorEnabled);
		SerializeValue(ar, "motorTargetVelocity", ref MotorTargetVelocity);
		SerializeValue(ar, "motorLimit", ref MotorLimit);
	}
}
