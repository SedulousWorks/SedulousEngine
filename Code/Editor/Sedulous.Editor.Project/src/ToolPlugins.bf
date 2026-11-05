using System;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.Project;

/// The plugins of a headless tool (the cook, the exporter, the MCP host): a tool has no
/// application, so its plugin host runs over a subsystem manager of its own. Made once the project
/// is open, it enables the plugins the project enables that the tool links, each the parts the
/// tool's role takes, and unloads them when it goes, before the project it read them from. An
/// Engine part is offered the engine's service as in the player and the editor, so the scene
/// managers and domains it adds join this tool's scenes and composition (a headless MCP host's
/// scene tools then know a plugin's components); a Pipeline part adds to the tool's pipeline
/// registries.
class ToolPlugins
{
	private SubsystemManager mSubsystems = new .() ~ delete _;
	/// What the Engine parts add, reversed as they unload.
	private EnginePluginServices mEngine = new .() ~ delete _;
	/// What the Pipeline parts add, reversed as they unload.
	private PipelinePluginServices mPipeline ~ delete _;
	/// After what it runs over and records through, so it goes first.
	private PluginHost mHost ~ delete _;
	private PluginLoadReport mReport = new .() ~ delete _;

	/// Over `parts` (BORROWED; PluginRegistry.Parts in a tool) and `project`'s list, a Pipeline
	/// part adding to `registries` (BORROWED; those the tool has, the rest null). `attach` hands the
	/// host what else the tool offers its plugins, before they load (BORROWED, called here).
	public this(HostRole role, EditorProject project, Span<PluginPart> parts, PipelineRegistries registries = default,
		delegate void(PluginHost host) attach = null)
	{
		mPipeline = new .(registries);
		mHost = new .(mSubsystems, role, EngineVersion.String);
		mEngine.Attach(mHost);
		mPipeline.Attach(mHost);
		if (attach != null)
			attach(mHost);
		ProjectPlugins.Load(mHost, parts, project.Settings, mReport);
	}

	/// Over the parts this binary links.
	public this(HostRole role, EditorProject project, PipelineRegistries registries = default,
		delegate void(PluginHost host) attach = null)
		: this(role, project, PluginRegistry.Parts, registries, attach)
	{
	}

	public ~this()
	{
		mHost.Unload();
	}

	public PluginHost Host => mHost;
	/// What the load did: the plugins enabled, those refused with why, those not enabled here.
	public PluginLoadReport Report => mReport;
}
