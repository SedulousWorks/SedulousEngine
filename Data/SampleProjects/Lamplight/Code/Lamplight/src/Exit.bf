using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// The way out of a level (a trigger volume): the thief walking in says so (ThiefEscaped); the game
/// ends the level if he carries the target, or tells him to find it.
[Behaviour("lamplight.exit")]
[DisplayName("Exit"), Category("Lamplight")]
[Description("The way out of a level: the thief walking in with the target ends it.")]
class Exit : Behaviour
{
	[Description("The thief")]
	public EntityRef Thief = .();

	protected override void OnTriggerEnter(EntityHandle other)
	{
		if (!Scene.IsValid(other) || (other != Scene.FindEntity(Thief.Id)))
			return;
		Post(ThiefEscaped(Scene.GetWorldPosition(Entity)));
	}
}
