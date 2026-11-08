using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// The chase camera: it springs toward a seat behind and above the target and aims at it.
/// "Behind" is the camera's own lag: as the bike rides on, the camera falls back, so the ground
/// direction from the bike back to the camera already points the right way. A crash (BikeCrashed)
/// shakes it.
[Behaviour("paperkid.follow_camera")]
[DisplayName("Follow Camera"), Category("PaperKid")]
[Description("Springs toward a seat behind and above the target, aims at it, and shakes when the bike crashes.")]
class FollowCamera : Behaviour
{
	[Description("The entity to follow (the bike)")]
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

	/// The entity Target names in this scene, found as it starts.
	private EntityHandle mTarget = .Invalid;
	/// The follow works on an unshaken position; a crash's shake is added only to where the camera
	/// is drawn, dying away, so it never pulls the follow off course.
	private Float3 mBase = .(0.0f, 0.0f, 0.0f);
	/// Seconds of shake left.
	private float mShake = 0.0f;

	protected override void OnStart()
	{
		Listen<BikeCrashed>(new [=this] (evt) => { mShake = ShakeTime; });
		mTarget = Scene.FindEntity(Target.Id);
		if (!Scene.IsValid(mTarget))
			return;
		// Start straight behind the bike's facing, not wherever the scene put the camera.
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
		// The target's LOCAL position (the bike is a root): physics has already written this
		// frame's interpolated pose there.
		let at = Scene.GetLocalTransform(mTarget).Position;
		let cam = mBase;
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
		var next = Lerp(cam, seat, Clamp(PositionSmoothing * dt, 0.0f, 1.0f));
		mBase = next;
		if (mShake > 0.0f)
		{
			mShake -= dt;
			let k = ShakeAmount * Clamp(mShake / ShakeTime, 0.0f, 1.0f);
			next = next + Float3(Feedback.Range(Random, -k, k), Feedback.Range(Random, -k, k), Feedback.Range(Random, -k, k));
		}
		Scene.SetLocalPosition(Entity, next);
		FaceToward(next, .(at.X, at.Y + LookHeight, at.Z));
	}

	/// Engine forward is -Z: yaw = atan2(-dir.x, -dir.z); a positive pitch looks up.
	private void FaceToward(Float3 from, Float3 to)
	{
		let dir = to - from;
		let len = Sqrt(dir.X * dir.X + dir.Y * dir.Y + dir.Z * dir.Z);
		if (len < 0.0001f)
			return;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}
}
