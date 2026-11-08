using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// Chases the rider down the last stretch. On an entity following the course line (a path follow
/// on the Course spline, stopped), with the Avalanche particle effect under it ("Front") and a
/// looping Rumble source ("Rumble"). Placed by Tools/course.py on a course that has one.
///
/// When the rider passes ReleaseAt metres down the line, the snow breaks loose Lead metres behind
/// it (AvalancheReleased) and runs down the line, gathering speed from StartSpeed at Gather m/s
/// each second up to TopSpeed: a rider riding clean stays ahead; one who crashes loses it. The gap
/// is told as it changes (AvalancheGap, whole metres) for the HUD, the rumble grows as it closes,
/// and so does the pad's. Within Reach of the rider it catches it (AvalancheCaught, and the board
/// crashes) and is spent: it rolls on over the rider and past for PassSeconds, then settles.
/// (Coming on again, it caught a crashed rider over and over: low on Ridge the slope is gentle, so
/// a rider down in the snow never gets back the speed to outrun it.) It stops at the finish
/// (RunFinished), and a new run (RunRestart) puts it back to wait.
[Behaviour("snowline.avalanche")]
[DisplayName("Avalanche"), Category("Snowline")]
[Description("Breaks loose behind the rider on the last stretch and chases it down the course line, crashing a rider it catches.")]
class Avalanche : Behaviour
{
	[Description("The course line (an entity with a spline)")]
	public EntityRef Course = .();
	/// Stored as "releaseAt": a field named Release would hide the behaviour's own Release.
	[Description("How far down the line the rider sets it off (m)")]
	public float ReleaseAt = 300.0f;
	[Description("How far behind the rider it breaks loose (m)")]
	public float Lead = 35.0f;
	[Description("Its speed as it breaks loose (m/s)")]
	public float StartSpeed = 15.0f;
	[Description("Its fastest (m/s): a little over a clean, untucked rider's on Ridge's last stretch")]
	public float TopSpeed = 22.5f;
	[Description("How fast it gathers speed (m/s each second)")]
	public float Gather = 3.0f;
	[Description("How close it comes to catch the rider (m)")]
	public float Reach = 4.0f;
	[Description("How long it rolls on past the rider it caught before it settles (s)")]
	public float PassSeconds = 2.5f;
	[Description("The gap at which the rumble is faint (m)")]
	public float HearFrom = 60.0f;
	[Description("The rumble's loudest volume")]
	public float RumbleVolume = 0.9f;

	/// The entity Course names in this scene, found as it starts.
	private EntityHandle mCourse = .Invalid;
	private EntityHandle mRider = .Invalid;
	private bool mReleased = false;
	private bool mFinished = false;
	private float mSpeed = 0.0f;
	private int32 mLastGap = -1;
	private float mPadTimer = 0.0f;
	/// After a catch, how long it rolls on yet (s); -1 before one.
	private float mPassing = -1.0f;

	protected override void OnStart()
	{
		// Over the line: the snow settles behind the rider.
		Listen<RunFinished>(new [=this] (evt) =>
			{
				mFinished = true;
				Quiet();
			});
		// A new run: back to waiting, still and silent.
		Listen<RunRestart>(new [=this] (evt) => Park());
		mCourse = Scene.FindEntity(Course.Id);
		mRider = Scene.FindEntityByName("Rider");
		Park();
	}

	protected override void OnUpdate(float dt)
	{
		let splines = Scene.GetSystem<SplineComponentManager>();
		if (!Scene.IsValid(mRider) || !Scene.IsValid(mCourse) || mFinished || (splines == null))
			return;
		let here = splines.ClosestPoint(mCourse, Scene.GetWorldPosition(mRider));
		if (!here.Valid)
			return;
		let rider = here.Distance;
		let follow = Get<PathFollowComponent>();
		if (follow == null)
			return;
		let audio = Scene.GetSystem<AudioSceneSystem>();
		if (!mReleased)
		{
			if (rider < ReleaseAt)
				return;
			mReleased = true;
			mSpeed = StartSpeed;
			follow.Distance = rider - Lead;
			follow.Playing = true;
			if (let particles = Scene.GetSystem<ParticleEffectComponentManager>())
				particles.Play(Child("Front"));
			let rumble = Child("Rumble");
			if (audio != null)
			{
				audio.SetVolume(rumble, 0.0f, 0.0f);
				audio.Play(rumble);
			}
			Post(AvalancheReleased((int32)Lead));
		}
		if (mPassing >= 0.0f)
		{
			// Spent: over the rider and on, then settled.
			mPassing -= dt;
			if (mPassing < 0.0f)
			{
				mFinished = true;
				Quiet();
			}
			return;
		}
		mSpeed = Min(mSpeed + Gather * dt, TopSpeed);
		follow.Speed = mSpeed;
		let gap = rider - follow.Distance;
		if (gap <= Reach)
		{
			Pieces.BoardOn(Scene, mRider)?.Crash();
			Post(AvalancheCaught(Scene.GetWorldPosition(mRider)));
			Post(AvalancheGap(0));
			Pieces.Rumble(Run, 1.0f, 0.6f, 0.6f);
			mPassing = PassSeconds;
			return;
		}
		let metres = (gap > 0.0f) ? (int32)gap : 0;
		if (metres != mLastGap)
		{
			mLastGap = metres;
			Post(AvalancheGap(metres));
		}
		// Louder and harder on the pad the closer it is: faint at HearFrom, loudest at Reach.
		let near = Clamp(1.0f - (gap - Reach) / (HearFrom - Reach), 0.0f, 1.0f);
		if (audio != null)
			audio.SetVolume(Child("Rumble"), RumbleVolume * (0.25f + 0.75f * near), 0.2f);
		mPadTimer -= dt;
		if ((mPadTimer <= 0.0f) && (near > 0.3f))
		{
			Pieces.Rumble(Run, 0.5f * near, 0.15f * near, 0.25f);
			mPadTimer = 0.2f;
		}
	}

	private void Park()
	{
		mReleased = false;
		mFinished = false;
		mSpeed = 0.0f;
		mLastGap = -1;
		mPassing = -1.0f;
		if (let follow = Get<PathFollowComponent>())
		{
			follow.Speed = 0.0f;
			follow.Distance = 0.0f;
		}
		Quiet();
	}

	private void Quiet()
	{
		if (let follow = Get<PathFollowComponent>())
			follow.Speed = 0.0f;
		let front = Child("Front");
		if (Scene.IsValid(front))
		{
			if (let particles = Scene.GetSystem<ParticleEffectComponentManager>())
				particles.Stop(front);
		}
		let rumble = Child("Rumble");
		if (Scene.IsValid(rumble))
		{
			if (let audio = Scene.GetSystem<AudioSceneSystem>())
				audio.SetVolume(rumble, 0.0f, 1.0f);
		}
	}

	private EntityHandle Child(StringView name) => Scene.FindChildByName(Entity, name);
}
