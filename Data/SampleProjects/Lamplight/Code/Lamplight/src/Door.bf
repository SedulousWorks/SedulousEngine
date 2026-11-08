using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// A door on its hinge (this entity, at the hinge edge; the leaf and its kinematic collider are
/// children, so they swing with it). Locked, it is picked by holding Interact at it: the thief's hand
/// goes to the lock (two-bone IK on the thief), a bar fills on the HUD, and letting go starts the
/// pick over. Unlocked, Interact opens it away from the thief and closes it again. A guard who comes
/// to it (Knock) opens it, locked or not: guards have the keys.
[Behaviour("lamplight.door")]
[DisplayName("Door"), Category("Lamplight")]
[Description("A door or gate on its hinge: picked open when locked, opened and shut with Interact, and opened by a guard who comes to it.")]
class Door : Behaviour
{
	[Description("The thief (it carries the hand's two-bone IK)")]
	public EntityRef Thief = .();
	[Description("Locked at the start")]
	public bool Locked = true;
	[Description("Seconds of holding Interact to pick the lock")]
	public float PickSeconds = 3.0f;
	[Description("How near the lock the thief must stand (m): within an arm's reach")]
	public float Reach = 0.8f;
	[Description("The door's yaw when shut (degrees; the leaf runs along +X from the hinge)")]
	public float ShutYaw = 0.0f;
	[Description("The lock's distance along the leaf from the hinge (m)")]
	public float LockAlong = 0.94f;
	[Description("The lock's height (m)")]
	public float LockHeight = 1.0f;
	[Description("How far it swings open (degrees)")]
	public float OpenAngle = 100.0f;
	[Description("How fast it swings (degrees a second)")]
	public float SwingSpeed = 160.0f;

	/// The thief Thief names in this scene, found as it starts.
	private EntityHandle mThief = .Invalid;
	/// Degrees from shut, and where it is swinging to.
	private float mAngle = 0.0f;
	private float mTarget = 0.0f;
	/// Seconds of the pick held so far.
	private float mPick = 0.0f;
	private bool mPicking = false;
	/// This door set the HUD's prompt (only the door that set it clears it).
	private bool mPrompting = false;

	protected override void OnStart()
	{
		mThief = Scene.FindEntity(Thief.Id);
		Turn(ShutYaw);
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mThief))
			return;
		let yaw = DegreesToRadians(ShutYaw);
		let hinge = Scene.GetWorldPosition(Entity);
		let along = Float3(Cos(yaw), 0.0f, -Sin(yaw)); // the shut leaf, hinge to lock
		let normal = Float3(Sin(yaw), 0.0f, Cos(yaw)); // its face
		let t = Scene.GetWorldPosition(mThief);
		let side = ((t.X - hinge.X) * normal.X + (t.Z - hinge.Z) * normal.Z >= 0.0f) ? 1.0f : -1.0f;
		// The lock on the thief's face of the shut leaf.
		let lockAt = Float3(hinge.X + along.X * LockAlong + normal.X * side * 0.05f, hinge.Y + LockHeight,
			hinge.Z + along.Z * LockAlong + normal.Z * side * 0.05f);
		let dx = lockAt.X - t.X;
		let dz = lockAt.Z - t.Z;
		let near = (dx * dx + dz * dz <= Reach * Reach) && (mAngle == 0.0f);

		var picking = Locked && near && Pieces.IsDown(Run, "Interact");
		if (picking)
		{
			mPick += dt;
			IkScene.SetTarget(Scene, mThief, lockAt);
			if (let thief = Pieces.ThiefOn(Scene, mThief))
				thief.Picking(lockAt);
			if (mPick >= PickSeconds)
			{
				Locked = false;
				picking = false;
			}
		}
		else
		{
			mPick = 0.0f; // let go: the pick starts over
		}
		if (picking != mPicking)
		{
			mPicking = picking;
			if (let ik = Scene.GetComponent<TwoBoneIkComponent>(mThief))
				ik.Weight = picking ? 1.0f : 0.0f;
		}
		if (!Locked && Pieces.WasPressed(Run, "Interact") && (near || (mTarget != 0.0f)))
		{
			// Open away from the thief (turned by a, the leaf points along (cos a, 0, -sin a), so
			// away from the thief's side is a = side x the angle); shut again from either side.
			mTarget = (mTarget != 0.0f) ? 0.0f : side * OpenAngle;
		}
		let swing = SwingSpeed * dt;
		let delta = mTarget - mAngle;
		mAngle = (Abs(delta) <= swing) ? mTarget : (mAngle + ((delta > 0.0f) ? swing : -swing));
		Turn(ShutYaw + mAngle);
		Prompt(near || (!Locked && (mTarget != 0.0f) && (dx * dx + dz * dz <= 4.0f * Reach * Reach)));
	}

	/// A guard at the door, at `at` (a Guard knocks): he has the keys, so a shut door opens away
	/// from him, locked or not, and stays open behind him.
	public void Knock(Float3 at)
	{
		if ((mTarget != 0.0f) || (mAngle != 0.0f))
			return;
		let yaw = DegreesToRadians(ShutYaw);
		let hinge = Scene.GetWorldPosition(Entity);
		let side = ((at.X - hinge.X) * Sin(yaw) + (at.Z - hinge.Z) * Cos(yaw) >= 0.0f) ? 1.0f : -1.0f;
		Locked = false;
		mTarget = side * OpenAngle;
	}

	/// The hinge turned to `degrees` about up (the hinge is a root, so its own turn is its turn in
	/// the world).
	private void Turn(float degrees)
	{
		Scene.SetLocalRotation(Entity, FromYawPitchRoll(DegreesToRadians(degrees), 0.0f, 0.0f));
	}

	/// The HUD's prompt and the pick's progress while in reach; cleared on leaving, only by the door
	/// that set it.
	private void Prompt(bool show)
	{
		if (show)
		{
			let panel = Hud.Find(Run, "hud-prompt-panel");
			if (panel == null)
				return; // the HUD is not up
			// The control Interact takes on the device in hand, not the action's name.
			let use = Pieces.Describe(Run, "Interact", .. scope String());
			let text = scope String();
			if (Locked)
			{
				if (mPicking)
					text.Append("Picking the lock...");
				else
					text.AppendF("Hold {}: pick the lock", use);
			}
			else
			{
				text.AppendF((mTarget != 0.0f) ? "{}: close the door" : "{}: open the door", use);
			}
			Hud.SetText(Hud.Find(Run, "hud-prompt"), text);
			panel.Visible = true;
			if (let bar = Hud.Find(Run, "hud-pick"))
			{
				bar.Visible = mPicking;
				if (let progress = bar as ProgressBar)
					progress.Value = mPick / PickSeconds;
			}
			mPrompting = true;
		}
		else if (mPrompting)
		{
			if (let panel = Hud.Find(Run, "hud-prompt-panel"))
				panel.Visible = false;
			mPrompting = false;
		}
	}
}
