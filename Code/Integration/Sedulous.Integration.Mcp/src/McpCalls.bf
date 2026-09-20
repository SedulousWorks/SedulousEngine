using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;

namespace Sedulous.Integration.Mcp;

/// The agent's side of the wire, for the goldens: a tools/call built and sent through the
/// real JSON-RPC path, so what is asserted is what an agent sees.
static class McpCalls
{
	/// Sends a tools/call; the parsed response, OWNED by the caller. The arguments are
	/// consumed.
	public static JsonValue CallResponse(McpServer server, StringView tool, JsonValue arguments)
	{
		let parameters = JsonValue.MakeObject();
		parameters.Set("name", JsonValue.MakeString(tool));
		parameters.Set("arguments", arguments);
		let request = JsonValue.MakeObject();
		defer delete request;
		request.Set("jsonrpc", JsonValue.MakeString("2.0"));
		request.Set("id", JsonValue.MakeNumber(1));
		request.Set("method", JsonValue.MakeString("tools/call"));
		request.Set("params", parameters);
		let line = scope String();
		Test.Assert(server.HandleLine(request.ToString(.. scope String()), line), "a call gets a reply");
		return JsonValue.Parse(line);
	}

	/// The tool's payload on success, OWNED by the caller: result.content[0].text re-parsed.
	public static JsonValue CallOk(McpServer server, StringView tool, JsonValue arguments)
	{
		let response = CallResponse(server, tool, arguments);
		defer delete response;
		Test.Assert(response.Get("error") == null, scope $"{tool}: a protocol error");
		let result = response.Get("result");
		let text = result.Get("content").At(0).Get("text").AsString();
		Test.Assert(!result.Get("isError").AsBool(), scope $"{tool} failed: {text}");
		return JsonValue.Parse(text);
	}

	/// The tool's error text; asserts the call was a TOOL failure, never a protocol one.
	public static void CallErr(McpServer server, StringView tool, JsonValue arguments, String outText)
	{
		let response = CallResponse(server, tool, arguments);
		defer delete response;
		Test.Assert(response.Get("error") == null, scope $"{tool}: a protocol error where a tool error was due");
		let result = response.Get("result");
		Test.Assert(result.Get("isError").AsBool(), scope $"{tool} succeeded where a refusal was due");
		outText.Set(result.Get("content").At(0).Get("text").AsString());
	}

	/// A raw JSON-RPC line; the parsed response, OWNED by the caller.
	public static JsonValue Ask(McpServer server, StringView line)
	{
		let reply = scope String();
		Test.Assert(server.HandleLine(line, reply));
		return JsonValue.Parse(reply);
	}

	public static JsonValue Obj() => JsonValue.MakeObject();

	/// Adds a string member and hands the object back, for chained argument building.
	public static JsonValue With(JsonValue arguments, StringView key, StringView value)
	{
		arguments.Set(key, JsonValue.MakeString(value));
		return arguments;
	}

	public static JsonValue With(JsonValue arguments, StringView key, double value)
	{
		arguments.Set(key, JsonValue.MakeNumber(value));
		return arguments;
	}

	/// A fresh scratch directory under the working directory, removed first.
	public static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	/// The named entry of an array of objects, or null.
	public static JsonValue Named(JsonValue entries, StringView key, StringView name)
	{
		for (int i < entries.Count)
			if (entries.At(i).Get(key).AsString() == name)
				return entries.At(i);
		return null;
	}

	public static bool HasString(JsonValue array, StringView value)
	{
		for (int i < array.Count)
			if (array.At(i).AsString() == value)
				return true;
		return false;
	}
}
