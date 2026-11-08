using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// Removes its entity once it has lived Life seconds: on a one-shot effect's prefab
/// (Prefabs/GemSparkle, Tools/gems.py), so a spawned burst does not stay in the scene after it is
/// spent.
[Behaviour("snowline.expire")]
[DisplayName("Expire"), Category("Snowline")]
[Description("Removes the entity once it has lived its life.")]
class Expire : Behaviour
{
	[Description("How long the entity lasts (s)")]
	public float Life = 1.5f;

	private float mAge = 0.0f;
	/// The removal was asked for: it takes effect as the frame ends.
	private bool mGone = false;

	protected override void OnUpdate(float dt)
	{
		mAge += dt;
		if (!mGone && (mAge >= Life))
		{
			mGone = true;
			Scene.DestroyEntity(Entity);
		}
	}
}
