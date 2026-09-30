using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Script.Pipeline;

namespace Sedulous.Editor.Mcp;

/// script_create: the editor's New Asset recipe, headless. The chosen backend's own starter
/// for the tier, never hand written text, goes to Sources/<name>.<ext>, and a script asset
/// envelope names it. The name uniquifies rather than overwrites. The description teaches
/// the loop: edit the FILE, script_validate, asset_cook to make the class attachable.
static class ScriptCreateTool
{
	private static StringView[3] cTiers = .("behavior", "level", "game");

	public static ScriptTier ParseTier(StringView name)
	{
		switch (name)
		{
		case "level": return .Level;
		case "game": return .Game;
		default: return .Behavior;
		}
	}

	public static void Register(McpServer server, ProjectSession session)
	{
		let languages = scope List<String>();
		defer { ClearAndDeleteItems(languages); }
		ScriptValidateTool.LanguageChoices(languages);
		let choices = scope List<StringView>();
		for (let language in languages)
			choices.Add(language);

		let schema = scope SchemaBuilder();
		schema.Str("name", "the asset name (also the source file stem)", true);
		schema.Enum("language", choices, "the script backend", true);
		schema.Enum("tier", cTiers, "which starter to seed (default behavior)");
		schema.Str("group", "source-DB group path to place it in (slash-joined; default root)");
		server.RegisterTool("script_create",
			"""
			Create a new script asset from the backend's starter template: writes Sources/<name>.<ext> with the tier's starter source and creates the script asset referencing it. Tiers: 'behavior' (per-entity, attach via a Script component), 'level' (per-scene, reserved class Level, set on the scene's script settings), 'game' (the run's orchestrator, reserved class Game). Returns the asset guid and the source file path - edit the FILE to write your gameplay code, use script_validate as the loop, then asset_cook to make the class attachable.
			""",
			schema.Build(), .Creates,
			new (arguments, outResult, outError) => Create(session, arguments, outResult, outError));
	}

	private static bool Create(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let requestedName = McpTools.ArgString(arguments, "name", .. scope .());
		if (requestedName.IsEmpty)
		{
			outError.Append("name must not be empty");
			return false;
		}
		let language = McpTools.ArgString(arguments, "language", .. scope .());
		let cook = ScriptLanguageCooks.Find(language);
		let suffix = ScriptLanguageCooks.ExtensionOf(language, .. scope .());
		if ((cook == null) || suffix.IsEmpty)
		{
			outError.AppendF("the '{}' backend is not available in this host (it may be disabled in this build)", language);
			return false;
		}
		let tier = ParseTier(McpTools.ArgString(arguments, "tier", .. scope .()));

		// The same creation File > New and asset_create run: the starter written to Sources/,
		// a behaviour's class named after the asset, the asset pointing at the file.
		let root = session.Project.SourceDb.RootGroup;
		let group = McpTools.ResolveGroupPath(root, McpTools.ArgString(arguments, "group", .. scope .()));
		let sourcesRoot = session.Project.SourcesRoot(.. scope .());
		let instance = ScriptCreators.CreateScript(.(group, root, sourcesRoot, requestedName), language, suffix, tier,
			(tier == .Level) ? "NewLevel" : ((tier == .Game) ? "NewGame" : "NewBehavior"));
		if (instance == null)
		{
			outError.AppendF("could not create '{}': the source file under '{}' or the asset did not write (log_read says which)", requestedName, sourcesRoot);
			return false;
		}
		let name = instance.Name;
		let fileName = scope $"{name}.{suffix}";
		let path = PathJoin(sourcesRoot, fileName, .. scope .());

		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(name));
		outResult.Set("language", JsonValue.MakeString(language));
		outResult.Set("tier", JsonValue.MakeString(tier == .Level ? "level" : (tier == .Game ? "game" : "behavior")));
		outResult.Set("sourceFile", JsonValue.MakeString(path));
		outResult.Set("fileName", JsonValue.MakeString(fileName));
		return true;
	}
}
