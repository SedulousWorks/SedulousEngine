using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.Input;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// The player's movement, jump, facing and animation.
///
/// On the Player entity, which carries a Character component (a kinematic capsule: its position
/// is the capsule's centre). The model is the entity's first child, the Character prefab
/// instance, whose root plays the skeletal clips.
///
/// The camera looks down -Z from behind, so the "Move" axis maps straight to the ground plane:
/// W (+Y) walks toward -Z, D (+X) toward +X.
///
/// A fall or a hit is paced so the player can find themselves again: a poof where they went, a
/// moment out of sight while the camera glides back to the safe ground (the player already moved
/// there, facing the way they stood on it), a poof as they reappear, then a moment of blinking in
/// which nothing can hurt. Safe ground is a spot stood still on with ground all round it: near an
/// edge the nearest spot that has it is kept instead, so a respawn never starts half off a ledge.
///
/// The pad rumbles with the game: a heavy jolt for a fall or a hit, a sharp kick off a stomped
/// enemy, a thud for a hard landing, and a happy pulse at the flag.
///
/// It also starts the hero's look over each frame: the coins, updating after it, each offer
/// themselves (OfferLook), and the nearest one in view turns the head.
[Behaviour("skyhopper.player_controller")]
[DisplayName("Player Controller"), Category("Sky Hopper")]
[Description("The player's movement, jump, facing and animation, its respawn on safe ground, and the hero's look at the nearest coin.")]
class PlayerController : Behaviour
{
	/// From the capsule's centre to its feet: half height plus radius.
	private const float cFeet = 0.95f;

	[Description("Top run speed (m/s)")]
	public float MoveSpeed = 7.0f;
	[Description("Ground acceleration (m/s^2)")]
	public float Acceleration = 40.0f;
	[Description("Air acceleration (m/s^2)")]
	public float AirAcceleration = 12.0f;
	[Description("Jump launch speed (m/s)")]
	public float JumpSpeed = 9.5f;
	[Description("Coyote time: a jump still counts this long after leaving a ledge (s)")]
	public float CoyoteTime = 0.12f;
	[Description("Jump buffer: a press this early before landing still jumps (s)")]
	public float JumpBuffer = 0.12f;
	[Description("Turn rate toward the move direction (rad/s)")]
	public float TurnSpeed = 14.0f;
	[Description("Below this height the player falls out and respawns")]
	public float KillHeight = -15.0f;
	[Description("Standing still this long on ground makes it the respawn point (s)")]
	public float SafeGroundTime = 0.4f;
	[Description("Bounce speed off a stomped enemy (m/s)")]
	public float BounceSpeed = 8.0f;
	[Description("Out of sight after a fall or a hit, while the camera glides back (s)")]
	public float RespawnDelay = 0.8f;
	[Description("Blinking after reappearing, when nothing can hurt (s)")]
	public float GraceTime = 1.2f;
	[Description("Safe ground reaches at least this far round the spot on every side (m)")]
	public float SafeMargin = 0.7f;

	private float mVelX = 0.0f;
	private float mVelZ = 0.0f;
	private float mYaw = 0.0f;
	private float mSinceGrounded = 0.0f;
	private float mSinceJumpPressed = 1000.0f;
	/// The clip playing: 0 idle, 1 run, 2 jump; -1 none yet.
	private int32 mAnim = -1;
	private Float3 mSpawn = .(0.0f, 0.0f, 0.0f);
	private EntityHandle mModel = .Invalid;
	private int32 mDeaths = 0;
	/// Seconds left of the grace after a respawn, while a hazard still touching cannot hurt.
	private float mInvulnerable = 0.0f;
	/// How long the player has stood grounded; past a moment, where it stands is safe ground.
	private float mGroundedFor = 0.0f;
	/// Grounded last frame, and how long the current time in the air has lasted.
	private bool mWasGrounded = true;
	private float mAirTime = 0.0f;
	/// The level is won: no more input, the player stands and enjoys it.
	private bool mCelebrating = false;
	/// Seconds left out of sight before reappearing (below 0: not respawning).
	private float mRespawning = -1.0f;
	/// The current still moment has been looked at for safe ground (once per stand).
	private bool mSafeChecked = false;
	/// The facing the player had on the safe ground, which a respawn gives back.
	private float mSpawnYaw = 0.0f;
	private EntityHandle mCamera = .Invalid;
	/// The nearest coin that turned the head this frame, how far it is; started over each frame.
	private float mLookNearest = FloatMax;

	/// The run's input; null outside a run.
	private InputFacade Controls => RunServices.Get<InputFacade>(Run);

	protected override void OnStart()
	{
		mSpawn = Scene.GetWorldPosition(Entity);
		mModel = Scene.GetFirstChild(Entity);
		mCamera = Scene.FindEntityByName("Camera");
		PlayAnim(0);
	}

	protected override void OnUpdate(float dt)
	{
		// The look starts over before the coins update: none in view, and the head eases back.
		mLookNearest = FloatMax;
		let aim = Get<AimIkComponent>();
		if (aim != null)
			aim.Active = false;

		if (dt <= 0.0f)
			return;
		let character = Get<CharacterComponent>();
		if (character == null)
			return;
		let input = Controls;
		if (mInvulnerable > 0.0f)
			mInvulnerable -= dt;
		if (mRespawning >= 0.0f)
		{
			// Out of sight at the safe ground, standing still while the camera arrives.
			character.Move(0.0f, 0.0f);
			mRespawning -= dt;
			if (mRespawning < 0.0f)
			{
				ShowModel(true);
				Spawn(Assets.Poof, Scene.GetWorldPosition(Entity));
			}
			return;
		}
		// The grace after reappearing: a blink, ten times a second.
		ShowModel((mInvulnerable > 0.0f) ? ((int32)(mInvulnerable * 10.0f) % 2 == 0) : true);
		let grounded = character.Grounded;
		// The feet stand on the ground under them only while the hero stands on it: in the air the
		// jump pose holds them at the model's ground, and they would reach for the floor below.
		let feet = Get<FootIkComponent>();
		if (feet != null)
			feet.Active = grounded;
		mSinceGrounded = grounded ? 0.0f : mSinceGrounded + dt;
		// A hard landing kicks up dust; a hop off a step does not.
		if (grounded && !mWasGrounded && (mAirTime > 0.35f))
		{
			Dust();
			Feedback.Rumble(Run, 0.3f, 0.1f, 0.08f); // the thud of landing
		}
		mAirTime = grounded ? 0.0f : mAirTime + dt;
		mWasGrounded = grounded;
		// Safe ground: a spot stood STILL on for a moment becomes the respawn point, so a fall
		// costs one jump, not the level. Still, because walking into a hazard passes over ground
		// that is not safe; standing still inside a hazard's reach hurts at once.
		let still = (mVelX * mVelX + mVelZ * mVelZ) < 0.25f;
		mGroundedFor = (grounded && still) ? mGroundedFor + dt : 0.0f;
		if (mGroundedFor <= 0.0f)
			mSafeChecked = false;
		if ((mGroundedFor > SafeGroundTime) && (mInvulnerable <= 0.0f) && !mSafeChecked)
		{
			mSafeChecked = true;
			if (FindSafeSpot(Scene.GetWorldPosition(Entity), let spot))
			{
				mSpawn = spot + Float3(0.0f, 0.1f, 0.0f);
				mSpawnYaw = mYaw;
			}
		}
		let jumpPressed = (input != null) && input.WasPressed("Jump");
		mSinceJumpPressed = jumpPressed ? 0.0f : mSinceJumpPressed + dt;

		// Steer the horizontal velocity toward the stick, snappier on the ground.
		let move = (mCelebrating || (input == null)) ? Float2(0.0f, 0.0f) : input.Value2D("Move");
		let targetX = move.X * MoveSpeed;
		let targetZ = -move.Y * MoveSpeed;
		let rate = (grounded ? Acceleration : AirAcceleration) * dt;
		mVelX = Approach(mVelX, targetX, rate);
		mVelZ = Approach(mVelZ, targetZ, rate);
		character.Move(mVelX, mVelZ);

		// Jump: buffered, and allowed a moment after walking off a ledge.
		if (!mCelebrating && (mSinceJumpPressed <= JumpBuffer) && (mSinceGrounded <= CoyoteTime))
		{
			character.Jump(JumpSpeed);
			Dust();
			Feedback.Play(Run, Assets.JumpSound, .Effects, 0.8f);
			mSinceJumpPressed = 1000.0f;
			mSinceGrounded = 1000.0f;
		}

		// Face the way we move.
		let speed = Sqrt(mVelX * mVelX + mVelZ * mVelZ);
		if (speed > 0.5f)
		{
			mYaw = TurnToward(mYaw, Atan2(mVelX, mVelZ), TurnSpeed * dt);
			Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitY, mYaw));
		}

		if (!grounded)
			PlayAnim(2);
		else if (speed > 0.5f)
			PlayAnim(1);
		else
			PlayAnim(0);

		// The grace after a respawn also covers the frame or two before the teleport lands, when
		// the player is still below the kill height.
		if ((mInvulnerable <= 0.0f) && (Scene.GetWorldPosition(Entity).Y < KillHeight))
		{
			Feedback.Play(Run, Assets.FallSound);
			Respawn();
		}
	}

	/// Came down on an enemy: bounce off it, in the air as on the ground.
	public void Bounce()
	{
		let character = Get<CharacterComponent>();
		if (character != null)
			character.Launch(BounceSpeed);
		mSinceGrounded = 1000.0f; // the bounce is not a coyote jump
		Feedback.Rumble(Run, 0.25f, 0.6f, 0.12f); // a sharp kick off the enemy
	}

	/// A hazard or an enemy touched the player: the same as a fall, with a jolt of the camera.
	public void Hurt()
	{
		if ((mInvulnerable <= 0.0f) && !mCelebrating)
		{
			Shake(0.35f);
			Feedback.Play(Run, Assets.HurtSound);
			Respawn();
		}
	}

	/// The flag is reached: stop taking input and stand still for the celebration.
	public void Celebrate()
	{
		mCelebrating = true;
		Feedback.Rumble(Run, 0.2f, 0.5f, 0.35f); // a happy pulse
	}

	/// A coin `distance` away, within `reach` of the hero and in view of its head, offers itself
	/// for the look: true when it is the nearest offered this frame, and the head turns to `at`.
	public bool OfferLook(float distance, float reach, Float3 at)
	{
		if ((distance >= reach) || (distance >= mLookNearest))
			return false;
		let aim = Get<AimIkComponent>();
		if (aim == null)
			return false;
		mLookNearest = distance;
		IkScene.SetTarget(Scene, Entity, at);
		aim.Active = true;
		return true;
	}

	/// A fall or a hit: a poof where the player went, then back to the last safe ground with no
	/// momentum, out of sight until the camera is there (OnUpdate brings them back).
	private void Respawn()
	{
		if (mRespawning >= 0.0f)
			return; // already on the way back
		mDeaths += 1;
		mVelX = 0.0f;
		mVelZ = 0.0f;
		Spawn(Assets.Poof, Scene.GetWorldPosition(Entity));
		Feedback.Rumble(Run, 0.8f, 0.5f, 0.3f); // the jolt of a fall or a hit
		let character = Get<CharacterComponent>();
		if (character != null)
			character.SetPosition(mSpawn);
		mYaw = mSpawnYaw;
		Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitY, mYaw));
		ShowModel(false);
		PlayAnim(0);
		mRespawning = RespawnDelay;
		mInvulnerable = RespawnDelay + GraceTime;
		Post(PlayerDied(mDeaths));
	}

	private void ShowModel(bool shown)
	{
		if (Scene.IsValid(mModel) && (Scene.IsActive(mModel) != shown))
			Scene.SetActive(mModel, shown);
	}

	/// The spot nearest `at` (searched on a 0.4 m grid out to 0.8 m) where the ground reaches
	/// SafeMargin past it on all four sides, level with the player's feet: false when there is none.
	private bool FindSafeSpot(Float3 at, out Float3 spot)
	{
		float[5] steps = .(0.0f, -0.4f, 0.4f, -0.8f, 0.8f);
		let feet = at.Y - cFeet;
		var best = 1000.0f;
		var found = false;
		spot = at;
		for (let dx in steps)
		{
			for (let dz in steps)
			{
				let x = at.X + dx;
				let z = at.Z + dz;
				let distance = dx * dx + dz * dz;
				if ((distance < best) && GroundAt(x, z, feet) && GroundAt(x + SafeMargin, z, feet)
					&& GroundAt(x - SafeMargin, z, feet) && GroundAt(x, z + SafeMargin, feet)
					&& GroundAt(x, z - SafeMargin, feet))
				{
					best = distance;
					spot = .(x, at.Y, z);
					found = true;
				}
			}
		}
		return found;
	}

	/// Flat ground under (x, z) level with the player's feet. The islands' tops are flat and their
	/// edges rounded, so a probe on the bevel (a little lower) counts as the edge, not as ground.
	private bool GroundAt(float x, float z, float feet)
	{
		let physics = Scene.GetSystem<PhysicsSceneSystem>();
		if (physics == null)
			return false;
		let hit = physics.RayCast(.(x, feet + 0.6f, z), .(0.0f, -1.0f, 0.0f), 1.2f);
		return hit.Hit && (Abs(hit.Position.Y - feet) < 0.08f);
	}

	private void Dust()
	{
		Spawn(Assets.Dust, Scene.GetWorldPosition(Entity) - Float3(0.0f, cFeet - 0.05f, 0.0f));
	}

	private void Spawn(Guid prefab, Float3 at) => Feedback.Spawn(Scene, prefab, at);

	private void Shake(float strength)
	{
		if (!Scene.IsValid(mCamera))
			return;
		let camera = Scene.GetSystem<BehaviourManager<FollowCamera>>()?.Get(mCamera);
		if ((camera != null) && camera.IsActive)
			camera.Shake(strength);
	}

	private void PlayAnim(int32 which)
	{
		if ((which == mAnim) || !Scene.IsValid(mModel))
			return;
		mAnim = which;
		let clip = (which == 1) ? Assets.RunClip : ((which == 2) ? Assets.JumpClip : Assets.IdleClip);
		if (let animation = Scene.GetSystem<SkeletalAnimationComponentManager>())
		{
			animation.SetClip(mModel, clip);
			animation.Play(mModel);
		}
	}

	private static float Approach(float value, float target, float step)
	{
		if (value < target)
			return (value + step > target) ? target : value + step;
		return (value - step < target) ? target : value - step;
	}

	/// Turns an angle toward another the short way round, by at most `step`.
	private static float TurnToward(float from, float to, float step)
	{
		var delta = to - from;
		while (delta > Pi)
			delta -= TwoPi;
		while (delta < -Pi)
			delta += TwoPi;
		if (Abs(delta) <= step)
			return to;
		return from + ((delta > 0.0f) ? step : -step);
	}
}
