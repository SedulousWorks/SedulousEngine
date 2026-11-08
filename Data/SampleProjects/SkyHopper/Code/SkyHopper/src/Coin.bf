using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// A pickup: it spins and bobs, and when the player comes within reach it is collected
/// (CoinCollected) and gone. On the coin's entity, whose first child is the Coin model. It tells
/// the game it is there as it starts (CoinRegistered), so the level's total counts it.
///
/// The hero looks at the nearest coin within its reach (an Aim IK on the Player) that it can turn
/// its head to: one in front of it, not too steep above or below. A coin behind it would twist the
/// head over backwards, so it does not count. The player starts the look over each frame; each
/// coin then offers itself (PlayerController.OfferLook), the nearest in view winning.
[Behaviour("skyhopper.coin")]
[DisplayName("Coin"), Category("Sky Hopper")]
[Description("Spins and bobs, is collected when the player comes within reach, and draws the hero's look.")]
class Coin : Behaviour
{
	[Description("Pickup reach from the player's centre (m)")]
	public float Radius = 1.3f;
	[Description("Spin rate (rad/s)")]
	public float SpinSpeed = 3.0f;
	[Description("Bob height (m)")]
	public float BobHeight = 0.2f;
	[Description("Points")]
	public int32 Value = 1;
	[Description("The hero looks at the nearest coin within this (m)")]
	public float LookRadius = 7.0f;
	[Description("... and within this turn from where the hero faces (degrees)")]
	public float LookTurn = 55.0f;
	[Description("... and within this angle above or below its eyes (degrees)")]
	public float LookPitch = 35.0f;

	private EntityHandle mPlayer = .Invalid;
	private Float3 mHome = .(0.0f, 0.0f, 0.0f);
	private float mTime = 0.0f;

	protected override void OnStart()
	{
		mPlayer = Scene.FindEntityByName("Player");
		mHome = Scene.GetLocalTransform(Entity).Position;
		Post(CoinRegistered(1));
	}

	protected override void OnUpdate(float dt)
	{
		mTime += dt;
		Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitY, mTime * SpinSpeed));
		Scene.SetLocalPosition(Entity, .(mHome.X, mHome.Y + Sin(mTime * 2.5f) * BobHeight, mHome.Z));
		if (!Scene.IsValid(mPlayer))
			return;
		let here = Scene.GetWorldPosition(Entity);
		let distance = Distance(Scene.GetWorldPosition(mPlayer), here);
		let player = Scene.GetSystem<BehaviourManager<PlayerController>>()?.Get(mPlayer);
		if ((player != null) && (distance < LookRadius) && InView())
			player.OfferLook(distance, LookRadius, here);
		if (distance < Radius)
		{
			// A coin still in reach takes the look back next frame.
			let aim = Scene.GetComponent<AimIkComponent>(mPlayer);
			if (aim != null)
				aim.Active = false;
			Post(CoinCollected(Value));
			Feedback.Spawn(Scene, Assets.CoinSparkle, here);
			Feedback.Play(Run, Assets.Chime, .Effects, 0.7f);
			Scene.DestroyEntity(Entity);
		}
	}

	/// Whether the hero can turn its head to this coin: the turn from its facing, and the angle
	/// above or below, each within its limit. The hero's centre stands in for its eyes (the head
	/// is about 0.1 m below it).
	private bool InView()
	{
		let to = Scene.GetWorldPosition(Entity) - Scene.GetWorldPosition(mPlayer);
		let flat = Sqrt(to.X * to.X + to.Z * to.Z);
		if (flat < 0.01f)
			return false; // straight above or below
		if (Abs(Atan2(to.Y, flat)) > LookPitch * DegToRad)
			return false;
		let facing = RotateVector(Scene.GetWorldRotation(mPlayer), .(0.0f, 0.0f, 1.0f));
		let facingFlat = Sqrt(facing.X * facing.X + facing.Z * facing.Z);
		if (facingFlat < 0.01f)
			return false;
		let along = (facing.X * to.X + facing.Z * to.Z) / (facingFlat * flat);
		return along >= Cos(LookTurn * DegToRad);
	}
}
