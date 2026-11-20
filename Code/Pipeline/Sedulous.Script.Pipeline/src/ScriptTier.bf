using System;

namespace Sedulous.Script.Pipeline;

/// The three kinds of behavior the engine runs, which is what a starter template is seeded
/// for: an entity's (EntityBehavior), a scene's own (SceneBehavior), the run's (RunBehavior).
/// Each starter's class is named after its asset.
enum ScriptTier
{
	/// Per entity, through a Behavior component slot: `self` and `scene` filled in, `on`
	/// handlers by name.
	Behavior,
	/// Per scene, a SceneBehavior set in the scene's Scene Behavior settings: `scene` filled in,
	/// onStart/onUpdate/onFixedUpdate/onStop.
	Level,
	/// The run's orchestrator, a RunBehavior: launch/update/exit, `Run` for scene loading
	/// and the run bus.
	Game
}
