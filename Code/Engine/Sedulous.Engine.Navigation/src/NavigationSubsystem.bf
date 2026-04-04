namespace Sedulous.Engine.Navigation;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;

/// Owns NavMesh build settings.
/// Per-scene navmeshes are managed by NavAgentManager (scene module), injected via ISceneAware.
class NavigationSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => 300;

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	public void OnSceneCreated(Scene scene)
	{
		// TODO: inject NavAgentManager into scene
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}
}
