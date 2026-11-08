using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace Lamplight;

/// Lamplight.Engine: this game's native code, the Engine part of its plugin package, loaded by every host.
///
/// Load is the one registration point: what the context and the host's services record is
/// reversed when the plugin unloads (the project closing). Unload removes what the recording
/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
/// so linking the project is all it takes; the project's entry enables it.
[AlwaysInclude]
class LamplightEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new LamplightEnginePart());
	}

	public override StringView PluginId => "lamplight";
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		// The engine's service: the game's behaviours, levels and game (GameplayServices'
		// AddBehaviour, AddLevel and SetGame) and its scene managers. A host without one,
		// such as the cook, offers none.
		let engine = context.Find<EnginePluginServices>();
		if (engine == null)
			return;
		// Behaviours update type by type in this order. The thief moves first, so his steps, his
		// light and what the guards see of him are this frame's; the doors, lamps and loot he
		// reaches come after the guards; the camera follows where he went, and the walls fade
		// between the camera and him last.
		GameplayServices.AddBehaviour<Thief>(engine);
		GameplayServices.AddBehaviour<Footsteps>(engine);
		GameplayServices.AddBehaviour<LightMeter>(engine);
		GameplayServices.AddBehaviour<Guard>(engine);
		GameplayServices.AddBehaviour<Door>(engine);
		GameplayServices.AddBehaviour<Lamp>(engine);
		GameplayServices.AddBehaviour<Flicker>(engine);
		GameplayServices.AddBehaviour<Loot>(engine);
		GameplayServices.AddBehaviour<Alarm>(engine);
		GameplayServices.AddBehaviour<Checkpoint>(engine);
		GameplayServices.AddBehaviour<Exit>(engine);
		GameplayServices.AddBehaviour<Pebble>(engine);
		GameplayServices.AddBehaviour<CameraRig>(engine);
		GameplayServices.AddBehaviour<CutawayWall>(engine);
		// The run: the title, the levels in order, the HUD, the pause menu, the results and the save.
		GameplayServices.SetGame<LamplightGame>(engine);
		GlobalLog(.Information, "Lamplight loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}
