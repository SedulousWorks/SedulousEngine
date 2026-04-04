namespace Sedulous.Engine.Physics;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;

/// Owns the physics engine instance and shared configuration (collision layers, shape caches).
/// Per-scene physics worlds are managed by PhysicsBodyManager (scene module), injected via ISceneAware.
class PhysicsSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => -100;

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
	}

	public void OnSceneCreated(Scene scene)
	{
		// TODO: inject PhysicsBodyManager into scene
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}
}
