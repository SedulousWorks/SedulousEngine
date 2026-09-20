using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.VFS;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// project_export: a thin wrapper over the ONE export entry point, the same call the
/// editor's Export menu and the CLI make, so an MCP export produces an identical dist. The
/// presets come from the project's export_presets.xml, else the synthesized host preset;
/// the templates from the root plus the player beside the host tool; the scene streams
/// pre-transcoded and the pruning scanner over the full composition.
static class ProjectExportTool
{
	private class Context
	{
		public ProjectSession Session;
		public BuilderRegistry Builders;
		/// Where the player beside the host lives: the export's host template.
		public String PlayerDir = new .() ~ delete _;
		/// The engine data root the shader cook reads.
		public String DataRoot = new .() ~ delete _;
	}

	public static void Register(McpServer server, ProjectSession session, BuilderRegistry builders,
		StringView playerDir, StringView dataRoot)
	{
		let context = new Context();
		context.Session = session;
		context.Builders = builders;
		context.PlayerDir.Set(playerDir);
		context.DataRoot.Set(dataRoot);

		let schema = scope SchemaBuilder();
		schema.Str("preset", "preset name (default: the project's first preset)");
		schema.Str("out", "output root directory (default: <project>/Dist)");
		schema.Boolean("rebuild", "force a full re-cook first (default incremental)");
		server.RegisterTool("project_export",
			"""
			Export the open project into a shippable dist: cook everything, stage the scenes, pack the content, cook the shader pack, and stage the preset's player template - the same single entry point the editor's Export menu and the export CLI use, so the result is identical. Long-running (a full cook may run). Presets come from the project's export_presets.xml (default: the first; no file = a synthesized host-platform preset). Returns the output directory and the cook/stage/pack counts; run project_health first to catch breakage before a long export.
			""",
			schema.Build(),
			new (arguments, outResult, outError) => Export(context, arguments, outResult, outError),
			context);
	}

	private static bool Export(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = context.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let presets = scope ExportPresetSet();
		{
			let projectFs = scope NativeFileSystem(project.Directory);
			if (ExportPresetsFile.Load(projectFs, presets) case .Err)
				ExportPresetsFile.Defaults(presets);
		}
		let presetName = McpTools.ArgString(arguments, "preset", .. scope .());
		let preset = presetName.IsEmpty ? (presets.Presets.IsEmpty ? null : presets.Presets[0]) : presets.Find(presetName);
		if (preset == null)
		{
			outError.AppendF("no preset named '{}' (available: ", presetName);
			for (int i < presets.Presets.Count)
				outError.AppendF("{}{}", (i > 0) ? ", " : "", presets.Presets[i].Name);
			outError.Append(")");
			return false;
		}

		let templates = scope TemplateRegistry();
		templates.Refresh(ExportTemplates.ResolveRoot("", .. scope .()), context.PlayerDir);
		let sceneStreams = scope Dictionary<Guid, List<uint8>>();
		defer { for (let entry in sceneStreams) delete entry.value; }
		SceneExportSupport.CollectSceneStreams(project.SourceDb.RootGroup, sceneStreams);
		SceneReferenceScanner scanner = scope (instance, db, outReferences) =>
			{
				SceneExportSupport.ScanSceneReferences(instance, db, outReferences.Resources, outReferences.Prefabs);
			};
		let outArg = McpTools.ArgString(arguments, "out", .. scope .());
		let outRoot = scope String();
		if (!outArg.IsEmpty)
			outRoot.Set(outArg);
		else
			PathJoin(project.Directory, "Dist", outRoot);
		let rebuild = McpTools.ArgBool(arguments, "rebuild");

		let result = scope ExportResult();
		if (ExportDriver.ExportOne(project, preset, templates, context.Builders, outRoot, context.DataRoot, rebuild, result, null, true, sceneStreams, scanner) case .Err)
		{
			outError.AppendF("export of preset '{}' failed - read log_read (category Export/Cook) for the failing step", preset.Name);
			return false;
		}
		outResult.Set("exported", JsonValue.MakeBool(true));
		outResult.Set("preset", JsonValue.MakeString(preset.Name));
		outResult.Set("outputDir", JsonValue.MakeString(result.OutputDir));
		outResult.Set("cooked", JsonValue.MakeNumber((double)result.Content.Cooked));
		outResult.Set("cookFailed", JsonValue.MakeNumber((double)result.Content.CookFailed));
		outResult.Set("scenesStaged", JsonValue.MakeNumber((double)result.Content.ScenesStaged));
		outResult.Set("filesPacked", JsonValue.MakeNumber((double)result.Content.FilesPacked));
		outResult.Set("filesStaged", JsonValue.MakeNumber((double)result.FilesStaged));
		if (!result.EngineVersionWarning.IsEmpty)
			outResult.Set("warning", JsonValue.MakeString(result.EngineVersionWarning));
		if (result.Pruning.Pruned)
		{
			let pruning = JsonValue.MakeObject();
			pruning.Set("kept", JsonValue.MakeNumber((double)result.Pruning.KeptCount));
			pruning.Set("dropped", JsonValue.MakeNumber((double)result.Pruning.Dropped.Count));
			outResult.Set("pruning", pruning);
		}
		return true;
	}
}
