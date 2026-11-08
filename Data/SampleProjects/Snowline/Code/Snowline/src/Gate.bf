using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// A slalom gate: two poles (each with its flag on a hinge) the rider passes between. When the
/// rider crosses the gate's line down the course it reports GatePassed (between the poles) or
/// GateMissed (round the outside: the game adds the penalty), with the gate's index. Placed by
/// Tools/course.py, which gives each gate its index and the course's heading at it.
///
/// The flags do not collide with the rider (a flag at its hinge's limit would stop it dead; see
/// Tools/gates.py), so the gate swings one the rider brushes past: a push along the rider's motion,
/// once each time the rider comes within reach of it. Each flag springs back to hang straight (its
/// hinge has no spring, and on an upright hinge gravity does not swing it back, so a flag once
/// brushed stayed turned, into the next run): the gate pushes it toward its rest angle, damped.
[Behaviour("snowline.gate")]
[DisplayName("Gate"), Category("Snowline")]
[Description("A slalom gate: reports the rider passing between its poles or round the outside, and swings the flags it brushes.")]
class Gate : Behaviour
{
	[Description("This gate's place down the course (0 = the first)")]
	public int32 Index = 0;
	[Description("Half the gap between the poles (m)")]
	public float HalfWidth = 4.0f;
	[Description("The course's heading at the gate (radians; 0 runs toward +Z)")]
	public float Heading = 0.0f;
	[Description("How far down the course a flag reaches the rider (m)")]
	public float BrushAlong = 0.9f;
	[Description("How far out from its pole a flag reaches (m)")]
	public float BrushOut = 0.8f;
	[Description("How far in from its pole a brush still swings the flag (m)")]
	public float BrushIn = 0.4f;
	[Description("The push for each m/s of the rider's speed (N s)")]
	public float BrushPush = 0.05f;
	[Description("The flags' spring back to rest (N m per radian)")]
	public float FlagSpring = 0.9f;
	[Description("Its damping (N m s per radian)")]
	public float FlagDamping = 0.15f;
	[Description("From a flag's hinge to its centre (m; Tools/gates.py FLAG_REACH)")]
	public float FlagReach = 0.3f;

	private EntityHandle mRider = .Invalid;
	private bool mCrossed = false;
	private bool mSeen = false;
	private float mLastAlong = 0.0f;
	private EntityHandle mFlagLeft = .Invalid;
	private EntityHandle mFlagRight = .Invalid;
	private bool mBrushingLeft = false;
	private bool mBrushingRight = false;
	// Each flag at rest, in its gate's frame: the way its panel points out, and its angle last frame.
	private Float3 mRestLeft = .(0.0f, 0.0f, 0.0f);
	private Float3 mRestRight = .(0.0f, 0.0f, 0.0f);
	private float mAngleLeft = 0.0f;
	private float mAngleRight = 0.0f;

	protected override void OnStart()
	{
		// A new run: the gate waits for the rider again.
		Listen<RunRestart>(new [=this] (evt) =>
			{
				mCrossed = false;
				mSeen = false;
			});
		mRider = Scene.FindEntityByName("Rider");
		Post(GateRegistered(Index));
		let gate = Scene.GetFirstChild(Entity); // the GateRed or GateBlue prefab's root
		if (Scene.IsValid(gate))
		{
			mFlagLeft = Scene.FindChildByName(gate, "FlagL");
			mFlagRight = Scene.FindChildByName(gate, "FlagR");
			mRestLeft = Outward(mFlagLeft);
			mRestRight = Outward(mFlagRight);
		}
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mRider))
			return;
		// The rider in the gate's frame: along the course, and across it (+ toward the right pole).
		let offset = Scene.GetWorldPosition(mRider) - Scene.GetWorldPosition(Entity);
		let along = Pieces.Along(offset, Heading);
		let across = Pieces.Across(offset, Heading);
		mBrushingLeft = Brush(mFlagLeft, mBrushingLeft, along, -across);
		mBrushingRight = Brush(mFlagRight, mBrushingRight, along, across);
		if (dt > 0.0f)
		{
			mAngleLeft = SpringBack(mFlagLeft, mRestLeft, mAngleLeft, dt);
			mAngleRight = SpringBack(mFlagRight, mRestRight, mAngleRight, dt);
		}
		if (mCrossed)
			return;
		if (mSeen && (mLastAlong < 0.0f) && (along >= 0.0f))
		{
			mCrossed = true;
			if ((across >= -HalfWidth) && (across <= HalfWidth))
				Post(GatePassed(Index));
			else
				Post(GateMissed(Index));
		}
		mLastAlong = along;
		mSeen = true;
	}

	/// Swings `flag` as the rider comes within its reach (`outward`: the rider's distance across
	/// the gate toward the flag's side): once per pass, along the rider's motion. Whether in reach.
	private bool Brush(EntityHandle flag, bool wasInReach, float along, float outward)
	{
		let fromPole = outward - HalfWidth;
		let inReach = (along > -BrushAlong) && (along < BrushAlong) && (fromPole > -BrushIn) && (fromPole < BrushOut);
		if (inReach && !wasInReach && Scene.IsValid(flag))
		{
			let rider = Scene.GetComponent<CharacterComponent>(mRider);
			let physics = Scene.GetSystem<PhysicsSceneSystem>();
			if ((rider != null) && (physics != null))
			{
				let v = rider.Velocity;
				physics.ApplyImpulse(flag, .(v.X * BrushPush, 0.0f, v.Z * BrushPush));
			}
		}
		return inReach;
	}

	/// The way a flag's panel points out from its hinge, flat, in its gate's frame (its local +X).
	private Float3 Outward(EntityHandle flag)
	{
		if (!Scene.IsValid(flag))
			return .(1.0f, 0.0f, 0.0f);
		let o = RotateVector(Scene.GetLocalTransform(flag).Rotation, .(1.0f, 0.0f, 0.0f));
		let flat = Sqrt(o.X * o.X + o.Z * o.Z);
		return (flat > 0.001f) ? Float3(o.X / flat, 0.0f, o.Z / flat) : Float3(1.0f, 0.0f, 0.0f);
	}

	/// Pushes a flag back toward its rest angle about its upright hinge, as a damped spring: a push at
	/// its centre along its swing, of (spring x angle + damping x its turn rate) over its reach.
	/// Returns the angle now (for the next frame's turn rate).
	private float SpringBack(EntityHandle flag, Float3 rest, float lastAngle, float dt)
	{
		if (!Scene.IsValid(flag))
			return 0.0f;
		let now = Outward(flag);
		// The angle from rest about up (+ turns +X toward -Z, as a turn about +Y does).
		let angle = Atan2(rest.Z * now.X - rest.X * now.Z, rest.X * now.X + rest.Z * now.Z);
		let rate = (angle - lastAngle) / dt;
		let torque = -(FlagSpring * angle + FlagDamping * rate);
		// Along the swing: up x outward, the way the angle grows; into the world by the gate's turn.
		let swing = RotateVector(Scene.GetLocalTransform(Entity).Rotation, Float3(-now.Z, 0.0f, now.X) * -1.0f);
		let push = torque * dt / FlagReach;
		if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
			physics.ApplyImpulse(flag, .(swing.X * push, 0.0f, swing.Z * push));
		return angle;
	}
}
