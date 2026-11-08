using System;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// The rider on the snow.
///
/// A grounded character moves only by its input, so the board drives the whole velocity
/// (CharacterComponent.Drive): each frame, gravity less its part along the ground's normal is added
/// to the velocity the rider has, kept along the ground; snow friction and air drag take some back.
/// The stick turns that velocity (a carve), at a rate, keeping its speed but for what a hard carve
/// scrubs off; a tuck cuts the drag and the turning; a jump pops the rider off the snow. In the air,
/// gravity alone: the stick spins the rider instead of carving, and the grab button holds a grab.
///
/// A landing after real air (MinAir) is judged against the path: the board within LandTolerance of
/// the way the rider is travelling, forward or switch (backward), is clean and gives a burst of
/// speed; anything else is a crash, which takes most of the speed and the control for CrashTime.
/// Each landing is told to the game to score (TrickLanded: its air, spin and grab, and whether it
/// was clean); a crash is RiderCrashed too.
///
/// Riding into something solid at speed (a tree, a rock: what took the speed did not go into the
/// snow) is a crash too. Riding past a trunk close and fast without touching it is a near miss
/// (NearMiss, once per trunk): an overlap in the trees' collision group around the rider.
///
/// A kicker launches the rider itself (Kicker calls Launch): the board takes off along its heading
/// at the speed and angle given. Landing short in a crevasse (Gap) and the avalanche catching the
/// rider (Avalanche) call Crash.
///
/// The rider's animation graph (Tools/graph.py) follows by parameters: Lean (heel -1 to toe +1),
/// Tuck, Airborne, Grab and Crashed. The lean is the turn the board makes, not the stick: as a rider
/// leans into a turn by its speed times how fast it turns (the lean that balances the turn's pull,
/// atan(v w / g)), full at FullLean degrees. Riding straight is upright whatever the stick says, and
/// a tuck, turning half as hard, leans less. The rider stands left foot forward facing the board's
/// right side, so a right turn is on the toe edge.
///
/// With Autopilot, the board steers itself down the course line (playtests, the measurements).
[Behaviour("snowline.board")]
[DisplayName("Board"), Category("Snowline")]
[Description("The rider on the snow: carves, tucks, jumps, spins and grabs, lands clean or crashes, and leaves its track, spray and wind.")]
class Board : Behaviour
{
	/// The longest step the board integrates at once (s).
	private const float cStep = 1.0f / 60.0f;
	private const float cGravity = 9.81f;

	[Description("The course line (an entity with a spline)")]
	public EntityRef Course = .();
	[Description("Steer down the course line on its own (playtests)")]
	public bool Autopilot = false;
	[Description("How far down the course line the autopilot aims (m)")]
	public float LookAhead = 15.0f;
	[Description("The stick the autopilot holds in the air, a spin (playtests: -1 to 1)")]
	public float AutopilotSpin = 0.0f;
	[Description("The autopilot holds a grab in the air (playtests)")]
	public bool AutopilotGrab = false;
	[Description("How far ahead the rider looks with nothing to look at (m)")]
	public float GazeAhead = 12.0f;
	[Description("How quickly the rider's gaze moves to a new target (per second)")]
	public float LookEase = 4.0f;
	[Description("Fastest turn of the velocity, a full carve (degrees a second)")]
	public float CarveRate = 80.0f;
	[Description("Speed a full carve scrubs off (share of gravity's pull into the slope)")]
	public float CarveScrub = 0.35f;
	[Description("Speed at which a carve scrubs in full; slower, in proportion (m/s)")]
	public float ScrubSpeed = 12.0f;
	[Description("Snow friction (share of gravity's pull into the slope)")]
	public float Friction = 0.04f;
	[Description("Air drag (per m/s of speed, per second)")]
	public float Drag = 0.0025f;
	[Description("Air drag in a tuck (share of the standing drag)")]
	public float TuckDrag = 0.45f;
	[Description("Turning in a tuck (share of the full carve)")]
	public float TuckTurn = 0.5f;
	[Description("Upward speed of a jump (m/s)")]
	public float JumpSpeed = 5.5f;
	[Description("Fastest spin in the air, the stick full over (degrees a second)")]
	public float SpinRate = 540.0f;
	[Description("Shortest time in the air that is a trick, judged as it lands (s)")]
	public float MinAir = 0.35f;
	[Description("How far the board may be off the path, forward or switch, for a clean landing (degrees)")]
	public float LandTolerance = 35.0f;
	[Description("A clean landing's burst of speed (m/s)")]
	public float LandBurst = 3.0f;
	[Description("Share of its speed a crash keeps")]
	public float CrashKeep = 0.25f;
	[Description("How long a crash takes the control away (s)")]
	public float CrashTime = 1.2f;
	[Description("Speed lost to something solid in one frame that is a crash (m/s)")]
	public float HitLoss = 5.0f;
	[Description("The physics collision group of the trees and rocks")]
	public int32 TreesGroup = 2;
	[Description("How close a trunk passes for a near miss (m, from the rider's centre to its axis)")]
	public float NearMissReach = 2.2f;
	[Description("Slowest speed a near miss counts at (m/s)")]
	public float NearMissSpeed = 9.0f;
	[Description("The board's mark in the snow (Prefabs/TrackMark)")]
	public Ref<PrefabDocument> TrackMark = .(Guid());
	[Description("Distance between the track's marks (m)")]
	public float TrackSpacing = 1.5f;
	[Description("Slowest speed that leaves a track (m/s)")]
	public float TrackSpeed = 2.0f;
	[Description("Carve (share of a full one) above which the board throws spray")]
	public float SprayCarve = 0.45f;
	[Description("Slowest speed that throws spray (m/s)")]
	public float SpraySpeed = 6.0f;
	[Description("Speed at which the wind is at its loudest (m/s)")]
	public float WindSpeed = 25.0f;
	[Description("The wind's loudest volume")]
	public float WindVolume = 0.7f;
	[Description("The lean into a turn that is the full carve pose (degrees)")]
	public float FullLean = 40.0f;

	/// The entity Course names in this scene, found as it starts.
	private EntityHandle mCourse = .Invalid;
	private Float3 mStart = .(0.0f, 0.0f, 0.0f);
	private Quaternion mStartRotation = .Identity;
	/// Radians; 0 faces +Z.
	private float mYaw = 0.0f;
	/// The eased lean into the turn, -1 heel .. +1 toe.
	private float mLean = 0.0f;
	/// The travel's heading last frame (radians), for the turn rate.
	private float mLastHeading = 0.0f;
	private bool mHeadingKnown = false;
	/// Where the head looks (eased).
	private Float3 mLookAt = .(0.0f, 0.0f, 0.0f);
	private bool mLookKnown = false;
	private bool mAirborne = false;
	/// The skinned mesh the graph drives.
	private EntityHandle mFigure = .Invalid;
	/// Metres ridden since the last mark of the track.
	private float mSinceMark = 0.0f;
	private bool mSpraying = false;
	/// The gate the rider looks at next.
	private int32 mNextGate = 0;
	/// A run begins: the next update starts from rest.
	private bool mFromRest = true;
	/// Off the snow since the last landing.
	private bool mInAir = false;
	/// How long this time in the air has lasted (s).
	private float mAir = 0.0f;
	/// How far the rider has spun in it (radians, signed).
	private float mSpin = 0.0f;
	/// How long it has held a grab in it (s).
	private float mGrabbed = 0.0f;
	/// How long the crash still holds (s).
	private float mCrash = 0.0f;
	/// The velocity the board drove last frame.
	private Float3 mDriven = .(0.0f, 0.0f, 0.0f);
	/// The next kicker launch's angle above level (degrees).
	private float mLaunchAngle = 0.0f;
	/// Its speed (m/s); 0 when none is due.
	private float mLaunchSpeed = 0.0f;
	/// The last trunk passed close (its centre).
	private Float3 mLastTrunk = .(1.0e9f, 0.0f, 0.0f);
	/// A crash told to the board (a short gap, the avalanche), taken next update.
	private bool mCrashDue = false;

	protected override void OnStart()
	{
		Listen<RunRestart>(new [=this] (evt) => Restart());
		// The gate the rider looks at next is the one after the last crossed (passed or missed).
		Listen<GatePassed>(new [=this] (evt) => { mNextGate = evt.Index + 1; });
		Listen<GateMissed>(new [=this] (evt) => { mNextGate = evt.Index + 1; });
		mCourse = Scene.FindEntity(Course.Id);
		let local = Scene.GetLocalTransform(Entity);
		mStart = local.Position;
		mStartRotation = local.Rotation;
		mYaw = Pieces.Yaw(mStartRotation);
		// The run starts with the rider's first frame: the clock (SnowlineGame) and the medal
		// ghosts count from here, so a rider level with a ghost crosses the line on its medal's time.
		Post(RunStarted(Entity));
	}

	/// A kicker's launch (Kicker): `angle` degrees above level at `speed` m/s, taken next update.
	public void Launch(float angle, float speed)
	{
		mLaunchAngle = angle;
		mLaunchSpeed = speed;
	}

	/// Down in the crevasse, short of its far side (Gap), or caught by the avalanche (Avalanche):
	/// a crash, taken next update.
	public void Crash()
	{
		mCrashDue = true;
	}

	protected override void OnUpdate(float dt)
	{
		if (dt <= 0.0f)
			return;
		let c = Get<CharacterComponent>();
		if (c == null)
			return;
		let struck = HitSomething(c);
		var v = AlongTheSnow(c);
		if (mFromRest)
		{
			// Every run starts from rest, and on the frame after it begins: the clock
			// (SnowlineGame) hears RunStarted or restarts on this frame and counts from the next,
			// so the board waits for it. Integrating this frame (the long first one after the
			// scene loads) gave the first run a head start the clock never saw, and a restarted
			// one would carry the last run's speed.
			c.Drive(Float3(0.0f, 0.0f, 0.0f));
			mDriven = .(0.0f, 0.0f, 0.0f);
			mFromRest = false;
			return;
		}
		let at = Scene.GetWorldPosition(Entity);
		let down = Travelled(at);

		// What the rider asks for: the carve (-1 left .. +1 right), a tuck, a jump, a grab.
		float steer = 0.0f;
		bool tuck = false;
		bool jump = false;
		if (Autopilot)
		{
			steer = AutoSteer(v, at, down);
		}
		else
		{
			let input = Pieces.Controls(Run);
			steer = (input != null) ? input.Value2D("Move").X : 0.0f;
			tuck = Pieces.IsDown(Run, "Tuck");
			jump = Pieces.WasPressed(Run, "Jump");
		}
		bool grab = Autopilot ? AutopilotGrab : Pieces.IsDown(Run, "Grab");
		if (mCrash > 0.0f)
		{
			// Down in the snow: no control until the crash is over.
			mCrash -= dt;
			steer = 0.0f;
			tuck = false;
			jump = false;
			grab = false;
		}

		var grounded = c.Grounded;
		if (mLaunchSpeed > 0.0f)
		{
			// Off a kicker's lip: along the heading, up at the lip's angle, and into the air.
			let heading = ((v.X * v.X + v.Z * v.Z) > 0.04f) ? Atan2(v.X, v.Z) : mYaw;
			let up = DegreesToRadians(mLaunchAngle);
			v = .(Sin(heading) * Cos(up) * mLaunchSpeed, Sin(up) * mLaunchSpeed, Cos(heading) * Cos(up) * mLaunchSpeed);
			mLaunchSpeed = 0.0f;
			grounded = false;
			Pieces.Play(Run, Assets.Pop, .Effects, 0.8f);
		}
		else if (jump && grounded && (mCrash <= 0.0f))
		{
			Pieces.Play(Run, Assets.Pop, .Effects, 0.6f, 1.1f);
		}
		if (!grounded)
		{
			// In the air the stick spins the rider (the autopilot holds AutopilotSpin).
			let stick = Autopilot ? AutopilotSpin : steer;
			let spin = ((mCrash > 0.0f) ? 0.0f : stick) * DegreesToRadians(SpinRate) * dt;
			mSpin += spin;
			mYaw += spin;
			mAir += dt;
			if (grab)
				mGrabbed += dt;
			mInAir = true;
		}
		// The frame in steps of at most cStep: a long frame (the first after the scene loads, a
		// hitch) is integrated as the short ones it stands for, so the speed a run gathers does not
		// hang on the frame rate. One long step had given a first run a 0.4 m/s head start.
		let steps = (int)Ceil(dt / cStep);
		let h = dt / (float)steps;
		// A jump pops the rider off the snow in the first step; the rest of the frame is in the
		// air. (Integrated as still on the snow, each later step laid the velocity back along the
		// slope and took the jump away: no jump at all whenever a frame ran longer than cStep.)
		var onSnow = grounded;
		for (int i < steps)
		{
			let popping = jump && (i == 0) && onSnow && (mCrash <= 0.0f);
			v = Integrate(c.GroundNormal, v, onSnow, steer, tuck, popping, h);
			if (popping)
				onSnow = false;
		}
		if (grounded && mInAir)
			v = Land(v, at);
		if (struck)
			Pieces.Play(Run, Assets.TreeHit, .Effects, 0.9f);
		if (struck || (mCrashDue && (mCrash <= 0.0f)))
			v = Crashed(v, at);
		mCrashDue = false;
		NearMissAt(at, v);
		c.Drive(v);
		mDriven = v;
		Face(v, dt, grounded);
		// The character's pointer is transient, and the track's spawn adds entities: `c` is not
		// used past here.
		Track(at, v, grounded, dt);
		Snow(v, steer, grounded);
		Wind(v);
		Animate(grounded ? TurnLean(v, dt) : 0.0f, tuck, !grounded, grab && !grounded, dt);
		Look(at, v, dt);
	}

	/// One step of the board's motion: on the snow (whose normal is `n`), gravity along the slope,
	/// friction, a carve's scrub, drag and the carve's turn (and a jump's pop); in the air, gravity.
	private Float3 Integrate(Float3 n, Float3 velocity, bool grounded, float steer, bool tuck, bool jump, float dt)
	{
		var v = velocity;
		if (!grounded)
			return .(v.X, v.Y - cGravity * dt, v.Z);
		// Keep the velocity along the ground, then add gravity's pull along it.
		let vn = Dot(v, n);
		v = .(v.X - n.X * vn, v.Y - n.Y * vn, v.Z - n.Z * vn);
		let gn = -cGravity * n.Y; // gravity (0, -g, 0) along the normal
		v = .(v.X - n.X * gn * dt, v.Y + (-cGravity - n.Y * gn) * dt, v.Z - n.Z * gn * dt);
		// Friction and a carve's scrub (from the press into the slope) and drag, against the motion.
		let speed = Length(v);
		if (speed > 0.01f)
		{
			// A carve's scrub grows with speed (the turn's sideways push), nothing at a crawl.
			let bite = (speed < ScrubSpeed) ? speed / ScrubSpeed : 1.0f;
			let grip = (Friction + CarveScrub * Abs(steer) * bite) * cGravity * n.Y;
			let resistance = Drag * (tuck ? TuckDrag : 1.0f) * speed * speed;
			let slow = (grip + resistance) * dt;
			let keep = (speed > slow) ? (speed - slow) / speed : 0.0f;
			v = v * keep;
		}
		v = Carve(v, steer * (tuck ? TuckTurn : 1.0f), dt);
		if (jump)
			v = .(v.X, v.Y + JumpSpeed, v.Z);
		return v;
	}

	/// The game starts the next run (the finish card's Jump): back to the top, at rest, facing
	/// down the course as at the start, the first gate next.
	private void Restart()
	{
		if (let c = Get<CharacterComponent>())
			c.SetPosition(mStart);
		Scene.SetLocalRotation(Entity, mStartRotation);
		mYaw = Pieces.Yaw(mStartRotation);
		mFromRest = true;
		mInAir = false;
		mAir = 0.0f;
		mSpin = 0.0f;
		mGrabbed = 0.0f;
		mCrash = 0.0f;
		mCrashDue = false;
		mDriven = .(0.0f, 0.0f, 0.0f);
		mNextGate = 0;
		mLean = 0.0f;
		mHeadingKnown = false;
		mLookKnown = false;
	}

	/// Turns the velocity's ground direction by the carve, keeping its speed. A right turn (steer
	/// > 0) turns the heading toward -X when going +Z: the yaw (atan2(x, z)) falls.
	private Float3 Carve(Float3 v, float steer, float dt)
	{
		let flat = Sqrt(v.X * v.X + v.Z * v.Z);
		if ((flat < 0.2f) || (steer == 0.0f))
			return v;
		let heading = Atan2(v.X, v.Z) - steer * DegreesToRadians(CarveRate) * dt;
		return .(Sin(heading) * flat, v.Y, Cos(heading) * flat);
	}

	/// The autopilot's carve: toward a point down the course line, -1..1.
	private float AutoSteer(Float3 v, Float3 at, float down)
	{
		let splines = Scene.GetSystem<SplineComponentManager>();
		if ((splines == null) || !Scene.IsValid(mCourse))
			return 0.0f;
		let length = splines.Length(mCourse);
		let aim = down + LookAhead;
		let ahead = splines.SampleAtDistance(mCourse, (aim < length) ? aim : length);
		let flat = Sqrt(v.X * v.X + v.Z * v.Z);
		let want = Atan2(ahead.Position.X - at.X, ahead.Position.Z - at.Z);
		let have = (flat > 0.2f) ? Atan2(v.X, v.Z) : want;
		let turn = Pieces.Wrap(want - have);
		// A turn to the left (the yaw rising) is a negative steer; full lock past 35 degrees off.
		return Clamp(-turn / DegreesToRadians(35.0f), -1.0f, 1.0f);
	}

	/// The rider's head looks at the next gate (an aim IK on the board's entity), then the finish,
	/// while it lies ahead; once it is behind (the finish crossed, a gate gone by), down the way the
	/// rider is travelling instead. The point eases from one target to the next, so the head turns
	/// rather than snaps. (Looking at the finish after crossing it, the head swung round to look
	/// back at it.) About eye height above the snow.
	private void Look(Float3 at, Float3 v, float dt)
	{
		let flat = Sqrt(v.X * v.X + v.Z * v.Z);
		let dx = (flat > 0.5f) ? v.X / flat : Sin(mYaw);
		let dz = (flat > 0.5f) ? v.Z / flat : Cos(mYaw);
		var want = Float3(at.X + dx * GazeAhead, at.Y + 0.3f, at.Z + dz * GazeAhead);
		var next = Scene.FindEntityByName(scope $"Gate{mNextGate}");
		if (!Scene.IsValid(next))
			next = Scene.FindEntityByName("Finish");
		if (Scene.IsValid(next))
		{
			let p = Scene.GetWorldPosition(next);
			let tx = p.X - at.X;
			let tz = p.Z - at.Z;
			let dist = Sqrt(tx * tx + tz * tz);
			// Ahead: within about 60 degrees of the travel.
			if ((dist > 1.0f) && ((tx * dx + tz * dz) > 0.5f * dist))
				want = p + Float3(0.0f, 1.2f, 0.0f);
		}
		if (!mLookKnown)
		{
			mLookAt = want;
			mLookKnown = true;
		}
		let ease = Min(LookEase * dt, 1.0f);
		mLookAt = mLookAt + (want - mLookAt) * ease;
		IkScene.SetTarget(Scene, Entity, mLookAt);
	}

	/// How far down the course line the rider is (m): the closest point's distance along it.
	private float Travelled(Float3 at)
	{
		let splines = Scene.GetSystem<SplineComponentManager>();
		if ((splines == null) || !Scene.IsValid(mCourse))
			return 0.0f;
		let here = splines.ClosestPoint(mCourse, at);
		return here.Valid ? here.Distance : 0.0f;
	}

	/// The board's track: a mark every TrackSpacing metres on the snow, under the board, along the
	/// heading. None in the air, nor at a crawl.
	private void Track(Float3 at, Float3 v, bool grounded, float dt)
	{
		let speed = Sqrt(v.X * v.X + v.Z * v.Z);
		if (!grounded || (speed < TrackSpeed) || (TrackMark.Id == Guid()))
		{
			mSinceMark = TrackSpacing; // the first mark on touching down lands at once
			return;
		}
		mSinceMark += speed * dt;
		if (mSinceMark < TrackSpacing)
			return;
		mSinceMark = 0.0f;
		// The character's position is its capsule's centre; the board is 0.9 m below it.
		Pieces.Spawn(Scene, TrackMark.Id, .(at.X, at.Y - 0.9f, at.Z), FromYawPitchRoll(Atan2(v.X, v.Z), 0.0f, 0.0f));
	}

	/// The board's snow: spray off its edge while it carves hard and fast (the Spray child, played
	/// and stopped only on a change), and a burst of powder as it lands (the Powder child).
	private void Snow(Float3 v, float steer, bool grounded)
	{
		let particles = Scene.GetSystem<ParticleEffectComponentManager>();
		let speed = Sqrt(v.X * v.X + v.Z * v.Z);
		let spraying = grounded && (Abs(steer) > SprayCarve) && (speed > SpraySpeed);
		if (spraying != mSpraying)
		{
			let spray = Scene.FindChildByName(Entity, "Spray");
			if (Scene.IsValid(spray) && (particles != null))
			{
				if (spraying)
					particles.Play(spray);
				else
					particles.Stop(spray);
			}
			mSpraying = spraying;
		}
		if (grounded && mAirborne)
		{
			let powder = Scene.FindChildByName(Entity, "Powder");
			if (Scene.IsValid(powder) && (particles != null))
				particles.Restart(powder);
		}
	}

	/// The wind in the rider's ears: silent standing, rising with the speed to its loudest at
	/// WindSpeed, and a little higher in pitch the faster it blows.
	private void Wind(Float3 v)
	{
		let source = Scene.FindChildByName(Entity, "Wind");
		let audio = Scene.GetSystem<AudioSceneSystem>();
		if (!Scene.IsValid(source) || (audio == null))
			return;
		let k = Min(Length(v) / WindSpeed, 1.0f);
		audio.SetVolume(source, WindVolume * k * k, 0.15f);
		audio.SetPitch(source, 0.8f + 0.5f * k, 0.15f);
	}

	/// The velocity to carry on from. The character's own step takes away whatever went into a
	/// surface; the snow under the board only turns it, though (its push is square to the motion
	/// along it). So when what was lost since the last drive went into the ground:
	/// - riding (or after a hop too short to be a trick, as over a kicker's curve), the board turns
	///   its own velocity along the snow and keeps its speed: the lost part had taken a rider from
	///   17 to 7 m/s up a kicker;
	/// - landing from real air, it keeps what lies along the snow and loses what went into it.
	/// Speed lost to anything else (a rock, a tree) stays lost.
	private Float3 AlongTheSnow(CharacterComponent* c)
	{
		let v = c.Velocity;
		if (!c.Grounded)
			return v;
		let n = c.GroundNormal;
		let lost = mDriven - v;
		let lostLength = Length(lost);
		if ((lostLength < 0.05f) || (Abs(Dot(lost, n)) < 0.8f * lostLength))
			return v;
		let into = Dot(mDriven, n);
		let along = mDriven - n * into;
		let alongLength = Length(along);
		if (alongLength < 0.01f)
			return v;
		if (mInAir && (mAir >= MinAir))
			return along; // a landing
		return along * (Length(mDriven) / alongLength);
	}

	/// Judges a landing at `at`: the board along the path (forward or switch) is clean, a burst of
	/// speed along it; across it is a crash. Short hops (under MinAir) are neither. The trick is
	/// told to the game to score. Returns the velocity the rider rides on with.
	private Float3 Land(Float3 v, Float3 at)
	{
		mInAir = false;
		let air = mAir;
		let spun = mSpin;
		let grabbed = mGrabbed;
		mAir = 0.0f;
		mSpin = 0.0f;
		mGrabbed = 0.0f;
		let flat = Sqrt(v.X * v.X + v.Z * v.Z);
		if ((air < MinAir) || (flat < 1.0f))
			return v;
		var off = Pieces.Wrap(mYaw - Atan2(v.X, v.Z));
		if (Abs(off) > Pi * 0.5f)
			off = Pieces.Wrap(off - Pi); // landing switch: judged against riding backward
		let clean = Abs(off) <= DegreesToRadians(LandTolerance);
		let halfTurns = (int32)(Abs(spun) / Pi + 0.5f);
		Post(TrickLanded(air, halfTurns * 180, grabbed, clean));
		if (clean)
		{
			Pieces.Play(Run, Assets.Land, .Effects, 0.9f);
			let k = (flat + LandBurst) / flat;
			return .(v.X * k, v.Y, v.Z * k);
		}
		return Crashed(v, at);
	}

	/// Down at `at`: most of the speed gone, the control for CrashTime.
	private Float3 Crashed(Float3 v, Float3 at)
	{
		Pieces.Play(Run, Assets.Crash, .Effects, 1.0f);
		mCrash = CrashTime;
		Post(RiderCrashed(at));
		return .(v.X * CrashKeep, v.Y, v.Z * CrashKeep);
	}

	/// Whether the character's step took a lot of speed into something that is not the snow: a
	/// tree, a rock. (Speed the snow takes goes along its normal, and AlongTheSnow gives it back.)
	private bool HitSomething(CharacterComponent* c)
	{
		if (mCrash > 0.0f)
			return false;
		let v = c.Velocity;
		let driven = Sqrt(mDriven.X * mDriven.X + mDriven.Z * mDriven.Z);
		let now = Sqrt(v.X * v.X + v.Z * v.Z);
		if (driven - now < HitLoss)
			return false;
		let lost = mDriven - v;
		let lostLength = Length(lost);
		if (c.Grounded && (Abs(Dot(lost, c.GroundNormal)) >= 0.8f * lostLength))
			return false; // into the snow, not into something on it
		// Thrown upward by what it met: a slope under it, not an obstacle. A hop on a kicker's
		// curve came back down onto the steeper ramp still counted as in the air, and the ramp
		// turning it upward (20 m/s ahead to 14 ahead and 11 up) read as a crash into something.
		// A tree or a rock takes the speed back along the travel and pushes nothing up.
		if (v.Y - mDriven.Y > 0.5f * lostLength)
			return false;
		return true;
	}

	/// A trunk passing within reach at speed, not touched: a near miss, once for each trunk.
	private void NearMissAt(Float3 at, Float3 v)
	{
		if ((mCrash > 0.0f) || ((v.X * v.X + v.Z * v.Z) < NearMissSpeed * NearMissSpeed))
			return;
		let physics = Scene.GetSystem<PhysicsSceneSystem>();
		if (physics == null)
			return;
		let trunk = physics.NearestOverlap(at, NearMissReach, (uint32)1 << (int)TreesGroup);
		if (!trunk.Hit)
			return;
		let p = trunk.Position;
		let dx = p.X - mLastTrunk.X;
		let dz = p.Z - mLastTrunk.Z;
		if ((dx * dx + dz * dz) < 0.25f)
			return; // this one again
		mLastTrunk = p;
		Post(NearMiss(p));
	}

	/// On the snow the rider turns to its travel (easing); in the air it holds the facing it spun to.
	private void Face(Float3 v, float dt, bool grounded)
	{
		if (grounded && ((v.X * v.X + v.Z * v.Z) >= 0.04f))
		{
			let turn = Pieces.Wrap(Atan2(v.X, v.Z) - mYaw);
			mYaw += turn * Min(8.0f * dt, 1.0f);
		}
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(mYaw, 0.0f, 0.0f));
	}

	/// How far the rider leans into the turn the board is making, -1 (heel) .. +1 (toe): the angle
	/// that balances the turn, atan(speed x turn rate / g), against FullLean. A right turn (the
	/// heading falling) is on the toe edge.
	private float TurnLean(Float3 v, float dt)
	{
		let speed = Sqrt(v.X * v.X + v.Z * v.Z);
		if (speed < 1.0f)
		{
			mHeadingKnown = false;
			return 0.0f;
		}
		let heading = Atan2(v.X, v.Z);
		let rate = mHeadingKnown ? Pieces.Wrap(heading - mLastHeading) / dt : 0.0f;
		mLastHeading = heading;
		mHeadingKnown = true;
		let angle = RadiansToDegrees(Atan2(speed * Abs(rate), cGravity));
		let lean = Min(angle / FullLean, 1.0f);
		return (rate < 0.0f) ? lean : -lean;
	}

	/// The skinned mesh the graph sits on: the model's root, its rig, the mesh under it. Found on
	/// first use, not at start (the model's instance may not have its children yet then).
	private EntityHandle Figure()
	{
		if (!Scene.IsValid(mFigure))
		{
			// FindChildByName searches the roots for an unassigned parent: each step stops at a miss.
			let model = Scene.FindChildByName(Entity, "RiderModel");
			let rig = Scene.IsValid(model) ? Scene.FindChildByName(model, "RiderRig") : EntityHandle.Invalid;
			mFigure = Scene.IsValid(rig) ? Scene.FindChildByName(rig, "RiderModel") : EntityHandle.Invalid;
		}
		return mFigure;
	}

	/// The graph's parameters: the lean eases toward the carve (a right turn is the toe edge).
	private void Animate(float steer, bool tuck, bool airborne, bool grab, float dt)
	{
		let figure = Figure();
		if (!Scene.IsValid(figure))
			return;
		mLean += (steer - mLean) * Min(6.0f * dt, 1.0f);
		if (let graphs = Scene.GetSystem<AnimationGraphComponentManager>())
		{
			graphs.SetFloat(figure, "Lean", mLean);
			graphs.SetBool(figure, "Tuck", tuck);
			graphs.SetBool(figure, "Airborne", airborne);
			graphs.SetBool(figure, "Grab", grab);
			graphs.SetBool(figure, "Crashed", mCrash > 0.0f);
		}
		mAirborne = airborne;
	}
}
