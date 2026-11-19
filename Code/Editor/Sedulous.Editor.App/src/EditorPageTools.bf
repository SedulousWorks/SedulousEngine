using System;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Mcp;
using Sedulous.VFS;

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
	/// Whether a project is open (null: one is); page_open refuses without one. Owned.
	public delegate bool() HasProject ~ delete _;
	/// Opens a file on disk at a line and column (1-based; 0 the start) where the Code Editor
	/// preference says, the project's Code folder when the file is empty. False when nothing
	/// opened. Owned.
	public delegate bool(StringView file, uint32 line, uint32 column) OpenCode ~ delete _;
}

/// The MCP tools over the editor's open PAGES, what only the editor host can serve: page_list,
/// page_open, page_reload and page_close, over the context's page list and the two actions
/// the application owns (opening a source asset's page, closing a page with its panel); and
/// code_open, which opens code where the user's Code Editor preference says. Reload
/// and close are refused while the page has unsaved changes unless the agent says so
/// explicitly (force, discard): a tool never waits for a human, so the destructive decision
/// is an argument, and the refusal tells the agent to ask the user.
static class EditorPageTools
{
	/// How many tools Register registers; a tripwire like EngineTools.cEngineToolCount.
	public const int cPageToolCount = 5;

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
				if ((seams.HasProject != null) && !seams.HasProject())
				{
					outError.Append(McpTools.cNoProject);
					return false;
				}
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
				seams.Context.RevealPage(page); // to front: a background tab's viewport never renders
				CopyIdentity(seams.Context, page, outResult);
				return true;
			});

		let reloadSchema = scope SchemaBuilder();
		reloadSchema.Str("guid", "the open page's asset", true);
		reloadSchema.Boolean("force", "discard the page's unsaved changes (default false)");
		server.RegisterTool("page_reload",
			"Reload an open page from its asset's source on disk, after scene_write or prefab_write changed what the page shows. The page stays open and refreshes in place (its undo history goes). REFUSED while the page has unsaved changes unless `force` is true, which discards them first. Returns the page's identity.",
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
					if (!seams.Context.DiscardPage(page))
					{
						outError.Append("the page's unsaved changes could not be discarded: its file did not read (the Console says why), so they are kept");
						return false;
					}
				}
				page.OnAssetExternallyModified();
				CopyIdentity(seams.Context, page, outResult);
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

		let codeSchema = scope SchemaBuilder();
		codeSchema.Str("guid", "a code asset");
		codeSchema.Str("path", "a file in the project's Code folder, as Code/...");
		codeSchema.Integer("line", "the line to open at, 1-based");
		codeSchema.Integer("column", "the column to open at, 1-based");
		server.RegisterTool("code_open",
			"Open code where the user's Code Editor preference says (an outside editor such as VS Code, or the built-in code page), as the Assets panel's Open does: a code asset by `guid`, or a file by `path` in the project's Code folder (as `Code/...`), at `line` and `column` (1-based; omitted: the start). With neither, opens the Code folder. Use page_open to look at a script's page yourself. Returns {opened, file}.",
			codeSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let project = seams.Context.Project;
				if (project == null)
				{
					outError.Append(McpTools.cNoProject);
					return false;
				}
				let guidText = McpTools.ArgString(arguments, "guid", .. scope .());
				let source = McpTools.ArgString(arguments, "path", .. scope .());
				let byGuid = !guidText.IsEmpty;
				let byPath = !source.IsEmpty;
				if (byGuid && byPath)
				{
					outError.Append("give guid or path, not both");
					return false;
				}
				let line = (int64)McpTools.ArgNumber(arguments, "line");
				let column = (int64)McpTools.ArgNumber(arguments, "column");
				if ((line < 0) || (column < 0))
				{
					outError.Append("line and column are 1-based");
					return false;
				}
				// The source path (Code/...) the file has, which must be in the Code folder.
				if (byGuid)
				{
					Guid id;
					if (!McpTools.ParseGuid(guidText, outError, out id))
						return false;
					let instance = project.SourceDb.GetInstance(id);
					if (instance == null)
					{
						outError.AppendF("no asset with guid '{}'", guidText);
						return false;
					}
					source.Set(instance.SourceName);
				}
				else if (byPath)
				{
					source.Replace('\\', '/');
				}
				let file = scope String();
				if (byGuid || byPath)
				{
					if (!SourcePath.AfterFolder(source, SourcePath.CodeFolder, let rest) || rest.IsEmpty || source.Contains(".."))
					{
						outError.AppendF("'{}' is not in the project's Code folder", source);
						return false;
					}
					project.SourceFile(source, file);
					if (!FileExists(file))
					{
						outError.AppendF("no file '{}'", source);
						return false;
					}
				}
				if ((seams.OpenCode == null) || !seams.OpenCode(file, (uint32)line, (uint32)column))
				{
					outError.Append("nothing opened (see log_read, category Editor)");
					return false;
				}
				outResult.Set("opened", JsonValue.MakeBool(true));
				outResult.Set("file", JsonValue.MakeString((byGuid || byPath) ? StringView(source) : SourcePath.CodeFolder));
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
