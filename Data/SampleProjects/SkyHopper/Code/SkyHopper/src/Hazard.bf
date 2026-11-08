using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// Spikes and the like: the player touching one is hurt (PlayerController.Hurt), walking into it
/// or landing on it.
///
/// Touching is a box, not a sphere: within Radius across the ground and with the player's centre
/// no higher than TouchHeight above the hazard's origin. A sphere could never be reached: the
/// hazard's own collider stops the player at its side, with the player's centre a metre above the
/// ground, and stood on top the centre is higher still (the spikes are 1.5 m tall: their centre
/// stands 2.5 m above their origin). With a Mover on the same entity, it hurts wherever the mover
/// has taken it.
[Behaviour("skyhopper.hazard")]
[DisplayName("Hazard"), Category("Sky Hopper")]
[Description("Hurts the player touching it, walking into it or landing on it.")]
class Hazard : Behaviour
{
	[Description("Touch reach across the ground, hazard to player (m)")]
	public float Radius = 1.1f;
	[Description("Touching while the player's centre is at most this far above the hazard's origin (m): its top plus the player's feet (0.95)")]
	public float TouchHeight = 2.6f;

	private EntityHandle mPlayer = .Invalid;

	protected override void OnStart()
	{
		mPlayer = Scene.FindEntityByName("Player");
	}

	protected override void OnUpdate(float dt)
	{
		if (!Scene.IsValid(mPlayer))
			return;
		let at = Scene.GetWorldPosition(mPlayer);
		let here = Scene.GetWorldPosition(Entity);
		let dx = at.X - here.X;
		let dz = at.Z - here.Z;
		let above = at.Y - here.Y;
		if ((dx * dx + dz * dz < Radius * Radius) && (above <= TouchHeight) && (above > -0.5f))
		{
			let player = Scene.GetSystem<BehaviourManager<PlayerController>>()?.Get(mPlayer);
			if ((player != null) && player.IsActive)
				player.Hurt();
		}
	}
}
