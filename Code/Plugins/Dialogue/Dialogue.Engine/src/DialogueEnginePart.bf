using System;
using Sedulous.Resource;
using Sedulous.Runtime;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Composition;

namespace Dialogue;

/// Dialogue.Engine: the dialogue plugin's runtime, the Engine part of the engine's official
/// dialogue package, loaded by every host whose project enables it. Its load registers the plugin's
/// cooked types, reads the project's settings for the plugin into DialogueSettings (the host holds
/// them while the plugin is loaded; Project Settings edits that object) and, in a host that offers
/// the engine's service, adds the dialogue's domain (the factories that load a cooked dialogue file
/// and a cooked cast) and a runner to every run. What it registers and adds is recorded and taken out again when the plugin
/// unloads. The part registers itself when the program starts, so linking it is all a host does;
/// the project's entry enables it.
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

	/// The dialogue's domain: its resources, no scene content. Built on first use, lives for the
	/// process (the composition borrows it while the plugin is loaded).
	public static DomainModule Domain => sDomain ?? (sDomain = new .(cPluginId, null, new ResourceModule[](DialogueResources.Module)));
	private static DomainModule sDomain ~ delete _;

	public override void Load(PluginContext context)
	{
		DialogueResources.RegisterAll();
		let settings = context.Settings<DialogueSettings>();
		if (let engine = context.Find<EnginePluginServices>())
		{
			engine.AddDomain(Domain);
			if (settings != null)
				engine.AddRunService(DialogueRun.Contribution(settings));
		}
	}
}
