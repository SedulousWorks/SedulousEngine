using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Engine.Project;
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
		importSchema.Map("options", "the importer's settings, as the import window shows them: {\"<setting>\": value}, a flag true or false, a number, or a choice by its value's name (a model's \"Up axis\": \"Z\"), the setting named by its label, case and spaces ignored (a model's: Scale, Up axis, Textures, Materials, Animations, Generate prefab, Generate scene, Generate collision, Convex collision, Generate LODs, Root motion); an unknown one is refused with the importer's list, unnamed settings keep their defaults, and the result lists every setting's value");
		importSchema.Str("name", "the asset's name (a single-asset importer's; default: the file's stem)");
		importSchema.Str("onConflict", "when another file's asset of this type has the name: refuse (default), replace, or keepBoth");
		server.RegisterTool("asset_import",
			"""
			Import an OS file into the open project: copy it under Sources/ and create the typed asset in the source database, routed by extension. When several importers claim the extension the first is used and the result names the alternatives; pass `importer` to choose. A name held by an asset of another type is refused; one held by another file's asset of its type is refused unless `onConflict` says `replace` (that asset takes the new file, its guid and references kept) or `keepBoth` (the next free name); re-importing the same file replaces its asset. Does not cook - call asset_cook next.
			""",
			importSchema.Build(), .Creates,
			new (call, arguments, outResult, outError) => Import(context, call, arguments, outResult, outError),
			context);

		let cookSchema = scope SchemaBuilder();
		cookSchema.Boolean("force", "re-cook every buildable asset regardless of cleanliness");
		server.RegisterTool("asset_cook",
			"Run the incremental cook over the open project: plan the dirty set and build it into the cooked database. Returns the cook stats (planned/cooked/failed/orphans).",
			cookSchema.Build(), .Rebuilds,
			new (call, arguments, outResult, outError) => Cook(context, call, arguments, outResult, outError));
	}

	private static ToolOutcome Import(Context context, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
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

		// The options: the importer's defaults, then the call's settings by label.
		let options = importer.CreateOptions();
		defer { if (options != null) delete options; }
		if (options != null)
			importer.InitializeOptions(source, options); // as the window would start them
		let settings = scope List<FieldInfo>();
		if (options != null)
			options.GetSettings(settings);
		if (let asked = arguments.Get("options"))
		{
			if (!asked.IsObject)
			{
				outError.Append("`options` takes an object of settings: {\"Generate collision\": true}");
				return .Failed;
			}
			for (int i < asked.Count)
			{
				let key = asked.KeyAt(i);
				let value = asked.Get(key);
				FieldInfo found = default;
				if ((options == null) || !options.FindSetting(key, out found))
				{
					outError.AppendF("the {} importer has no option '{}'; its options are: ", importer.Label, key);
					if (settings.IsEmpty)
						outError.Append("none");
					for (int t < settings.Count)
					{
						if (t > 0)
							outError.Append(", ");
						ImportOptions.SettingLabel(settings[t], outError);
					}
					return .Failed;
				}
				let address = SettingAt(options, found);
				let type = found.FieldType;
				if (type == typeof(bool))
				{
					if (!value.IsBool)
					{
						outError.AppendF("option '{}' takes true or false", key);
						return .Failed;
					}
					*(bool*)address = value.AsBool();
				}
				else if (type == typeof(float))
				{
					if (!value.IsNumber)
					{
						outError.AppendF("option '{}' takes a number", key);
						return .Failed;
					}
					*(float*)address = (float)value.AsNumber();
				}
				else if (type.IsEnum)
				{
					// By a case's name only (Enum.Parse would take a number too).
					bool named = false;
					for (var (name, data) in Enum.GetEnumerator(type))
					{
						if (value.IsString && (name == value.AsString()))
						{
							named = true;
							SettingFields.WriteChoice(options, found, data);
						}
					}
					if (!named)
					{
						outError.AppendF("option '{}' takes {}", key, SettingFields.ChoiceNames(type, .. scope .()));
						return .Failed;
					}
				}
				else
				{
					outError.AppendF("option '{}' is not one asset_import sets", key);
					return .Failed;
				}
			}
		}

		ImportRequest request = .();
		request.Source = source;
		request.GroupPath = McpTools.ArgString(arguments, "group", .. scope .());
		request.Importer = importer;

		// The name asked for, and what to do when another file's asset holds it.
		let conflict = McpTools.ArgString(arguments, "onConflict", .. scope .());
		if (conflict.IsEmpty || (conflict == "refuse"))
			request.OnConflict = .Refuse;
		else if (conflict == "replace")
			request.OnConflict = .Replace;
		else if (conflict == "keepBoth")
			request.OnConflict = .KeepBoth;
		else
		{
			outError.AppendF("onConflict is refuse, replace or keepBoth, not '{}'", conflict);
			return .Failed;
		}
		var named = options;
		let asked = McpTools.ArgString(arguments, "name", .. scope .());
		ImportOptions own = null;
		defer { delete own; }
		if (!asked.IsEmpty)
		{
			if (named == null)
			{
				own = new ImportOptions();
				named = own;
			}
			ClearAndDeleteItems!(named.Selection.Entries);
			ImportPaths.SingleAssetPlan(source, named.Selection);
			named.Selection.Entries[0].TargetName.Set(asked);
		}
		request.Options = named;

		// The clash, refused here with what holds the name (the importer refuses too).
		{
			let project = session.Project;
			let into = McpTools.ResolveGroupPath(project.SourceDb.RootGroup, request.GroupPath);
			let ledger = ImportPaths.ImportLedgerPath(project.CacheRoot(.. scope .()), .. scope .());
			let clash = scope ImportClash();
			importer.FindClash(into, source, (named != null) ? named.Selection : null, ledger, clash);
			if (!ImportPaths.ImportClashAllows(clash, request.OnConflict))
			{
				ImportPaths.DescribeImportClash(clash, outError);
				outError.Append((clash.Kind == .OtherType) ? " Pass `name`." : " Pass `onConflict`: replace or keepBoth (or `name`).");
				return .Failed;
			}
		}
		let done = scope ImportOutcome();
		switch (context.Operations.Import(call, request, done, outError))
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
		if (!settings.IsEmpty)
		{
			let applied = JsonValue.MakeObject();
			for (let setting in settings)
			{
				let label = ImportOptions.SettingLabel(setting, .. scope .());
				let address = SettingAt(options, setting);
				if (setting.FieldType == typeof(bool))
					applied.Set(label, JsonValue.MakeBool(*(bool*)address));
				else if (setting.FieldType == typeof(float))
					applied.Set(label, JsonValue.MakeNumber(*(float*)address));
				else if (setting.FieldType.IsEnum)
				{
					let name = scope String();
					Enum.EnumToString(setting.FieldType, name, SettingFields.ReadChoice(options, setting));
					applied.Set(label, JsonValue.MakeString(name));
				}
			}
			outResult.Set("options", applied);
		}
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

	/// A bool setting's value in `options`, where it lives.
	private static void* SettingAt(ImportOptions options, FieldInfo setting)
		=> (uint8*)Internal.UnsafeCastToPtr(options) + setting.MemberOffset;

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

	private static ToolOutcome Cook(Context context, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!context.Session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return .Failed;
		}
		CookOutcome done = .();
		switch (context.Operations.Cook(call, McpTools.ArgBool(arguments, "force"), ref done, outError))
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
