using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// A trigger volume the thief walks into: from then on a catch sends him back here
/// (CheckpointReached with where to stand, which the Thief keeps). Once each.
[Behaviour("lamplight.checkpoint")]
[DisplayName("Checkpoint"), Category("Lamplight")]
[Description("A trigger the thief walks into: a catch sends him back here from then on.")]
class Checkpoint : Behaviour
{
	[Description("The thief")]
	public EntityRef Thief = .();

	private bool mReached = false;

	protected override void OnTriggerEnter(EntityHandle other)
	{
		if (mReached || !Scene.IsValid(other) || (other != Scene.FindEntity(Thief.Id)))
			return;
		mReached = true;
		Post(CheckpointReached(Scene.GetWorldPosition(Entity)));
	}
}
