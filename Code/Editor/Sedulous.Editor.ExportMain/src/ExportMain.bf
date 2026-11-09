using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Engine.Composition;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.ExportMain;

/// The command line exporter: a project into a shippable dist through the ONE entry point
/// the editor's Export menu and the MCP host share.
///
/// Usage:
///   Sedulous.Tools.Export <projectDir> [--out <dir>] [--preset <name> | --all] [--rebuild] [--data-root <dir>]
///   Sedulous.Tools.Export <projectDir> --content-only --platform <name> [--out <dir>] [--preset <name>] [--rebuild]
///
/// An export builds the project's own player for each preset with BeefBuild, inline, against
/// the engine SDK ($SEDULOUS_SDK, else the checkout the data root is in); BeefBuild's lines go
/// to the console as the build's log lines. The engine data root, whose Shaders the export
/// cooks, is found by the Data/.dataroot walk from this tool, or --data-root. --content-only
/// stages what the game reads and builds no player (the content pak, player.xml and the shader
/// pack) for a platform named with --platform, Android64 for an Android app's assets.
///
/// A library rather than the executable's own, so the stock tool (Sedulous.Tools.Export) and a
/// project's own build (`<Game>Tools export`, which links the project's packages) export the
/// same way: each Main is one call to Run.
static class ExportMain
{
	public static int Run(String[] args)
	{
		InitGlobalLogger(new ConsoleLogger(.Information, "Export"), true);
		defer ShutdownGlobalLogger();

		// The project comes first: an option in its place is a mistyped command line.
		if ((args.Count < 1) || args[0].StartsWith("--"))
			return Usage();

		let projectDir = args[0];
		let outArg = scope String();
		let presetName = scope String();
		bool all = false;
		bool rebuild = false;
		bool contentOnly = false;
		let platformArg = scope String();
		for (int i = 1; i < args.Count; i++)
		{
			if ((args[i] == "--out") && (i + 1 < args.Count))
				outArg.Set(args[++i]);
			else if ((args[i] == "--preset") && (i + 1 < args.Count))
				presetName.Set(args[++i]);
			else if (args[i] == "--all")
				all = true;
			else if (args[i] == "--rebuild")
				rebuild = true;
			else if (args[i] == "--content-only")
				contentOnly = true;
			else if ((args[i] == "--platform") && (i + 1 < args.Count))
				platformArg.Set(args[++i]);
			else if (args[i].StartsWith("--data-root"))
			{
				if ((args[i] == "--data-root") && (i + 1 < args.Count))
					i++;
			}
			else
			{
				Console.Error.WriteLine("unknown option: {}", args[i]);
				return Usage();
			}
		}
		if (all && !presetName.IsEmpty)
		{
			Console.Error.WriteLine("--all and --preset are mutually exclusive");
			return 1;
		}
		if (contentOnly && (all || platformArg.IsEmpty))
		{
			Console.Error.WriteLine("--content-only takes --platform <name> and one preset, not --all");
			return 1;
		}

		let project = EditorProject.Open(projectDir);
		if (project == null)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: failed to open project '{}'", projectDir);
			return 1;
		}
		defer delete project;

		// The engine data root: the Shaders the export cooks, and a custom shader's includes.
		let dataRoot = scope String();
		ResolveDataRoot(args, dataRoot);
		if (dataRoot.IsEmpty)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: no data root (put Data/ with its .dataroot marker beside the tool, or pass --data-root <dir>)");
			return 1;
		}

		// The pipeline's composition root, and the builders it fills.
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, dataRoot);
		// The plugins the project enables that this tool links, their Engine, Pipeline and Tooling
		// parts (their builders join the export's cook).
		let plugins = scope ToolPlugins(.Export, project, PipelineRegistries(builders, null, null));
		for (let refusal in plugins.Report.Refused)
			Console.Error.WriteLine("Sedulous.Tools.Export: {}", refusal.Reason);

		// The scene streams pre-transcoded over the FULL manager set, and the scanner the
		// pruning walks with; both from the engine's scene surface.
		let sceneStreams = scope Dictionary<Guid, List<uint8>>();
		defer { for (let entry in sceneStreams) delete entry.value; }
		SceneExportSupport.CollectSceneStreams(project.SourceDb.RootGroup, sceneStreams);
		SceneReferenceScanner scanner = scope (instance, db, outReferences) =>
			{
				SceneExportSupport.ScanSceneReferences(instance, db, outReferences.Resources, outReferences.Prefabs);
			};

		let presets = scope ExportPresetSet();
		{
			let projectFs = scope NativeFileSystem(project.Directory);
			if (ExportPresetsFile.Load(projectFs, presets) case .Err)
				ExportPresetsFile.Defaults(presets);
		}
		// The player each preset ships, built on this thread.
		let buildService = scope ProjectBuildService();
		let players = scope PresetPlayerBuilder(buildService, dataRoot);
		let outRoot = scope String();
		if (!outArg.IsEmpty)
			outRoot.Set(outArg);
		else
			PathJoin(project.Directory, ProjectLayout.DistDir, outRoot);

		if (all)
		{
			let summary = scope ExportAllSummary();
			if (ExportDriver.ExportAll(project, presets.Presets, players, builders, outRoot, dataRoot, rebuild, null, true, sceneStreams, scanner, null, plugins.ExportHooks, plugins.Host, summary) case .Err)
			{
				Console.Error.WriteLine("Sedulous.Tools.Export: one or more presets failed (see log)");
				return 1;
			}
			Console.WriteLine("export done: {} preset(s) -> {}", summary.Exported, outRoot);
			for (let skipped in summary.Skipped)
				Console.WriteLine("  skipped '{}': its player builds on another host", skipped);
			return 0;
		}
		let preset = presetName.IsEmpty ? (presets.Presets.IsEmpty ? null : presets.Presets[0]) : presets.Find(presetName);
		if (preset == null)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: no preset{}", presetName.IsEmpty ? " defined" : scope $" named {presetName}");
			return 1;
		}
		// --platform names the platform the content is for, over the chosen preset's own (this run
		// alone: the presets file is not saved).
		if (!platformArg.IsEmpty)
			preset.Platform.Set(platformArg);
		let result = scope ExportResult();
		if (ExportDriver.ExportOne(project, preset, players, builders, outRoot, dataRoot, rebuild, result, null, true, sceneStreams, scanner, null, plugins.ExportHooks, plugins.Host, contentOnly) case .Err)
		{
			if (!result.Refusal.IsEmpty)
				Console.Error.WriteLine("Sedulous.Tools.Export: export refused: {}", result.Refusal);
			Console.Error.WriteLine("Sedulous.Tools.Export: export failed (see log)");
			return 1;
		}
		Console.WriteLine("exported '{}' -> {}\n  cook: {} cooked, {} scene(s), {} packed | staged {} file(s)",
			preset.Name, result.OutputDir, result.Content.Cooked, result.Content.ScenesStaged, result.Content.FilesPacked, result.FilesStaged);
		Console.WriteLine("  player: {}", result.PlayerReason);
		if (result.Pruning.Pruned)
		{
			Console.WriteLine("  pruned: {} kept, {} dropped -> {}/export-report.txt", result.Pruning.KeptCount, result.Pruning.Dropped.Count, result.OutputDir);
			Console.Write(result.Pruning.Format(.. scope .()));
		}
		return 0;
	}

	private static int Usage()
	{
		Console.Error.WriteLine("""
			usage:
			  Sedulous.Tools.Export <projectDir> [--out <dir>] [--preset <name> | --all] [--rebuild] [--data-root <dir>]
			  Sedulous.Tools.Export <projectDir> --content-only --platform <name> [--out <dir>] [--preset <name>] [--rebuild]
			""");
		return 1;
	}
}
