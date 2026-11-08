using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace PaperKid;

/// PaperKid.Engine: this game's native code, the Engine part of its plugin package, loaded by every host.
///
/// Load is the one registration point: what the context and the host's services record is
/// reversed when the plugin unloads (the project closing). Unload removes what the recording
/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
/// so linking the project is all it takes; the project's entry enables it.
[AlwaysInclude]
class PaperKidEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new PaperKidEnginePart());
	}

	public override StringView PluginId => "paperkid";
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
		// Behaviours update type by type in this order. The bike comes first: the camera follows
		// where it went this frame, and a crash an obstacle finds lands after the bike's update.
		GameplayServices.AddBehaviour<Bike>(engine);
		GameplayServices.AddBehaviour<FollowCamera>(engine);
		GameplayServices.AddBehaviour<MapMarkers>(engine);
		GameplayServices.AddBehaviour<Vehicle>(engine);
		GameplayServices.AddBehaviour<Pedestrian>(engine);
		GameplayServices.AddBehaviour<Obstacle>(engine);
		GameplayServices.AddBehaviour<Subscriber>(engine);
		GameplayServices.AddBehaviour<Paper>(engine);
		GameplayServices.AddBehaviour<Fx>(engine);
		GameplayServices.AddBehaviour<Pet>(engine);
		GameplayServices.AddBehaviour<Stroller>(engine);
		// A block's rules: its clock, papers and quota, on each block's scene.
		GameplayServices.AddLevel<Block>(engine);
		// The run: the title, the blocks in order, the score and the lives.
		GameplayServices.SetGame<PaperKidGame>(engine);
		GlobalLog(.Information, "PaperKid loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}
