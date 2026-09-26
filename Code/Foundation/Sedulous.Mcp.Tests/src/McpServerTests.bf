using System;
using System.Collections;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Mcp.Tests;

/// The protocol layer: lifecycle, dispatch, and what each kind of failure looks like on the
/// wire.
class McpServerTests
{
	/// Handles one line and parses the response back into a value the caller owns. Null for a
	/// notification, which gets no reply at all.
	private static JsonValue Ask(McpServer server, StringView request)
	{
		let line = scope String();
		if (server.HandleLine(request, line) != .Answered)
			return null;
		return JsonValue.Parse(line);
	}

	/// The error code from a response, or nought when it carried a result instead.
	private static int64 ErrorCode(JsonValue response)
	{
		let error = response.Get("error");
		return (error != null) ? error.Get("code").AsInt() : 0;
	}

	[Test]
	public static void InitializeReportsTheVersionCapabilitiesAndServerInfo()
	{
		let server = scope McpServer();
		server.SetServerInfo("test-server", "9.9.9");

		let response = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}");
		defer delete response;

		let result = response.Get("result");
		Test.Assert(result.Get("protocolVersion").AsString() == McpServer.ProtocolVersion);
		// The keys being PRESENT is what advertises the capability.
		Test.Assert(result.Get("capabilities").Has("tools"));
		Test.Assert(result.Get("capabilities").Has("resources"));
		Test.Assert(result.Get("serverInfo").Get("name").AsString() == "test-server");
		Test.Assert(result.Get("serverInfo").Get("version").AsString() == "9.9.9");
	}

	[Test]
	public static void ANotificationNeverGetsAResponse()
	{
		let server = scope McpServer();
		let line = scope String();

		// No id means a notification, whatever the method is.
		Test.Assert(server.HandleLine("{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}", line) == .Notification);
		Test.Assert(server.HandleLine("{\"jsonrpc\":\"2.0\",\"method\":\"notifications/cancelled\"}", line) == .Notification);
		Test.Assert(server.HandleLine("{\"jsonrpc\":\"2.0\",\"method\":\"something/unknown\"}", line) == .Notification);
		// A malformed notification is ignored too, which is what JSON-RPC asks for.
		Test.Assert(server.HandleLine("{\"jsonrpc\":\"2.0\"}", line) == .Notification);
	}

	[Test]
	public static void PingAnswersAnEmptyResult()
	{
		let server = scope McpServer();
		let response = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"ping\"}");
		defer delete response;

		Test.Assert(response.Get("result").IsObject);
		Test.Assert(response.Get("id").AsInt() == 7);
	}

	[Test]
	public static void TheRequestIdTypeIsEchoedVerbatim()
	{
		let server = scope McpServer();

		let numeric = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":42,\"method\":\"ping\"}");
		defer delete numeric;
		Test.Assert(numeric.Get("id").IsNumber);
		Test.Assert(numeric.Get("id").AsInt() == 42);

		// A string id must come back a STRING: a client matches its request by exact value.
		let text = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":\"abc\",\"method\":\"ping\"}");
		defer delete text;
		Test.Assert(text.Get("id").IsString);
		Test.Assert(text.Get("id").AsString() == "abc");
	}

	[Test]
	public static void ToolsListEmitsNamesDescriptionsAndSchemas()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		schema.Str("path", "where to look", true);
		server.RegisterTool("find", "finds things", schema.Build(),
			new (arguments, outResult, outError) => true);

		let response = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\"}");
		defer delete response;

		let tools = response.Get("result").Get("tools");
		Test.Assert(tools.Count == 1);
		Test.Assert(tools.At(0).Get("name").AsString() == "find");
		Test.Assert(tools.At(0).Get("description").AsString() == "finds things");
		Test.Assert(tools.At(0).Get("inputSchema").Get("type").AsString() == "object");
		Test.Assert(tools.At(0).Get("inputSchema").Get("properties").Has("path"));
	}

	[Test]
	public static void AToolCallRoundTripsThroughTheRegistry()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		schema.Str("name", "who to greet", true);
		server.RegisterTool("greet", "says hello", schema.Build(),
			new (arguments, outResult, outError) =>
			{
				outResult.Set("greeting",
					JsonValue.MakeString(scope $"hello {arguments.Get("name").AsString()}"));
				return true;
			});

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"greet\",\"arguments\":{\"name\":\"world\"}}}");
		defer delete response;

		let result = response.Get("result");
		Test.Assert(!result.Get("isError").AsBool());
		// The tool's value arrives JSON stringified inside a text content item.
		let text = result.Get("content").At(0).Get("text").AsString();
		Test.Assert(text.Contains("hello world"));
	}

	[Test]
	public static void AToolFailureIsASuccessfulResponseCarryingTheRealText()
	{
		let server = scope McpServer();
		server.RegisterTool("boom", "always fails", scope SchemaBuilder().Build(),
			new (arguments, outResult, outError) =>
			{
				outError.Set("the pipeline is not built");
				return false;
			});

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"boom\"}}");
		defer delete response;

		// A tool failing is the agent's business, not the protocol's, so this is a result and
		// not an error envelope.
		Test.Assert(response.Get("error") == null);
		let result = response.Get("result");
		Test.Assert(result.Get("isError").AsBool());
		Test.Assert(result.Get("content").At(0).Get("text").AsString()
			== "the pipeline is not built");
	}

	[Test]
	public static void AMissingRequiredFieldIsAProtocolErrorNamingTheField()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		schema.Str("path", "where", true);
		server.RegisterTool("find", "finds", schema.Build(),
			new (arguments, outResult, outError) => true);

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"find\",\"arguments\":{}}}");
		defer delete response;

		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidParams);
		// The message names the field, because that is what an agent acts on.
		Test.Assert(response.Get("error").Get("message").AsString().Contains("path"));
	}

	[Test]
	public static void AWrongFieldTypeIsAProtocolErrorNamingTheField()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		schema.Integer("count", "how many", true);
		server.RegisterTool("take", "takes", schema.Build(),
			new (arguments, outResult, outError) => true);

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"take\",\"arguments\":{\"count\":\"lots\"}}}");
		defer delete response;

		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidParams);
		Test.Assert(response.Get("error").Get("message").AsString().Contains("count"));
	}

	[Test]
	public static void AValueOutsideAnEnumIsRefused()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		let choices = scope StringView[](  "read", "write");
		schema.Enum("mode", choices, "how", true);
		server.RegisterTool("open", "opens", schema.Build(),
			new (arguments, outResult, outError) => true);

		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"open\",\"arguments\":{\"mode\":\"destroy\"}}}");
		defer delete response;

		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidParams);
	}

	[Test]
	public static void AnUndeclaredFieldIsIgnored()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		schema.Str("path", "where", true);
		server.RegisterTool("find", "finds", schema.Build(),
			new (arguments, outResult, outError) => true);

		// This subset does not enforce additionalProperties, so an extra field passes.
		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"find\",\"arguments\":{\"path\":\"/x\",\"extra\":1}}}");
		defer delete response;
		Test.Assert(response.Get("error") == null);
	}

	[Test]
	public static void AnUnknownToolIsARefusalRatherThanACrash()
	{
		let server = scope McpServer();
		let response = Ask(server,
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"nope\"}}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidParams);
	}

	[Test]
	public static void AnUnknownMethodIsMethodNotFound()
	{
		let server = scope McpServer();
		let response = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"does/not/exist\"}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.MethodNotFound);
	}

	[Test]
	public static void ABatchArrayIsRefused()
	{
		let server = scope McpServer();
		// Later revisions of the specification dropped batches.
		let response = Ask(server, "[{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"ping\"}]");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidRequest);
		Test.Assert(response.Get("id").IsNull);
	}

	[Test]
	public static void GarbageIsAParseError()
	{
		let server = scope McpServer();
		let response = Ask(server, "this is not json");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.ParseError);
		Test.Assert(response.Get("id").IsNull);
	}

	[Test]
	public static void ANonStringMethodWithAnIdIsAnInvalidRequest()
	{
		let server = scope McpServer();
		let response = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":5}");
		defer delete response;
		Test.Assert(ErrorCode(response) == (int64)RpcError.InvalidRequest);
	}

	// ---- the tool observer ----

	[Test]
	public static void TheToolObserverHearsEveryFinishedCallByNameAndOutcomeAndNothingElse()
	{
		let server = scope McpServer();
		let schema = scope SchemaBuilder();
		schema.Str("message", "what to echo", true);
		server.RegisterTool("echo", "echoes", schema.Build(),
			new (arguments, outResult, outError) => true);
		server.RegisterTool("fail", "always fails", scope SchemaBuilder().Build(),
			new (arguments, outResult, outError) =>
			{
				outError.Set("no");
				return false;
			});
		let heard = scope List<String>();
		defer ClearAndDeleteItems(heard);
		server.SetToolObserver(new (tool, isError) => heard.Add(new $"{tool}:{isError ? "err" : "ok"}"));

		for (let line in scope String[](
			"{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"echo\",\"arguments\":{\"message\":\"hi\"}}}",
			"{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"fail\"}}",
			// Not a finished tool run: a schema refusal, an unknown tool, a ping.
			"{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"echo\",\"arguments\":{}}}",
			"{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"nope\"}}",
			"{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"ping\"}"))
			delete Ask(server, line);

		Test.Assert(heard.Count == 2);
		Test.Assert(heard[0] == "echo:ok");
		Test.Assert(heard[1] == "fail:err");
	}

	// ---- a tool that is not finished ----

	private const String cSlowCall = "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"tools/call\",\"params\":{\"name\":\"slow\"}}";

	/// The call counter a slow tool shares with its test.
	private class SlowTool
	{
		public int Calls = 0;
		public int AnswerOnCall = 3;
	}

	/// A tool that answers on its AnswerOnCall'th entry and is not finished before that: the
	/// shape of a tool waiting on a background job, minus the job.
	private static void RegisterSlow(McpServer server, SlowTool slow)
	{
		server.RegisterTool("slow", "answers after a few re-entries", scope SchemaBuilder().Build(),
			new (arguments, outResult, outError) =>
			{
				slow.Calls++;
				if (slow.Calls < slow.AnswerOnCall)
					return .NotFinished;
				outResult.Set("calls", JsonValue.MakeNumber(slow.Calls));
				return .Answered;
			});
	}

	[Test]
	public static void AToolThatIsNotFinishedSaysSoUntilTheSameLineLandsItsAnswer()
	{
		let server = scope McpServer();
		let slow = scope SlowTool();
		RegisterSlow(server, slow);

		let line = scope String();
		Test.Assert(server.HandleLine(cSlowCall, line) == .NotFinished);
		Test.Assert(line.IsEmpty, "nothing to write while it waits");
		Test.Assert(server.HandleLine(cSlowCall, line) == .NotFinished);

		let response = Ask(server, cSlowCall);
		Test.Assert(response != null);
		defer delete response;
		Test.Assert(response.Get("id").AsInt() == 9);
		let result = response.Get("result");
		Test.Assert(!result.Get("isError").AsBool());
		Test.Assert(result.Get("content").At(0).Get("text").AsString().Contains("\"calls\":3"));
		Test.Assert(slow.Calls == 3);
	}

	[Test]
	public static void ServeReentersANotFinishedLineUntilItAnswers()
	{
		let server = scope McpServer();
		let slow = scope SlowTool();
		slow.AnswerOnCall = 4;
		RegisterSlow(server, slow);

		let transport = scope InMemoryTransport();
		transport.Push(cSlowCall);
		transport.Push("{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"ping\"}");
		McpServe.Serve(server, transport);

		// The waits wrote nothing, and the ping behind the slow call still got through.
		Test.Assert(transport.OutputCount == 2);
		Test.Assert(slow.Calls == 4, "entered once per attempt");
		let first = JsonValue.Parse(transport.Output(0));
		defer delete first;
		Test.Assert(first.Get("id").AsInt() == 9);
		Test.Assert(first.Get("result").Get("content").At(0).Get("text").AsString().Contains("\"calls\":4"));
		let second = JsonValue.Parse(transport.Output(1));
		defer delete second;
		Test.Assert(second.Get("id").AsInt() == 7);
	}
}
