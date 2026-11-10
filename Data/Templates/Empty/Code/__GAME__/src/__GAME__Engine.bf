using System;
using Sedulous.Core.Logging;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace __GAME__;

/// __GAME__.Engine: this game's native code, the Engine part of its plugin package, loaded by every host.
///
/// Load is the one registration point: what the context and the host's services record is
/// reversed when the plugin unloads (the project closing). Unload removes what the recording
/// cannot, such as a subsystem Load added. The part registers itself when the program starts,
/// so linking the project is all it takes; the project's entry enables it.
[AlwaysInclude]
class __GAME__EnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new __GAME__EnginePart());
	}

	public override StringView PluginId => "__GAME_ID__";
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
		GameplayServices.AddBehaviour<Rotator>(engine);
		GlobalLog(.Information, "__GAME__ loaded");
	}

	public override void Unload(PluginContext context)
	{
	}
}
