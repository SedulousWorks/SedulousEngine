namespace Sedulous.Engine.Animation;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;

/// Owns the animation clip cache.
/// Per-scene animation is managed by AnimationManager (scene module), injected via ISceneAware.
class AnimationSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => 100;

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	public void OnSceneCreated(Scene scene)
	{
		// TODO: inject AnimationManager into scene
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}
}
