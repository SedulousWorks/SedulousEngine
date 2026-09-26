using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.Mcp;

/// asset_import / asset_cook: the WRITE side. Routing (which importer, by extension and
/// hint), refusals and the result shapes are here, shared by every host; the work runs through
/// the host's IProjectOperations: inline on the stdio host, the editor's cook and job services
/// otherwise, the tool re-entered each pump until they finish. The importer registry is the
/// host's (the same set the editor's drag and drop routes through) and outlives the server.
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
		public ImporterRegistry Importers;
		public IProjectOperations Operations;
	}

	public static void Register(McpServer server, ProjectSession session, ImporterRegistry importers,
		IProjectOperations operations)
	{
		let context = new Context();
		context.Session = session;
		context.Importers = importers;
		context.Operations = operations;

		let importSchema = scope SchemaBuilder();
		importSchema.Str("source", "absolute path to the file to import", true);
		importSchema.Str("group", "source-DB group path to place it in (slash-joined; default root)");
		importSchema.Str("importer", "which importer to use when several claim the extension, by label (the result of an unhinted import lists them)");
		server.RegisterTool("asset_import",
			"""
			Import an OS file into the open project: copy it under Sources/ and create the typed asset in the source database, routed by extension. When several importers claim the extension the first is used and the result names the alternatives; pass `importer` to choose. Does not cook - call asset_cook next.
			""",
			importSchema.Build(), .Creates,
			new (arguments, outResult, outError) => Import(context, arguments, outResult, outError),
			context);

		let cookSchema = scope SchemaBuilder();
		cookSchema.Boolean("force", "re-cook every buildable asset regardless of cleanliness");
		server.RegisterTool("asset_cook",
			"Run the incremental cook over the open project: plan the dirty set and build it into the cooked database. Returns the cook stats (planned/cooked/failed/orphans).",
			cookSchema.Build(), .Rebuilds,
			new (arguments, outResult, outError) => Cook(context, arguments, outResult, outError));
	}

	private static ToolOutcome Import(Context context, JsonValue arguments, JsonValue outResult, String outError)
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

		ImportRequest request = .();
		request.Source = source;
		request.GroupPath = McpTools.ArgString(arguments, "group", .. scope .());
		request.Importer = importer;
		let done = scope ImportOutcome();
		switch (context.Operations.Import(request, done, outError))
		{
		case .Failed: return .Failed;
		case .NotYet: return .NotFinished; // the host's import is still running
		case .Finished:
		}
		outResult.Set("guid", McpTools.GuidToJson(done.Id));
		outResult.Set("name", JsonValue.MakeString(done.Name));
		outResult.Set("type", JsonValue.MakeString(done.Type));
		outResult.Set("typeNamespace", JsonValue.MakeString(done.TypeNamespace));
		outResult.Set("deferredWrites", JsonValue.MakeNumber((double)done.DeferredWrites));
		outResult.Set("prepareMs", JsonValue.MakeNumber((double)done.PrepareMs));
		outResult.Set("mainMs", JsonValue.MakeNumber((double)done.MainMs));
		outResult.Set("flushMs", JsonValue.MakeNumber((double)done.FlushMs));
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

	private static ToolOutcome Cook(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!context.Session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return .Failed;
		}
		CookOutcome done = .();
		switch (context.Operations.Cook(McpTools.ArgBool(arguments, "force"), ref done, outError))
		{
		case .Failed: return .Failed;
		case .NotYet: return .NotFinished; // the host's cook is still running
		case .Finished:
		}
		outResult.Set("planned", JsonValue.MakeNumber((double)done.Planned));
		outResult.Set("cooked", JsonValue.MakeNumber((double)done.Cooked));
		outResult.Set("failed", JsonValue.MakeNumber((double)done.Failed));
		outResult.Set("orphansSwept", JsonValue.MakeNumber((double)done.OrphansSwept));
		outResult.Set("upToDate", JsonValue.MakeNumber((double)done.UpToDate));
		outResult.Set("unbuildable", JsonValue.MakeNumber((double)done.Unbuildable));
		return .Answered;
	}
}
