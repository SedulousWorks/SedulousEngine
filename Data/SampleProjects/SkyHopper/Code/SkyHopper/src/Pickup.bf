using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// What a pickup tells the game it was: a heart or a gem.
enum PickupEvent : uint8
{
	/// A heart: LifeCollected, a life back.
	case LifeCollected = 0;
	/// The level's gem: GemCollected, a bonus.
	case GemCollected = 1;
}

/// Something worth taking that is not a coin: a heart (a life) or a gem (a bonus). It spins and
/// bobs like a coin, and when the player comes within reach it is taken: the event TakenEvent
/// names goes out with Value, a sparkle and a chime mark it, and it is gone. On the pickup's
/// entity, whose first child is its model.
[Behaviour("skyhopper.pickup")]
[DisplayName("Pickup"), Category("Sky Hopper")]
[Description("A heart or a gem: spins and bobs, and tells the game it was taken when the player comes within reach.")]
class Pickup : Behaviour
{
	[Description("The event announcing it was taken")]
	public PickupEvent TakenEvent = .LifeCollected;
	[Description("The event's value")]
	public int32 Value = 1;
	[Description("Pickup reach from the player's centre (m)")]
	public float Radius = 1.3f;
	[Description("Spin rate (rad/s)")]
	public float SpinSpeed = 2.0f;
	[Description("Bob height (m)")]
	public float BobHeight = 0.25f;
	[Description("The chime's pitch")]
	public float ChimePitch = 1.3f;

	private EntityHandle mPlayer = .Invalid;
	private Float3 mHome = .(0.0f, 0.0f, 0.0f);
	private float mTime = 0.0f;

	protected override void OnStart()
	{
		mPlayer = Scene.FindEntityByName("Player");
		mHome = Scene.GetLocalTransform(Entity).Position;
	}

	protected override void OnUpdate(float dt)
	{
		mTime += dt;
		Scene.SetLocalRotation(Entity, Quaternion.FromAxisAngle(Float3.UnitY, mTime * SpinSpeed));
		Scene.SetLocalPosition(Entity, .(mHome.X, mHome.Y + Sin(mTime * 2.0f) * BobHeight, mHome.Z));
		if (!Scene.IsValid(mPlayer))
			return;
		let here = Scene.GetWorldPosition(Entity);
		if (Distance(Scene.GetWorldPosition(mPlayer), here) >= Radius)
			return;
		switch (TakenEvent)
		{
		case .LifeCollected: Post(LifeCollected(Value));
		case .GemCollected: Post(GemCollected(Value));
		}
		Feedback.Spawn(Scene, Assets.CoinSparkle, here);
		Feedback.Play(Run, Assets.Chime, .Effects, 0.8f, ChimePitch);
		Feedback.Rumble(Run, 0.1f, 0.5f, 0.12f);
		Scene.DestroyEntity(Entity);
	}
}
