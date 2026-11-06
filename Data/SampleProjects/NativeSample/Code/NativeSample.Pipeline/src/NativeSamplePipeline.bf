using System;
using Sedulous.Runtime;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using NativeSample.Notes;

namespace NativeSample;

/// NativeSample.Pipeline: the Pipeline part of the reference game's plugin package, loaded by the
/// editor and the CLI tools. Its load registers the note's types and adds its builder and its
/// creator to the host's pipeline registries (the editor's, a tool's), each recorded and taken
/// out again when the plugin unloads.
[AlwaysInclude]
class NativeSamplePipelinePart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");

	static this()
	{
		PluginRegistry.Register(new NativeSamplePipelinePart());
	}

	public override StringView PluginId => "nativesample";
	public override PluginPartKind Kind => .Pipeline;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		NoteTypes.RegisterAll();
		let pipeline = context.Find<PipelinePluginServices>();
		if (pipeline == null)
			return;
		pipeline.AddBuilder(new NoteBuilder());
		pipeline.AddCreator(new AssetCreator(Notes.cCreator, "Native Sample", typeof(NoteAsset), new (at) =>
			{
				let target = at.Target;
				if (target == null)
					return null;
				let instance = target.CreateInstance(target.UniqueInstanceName(at.NameOr("Note"), .. scope .()), Notes.TypeName(.. scope .()));
				if ((instance == null) || (instance.WriteObject(scope NoteAsset()) case .Err))
					return null;
				return instance;
			}).Under("Notes"));
	}
}
