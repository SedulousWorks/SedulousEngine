using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;

namespace Sedulous.Editor.Mcp;

/// asset_rename: the Assets browser's Rename for an agent. The asset keeps its guid, so everything
/// that references it still does; its cooked product and the default scene's path mirror follow
/// (EditorProject.RenameAsset). The host runs it through IProjectOperations.Rename (the editor
/// waits out a cook).
static class AssetRenameTool
{
	private class Context
	{
		public ProjectSession Session;
		public IProjectOperations Operations;
	}

	public static void Register(McpServer server, ProjectSession session, IProjectOperations operations)
	{
		let context = new Context();
		context.Session = session;
		context.Operations = operations;

		let schema = scope SchemaBuilder();
		schema.Str("guid", "the source asset to rename", true);
		schema.Str("name", "its new name, within the same group", true);
		server.RegisterTool("asset_rename",
			"Rename a source asset within its group, as the editor's Assets browser does. It keeps its guid, so whatever references it still does; its cooked product and the project's default scene path follow. Refused for a name a file cannot take (empty, any of /\\:*?\"<>|, a space at an end, a dot at its end) or one another asset in the group has. In the editor a running cook is waited out. Returns {guid, name, path}.",
			schema.Build(), .Adjusts,
			new (call, arguments, outResult, outError) => Rename(context, call, arguments, outResult, outError),
			context);
	}

	private static ToolOutcome Rename(Context context, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		if (!McpTools.ParseGuid(McpTools.ArgString(arguments, "guid", .. scope .()), outError, let id))
			return false;
		let name = McpTools.ArgString(arguments, "name", .. scope .());
		switch (context.Operations.Rename(call, id, name, outError))
		{
		case .Failed: return .Failed;
		case .NotYet: return .NotFinished; // held while a cook reads the databases
		case .Finished:
		}
		let instance = session.Project.SourceDb.GetInstance(id);
		outResult.Set("guid", McpTools.GuidToJson(id));
		outResult.Set("name", JsonValue.MakeString((instance != null) ? instance.Name : name));
		outResult.Set("path", JsonValue.MakeString((instance != null) ? instance.GetPath(.. scope .()) : ""));
		return true;
	}
}
