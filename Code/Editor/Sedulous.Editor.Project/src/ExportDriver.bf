using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Engine.Project;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.VFS;
using Sedulous.VFS.Pak;
using Sedulous.Runtime;

namespace Sedulous.Editor.Project;

/// The export: a project into a shippable dist. Build the game's player for the preset (an
/// IPlayerBuilder: the project's own, its packages and the engine plugins it enables linked
/// in); cook everything, or the reachable closure of the entry points when the preset prunes;
/// stage the scenes as binary products; pack the cooked content, one pak on the desktop and the
/// BC and ASTC siblings on the web; write the dist manifest; cook the shader pack into the
/// dist's Data; stage the player, the files its build left beside it and the preset's extra
/// files. The project's plugins refuse an export they cannot ship (ExportPlugins.Check), and
/// another host's desktop platform is refused, both before anything builds. The plugins'
/// deploy files ship beside the player, and their export hooks run over the staged dist. The
/// ONE entry point the editor's Export menu, the CLI and the MCP host share, so a preset
/// produces the same dist whichever surface triggers it.
static class ExportDriver
{
	// ---- the scene streams ----

	/// The scene and prefab TEXT sources under the group, pre-transcoded to the binary wire by
	/// the stager (the editor's SceneStreamStager: main thread only) and keyed by instance for
	/// the export's packer. The map owns its lists. An instance the stager declines (not a
	/// scene, or a failure) is left out; the exporter then stages its source verbatim.
	public static void CollectSceneStreams(Group group, delegate bool(Instance instance, List<uint8> outBytes) stager,
		Dictionary<Guid, List<uint8>> outStreams)
	{
		for (let instance in group.Instances)
		{
			let bytes = new List<uint8>();
			if (stager(instance, bytes))
			{
				if (outStreams.TryGetValue(instance.Id, let old))
					delete old;
				outStreams[instance.Id] = bytes;
			}
			else
			{
				delete bytes;
			}
		}
		for (let child in group.Groups)
			CollectSceneStreams(child, stager, outStreams);
	}

	// ---- the reachable closure ----

	/// The seeds: the manifest's guid fields, the Always Export instances and the members of
	/// the Always Export groups, deduplicated by guid. The caller owns the roots.
	public static void CollectExportRoots(EditorProject project, List<ExportRoot> outRoots)
	{
		let seen = scope HashSet<Guid>();
		void Add(Guid id, ExportRootReason reason)
		{
			if (!id.IsSet || seen.Contains(id))
				return;
			seen.Add(id);
			let root = new ExportRoot();
			root.Id = id;
			root.Reason = reason;
			if (let instance = project.SourceDb.GetInstance(id))
				instance.GetPath(root.Name);
			outRoots.Add(root);
		}
		let settings = project.Settings;
		Add(settings.DefaultSceneId, .DefaultScene);
		Add(settings.StartupScriptId, .StartupScript);
		Add(settings.DefaultInputMapId, .ManifestDefault);
		Add(settings.DefaultBusLayoutId, .ManifestDefault);
		Add(settings.DefaultUiFontId, .ManifestDefault);
		for (let id in settings.UiFontIds)
			Add(id, .ManifestDefault);
		for (let id in settings.GuiStyleSheetIds)
			Add(id, .ManifestDefault);
		Add(settings.GuiLoadingDocumentId, .ManifestDefault);
		for (let id in project.ExportRoots.Instances)
			Add(id, .Flag);
		for (let groupPath in project.ExportRoots.Groups)
		{
			let members = scope List<Guid>();
			ExportRootsFile.CollectGroupInstances(project.SourceDb, groupPath, members);
			for (let id in members)
				Add(id, .Group);
		}
	}

	/// The seeds and everything a scene or prefab among them references, transitively.
	public static void ExpandReachableRoots(EditorProject project, List<ExportRoot> seeds, SceneReferenceScanner scanner, List<Guid> outRoots)
	{
		let seen = scope HashSet<Guid>();
		let queue = scope List<Guid>();
		void Push(Guid id)
		{
			if (!id.IsSet || seen.Contains(id))
				return;
			seen.Add(id);
			outRoots.Add(id);
			queue.Add(id);
		}
		for (let root in seeds)
			Push(root.Id);
		int head = 0;
		while (head < queue.Count)
		{
			let id = queue[head++];
			let instance = project.SourceDb.GetInstance(id);
			if ((instance == null) || !ExportStaging.IsSceneLike(instance) || (scanner == null))
				continue;
			let refs = scope SceneReferences();
			scanner(instance, project.SourceDb, refs);
			for (let g in refs.Resources)
				Push(g);
			for (let g in refs.Prefabs)
				Push(g);
		}
	}

	/// Plans the closure of `planRoots` and, when `cook`, cooks it; `outReachable` is the
	/// plan's reachable set either way.
	public static Result<void, ErrorCode> CookReachable(EditorProject project, BuilderRegistry builders, Span<Guid> planRoots,
		bool cook, bool rebuild, ExportStats stats, List<Guid> outReachable, ExportProgress onProgress = null)
	{
		let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let jobs = scope JobSystem();
		let driver = scope CookDriver(project.SourceDb, project.CookedDb, builders, sourcesMount, cacheMount, jobs);
		let plan = scope CookPlan();
		driver.PlanFor(planRoots, plan, rebuild);
		outReachable.AddRange(plan.Reachable);
		if (cook)
		{
			let progress = scope CookProgress();
			progress.OnItem = new [=onProgress](done, total, path, ok) => { ReportCookStep(onProgress, done, total, path); };
			defer delete progress.OnItem;
			let cookStats = scope CookStats();
			driver.Execute(plan, cookStats, progress);
			stats.Cooked = cookStats.Cooked;
			stats.CookFailed = cookStats.Failed;
			if (cookStats.Failed > 0)
			{
				GlobalLog(.Error, "Export: aborting - the cook has {} failure(s)", cookStats.Failed);
				return .Err(.Internal);
			}
		}
		return .Ok;
	}

	/// The cook's share of an export's progress: after the player's build
	/// (PlayerBuild.cProgressStart..cProgressEnd), up to the variants at 0.6.
	public const float cCookStart = 0.42f;
	public const float cCookEnd = 0.6f;

	/// The cook occupies cCookStart..cCookEnd of the export.
	private static void ReportCookStep(ExportProgress onProgress, int done, int total, StringView path)
	{
		if (onProgress == null)
			return;
		let fraction = (total > 0) ? cCookStart + ((float)done / (float)total) * (cCookEnd - cCookStart) : cCookEnd;
		onProgress(scope $"Cooking {path}", fraction);
	}

	// ---- variants ----

	/// The desktop's single pak from the host database; a web build's BC and ASTC siblings
	/// and an Android build's one ASTC pak from their own per target databases.
	public static void VariantsForPlatform(EditorProject project, StringView platform, List<ContentVariant> outVariants)
	{
		if (ExportStaging.IsWebPlatform(platform))
		{
			for (let key in scope String[]("bc", "astc"))
			{
				let variant = new ContentVariant();
				variant.Key.Set(key);
				variant.PakName.Set(scope $"Content-{key}.pak");
				variant.CookedDir.Set(scope $"{project.Directory}/Cooked-web-{key}");
				variant.TargetId.Set(scope $"web-{key}");
				outVariants.Add(variant);
			}
		}
		else if (platform.StartsWith("Android"))
		{
			// One pak, its textures ASTC (Android's GPUs do not read BC), cooked into a sibling
			// of the host Cooked/ as Sedulous.Tools.Cook --target android does.
			let variant = new ContentVariant();
			variant.Key.Set("android");
			variant.PakName.Set(ProjectLayout.DistContentPak);
			variant.CookedDir.Set(scope $"{project.Directory}/Cooked-android");
			variant.TargetId.Set("android");
			outVariants.Add(variant);
		}
		else
		{
			let variant = new ContentVariant();
			variant.PakName.Set(ProjectLayout.DistContentPak);
			PathJoin(project.Directory, ProjectLayout.CookedDir, variant.CookedDir);
			outVariants.Add(variant);
		}
	}

	/// Cooks every keyed variant's target database beside the host's, the invariant
	/// products carried forward; the desktop's host database already IS its variant.
	public static Result<void, ErrorCode> CookVariantTargets(EditorProject project, BuilderRegistry builders, List<ContentVariant> variants,
		bool rebuild, ExportProgress onProgress = null)
	{
		let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let hostRecords = scope CookDb();
		hostRecords.Load(cacheMount);
		let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let jobs = scope JobSystem();
		int failed = 0;
		for (let variant in variants)
		{
			if (variant.Key.IsEmpty)
				continue;
			if (onProgress != null)
				onProgress(scope $"Cooking variant {variant.Key}", 0.6f);
			// The variant's cook target resolves to its capability profile (ASTC or BC).
			let targetId = variant.TargetId;
			let cacheDir = PathJoin(project.CacheRoot(.. scope .()), targetId, .. scope .());
			CreateDirectory(variant.CookedDir);
			CreateDirectory(cacheDir);
			let targetCookedMount = scope NativeFileSystem(variant.CookedDir);
			let targetCacheMount = scope NativeFileSystem(cacheDir);
			SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
			let targetDb = scope ContentDatabase(targetCookedMount, binary, ProjectLayout.CookedAssetExtension);
			let stats = scope CookStats();
			CookDriver.CookForTarget(project.SourceDb, targetDb, project.CookedDb, hostRecords, builders,
				sourcesMount, targetCacheMount, CookTarget.For(targetId), stats, jobs, rebuild);
			failed += stats.Failed;
			GlobalLog(.Information, "Export: variant '{}' cooked {}, copied forward {}, failed {}", variant.Key, stats.Cooked, stats.CopiedForward, stats.Failed);
		}
		return (failed == 0) ? .Ok : .Err(.Internal);
	}

	// ---- content ----

	/// Stages the scenes, packs each variant's cooked tree with them, writes the dist
	/// manifest, and with a reachable set prunes and reports. `sceneStreams` pre-transcoded
	/// scene bytes by guid, null for verbatim. The project's custom shaders are recorded in
	/// `stats` for the shader pack step and staged without their HLSL unless
	/// `includeShaderSource`.
	public static Result<void, ErrorCode> ExportContent(EditorProject project, StringView outDir, ExportStats stats,
		ExportProgress onProgress, Dictionary<Guid, List<uint8>> sceneStreams, HashSet<Guid> reachable,
		List<ExportRoot> roots, PruningReport outReport, List<ContentVariant> variants, bool includeShaderSource = false)
	{
		if (onProgress != null)
			onProgress("Staging scenes...", 0.65f);
		if (!CreateDirectory(outDir))
			return .Err(.NotSupported);
		let stagingDir = PathJoin(outDir, ".stage-scenes", .. scope .());
		CreateDirectory(stagingDir);
		defer RemoveDirectoryRecursive(stagingDir);
		let stagingMount = scope NativeFileSystem(stagingDir);
		let droppedScenes = scope List<String>();
		defer { ClearAndDeleteItems(droppedScenes); }
		// Cooked products replaced by a staged, stripped copy.
		let strippedShaders = scope HashSet<String>();
		defer { for (let path in strippedShaders) delete path; }
		{
			SerializerFactory binary = scope (stream, mode) => new BinarySerializerContext(stream, mode);
			let staging = scope ContentDatabase(stagingMount, binary, ProjectLayout.CookedAssetExtension);
			let scenes = scope List<Instance>();
			ExportStaging.CollectScenes(project.SourceDb.RootGroup, scenes);
			int staged = 0;
			for (let scene in scenes)
			{
				if ((reachable != null) && !reachable.Contains(scene.Id))
				{
					droppedScenes.Add(scene.GetPath(.. new String()));
					continue;
				}
				if (!ExportStaging.StageScene(scene, staging, sceneStreams))
				{
					GlobalLog(.Error, "Export: failed to stage scene '{}'", scene.GetPath(.. scope .()));
					return .Err(.Internal);
				}
				staged++;
			}
			stats.ScenesStaged = staged;

			// The project's custom shaders the dist ships: recorded for the shader pack step,
			// which cooks them to bytecode; staged without their HLSL unless the preset keeps it
			// (the project's own Cooked/ keeps its source for the editor, so a copy is staged).
			let shaderType = typeof(Sedulous.Shaders.Resource.ShaderSource).GetFullName(.. scope .());
			let products = scope List<Instance>();
			ExportStaging.CollectAllInstances(project.CookedDb.RootGroup, products);
			for (let product in products)
			{
				if ((product.TypeName != shaderType) || ((reachable != null) && !reachable.Contains(product.Id)))
					continue;
				stats.Shaders.Add(product.Id);
				if (includeShaderSource)
					continue;
				if (!ExportStaging.StageStrippedShader(product, staging))
				{
					GlobalLog(.Error, "Export: failed to stage shader '{}'", product.GetPath(.. scope .()));
					return .Err(.Internal);
				}
				strippedShaders.Add(product.GetPath(.. new String()));
			}
		}

		HashSet<String> reachablePaths = null;
		defer { if (reachablePaths != null) DeleteContainerAndItems!(reachablePaths); }
		int keptProducts = 0;
		let droppedProducts = scope List<String>();
		defer { ClearAndDeleteItems(droppedProducts); }
		if (reachable != null)
		{
			reachablePaths = new HashSet<String>();
			let cooked = scope List<Instance>();
			ExportStaging.CollectAllInstances(project.CookedDb.RootGroup, cooked);
			for (let product in cooked)
			{
				if (reachable.Contains(product.Id))
				{
					reachablePaths.Add(product.GetPath(.. new String()));
					keptProducts++;
				}
			}
			let sources = scope List<Instance>();
			ExportStaging.CollectAllInstances(project.SourceDb.RootGroup, sources);
			for (let source in sources)
				if (!ExportStaging.IsSceneLike(source) && !reachable.Contains(source.Id))
					droppedProducts.Add(source.GetPath(.. new String()));
		}

		if (onProgress != null)
			onProgress("Packing content...", 0.78f);
		let effective = scope List<ContentVariant>();
		bool ownVariants = false;
		if (variants.IsEmpty)
		{
			VariantsForPlatform(project, BuildLayout.HostPlatformName, effective);
			ownVariants = true;
		}
		else
			effective.AddRange(variants);
		defer { if (ownVariants) ClearAndDeleteItems(effective); }
		for (let variant in effective)
		{
			let pak = scope PakBuilder();
			let cookedMount = scope NativeFileSystem(variant.CookedDir);
			if (!ExportStaging.PackTree(cookedMount, "", pak, ref stats.FilesPacked, reachablePaths, strippedShaders)
				|| !ExportStaging.PackTree(stagingMount, "", pak, ref stats.FilesPacked, null))
			{
				GlobalLog(.Error, "Export: packing failed for variant '{}'", variant.PakName);
				return .Err(.Internal);
			}
			if (pak.Write(PathJoin(outDir, variant.PakName, .. scope .())) case .Err)
			{
				GlobalLog(.Error, "Export: failed to write '{}'", variant.PakName);
				return .Err(.Internal);
			}
		}

		if (onProgress != null)
			onProgress("Writing manifest...", 0.9f);
		{
			let outMount = scope NativeFileSystem(outDir);
			// Every setting, through the settings' own serialization: a hand-kept copy missed the
			// loading screen and the MSAA once already. A preset overriding the display rewrites
			// it after (ApplyPresetDisplay).
			let dist = scope ProjectSettings();
			if (ProjectManifest.Copy(project.Settings, dist) case .Err)
			{
				GlobalLog(.Error, "Export: failed to copy the project settings into the dist manifest");
				return .Err(.Internal);
			}
			if (ProjectManifest.Save(outMount, dist, ProjectLayout.DistManifestFile) case .Err)
			{
				GlobalLog(.Error, "Export: failed to write the dist manifest");
				return .Err(.Internal);
			}
		}

		if (reachable != null)
		{
			let report = scope PruningReport();
			report.Pruned = true;
			if (roots != null)
				for (let root in roots)
					report.Roots.Add(root.Clone());
			report.KeptCount = stats.ScenesStaged + keptProducts;
			for (let dropped in droppedScenes)
				report.Dropped.Add(new String(dropped));
			for (let dropped in droppedProducts)
				report.Dropped.Add(new String(dropped));
			let text = report.Format(.. scope .());
			GlobalLog(.Information, "Export: pruned dist: {} kept, {} dropped ({} root(s))", report.KeptCount, report.Dropped.Count, report.Roots.Count);
			WriteFile(PathJoin(outDir, "export-report.txt", .. scope .()), .((uint8*)text.Ptr, text.Length)).IgnoreError();
			if (outReport != null)
				report.CopyTo(outReport);
		}
		return .Ok;
	}

	/// The whole project cooked, the variants cooked, and the content exported.
	public static Result<void, ErrorCode> ExportProject(EditorProject project, StringView outDir, BuilderRegistry builders, bool rebuild,
		ExportStats outStats = null, ExportProgress onProgress = null, Dictionary<Guid, List<uint8>> sceneStreams = null,
		List<ContentVariant> variants = null, bool includeShaderSource = false)
	{
		let stats = scope ExportStats();
		defer { if (outStats != null) stats.CopyTo(outStats); }
		if (onProgress != null)
			onProgress("Cooking content...", cCookStart);
		{
			let sourcesMount = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
			let cacheMount = scope NativeFileSystem(project.CacheRoot(.. scope .()));
			let jobs = scope JobSystem();
			let driver = scope CookDriver(project.SourceDb, project.CookedDb, builders, sourcesMount, cacheMount, jobs);
			let plan = scope CookPlan();
			driver.Plan(plan, rebuild);
			let progress = scope CookProgress();
			progress.OnItem = new [=onProgress](done, total, path, ok) => { ReportCookStep(onProgress, done, total, path); };
			defer delete progress.OnItem;
			let cookStats = scope CookStats();
			driver.Execute(plan, cookStats, progress);
			stats.Cooked = cookStats.Cooked;
			stats.CookFailed = cookStats.Failed;
			if (cookStats.Failed > 0)
			{
				GlobalLog(.Error, "Export: aborting - the cook has {} failure(s)", cookStats.Failed);
				return .Err(.Internal);
			}
		}
		let effective = scope List<ContentVariant>();
		if (variants != null)
			effective.AddRange(variants);
		if (!effective.IsEmpty && (CookVariantTargets(project, builders, effective, rebuild, onProgress) case .Err))
		{
			GlobalLog(.Error, "Export: aborting - a variant cook failed");
			return .Err(.Internal);
		}
		return ExportContent(project, outDir, stats, onProgress, sceneStreams, null, null, null, effective, includeShaderSource);
	}

	// ---- one preset ----

	/// A preset's own render resolution, window or orientation, over what the project's dist
	/// manifest says: the platform's values ship in its player.xml. Nothing to do when it
	/// overrides none.
	public static Result<void, ErrorCode> ApplyPresetDisplay(StringView outDir, ExportPreset preset)
	{
		if (!preset.OverridesRender && !preset.OverridesWindow && !preset.OverridesOrientation)
			return .Ok;
		let mount = scope NativeFileSystem(outDir);
		let dist = scope ProjectSettings();
		if (ProjectManifest.Load(mount, dist, ProjectLayout.DistManifestFile) case .Err(let error))
		{
			GlobalLog(.Error, "Export: the dist manifest did not read back for the preset's display");
			return .Err(error);
		}
		if (preset.OverridesRender)
		{
			dist.RenderWidth = preset.RenderWidth;
			dist.RenderHeight = preset.RenderHeight;
			dist.RenderFit = preset.RenderFit;
		}
		if (preset.OverridesWindow)
		{
			dist.WindowWidth = preset.WindowWidth;
			dist.WindowHeight = preset.WindowHeight;
			dist.WindowMode = preset.WindowMode;
			dist.WindowResizable = preset.WindowResizable;
		}
		if (preset.OverridesOrientation)
			dist.Orientation = preset.Orientation;
		if (ProjectManifest.Save(mount, dist, ProjectLayout.DistManifestFile) case .Err(let saveError))
		{
			GlobalLog(.Error, "Export: failed to write the preset's display into the dist manifest");
			return .Err(saveError);
		}
		return .Ok;
	}

	/// Whether `platform` is a desktop platform whose player builds on another host than this one:
	/// BeefBuild builds a desktop player for its own host alone (the web builds on any).
	public static bool BuildsOnAnotherHost(StringView platform)
	{
		return ((platform == "Linux64") || (platform == "Win64") || (platform == "macOS")) && (platform != BuildLayout.HostPlatformName);
	}

	/// Exports one preset into <outRoot>/<subdir>. Refused before anything is built or written:
	/// a plugin the export cannot ship (ExportPlugins.Check, its packages found in the project
	/// or the engine SDK `dataRoot` is in), another host's desktop platform or a config no player
	/// is built in (ProjectPlayerBuilder.Target), and a script that cannot run on the platform.
	/// Then the player is built by `players` for the preset's platform and config, so a compile
	/// error refuses before the cook; the content is cooked and packed, whole or pruned to the
	/// closure when the preset asks and a scanner or a precomputed root set is at hand; the
	/// shader pack is cooked from `dataRoot`; and the player (named by the preset, else by the
	/// game), the files its build left beside it, its symbols when opted in, the extra files and
	/// the plugins' deploy files are staged before the plugins' export hooks run. `contentOnly`
	/// stages what the game reads and no player: the content pak(s), player.xml and the shader
	/// pack, with no player built (an Android app's assets, which its own build packs beside the
	/// player library).
	public static Result<void, ErrorCode> ExportOne(EditorProject project, ExportPreset preset, IPlayerBuilder players,
		BuilderRegistry builders, StringView outRoot, StringView dataRoot, bool rebuild, ExportResult outResult = null,
		ExportProgress onProgress = null, bool cook = true, Dictionary<Guid, List<uint8>> sceneStreams = null,
		SceneReferenceScanner scanner = null, List<Guid> precomputedReachableRoots = null, ExportPluginServices hooks = null,
		PluginHost plugins = null, bool contentOnly = false)
	{
		let result = scope ExportResult();
		defer
		{
			if (outResult != null)
			{
				result.Content.CopyTo(outResult.Content);
				outResult.FilesStaged = result.FilesStaged;
				outResult.OutputDir.Set(result.OutputDir);
				outResult.EngineVersionWarning.Set(result.EngineVersionWarning);
				result.Pruning.CopyTo(outResult.Pruning);
				outResult.PlayerReason.Set(result.PlayerReason);
				outResult.Refusal.Set(result.Refusal);
				outResult.SetPlayerJob(result.PlayerJob);
			}
		}
		// The project's plugins: each found in the project's package or the SDK's, and supported
		// where it is enabled. An SDK not found leaves the engine's plugins in no package.
		let sdk = scope String();
		ProjectBuild.FindSdk(dataRoot, sdk);
		let enabled = scope List<String>();
		defer { ClearAndDeleteItems!(enabled); }
		if (!ExportPlugins.Check(project, sdk, preset.Platform, enabled, result.Refusal))
		{
			GlobalLog(.Error, "Export: preset '{}': {}", preset.Name, result.Refusal);
			return .Err(.InvalidArgument);
		}
		// The platform against this host, and the config: what the build would refuse, said
		// before the scripts are checked. A content-only export builds no player.
		if (!contentOnly)
		{
			let config = scope String();
			BuildEntry entry;
			if (ProjectPlayerBuilder.Target(preset, out entry, config, result.Refusal) case .Err(let refused))
			{
				GlobalLog(.Error, "Export: preset '{}': {}", preset.Name, result.Refusal);
				return .Err(refused);
			}
		}
		// The project's scripts against what the platform has of its plugins (as `plugins` loaded
		// them), before anything builds or cooks: a script cooks once and ships to every platform.
		ExportPlugins.CheckScriptsOn(project, plugins, preset.Platform, result.Refusal);
		if (!result.Refusal.IsEmpty)
		{
			GlobalLog(.Error, "Export: preset '{}': {}", preset.Name, result.Refusal);
			return .Err(.InvalidArgument);
		}
		// The player, built before the cook: a compile error refuses before minutes of cooking.
		let build = scope PlayerBuild();
		if (!contentOnly)
		{
			if (players.Build(project, preset, build, onProgress, result.Refusal) case .Err(let failed))
			{
				if (result.Refusal.IsEmpty)
					result.Refusal.Set("the player did not build");
				GlobalLog(.Error, "Export: preset '{}': {}", preset.Name, result.Refusal);
				return .Err(failed);
			}
			result.PlayerReason.Set(build.Description);
			result.SetPlayerJob(build.Job);
			GlobalLog(.Information, "Export: preset '{}': player {}", preset.Name, build.Description);
		}

		let subdir = preset.OutputSubdir.IsEmpty ? ExportStaging.SanitizeName(preset.Name, .. scope :: .()) : StringView(preset.OutputSubdir);
		PathJoin(outRoot, subdir, result.OutputDir);
		CreateDirectory(result.OutputDir);

		var prune = preset.PruneToReachable;
		if (prune && (scanner == null) && (precomputedReachableRoots == null))
		{
			GlobalLog(.Warning, "Export: preset '{}' requests pruning but no scene-reference scanner or precomputed root set was supplied - exporting everything", preset.Name);
			prune = false;
		}
		let variants = scope List<ContentVariant>();
		defer { ClearAndDeleteItems(variants); }
		VariantsForPlatform(project, preset.Platform, variants);

		Result<void, ErrorCode> contentStatus = .Ok;
		if (prune)
		{
			let seeds = scope List<ExportRoot>();
			defer { ClearAndDeleteItems(seeds); }
			CollectExportRoots(project, seeds);
			let planRoots = scope List<Guid>();
			if (precomputedReachableRoots != null)
				planRoots.AddRange(precomputedReachableRoots);
			else
				ExpandReachableRoots(project, seeds, scanner, planRoots);
			let reachableList = scope List<Guid>();
			contentStatus = CookReachable(project, builders, planRoots, cook, rebuild, result.Content, reachableList, onProgress);
			if (contentStatus case .Ok)
				contentStatus = CookVariantTargets(project, builders, variants, rebuild, onProgress);
			if (contentStatus case .Ok)
			{
				let reachable = scope HashSet<Guid>();
				for (let g in reachableList)
					reachable.Add(g);
				contentStatus = ExportContent(project, result.OutputDir, result.Content, onProgress, sceneStreams, reachable, seeds, result.Pruning, variants, preset.IncludeShaderSource);
			}
		}
		else if (cook)
		{
			contentStatus = ExportProject(project, result.OutputDir, builders, rebuild, result.Content, onProgress, sceneStreams, variants, preset.IncludeShaderSource);
		}
		else
		{
			contentStatus = CookVariantTargets(project, builders, variants, rebuild, onProgress);
			if (contentStatus case .Ok)
				contentStatus = ExportContent(project, result.OutputDir, result.Content, onProgress, sceneStreams, null, null, null, variants, preset.IncludeShaderSource);
		}
		if (contentStatus case .Err)
			return .Err(.Internal);
		if (ApplyPresetDisplay(result.OutputDir, preset) case .Err)
			return .Err(.Internal);

		if (contentOnly)
		{
			// What the game reads and no player: the shader pack beside the content, and done.
			if (ExportStaging.StageShaderPack(result.OutputDir, dataRoot, preset.Platform, project.CookedDb, result.Content.Shaders,
				let shaderVariants) case .Err)
				return .Err(.Internal);
			result.FilesStaged += 2; // the pack and the marker
			GlobalLog(.Information, "Export: preset '{}': content only, at '{}' ({} shader variants)", preset.Name, result.OutputDir, shaderVariants);
			return .Ok;
		}

		if (onProgress != null)
			onProgress("Staging player...", 0.93f);
		// Named by the preset, else by the game ("SkyHopper", not the build's SkyHopperPlayer).
		let playerName = scope String(preset.PlayerName);
		if (playerName.IsEmpty)
			ProjectBuild.GameName(project.Name, playerName);
		let outName = ExportStaging.PlayerOutputName(preset.Platform, playerName, build.Binary, .. scope .());
		if (!FileCopy.CopyFile(build.Directory, build.Binary, result.OutputDir, outName))
		{
			GlobalLog(.Error, "Export: failed to stage player '{}' from {}", build.Binary, build.Directory);
			return .Err(.Internal);
		}
		result.FilesStaged++;

		if (onProgress != null)
			onProgress("Cooking shaders...", 0.95f);
		{
			if (ExportStaging.StageShaderPack(result.OutputDir, dataRoot, preset.Platform, project.CookedDb, result.Content.Shaders,
				let shaderVariants) case .Err)
				return .Err(.Internal);
			result.FilesStaged += 2;
			GlobalLog(.Information, "Export: staged Data/{} ({} variants)", Sedulous.Shaders.ShaderSystemHost.cShaderPackPath, shaderVariants);
		}

		// What the build left beside the player: its runtime libraries and the notices, or the web
		// page's parts.
		if ((onProgress != null) && !build.Files.IsEmpty)
			onProgress("Staging runtime libs...", 0.96f);
		for (let file in build.Files)
		{
			if (FileCopy.CopyFile(build.Directory, file, result.OutputDir, file))
				result.FilesStaged++;
			else
				GlobalLog(.Warning, "Export: '{}' not found beside the player in {}", file, build.Directory);
		}
		if (preset.StageSymbols)
		{
			for (let symbol in build.Symbols)
			{
				if (FileCopy.CopyFile(build.Directory, symbol, result.OutputDir, symbol))
					result.FilesStaged++;
				else
					GlobalLog(.Warning, "Export: symbol file '{}' not found in {}", symbol, build.Directory);
			}
		}
		for (let extra in preset.AdditionalFiles)
		{
			if (FileCopy.CopyFile(project.Directory, extra, result.OutputDir, PathFilename(extra, .. scope .())))
				result.FilesStaged++;
			else
				GlobalLog(.Warning, "Export: additional file '{}' not found", extra);
		}
		// The deploy files of the plugins the project enables on this platform, beside the player.
		if (!ExportPlugins.StageDeployFiles(project, sdk, enabled, preset.Platform, result.OutputDir, ref result.FilesStaged))
		{
			result.Refusal.Set("a plugin's deploy file is missing (see the log)");
			return .Err(.NotFound);
		}
		// The project's plugins' export hooks, over the staged dist.
		if ((hooks != null) && (hooks.Count > 0))
		{
			if (onProgress != null)
				onProgress("Running the plugins' export hooks...", 0.99f);
			var context = ExportHookContext();
			context.Project = project;
			context.Preset = preset;
			context.OutputDir = result.OutputDir;
			let failure = scope String();
			if (!hooks.Run(context, failure))
			{
				result.Refusal.AppendF("export hook {}", failure);
				GlobalLog(.Error, "Export: preset '{}': {}", preset.Name, result.Refusal);
				return .Err(.Internal);
			}
		}
		if (onProgress != null)
			onProgress("Done", 1.0f);
		return .Ok;
	}

	/// Every preset in turn, each (platform, config) built once by `players` for all the presets
	/// that share it. A preset for another host's desktop platform (BuildsOnAnotherHost) is
	/// skipped with a notice, not failed: a project's Windows preset is exported on Windows. Ok
	/// when every preset not skipped exported; the counts in `outSummary` when given.
	public static Result<void, ErrorCode> ExportAll(EditorProject project, List<ExportPreset> presets, IPlayerBuilder players,
		BuilderRegistry builders, StringView outRoot, StringView dataRoot, bool rebuild, ExportProgress onProgress = null,
		bool cook = true, Dictionary<Guid, List<uint8>> sceneStreams = null, SceneReferenceScanner scanner = null,
		List<Guid> precomputedReachableRoots = null, ExportPluginServices hooks = null, PluginHost plugins = null,
		ExportAllSummary outSummary = null)
	{
		let once = scope OncePerTarget(players);
		let summary = scope ExportAllSummary();
		defer { if (outSummary != null) summary.CopyTo(outSummary); }
		let n = presets.Count;
		for (int i < n)
		{
			let preset = presets[i];
			if (BuildsOnAnotherHost(preset.Platform))
			{
				let why = scope String();
				BuildEntry entry;
				// Refused, as another host's platform always is: its refusal says why.
				ProjectPlayerBuilder.Target(preset, out entry, scope .(), why).IgnoreError();
				GlobalLog(.Information, "Export: preset '{}' skipped: {}", preset.Name, why);
				summary.Skipped.Add(new .(preset.Name));
				continue;
			}
			let index = i;
			ExportProgress scoped = scope [&](step, fraction) =>
				{
					if (onProgress != null)
						onProgress(scope $"{preset.Name}: {step}", ((float)index + fraction) / (float)n);
				};
			let result = scope ExportResult();
			if (ExportOne(project, preset, once, builders, outRoot, dataRoot, rebuild, result, scoped, cook, sceneStreams, scanner, precomputedReachableRoots, hooks, plugins) case .Ok)
			{
				summary.Exported++;
				GlobalLog(.Information, "Export: exported '{}' -> {} ({} files staged)", preset.Name, result.OutputDir, result.FilesStaged);
			}
			else
			{
				summary.Failed++;
				GlobalLog(.Error, "Export: preset '{}' failed{}", preset.Name, result.Refusal.IsEmpty ? "" : scope $": {result.Refusal}");
			}
		}
		if (!summary.Skipped.IsEmpty)
			GlobalLog(.Information, "Export: {} preset(s) skipped, for another host's platform: export them there", summary.Skipped.Count);
		return (summary.Failed == 0) ? .Ok : .Err(.Internal);
	}

	/// A player builder over another that builds each (entry, build config) once and gives the
	/// same build to every later preset of it, so ExportAll's presets that differ only in their
	/// content (a pruned and a full dist, two names) pay for one compile. A refusal is kept too:
	/// a compile that failed is not run again for the next preset.
	private class OncePerTarget : IPlayerBuilder
	{
		private class Made
		{
			public PlayerBuild Build = new .() ~ delete _;
			public bool Failed;
			public ErrorCode Error;
			public String Refusal = new .() ~ delete _;
		}

		/// Borrowed.
		private IPlayerBuilder mInner;
		/// By "<entry>|<config>"; the keys and the builds are its own.
		private Dictionary<String, Made> mMade = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

		public this(IPlayerBuilder inner)
		{
			mInner = inner;
		}

		public Result<void, ErrorCode> Build(EditorProject project, ExportPreset preset, PlayerBuild outBuild, ExportProgress onProgress,
			String outRefusal)
		{
			let config = scope String();
			BuildEntry entry;
			if (ProjectPlayerBuilder.Target(preset, out entry, config, scope .()) case .Err)
				return mInner.Build(project, preset, outBuild, onProgress, outRefusal); // its refusal, as it says it
			let key = scope $"{entry}|{config}";
			Made made;
			if (!mMade.TryGetValue(key, out made))
			{
				made = new Made();
				if (mInner.Build(project, preset, made.Build, onProgress, made.Refusal) case .Err(let error))
				{
					made.Failed = true;
					made.Error = error;
				}
				mMade[new String(key)] = made;
			}
			outBuild.Clear();
			if (made.Failed)
			{
				outRefusal.Set(made.Refusal);
				return .Err(made.Error);
			}
			made.Build.CopyTo(outBuild);
			return .Ok;
		}
	}
}
