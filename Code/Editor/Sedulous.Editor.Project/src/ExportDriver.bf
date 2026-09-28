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

namespace Sedulous.Editor.Core;

/// The export: a project into a shippable dist. Cook everything, or the reachable closure
/// of the entry points when the preset prunes; stage the scenes as binary products; pack
/// the cooked content, one pak on the desktop and the BC and ASTC siblings on the web; write
/// the dist manifest; cook the shader pack into the dist's Data; stage the resolved
/// template's player and sidecars and the preset's extra files. The ONE entry point the
/// editor's Export menu, the CLI and the MCP host share, so a preset produces the same dist
/// whichever surface triggers it.
///
/// A project naming a native module is refused: native game modules are not supported.
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
		Add(settings.DefaultUiThemeId, .ManifestDefault);
		Add(settings.DefaultUiFontId, .ManifestDefault);
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

	/// The cook occupies 0.05..0.60 of the export.
	private static void ReportCookStep(ExportProgress onProgress, int done, int total, StringView path)
	{
		if (onProgress == null)
			return;
		let fraction = (total > 0) ? 0.05f + ((float)done / (float)total) * 0.55f : 0.6f;
		onProgress(scope $"Cooking {path}", fraction);
	}

	// ---- variants ----

	/// The desktop's single pak from the host database; a web build's BC and ASTC siblings
	/// from their own per target databases.
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
				outVariants.Add(variant);
			}
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
			let targetId = scope $"web-{variant.Key}";
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
	/// scene bytes by guid, null for verbatim.
	public static Result<void, ErrorCode> ExportContent(EditorProject project, StringView outDir, ExportStats stats,
		ExportProgress onProgress, Dictionary<Guid, List<uint8>> sceneStreams, HashSet<Guid> reachable,
		List<ExportRoot> roots, PruningReport outReport, List<ContentVariant> variants)
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
			if (!ExportStaging.PackTree(cookedMount, "", pak, ref stats.FilesPacked, reachablePaths)
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
			let dist = scope ProjectSettings();
			dist.Name.Set(project.Settings.Name);
			dist.DefaultSceneId = project.Settings.DefaultSceneId;
			dist.DefaultScene.Set(project.Settings.DefaultScene);
			dist.StartupScriptId = project.Settings.StartupScriptId;
			dist.StartupScript.Set(project.Settings.StartupScript);
			dist.DefaultInputMapId = project.Settings.DefaultInputMapId;
			dist.DefaultBusLayoutId = project.Settings.DefaultBusLayoutId;
			dist.DefaultUiThemeId = project.Settings.DefaultUiThemeId;
			dist.DefaultUiFontId = project.Settings.DefaultUiFontId;
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
		List<ContentVariant> variants = null)
	{
		let stats = scope ExportStats();
		defer { if (outStats != null) stats.CopyTo(outStats); }
		if (onProgress != null)
			onProgress("Cooking content...", 0.05f);
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
		return ExportContent(project, outDir, stats, onProgress, sceneStreams, null, null, null, effective);
	}

	// ---- one preset ----

	/// Exports one preset into <outRoot>/<subdir>: the template resolved, the content cooked
	/// and packed, whole or pruned to the closure when the preset asks and a scanner or a
	/// precomputed root set is at hand, the shader pack cooked from `dataRoot`, the player,
	/// the sidecars, the symbols when opted in, and the extra files staged.
	public static Result<void, ErrorCode> ExportOne(EditorProject project, ExportPreset preset, TemplateRegistry templates,
		BuilderRegistry builders, StringView outRoot, StringView dataRoot, bool rebuild, ExportResult outResult = null,
		ExportProgress onProgress = null, bool cook = true, Dictionary<Guid, List<uint8>> sceneStreams = null,
		SceneReferenceScanner scanner = null, List<Guid> precomputedReachableRoots = null)
	{
		let template = templates.Resolve(preset);
		if (template == null)
		{
			GlobalLog(.Error, "Export: no export template for preset '{}' (platform '{}') - import one", preset.Name, preset.Platform);
			return .Err(.NotFound);
		}
		if (!project.Settings.NativeModule.IsEmpty)
		{
			GlobalLog(.Error, "Export: the project names a native module '{}'; native game modules are not supported yet", project.Settings.NativeModule);
			return .Err(.NotSupported);
		}
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
			}
		}
		if (!template.EngineVersion.IsEmpty && (template.EngineVersion != EngineVersion.String))
		{
			GlobalLog(.Warning, "Export: template '{}' was built against engine {} but this build is {} - exporting anyway", template.Id, template.EngineVersion, EngineVersion.String);
			result.EngineVersionWarning.AppendF("Template '{}' targets engine {} (this build is {}).", template.Id, template.EngineVersion, EngineVersion.String);
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
				contentStatus = ExportContent(project, result.OutputDir, result.Content, onProgress, sceneStreams, reachable, seeds, result.Pruning, variants);
			}
		}
		else if (cook)
		{
			contentStatus = ExportProject(project, result.OutputDir, builders, rebuild, result.Content, onProgress, sceneStreams, variants);
		}
		else
		{
			contentStatus = CookVariantTargets(project, builders, variants, rebuild, onProgress);
			if (contentStatus case .Ok)
				contentStatus = ExportContent(project, result.OutputDir, result.Content, onProgress, sceneStreams, null, null, null, variants);
		}
		if (contentStatus case .Err)
			return .Err(.Internal);

		if (onProgress != null)
			onProgress("Staging player...", 0.93f);
		let outName = ExportStaging.PlayerOutputName(preset.Platform, preset.PlayerName, template.PlayerBinary, .. scope .());
		if (!ExportTemplates.CopyFile(template.Directory, template.PlayerBinary, result.OutputDir, outName))
		{
			GlobalLog(.Error, "Export: failed to stage player '{}' from {}", template.PlayerBinary, template.Id);
			return .Err(.Internal);
		}
		result.FilesStaged++;

		if (onProgress != null)
			onProgress("Cooking shaders...", 0.95f);
		{
			if (ExportStaging.StageShaderPack(result.OutputDir, dataRoot, preset.Platform, let shaderVariants) case .Err)
				return .Err(.Internal);
			result.FilesStaged += 2;
			GlobalLog(.Information, "Export: staged Data/{} ({} variants)", Sedulous.Shaders.ShaderSystemHost.cShaderPackPath, shaderVariants);
		}

		if ((onProgress != null) && !template.Sidecars.IsEmpty)
			onProgress("Staging runtime libs...", 0.96f);
		for (let sidecar in template.Sidecars)
		{
			if (ExportStaging.IsDxcRuntimeLib(sidecar))
			{
				GlobalLog(.Information, "Export: omitting DXC sidecar '{}' (dist renders from the cooked shader pack)", sidecar);
				continue;
			}
			if (ExportTemplates.CopyFile(template.Directory, sidecar, result.OutputDir, sidecar))
				result.FilesStaged++;
			else
				GlobalLog(.Warning, "Export: sidecar '{}' not found in template '{}'", sidecar, template.Id);
		}
		if (preset.StageSymbols)
		{
			for (let symbol in template.Symbols)
			{
				if (ExportTemplates.CopyFile(template.Directory, symbol, result.OutputDir, symbol))
					result.FilesStaged++;
				else
					GlobalLog(.Warning, "Export: symbol file '{}' not found in template '{}'", symbol, template.Id);
			}
		}
		for (let extra in preset.AdditionalFiles)
		{
			if (ExportTemplates.CopyFile(project.Directory, extra, result.OutputDir, PathFilename(extra, .. scope .())))
				result.FilesStaged++;
			else
				GlobalLog(.Warning, "Export: additional file '{}' not found", extra);
		}
		if (onProgress != null)
			onProgress("Done", 1.0f);
		return .Ok;
	}

	/// Every preset in turn; Ok only when all succeeded.
	public static Result<void, ErrorCode> ExportAll(EditorProject project, List<ExportPreset> presets, TemplateRegistry templates,
		BuilderRegistry builders, StringView outRoot, StringView dataRoot, bool rebuild, ExportProgress onProgress = null,
		bool cook = true, Dictionary<Guid, List<uint8>> sceneStreams = null, SceneReferenceScanner scanner = null,
		List<Guid> precomputedReachableRoots = null)
	{
		int ok = 0;
		let n = presets.Count;
		for (int i < n)
		{
			let preset = presets[i];
			let index = i;
			ExportProgress scoped = scope [&](step, fraction) =>
				{
					if (onProgress != null)
						onProgress(scope $"{preset.Name}: {step}", ((float)index + fraction) / (float)n);
				};
			let result = scope ExportResult();
			if (ExportOne(project, preset, templates, builders, outRoot, dataRoot, rebuild, result, scoped, cook, sceneStreams, scanner, precomputedReachableRoots) case .Ok)
			{
				ok++;
				GlobalLog(.Information, "Export: exported '{}' -> {} ({} files staged)", preset.Name, result.OutputDir, result.FilesStaged);
			}
			else
			{
				GlobalLog(.Error, "Export: preset '{}' failed", preset.Name);
			}
		}
		return (ok == n) ? .Ok : .Err(.Internal);
	}
}
