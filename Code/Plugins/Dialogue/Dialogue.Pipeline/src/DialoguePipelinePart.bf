using System;
using Sedulous.Runtime;

namespace Dialogue;

/// Dialogue.Pipeline: the Pipeline part of the engine's official dialogue package. It loads and registers
/// nothing yet: the package is whole in every host, so a project enabling it loads one package.
[AlwaysInclude]
class DialoguePipelinePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new DialoguePipelinePart());
	}

	public override StringView PluginId => "dialogue";
	public override PluginPartKind Kind => .Pipeline;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context) {}
}
