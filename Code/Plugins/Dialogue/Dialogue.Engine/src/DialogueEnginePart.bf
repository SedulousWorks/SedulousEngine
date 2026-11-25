using System;
using Sedulous.Runtime;

namespace Dialogue;

/// Dialogue.Engine: the dialogue plugin's runtime, the Engine part of the engine's official
/// dialogue package, loaded by every host whose project enables it. Its load reads the project's
/// settings for the plugin into DialogueSettings, which the host then holds while the plugin is
/// loaded (Project Settings edits that object). The part registers itself when the program starts,
/// so linking it is all a host does; the project's entry enables it.
[AlwaysInclude]
class DialogueEnginePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");
	public const String cPluginId = "dialogue";

	static this()
	{
		PluginRegistry.Register(new DialogueEnginePart());
	}

	public override StringView PluginId => cPluginId;
	public override PluginPartKind Kind => .Engine;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		context.Settings<DialogueSettings>();
	}
}
