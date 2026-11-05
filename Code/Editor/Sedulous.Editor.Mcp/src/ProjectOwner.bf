using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// The stdio host's project ownership: project_open stores what it opened here and points
/// the session at it. The editor host has no owner, its project being the editor's own.
class ProjectOwner
{
	public EditorProject Project ~ delete _;
	/// The open project's plugins, those this host links. Declared after the project, so they go
	/// first.
	public ToolPlugins Plugins ~ delete _;
	/// The host's pipeline registries a project's plugins add to as it opens (BORROWED); none
	/// leaves a Pipeline part nothing to add to.
	public PipelineRegistries PluginRegistries;
	/// What a project's plugins' Tooling parts add MCP tools through (BORROWED); null: none.
	public McpPluginServices PluginTools = null;
	/// The plugin parts a project may enable; null is the parts that registered in this binary
	/// (PluginRegistry). BORROWED.
	public List<PluginPart> PluginParts = null;

	/// Takes ownership of `project`, releasing whatever was open, and points the session at
	/// it, the plugins it enables enabled for MCP. The session is cleared first, so it never names
	/// a project that is being deleted, and the previous project's plugins go before it.
	public void Open(ProjectSession session, EditorProject project)
	{
		session.Plugins = null;
		session.ExportHooks = null;
		DeleteAndNullify!(Plugins);
		session.Project = null;
		delete Project;
		Project = project;
		let tools = PluginTools;
		let parts = (PluginParts != null) ? (Span<PluginPart>)PluginParts : PluginRegistry.Parts;
		Plugins = new ToolPlugins(.Mcp, project, parts, PluginRegistries, scope (host) =>
			{
				if (tools != null)
					tools.Attach(host);
			});
		session.Project = project;
		session.Plugins = Plugins.Host;
		session.ExportHooks = Plugins.ExportHooks;
	}
}
