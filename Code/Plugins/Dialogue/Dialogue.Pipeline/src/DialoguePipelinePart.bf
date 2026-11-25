using System;
using Sedulous.Runtime;
using Sedulous.Pipeline.Importer;

namespace Dialogue;

/// Dialogue.Pipeline: the Pipeline part of the engine's official dialogue package, the part the
/// editor and the command-line tools load. Its load registers the dialogue's asset types and, where
/// the host offers its pipeline registries, adds the dialogue file's and the cast's builders, the
/// `.dialogue` importer and File > New's creators, each recorded and taken out again when the
/// plugin unloads. The builders read the plugin's settings, which the host holds while the plugin
/// is loaded.
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

	public override void Load(PluginContext context)
	{
		DialoguePipelineTypes.RegisterAll();
		let settings = context.Settings<DialogueSettings>();
		let pipeline = context.Find<PipelinePluginServices>();
		if ((pipeline == null) || (settings == null))
			return;
		pipeline.AddBuilder(new DialogueBuilder(settings));
		pipeline.AddBuilder(new DialogueCastBuilder());
		pipeline.AddImporter(new DialogueFileImporter());
		DialogueCreators.AddCreators(pipeline);
	}
}
