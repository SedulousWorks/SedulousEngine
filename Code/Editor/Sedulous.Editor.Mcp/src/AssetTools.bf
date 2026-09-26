using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Editor.Mcp;

/// asset_list / asset_info: the open project's content databases, read.
static class AssetTools
{
	private static StringView[2] cDatabases = .("source", "cooked");

	public static void Register(McpServer server, ProjectSession session)
	{
		let listSchema = scope SchemaBuilder();
		listSchema.Enum("database", cDatabases, "which content database (default: source)");
		server.RegisterTool("asset_list",
			"List the assets in the open project's content database (guid, name, type, group).",
			listSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => List(session, arguments, outResult, outError));

		let infoSchema = scope SchemaBuilder();
		infoSchema.Str("guid", "the asset guid (canonical 8-4-4-4-12 form)", true);
		infoSchema.Enum("database", cDatabases, "which content database (default: source)");
		server.RegisterTool("asset_info",
			"Details about one asset in the open project, by guid.",
			infoSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Info(session, arguments, outResult, outError));
	}

	private static ContentDatabase PickDb(ProjectSession session, JsonValue arguments)
	{
		let which = McpTools.ArgString(arguments, "database", .. scope .());
		return (which == "cooked") ? session.Project.CookedDb : session.Project.SourceDb;
	}

	private static bool List(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let assets = JsonValue.MakeArray();
		Collect(PickDb(session, arguments).RootGroup, scope String(), assets);
		outResult.Set("count", JsonValue.MakeNumber((double)assets.Count));
		outResult.Set("assets", assets);
		return true;
	}

	/// Every instance under `group`, depth first, as {guid, name, type, group?}.
	private static void Collect(Group group, String path, JsonValue outAssets)
	{
		for (let instance in group.Instances)
		{
			let entry = McpTools.InstanceToJson(instance);
			if (!path.IsEmpty)
				entry.Set("group", JsonValue.MakeString(path));
			outAssets.Add(entry);
		}
		for (let child in group.Groups)
		{
			let childPath = scope String(path);
			if (!childPath.IsEmpty)
				childPath.Append('/');
			childPath.Append(child.Name);
			Collect(child, childPath, outAssets);
		}
	}

	private static bool Info(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let guidText = McpTools.ArgString(arguments, "guid", .. scope .());
		if (!McpTools.ParseGuid(guidText, outError, let id))
			return false;
		let instance = PickDb(session, arguments).GetInstance(id);
		if (instance == null)
		{
			outError.AppendF("no asset with guid '{}'", guidText);
			return false;
		}
		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("type", JsonValue.MakeString(instance.TypeName));
		outResult.Set("group", JsonValue.MakeString(McpTools.GroupPath(instance.OwningGroup, .. scope .())));
		return true;
	}
}
