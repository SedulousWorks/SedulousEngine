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
[DisplayName("Character")]
[Category("Physics")]
[Scriptable]
struct CharacterComponent : ISerializable
{
	// ---- authored ----

	[Scriptable]
	public float Radius = 0.35f;
	/// The cylinder's half length, so the whole capsule is twice this plus two radii.
	[Scriptable]
	public float HalfHeight = 0.55f;
	[Scriptable]
	public float MaxSlopeDegrees = 50.0f;
	[Scriptable]
	public float Mass = 70.0f;
	/// The push force cap. The backend's own default barely nudges a prop.
	[Scriptable]
	public float MaxStrength = 500.0f;
	[Scriptable]
	public float StepUp = 0.4f;
	[Scriptable]
	public float StepDown = 0.5f;

	// ---- the input gameplay writes ----

	/// World space. The vertical component is ignored while grounded.
	[Hidden]
	public Float3 MoveVelocity = .(0.0f, 0.0f, 0.0f);
	/// Consumed at the next grounded step.
	[Hidden]
	public float JumpSpeed = 0.0f;
	/// Consumed at the next step, grounded or not: the vertical speed it sets.
	[Hidden]
	public float LaunchSpeed = 0.0f;
	[Hidden]
	public bool LaunchPending = false;
	[Hidden]
	public Float3 TeleportTo = .(0.0f, 0.0f, 0.0f);
	/// Consumed as a snap at the next step, then cleared.
	[Hidden]
	public bool TeleportPending = false;
	/// Driven (Drive): the script owns the whole velocity, gravity included, until the next
	/// Move. What a board or a sled needs: momentum along a slope, which the standard recipe (a
	/// grounded character moves only by its input) cannot keep.
	[Hidden]
	public bool Driving = false;
	[Hidden]
	public Float3 DriveVelocity = .(0.0f, 0.0f, 0.0f);

	// ---- runtime ----

	public CharacterId Character = .();
	/// The effective active state this domain last reconciled against.
	[Hidden]
	public bool SimActive = false;
	[Hidden]
	public CharacterGround Ground = .InAir;
	[Hidden]
	public Float3 PrevPosition = .(0, 0, 0);
	[Hidden]
	public Float3 CurrPosition = .(0, 0, 0);
	/// How fast it moved over the last step (m/s): the motion the sweep allowed, not the
	/// velocity asked for, since a wall or a slope bends it and a script integrating momentum
	/// needs what happened.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public Float3 Velocity = .(0, 0, 0);
	/// The ground under it after the last step; straight up in the air.
	[Scriptable]
	[Hidden]
	[ReadOnly]
	public Float3 GroundNormal = .(0, 1, 0);

	public this() {}

	/// Steers along the ground. The vertical is left to gravity and to the jump.
	[Scriptable]
	public void Move(float velocityX, float velocityZ) mut
	{
		MoveVelocity = .(velocityX, 0.0f, velocityZ);
		Driving = false;
	}

	/// The whole velocity for the coming steps, gravity included, replacing the standard recipe
	/// (Move, Jump, Launch) until the next Move. Read Velocity and GroundNormal to integrate it:
	/// gravity along a slope is gravity less its part along the ground normal.
	[Scriptable]
	public void Drive(float x, float y, float z) mut
	{
		DriveVelocity = .(x, y, z);
		Driving = true;
	}

	[Scriptable]
	public void Drive(Float3 velocity) mut => Drive(velocity.X, velocity.Y, velocity.Z);

	[Scriptable]
	public void Jump(float speed) mut
	{
		JumpSpeed = speed;
	}

	/// Sets the vertical speed at the next step, on the ground OR in the air, replacing what
	/// gravity had built up: a bounce off an enemy, a spring pad, a double jump. Negative
	/// slams down. A pending Jump is dropped.
	[Scriptable]
	public void Launch(float speed) mut
	{
		LaunchSpeed = speed;
		LaunchPending = true;
	}

	/// Requests a hard snap, which is what a respawn is.
	///
	/// The TICK moves the character rather than the caller setting a position: a live
	/// character owns its transform, so a plain move would be overwritten on the next step.
	/// Momentum drops with it, and the request clears once applied.
	[Scriptable]
	public void SetPosition(Float3 position) mut
	{
		TeleportTo = position;
		TeleportPending = true;
	}

	[Scriptable]
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
