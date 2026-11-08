using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// The chase camera: it springs toward a seat behind and above the target and aims at it. "Behind"
/// is the camera's own lag: as the rider goes on, the camera falls back, so the ground direction
/// from the rider back to the camera already points the right way. A crash (RiderCrashed) shakes
/// it; a new run (RunRestart) seats it straight behind the rider again.
[Behaviour("snowline.follow_camera")]
[DisplayName("Follow Camera"), Category("Snowline")]
[Description("Springs toward a seat behind and above the target, aims at it, and shakes when the rider crashes.")]
class FollowCamera : Behaviour
{
	[Description("The entity to follow (the rider)")]
	public EntityRef Target = .();
	[Description("Distance behind the target (m)")]
	public float Distance = 8.0f;
	[Description("Height above the target (m)")]
	public float Height = 3.4f;
	[Description("Aim this far above the target (m)")]
	public float LookHeight = 1.2f;
	[Description("Position spring rate (higher = snappier)")]
	public float PositionSmoothing = 4.5f;
	[Description("How long a crash shakes the camera (s)")]
	public float ShakeTime = 0.35f;
	[Description("How far a crash shakes it at first (m)")]
	public float ShakeAmount = 0.35f;
	[Description("A target this far from the seat has jumped: the camera snaps to it (m)")]
	public float SnapDistance = 40.0f;

	/// The entity Target names in this scene, found as it starts.
	private EntityHandle mTarget = .Invalid;
	/// The follow works on an unshaken position; a crash's shake is added only to where the camera
	/// is drawn, dying away, so it never pulls the follow off course.
	private Float3 mBase = .(0.0f, 0.0f, 0.0f);
	/// Seconds of shake left.
	private float mShake = 0.0f;
	/// A new run: seat behind the rider again on the next update.
	private bool mReseat = false;

	protected override void OnStart()
	{
		Listen<RiderCrashed>(new [=this] (evt) => { mShake = ShakeTime; });
		// A new run puts the rider back at the top: the camera goes straight behind it again. Its
		// lag would otherwise seat it on the side it was last on (downhill, at the finish), facing
		// the rider. On the next update, once the board has turned the rider back down the course.
		Listen<RunRestart>(new [=this] (evt) => { mReseat = true; });
		mTarget = Scene.FindEntity(Target.Id);
		SeatBehind();
	}

	/// Straight behind the rider's facing, not wherever the scene or the last run left the camera.
	private void SeatBehind()
	{
		if (!Scene.IsValid(mTarget))
			return;
		let at = Scene.GetWorldPosition(mTarget);
		let back = RotateVector(Scene.GetLocalTransform(mTarget).Rotation, .(0.0f, 0.0f, -1.0f));
		let seat = Float3(at.X + back.X * Distance, at.Y + Height, at.Z + back.Z * Distance);
		Scene.SetLocalPosition(Entity, seat);
		mBase = seat;
		FaceToward(seat, .(at.X, at.Y + LookHeight, at.Z));
	}

	protected override void OnUpdate(float dt)
	{
		if ((dt <= 0.0f) || !Scene.IsValid(mTarget))
			return;
		if (mReseat)
		{
			mReseat = false;
			SeatBehind();
			return;
		}
		// This frame's pose: physics has already written the rider's interpolated position, and a
		// world position read in an update is current.
		let at = Scene.GetWorldPosition(mTarget);
		var cam = mBase;
		var backX = cam.X - at.X;
		var backZ = cam.Z - at.Z;
		var flat = Sqrt(backX * backX + backZ * backZ);
		if (flat < 0.001f)
		{
			backX = 0.0f;
			backZ = 1.0f;
			flat = 1.0f;
		}
		let seat = Float3(at.X + backX / flat * Distance, at.Y + Height, at.Z + backZ / flat * Distance);
		// A jump of the target (a respawn back at the top) snaps the seat rather than flying the
		// camera the length of the course behind it.
		if (LengthSquared(seat - cam) > SnapDistance * SnapDistance)
			cam = seat;
		var next = Lerp(cam, seat, Clamp(PositionSmoothing * dt, 0.0f, 1.0f));
		mBase = next;
		if (mShake > 0.0f)
		{
			mShake -= dt;
			let k = ShakeAmount * Clamp(mShake / ShakeTime, 0.0f, 1.0f);
			next = next + Float3(Pieces.Range(Random, -k, k), Pieces.Range(Random, -k, k), Pieces.Range(Random, -k, k));
		}
		Scene.SetLocalPosition(Entity, next);
		FaceToward(next, .(at.X, at.Y + LookHeight, at.Z));
	}

	/// Engine forward is -Z: yaw = atan2(-dir.x, -dir.z); a positive pitch looks up.
	private void FaceToward(Float3 from, Float3 to)
	{
		let dir = to - from;
		let len = Length(dir);
		if (len < 0.0001f)
			return;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}
}
