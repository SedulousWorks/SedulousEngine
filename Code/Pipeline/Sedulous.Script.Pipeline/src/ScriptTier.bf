using System;

namespace Sedulous.Script.Pipeline;

/// The three kinds of script class the engine runs, which is what a starter template is
/// seeded for: a behaviour attached to an entity, a scene's own `Level`, the run's `Game`.
enum ScriptTier
{
	/// Per entity, through a Script component slot: `self` and `scene` filled in, `on`
	/// handlers by name.
	Behavior,
	/// Per scene, the reserved class `Level` set on the scene's script settings: `scene`
	/// filled in, onStart/onUpdate/onFixedUpdate/onStop.
	Level,
	/// The run's orchestrator, the reserved class `Game`: launch/update/exit, `Run` for
	/// scene loading and the run bus.
	Game
}
