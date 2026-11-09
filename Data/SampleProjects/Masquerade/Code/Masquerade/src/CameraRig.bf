using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// The camera above and behind the player, turned a quarter at a time (TurnLeft and TurnRight),
/// swinging round to the new quarter rather than cutting to it, and following the player with a
/// little lag so a step does not jolt the view. Behind the title it sweeps slowly to and fro before
/// the ball's dais instead (each map's dais stands against a wall, so a full circle would leave the
/// hall), on the time the game hands it (TitleView): the scene holds still at time scale 0 there.
[Behaviour("masquerade.camera_rig")]
[DisplayName("Camera Rig"), Category("Masquerade")]
[Description("Follows the player from above and behind, turned a quarter at a time; behind the title it sweeps before the dais.")]
class CameraRig : Behaviour
{
	[Description("The player to follow")]
	public EntityRef Target = .();
	[Description("Distance back from the player, along the floor (m)")]
	public float Distance = 6.5f;
	[Description("Height above the player (m)")]
	public float Height = 7.0f;
	[Description("Aim this far above the player's feet (m)")]
	public float LookHeight = 0.8f;
	[Description("How quickly it catches up with the player")]
	public float Follow = 6.0f;
	[Description("How quickly it swings to a new quarter")]
	public float Swing = 7.0f;
	[Description("Behind the title: distance from the dais (m)")]
	public float TitleDistance = 12.0f;
	[Description("Behind the title: height above the floor (m)")]
	public float TitleHeight = 7.5f;
	[Description("Behind the title: aim this far above the dais, so it sits below the menu (m)")]
	public float TitleLook = 4.0f;
	[Description("Behind the title: how far it sweeps each side of the dais's front (radians)")]
	public float TitleSweep = 0.7f;
	[Description("Behind the title: how fast it sweeps (radians of its cycle a second)")]
	public float TitleTurn = 0.12f;

	/// The entity it follows: the one Target names in this scene, found as it starts, or the one
	/// Track handed it.
	private EntityHandle mTarget = .Invalid;
	/// 0 looks north (-Z), then quarters clockwise.
	private int32 mQuarter = 0;
	/// The swing's current angle (radians).
	private float mYaw = 0.0f;
	private Float3 mFocus = .(0.0f, 0.0f, 0.0f);
	/// Sweeping before the dais behind the title.
	private bool mTitle = false;
	/// Where in its sweep it is (radians of the cycle).
	private float mPhase = 0.0f;

	protected override void OnStart()
	{
		// A hunter may have handed it someone to follow before it started (Track).
		if (!Scene.IsValid(mTarget))
			mTarget = Scene.FindEntity(Target.Id);
		if (Scene.IsValid(mTarget))
			mFocus = Scene.GetWorldPosition(mTarget);
		Place();
	}

	/// Follows `who` from now on (a client's own hunter, which appears after the scene).
	public void Track(EntityHandle who)
	{
		mTarget = who;
		if ((Scene != null) && Scene.IsValid(mTarget))
			mFocus = Scene.GetWorldPosition(mTarget);
	}

	/// The title's frame (MasqueradeGame): its real time while the title is up, below zero once a
	/// round begins, when the rig is back behind the player at once.
	public void TitleView(float dt)
	{
		if (Scene == null)
			return;
		if (dt < 0.0f)
		{
			mTitle = false;
			if (Scene.IsValid(mTarget))
				mFocus = Scene.GetWorldPosition(mTarget);
			mYaw = (float)mQuarter * Pi * 0.5f;
			Place();
			return;
		}
		let dais = Scene.FindEntityByName("Dais");
		if (!Scene.IsValid(dais))
			return;
		mTitle = true;
		mPhase += TitleTurn * dt;
		let angle = TitleSweep * Sin(mPhase); // 0 is straight out from the wall (+Z)
		let at = Scene.GetWorldPosition(dais);
		Look(.(at.X - Sin(angle) * TitleDistance, TitleHeight, at.Z + Cos(angle) * TitleDistance), .(at.X, at.Y + TitleLook, at.Z));
	}

	protected override void OnUpdate(float dt)
	{
		if (mTitle)
			return;
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

	/// Behind the focus for the current angle: yaw 0 sits south of it (+Z) looking north.
	private void Place()
	{
		let seat = Float3(mFocus.X - Sin(mYaw) * Distance, mFocus.Y + Height, mFocus.Z + Cos(mYaw) * Distance);
		Look(seat, .(mFocus.X, mFocus.Y + LookHeight, mFocus.Z));
	}

	/// Sits at `seat` looking at `at`. Engine forward is -Z: yaw = atan2(-dir.x, -dir.z); a
	/// positive pitch looks up.
	private void Look(Float3 seat, Float3 at)
	{
		Scene.SetLocalPosition(Entity, seat);
		let dir = Float3(at.X - seat.X, at.Y - seat.Y, at.Z - seat.Z);
		let len = Length(dir);
		if (len < 0.0001f)
			return;
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(Atan2(-dir.X, -dir.Z), Asin(dir.Y / len), 0.0f));
	}
}
