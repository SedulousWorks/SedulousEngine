using System;
using Sedulous.Mcp;
using Sedulous.Mcp.Reflection;
using Sedulous.Mcp.Script;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// The engine tool surface EVERY MCP host serves, listed ONCE, so the stdio host and the
/// editor host compose through it and cannot drift.
///
/// Reflection (type_list, type_info), script_api, project_info, the asset tools (list, info,
/// import, cook, uses), project_health, the log tools (log_read, log_write, known_issues), the
/// scene and prefab tools, script_validate and script_create, project_export, and the docs://
/// and project:// resources. A host adds what only it can serve on top: the stdio host
/// project_create and project_open, the editor its live tools, and each its own host_info.
static class EngineTools
{
	/// How many tools Register registers. A new engine tool bumps this DELIBERATELY, and a
	/// lost registration fails its test loudly. host_info and the stdio host's project_create
	/// and project_open are not in it: each host registers its own.
	public const int cEngineToolCount = 21;

	/// The pipeline's types, builders and script surface must already be registered: the
	/// script tools read that surface, the asset tools the two registries. The operations are
	/// how THIS host runs the cook, import and export behind their tools (IProjectOperations).
	public static void Register(McpServer server, ProjectSession session, BuilderRegistry builders,
		ImporterRegistry importers, EditorLogBuffer logBuffer, EngineToolPaths paths,
		IProjectOperations operations)
	{
		ReflectionTools.Register(server);
		ScriptTools.Register(server, PipelineRegistration.Surface);
		ProjectInfoTool.Register(server, session);
		AssetTools.Register(server, session);
		AssetWriteTools.Register(server, session, importers, operations);
		AssetUsesTool.Register(server, session, builders);
		ProjectHealthTool.Register(server, session, builders);
		LogTools.Register(server, logBuffer, paths.KnownIssues);
		SceneTools.Register(server, session);
		if (!paths.ShippingDocsDir.IsEmpty)
			ShippingDocResources.Register(server, paths.ShippingDocsDir);
		ProjectResources.Register(server, session);
		ScriptValidateTool.Register(server);
		ScriptCreateTool.Register(server, session);
		ProjectExportTool.Register(server, session, operations);
	}
}
