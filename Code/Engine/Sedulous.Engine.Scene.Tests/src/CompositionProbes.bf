using System;
using Sedulous.Scene;

namespace Sedulous.Engine.Scene.Tests;

/// The install side of the test's "render" module, as a function the module can point at.
static class CompositionProbes
{
	public static void InstallRenderManagers(Scene scene)
	{
		scene.AddSystem<RenderSceneSystem>();
	}
}
