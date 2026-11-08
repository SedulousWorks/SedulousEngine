using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// Removes its entity a while after it appears: what a one-shot effect's prefab carries, so
/// whoever spawns it can forget it.
[Behaviour("skyhopper.timed_life")]
[DisplayName("Timed Life"), Category("Sky Hopper")]
[Description("Removes the entity a while after it appears.")]
class TimedLife : Behaviour
{
	[Description("Seconds before the entity removes itself")]
	public float Seconds = 3.0f;

	private float mAge = 0.0f;
	/// The removal was asked for: it takes effect as the frame ends.
	private bool mGone = false;

	protected override void OnUpdate(float dt)
	{
		mAge += dt;
		if (!mGone && (mAge >= Seconds))
		{
			mGone = true;
			Scene.DestroyEntity(Entity);
		}
	}
}
