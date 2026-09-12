using Sedulous.Scene;

namespace Sedulous.Engine.Spline;

/// The domain's scene composition install.
static class SplineScene
{
	public static void AddSplineSceneManagers(Scene scene)
	{
		scene.AddSystem<SplineComponentManager>();
		scene.AddSystem<PathFollowComponentManager>();
	}
}
