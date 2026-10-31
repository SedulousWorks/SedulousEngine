using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.GUI;
using Sedulous.GUI.Pipeline;

namespace Sedulous.Editor.Mcp;

/// gui_validate: checks the engine GUI's markup (a `.xml` document) or a sheet (`.css`) WITHOUT
/// saving it, through the check its cook runs (the markup loader's or the CSS parser's diagnostics:
/// what was dropped a warning, markup that does not build an error), so an agent writing a game's
/// screens loops on it as on script_validate and shader_validate. Returns each diagnostic with its
/// line, and the asset guids the text names (`{guid}`), each a dependency of its cook. Project
/// independent.
static class GuiValidateTool
{
	public static void Register(McpServer server)
	{
		let schema = scope SchemaBuilder();
		schema.Str("source", "the full text", true);
		StringView[2] kinds = .("document", "sheet");
		schema.Enum("kind", kinds, "document (.xml) or sheet (.css)", true);
		server.RegisterTool("gui_validate",
			"""
			CHECK the engine GUI's text without saving: a `document` (.xml markup) or a `sheet` (.css), the exact check its cook runs. Returns `valid` (false only when markup does not build; a sheet always reads), each diagnostic {level: error | warning, line (from 1, 0 when not known), message} (what the loader or the parser dropped, a property name nothing takes), and `references`, the asset guids the text names ({guid}: images, fonts, sheets, documents). Use as the loop while writing a game's screens, then edit the asset's linked source file and cook; the editor's page for it previews it live.
			""",
			schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Validate(arguments, outResult, outError));
	}

	private static bool Validate(JsonValue arguments, JsonValue outResult, String outError)
	{
		let source = McpTools.ArgString(arguments, "source", .. scope .());
		let document = McpTools.ArgString(arguments, "kind", .. scope .()) == "document";
		let found = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(found); }
		var valid = true;
		if (document)
			valid = GuiPipeline.ValidateDocument(source, found);
		else
			GuiPipeline.ValidateStyleSheet(source, found);

		let diagnostics = JsonValue.MakeArray();
		for (let d in found)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("level", JsonValue.MakeString((d.Level == .Error) ? "error" : "warning"));
			entry.Set("line", JsonValue.MakeNumber(d.Line));
			entry.Set("message", JsonValue.MakeString(d.Message));
			diagnostics.Add(entry);
		}
		let references = JsonValue.MakeArray();
		let ids = scope List<Guid>();
		GuiPipeline.FindGuidReferences(source, ids);
		for (let id in ids)
			references.Add(JsonValue.MakeString(id.ToString(.. scope .())));
		outResult.Set("valid", JsonValue.MakeBool(valid));
		outResult.Set("diagnostics", diagnostics);
		outResult.Set("references", references);
		return true;
	}
}
