using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace Masquerade;

/// Masquerade.Engine: this game's native code, the Engine part of its plugin package, loaded by every host.
///
/// Load is the one registration point: what the context and the host's services record is
/// reversed when the plugin unloads (the project closing). Unload removes what the recording
/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
/// so linking the project is all it takes; the project's entry enables it.
[AlwaysInclude]
class MasqueradeEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new MasqueradeEnginePart());
	}

	public override StringView PluginId => "masquerade";
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
		// Behaviours update type by type in this order. The orchestra sets the evening's cue first;
		// the player's hunter moves, then the guests and the bots wander, talk, dance and step
		// aside; the ball judges the round from where everyone now is, and the camera follows
		// last.
		GameplayServices.AddBehaviour<Orchestra>(engine);
		GameplayServices.AddBehaviour<Player>(engine);
		GameplayServices.AddBehaviour<Guest>(engine);
		GameplayServices.AddBehaviour<Ball>(engine);
		GameplayServices.AddBehaviour<CameraRig>(engine);
		// The run: the title, hosting and joining, the HUD, the pause menu, the results and the save.
		GameplayServices.SetGame<MasqueradeGame>(engine);
		GlobalLog(.Information, "Masquerade loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}
