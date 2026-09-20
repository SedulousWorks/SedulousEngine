using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.Mcp;

/// asset_import / asset_cook: the WRITE side, headless. Import routes an OS file through the
/// host's importer set into the open project's source database; cook runs the incremental
/// cook driver over the project. The registries are the host's, populated once from
/// Pipeline.Registration, and outlive the server.
///
/// Import resolves the extension with FindAllFor, the interactive path's call, not the
/// singular FindFor whose first claimant always won: `.png` is claimed by the texture, the
/// image and the heightfield importers. Without a hint the first claimant keeps the default
/// and the result names the alternatives, so an agent re-imports with `importer` set.
static class AssetWriteTools
{
	private class Context
	{
		public ProjectSession Session;
		public BuilderRegistry Builders;
		public ImporterRegistry Importers;
	}

	public static void Register(McpServer server, ProjectSession session, BuilderRegistry builders,
		ImporterRegistry importers)
	{
		let context = new Context();
		context.Session = session;
		context.Builders = builders;
		context.Importers = importers;

		let importSchema = scope SchemaBuilder();
		importSchema.Str("source", "absolute path to the file to import", true);
		importSchema.Str("group", "source-DB group path to place it in (slash-joined; default root)");
		importSchema.Str("importer", "which importer to use when several claim the extension, by label (the result of an unhinted import lists them)");
		server.RegisterTool("asset_import",
			"""
			Import an OS file into the open project: copy it under Sources/ and create the typed asset in the source database, routed by extension. When several importers claim the extension the first is used and the result names the alternatives; pass `importer` to choose. Does not cook - call asset_cook next.
			""",
			importSchema.Build(),
			new (arguments, outResult, outError) => Import(context, arguments, outResult, outError),
			context);

		let cookSchema = scope SchemaBuilder();
		cookSchema.Boolean("force", "re-cook every buildable asset regardless of cleanliness");
		server.RegisterTool("asset_cook",
			"Run the incremental cook over the open project: plan the dirty set and build it into the cooked database. Returns the cook stats (planned/cooked/failed/orphans).",
			cookSchema.Build(),
			new (arguments, outResult, outError) => Cook(context, arguments, outResult, outError));
	}

	private static bool Import(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let source = McpTools.ArgString(arguments, "source", .. scope .());
		let hint = McpTools.ArgString(arguments, "importer", .. scope .());
		let suffix = ImportPaths.ExtensionLower(source, .. scope .());

		let claimants = scope List<IFileImporter>();
		context.Importers.FindAllFor(suffix, claimants);
		if (claimants.IsEmpty)
		{
			outError.AppendF("no importer registered for '.{}' files", suffix);
			return false;
		}
		IFileImporter importer = null;
		if (hint.IsEmpty)
		{
			importer = claimants[0];
		}
		else
		{
			for (let candidate in claimants)
				if (candidate.Label == hint)
					importer = candidate;
			if (importer == null)
			{
				outError.AppendF("no importer '{}' claims '.{}'; the claimants are: ", hint, suffix);
				AppendLabels(claimants, null, outError);
				return false;
			}
		}

		let group = McpTools.ResolveGroupPath(session.Project.SourceDb.RootGroup,
			McpTools.ArgString(arguments, "group", .. scope .()));
		let importContext = scope ImportContext(session.Project.SourcesRoot(.. scope .()));
		let imported = importer.Import(source, importContext, group, null, null, null);
		if (imported case .Err(let error))
		{
			outError.AppendF("import of '{}' failed ({})", source, error);
			return false;
		}
		let instance = imported.Get();
		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("type", JsonValue.MakeString(instance.TypeName));
		outResult.Set("importer", JsonValue.MakeString(importer.Label));
		if (claimants.Count > 1)
		{
			let alternatives = JsonValue.MakeArray();
			for (let candidate in claimants)
				if (candidate != importer)
					alternatives.Add(JsonValue.MakeString(candidate.Label));
			outResult.Set("alsoClaimableBy", alternatives);
		}
		return true;
	}

	private static void AppendLabels(List<IFileImporter> importers, IFileImporter except, String outText)
	{
		bool first = true;
		for (let importer in importers)
		{
			if (importer == except)
				continue;
			if (!first)
				outText.Append(", ");
			outText.Append(importer.Label);
			first = false;
		}
	}

	private static bool Cook(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let force = McpTools.ArgBool(arguments, "force");
		let project = session.Project;
		// Second mounts on Sources/ and .cache/: the cook driver hashes source files and
		// persists its records through these; the source and cooked databases are open already.
		let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let driver = scope CookDriver(project.SourceDb, project.CookedDb, context.Builders, sourcesMount, cacheMount);
		let plan = scope CookPlan();
		driver.Plan(plan, force);
		let stats = scope CookStats();
		driver.Execute(plan, stats);

		outResult.Set("planned", JsonValue.MakeNumber((double)plan.Dirty.Count));
		outResult.Set("cooked", JsonValue.MakeNumber((double)stats.Cooked));
		outResult.Set("failed", JsonValue.MakeNumber((double)stats.Failed));
		outResult.Set("orphansSwept", JsonValue.MakeNumber((double)stats.OrphansSwept));
		outResult.Set("upToDate", JsonValue.MakeNumber((double)plan.UpToDate));
		outResult.Set("unbuildable", JsonValue.MakeNumber((double)plan.Unbuildable));
		return true;
	}
}
