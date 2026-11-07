using System;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace NativeSample;

/// NativeSample: the reference game's runtime code, the Engine part of its plugin package,
/// loaded by every host.
///
/// Load is the one registration point: it adds the spin manager, which turns the entities with a
/// spin component, and the Bob behaviour's manager, to every scene, live ones
/// included, through the engine's service (a host without one, such as the cook, offers none, and
/// nothing is added). What it adds is recorded and taken out again when the plugin unloads (the
/// project closing). The part registers itself when the program starts, so linking the project
/// is all it takes; the project's entry enables it.
[AlwaysInclude]
class NativeSampleEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");
	/// The id the part contributes the manager under.
	public const String cSpinContribution = "nativesample.spin";

	static this()
	{
		PluginRegistry.Register(new NativeSampleEnginePart());
	}

	public override StringView PluginId => "nativesample";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => cManifest;

	/// The scene contributions' key for the spin manager.
	public static uint64 SpinManagerType => TypeIdOf(typeof(SpinManager).GetFullName(.. scope .()));

	private static void InstallSpin(Sedulous.Scene.Scene scene) => scene.AddSystem<SpinManager>();

	/// The last load found a type of the plugin's on a script surface already, and published none.
	public static bool ScriptTypesRefused = false;

	public override void Load(PluginContext context)
	{
		let engine = context.Find<EnginePluginServices>();
		if (engine == null)
			return;
		var spin = SceneModuleContribution();
		spin.Id = cSpinContribution;
		spin.Install = => InstallSpin;
		spin.SystemType = SpinManagerType;
		engine.AddSceneManager(spin);
		// Its behaviour: Bob's manager in every scene, and with it the system that runs behaviours.
		GameplayServices.AddBehaviour<Bob>(engine);
		// Its own script types (the Spin component) on the process's surfaces while it is enabled.
		ScriptTypesRefused = !engine.AddScriptTypes(PluginId, => NativeSampleScriptSurface.Populate);
		GlobalLog(.Information, "NativeSample loaded");
	}
}
