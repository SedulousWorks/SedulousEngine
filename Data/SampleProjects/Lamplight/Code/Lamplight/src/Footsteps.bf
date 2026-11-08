using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Physics.Resource;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// What a floor is made of, for the sound of a step on it.
enum Surface : uint8
{
	/// Boards, and anything not named below.
	case Wood = 0;
	case Stone = 1;
	case Gravel = 2;
	case Grass = 3;
}

/// The thief's steps: one each stride (the clips' strides, blender/thief.py), the sound of what the
/// foot lands on (the physical material under it, PhysicsHit.Material) and a Noise for whoever
/// listens (the guards): where it was and how loud, 0 to 1. Sneaking is silent; a run is louder
/// than a walk, and gravel louder than boards, grass softer.
[Behaviour("lamplight.footsteps")]
[DisplayName("Footsteps"), Category("Lamplight")]
[Description("The thief's steps: a sound per stride by the surface underfoot, and a noise the guards hear.")]
class Footsteps : Behaviour
{
	[Description("Boards (Surfaces/Wood)")]
	public Ref<PhysicalMaterial> Wood = .(Guid());
	[Description("Flags (Surfaces/Stone)")]
	public Ref<PhysicalMaterial> Stone = .(Guid());
	[Description("Surfaces/Gravel")]
	public Ref<PhysicalMaterial> Gravel = .(Guid());
	[Description("Surfaces/Grass")]
	public Ref<PhysicalMaterial> Grass = .(Guid());
	[Description("Metres a step, sneaking")]
	public float SneakStride = 0.6f;
	[Description("Metres a step, walking")]
	public float WalkStride = 0.8f;
	[Description("Metres a step, running")]
	public float RunStride = 1.35f;
	[Description("Faster than this (m/s) is a run")]
	public float RunSpeed = 3.0f;
	[Description("How loud a walking step is (0..1, on boards)")]
	public float WalkNoise = 0.4f;
	[Description("How loud a running step is (0..1, on boards)")]
	public float RunNoise = 1.0f;
	[Description("From the thief's centre down to the floor (m)")]
	public float FootDrop = 0.9f;

	/// Metres walked since the last step.
	private float mTravel = 0.0f;
	/// The last step's take, 1 to 3, each step the next.
	private int32 mTake = 0;
	/// The last step's surface, how many steps, and how many whose sound started: what a playtest
	/// reads.
	private Surface mSurface = .Wood;
	private int32 mSteps = 0;
	private int32 mHeard = 0;

	protected override void OnUpdate(float dt)
	{
		let body = Get<CharacterComponent>();
		if (body == null)
			return;
		let v = body.Velocity;
		let speed = Sqrt(v.X * v.X + v.Z * v.Z);
		if (speed < 0.2f)
		{
			mTravel = 0.0f; // stood still: the next step is a whole stride away
			return;
		}
		let sneaking = Pieces.IsDown(Run, "Sneak");
		let running = !sneaking && (speed > RunSpeed);
		let stride = sneaking ? SneakStride : (running ? RunStride : WalkStride);
		mTravel += speed * dt;
		if (mTravel < stride)
			return;
		mTravel -= stride;
		if (!sneaking)
			Step(running ? RunNoise : WalkNoise);
	}

	/// A step: what is underfoot, its sound at the foot, and the noise it makes.
	private void Step(float noise)
	{
		let physics = Scene.GetSystem<PhysicsSceneSystem>();
		if (physics == null)
			return;
		let at = Scene.GetWorldPosition(Entity);
		let hit = physics.RayCast(at, .(0.0f, -1.0f, 0.0f), FootDrop + 0.3f);
		if (!hit.Hit)
			return; // in the air
		let under = hit.Material;
		var surface = Surface.Wood;
		var loudness = 1.0f;
		if ((Stone.Id != Guid()) && (under == Stone.Id))
		{
			surface = .Stone;
			loudness = 0.9f;
		}
		else if ((Gravel.Id != Guid()) && (under == Gravel.Id))
		{
			surface = .Gravel;
			loudness = 1.4f;
		}
		else if ((Grass.Id != Guid()) && (under == Grass.Id))
		{
			surface = .Grass;
			loudness = 0.4f;
		}
		mTake = mTake % 3 + 1;
		mSurface = surface;
		mSteps++;
		let foot = hit.Position;
		if (Pieces.PlayAt(Run, Assets.Step(surface, mTake), foot))
			mHeard++;
		Post(Noise(foot, Min(noise * loudness, 1.0f)));
	}
}
