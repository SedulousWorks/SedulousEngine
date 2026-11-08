using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// The camera above and behind the thief, turned a quarter at a time (TurnLeft and TurnRight),
/// swinging round to the new quarter rather than cutting to it, and following the thief with a
/// little lag so a step does not jolt the view.
[Behaviour("lamplight.camera_rig")]
[DisplayName("Camera Rig"), Category("Lamplight")]
[Description("Follows the thief from above and behind, turned a quarter at a time with TurnLeft and TurnRight.")]
class CameraRig : Behaviour
{
	[Description("The thief to follow")]
	public EntityRef Target = .();
	[Description("Distance back from the thief, along the floor (m)")]
	public float Distance = 6.5f;
	[Description("Height above the thief (m)")]
	public float Height = 7.0f;
	[Description("Aim this far above the thief's feet (m)")]
	public float LookHeight = 0.8f;
	[Description("How quickly it catches up with the thief")]
	public float Follow = 6.0f;
	[Description("How quickly it swings to a new quarter")]
	public float Swing = 7.0f;

	/// The entity Target names in this scene, found as it starts.
	private EntityHandle mTarget = .Invalid;
	/// 0 looks north (-Z), then quarters clockwise.
	private int32 mQuarter = 0;
	/// The swing's current angle (radians).
	private float mYaw = 0.0f;
	private Float3 mFocus = .(0.0f, 0.0f, 0.0f);

	protected override void OnStart()
	{
		mTarget = Scene.FindEntity(Target.Id);
		if (Scene.IsValid(mTarget))
			mFocus = Scene.GetWorldPosition(mTarget);
		Place();
	}

	protected override void OnUpdate(float dt)
	{
		if (Pieces.WasPressed(Run, "TurnLeft"))
			mQuarter = (mQuarter + 3) % 4;
		if (Pieces.WasPressed(Run, "TurnRight"))
			mQuarter = (mQuarter + 1) % 4;
		let want = (float)mQuarter * Pi * 0.5f;
		mYaw += Pieces.Wrap(want - mYaw) * Clamp(Swing * dt, 0.0f, 1.0f);
		if (Scene.IsValid(mTarget))
		{
			let at = Scene.GetWorldPosition(mTarget);
			let k = Clamp(Follow * dt, 0.0f, 1.0f);
			mFocus = .(mFocus.X + (at.X - mFocus.X) * k, mFocus.Y + (at.Y - mFocus.Y) * k, mFocus.Z + (at.Z - mFocus.Z) * k);
		}
		Place();
	}

	/// Behind the focus for the current angle: yaw 0 sits south of it (+Z) looking north. Engine
	/// forward is -Z: yaw = atan2(-dir.x, -dir.z); a positive pitch looks up.
	private void Place()
	{
		let seat = Float3(mFocus.X - Sin(mYaw) * Distance, mFocus.Y + Height, mFocus.Z + Cos(mYaw) * Distance);
		Scene.SetLocalPosition(Entity, seat);
		let dir = Float3(mFocus.X - seat.X, mFocus.Y + LookHeight - seat.Y, mFocus.Z - seat.Z);
		let len = Length(dir);
		if (len < 0.0001f)
			return;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}
}
