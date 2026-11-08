using System;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Engine.Composition;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay;

/// What a game's Engine part registers its game code with, from its Load, through the engine's
/// service (PluginContext.Find<EnginePluginServices>; a host without one, such as the cook,
/// offers none, and nothing is added).
///
/// Each behaviour and level is a scene contribution, so it reaches every live scene and every
/// scene made after; the game is a run listener, so it reaches every run. The plugin host's
/// unload takes each out again in reverse.
static class GameplayServices
{
	/// The contribution ids, labels only: contributions are keyed by their system type.
	public const String cBehaviourSystemContribution = "gameplay.behaviours";
	public const String cBehaviourContribution = "gameplay.behaviour";
	public const String cLevelContribution = "gameplay.level";

	/// Puts `T`'s BehaviourManager in every scene, and with the first behaviour registered the
	/// scene's BehaviourSystem, which runs them all.
	///
	/// The system is contributed before the manager, and contributions are idempotent by type,
	/// so only the first registration in the process adds it and records it, and the reversal,
	/// which runs backwards (each part's records last to first, the parts last loaded first),
	/// removes it after the last manager.
	public static void AddBehaviour<T>(EnginePluginServices engine) where T : Behaviour, new, delete
	{
		if (engine == null)
			return;

		var system = SceneModuleContribution();
		system.Id = cBehaviourSystemContribution;
		system.Install = => InstallSystem;
		system.SystemType = SystemTypeOf<BehaviourSystem>();
		engine.AddSceneManager(system);

		var manager = SceneModuleContribution();
		manager.Id = cBehaviourContribution;
		manager.Install = => InstallManager<T>;
		manager.SystemType = SystemTypeOf<BehaviourManager<T>>();
		engine.AddSceneManager(manager);
	}

	/// Puts level `T` in every scene, inactive until a scene turns its Active on (a scene's
	/// saved block does). Idempotent by type, as every contribution is, and taken out again
	/// by the unload's reversal, which deletes it from every live scene (no OnStop then; its
	/// subscriptions and queued calls end).
	///
	/// Refuses at compile time a class without [Level], or one that overrides the scene hooks
	/// the level drives itself (Level.EmitChecks).
	public static void AddLevel<T>(EnginePluginServices engine) where T : Level, new, delete
	{
		if (engine == null)
			return;

		var level = SceneModuleContribution();
		level.Id = cLevelContribution;
		level.Install = => InstallLevel<T>;
		level.SystemType = SystemTypeOf<T>();
		engine.AddSceneManager(level);
	}

	/// Makes `T` the build's game: a GameRunner on the engine's runs, so each run's LaunchGame
	/// makes a `T`, held for that session. One game per engine: a second registration is
	/// refused, logged. False, with nothing added, then, without the engine's service, or in a
	/// host without runs (a cook, a tool).
	public static bool SetGame<T>(EnginePluginServices engine) where T : Game, new, delete
	{
		if (engine == null)
			return false;
		if (engine.FindRunListener<GameRunner>() != null)
		{
			GlobalLog(.Error, "Gameplay: the engine has a game already; '{}' is not registered", typeof(T).GetFullName(.. scope .()));
			return false;
		}
		return engine.AddRunListener(new GameRunner(=> CreateGame<T>));
	}

	private static Game CreateGame<T>() where T : Game, new, delete
	{
		return new T();
	}

	/// The key a scene files system `S` under, which is how a contribution's removal finds it
	/// in a live scene.
	public static uint64 SystemTypeOf<S>() where S : SceneSystem
		=> TypeIdOf(typeof(S).GetFullName(.. scope .()));

	private static void InstallSystem(Scene scene)
	{
		if (!scene.HasSystem<BehaviourSystem>())
			scene.AddSystem<BehaviourSystem>();
	}

	private static void InstallManager<T>(Scene scene) where T : Behaviour, new, delete
	{
		if (!scene.HasSystem<BehaviourManager<T>>())
			scene.AddSystem<BehaviourManager<T>>();
	}

	private static void InstallLevel<T>(Scene scene) where T : Level, new, delete
	{
		Level.EmitChecks(typeof(T));
		if (!scene.HasSystem<T>())
			scene.AddSystem<T>();
	}
}
