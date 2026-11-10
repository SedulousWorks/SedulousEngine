using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.VG.Resource;

namespace Sedulous.Tools.Cook.Tests;

/// The cooker's whole path on a real project directory, with the composition root's own
/// importers and builders: a source file dropped in, the asset cooked, the product read
/// back through the cooked database, and a second plan finding nothing to do. Every host
/// that cooks runs exactly this; the CLI only parses the flags around it.
static class HeadlessCookTests
{
	private const String cHeartSvg = """
		<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 21 L3 12 A5 5 0 0 1 12 5 A5 5 0 0 1 21 12 Z" fill="#E53935"/></svg>
		""";

	/// A script asset as an old project holds it, written before scripting went: its type is
	/// one this build has no code for.
	private const String cOldScriptEnvelope = """
		<root>
			<string name="guid">1f0594d1-deb5-f144-a8d2-85ca05815b87</string>
			<string name="typeName">Sedulous.Script.Pipeline.ScriptClassAsset</string>
			<array name="dataVersions" count="1">
				<u64 name="type">6162296549784860781</u64>
				<u32 name="version">0</u32>
			</array>
			<object name="payload">
				<object>
					<string name="fileName">Mover.as</string>
					<string name="language">angelscript</string>
					<string name="className"/>
				</object>
			</object>
		</root>
		""";

	[Test]
	public static void AVectorImageDroppedIntoAProjectCooksToAProductAndStaysUpToDate()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_headless_cook", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "CookMe") case .Ok);

		// An old project's script asset, there before the project opens, as its file is.
		let scripts = PathJoin(PathJoin(dir, ProjectLayout.ContentDir, .. scope .()), "Scripts", .. scope .());
		CreateDirectory(PathJoin(dir, ProjectLayout.ContentDir, .. scope .()));
		CreateDirectory(scripts);
		let envelopePath = PathJoin(scripts, "Mover.xasset", .. scope .());
		File.WriteAllText(envelopePath, cOldScriptEnvelope).IgnoreError();

		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let scriptId = Guid.Parse("1f0594d1-deb5-f144-a8d2-85ca05815b87").Get();
		let script = project.SourceDb.GetInstance(scriptId);
		Test.Assert(script != null, "the old script asset is listed");
		Test.Assert(script.TypeName == "Sedulous.Script.Pipeline.ScriptClassAsset", "under the type it was written with");

		PipelineRegistration.RegisterPipelineTypes();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);
		let read = script.ReadObject();
		Test.Assert(read == null, "its type is unknown here, so it reads as nothing");
		delete read;

		// The drop: a vector image on disk, taken in by whichever importer claims ".svg".
		let dropped = PathJoin(dir, "Heart.svg", .. scope .());
		File.WriteAllText(dropped, cHeartSvg).IgnoreError();
		let importer = importers.FindFor("svg");
		Test.Assert(importer != null, "an importer claims .svg");
		Test.Assert(importers.FindFor("as") == null, "and none a script");
		let context = scope ImportContext(project.SourcesRoot(.. scope .()));
		let imported = importer.Import(dropped, context, project.SourceDb.RootGroup, null, null, null);
		Test.Assert(imported case .Ok, "imported");
		let assetId = imported.Value.Id;

		// The cook: the CLI's body, on the project's own mounts. The script is passed by, not
		// failed: no builder claims its type.
		let sources = scope NativeFileSystem(project.SourcesRoot(.. scope .()));
		let cache = scope NativeFileSystem(project.CacheRoot(.. scope .()));
		let driver = scope CookDriver(project.SourceDb, project.CookedDb, builders, sources, cache);
		let plan = scope CookPlan();
		driver.Plan(plan);
		Test.Assert((plan.Dirty.Count == 1) && (plan.Unbuildable == 1), scope $"{plan.Dirty.Count} dirty, {plan.Unbuildable} unbuildable");
		let stats = scope CookStats();
		driver.Execute(plan, stats);
		Test.Assert((stats.Cooked == 1) && (stats.Failed == 0), scope $"cooked {stats.Cooked}, failed {stats.Failed}");

		// The product, through the cooked database by the source's id: a vector image the
		// runtime would load.
		let product = project.CookedDb.ReadObject(assetId);
		Test.Assert(product != null, "the product is in the cooked database and reads back by its registered type");
		defer delete product;
		let image = product as VectorImageResource;
		Test.Assert((image != null) && image.Svg.Contains("<svg"));
		Test.Assert(project.CookedDb.GetInstance(scriptId) == null, "the script cooked to nothing");

		// Nothing changed: the second plan is clean, and the script is still there as it was.
		let again = scope CookPlan();
		driver.Plan(again);
		Test.Assert((again.Dirty.Count == 0) && (again.UpToDate == 1) && (again.Unbuildable == 1), scope $"{again.Dirty.Count} dirty on the second plan");
		Test.Assert(project.SourceDb.GetInstance(scriptId) == script);
		let kept = scope String();
		Test.Assert((File.ReadAllText(envelopePath, kept) case .Ok) && (kept == cOldScriptEnvelope), "its file untouched");
	}
}
