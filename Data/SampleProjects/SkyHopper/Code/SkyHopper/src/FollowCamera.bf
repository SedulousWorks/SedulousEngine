using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// A platformer camera: behind and above the player at a fixed offset, springing after it and
/// aiming just above it. The offset never turns, so the controls stay world relative: forward is
/// always away from the camera. A jolt (Shake) rides on top of the follow and dies away.
[Behaviour("skyhopper.follow_camera")]
[DisplayName("Follow Camera"), Category("Sky Hopper")]
[Description("Follows the target from behind and above, springing after it, and shakes when jolted.")]
class FollowCamera : Behaviour
{
	[Description("The entity to follow (the player)")]
	public EntityRef Target = .();
	[Description("Distance behind the target (m)")]
	public float Distance = 11.0f;
	[Description("Height above the target (m)")]
	public float Height = 6.0f;
	[Description("Aim this far above the target (m)")]
	public float LookHeight = 1.0f;
	[Description("Position spring rate (higher = snappier)")]
	public float PositionSmoothing = 5.0f;
	[Description("How fast a shake dies away (per second)")]
	public float ShakeDecay = 6.0f;

	/// The shake's strength now (m), set by Shake and decaying to nothing.
	private float mShake = 0.0f;
	/// Where the follow has the camera, before any shake.
	private Float3 mFollowPos = .(0.0f, 0.0f, 0.0f);
	/// The entity Target names in this scene, found as it starts.
	private EntityHandle mTarget = .Invalid;

	/// Something jolted the view: a hit, a landing from high up. Strength in metres.
	public void Shake(float strength)
	{
		if (strength > mShake)
			mShake = strength;
	}

	protected override void OnStart()
	{
		mTarget = Scene.FindEntity(Target.Id);
		if (!Scene.IsValid(mTarget))
			return;
		let at = Scene.GetWorldPosition(mTarget);
		let start = Float3(at.X, at.Y + Height, at.Z + Distance);
		Scene.SetLocalPosition(Entity, start);
		mFollowPos = start;
		FaceToward(start, .(at.X, at.Y + LookHeight, at.Z));
	}

	protected override void OnUpdate(float dt)
	{
		if ((dt <= 0.0f) || !Scene.IsValid(mTarget))
			return;
		let at = Scene.GetWorldPosition(mTarget);
		let desired = Float3(at.X, at.Y + Height, at.Z + Distance);
		let newPos = Lerp(mFollowPos, desired, Clamp(PositionSmoothing * dt, 0.0f, 1.0f));
		mFollowPos = newPos;
		Scene.SetLocalPosition(Entity, newPos);
		FaceToward(newPos, .(at.X, at.Y + LookHeight, at.Z));
		// The shake rides on top of the follow, which never sees it.
		if (mShake > 0.001f)
		{
			let random = Random;
			if (random != null)
				Scene.SetLocalPosition(Entity, newPos + Float3(random.Range(-mShake, mShake), random.Range(-mShake, mShake), 0.0f));
			mShake -= mShake * Clamp(ShakeDecay * dt, 0.0f, 1.0f);
		}
	}

	/// Tilts the camera's forward (-Z) down toward `to`. The camera never turns (it always looks
	/// down -Z), so the aim is a pitch alone: a rotation about +X, negative to look down.
	private void FaceToward(Float3 from, Float3 to)
	{
		let dy = to.Y - from.Y;
		let dz = from.Z - to.Z;
		if (Abs(dy) + Abs(dz) < 0.0001f)
			return;
		Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitX, Atan2(dy, dz)));
	}
}
