namespace Sedulous.Scenes;

/// Non-generic base class for component managers.
/// Provides the InitializePendingComponents hook that Scene calls
/// before FixedUpdate each frame. Only component managers need this -
/// plain SceneModules do not.
public abstract class ComponentManagerBase : SceneModule
{
	/// Initializes any components created since the last frame.
	/// Called by Scene before FixedUpdate so new physics bodies, audio sources,
	/// etc. are ready before their first simulation step.
	/// ComponentManager<T> overrides this to call OnComponentInitialized on
	/// each pending component.
	public abstract void InitializePendingComponents();
}
