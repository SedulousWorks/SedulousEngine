using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Mcp.Http;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// What EditorMcpHost.Start binds and writes.
struct EditorMcpHostConfig
{
	/// Nought lets the operating system choose (tests); the preference's port otherwise.
	public uint16 Port = 0;
	/// The bearer secret; the transport refuses to serve without one. BORROWED.
	public StringView Token = default;
	/// Where mcp-token is written for a local agent; empty writes it nowhere. BORROWED.
	public StringView TokenFileDirectory = default;
}

/// The editor's MCP host. It serves the engine surface every host serves (EngineTools,
/// pointed at the editor's LIVE project: one content database, one writer) plus this host's
/// own host_info, over localhost HTTP and SSE behind a bearer token, and is pumped ONCE PER
/// FRAME on the main thread, so a tool may touch anything the editor owns. It lives for one
/// open project: the application starts it once the project's services are up and stops it
/// before they go. The token is also written to a file beside the editor's settings, so a
/// local agent configures itself.
class EditorMcpHost
{
	/// The token file's name under EditorMcpHostConfig.TokenFileDirectory.
	public const String cTokenFileName = "mcp-token";

	private McpServer mServer = new .() ~ delete _;
	private McpHttpHost mHttp ~ delete _;
	private ProjectSession mSession;

	/// Told (tool, isError) after every finished tools/call: the application shows the
	/// agent's activity. Owned.
	public delegate void(StringView tool, bool isError) OnToolFinished ~ delete _;

	/// Registers the shared engine surface over the session (pointed at the editor's live
	/// project), this host's host_info, and every domain's MCP tool contribution on the context
	/// (what the scene editor and the like serve over the live editor); the operations are how
	/// this host runs the cook, import and export behind their tools. Every reference must
	/// outlive the host: the application owns them all for the project's life.
	public this(EditorContext context, ProjectSession session, EditorLogBuffer logBuffer, BuilderRegistry builders,
		ImporterRegistry importers, EngineToolPaths paths, IProjectOperations operations, StringView buildStamp)
	{
		mHttp = new .(mServer);
		mSession = session;
		// Distinct from the stdio host's "engine-mcp": an agent talking to both tells them apart.
		mServer.SetServerInfo("engine-editor-mcp", "0.1.0");
		EngineTools.Register(mServer, mSession, builders, importers, logBuffer, paths, operations);
		context.ApplyMcpToolContributions(mServer); // the domains' live tools
		McpHostInfo.Register(mServer, buildStamp,
			new (outState) =>
			{
				outState.Set("kind", JsonValue.MakeString("editor"));
				outState.Set("projectOpen", JsonValue.MakeBool(true));
				outState.Set("projectName", JsonValue.MakeString(mSession.Project.Name));
				outState.Set("projectDirectory", JsonValue.MakeString(mSession.Project.Directory));
			});
		mServer.SetToolObserver(new (tool, isError) =>
			{
				if (OnToolFinished != null)
					OnToolFinished(tool, isError);
			});
	}

	public ~this()
	{
		Stop();
	}

	public bool IsRunning => mHttp.IsRunning;
	public uint16 BoundPort => mHttp.BoundPort;
	/// An agent is waiting on a tool that is not finished: keep pumping.
	public bool HasPendingRequest => mHttp.HasPendingRequest;
	public McpServer Server => mServer;

	/// Binds the port and writes the token file. False when the port is taken (another
	/// editor, most likely) or the token is empty; the host then serves nothing.
	public bool Start(EditorMcpHostConfig config)
	{
		McpHttpConfig http = .();
		http.Port = config.Port;
		http.Token = config.Token;
		if (!mHttp.Start(http))
			return false;
		if (!config.TokenFileDirectory.IsEmpty)
		{
			// The same trust domain as the settings file next to it: user readable, so a
			// local agent reads the secret instead of the user pasting it.
			CreateDirectory(config.TokenFileDirectory);
			let path = PathJoin(config.TokenFileDirectory, cTokenFileName, .. scope .());
			if (System.IO.File.WriteAllText(path, config.Token) case .Err)
				GlobalLog(.Warning, scope $"MCP: the token file could not be written under '{config.TokenFileDirectory}', agents must take the token from Preferences");
		}
		return true;
	}

	public void Stop() => mHttp.Stop();

	/// One pump of the transport: answers a waiting call, re-enters a not finished one. Once
	/// per frame, on the main thread.
	public void Pump() => mHttp.Pump();
}
