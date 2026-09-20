using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Script.Pipeline;
using Sedulous.Script.Resource;

namespace Sedulous.Editor.Mcp;

/// script_validate: compiles an in memory source through the SAME per language cook the
/// asset pipeline uses, so what validates is exactly what would cook. Project independent.
/// Returns the compile problems, and on success what the engine harvested: the class, the
/// handlers, the properties, whether it starts coroutines, so the agent sees what the
/// engine RECOGNISED. Compile only: a call against the engine API is not type checked
/// beyond what the language itself checks, which the description says.
static class ScriptValidateTool
{
	/// The languages the host's cooks claim, read at registration for the schema's enum.
	public static void LanguageChoices(List<String> outLanguages) => ScriptLanguageCooks.CollectLanguages(outLanguages);

	public static void Register(McpServer server)
	{
		let languages = scope List<String>();
		defer { ClearAndDeleteItems(languages); }
		LanguageChoices(languages);
		let choices = scope List<StringView>();
		for (let language in languages)
			choices.Add(language);

		let schema = scope SchemaBuilder();
		schema.Str("source", "the full script source text", true);
		schema.Enum("language", choices, "the script backend to compile against", true);
		schema.Str("name", "a display name for error messages (e.g. the intended file name; default 'script')");
		schema.Str("className", "the class to harvest (default: the first class the source declares)");
		server.RegisterTool("script_validate",
			"""
			COMPILE-CHECK a script source against a backend without saving: the exact compile the asset cook would run. Returns compile errors with line numbers, and on success the harvested metadata (className, handlers, properties, usesCoroutines) - confirm the engine recognized what you wrote. Use as the validation loop while authoring scripts, BEFORE creating the asset. Limits: compile only - a misspelled engine method is a compile error only where the language sees the call; check signatures with script_api.
			""",
			schema.Build(),
			new (arguments, outResult, outError) => Validate(arguments, outResult, outError));
	}

	private static bool Validate(JsonValue arguments, JsonValue outResult, String outError)
	{
		let language = McpTools.ArgString(arguments, "language", .. scope .());
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		if (name.IsEmpty)
			name.Set("script");
		let cook = ScriptLanguageCooks.Find(language);
		if (cook == null)
		{
			outError.AppendF("the '{}' backend is not available in this host (its cook did not register - the backend may be disabled in this build)", language);
			return false;
		}
		let source = McpTools.ArgString(arguments, "source", .. scope .());
		let className = McpTools.ArgString(arguments, "className", .. scope .());
		let record = scope ScriptClassSource();
		let problems = scope List<String>();
		defer { ClearAndDeleteItems(problems); }
		let ok = cook.Cook(source, name, className, record, problems);

		let errors = JsonValue.MakeArray();
		for (let problem in problems)
		{
			// The compiler's "name(line,col): error: text" is split so an agent reads the
			// line without parsing; a problem in another shape keeps line 0.
			let entry = JsonValue.MakeObject();
			entry.Set("line", JsonValue.MakeNumber((double)LineOf(problem)));
			entry.Set("message", JsonValue.MakeString(problem));
			errors.Add(entry);
		}
		outResult.Set("valid", JsonValue.MakeBool(ok));
		outResult.Set("errors", errors);
		if (ok)
		{
			outResult.Set("className", JsonValue.MakeString(record.ClassName));
			let handlers = JsonValue.MakeArray();
			for (let handler in record.Handlers)
				handlers.Add(JsonValue.MakeString(handler));
			outResult.Set("handlers", handlers);
			let properties = JsonValue.MakeArray();
			for (let property in record.Properties)
				properties.Add(JsonValue.MakeString(property.Name));
			outResult.Set("properties", properties);
			outResult.Set("usesCoroutines", JsonValue.MakeBool(record.UsesCoroutines));
		}
		// The honesty marker, mirroring scene_validate: what this validation covers.
		outResult.Set("checkLevel", JsonValue.MakeString("compile"));
		return true;
	}

	/// The line in "name(line,col): ..." or "name (line, col) : ...", 0 when absent.
	public static int LineOf(StringView problem)
	{
		let open = problem.IndexOf('(');
		if (open < 0)
			return 0;
		int line = 0;
		bool any = false;
		for (int i = open + 1; i < problem.Length; i++)
		{
			let c = problem[i];
			if (c.IsDigit)
			{
				line = line * 10 + (c - '0');
				any = true;
			}
			else if (c == ' ')
			{
				continue;
			}
			else
			{
				break;
			}
		}
		return any ? line : 0;
	}
}
