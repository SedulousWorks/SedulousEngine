using System;
using Sedulous.Runtime;

namespace Dialogue;

/// Dialogue.Editor: the Editor part of the engine's official dialogue package. It loads and registers
/// nothing yet: the package is whole in every host, so a project enabling it loads one package.
[AlwaysInclude]
class DialogueEditorPart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new DialogueEditorPart());
	}

	public override StringView PluginId => "dialogue";
	public override PluginPartKind Kind => .Editor;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context) {}
}
