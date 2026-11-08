using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// A one-shot particle burst (an Fx* prefab: its effect bursts once when it is spawned), gone once
/// the burst has played out. The game's code spawns these where things happen: confetti over a
/// cleared block, a sparkle on a delivery, dust off a crash, a puff where a paper lands.
[Behaviour("paperkid.fx")]
[DisplayName("Fx"), Category("PaperKid")]
[Description("Removes a one-shot burst once it has played out.")]
class Fx : Behaviour
{
	[Description("Seconds before the burst is gone")]
	public float Lifetime = 4.0f;

	private float mAge = 0.0f;
	/// The removal was asked for: it takes effect as the frame ends.
	private bool mGone = false;

	protected override void OnUpdate(float dt)
	{
		mAge += dt;
		if (!mGone && (mAge >= Lifetime))
		{
			mGone = true;
			Scene.DestroyEntity(Entity);
		}
	}
}
