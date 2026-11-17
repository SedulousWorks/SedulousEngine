using System;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Mcp.Script;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Fixture;

namespace Sedulous.Mcp.Script.Tests;

/// script_api against a real backend, over the fixture surface, driven through the JSON-RPC
/// path an agent uses. The tool is backend neutral: it reports whatever ScriptBackends holds.
static class ScriptToolsTests
{
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

	private static JsonValue CallOk(McpServer server, StringView tool, JsonValue arguments)
	{
		let response = CallResponse(server, tool, arguments);
		defer delete response;
		Test.Assert(response.Get("error") == null);
		Test.Assert(!response.Get("result").Get("isError").AsBool());
		return JsonValue.Parse(response.Get("result").Get("content").At(0).Get("text").AsString());
	}

	private static JsonValue Arg(StringView key, StringView value)
	{
		let arguments = JsonValue.MakeObject();
		arguments.Set(key, JsonValue.MakeString(value));
		return arguments;
	}

	private static JsonValue TypeNamed(JsonValue types, StringView scriptName)
	{
		for (int i < types.Count)
			if (types.At(i).Get("scriptName").AsString() == scriptName)
				return types.At(i);
		return null;
	}

	[Test]
	public static void ScriptApiReportsTheRegisteredBackendsBoundApi()
	{
		AngelScriptBackend.Register();
		let surface = scope ScriptSurface();
		FixtureSurface.Populate(surface);
		let server = scope McpServer();
		ScriptTools.Register(server, surface);

		let api = CallOk(server, "script_api", JsonValue.MakeObject());
		defer delete api;
		let languages = api.Get("languages");
		Test.Assert(languages.Count >= 1);

		JsonValue angelscript = null;
		for (int i < languages.Count)
			if (languages.At(i).Get("language").AsString() == "angelscript")
				angelscript = languages.At(i);
		Test.Assert(angelscript != null, "the registered backend is reported");
		let types = angelscript.Get("types");
		Test.Assert(angelscript.Get("typeCount").AsInt() > 0);
		Test.Assert(types.Count == angelscript.Get("typeCount").AsInt());

		// A bound type, spelled as the script writes it, with its members and their kinds.
		let thing = TypeNamed(types, "Thing");
		Test.Assert(thing != null, "Thing is bound");
		Test.Assert(!thing.Get("isNamespace").AsBool());
		Test.Assert(thing.Get("typeFullName").AsString() == "Sedulous.Script.Fixture.Thing");
		Test.Assert(thing.Get("members").Count > 0);
		bool sawSignature = false;
		for (int i < thing.Get("members").Count)
		{
			let m = thing.Get("members").At(i);
			Test.Assert(!m.Get("signature").AsString().IsEmpty);
			let kind = m.Get("kind").AsString();
			Test.Assert((kind == "method") || (kind == "property") || (kind == "constant"));
			Test.Assert(m.Get("readOnly") != null, "every member says whether it is read only");
			sawSignature = true;
		}
		Test.Assert(sawSignature);
		// A [ReadOnly] field reads and refuses assignment; a plain field does not.
		JsonValue MemberNamed(StringView name)
		{
			for (int i < thing.Get("members").Count)
				if (thing.Get("members").At(i).Get("name").AsString() == name)
					return thing.Get("members").At(i);
			return null;
		}
		Test.Assert(MemberNamed("Serial").Get("readOnly").AsBool());
		Test.Assert(!MemberNamed("Count").Get("readOnly").AsBool());

		// The availability domain rides along: a runtime type is in the player, a pipeline
		// type exists for tools only.
		Test.Assert(thing.Get("domain").AsString() == "Runtime");
		Test.Assert(thing.Get("inPlayer").AsBool());
		let cooker = TypeNamed(types, "Cooker");
		Test.Assert(cooker != null, "the pipeline domain type is bound too");
		Test.Assert(cooker.Get("domain").AsString() == "Pipeline");
		Test.Assert(!cooker.Get("inPlayer").AsBool());
	}

	[Test]
	public static void ScriptApiNarrowsByLanguageAndAnUnknownLanguageIsAToolError()
	{
		AngelScriptBackend.Register();
		let surface = scope ScriptSurface();
		FixtureSurface.Populate(surface);
		let server = scope McpServer();
		ScriptTools.Register(server, surface);

		let narrowed = CallOk(server, "script_api", Arg("language", "angelscript"));
		defer delete narrowed;
		Test.Assert(narrowed.Get("languages").Count == 1);
		Test.Assert(narrowed.Get("languages").At(0).Get("language").AsString() == "angelscript");

		let bogus = CallResponse(server, "script_api", Arg("language", "cobol"));
		defer delete bogus;
		Test.Assert(bogus.Get("result").Get("isError").AsBool());
		let text = bogus.Get("result").Get("content").At(0).Get("text").AsString();
		Test.Assert(text.Contains("cobol"));
	}

	/// script_declarations writes the backend's declarations file into the folder: an external
	/// editor completes and checks scripts from it, and nothing wrote one.
	[Test]
	public static void ScriptDeclarationsWritesTheBackendsDeclarationsFile()
	{
		AngelScriptBackend.Register();
		let surface = scope ScriptSurface();
		FixtureSurface.Populate(surface);
		let server = scope McpServer();
		ScriptTools.Register(server, surface);
		server.Paths.AddFolder(Sedulous.Core.IO.GetCurrentDirectory(.. scope .())); // the test's scratch folder, as a host allows its own
		let folder = "scratch_script_declarations";
		Sedulous.Core.IO.RemoveDirectoryRecursive(folder);
		Test.Assert(Sedulous.Core.IO.CreateDirectory(folder));
		defer Sedulous.Core.IO.RemoveDirectoryRecursive(folder);

		let arguments = Arg("directory", folder);
		arguments.Set("language", JsonValue.MakeString("angelscript"));
		let written = CallOk(server, "script_declarations", arguments);
		defer delete written;
		Test.Assert(written.Get("files").Count == 1);
		let path = written.Get("files").At(0).Get("path").AsString();
		Test.Assert(path.EndsWith("as.predefined"));
		let bytes = scope System.Collections.List<uint8>();
		Test.Assert(Sedulous.Core.IO.ReadFile(path, bytes) case .Ok);
		let text = StringView((char8*)bytes.Ptr, bytes.Count);
		Test.Assert(text.Contains("class Thing"), "a bound class");
		Test.Assert(text.Contains("class Float3"), "a math value");
		Test.Assert(text.Contains(" property;"), "an accessor reads as a property");

		let refused = CallResponse(server, "script_declarations", Arg("directory", "no_such_folder_here"));
		defer delete refused;
		Test.Assert((refused.Get("error") != null) || refused.Get("result").Get("isError").AsBool());

		// A folder outside what the host allows is refused before anything is written there.
		let outside = CallResponse(server, "script_declarations", Arg("directory", ".."));
		defer delete outside;
		Test.Assert(outside.Get("result").Get("isError").AsBool());
		Test.Assert(outside.Get("result").Get("content").At(0).Get("text").AsString().Contains("outside the folders this host allows"));
	}
}
