using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.VFS;
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
/// script_create, project_export, the log tools with the curated known issues, and the read only resources:
/// the shipping docs as docs://<name> and the open project's scenes as project://.
///
/// Usage: Sedulous.Tools.Mcp [--data-root <dir>]   (run it from inside the engine checkout so
/// the docs, KnownIssues.md and the data root resolve, or stage them beside the executable)
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

		// The engine data root, whose Shaders the export cooks: --data-root, else the
		// Data/.dataroot walk from this tool.
		let dataRoot = scope String();
		ResolveDataRoot(args, dataRoot);
		if (dataRoot.IsEmpty)
		{
			Console.Error.WriteLine("Sedulous.Tools.Mcp: no data root (put Data/ with its .dataroot marker beside the tool, or pass --data-root <dir>)");
			return 1;
		}

		// The session every tool works through. This host OWNS the project it opens:
		// project_open stores it in the owner and points the session at it. Both outlive
		// the server.
		let owner = scope ProjectOwner();
		let session = scope ProjectSession();
		// The engine surface every host serves, one list in Editor.Mcp, with the paths only
		// this host knows how to find: the curated docs and known issues by the walk up from
		// the executable.
		let paths = scope EngineToolPaths();
		paths.LocateShippingDocs(scope StringView[](GetExecutableDirectory(.. scope .()), GetCurrentDirectory(.. scope .())));
		// This host runs the cook, import and export INLINE: the export stages the player from
		// beside this executable and cooks shaders from the data root.
		let operations = scope InlineProjectOperations(session, builders,
			BuildLayout.PlayerDirectoryBeside(GetExecutableDirectory(.. scope .()), .. scope .()), dataRoot);
		EngineTools.Register(server, session, builders, importers, logBuffer, paths, operations);
		// This host's additions: an agent opens, or scaffolds, the project it wants.
		ProjectOpenTools.Register(server, session, owner);

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
