using System;
using System.Diagnostics;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// The ops hygiene tool every host registers.
static class McpHostInfo
{
	/// What the host reports about itself, appended to outState. Null when it has nothing to
	/// add.
	public typealias StateReporter = delegate void(JsonValue outState);

	/// What the handler closes over. OWNED by the tool, because a Beef closure cannot delete
	/// what it captured.
	private class State
	{
		public String BuildStamp = new .() ~ delete _;
		public StateReporter Report ~ delete _;
	}

	/// Registers host_info.
	///
	/// It answers the two questions that otherwise cost a whole session: WHICH PROCESS is
	/// this, so a hung host can be killed by pid, and WHICH BUILD is it, so a stale binary
	/// after a rebuild is obvious rather than mysterious.
	///
	/// OWNERSHIP of the reporter transfers.
	public static void Register(McpServer server, StringView buildStamp,
		StateReporter hostState = null)
	{
		let state = new State();
		state.BuildStamp.Set(buildStamp);
		state.Report = hostState;

		let description = scope String();
		description.Append("The host process's identity: pid (kill a hung host by pid), ");
		description.Append("buildStamp (detect a stale binary after a rebuild), server and ");
		description.Append("protocol versions, and host state (for example the open project). ");
		description.Append("Read this first in a new session.");

		let schema = scope SchemaBuilder();
		server.RegisterTool("host_info", description, schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				outResult.Set("pid", JsonValue.MakeNumber((double)Process.CurrentId));
				outResult.Set("buildStamp", JsonValue.MakeString(state.BuildStamp));
				outResult.Set("serverName", JsonValue.MakeString(server.ServerName));
				outResult.Set("serverVersion", JsonValue.MakeString(server.ServerVersion));
				outResult.Set("protocolVersion", JsonValue.MakeString(McpServer.ProtocolVersion));

				if (state.Report != null)
				{
					let hostSection = JsonValue.MakeObject();
					state.Report(hostSection);
					outResult.Set("host", hostSection);
				}
				return true;
			}, state);
	}
}
