using System;
using Sedulous.Resource;
using Sedulous.Runtime;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Composition;
using Sedulous.Sequence;

namespace Dialogue;

/// Dialogue.Engine: the dialogue plugin's runtime, the Engine part of the engine's official
/// dialogue package, loaded by every host whose project enables it. Its load registers the plugin's
/// cooked types and its sequence track kind (Dialogue Lines), reads the project's settings for the
/// plugin into DialogueSettings (the host holds them while the plugin is loaded; Project Settings
/// edits that object) and, in a host that offers the engine's service, adds the dialogue's domain
/// (the factories that load a cooked dialogue file and a cooked cast), a runner to every run and
/// the `Dialogue` script service. What it registers and adds is recorded and taken out again when
/// the plugin unloads. The part registers itself when the program starts, so linking it is all a
/// host does; the project's entry enables it.
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
		// The line track joins the engine's track kinds. A load is recorded and reversed on unload,
		// so it registers nothing of the engine's (their base kinds are the engine's to register).
		SequenceTracks.Register<DialogueLineTrack>();
		let settings = context.Settings<DialogueSettings>();
		if (let engine = context.Find<EnginePluginServices>())
		{
			engine.AddDomain(Domain);
			if (settings != null)
				engine.AddRunService(DialogueRun.Contribution(settings));
			// `Dialogue` in scripts: each run's, over the idle one a script outside every run finds.
			engine.AddRunService(DialogueRun.FacadeContribution);
			engine.AddScriptTypes(cPluginId, => DialogueScriptSurface.Populate);
			if (context.Subsystems != null)
			{
				sIdleFacade = new .(null);
				context.Subsystems.RegisterService(sIdleFacade);
			}
		}
	}

	public override void Unload(PluginContext context)
	{
		SequenceTracks.Unregister<DialogueLineTrack>();
		if (sIdleFacade == null)
			return;
		if ((context.Subsystems != null) && (context.Subsystems.FindService(typeof(DialogueFacade)) === sIdleFacade))
			context.Subsystems.UnregisterService<DialogueFacade>();
		DeleteAndNullify!(sIdleFacade);
	}

	/// The `Dialogue` a script outside every run finds while the plugin is loaded: every call refused.
	private static DialogueFacade sIdleFacade ~ delete _;
}
