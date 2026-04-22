namespace Sedulous.Engine;

using Sedulous.Engine.Core;

/// Interface for subsystems that need to react to scene lifecycle events.
/// Subsystems implementing this are notified by SceneSubsystem when scenes
/// are created or destroyed, allowing them to inject their scene modules.
///
/// Example: RenderSubsystem implements ISceneAware to inject
/// MeshComponentManager, LightComponentManager, etc. into new scenes.
interface ISceneAware
{
	/// Called when a new scene is created.
	/// Use this to add scene modules (component managers) to the scene.
	void OnSceneCreated(Scene scene);

	/// Called after all ISceneAware subsystems have received OnSceneCreated.
	/// Safe to access resources created by other subsystems (e.g., per-scene Pipeline).
	/// Mirror of OnReady at the scene level.
	void OnSceneReady(Scene scene);

	/// Called when a scene is about to be destroyed.
	/// Use this to clean up any references to the scene.
	void OnSceneDestroyed(Scene scene);
}
