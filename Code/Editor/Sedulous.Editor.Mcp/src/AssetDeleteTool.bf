using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Mcp;

/// asset_delete: the Assets browser's Delete for an agent. Refused while anything still uses
/// the asset, by the same scan asset_uses runs, unless `force` says the breakage is meant;
/// the host does the rest (the editor closes the asset's page and waits out a cook).
static class AssetDeleteTool
{
	private class Context
	{
		public ProjectSession Session;
		public BuilderRegistry Builders;
		public IProjectOperations Operations;
	}

	public static void Register(McpServer server, ProjectSession session, BuilderRegistry builders,
		IProjectOperations operations)
	{
		let context = new Context();
		context.Session = session;
		context.Builders = builders;
		context.Operations = operations;

		let schema = scope SchemaBuilder();
		schema.Str("guid", "the source asset to delete", true);
		schema.Boolean("force", "delete even though something still uses it, leaving those references dangling (default false)");
		server.RegisterTool("asset_delete",
			"Delete a source asset, as the editor's Assets browser does: its stored object and data files go, and the next cook sweeps its cooked product. The original file an import copied under Sources/ is NOT removed - it is an ordinary file. Refused while other assets or the project settings use it (the refusal names them, as asset_uses would); `force` deletes anyway. In the editor its open page closes first, and a running cook is waited out. Returns the deleted asset's identity.",
			schema.Build(), .Deletes,
			new (call, arguments, outResult, outError) => Delete(context, call, arguments, outResult, outError),
			context);
	}

	private static ToolOutcome Delete(Context context, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		if (!McpTools.ParseGuid(McpTools.ArgString(arguments, "guid", .. scope .()), outError, let id))
			return false;
		let instance = session.Project.SourceDb.GetInstance(id);
		if (instance == null)
		{
			// A re-entered call whose delete already landed finds nothing: that is its success.
			if (call.State != null)
				return true;
			outError.AppendF("no asset with guid {} in the open project", id);
			return false;
		}

		// Checked once, on the first entry; a call waiting out a cook does not rescan.
		if ((call.State == null) && !McpTools.ArgBool(arguments, "force"))
		{
			let users = scope List<String>();
			let settings = scope List<String>();
			defer { ClearAndDeleteItems(users); ClearAndDeleteItems(settings); }
			AssetUsesTool.DirectUsers(session, context.Builders, id, users, settings);
			if (!users.IsEmpty || !settings.IsEmpty)
			{
				outError.AppendF("refused - '{}' is still used", instance.Name);
				if (!users.IsEmpty)
				{
					outError.Append(" by ");
					for (int i < users.Count)
						outError.AppendF("{}'{}'", (i > 0) ? ", " : "", users[i]);
				}
				if (!settings.IsEmpty)
				{
					outError.Append(users.IsEmpty ? " by the project settings: " : "; and by the project settings: ");
					for (int i < settings.Count)
						outError.AppendF("{}{}", (i > 0) ? ", " : "", settings[i]);
				}
				outError.Append(". Change those first, or pass force to delete anyway. Nothing was deleted.");
				return false;
			}
		}

		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("type", JsonValue.MakeString(instance.TypeName));
		switch (context.Operations.Delete(call, id, outError))
		{
		case .Failed: return .Failed;
		case .NotYet: return .NotFinished;
		case .Finished:
		}
		outResult.Set("deleted", JsonValue.MakeBool(true));
		return true;
	}
}
