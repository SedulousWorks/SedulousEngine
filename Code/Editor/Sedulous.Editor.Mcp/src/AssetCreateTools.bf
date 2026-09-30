using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Mcp;

/// asset_creators / asset_create: every asset kind the editor's File > New makes, made by an
/// agent. The creators are the pipeline's (PipelineRegistration.RegisterAllCreators) and the
/// host's registry outlives the server; the work runs through the host's IProjectOperations,
/// so the editor's creation also requests the cook and sets a first scene as the default.
static class AssetCreateTools
{
	private class Context
	{
		public ProjectSession Session;
		public AssetCreatorRegistry Creators;
		public IProjectOperations Operations;
	}

	public static void Register(McpServer server, ProjectSession session, AssetCreatorRegistry creators,
		IProjectOperations operations)
	{
		let context = new Context();
		context.Session = session;
		context.Creators = creators;
		context.Operations = operations;

		server.RegisterTool("asset_creators",
			"Every kind of asset asset_create can make (what the editor's File > New offers): each creator's `label`, its menu `category`, the `type` it creates, and the `defaultGroup` its assets land in when no group is given. Imported kinds (textures, models, audio clips, fonts) come from asset_import instead.",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => List(context, arguments, outResult, outError),
			context); // the first tool owns the shared context

		let schema = scope SchemaBuilder();
		schema.Str("creator", "the creator's label (asset_creators lists them), case-insensitive");
		schema.Str("type", "or the asset type's full name, when one creator makes it");
		schema.Str("name", "the asset's name, exact: a name already taken in the group is refused (default: the creator's own, made unique)");
		schema.Str("group", "source-DB group path, slash joined, created when missing (default: the creator's defaultGroup)");
		server.RegisterTool("asset_create",
			"""
			Create a new asset the way the editor's File > New does: a fresh instance seeded with its defaults (an input map with the default sets, a PBR material from the preset, a scene with a sun, a script class from its tier's starter). Name the creator by `creator` label or by `type`. Returns {guid, name, type, path}; read the asset with asset_info, edit it with the scene tools or its page, and call asset_cook before a runtime needs it (the editor host requests the cook itself).
			""",
			schema.Build(), .Creates,
			new (call, arguments, outResult, outError) => Create(context, call, arguments, outResult, outError));
	}

	private static ToolOutcome List(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let items = JsonValue.MakeArray();
		for (let creator in context.Creators)
		{
			let item = JsonValue.MakeObject();
			item.Set("label", JsonValue.MakeString(creator.Label));
			item.Set("category", JsonValue.MakeString(creator.Category));
			item.Set("type", JsonValue.MakeString(creator.TypeName));
			item.Set("defaultGroup", JsonValue.MakeString(creator.DefaultGroup));
			items.Add(item);
		}
		outResult.Set("count", JsonValue.MakeNumber((double)context.Creators.Count));
		outResult.Set("creators", items);
		return true;
	}

	private static ToolOutcome Create(Context context, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!context.Session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return .Failed;
		}
		let label = McpTools.ArgString(arguments, "creator", .. scope .());
		let type = McpTools.ArgString(arguments, "type", .. scope .());
		AssetCreator creator = null;
		if (!label.IsEmpty)
		{
			creator = context.Creators.FindByLabel(label);
			if (creator == null)
			{
				outError.AppendF("no creator labelled '{}'; asset_creators lists them", label);
				return .Failed;
			}
		}
		else if (!type.IsEmpty)
		{
			creator = context.Creators.FindByType(type);
			if (creator == null)
			{
				outError.AppendF("no single creator makes '{}' (none, or several: pass `creator` by label); asset_creators lists them", type);
				return .Failed;
			}
		}
		else
		{
			outError.Append("pass `creator` (a label) or `type`");
			return .Failed;
		}

		CreateRequest request = .();
		request.Creator = creator;
		request.GroupPath = McpTools.ArgString(arguments, "group", .. scope .());
		request.Name = McpTools.ArgString(arguments, "name", .. scope .());
		let done = scope CreateOutcome();
		switch (context.Operations.Create(call, request, done, outError))
		{
		case .Failed: return .Failed;
		case .NotYet: return .NotFinished; // the host holds creation while a cook reads the databases
		case .Finished:
		}
		outResult.Set("guid", McpTools.GuidToJson(done.Id));
		outResult.Set("name", JsonValue.MakeString(done.Name));
		outResult.Set("type", JsonValue.MakeString(done.Type));
		outResult.Set("path", JsonValue.MakeString(done.Path));
		outResult.Set("creator", JsonValue.MakeString(creator.Label));
		return true;
	}
}
