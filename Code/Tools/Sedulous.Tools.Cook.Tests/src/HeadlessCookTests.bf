using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Script.Resource;

namespace Sedulous.Tools.Cook.Tests;

/// The cooker's whole path on a real project directory, with the composition root's own
/// importers and builders: a source file dropped in, the asset cooked, the product read
/// back through the cooked database, and a second plan finding nothing to do. Every host
/// that cooks runs exactly this; the CLI only parses the flags around it.
static class HeadlessCookTests
{
	[Test]
	public static void AScriptDroppedIntoAProjectCooksToAProductAndStaysUpToDate()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_headless_cook", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "CookMe") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);

		// The drop: a script file on disk, taken in by whichever importer claims ".as".
		let dropped = PathJoin(dir, "Mover.as", .. scope .());
		File.WriteAllText(dropped, """
			class Mover
			{
				Entity self;
				Scene@ scene;
				float speed = 2.0f;
				void onUpdate(float dt) { }
			}
			""").IgnoreError();
		let importer = importers.FindFor("as");
		Test.Assert(importer != null, "an importer claims .as");
		let context = scope ImportContext(project.SourcesRoot(.. scope .()));
		let imported = importer.Import(dropped, context, project.SourceDb.RootGroup, null, null, null);
		Test.Assert(imported case .Ok, "imported");
		let assetId = imported.Value.Id;

		// The cook: the CLI's body, on the project's own mounts.
		let sources = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let cache = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let driver = scope CookDriver(project.SourceDb, project.CookedDb, builders, sources, cache);
		let plan = scope CookPlan();
		driver.Plan(plan);
		Test.Assert(plan.Dirty.Count == 1, scope $"{plan.Dirty.Count} dirty, {plan.Unbuildable} unbuildable");
		let stats = scope CookStats();
		driver.Execute(plan, stats);
		Test.Assert((stats.Cooked == 1) && (stats.Failed == 0), scope $"cooked {stats.Cooked}, failed {stats.Failed}");

		// The product, through the cooked database by the source's id: a ScriptClass the
		// runtime would load.
		let product = project.CookedDb.ReadObject(assetId);
		Test.Assert(product != null, "the product is in the cooked database and reads back by its registered type");
		defer delete product;
		let source = product as ScriptClassSource;
		Test.Assert((source != null) && (source.ClassName == "Mover") && (source.Language == "angelscript"));
		Test.Assert(source.Properties.Count == 1, scope $"{source.Properties.Count} properties harvested");

		// Nothing changed: the second plan is clean.
		let again = scope CookPlan();
		driver.Plan(again);
		Test.Assert((again.Dirty.Count == 0) && (again.UpToDate == 1), scope $"{again.Dirty.Count} dirty on the second plan");
	}
}
