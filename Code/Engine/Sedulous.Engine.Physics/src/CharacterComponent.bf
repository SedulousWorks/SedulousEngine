using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// A walking capsule: kinematic, with slope, step and stair handling, and it PUSHES the
/// dynamic bodies it meets.
///
/// The entity's POSITION is the capsule's centre and belongs to physics while the scene
/// simulates, interpolated like a dynamic body's. The ROTATION stays the scene's, because
/// which way a character faces is gameplay rather than simulation.
///
/// Gameplay writes the movement velocity and a one shot jump; the tick reads them.
[SerializableComponent("physics.Character")]
struct CharacterComponent : ISerializable
{
	// ---- authored ----

	public float Radius = 0.35f;
	/// The cylinder's half length, so the whole capsule is twice this plus two radii.
	public float HalfHeight = 0.55f;
	public float MaxSlopeDegrees = 50.0f;
	public float Mass = 70.0f;
	/// The push force cap. The backend's own default barely nudges a prop.
	public float MaxStrength = 500.0f;
	public float StepUp = 0.4f;
	public float StepDown = 0.5f;

	// ---- the input gameplay writes ----

	/// World space. The vertical component is ignored while grounded.
	public Float3 MoveVelocity = .(0.0f, 0.0f, 0.0f);
	/// Consumed at the next grounded step.
	public float JumpSpeed = 0.0f;
	public Float3 TeleportTo = .(0.0f, 0.0f, 0.0f);
	/// Consumed as a snap at the next step, then cleared.
	public bool TeleportPending = false;

	// ---- runtime ----

	public CharacterId Character = .();
	/// The effective active state this domain last reconciled against.
	public bool SimActive = false;
	public CharacterGround Ground = .InAir;
	public Float3 PrevPosition = .(0, 0, 0);
	public Float3 CurrPosition = .(0, 0, 0);

	public this() {}

	/// Steers along the ground. The vertical is left to gravity and to the jump.
	public void Move(float velocityX, float velocityZ) mut
	{
		MoveVelocity = .(velocityX, 0.0f, velocityZ);
	}

	public void Jump(float speed) mut
	{
		JumpSpeed = speed;
	}

	/// Requests a hard snap, which is what a respawn is.
	///
	/// The TICK moves the character rather than the caller setting a position: a live
	/// character owns its transform, so a plain move would be overwritten on the next step.
	/// Momentum drops with it, and the request clears once applied.
	public void SetPosition(Float3 position) mut
	{
		TeleportTo = position;
		TeleportPending = true;
	}

	public bool Grounded => Ground == .OnGround;

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "halfHeight", ref HalfHeight);
		SerializeValue(ar, "maxSlopeDegrees", ref MaxSlopeDegrees);
		SerializeValue(ar, "mass", ref Mass);
		SerializeValue(ar, "maxStrength", ref MaxStrength);
		SerializeValue(ar, "stepUp", ref StepUp);
		SerializeValue(ar, "stepDown", ref StepDown);
	}
}
