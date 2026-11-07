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
	/// Open (or focus) the page over a source file of the project's own code (EditorPages.OpenFile),
	/// the path relative to the project or absolute. Null with why in the error. Unset: none opens.
	/// Owned.
	public delegate EditorPage(StringView path, String outError) OpenFile ~ delete _;
	/// Close a page for good, panel and all. Owned.
	public delegate void(EditorPage page) ClosePage ~ delete _;
	/// Whether a project is open (null: one is); page_open refuses without one. Owned.
	public delegate bool() HasProject ~ delete _;
}

/// The MCP tools over the editor's open PAGES, what only the editor host can serve: page_list,
/// page_open, page_reload and page_close, over the context's page list and the actions the
/// application owns (opening a source asset's page or a source file's, closing a page with its
/// panel). A page is named by its asset's guid, or a source file's page (SourceFilePage, which
/// edits no asset) by its file. Reload and close are refused while the page has unsaved changes
/// unless the agent says so explicitly (force, discard): a tool never waits for a human, so the
/// destructive decision is an argument, and the refusal tells the agent to ask the user.
static class EditorPageTools
{
	/// How many tools Register registers; a tripwire like EngineTools.cEngineToolCount.
	public const int cPageToolCount = 4;

	/// OWNERSHIP of the seams transfers; the first tool holds them for all four.
	public static void Register(McpServer server, PageToolSeams seams)
	{
		let listSchema = scope SchemaBuilder();
		server.RegisterTool("page_list",
			"The pages the editor has open: each one's asset guid, title, whether it has unsaved changes, and which is active; a source file's page (a .bf of the project's code) has no asset, and gives its `file` instead. A page is the live, editable view of an asset; the scene and prefab tools read and write the asset's SOURCE, which a page reloads from disk only through page_reload.",
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
		openSchema.Str("guid", "the source asset to open (or give `file`)");
		openSchema.Str("file", "a source file of the project's own code to open instead of an asset: a path under its Code/ or Plugins/, relative to the project (as project_build's diagnostics name it) or absolute");
		openSchema.Integer("line", "with `file`, the line to take the code to, from 1 (a diagnostic's line)");
		openSchema.Integer("column", "with `line`, the column, from 1");
		server.RegisterTool("page_open",
			"Open the page for a source asset (by guid), or for a source file of the project's own code (by `file`, a .bf under Code/ or Plugins/, edited as text and saved back to the file with action_execute file.save), and make it the active one, or focus it when it is already open; with `line` (and `column`) the code goes there, for the user to see. Returns the page's identity ({guid, title, dirty, active}; a source file's page has a null guid and its `file`). Fails when no asset has that guid or its type has no page, or for a file outside the project's Code/ and Plugins/ or not there.",
			openSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				if ((seams.HasProject != null) && !seams.HasProject())
				{
					outError.Append(McpTools.cNoProject);
					return false;
				}
				let path = McpTools.ArgString(arguments, "file", .. scope .());
				if (!path.IsEmpty)
				{
					if (McpTools.ArgString(arguments, "guid", .. scope .()).Length > 0)
					{
						outError.Append("give `guid` or `file`, not both");
						return false;
					}
					let filePage = (seams.OpenFile != null) ? seams.OpenFile(path, outError) : null;
					if (filePage == null)
					{
						if (outError.IsEmpty)
							outError.Append("this editor opens no source file");
						return false;
					}
					let line = (int)McpTools.ArgNumber(arguments, "line", 0);
					if (line > 0)
					{
						if (let sourcePage = filePage as SourceFilePage)
							sourcePage.GoTo(line, (int)McpTools.ArgNumber(arguments, "column", 0));
					}
					seams.Context.RevealPage(filePage);
					CopyIdentity(seams.Context, filePage, outResult);
					return true;
				}
				let text = McpTools.ArgString(arguments, "guid", .. scope .());
				if (text.IsEmpty)
				{
					outError.Append("give the `guid` of a source asset, or the `file` of a source file");
					return false;
				}
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
				seams.Context.RevealPage(page); // to front: a background tab's viewport never renders
				CopyIdentity(seams.Context, page, outResult);
				return true;
			});

		let reloadSchema = scope SchemaBuilder();
		reloadSchema.Str("guid", "the open page's asset (or give `file`)");
		reloadSchema.Str("file", "the open source file's page, by its file as page_list names it");
		reloadSchema.Boolean("force", "discard the page's unsaved changes (default false)");
		server.RegisterTool("page_reload",
			"Reload an open page from its asset's source on disk, after scene_write or prefab_write changed what the page shows, or a source file's page from its file. The page stays open and refreshes in place (its undo history goes). REFUSED while the page has unsaved changes unless `force` is true, which discards them first. Returns the page's identity.",
			reloadSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let page = NamedPage(seams.Context, arguments, outError);
				if (page == null)
					return false;
				if (page.IsDirty)
				{
					if (!McpTools.ArgBool(arguments, "force"))
					{
						UnsavedChangesRefusal(page, "force", outError);
						return false;
					}
					// The page's own discard, then the refresh a clean page takes: a page
					// refreshes only when clean (an apply to prefab or a re-import leaves a
					// dirty page alone with a warning), so the discard comes first.
					page.DiscardChanges();
				}
				page.OnAssetExternallyModified();
				CopyIdentity(seams.Context, page, outResult);
				return true;
			});

		let closeSchema = scope SchemaBuilder();
		closeSchema.Str("guid", "the open page's asset (or give `file`)");
		closeSchema.Str("file", "the open source file's page, by its file as page_list names it");
		closeSchema.Boolean("discard", "drop the page's unsaved changes (default false)");
		server.RegisterTool("page_close",
			"Close an open page, named by its asset's guid or a source file's page by its file. REFUSED while it has unsaved changes unless `discard` is true, which drops them. Returns {closed, guid} or {closed, file}.",
			closeSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let page = NamedPage(seams.Context, arguments, outError);
				if (page == null)
					return false;
				if (page.IsDirty && !McpTools.ArgBool(arguments, "discard"))
				{
					UnsavedChangesRefusal(page, "discard", outError);
					return false;
				}
				outResult.Set("closed", JsonValue.MakeBool(true));
				if (let sourcePage = page as SourceFilePage)
					outResult.Set("file", JsonValue.MakeString(sourcePage.ProjectFile));
				else
					outResult.Set("guid", JsonValue.MakeString(McpTools.ArgString(arguments, "guid", .. scope .())));
				seams.ClosePage(page);
				return true;
			});
	}

	/// The open page the arguments name: by `file`, a source file's page; else by `guid`. Null,
	/// with why in `outError`, when the name is malformed or no open page has it.
	private static EditorPage NamedPage(EditorContext context, JsonValue arguments, String outError)
	{
		let file = McpTools.ArgString(arguments, "file", .. scope .());
		if (!file.IsEmpty)
		{
			let page = FindOpenFile(context, file);
			if (page == null)
				outError.AppendF("no open page for file '{}' (page_list shows the open ones; page_open opens one)", file);
			return page;
		}
		let text = McpTools.ArgString(arguments, "guid", .. scope .());
		Guid id;
		if (!McpTools.ParseGuid(text, outError, out id))
			return null;
		let page = FindOpenPage(context, id);
		if (page == null)
			outError.AppendF("no open page for guid '{}' (page_list shows the open ones; page_open opens one)", text);
		return page;
	}

	/// The open source file's page for `file`, as page_list names it (relative to the project) or
	/// as an absolute path; null with none.
	private static EditorPage FindOpenFile(EditorContext context, StringView file)
	{
		let named = scope String(file);
		named.Replace('\\', '/');
		for (let page in context.OpenPages)
		{
			if (let sourcePage = page as SourceFilePage)
			{
				if ((sourcePage.ProjectFile == named) || (sourcePage.FilePath == named))
					return page;
			}
		}
		return null;
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
		// A source file's page edits no asset: its file names it.
		if (let sourcePage = page as SourceFilePage)
		{
			outIdentity.Set("guid", JsonValue.MakeNull());
			outIdentity.Set("file", JsonValue.MakeString(sourcePage.ProjectFile));
		}
		else
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
