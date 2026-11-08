using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace SkyHopper;

/// SkyHopper.Engine: this game's native code, the Engine part of its plugin package, loaded by every host.
///
/// Load is the one registration point: what the context and the host's services record is
/// reversed when the plugin unloads (the project closing). Unload removes what the recording
/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
/// so linking the project is all it takes; the project's entry enables it.
[AlwaysInclude]
class SkyHopperEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new SkyHopperEnginePart());
	}

	public override StringView PluginId => "skyhopper";
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
		// Behaviours update type by type in this order. The player comes first: what the others
		// call on it (a hurt, a bounce, the flag) lands after its own update, and it starts the
		// coins' look over each frame before they offer theirs.
		GameplayServices.AddBehaviour<PlayerController>(engine);
		GameplayServices.AddBehaviour<FollowCamera>(engine);
		GameplayServices.AddBehaviour<Coin>(engine);
		GameplayServices.AddBehaviour<Pickup>(engine);
		GameplayServices.AddBehaviour<Enemy>(engine);
		GameplayServices.AddBehaviour<Mover>(engine);
		GameplayServices.AddBehaviour<Hazard>(engine);
		GameplayServices.AddBehaviour<Goal>(engine);
		GameplayServices.AddBehaviour<TimedLife>(engine);
		// The run: the title, the levels in order, the HUD, the stakes and the saves.
		GameplayServices.SetGame<SkyHopperGame>(engine);
		GlobalLog(.Information, "SkyHopper loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}
