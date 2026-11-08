using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.Input;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// The player's ride, on the Bike entity (a Character component: a kinematic capsule).
///
/// "Move": Y is throttle and brake, X steers. The bike keeps a heading and a signed speed, turns
/// the heading (harder the faster it goes, and reversed while backing up), drives the character
/// along it, and points the entity the same way.
///
/// "Throw" launches a paper along the aim: the bike's forward, biased toward the nearest delivery
/// zone in front (the soft auto-aim), with an upward arc. The block owns the paper count: each
/// throw is PaperThrown, and the block answers with PapersLeft.
///
/// A crash (Crash, called by an Obstacle) knocks the bike back against the way it was going and
/// leaves the steering and throttle weak for a moment; the block takes the time penalty
/// (BikeCrashed).
///
/// The feel: the bike leans into its turns (harder the faster it goes) and wobbles while it
/// recovers from a crash, which kicks up road dust; a throw and a crash each have their sound,
/// pitched a little at random so repeats do not sound the same, and each kicks the pad (a crash a
/// heavy jolt, a throw a flick). A cleared block bursts confetti over the rider. Near a subscriber,
/// the throw is shown before it is made: a trail of glowing dots along the path a paper would take,
/// drifting forward, and a ring spinning on the porch the throw is pulled toward (the AimDot and
/// TargetRing prefabs, spawned once and moved each frame).
///
/// The kid on his bike is the child KidBike, whose clips play: Ride at the bike's speed (it covers
/// 4.4 m of road a second at speed 1), and a throw with the hand on the side the paper goes.
[Behaviour("paperkid.bike")]
[DisplayName("Bike"), Category("PaperKid")]
[Description("The player's ride: drives the character, throws papers with a soft auto-aim at the nearest porch, and shows the throw before it is made.")]
class Bike : Behaviour
{
	/// The throw's guide dots, and the flight seconds between them.
	private const int32 cAimDots = 14;
	private const float cAimStep = 0.09f;
	/// The road the Ride clip covers at speed 1 (m).
	private const float cRideMetres = 4.4f;

	[Description("Top forward speed (m/s)")]
	public float MaxSpeed = 11.0f;
	[Description("Top reverse speed (m/s)")]
	public float ReverseSpeed = 3.5f;
	[Description("Throttle ramp (m/s^2)")]
	public float Acceleration = 10.0f;
	[Description("Brake ramp (m/s^2)")]
	public float Braking = 22.0f;
	[Description("Roll-down when coasting (m/s^2)")]
	public float CoastDeceleration = 5.0f;
	[Description("Turn rate at full speed (deg/s)")]
	public float TurnSpeedDegrees = 120.0f;
	[Description("Steering authority at a crawl (0..1)")]
	public float MinSteerFraction = 0.3f;

	[Description("Throw speed (m/s)")]
	public float ThrowSpeed = 9.0f;
	[Description("Throw arc (upward share)")]
	public float ThrowArc = 0.55f;
	[Description("Auto-aim strength (0 = straight ahead, 1 = lands on the zone)")]
	public float AutoAim = 0.85f;
	[Description("Auto-aim reach (m)")]
	public float AimRange = 16.0f;
	[Description("The delivery zones' collision group")]
	public int32 ZoneGroup = 2;

	[Description("After a crash, how long the controls stay weak (s)")]
	public float CrashTime = 1.5f;
	[Description("The controls' strength while recovering (0..1)")]
	public float CrashControl = 0.25f;
	[Description("The speed a crash knocks the bike back at (m/s)")]
	public float Knockback = 4.0f;
	[Description("Lean into a turn at full speed (deg)")]
	public float MaxLean = 14.0f;

	/// Radians; 0 faces +Z.
	private float mHeading = 0.0f;
	private float mSpeed = 0.0f;
	/// The block's papers left; -1 until it says.
	private int32 mPapers = -1;
	private float mAimX = 0.0f;
	private float mAimZ = 1.0f;
	private bool mHasTarget = false;
	private Float3 mTarget = .(0.0f, 0.0f, 0.0f);
	/// Seconds of weak controls left after a crash.
	private float mRecovering = 0.0f;
	/// Degrees, eased toward the steering.
	private float mLean = 0.0f;
	/// The throw's guides: its dots and its ring, spawned at the start.
	private List<EntityHandle> mDots = new .() ~ delete _;
	private EntityHandle mRing = .Invalid;
	/// Drives the dots' drift and the ring's spin.
	private float mClock = 0.0f;
	/// The kid on his bike: the model whose clips play.
	private EntityHandle mKid = .Invalid;
	/// Seconds of a throw's clip left to play.
	private float mThrowing = 0.0f;

	/// The run's input; null outside a run.
	private InputFacade Controls => RunServices.Get<InputFacade>(Run);

	protected override void OnStart()
	{
		Listen<PapersLeft>(new [=this] (evt) => { mPapers = evt.Count; });
		Listen<QuotaMet>(new [=this] (evt) => Celebrate());
		mKid = Scene.FindChildByName(Entity, "KidBike");
		if (Scene.IsValid(mKid))
			Feedback.PlayClip(Scene, mKid, Assets.RideClip);
		// Start facing the way the scene placed the bike.
		let forward = RotateVector(Scene.GetLocalTransform(Entity).Rotation, .(0.0f, 0.0f, 1.0f));
		mHeading = Atan2(forward.X, forward.Z);
		// The throw's guides, hidden until there is a throw to show.
		let at = Scene.GetLocalTransform(Entity).Position;
		for (int32 i < cAimDots)
		{
			let dot = Feedback.Spawn(Scene, Assets.AimDot, at);
			if (Scene.IsValid(dot))
			{
				Scene.SetActive(dot, false);
				mDots.Add(dot);
			}
		}
		mRing = Feedback.Spawn(Scene, Assets.TargetRing, at);
		if (Scene.IsValid(mRing))
			Scene.SetActive(mRing, false);
	}

	/// The bike ran into something (an Obstacle): knocked back off it, the controls weak a while.
	/// Nothing while it is still down from the last one.
	public void Crash()
	{
		if (mRecovering > 0.0f)
			return;
		mRecovering = CrashTime;
		// Bounce back against the way the bike was going: off whatever it ran into.
		mSpeed = (mSpeed >= 0.0f) ? -Knockback : Knockback;
		Feedback.Play(Run, Assets.CrashSound, .Effects, 1.0f, Feedback.Range(Random, 0.9f, 1.1f));
		Feedback.Rumble(Run, 0.9f, 0.5f, 0.35f); // the jolt of a crash
		// Road dust off the wheels (the bike's centre is 0.9 above them).
		Feedback.Spawn(Scene, Assets.FxDust, Scene.GetLocalTransform(Entity).Position + Float3(0.0f, -0.8f, 0.0f));
		Post(BikeCrashed(1));
	}

	protected override void OnUpdate(float dt)
	{
		if (dt <= 0.0f)
			return;
		let input = Controls;
		var move = (input != null) ? input.Value2D("Move") : Float2(0.0f, 0.0f);
		if (mRecovering > 0.0f)
		{
			mRecovering -= dt;
			move = .(move.X * CrashControl, move.Y * CrashControl);
		}
		UpdateSpeed(move.Y, dt);
		UpdateHeading(move.X, dt);
		let forward = Facing();
		let character = Get<CharacterComponent>();
		if (character != null)
			character.Move(forward.X * mSpeed, forward.Z * mSpeed);
		// Lean into the turn (a positive roll tips the top toward screen right from behind, the
		// way a right turn leans), eased so it settles rather than snaps; wobble while recovering.
		var authority = Abs(mSpeed) / MaxSpeed;
		if (authority > 1.0f)
			authority = 1.0f;
		let lean = move.X * MaxLean * authority;
		mLean += (lean - mLean) * Clamp(8.0f * dt, 0.0f, 1.0f);
		let wobble = (mRecovering > 0.0f) ? Sin(mRecovering * 24.0f) * 9.0f * (mRecovering / CrashTime) : 0.0f;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mHeading, 0.0f, DegreesToRadians(mLean + wobble)));

		mClock += dt;
		if (mPapers == 0)
		{
			HideGuides();
		}
		else
		{
			ComputeAim();
			PlaceGuides();
			if ((input != null) && input.WasPressed("Throw") && ThrowPaper())
			{
				StartThrowClip();
				Feedback.Play(Run, Assets.ThrowSound, .Effects, 0.8f, Feedback.Range(Random, 0.9f, 1.15f));
				Feedback.Rumble(Run, 0.0f, 0.25f, 0.05f); // the flick of a throw
				Post(PaperThrown(1));
			}
		}
		AnimateKid(dt);
	}

	/// The block is cleared: confetti bursts over the rider, and hangs in the slow motion after.
	private void Celebrate()
	{
		Feedback.Spawn(Scene, Assets.FxConfetti, Scene.GetLocalTransform(Entity).Position + Float3(0.0f, 1.6f, 0.0f));
	}

	/// The kid pedals as fast as the bike goes (and stops pedalling when it stops); a throw plays
	/// at least at walking pace, so it is seen even from a standstill.
	private void AnimateKid(float dt)
	{
		if (!Scene.IsValid(mKid))
			return;
		var pace = Abs(mSpeed) / cRideMetres;
		if (mThrowing > 0.0f)
		{
			if (pace < 1.0f)
				pace = 1.0f;
			mThrowing -= dt * pace;
			if (mThrowing <= 0.0f)
				Feedback.PlayClip(Scene, mKid, Assets.RideClip);
		}
		Feedback.ClipSpeed(Scene, mKid, pace);
	}

	private void StartThrowClip()
	{
		if (!Scene.IsValid(mKid))
			return;
		// Which side of the bike the paper goes: the porch it is aimed at, else the aim. The bike's
		// +X is the kid's left (it turns by mHeading about +Y, which takes +X to (cos, 0, -sin)).
		// Straight ahead, he throws right-handed.
		var toX = mAimX;
		var toZ = mAimZ;
		if (mHasTarget)
		{
			let at = Scene.GetWorldPosition(Entity);
			toX = mTarget.X - at.X;
			toZ = mTarget.Z - at.Z;
		}
		let across = toX * Cos(mHeading) - toZ * Sin(mHeading);
		Feedback.PlayClip(Scene, mKid, (across > 0.05f) ? Assets.ThrowLeftClip : Assets.ThrowRightClip);
		mThrowing = 1.0f;
	}

	private Float3 Facing() => .(Sin(mHeading), 0.0f, Cos(mHeading));

	private void UpdateSpeed(float throttle, float dt)
	{
		if (throttle > 0.0f)
		{
			mSpeed += throttle * ((mSpeed < 0.0f) ? Braking : Acceleration) * dt;
		}
		else if (throttle < 0.0f)
		{
			mSpeed += throttle * ((mSpeed > 0.0f) ? Braking : Acceleration) * dt;
		}
		else if (mSpeed > 0.0f)
		{
			mSpeed -= CoastDeceleration * dt;
			if (mSpeed < 0.0f)
				mSpeed = 0.0f;
		}
		else if (mSpeed < 0.0f)
		{
			mSpeed += CoastDeceleration * dt;
			if (mSpeed > 0.0f)
				mSpeed = 0.0f;
		}
		if (mSpeed > MaxSpeed)
			mSpeed = MaxSpeed;
		if (mSpeed < -ReverseSpeed)
			mSpeed = -ReverseSpeed;
	}

	/// A positive yaw turns +Z toward +X, which is screen left from behind: right steer lowers it.
	private void UpdateHeading(float steer, float dt)
	{
		if ((steer == 0.0f) || (mSpeed == 0.0f))
			return;
		var authority = Abs(mSpeed) / MaxSpeed;
		if (authority > 1.0f)
			authority = 1.0f;
		if (authority < MinSteerFraction)
			authority = MinSteerFraction;
		let direction = (mSpeed >= 0.0f) ? 1.0f : -1.0f;
		mHeading -= steer * direction * DegreesToRadians(TurnSpeedDegrees) * authority * dt;
	}

	/// The delivery zones' collision group as a mask.
	private uint32 ZoneMask => (uint32)1 << (int)ZoneGroup;

	/// The scene's gravity along Y; nought without physics.
	private float GravityY
	{
		get
		{
			let physics = Scene.GetSystem<PhysicsSceneSystem>();
			return (physics != null) ? physics.Gravity.Y : 0.0f;
		}
	}

	/// The throw's horizontal aim: forward, pulled toward the nearest zone in front.
	private void ComputeAim()
	{
		let pos = Scene.GetWorldPosition(Entity);
		let f = Facing();
		var aimX = f.X;
		var aimZ = f.Z;
		mHasTarget = false;
		let zones = scope List<EntityHandle>();
		if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
			physics.OverlapSphere(pos, AimRange, zones, ZoneMask);
		var best = AimRange * AimRange + 1.0f;
		for (let zone in zones)
		{
			let z = Scene.GetWorldPosition(zone);
			let dx = z.X - pos.X;
			let dz = z.Z - pos.Z;
			let dist2 = dx * dx + dz * dz;
			if (dist2 < 0.0001f)
				continue;
			let len = Sqrt(dist2);
			if (((dx / len) * f.X + (dz / len) * f.Z > 0.1f) && (dist2 < best))
			{
				best = dist2;
				aimX = f.X + (dx / len - f.X) * AutoAim;
				aimZ = f.Z + (dz / len - f.Z) * AutoAim;
				mHasTarget = true;
				mTarget = z;
			}
		}
		let l = Sqrt(aimX * aimX + aimZ * aimZ);
		mAimX = aimX / l;
		mAimZ = aimZ / l;
	}

	/// Above the rider's head, so the paper never meets the bike's own capsule on the way out.
	private Float3 LaunchPoint()
	{
		let pos = Scene.GetWorldPosition(Entity);
		let f = Facing();
		return .(pos.X + f.X * 0.6f, pos.Y + 1.6f, pos.Z + f.Z * 0.6f);
	}

	/// The paper's launch velocity: along the aim at the throw speed, plus the bike's own speed.
	/// With a zone locked, the ground part leans (by AutoAim) toward the velocity that lands the
	/// paper on the zone in its flight time: the soft auto-aim corrects the range as well as the
	/// direction, so a throw at a marked porch from a moving bike usually lands.
	private Float3 LaunchVelocity()
	{
		let mag = Sqrt(1.0f + ThrowArc * ThrowArc);
		let carry = Facing() * mSpeed;
		var vx = mAimX / mag * ThrowSpeed + carry.X;
		let vy = ThrowArc / mag * ThrowSpeed;
		var vz = mAimZ / mag * ThrowSpeed + carry.Z;
		let g = -GravityY;
		if (mHasTarget && (g > 0.0f))
		{
			let from = LaunchPoint();
			let drop = from.Y - (mTarget.Y + 0.4f);
			let flight = (vy + Sqrt(vy * vy + 2.0f * g * drop)) / g;
			if (flight > 0.05f)
			{
				vx += ((mTarget.X - from.X) / flight - vx) * AutoAim;
				vz += ((mTarget.Z - from.Z) / flight - vz) * AutoAim;
			}
		}
		return .(vx, vy, vz);
	}

	/// The throw's path, under the scene's gravity: a dot every cAimStep seconds of flight, the
	/// row drifting forward one step each half second and shrinking toward its end, stopped where
	/// the path meets the ground. The ring sits on the zone the throw is pulled toward. Both show
	/// only while a subscriber is in reach, so the road stays clear between houses.
	private void PlaceGuides()
	{
		if (!mHasTarget)
		{
			HideGuides();
			return;
		}
		let p = LaunchPoint();
		let v = LaunchVelocity();
		let g = GravityY;
		let drift = (mClock * 2.0f) - (float)(int32)(mClock * 2.0f);
		var landed = false;
		for (int i < mDots.Count)
		{
			let dot = mDots[i];
			let t = cAimStep * ((float)i + drift + 0.5f);
			let y = p.Y + v.Y * t + 0.5f * g * t * t;
			if (landed || (y < 0.0f))
			{
				landed = true;
				Scene.SetActive(dot, false);
				continue;
			}
			Scene.SetActive(dot, true);
			Scene.SetLocalPosition(dot, .(p.X + v.X * t, y, p.Z + v.Z * t));
			let size = 1.0f - 0.45f * ((float)i / (float)mDots.Count);
			Scene.SetLocalScale(dot, .(size, size, size));
		}
		if (!Scene.IsValid(mRing))
			return;
		Scene.SetActive(mRing, true);
		Scene.SetLocalPosition(mRing, .(mTarget.X, 0.02f, mTarget.Z));
		Scene.SetLocalRotation(mRing, FromYawPitchRoll(DegreesToRadians(mClock * 70.0f), 0.0f, 0.0f));
		let pulse = 1.0f + 0.08f * Sin(mClock * 6.0f);
		Scene.SetLocalScale(mRing, .(pulse, 1.0f, pulse));
	}

	private void HideGuides()
	{
		for (let dot in mDots)
			Scene.SetActive(dot, false);
		Scene.SetActive(mRing, false);
	}

	/// A paper launched from above the rider: false when none could be spawned.
	private bool ThrowPaper()
	{
		let paper = Feedback.Spawn(Scene, Assets.Newspaper, LaunchPoint());
		if (!Scene.IsValid(paper))
			return false;
		// An impulse is mass times the change in speed; the paper's mass is its rigid body's.
		let body = Scene.GetComponent<RigidBodyComponent>(paper);
		var mass = (body != null) ? body.Mass : 0.0f;
		if (mass <= 0.0f)
			mass = 1.0f;
		if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
			physics.ApplyImpulse(paper, LaunchVelocity() * mass);
		return true;
	}
}
