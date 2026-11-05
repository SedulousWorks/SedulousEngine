using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;

namespace Sedulous.Editor.Mcp;

/// Where a Tooling part registers its tools: the server being served and the session its tools
/// work through.
class PluginToolTarget
{
	private McpServer mServer;
	private ProjectSession mSession;
	private List<String> mRegistered;

	/// All three BORROWED, for the registrar's call.
	public this(McpServer server, ProjectSession session, List<String> registered)
	{
		mServer = server;
		mSession = session;
		mRegistered = registered;
	}

	public ProjectSession Session => mSession;

	/// Registers a tool, as McpServer.RegisterTool takes it (OWNERSHIP of the schema and the
	/// handler transfers); false (nothing registered, both deleted, a warning logged) when the name
	/// is served.
	public bool RegisterTool(StringView name, StringView description, JsonValue inputSchema, ToolAnnotations annotations,
		Tool.Handler handler)
	{
		if (!Claim(name))
		{
			delete inputSchema;
			delete handler;
			return false;
		}
		mRegistered.Add(new .(name));
		mServer.RegisterTool(name, description, inputSchema, annotations, handler);
		return true;
	}

	/// A tool whose handler sees its call (one answering NotFinished), as McpServer takes it.
	public bool RegisterTool(StringView name, StringView description, JsonValue inputSchema, ToolAnnotations annotations,
		Tool.CallHandler handler)
	{
		if (!Claim(name))
		{
			delete inputSchema;
			delete handler;
			return false;
		}
		mRegistered.Add(new .(name));
		mServer.RegisterTool(name, description, inputSchema, annotations, handler);
		return true;
	}

	private bool Claim(StringView name)
	{
		if (!mServer.HasTool(name))
			return true;
		GlobalLog(.Warning, "Plugins: a plugin's MCP tool '{}' is not served: the name is taken", name);
		return false;
	}
}

/// What a plugin's Tooling part adds over MCP, through the service its host provides
/// (PluginContext.Find<McpPluginServices>): tools, which every MCP server the service serves
/// offers, one there before the plugin loaded and one started after alike. The service keeps
/// each plugin's tool registrations, applies them to a server as it is served, and takes the tools
/// out of every server when their plugin unloads. A plugin's tool may not take a name already
/// served: the engine's tools and other plugins' keep theirs.
class McpPluginServices : IRegistrationRecorder
{
	/// Registers a plugin's tools into one server.
	public typealias ToolRegistrar = delegate void(PluginToolTarget tools);

	private class Applied
	{
		/// BORROWED.
		public McpServer Server;
		public List<String> Names = new .() ~ DeleteContainerAndItems!(_);
	}

	private class Contribution
	{
		/// This service's, what the recording keeps.
		public uint64 Token;
		public ToolRegistrar Registrar ~ delete _;
		public List<Applied> Applied = new .() ~ DeleteContainerAndItems!(_);
	}

	private List<Contribution> mContributions = new .() ~ DeleteContainerAndItems!(_);
	/// The servers served, and the session each one's tools work through. BORROWED.
	private List<McpServer> mServers = new .() ~ delete _;
	private List<ProjectSession> mSessions = new .() ~ delete _;
	/// The armed part's sink. BORROWED, the loader's; null while none loads.
	private List<uint64> mSink = null;
	private uint64 mNextToken = 1;

	/// Hands this service to `host`'s plugins and records what they add through it. Before the
	/// host enables any; this outlives the host.
	public bool Attach(PluginHost host)
	{
		if (!host.Provide(this))
			return false;
		host.Loader.AddRecorder(this);
		return true;
	}

	/// Serves `server` (its tools working through `session`, both BORROWED until DetachServer):
	/// every loaded plugin's tools join it now, and a plugin loaded later adds its own.
	public void AttachServer(McpServer server, ProjectSession session)
	{
		if (mServers.Contains(server))
			return;
		mServers.Add(server);
		mSessions.Add(session);
		for (let contribution in mContributions)
			Apply(contribution, server, session);
	}

	/// Stops serving `server`: the plugins' tools leave it (a server going away calls this first).
	public void DetachServer(McpServer server)
	{
		for (let contribution in mContributions)
			Withdraw(contribution, server);
		let index = mServers.IndexOf(server);
		if (index < 0)
			return;
		mServers.RemoveAt(index);
		mSessions.RemoveAt(index);
	}

	/// Adds the tools `registrar` registers (TAKEN) to every server this service serves, and to
	/// each it serves later; they leave with the plugin. False for a null registrar.
	public bool AddTools(ToolRegistrar registrar)
	{
		if (registrar == null)
			return false;
		let contribution = new Contribution();
		contribution.Token = mNextToken++;
		contribution.Registrar = registrar;
		mContributions.Add(contribution);
		for (int i < mServers.Count)
			Apply(contribution, mServers[i], mSessions[i]);
		if (mSink != null)
			mSink.Add(contribution.Token);
		return true;
	}

	/// The tools the plugins added to `server`, by name, appended.
	public void ToolsServedBy(McpServer server, List<String> outNames)
	{
		for (let contribution in mContributions)
		{
			for (let applied in contribution.Applied)
			{
				if (applied.Server != server)
					continue;
				for (let name in applied.Names)
					outNames.Add(new .(name));
			}
		}
	}

	/// Armed around each part's load, so what it added is recorded against it.
	public override void Arm(List<uint64> sink) => mSink = sink;
	public override void Disarm() => mSink = null;

	public override void Reverse(uint64 id)
	{
		for (int i < mContributions.Count)
		{
			let contribution = mContributions[i];
			if (contribution.Token != id)
				continue;
			for (let server in mServers)
				Withdraw(contribution, server);
			mContributions.RemoveAt(i);
			delete contribution;
			return;
		}
	}

	private static void Apply(Contribution contribution, McpServer server, ProjectSession session)
	{
		let applied = new Applied();
		applied.Server = server;
		contribution.Applied.Add(applied);
		let tools = scope PluginToolTarget(server, session, applied.Names);
		contribution.Registrar(tools);
	}

	private static void Withdraw(Contribution contribution, McpServer server)
	{
		for (int i < contribution.Applied.Count)
		{
			let applied = contribution.Applied[i];
			if (applied.Server != server)
				continue;
			for (let name in applied.Names)
				server.UnregisterTool(name);
			contribution.Applied.RemoveAt(i);
			delete applied;
			return;
		}
	}
}
