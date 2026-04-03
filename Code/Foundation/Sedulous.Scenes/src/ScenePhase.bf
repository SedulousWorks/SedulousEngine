namespace Sedulous.Scenes;

/// Phases of a scene update, executed in order each frame.
/// Component managers register update functions into specific phases.
public enum ScenePhase
{
	/// Initialize newly created components.
	Initialize,

	/// Synchronous pre-update (physics results readback, input application).
	PreUpdate,

	/// Main update (gameplay, AI, simulation). Parallel-capable in future.
	Update,

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
