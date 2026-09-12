using System;
using Sedulous.Scene;

namespace Sedulous.Engine.Scene.Tests;

/// The per scene system the "render" module installs, standing in for a real domain's.
class RenderSceneSystem : SceneSystem
{
	public int Ticks = 0;

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase == .PostTransform)
			Ticks++;
	}
}
