using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Engine.Project; // ProjectLayout.DistDir: where exports go

namespace Sedulous.Editor.Mcp;

/// project_export: preset resolution and the result shape here, the work through the host's
/// operations (inline on the stdio host, the editor's export job otherwise), which reach the
/// ONE export entry point, the same call the editor's Export menu and the CLI make, so an MCP
/// export produces an identical dist. The presets come from the project's
/// export_presets.xml, else the synthesized host preset.
static class ProjectExportTool
{
	/// How long the editor host lets an export run by default, and at most, in seconds: past the
	/// host's own 600 s step, since a project's first shipping or web build compiles the engine
	/// before the cook.
	public const double cDefaultTimeoutSeconds = 1800;
	public const double cMaxTimeoutSeconds = 7200;
	/// How many of the player's build diagnostics the answer lists, errors first; build_status
	/// has the whole build.
	public const int cBuildDiagnostics = 10;

	private class Context
	{
		public ProjectSession Session;
		public IProjectOperations Operations;
	}

	public static void Register(McpServer server, ProjectSession session, IProjectOperations operations)
	{
		let context = new Context();
		context.Session = session;
		context.Operations = operations;

		let schema = scope SchemaBuilder();
		schema.Str("preset", "preset name (default: the project's first preset)");
		schema.Str("out", "output root directory (default: <project>/Dist)");
		schema.Boolean("rebuild", "force a full re-cook first (default incremental)");
		schema.Boolean("build", "build the player with BeefBuild (default true); false ships the player the last build of the preset's platform and config left, refused when there is none");
		schema.Number("timeoutSeconds", "in the editor, how long the export may run before the call answers with an error (default 1800, at most 7200); the export goes on");
		server.RegisterTool("project_export",
			"""
			Export the open project into a shippable dist: build the game's own player for the preset's platform and config with BeefBuild (incremental; a project's first shipping or web build compiles the engine and takes minutes), cook everything, stage the scenes, pack the content and cook the shader pack - the same single entry point the editor's Export menu and the export CLI use, so the result is identical. Long-running. Presets come from the project's export_presets.xml (default: the first; no file = a synthesized host-platform preset); export_presets says which build here. REFUSED for another host's platform (a Win64 player builds on Windows), a web preset without Emscripten, a plugin that cannot ship, and a player that does not compile (the refusal quotes its first errors; build_status has the whole build). Returns the output directory, the cook/stage/pack counts, `player` (what was built) and `build` (built: false when nothing compiled; else the build as project_build answers it, at most 10 diagnostics); run project_health first to catch breakage before a long export.
			""",
			schema.Build(), .Rebuilds,
			new (call, arguments, outResult, outError) => Export(context, call, arguments, outResult, outError),
			context);
	}

	private static ToolOutcome Export(Context context, ToolCall call, JsonValue arguments, JsonValue outResult, String outError)
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

		let outArg = McpTools.ArgString(arguments, "out", .. scope .());
		let outRoot = scope String();
		if (!outArg.IsEmpty)
			outRoot.Set(outArg);
		else
			PathJoin(project.Directory, ProjectLayout.DistDir, outRoot);
		ExportRequest request = .();
		request.Preset = preset;
		request.OutRoot = outRoot;
		request.Rebuild = McpTools.ArgBool(arguments, "rebuild");
		request.Build = McpTools.ArgBool(arguments, "build", true);
		request.TimeoutSeconds = Math.Clamp(McpTools.ArgNumber(arguments, "timeoutSeconds", cDefaultTimeoutSeconds), 1.0, cMaxTimeoutSeconds);
		let result = scope ExportResult();
		switch (context.Operations.Export(call, request, result, outError))
		{
		case .Failed: return .Failed;
		case .NotYet: return .NotFinished; // the host's export is still running
		case .Finished:
		}
		outResult.Set("exported", JsonValue.MakeBool(true));
		outResult.Set("preset", JsonValue.MakeString(preset.Name));
		outResult.Set("outputDir", JsonValue.MakeString(result.OutputDir));
		outResult.Set("cooked", JsonValue.MakeNumber((double)result.Content.Cooked));
		outResult.Set("cookFailed", JsonValue.MakeNumber((double)result.Content.CookFailed));
		outResult.Set("scenesStaged", JsonValue.MakeNumber((double)result.Content.ScenesStaged));
		outResult.Set("filesPacked", JsonValue.MakeNumber((double)result.Content.FilesPacked));
		outResult.Set("filesStaged", JsonValue.MakeNumber((double)result.FilesStaged));
		outResult.Set("player", JsonValue.MakeString(result.PlayerReason));
		// The player's build as project_build answers one, or built: false when nothing compiled
		// it (the last build reused).
		let build = JsonValue.MakeObject();
		build.Set("built", JsonValue.MakeBool(result.PlayerJob != null));
		if (result.PlayerJob != null)
			BuildJobJson.Write(result.PlayerJob, build, cBuildDiagnostics);
		outResult.Set("build", build);
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
