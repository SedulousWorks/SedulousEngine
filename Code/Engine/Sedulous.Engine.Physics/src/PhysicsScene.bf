using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// THE physics manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one. The
/// runtime wiring, the contact listeners, stays with the subsystem.
static class PhysicsScene
{
	public static void AddPhysicsSceneManagers(Scene scene)
	{
		scene.AddSystem<RigidBodyComponentManager>();
		scene.AddSystem<ColliderComponentManager>();
		scene.AddSystem<JointComponentManager>();
		scene.AddSystem<CharacterComponentManager>();
		// Carries the per scene settings block.
		scene.AddSystem<PhysicsSceneSystem>();
	}
}
