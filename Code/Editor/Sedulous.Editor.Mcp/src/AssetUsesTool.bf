using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Mcp;

/// asset_uses: the REVERSE dependency query, "what uses this asset". Required reading
/// before any destructive change: the agent sees every direct user and the kind of each
/// edge before it breaks one.
///
/// Edges come from the SAME sources the engine uses, computed LIVE, never a cached graph:
/// a buildable asset's builder ScanDependencies, exactly what the cook hashes, as `reads`
/// (content consumed at cook time) and `references` (the product's runtime refs); a scene's
/// or prefab's component Refs and prefab instances through the full manager scan; and the
/// manifest's own guid fields. Direct users only: re-run on a user to walk the chain.
static class AssetUsesTool
{
	private class Context
	{
		public ProjectSession Session;
		public BuilderRegistry Builders;
	}

	/// One direct user: the instance, its group path, and every edge kind it holds.
	private class Use
	{
		public Instance User;
		public String Group = new .() ~ delete _;
		public List<String> Edges = new .() ~ DeleteContainerAndItems!(_);
	}

	/// The manifest's guid fields, named as the tool reports them.
	public static void SettingsReferences(ProjectSettings settings, List<(StringView name, Guid id)> outRefs)
	{
		outRefs.Add(("defaultScene", settings.DefaultSceneId));
		outRefs.Add(("startupScript", settings.StartupScriptId));
		outRefs.Add(("defaultInputMap", settings.DefaultInputMapId));
		outRefs.Add(("defaultBusLayout", settings.DefaultBusLayoutId));
		outRefs.Add(("defaultUiTheme", settings.DefaultUiThemeId));
		outRefs.Add(("defaultUiFont", settings.DefaultUiFontId));
		outRefs.Add(("loadingDocument", settings.LoadingDocumentId));
	}

	public static void Register(McpServer server, ProjectSession session, BuilderRegistry builders)
	{
		let context = new Context();
		context.Session = session;
		context.Builders = builders;
		let schema = scope SchemaBuilder();
		schema.Str("guid", "the asset guid (canonical 8-4-4-4-12 form)", true);
		server.RegisterTool("asset_uses",
			"""
			REVERSE dependency query: every DIRECT user of an asset, with the edge kind - 'reads' (an asset's cook consumes its content), 'references' (an asset's cooked product refers to it at runtime), 'scene-resource' (a scene/prefab component references it), 'prefab-instance' (a scene/prefab instantiates it), plus any project-settings fields pointing at it (default scene, startup script, ...). Computed live from the source database. Call this BEFORE deleting, renaming, or moving an asset; an empty result means nothing in the source database or project settings points at it. Direct users only - re-run on a user to walk the chain.
			""",
			schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Uses(context, arguments, outResult, outError),
			context);
	}

	private static bool Uses(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let guidText = McpTools.ArgString(arguments, "guid", .. scope .());
		if (!McpTools.ParseGuid(guidText, outError, let id))
			return false;
		let db = session.Project.SourceDb;
		let target = db.GetInstance(id);
		if (target == null)
		{
			outError.AppendF("no asset with guid '{}' in the source database (asset_uses answers over source assets; use asset_list to find the right guid)", guidText);
			return false;
		}

		let sourcesMount = scope NativeFileSystem(session.Project.SourcesRoot(.. scope .()));
		let uses = scope List<Use>();
		defer { ClearAndDeleteItems(uses); }
		Collect(db.RootGroup, scope String(), id, db, context.Builders, sourcesMount, uses);

		let usedBy = JsonValue.MakeArray();
		for (let use in uses)
		{
			let entry = McpTools.InstanceToJson(use.User);
			if (!use.Group.IsEmpty)
				entry.Set("group", JsonValue.MakeString(use.Group));
			let edges = JsonValue.MakeArray();
			for (let kind in use.Edges)
				edges.Add(JsonValue.MakeString(kind));
			entry.Set("edges", edges);
			usedBy.Add(entry);
		}

		// The manifest's own references: a scene can be in use by the project itself.
		let settingsUses = JsonValue.MakeArray();
		let refs = scope List<(StringView name, Guid id)>();
		SettingsReferences(session.Project.Settings, refs);
		for (let reference in refs)
			if (reference.id == id)
				settingsUses.Add(JsonValue.MakeString(reference.name));

		outResult.Set("guid", McpTools.GuidToJson(target.Id));
		outResult.Set("name", JsonValue.MakeString(target.Name));
		outResult.Set("type", JsonValue.MakeString(target.TypeName));
		outResult.Set("useCount", JsonValue.MakeNumber((double)uses.Count));
		outResult.Set("usedBy", usedBy);
		outResult.Set("projectSettingsUses", settingsUses);
		return true;
	}

	/// Every source instance under `group`, depth first, with an edge to `target`.
	private static void Collect(Group group, String path, Guid target, ContentDatabase db,
		BuilderRegistry builders, IFileSystem sourcesMount, List<Use> outUses)
	{
		for (let instance in group.Instances)
		{
			if (instance.Id == target)
				continue;
			let use = scope Use();
			if (McpTools.IsSceneDocument(instance) || McpTools.IsPrefabDocument(instance))
			{
				let resources = scope List<Guid>();
				let prefabs = scope List<Guid>();
				SceneReferences.Collect(instance, db, resources, prefabs);
				if (SceneReferences.Contains(resources, target))
					use.Edges.Add(new String("scene-resource"));
				if (SceneReferences.Contains(prefabs, target))
					use.Edges.Add(new String("prefab-instance"));
			}
			else if (let builder = builders.FindByTypeName(instance.TypeName))
			{
				let object = instance.ReadObject();
				defer { if (object != null) delete object; }
				if (let asset = McpTools.AsAsset(object))
				{
					let scanContext = scope AssetBuildContext();
					scanContext.Sources = sourcesMount;
					scanContext.Database = db;
					let deps = scope AssetDependencies();
					builder.ScanDependencies(asset, scanContext, deps);
					if (SceneReferences.Contains(deps.Reads, target))
						use.Edges.Add(new String("reads"));
					if (SceneReferences.Contains(deps.References, target))
						use.Edges.Add(new String("references"));
				}
			}
			if (!use.Edges.IsEmpty)
			{
				let kept = new Use();
				kept.User = instance;
				kept.Group.Set(path);
				kept.Edges.AddRange(use.Edges);
				use.Edges.Clear();
				outUses.Add(kept);
			}
		}
		for (let child in group.Groups)
		{
			let childPath = scope String(path);
			if (!childPath.IsEmpty)
				childPath.Append('/');
			childPath.Append(child.Name);
			Collect(child, childPath, target, db, builders, sourcesMount, outUses);
		}
	}
}
