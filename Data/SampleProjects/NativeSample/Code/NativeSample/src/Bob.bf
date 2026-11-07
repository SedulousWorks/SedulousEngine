using System;
using Sedulous.Core;
using Sedulous.Engine.Gameplay;

namespace NativeSample;

/// Moves its entity up and down about where it stood when it started (its first update of a
/// simulating scene): the reference game's own behaviour, a class on its entity, saved with the scene.
[Behaviour("nativesample.Bob")]
[DisplayName("Bob")]
[Category("Native Sample")]
[Description("Moves the entity up and down about where it started while the scene simulates.")]
class Bob : Behaviour
{
	[Description("How far above and below its start it goes.")]
	public float Height = 0.25f;
	[DisplayName("Cycles Per Second"), Description("How many times a second it goes up and down.")]
	public float Speed = 0.5f;

	/// Where it started: the middle of its travel. Runtime state, neither saved nor shown.
	private float mBaseY = 0.0f;
	/// How far through the cycle it is, in cycles, kept in [0, 1).
	private float mPhase = 0.0f;

	protected override void OnStart()
	{
		mBaseY = Scene.GetLocalTransform(Entity).Position.Y;
	}

	protected override void OnUpdate(float dt)
	{
		mPhase += Speed * dt;
		mPhase -= Math.Floor(mPhase);
		var local = Scene.GetLocalTransform(Entity);
		local.Position.Y = mBaseY + Height * Math.Sin(mPhase * TwoPi);
		Scene.SetLocalTransform(Entity, local);
	}
}
