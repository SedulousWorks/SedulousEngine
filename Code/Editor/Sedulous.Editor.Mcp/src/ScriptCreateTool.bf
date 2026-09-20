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
			schema.Build(),
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

		let group = McpTools.ResolveGroupPath(session.Project.SourceDb.RootGroup,
			McpTools.ArgString(arguments, "group", .. scope .()));
		let name = group.UniqueInstanceName(requestedName, .. scope .());
		let fileName = scope $"{name}.{suffix}";

		let starter = scope String();
		cook.NewAssetTemplate(tier, starter);
		let path = PathJoin(session.Project.SourcesRoot(.. scope .()), fileName, .. scope .());
		if (WriteFile(path, .((uint8*)starter.Ptr, starter.Length)) case .Err)
		{
			outError.AppendF("could not write the source file '{}'", path);
			return false;
		}

		let instance = group.CreateInstance(name, typeof(ScriptClassAsset).GetFullName(.. scope .()));
		if (instance == null)
		{
			outError.AppendF("could not create the asset '{}'", name);
			return false;
		}
		let asset = scope ScriptClassAsset();
		asset.FileName.Set(fileName);
		asset.Language.Set(language);
		if (instance.WriteObject(asset) case .Err)
		{
			outError.AppendF("could not write the asset envelope for '{}'", name);
			return false;
		}

		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(name));
		outResult.Set("language", JsonValue.MakeString(language));
		outResult.Set("tier", JsonValue.MakeString(tier == .Level ? "level" : (tier == .Game ? "game" : "behavior")));
		outResult.Set("sourceFile", JsonValue.MakeString(path));
		outResult.Set("fileName", JsonValue.MakeString(fileName));
		return true;
	}
}
