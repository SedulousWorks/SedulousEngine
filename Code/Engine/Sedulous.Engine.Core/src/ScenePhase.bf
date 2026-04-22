namespace Sedulous.Engine.Core;

/// Phases of a scene update, executed in order each frame.
/// Component managers register update functions into specific phases.
public enum ScenePhase
{
	/// Initialize newly created components.
	Initialize,

	/// Synchronous pre-update (physics results readback, input application).
	PreUpdate,

	/// Main update (gameplay, AI, simulation). Sequential - safe for cross-component access.
	Update,

	/// Parallel update - all registered managers run concurrently via JobSystem.ParallelFor.
	/// Each manager may ONLY access its own component pool. No entity creation/destruction,
	/// no hierarchy changes, no transform writes, no cross-component reads.
	AsyncUpdate,

	/// Synchronous post-update (animation, constraints, late logic).
	PostUpdate,

	/// Propagate dirty transforms down the hierarchy. Internal to Scene.
	TransformUpdate,

	/// After transforms are final (render extraction, spatial index update).
	PostTransform,

	/// Deferred entity/component destruction.
	Cleanup,

	COUNT
}
