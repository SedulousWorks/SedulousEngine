using System;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// The live editor the page tools see. The context lists the pages; the application supplies
/// the two actions that involve a page's panel, which the context does not own.
class PageToolSeams
{
	public EditorContext Context = null;
	/// Open (or focus) the page for a source asset. Null when there is no such asset, or no
	/// page for its type; the reason is in the log. Owned.
	public delegate EditorPage(Guid id) OpenPage ~ delete _;
	/// Close a page for good, panel and all. Owned.
	public delegate void(EditorPage page) ClosePage ~ delete _;
}

/// The MCP tools over the editor's open PAGES, what only the editor host can serve: page_list,
/// page_open, page_reload and page_close, over the context's page list and the two actions
/// the application owns (opening a source asset's page, closing a page with its panel). Reload
/// and close are refused while the page has unsaved changes unless the agent says so
/// explicitly (force, discard): a tool never waits for a human, so the destructive decision
/// is an argument, and the refusal tells the agent to ask the user.
static class EditorPageTools
{
	/// How many tools Register registers; a tripwire like EngineTools.cEngineToolCount.
	public const int cPageToolCount = 4;

	/// OWNERSHIP of the seams transfers; the first tool holds them for all four.
	public static void Register(McpServer server, PageToolSeams seams)
	{
		let listSchema = scope SchemaBuilder();
		server.RegisterTool("page_list",
			"The pages the editor has open: each one's asset guid, title, whether it has unsaved changes, and which is active. A page is the live, editable view of an asset; the scene and prefab tools read and write the asset's SOURCE, which a page reloads from disk only through page_reload.",
			listSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let pages = JsonValue.MakeArray();
				for (let page in seams.Context.OpenPages)
					pages.Add(Identity(seams.Context, page));
				outResult.Set("pages", pages);
				return true;
			}, seams);

		let openSchema = scope SchemaBuilder();
		openSchema.Str("guid", "the source asset to open", true);
		server.RegisterTool("page_open",
			"Open the page for a source asset (by guid) and make it the active one, or focus it when it is already open. Returns the page's identity. Fails when no asset has that guid or its type has no page.",
			openSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let text = McpTools.ArgString(arguments, "guid", .. scope .());
				Guid id;
				if (!McpTools.ParseGuid(text, outError, out id))
					return false;
				var page = FindOpenPage(seams.Context, id);
				if (page == null)
				{
					page = seams.OpenPage(id);
					if (page == null)
					{
						outError.AppendF("no asset with guid '{}', or its type has no page (see log_read, category Editor)", text);
						return false;
					}
				}
				seams.Context.SetActivePage(page);
				CopyIdentity(seams.Context, page, outResult);
				return true;
			});

		let reloadSchema = scope SchemaBuilder();
		reloadSchema.Str("guid", "the open page's asset", true);
		reloadSchema.Boolean("force", "discard the page's unsaved changes (default false)");
		server.RegisterTool("page_reload",
			"Reload an open page from its asset's source on disk, after scene_write or prefab_write changed what the page shows. REFUSED while the page has unsaved changes unless `force` is true, which discards them. Returns the reopened page's identity.",
			reloadSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let text = McpTools.ArgString(arguments, "guid", .. scope .());
				Guid id;
				if (!McpTools.ParseGuid(text, outError, out id))
					return false;
				let page = FindOpenPage(seams.Context, id);
				if (page == null)
				{
					outError.AppendF("no open page for guid '{}' (page_list shows the open ones; page_open opens one)", text);
					return false;
				}
				if (page.IsDirty && !McpTools.ArgBool(arguments, "force"))
				{
					UnsavedChangesRefusal(page, "force", outError);
					return false;
				}
				seams.ClosePage(page);
				let reopened = seams.OpenPage(id);
				if (reopened == null)
				{
					outError.AppendF("the page closed but its asset '{}' could not be reopened (see log_read, category Editor)", text);
					return false;
				}
				seams.Context.SetActivePage(reopened);
				CopyIdentity(seams.Context, reopened, outResult);
				return true;
			});

		let closeSchema = scope SchemaBuilder();
		closeSchema.Str("guid", "the open page's asset", true);
		closeSchema.Boolean("discard", "drop the page's unsaved changes (default false)");
		server.RegisterTool("page_close",
			"Close an open page. REFUSED while it has unsaved changes unless `discard` is true, which drops them. Returns {closed, guid}.",
			closeSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let text = McpTools.ArgString(arguments, "guid", .. scope .());
				Guid id;
				if (!McpTools.ParseGuid(text, outError, out id))
					return false;
				let page = FindOpenPage(seams.Context, id);
				if (page == null)
				{
					outError.AppendF("no open page for guid '{}'", text);
					return false;
				}
				if (page.IsDirty && !McpTools.ArgBool(arguments, "discard"))
				{
					UnsavedChangesRefusal(page, "discard", outError);
					return false;
				}
				seams.ClosePage(page);
				outResult.Set("closed", JsonValue.MakeBool(true));
				outResult.Set("guid", JsonValue.MakeString(text));
				return true;
			});
	}

	/// {guid, title, dirty, active}, OWNED by the caller.
	private static JsonValue Identity(EditorContext context, EditorPage page)
	{
		let identity = JsonValue.MakeObject();
		CopyIdentity(context, page, identity);
		return identity;
	}

	private static void CopyIdentity(EditorContext context, EditorPage page, JsonValue outIdentity)
	{
		outIdentity.Set("guid", McpTools.GuidToJson(page.InstanceId));
		outIdentity.Set("title", JsonValue.MakeString(page.Title));
		outIdentity.Set("dirty", JsonValue.MakeBool(page.IsDirty));
		outIdentity.Set("active", JsonValue.MakeBool(context.ActivePage == page));
	}

	private static EditorPage FindOpenPage(EditorContext context, Guid id)
	{
		for (let page in context.OpenPages)
			if (page.InstanceId == id)
				return page;
		return null;
	}

	private static void UnsavedChangesRefusal(EditorPage page, StringView argument, String outError)
	{
		outError.AppendF("page '{}' has unsaved changes - ask the user to save or discard them, or pass {}:true to discard them yourself", page.Title, argument);
	}
}
