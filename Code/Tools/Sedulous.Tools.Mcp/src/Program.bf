using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Mcp.Reflection;
using Sedulous.Mcp.Script;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;

namespace Sedulous.Tools.Mcp;

/// The headless MCP server: newline delimited JSON-RPC over stdin and stdout, so an agent,
/// Claude Code on one command line, gets the engine's authoring surface with the editor
/// CLOSED. STDOUT IS THE WIRE; every engine log goes to stderr.
///
/// The surface: host_info, the reflection tools, script_api over the pipeline surface, the
/// project tools (create/open/info, asset list/info/import/cook, asset_uses,
/// project_health), the scene tools (read/write/validate, prefabs), script_validate and
/// script_create, the log tools with the curated known issues, and the read only resources:
/// the shipping docs as docs://<name> and the open project's scenes as project://.
///
/// Usage: Sedulous.Tools.Mcp   (no arguments; run it from inside the engine checkout so the
/// docs and KnownIssues.md resolve, or stage them beside the executable)
class Program
{
	public static int Main(String[] args)
	{
		// The log capture FIRST, before anything logs, so log_read sees the whole run; the
		// stderr mirror second.
		let logBuffer = new EditorLogBuffer();
		let logger = new CompositeLogger();
		logger.Add(logBuffer, true);
		logger.Add(new StderrLogger(.Information), true);
		InitGlobalLogger(logger, true);
		defer ShutdownGlobalLogger();

		// The pipeline's composition root: every type, backend and cook, the pipeline script
		// surface, then the host's builder and importer sets. They outlive the server and
		// back asset_cook, asset_import, asset_uses and project_health.
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		PipelineRegistration.RegisterAllImporters(importers);

		let server = scope McpServer();
		server.SetServerInfo("engine-mcp", "0.1.0");
		ReflectionTools.Register(server);
		ScriptTools.Register(server, PipelineRegistration.Surface);

		// The host's current project, populated by project_open and create.
		let session = scope ProjectSession();
		ProjectTools.Register(server, session);
		AssetTools.Register(server, session);
		AssetWriteTools.Register(server, session, builders, importers);
		AssetUsesTool.Register(server, session, builders);
		ProjectHealthTool.Register(server, session, builders);
		SceneTools.Register(server, session);
		ScriptValidateTool.Register(server);
		ScriptCreateTool.Register(server, session);
		LogTools.Register(server, logBuffer, ShippingDocs.FindKnownIssues(.. scope .()));

		let docs = ShippingDocs.FindDirectory(.. scope .());
		if (!docs.IsEmpty)
			ShippingDocs.Register(server, docs);
		ProjectResources.Register(server, session);

		// The build stamp is the executable's own write time: what was linked, whatever
		// was or was not recompiled into it.
		McpHostInfo.Register(server, BuildStamp(.. scope .()),
			new (outState) =>
			{
				outState.Set("projectOpen", JsonValue.MakeBool(session.IsOpen));
				if (session.IsOpen)
				{
					outState.Set("projectName", JsonValue.MakeString(session.Project.Name));
					outState.Set("projectDirectory", JsonValue.MakeString(session.Project.Directory));
				}
			});

		let transport = scope StdioTransport();
		McpServe.Serve(server, transport);
		return 0;
	}

	private static void BuildStamp(String outStamp)
	{
		let exe = Environment.GetExecutableFilePath(.. scope .());
		if (File.GetLastWriteTimeUtc(exe) case .Ok(let time))
			time.ToString(outStamp, "yyyy-MM-ddTHH:mm:ssZ");
		else
			outStamp.Set("unknown");
	}
}
