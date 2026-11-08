using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace Snowline;

/// Snowline.Engine: this game's native code, the Engine part of its plugin package, loaded by every host.
///
/// Load is the one registration point: what the context and the host's services record is
/// reversed when the plugin unloads (the project closing). Unload removes what the recording
/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
/// so linking the project is all it takes; the project's entry enables it.
[AlwaysInclude]
class SnowlineEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new SnowlineEnginePart());
	}

	public override StringView PluginId => "snowline";
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
		// Behaviours update type by type in this order. The board rides first, so the gates, the
		// finish, the gems, the kickers, the gap and the avalanche judge where the rider is this
		// frame (a kicker's launch or a crash they hand the board takes on its next update); the
		// ghosts ride beside it, the track marks and bursts age, and the camera follows last.
		GameplayServices.AddBehaviour<Board>(engine);
		GameplayServices.AddBehaviour<Gate>(engine);
		GameplayServices.AddBehaviour<Finish>(engine);
		GameplayServices.AddBehaviour<Gem>(engine);
		GameplayServices.AddBehaviour<Kicker>(engine);
		GameplayServices.AddBehaviour<Gap>(engine);
		GameplayServices.AddBehaviour<Avalanche>(engine);
		GameplayServices.AddBehaviour<Ghost>(engine);
		GameplayServices.AddBehaviour<PlayerGhost>(engine);
		GameplayServices.AddBehaviour<TrackMark>(engine);
		GameplayServices.AddBehaviour<Expire>(engine);
		GameplayServices.AddBehaviour<FollowCamera>(engine);
		// The run: the title and its courses, the clock, gates, gems and tricks, the HUD, the
		// pause menu, the results, the ending and the save.
		GameplayServices.SetGame<SnowlineGame>(engine);
		GlobalLog(.Information, "Snowline loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}
