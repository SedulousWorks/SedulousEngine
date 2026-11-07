using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Engine.Composition;

namespace Sedulous.Engine.Gameplay;

/// What a game's Engine part registers its game code with, from its Load, through the engine's
/// service (PluginContext.Find<EnginePluginServices>; a host without one, such as the cook,
/// offers none, and nothing is added).
///
/// Each registration is a scene contribution, so it reaches every live scene and every scene
/// made after, and the plugin host's unload takes it out again in reverse.
static class GameplayServices
{
	/// The contribution ids, labels only: contributions are keyed by their system type.
	public const String cBehaviourSystemContribution = "gameplay.behaviours";
	public const String cBehaviourContribution = "gameplay.behaviour";

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
}
