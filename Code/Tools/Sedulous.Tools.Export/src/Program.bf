using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Engine.SceneSurface;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;

namespace Sedulous.Tools.Export;

/// The command line exporter: a project into a shippable dist through the ONE entry point
/// the editor's Export menu and the MCP host share, and the template subcommands.
///
/// Usage:
///   Sedulous.Tools.Export <projectDir> [--out <dir>] [--preset <name> | --all] [--rebuild] [--data-root <dir>]
///   Sedulous.Tools.Export --template list
///   Sedulous.Tools.Export --template import <templateDir>
///   Sedulous.Tools.Export --template create <playerDir> [--install | --out <folder>]
///
/// The host template is the player built beside this tool, build/<Config>_<Platform>/
/// Sedulous.Engine.Player.Desktop; the templates root is $SEDULOUS_TEMPLATES_DIR, else
/// <user-data>/templates. The engine data root, whose Shaders the export cooks, is found by
/// the Data/.dataroot walk from this tool, or --data-root.
class Program
{
	public static int Main(String[] args)
	{
		InitGlobalLogger(new ConsoleLogger(.Information, "Export"), true);
		defer ShutdownGlobalLogger();

		if ((args.Count >= 1) && (args[0] == "--template"))
		{
			if (args.Count < 2)
				return Usage();
			switch (args[1])
			{
			case "list": return TemplateList();
			case "import":
				if (args.Count < 3)
					return Usage();
				return TemplateImport(args[2]);
			case "create": return TemplateCreate(args);
			default: return Usage();
			}
		}
		if (args.Count < 1)
			return Usage();

		let projectDir = args[0];
		let outArg = scope String();
		let presetName = scope String();
		bool all = false;
		bool rebuild = false;
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

		let project = EditorProject.Open(projectDir);
		if (project == null)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: failed to open project '{}'", projectDir);
			return 1;
		}
		defer delete project;

		// The pipeline's composition root, and the builders it fills.
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);

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
		let registry = scope TemplateRegistry();
		BuildRegistry(registry);
		let outRoot = scope String();
		if (!outArg.IsEmpty)
			outRoot.Set(outArg);
		else
			PathJoin(project.Directory, "Dist", outRoot);
		let dataRoot = scope String();
		ResolveDataRoot(args, dataRoot);
		if (dataRoot.IsEmpty)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: no data root (put Data/ with its .dataroot marker beside the tool, or pass --data-root <dir>)");
			return 1;
		}

		if (all)
		{
			if (ExportDriver.ExportAll(project, presets.Presets, registry, builders, outRoot, dataRoot, rebuild, null, true, sceneStreams, scanner) case .Err)
			{
				Console.Error.WriteLine("Sedulous.Tools.Export: one or more presets failed (see log)");
				return 1;
			}
			Console.WriteLine("export done: {} preset(s) -> {}", presets.Presets.Count, outRoot);
			return 0;
		}
		let preset = presetName.IsEmpty ? (presets.Presets.IsEmpty ? null : presets.Presets[0]) : presets.Find(presetName);
		if (preset == null)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: no preset{}", presetName.IsEmpty ? " defined" : scope $" named {presetName}");
			return 1;
		}
		let result = scope ExportResult();
		if (ExportDriver.ExportOne(project, preset, registry, builders, outRoot, dataRoot, rebuild, result, null, true, sceneStreams, scanner) case .Err)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: export failed (see log)");
			return 1;
		}
		Console.WriteLine("exported '{}' -> {}\n  cook: {} cooked, {} scene(s), {} packed | staged {} file(s)",
			preset.Name, result.OutputDir, result.Content.Cooked, result.Content.ScenesStaged, result.Content.FilesPacked, result.FilesStaged);
		if (!result.EngineVersionWarning.IsEmpty)
			Console.WriteLine("  warning: {}", result.EngineVersionWarning);
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
			  Sedulous.Tools.Export --template list
			  Sedulous.Tools.Export --template import <templateDir>
			  Sedulous.Tools.Export --template create <playerDir> [--install | --out <folder>]
			""");
		return 1;
	}

	private static void TemplatesRoot(String outPath) => ExportTemplates.ResolveRoot("", outPath);

	/// The bundles under the templates root plus the host player beside this tool.
	private static void BuildRegistry(TemplateRegistry registry)
	{
		let playerDir = BuildLayout.PlayerDirectoryBeside(GetExecutableDirectory(.. scope .()), .. scope .());
		registry.Refresh(TemplatesRoot(.. scope .()), playerDir);
	}

	private static int TemplateList()
	{
		let registry = scope TemplateRegistry();
		BuildRegistry(registry);
		Console.WriteLine("export templates (root: {}):", TemplatesRoot(.. scope .()));
		for (int i < registry.Count)
		{
			let template = registry.At(i);
			Console.WriteLine("  {,-32} {,-8} {}{}", template.Id, template.Platform, template.Name, template.IsHost ? "  [host]" : "");
		}
		return 0;
	}

	private static int TemplateImport(StringView srcDir)
	{
		let root = TemplatesRoot(.. scope .());
		let importedId = scope String();
		if (ExportTemplates.Import(srcDir, root, importedId) case .Err)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: failed to import '{}' (no valid template.xml?)", srcDir);
			return 1;
		}
		Console.WriteLine("imported template '{}' -> {}", importedId, PathJoin(root, importedId, .. scope .()));
		return 0;
	}

	private static int TemplateCreate(String[] args)
	{
		if (args.Count < 3)
			return Usage();
		let playerDir = args[2];
		bool install = true;
		let outFolder = scope String();
		for (int i = 3; i < args.Count; i++)
		{
			if (args[i] == "--install")
				install = true;
			else if ((args[i] == "--out") && (i + 1 < args.Count))
			{
				install = false;
				outFolder.Set(args[++i]);
			}
			else
			{
				Console.Error.WriteLine("unknown option: {}", args[i]);
				return Usage();
			}
		}
		let destRoot = install ? TemplatesRoot(.. scope :: .()) : StringView(outFolder);
		let createdId = scope String();
		let createdDir = scope String();
		if (ExportTemplates.Create(playerDir, destRoot, install ? .Install : .ExportFolder, createdId, createdDir) case .Err)
		{
			Console.Error.WriteLine("Sedulous.Tools.Export: failed to create a template from '{}' (no player binary there?)", playerDir);
			return 1;
		}
		Console.WriteLine("created template '{}' -> {}", createdId, createdDir);
		return 0;
	}
}
