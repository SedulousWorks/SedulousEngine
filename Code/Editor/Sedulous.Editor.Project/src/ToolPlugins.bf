using System;
using Sedulous.Runtime;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// The plugins of a headless tool (the cook, the exporter, the MCP host): a tool has no
/// application, so its plugin host runs over a subsystem manager of its own. Made once the project
/// is open, it enables the plugins the project enables that the tool links, each the parts the
/// tool's role takes, and unloads them when it goes, before the project it read them from.
class ToolPlugins
{
	private SubsystemManager mSubsystems = new .() ~ delete _;
	/// After the manager it runs over, so it goes first.
	private PluginHost mHost ~ delete _;
	private PluginLoadReport mReport = new .() ~ delete _;

	/// Over `parts` (BORROWED; PluginRegistry.Parts in a tool) and `project`'s list.
	public this(HostRole role, EditorProject project, Span<PluginPart> parts)
	{
		mHost = new .(mSubsystems, role, EngineVersion.String);
		ProjectPlugins.Load(mHost, parts, project.Settings, mReport);
	}

	/// Over the parts this binary links.
	public this(HostRole role, EditorProject project) : this(role, project, PluginRegistry.Parts)
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
