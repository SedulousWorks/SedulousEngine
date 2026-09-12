using System;
using Sedulous.Scene;

namespace Sedulous.Engine.Scene.Tests;

/// Counts fixed steps and captures the variable delta a scene's systems actually see.
class TimeProbeSystem : SceneSystem
{
	public uint32 FixedSteps = 0;
	public float LastUpdateDelta = 0.0f;
	public float AccumulatedUpdate = 0.0f;

	// A BLOCK body: Beef will not take an increment as an expression body.
	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		FixedSteps++;
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase != .Update)
			return;

		LastUpdateDelta = deltaTime;
		AccumulatedUpdate += deltaTime;
	}
}
