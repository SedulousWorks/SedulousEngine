using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// The level's end: the player reaching the flag wins it (GoalReached), once, with confetti, and
/// the player stops to celebrate (PlayerController.Celebrate).
[Behaviour("skyhopper.goal")]
[DisplayName("Goal"), Category("Sky Hopper")]
[Description("The level's flag: the player reaching it wins the level.")]
class Goal : Behaviour
{
	[Description("Reach from the flag's base to the player's centre (m)")]
	public float Radius = 1.8f;

	private EntityHandle mPlayer = .Invalid;
	private bool mReached = false;

	protected override void OnStart()
	{
		mPlayer = Scene.FindEntityByName("Player");
	}

	protected override void OnUpdate(float dt)
	{
		if (mReached || !Scene.IsValid(mPlayer))
			return;
		let here = Scene.GetWorldPosition(Entity);
		if (Distance(Scene.GetWorldPosition(mPlayer), here) >= Radius)
			return;
		mReached = true;
		Feedback.Spawn(Scene, Assets.Confetti, here + Float3(0.0f, 1.0f, 0.0f));
		let player = Scene.GetSystem<BehaviourManager<PlayerController>>()?.Get(mPlayer);
		if ((player != null) && player.IsActive)
			player.Celebrate();
		Post(GoalReached(Entity));
	}
}
