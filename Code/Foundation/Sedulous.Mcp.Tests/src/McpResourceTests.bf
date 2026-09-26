using System;
using System.Collections;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Mcp.Tests;

/// Resources: static registrations, dynamic providers, and the transport loop.
class McpResourceTests
{
	private static JsonValue Ask(McpServer server, StringView request)
	{
		let line = scope String();
		if (server.HandleLine(request, line) != .Answered)
			return null;
		return JsonValue.Parse(line);
	}

	private static int64 ErrorCode(JsonValue response)
	{
		let error = response.Get("error");
		return (error != null) ? error.Get("code").AsInt() : 0;
	}

	[Test]
	public static void AStaticResourceListsAndReads()
	{
		let server = scope McpServer();
		server.RegisterResource("engine://readme", "readme", "text/markdown", "the readme",
			new (outText, outError) =>
			{
				outText.Set("# hello");
				return true;
			});

		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/list\"}");
		defer delete listed;
		let entries = listed.Get("result").Get("resources");
		Test.Assert(entries.Count == 1);
		Test.Assert(entries.At(0).Get("uri").AsString() == "engine://readme");
		Test.Assert(entries.At(0).Get("mimeType").AsString() == "text/markdown");

		let read = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"resources/read\",\"params\":{\"uri\":\"engine://readme\"}}");
		defer delete read;
		let contents = read.Get("result").Get("contents");
		Test.Assert(contents.At(0).Get("text").AsString() == "# hello");
		Test.Assert(contents.At(0).Get("mimeType").AsString() == "text/markdown");
	}

	[Test]
	public static void AnUnknownUriIsRefused()
	{
		let server = scope McpServer();
		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/read\",\"params\":{\"uri\":\"engine://nope\"}}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidParams);
	}

	[Test]
	public static void AReadWithNoUriIsRefused()
	{
		let server = scope McpServer();
		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/read\",\"params\":{}}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidParams);
	}

	[Test]
	public static void AFailingReaderIsAnInternalError()
	{
		let server = scope McpServer();
		server.RegisterResource("engine://broken", "broken", "text/plain", "fails",
			new (outText, outError) =>
			{
				outError.Set("the file is gone");
				return false;
			});

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/read\",\"params\":{\"uri\":\"engine://broken\"}}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InternalError);
		Test.Assert(response.Get("error").Get("message").AsString() == "the file is gone");
	}

	[Test]
	public static void AProviderContributesADynamicSet()
	{
		let server = scope McpServer();
		server.RegisterResourceProvider(new ResourceProvider(
			new (outResources) =>
			{
				outResources.Add(new Resource("scene://one", "one", "application/json", "a scene"));
				outResources.Add(new Resource("scene://two", "two", "application/json", "a scene"));
			},
			new (uri, outText, outError) =>
			{
				if (uri == "scene://one")
				{
					outText.Set("{\"entities\":1}");
					return .Ok;
				}
				// Not this provider's uri, so the server tries the next one.
				return .NotMine;
			}));

		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/list\"}");
		defer delete listed;
		Test.Assert(listed.Get("result").Get("resources").Count == 2);

		let read = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"resources/read\",\"params\":{\"uri\":\"scene://one\"}}");
		defer delete read;
		let contents = read.Get("result").Get("contents");
		Test.Assert(contents.At(0).Get("text").AsString() == "{\"entities\":1}");
		// The mime type comes from the provider's own listing rather than a default.
		Test.Assert(contents.At(0).Get("mimeType").AsString() == "application/json");

		// A uri no provider claims is still unknown.
		let missing = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"resources/read\",\"params\":{\"uri\":\"scene://three\"}}");
		defer delete missing;
		Test.Assert(ErrorCode(missing) == (int64)RpcError.InvalidParams);
	}

	[Test]
	public static void AProviderThatClaimsAUriAndFailsIsDistinctFromOneThatDeclines()
	{
		let server = scope McpServer();
		server.RegisterResourceProvider(new ResourceProvider(
			new (outResources) => {},
			new (uri, outText, outError) =>
			{
				outError.Set("the scene did not load");
				return .Failed;
			}));

		// Claimed and failed is an INTERNAL error, not an unknown resource: the difference
		// tells an agent whether to fix the uri or fix the world.
		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/read\",\"params\":{\"uri\":\"scene://x\"}}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InternalError);
	}

	[Test]
	public static void StaticAndDynamicEntriesBothAppearInAListing()
	{
		let server = scope McpServer();
		server.RegisterResource("engine://static", "static", "text/plain", "fixed",
			new (outText, outError) => true);
		server.RegisterResourceProvider(new ResourceProvider(
			new (outResources) =>
			{
				outResources.Add(new Resource("scene://live", "live", "text/plain", "moving"));
			},
			new (uri, outText, outError) => ResourceReadOutcome.NotMine));

		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"resources/list\"}");
		defer delete listed;
		Test.Assert(listed.Get("result").Get("resources").Count == 2);
	}

	[Test]
	public static void TheServeLoopAnswersEveryRequestAndSkipsNotifications()
	{
		let server = scope McpServer();
		let transport = scope InMemoryTransport();

		transport.Push("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}");
		// A notification in the middle produces no line, and must not shift the others.
		transport.Push("{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}");
		transport.Push("{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"ping\"}");
		transport.Push("not json at all");
		transport.Push("{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"ping\"}");

		McpServe.Serve(server, transport);

		// Four in, four answered: the notification is the only silent one, and the garbage
		// line did not stop the loop.
		Test.Assert(transport.OutputCount == 4);

		let last = JsonValue.Parse(transport.Output(3));
		defer delete last;
		Test.Assert(last.Get("id").AsInt() == 3);
	}

	[Test]
	public static void HostInfoReportsTheProcessAndBuild()
	{
		let server = scope McpServer();
		McpHostInfo.Register(server, "build-1234",
			new (outState) => outState.Set("project", JsonValue.MakeString("demo")));

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"host_info\"}}");
		defer delete response;

		let text = response.Get("result").Get("content").At(0).Get("text").AsString();
		Test.Assert(text.Contains("build-1234"));
		Test.Assert(text.Contains("\"pid\""));
		Test.Assert(text.Contains(McpServer.ProtocolVersion));
		// The host's own state is nested rather than merged, so a host cannot shadow a field.
		Test.Assert(text.Contains("demo"));
	}
}
