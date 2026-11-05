using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Script.Pipeline;
using Sedulous.Script.Resource;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// script_validate: compiles an in memory source through the SAME per language cook the
/// asset pipeline uses, so what validates is exactly what would cook. Project independent.
/// Returns the compile problems, and on success what the engine harvested: the class, the
/// handlers, the properties, whether it starts coroutines, so the agent sees what the
/// engine RECOGNISED. Compile only: a call against the engine API is not type checked
/// beyond what the language itself checks, which the description says. With a `platform`, the
/// script is also checked against what the open project's plugins leave there: the types of the
/// plugins this host loaded that the project does not enable on it are left out, as an export
/// for that platform checks it.
static class ScriptValidateTool
{
	/// The languages the host's cooks claim, read at registration for the schema's enum.
	public static void LanguageChoices(List<String> outLanguages) => ScriptLanguageCooks.CollectLanguages(outLanguages);

	/// `session` (BORROWED; null: no `platform` check) is the open project's, with its plugins.
	public static void Register(McpServer server, ProjectSession session = null)
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
		schema.Str("platform", "also check it for this platform's plugins (Linux64, Win64, Web); needs an open project");
		server.RegisterTool("script_validate",
			"""
			COMPILE-CHECK a script source against a backend without saving: the exact compile the asset cook would run. Returns compile errors with line numbers, and on success the harvested metadata (className, handlers, properties, usesCoroutines) - confirm the engine recognized what you wrote. Use as the validation loop while authoring scripts, BEFORE creating the asset. Limits: compile only - a misspelled engine method is a compile error only where the language sees the call; check signatures with script_api. With `platform`, also checks it against what the open project's plugins leave there (a plugin the project does not enable on that platform takes its types with it), as an export for it does.
			""",
			schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Validate(session, arguments, outResult, outError));
	}

	private static bool Validate(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		let platform = McpTools.ArgString(arguments, "platform", .. scope .());
		if (!platform.IsEmpty && ((session == null) || !session.IsOpen))
		{
			outError.Append("a `platform` check needs an open project (its plugins)");
			return false;
		}
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
		var ok = cook.Cook(source, name, className, record, problems);
		// Then against the platform's surface, when one is asked for and it lacks plugins.
		let absent = scope String();
		if (ok && !platform.IsEmpty && (session.Plugins != null))
		{
			let hidden = scope List<String>();
			defer { ClearAndDeleteItems!(hidden); }
			ExportPlugins.AbsentPluginTypes(session.Project, session.Plugins, platform, hidden, absent);
			if (!hidden.IsEmpty)
			{
				let views = scope List<StringView>();
				for (let hiddenName in hidden)
					views.Add(hiddenName);
				ok = cook.Check(source, name, scope .(), problems, (Span<StringView>)views);
			}
		}

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
		if (!platform.IsEmpty)
		{
			// The plugins the platform lacks, whose types the check left out.
			outResult.Set("platform", JsonValue.MakeString(platform));
			outResult.Set("absentPlugins", JsonValue.MakeString(absent));
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
