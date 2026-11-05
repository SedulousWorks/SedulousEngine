using System;
using Sedulous.Runtime;
using Sedulous.Engine.Project;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.Project;

/// The plugins of a headless tool (the cook, the exporter, the MCP host): a tool has no
/// application, so its plugin host runs over a subsystem manager of its own. Made once the project
/// is open, it enables the plugins the project enables that the tool links, each the parts the
/// tool's role takes, a Pipeline part adding to the tool's pipeline registries, and unloads them
/// when it goes, before the project it read them from.
class ToolPlugins
{
	private SubsystemManager mSubsystems = new .() ~ delete _;
	/// What the Pipeline parts add, reversed as they unload.
	private PipelinePluginServices mPipeline ~ delete _;
	/// After what it runs over and records through, so it goes first.
	private PluginHost mHost ~ delete _;
	private PluginLoadReport mReport = new .() ~ delete _;

	/// Over `parts` (BORROWED; PluginRegistry.Parts in a tool) and `project`'s list, a Pipeline
	/// part adding to `registries` (BORROWED; those the tool has, the rest null).
	public this(HostRole role, EditorProject project, Span<PluginPart> parts, PipelineRegistries registries = default)
	{
		mPipeline = new .(registries);
		mHost = new .(mSubsystems, role, EngineVersion.String);
		mPipeline.Attach(mHost);
		ProjectPlugins.Load(mHost, parts, project.Settings, mReport);
	}

	/// Over the parts this binary links.
	public this(HostRole role, EditorProject project, PipelineRegistries registries = default)
		: this(role, project, PluginRegistry.Parts, registries)
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
