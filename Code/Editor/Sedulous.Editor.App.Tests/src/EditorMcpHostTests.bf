using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Http;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The MCP host over REAL loopback against a scratch project: the token file, host_info's
/// editor state, project_info on the live project, the surface (the shared engine tools plus
/// host_info and nothing of the stdio host's), the bearer refusal, and the finished call
/// report.
class EditorMcpHostTests
{
	private static HttpRequest Post(StringView token, StringView body)
	{
		let request = new HttpRequest("POST", "/mcp");
		if (!token.IsEmpty)
			request.AddHeader("Authorization", scope $"Bearer {token}");
		request.AddHeader("Content-Type", "application/json");
		request.SetBodyText(body);
		return request;
	}

	/// One JSON-RPC call from the client thread: the parsed response, OWNED by the caller, or
	/// null on a transport failure, so the assertions read as no answer.
	private static JsonValue Call(uint16 port, StringView token, StringView body)
	{
		let request = Post(token, body);
		defer delete request;
		if (HttpClient.Fetch("127.0.0.1", port, request) case .Ok(let response))
		{
			defer delete response;
			if (response.Status == 200)
				return JsonValue.Parse(response.BodyText);
		}
		return null;
	}

	/// A finished tool's JSON payload out of the tools/call envelope, OWNED by the caller.
	private static JsonValue Payload(JsonValue response)
	{
		return JsonValue.Parse(response.Get("result").Get("content").At(0).Get("text").AsString());
	}

	[Test]
	public static void ServesTheEngineSurfaceOverTheLiveProjectAndReportsItsFinishedCalls()
	{
		RemoveDirectoryRecursive("mcp_host_project");
		RemoveDirectoryRecursive("mcp_host_userdata");
		defer { RemoveDirectoryRecursive("mcp_host_project"); RemoveDirectoryRecursive("mcp_host_userdata"); }
		Test.Assert(EditorProject.Create("mcp_host_project", "Hosted") case .Ok);
		let project = EditorProject.Open("mcp_host_project");
		Test.Assert(project != null);
		defer delete project;
		let logBuffer = scope EditorLogBuffer();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();

		let session = scope ProjectSession();
		session.Project = project;
		let operations = scope InlineProjectOperations(session, builders, "", "");
		let context = scope EditorContext();
		// A domain's contribution (registered at boot) reaches the served surface.
		context.RegisterMcpToolContribution(new (server) =>
			{
				server.RegisterTool("contributed_tool", "from a domain", scope SchemaBuilder().Build(), .ReadOnly,
					new (arguments, outResult, outError) => true);
			});
		let host = scope EditorMcpHost(context, session, logBuffer, builders, importers, scope EngineToolPaths(), operations, "test-stamp");
		let finished = scope List<String>();
		defer ClearAndDeleteItems(finished);
		host.OnToolFinished = new (tool, isError) => finished.Add(new $"{tool}:{isError ? "err" : "ok"}");
		Test.Assert(!host.IsRunning);

		EditorMcpHostConfig config = .();
		config.Port = 0;
		config.Token = "sekrit";
		config.TokenFileDirectory = "mcp_host_userdata";
		Test.Assert(host.Start(config));
		Test.Assert(host.IsRunning);
		let port = host.BoundPort;
		Test.Assert(port != 0);
		Test.Assert(System.IO.File.ReadAllText("mcp_host_userdata/mcp-token", .. scope .()) == "sekrit");

		JsonValue info = null, projectInfo = null, tools = null;
		bool wrongTokenRefused = false;
		bool done = false;
		defer { delete info; delete projectInfo; delete tools; }
		let client = scope Thread(new [&]() =>
			{
				info = Call(port, "sekrit",
					"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"host_info\",\"arguments\":{}}}");
				projectInfo = Call(port, "sekrit",
					"{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"project_info\",\"arguments\":{}}}");
				tools = Call(port, "sekrit", "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/list\"}");
				let refused = Post("wrong", "{}");
				defer delete refused;
				if (HttpClient.Fetch("127.0.0.1", port, refused) case .Ok(let response))
				{
					wrongTokenRefused = (response.Status == 401);
					delete response;
				}
				done = true;
			});
		client.Start(false);
		for (int i = 0; (i < 5000) && !done; i++)
		{
			host.Pump();
			Thread.Sleep(1);
		}
		client.Join();

		// host_info: this host's identity and the live project.
		Test.Assert(info != null);
		let infoPayload = Payload(info);
		defer delete infoPayload;
		Test.Assert(infoPayload.Get("serverName").AsString() == "engine-editor-mcp");
		Test.Assert(infoPayload.Get("buildStamp").AsString() == "test-stamp");
		Test.Assert(infoPayload.Get("host").Get("kind").AsString() == "editor");
		Test.Assert(infoPayload.Get("host").Get("projectOpen").AsBool());
		Test.Assert(infoPayload.Get("host").Get("projectName").AsString() == "Hosted");
		// project_info answers for the SAME project object the editor holds.
		Test.Assert(projectInfo != null);
		let projectPayload = Payload(projectInfo);
		defer delete projectPayload;
		Test.Assert(projectPayload.Get("name").AsString() == "Hosted");
		// The surface: the shared engine tools, host_info, and the domain's contribution; never
		// the stdio host's project_open.
		Test.Assert(tools != null);
		let listed = tools.Get("result").Get("tools");
		Test.Assert(listed.Count == EngineTools.cEngineToolCount + 2);
		bool hasHostInfo = false;
		bool hasProjectOpen = false;
		bool hasContributed = false;
		for (int i < listed.Count)
		{
			let name = listed.At(i).Get("name").AsString();
			hasHostInfo |= (name == "host_info");
			hasProjectOpen |= (name == "project_open");
			hasContributed |= (name == "contributed_tool");
		}
		Test.Assert(hasHostInfo);
		Test.Assert(hasContributed);
		Test.Assert(!hasProjectOpen);
		Test.Assert(wrongTokenRefused);
		// Every finished call was reported, in order.
		Test.Assert(finished.Count == 2);
		Test.Assert(finished[0] == "host_info:ok");
		Test.Assert(finished[1] == "project_info:ok");

		host.Stop();
		Test.Assert(!host.IsRunning);
	}

	[Test]
	public static void AnEmptyTokenNeverServes()
	{
		RemoveDirectoryRecursive("mcp_host_project2");
		defer RemoveDirectoryRecursive("mcp_host_project2");
		Test.Assert(EditorProject.Create("mcp_host_project2", "Hosted") case .Ok);
		let project = EditorProject.Open("mcp_host_project2");
		Test.Assert(project != null);
		defer delete project;
		let logBuffer = scope EditorLogBuffer();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		let session = scope ProjectSession();
		session.Project = project;
		let operations = scope InlineProjectOperations(session, builders, "", "");
		let context = scope EditorContext();
		let host = scope EditorMcpHost(context, session, logBuffer, builders, importers, scope EngineToolPaths(), operations, "test-stamp");
		EditorMcpHostConfig config = .(); // no token
		Test.Assert(!host.Start(config));
		Test.Assert(!host.IsRunning);
	}
}
