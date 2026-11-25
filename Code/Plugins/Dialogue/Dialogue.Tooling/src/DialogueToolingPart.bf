using System;
using Sedulous.Runtime;

namespace Dialogue;

/// Dialogue.Tooling: the Tooling part of the engine's official dialogue package. It loads and registers
/// nothing yet: the package is whole in every host, so a project enabling it loads one package.
[AlwaysInclude]
class DialogueToolingPart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new DialogueToolingPart());
	}

	public override StringView PluginId => "dialogue";
	public override PluginPartKind Kind => .Tooling;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context) {}
}
