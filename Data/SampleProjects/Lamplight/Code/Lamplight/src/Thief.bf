using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// The player: moves on the floor relative to where the camera looks (up on the stick is away from
/// the camera, whichever quarter it has turned to), at a sneak (crouched), a walk or a run, and
/// turns to face where it goes. The character controller keeps it on the floor and out of the
/// walls; the model's graph (graph.py) follows by Speed and Crouched. Caught (ThiefCaught, from a
/// Guard), it goes back to the last checkpoint. Throw lobs a pebble ahead (Pebble), to draw a guard
/// away.
[Behaviour("lamplight.thief")]
[DisplayName("Thief"), Category("Lamplight")]
[Description("The player: moves relative to the camera at a sneak, a walk or a run, throws pebbles, and goes back to the last checkpoint when caught.")]
class Thief : Behaviour
{
	[Description("The camera whose facing makes forward")]
	public EntityRef Camera = .();
	[Description("Sneaking speed (m/s): crouched, silent")]
	public float SneakSpeed = 1.0f;
	[Description("Walking speed (m/s)")]
	public float WalkSpeed = 1.6f;
	[Description("Running speed (m/s): loud")]
	public float RunSpeed = 4.5f;
	[Description("How fast the body turns toward where it goes")]
	public float TurnRate = 10.0f;
	[Description("The pebble thrown (Prefabs/Pebble)")]
	public Ref<PrefabResource> Pebble = .(Guid());
	[Description("How fast a pebble leaves the hand (m/s)")]
	public float ThrowSpeed = 7.0f;
	[Description("Seconds between throws")]
	public float ThrowEvery = 0.8f;

	/// Radians; 0 faces +Z.
	private float mYaw = 0.0f;
	/// The camera Camera names in this scene, found as it starts.
	private EntityHandle mCamera = .Invalid;
	/// The model's skinned mesh, which carries the graph: Thief (the instance) / ThiefRig / Thief.
	private EntityHandle mFigure = .Invalid;
	/// Where a catch sends the thief back.
	private Float3 mCheckpoint = .(0.0f, 0.0f, 0.0f);
	private float mSinceThrow = 99.0f;

	protected override void OnStart()
	{
		Listen<ThiefCaught>(new [=this] (evt) => Caught());
		Listen<CheckpointReached>(new [=this] (evt) => Reached(evt.At));
		mCamera = Scene.FindEntity(Camera.Id);
		mCheckpoint = Scene.GetWorldPosition(Entity);
	}

	protected override void OnUpdate(float dt)
	{
		let body = Get<CharacterComponent>();
		if (body == null)
			return;
		let crouched = Pieces.IsDown(Run, "Sneak");
		mSinceThrow += dt;
		if (Pieces.WasPressed(Run, "Throw") && (mSinceThrow >= ThrowEvery))
		{
			mSinceThrow = 0.0f;
			ThrowPebble();
		}
		Animate(body, crouched);

		let input = Pieces.Controls(Run);
		var stick = (input != null) ? input.Value2D("Move") : Float2.Zero;
		let amount = Sqrt(stick.X * stick.X + stick.Y * stick.Y);
		if ((amount < 0.05f) || !Scene.IsValid(mCamera))
		{
			body.Move(0.0f, 0.0f);
			return;
		}
		if (amount > 1.0f)
			stick = .(stick.X / amount, stick.Y / amount);
		// The camera's facing along the floor: forward, and right of it.
		let look = RotateVector(Scene.GetWorldRotation(mCamera), .(0.0f, 0.0f, -1.0f));
		let flat = Sqrt(look.X * look.X + look.Z * look.Z);
		if (flat < 0.0001f)
			return;
		let forward = Float3(look.X / flat, 0.0f, look.Z / flat);
		let right = Float3(-forward.Z, 0.0f, forward.X);
		let speed = crouched ? SneakSpeed : (Pieces.IsDown(Run, "Run") ? RunSpeed : WalkSpeed);
		let vx = (forward.X * stick.Y + right.X * stick.X) * speed;
		let vz = (forward.Z * stick.Y + right.Z * stick.X) * speed;
		body.Move(vx, vz);

		// Face where it goes (the model faces +Z), turning the short way round.
		let delta = Pieces.Wrap(Atan2(vx, vz) - mYaw);
		mYaw += delta * Clamp(TurnRate * dt, 0.0f, 1.0f);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
	}

	/// Caught by a guard: back to the last checkpoint.
	private void Caught()
	{
		if (let body = Get<CharacterComponent>())
			body.SetPosition(mCheckpoint);
	}

	/// A checkpoint reached: a catch now sends the thief back here, and the HUD says so.
	private void Reached(Float3 at)
	{
		mCheckpoint = at;
		if (let note = Hud.Find(Run, "hud-note"))
		{
			Hud.SetText(note, "Checkpoint");
			note.Animate("opacity", "0", 2.5f, "ease").From("1").ReleaseRef();
		}
	}

	/// A door's lock being picked at `at` (a Door calls it each frame of the pick): face it and
	/// stand still, the hand on it.
	public void Picking(Float3 at)
	{
		let p = Scene.GetWorldPosition(Entity);
		mYaw = Atan2(at.X - p.X, at.Z - p.Z);
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
	}

	/// A pebble from the hand, ahead and up, the way the thief faces.
	private void ThrowPebble()
	{
		if (Pebble.Id == Guid())
			return;
		let spawner = Scene.GetSystem<PrefabSpawnSystem>();
		if (spawner == null)
			return;
		let p = Scene.GetWorldPosition(Entity);
		let ahead = Float3(Sin(mYaw), 0.0f, Cos(mYaw)); // the model faces +Z
		let stone = spawner.Spawn(Pebble, .(p.X + ahead.X * 0.4f, p.Y + 0.5f, p.Z + ahead.Z * 0.4f));
		if (!Scene.IsValid(stone))
			return;
		// An impulse is the mass times the change in speed: up at about 35 degrees. The pebble's
		// prefab carries a rigid body; one spawned this frame is not built yet, and takes the
		// impulse when it is.
		let rigid = Scene.GetComponent<RigidBodyComponent>(stone);
		var mass = (rigid != null) ? rigid.Mass : 0.0f;
		if (mass <= 0.0f)
			mass = 1.0f;
		let v = ThrowSpeed * mass;
		if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
			physics.ApplyImpulse(stone, .(ahead.X * v * 0.82f, v * 0.57f, ahead.Z * v * 0.82f));
	}

	/// The graph by what the body did: its speed along the floor (so a thief pressed against a wall
	/// stands rather than runs on the spot), and crouched while sneaking.
	private void Animate(CharacterComponent* body, bool crouched)
	{
		if (!Scene.IsValid(mFigure))
			mFigure = Pieces.Figure(Scene, Entity, "Thief", "ThiefRig");
		if (!Scene.IsValid(mFigure))
			return;
		let v = body.Velocity;
		Pieces.SetFloat(Scene, mFigure, "Speed", Sqrt(v.X * v.X + v.Z * v.Z));
		Pieces.SetBool(Scene, mFigure, "Crouched", crouched);
	}
}
