using System;
using System.Collections;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The scene editor's live MCP tools, served by the editor's MCP host through the scene
/// editor's tool contribution: selection_get and selection_set, simulate_start and
/// simulate_stop, over whichever scene or prefab page a call addresses. `page` is the scene
/// asset's guid as page_list reports it, defaulting to the active page when that is a scene
/// page; every result names the page it acted on, since several scene pages may be open, each
/// with its own selection.
static class SceneMcpTools
{
	/// How many tools Register registers; a tripwire like the page tools'.
	public const int cSceneLiveToolCount = 4;

	private const String cPageArgument = "the scene or prefab page's asset guid (default: the active page)";

	public static void Register(McpServer server, EditorContext context)
	{
		let getSchema = scope SchemaBuilder();
		getSchema.Str("page", cPageArgument);
		server.RegisterTool("selection_get",
			"A scene page's entity selection: the entities in order (the first is the primary, the gizmo pivot), each with its name. Defaults to the active page.",
			getSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				WriteSelection(page, outResult);
				return true;
			});

		let setSchema = scope SchemaBuilder();
		setSchema.Str("page", cPageArgument);
		setSchema.Arr("entities", "string", "the entity guids to select, in order", true);
		server.RegisterTool("selection_set",
			"Select entities on a scene page (an empty list clears): the hierarchy, the inspector and the gizmos follow, so this is also how to SHOW the user which entity is meant. The first guid becomes the primary. Every guid must be an entity of that page's scene. Returns the selection as selection_get does.",
			setSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let edit = (page as ISceneEditorPage).EditContext;
				let list = arguments.Get("entities");
				let ids = scope List<Guid>();
				for (int i < list.Count)
				{
					let text = list.At(i).AsString();
					Guid id;
					if (!(Guid.Parse(text) case .Ok(out id)))
					{
						outError.AppendF("invalid entity guid '{}'", text);
						return false;
					}
					if (!edit.Scene.IsValid(edit.Resolve(id)))
					{
						outError.AppendF("no entity with guid '{}' in page '{}' (scene_read shows the scene's entities)", text, page.Title);
						return false;
					}
					ids.Add(id);
				}
				edit.EntitySelection.Set(ids);
				WriteSelection(page, outResult);
				return true;
			});

		let startSchema = scope SchemaBuilder();
		startSchema.Str("page", cPageArgument);
		server.RegisterTool("simulate_start",
			"Start a scene page's edit-mode Simulate: the live scene runs (physics, systems) from a snapshot that simulate_stop restores; edits are locked meanwhile. A no-op when already simulating. Returns {page, simulating}.",
			startSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				(page as ISceneEditorPage).StartSimulation();
				WriteSimulation(page, outResult);
				return true;
			});

		let stopSchema = scope SchemaBuilder();
		stopSchema.Str("page", cPageArgument);
		server.RegisterTool("simulate_stop",
			"Stop a scene page's Simulate and restore the scene from its snapshot. A no-op when not simulating. Returns {page, simulating}.",
			stopSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				(page as ISceneEditorPage).StopSimulation();
				WriteSimulation(page, outResult);
				return true;
			});
	}

	/// The scene page a call addresses: `page` (a guid) when given, else the active page; null
	/// with the reason in outError when it is not a scene page.
	private static EditorPage ResolveScenePage(EditorContext context, JsonValue arguments, String outError)
	{
		EditorPage page = null;
		let pageArg = arguments.Get("page");
		if ((pageArg != null) && pageArg.IsString)
		{
			let text = pageArg.AsString();
			Guid id;
			if (!(Guid.Parse(text) case .Ok(out id)))
			{
				outError.AppendF("invalid page guid '{}'", text);
				return null;
			}
			for (let open in context.OpenPages)
			{
				if (open.InstanceId == id)
				{
					page = open;
					break;
				}
			}
			if (page == null)
			{
				outError.AppendF("no open page for guid '{}' (page_list shows the open ones; page_open opens one)", text);
				return null;
			}
		}
		else
		{
			page = context.ActivePage;
			if (page == null)
			{
				outError.Append("no page is active - page_open a scene first, or pass `page`");
				return null;
			}
		}
		if (!(page is ISceneEditorPage))
		{
			outError.AppendF("page '{}' is not a scene or prefab page - pass `page` with a scene's guid, or page_open one", page.Title);
			return null;
		}
		return page;
	}

	private static JsonValue PageJson(EditorPage page)
	{
		let identity = JsonValue.MakeObject();
		identity.Set("guid", JsonValue.MakeString(page.InstanceId.ToString(.. scope .())));
		identity.Set("title", JsonValue.MakeString(page.Title));
		return identity;
	}

	/// The page's selection as the agent sees it: the page, the entities in order (the first
	/// is the primary, the gizmo pivot), each with its name.
	private static void WriteSelection(EditorPage page, JsonValue outResult)
	{
		let edit = (page as ISceneEditorPage).EditContext;
		let entities = JsonValue.MakeArray();
		for (let id in edit.EntitySelection.Items)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("guid", JsonValue.MakeString(id.ToString(.. scope .())));
			let handle = edit.Resolve(id);
			entry.Set("name", JsonValue.MakeString(edit.Scene.IsValid(handle) ? edit.Scene.GetEntityName(handle) : ""));
			entities.Add(entry);
		}
		outResult.Set("page", PageJson(page));
		outResult.Set("primary", edit.EntitySelection.IsEmpty ? JsonValue.MakeNull() : JsonValue.MakeString(edit.EntitySelection.Primary.ToString(.. scope .())));
		outResult.Set("entities", entities);
	}

	private static void WriteSimulation(EditorPage page, JsonValue outResult)
	{
		outResult.Set("page", PageJson(page));
		outResult.Set("simulating", JsonValue.MakeBool((page as ISceneEditorPage).IsSimulating));
	}
}
