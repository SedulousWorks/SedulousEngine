using System;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Mcp.Reflection;

namespace Sedulous.Mcp.Reflection.Tests;

/// The reflection tools, driven through the real JSON-RPC path rather than by calling the
/// handlers directly: what an agent sees is the wire format, so that is what is asserted.
class ReflectionToolsTests
{
	/// Builds and sends a tools/call, returning the parsed response. OWNED by the caller.
	private static JsonValue CallResponse(McpServer server, StringView tool, JsonValue arguments)
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
		Test.Assert(server.HandleLine(request.ToString(.. scope String()), line) == .Answered);
		return JsonValue.Parse(line);
	}

	/// The tool's own payload: result.content[0].text, re-parsed. Asserts the call succeeded.
	/// OWNED by the caller.
	private static JsonValue CallOk(McpServer server, StringView tool, JsonValue arguments)
	{
		let response = CallResponse(server, tool, arguments);
		defer delete response;
		Test.Assert(response.Get("error") == null);
		Test.Assert(!response.Get("result").Get("isError").AsBool());
		return JsonValue.Parse(response.Get("result").Get("content").At(0).Get("text").AsString());
	}

	/// A one-field arguments object. OWNERSHIP transfers to the call.
	private static JsonValue Arg(StringView key, StringView value)
	{
		let arguments = JsonValue.MakeObject();
		arguments.Set(key, JsonValue.MakeString(value));
		return arguments;
	}

	private static bool HasTypeNamed(JsonValue listing, StringView name, StringView namespaceName)
	{
		let types = listing.Get("types");
		for (int i < types.Count)
		{
			if ((types.At(i).Get("name").AsString() == name)
				&& (types.At(i).Get("namespace").AsString() == namespaceName))
				return true;
		}
		return false;
	}

	/// The named entry of an array of objects, or null.
	private static JsonValue Named(JsonValue entries, StringView name)
	{
		for (int i < entries.Count)
		{
			if (entries.At(i).Get("name").AsString() == name)
				return entries.At(i);
		}
		return null;
	}

	[Test]
	public static void TypeListSurfacesAuthoredTypes()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let listing = CallOk(server, "type_list", JsonValue.MakeObject());
		defer delete listing;

		Test.Assert(listing.Get("count").AsInt() > 0);
		Test.Assert(listing.Get("count").AsInt() == listing.Get("types").Count);
		Test.Assert(HasTypeNamed(listing, "Widget", "Sedulous.Mcp.Reflection.Tests.Alpha"));
		Test.Assert(HasTypeNamed(listing, "Widget", "Sedulous.Mcp.Reflection.Tests.Beta"));
		Test.Assert(HasTypeNamed(listing, "Mode", "Sedulous.Mcp.Reflection.Tests.Alpha"));
	}

	[Test]
	public static void TheNamespaceFilterIsAPrefix()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let alpha = CallOk(server, "type_list",
			Arg("namespace", "Sedulous.Mcp.Reflection.Tests.Alpha"));
		defer delete alpha;
		Test.Assert(HasTypeNamed(alpha, "Widget", "Sedulous.Mcp.Reflection.Tests.Alpha"));
		// The Beta twin is excluded, which is the whole point of filtering.
		Test.Assert(!HasTypeNamed(alpha, "Widget", "Sedulous.Mcp.Reflection.Tests.Beta"));

		// A PREFIX, not an exact match: the parent namespace takes in both.
		let both = CallOk(server, "type_list", Arg("namespace", "Sedulous.Mcp.Reflection.Tests"));
		defer delete both;
		Test.Assert(HasTypeNamed(both, "Widget", "Sedulous.Mcp.Reflection.Tests.Alpha"));
		Test.Assert(HasTypeNamed(both, "Widget", "Sedulous.Mcp.Reflection.Tests.Beta"));

		// A prefix nothing matches is empty rather than an error.
		let none = CallOk(server, "type_list", Arg("namespace", "No.Such.Namespace"));
		defer delete none;
		Test.Assert(none.Get("count").AsInt() == 0);
	}

	[Test]
	public static void CompilerDerivedTypesAreNotListed()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let listing = CallOk(server, "type_list", JsonValue.MakeObject());
		defer delete listing;

		// Beef's table holds every pointer, array and boxed wrapper it ever built. None of them
		// is a type anybody wrote, and an agent looking for the authored surface should not have
		// to wade through them.
		//
		// EndsWith rather than Contains: List<uint8*> is an authored generic that happens to be
		// specialised on a pointer, and belongs in the listing.
		let types = listing.Get("types");
		for (int i < types.Count)
		{
			let name = types.At(i).Get("name").AsString();
			Test.Assert(!name.EndsWith('*'));
			Test.Assert(!name.EndsWith(']'));
			Test.Assert(!name.StartsWith('('));
		}
	}

	[Test]
	public static void TypeInfoDescribesFieldsAndMethods()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let info = CallOk(server, "type_info", Arg("type", "Gadget"));
		defer delete info;

		Test.Assert(info.Get("name").AsString() == "Gadget");
		Test.Assert(info.Get("namespace").AsString() == "Sedulous.Mcp.Reflection.Tests.Alpha");
		// The base is reported unqualified, which is how an agent refers to it.
		Test.Assert(info.Get("base").AsString() == "Widget");

		Test.Assert(Named(info.Get("properties"), "Enabled") != null);
		Test.Assert(Named(info.Get("properties"), "Enabled").Get("type").AsString() == "bool");
	}

	[Test]
	public static void AMethodCarriesItsParamsAndReturnType()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let info = CallOk(server, "type_info", Arg("type", "Widget"));
		defer delete info;

		let area = Named(info.Get("methods"), "Area");
		Test.Assert(area != null);
		Test.Assert(area.Get("returns").AsString() == "int32");
		Test.Assert(area.Get("params").Count == 0);

		let resize = Named(info.Get("methods"), "Resize");
		Test.Assert(resize != null);
		// A void return is spelled out rather than omitted, so an agent never has to infer it.
		Test.Assert(resize.Get("returns").AsString() == "void");
		Test.Assert(resize.Get("params").Count == 2);
		Test.Assert(resize.Get("params").At(0).Get("name").AsString() == "width");
		Test.Assert(resize.Get("params").At(0).Get("type").AsString() == "int32");
		Test.Assert(resize.Get("params").At(1).Get("name").AsString() == "height");
	}

	[Test]
	public static void AnEnumReportsItsValues()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let info = CallOk(server, "type_info", Arg("type", "Mode"));
		defer delete info;

		let values = info.Get("enum");
		Test.Assert(values != null);
		Test.Assert(values.Count == 3);
		// The VALUE matters as much as the name: an agent writing a scene edit emits the number.
		Test.Assert(Named(values, "Idle").Get("value").AsInt() == 3);
		Test.Assert(Named(values, "Running").Get("value").AsInt() == 7);

		// The cases do not also turn up as fields, which is what they are underneath.
		Test.Assert(Named(info.Get("properties"), "Idle") == null);
	}

	[Test]
	public static void ANonEnumHasNoEnumKey()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let info = CallOk(server, "type_info", Arg("type", "Widget"));
		defer delete info;
		// Absent rather than empty: an empty array would read as "an enum with no values".
		Test.Assert(info.Get("enum") == null);
	}

	[Test]
	public static void TheNamespaceArgumentDisambiguatesADuplicatedName()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let arguments = JsonValue.MakeObject();
		arguments.Set("type", JsonValue.MakeString("Widget"));
		arguments.Set("namespace", JsonValue.MakeString("Sedulous.Mcp.Reflection.Tests.Beta"));

		let info = CallOk(server, "type_info", arguments);
		defer delete info;

		Test.Assert(info.Get("namespace").AsString() == "Sedulous.Mcp.Reflection.Tests.Beta");
		// The Beta twin's own field, which the Alpha one does not have.
		Test.Assert(Named(info.Get("properties"), "Depth") != null);
		Test.Assert(Named(info.Get("properties"), "Width") == null);
	}

	[Test]
	public static void AnUnknownTypeIsAToolErrorNotAProtocolFault()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let response = CallResponse(server, "type_info", Arg("type", "NoSuchType"));
		defer delete response;

		// A type that does not exist is the agent's mistake to correct, not a broken request,
		// so it travels as a successful response carrying error content.
		Test.Assert(response.Get("error") == null);
		Test.Assert(response.Get("result").Get("isError").AsBool());
		let text = response.Get("result").Get("content").At(0).Get("text").AsString();
		Test.Assert(text.Contains("NoSuchType"));
	}

	[Test]
	public static void TypeInfoWithoutATypeIsRefusedBySchema()
	{
		let server = scope McpServer();
		ReflectionTools.Register(server);

		let response = CallResponse(server, "type_info", JsonValue.MakeObject());
		defer delete response;
		// 'type' is required, so this never reaches the tool at all.
		Test.Assert(response.Get("error").Get("code").AsInt() == (int64)RpcError.InvalidParams);
	}
}
