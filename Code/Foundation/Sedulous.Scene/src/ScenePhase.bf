namespace Sedulous.Scene;

/// The ordered slots a scene runs each update.
///
/// The ORDER is the contract, and systems that depend on each other rely on it: input and
/// physics readback before gameplay, gameplay before parallel work, everything before the
/// transform recompute, extraction after it. TransformUpdate is internal, driven by the
/// scene itself; a system registers into the others.
enum ScenePhase : uint8
{
	/// Run the component initialisation deferred from Add.
	Initialize,
	/// Physics readback, input application.
	PreUpdate,
	/// Gameplay and AI. Sequential, so a cross component read is safe.
	Update,
	/// Parallel per system: a system may touch ONLY its own data here.
	AsyncUpdate,
	/// Animation, constraints, late logic.
	PostUpdate,
	/// Internal: the scene propagates dirty transforms.
	TransformUpdate,
	/// Render extraction and spatial indexing, with final transforms ready.
	PostTransform,
	/// Deferred destruction settles here.
	Cleanup,

	Count
}
