using System;
using Sedulous.Core;
using Sedulous.Engine.Gameplay;

namespace __GAME__;

/// Turns its entity about its own up axis while the scene simulates: the game's starter
/// behaviour, a class on its entity whose public fields are saved with the scene, shown in
/// the inspector and set by the tools. The Engine part's Load registers it, and Add
/// Component puts it on an entity.
[Behaviour("__GAME_ID__.Rotator")]
[DisplayName("Rotator")]
[Category("__GAME__")]
[Description("Turns the entity about its own up axis while the scene simulates.")]
class Rotator : Behaviour
{
	[DisplayName("Turns Per Second"), Description("How many whole turns it makes a second.")]
	public float TurnsPerSecond = 0.25f;

	protected override void OnUpdate(float dt)
	{
		let turn = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), TurnsPerSecond * TwoPi * dt);
		// The turn applies in the entity's own frame; normalizing keeps the rotation a unit
		// one over many frames of accumulated products.
		var local = Scene.GetLocalTransform(Entity);
		local.Rotation = Normalized(local.Rotation * turn);
		Scene.SetLocalTransform(Entity, local);
	}
}
