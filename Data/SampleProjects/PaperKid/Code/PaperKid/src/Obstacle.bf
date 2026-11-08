using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// Something the bike crashes into: a car, a pedestrian, the street junk. When the bike comes
/// within reach it crashes (Bike.Crash), and this obstacle waits a moment before it can be hit
/// again, so one bump is one crash.
[Behaviour("paperkid.obstacle")]
[DisplayName("Obstacle"), Category("PaperKid")]
[Description("Crashes the bike when it comes within reach, then waits a moment before it can be hit again.")]
class Obstacle : Behaviour
{
	[Description("Reach from this entity's origin to the bike's centre (m)")]
	public float Radius = 1.0f;
	[Description("Seconds before this obstacle can be hit again")]
	public float Cooldown = 2.0f;

	private EntityHandle mBike = .Invalid;
	private float mWait = 0.0f;

	protected override void OnStart()
	{
		mBike = Scene.FindEntityByName("Bike");
	}

	protected override void OnUpdate(float dt)
	{
		if (mWait > 0.0f)
		{
			mWait -= dt;
			return;
		}
		if (!Scene.IsValid(mBike))
			return;
		let at = Scene.GetWorldPosition(Entity);
		let bike = Scene.GetWorldPosition(mBike);
		let dx = bike.X - at.X;
		let dz = bike.Z - at.Z;
		if (dx * dx + dz * dz < Radius * Radius)
		{
			mWait = Cooldown;
			let rider = Scene.GetSystem<BehaviourManager<Bike>>()?.Get(mBike);
			if ((rider != null) && rider.IsActive)
				rider.Crash();
		}
	}
}
