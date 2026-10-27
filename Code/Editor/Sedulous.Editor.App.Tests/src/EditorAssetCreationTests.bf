using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The type the test creators make; only its name is stored, the instances never written.
class CreatedThing
{
}

/// A builder for CreatedThing, so a create of one asks for a cook. The cook finds nothing to
/// read in the unwritten instance and counts it unbuildable; Build is never reached.
class CreatedThingBuilder : IAssetBuilder
{
	public Type AssetType => typeof(CreatedThing);
	public Type ProductType => typeof(CreatedThing);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context) => .Err(.Unknown);
}

/// EditorAssetCreation: a create with no project, or one its creator cannot write, says so
/// and opens nothing; one that writes its asset opens its page, says the row exists, and a
/// scene becomes the project's default (saved) when it has none; a create during a cook waits
/// for it; a type a builder cooks is cooked at once.
class EditorAssetCreationTests
{
	/// The services a creation runs on, over the real cook service; the notices land in Said,
	/// the pages opened in Opened and the creations reported in Created.
	class Bench
	{
		public EditorContext Context = new .() ~ delete _;
		public BuilderRegistry Builders = new .() ~ delete _;
		public EditorCookService Cook = new .() ~ delete _;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		/// Borrowed from the project's database.
		public List<Instance> Opened = new .() ~ delete _;
		public List<Instance> Created = new .() ~ delete _;
		/// Stands in for a background export: true holds the cook's mutation lock.
		public bool Locked = false;
		public EditorProject Project = null ~ delete _;
		public String Dir = new .() ~ delete _;

		public this()
		{
			let said = Said;
			Context.OnNotice = new [=said](kind, message) => { said.Add(new String(message)); };
			let bench = this;
			Cook.ExternalMutationLock = new [=bench]() => bench.Locked;
		}

		public ~this()
		{
			Cook.Shutdown();
			if (Project != null)
			{
				DeleteAndNullify!(Project);
				RemoveDirectoryRecursive(Dir);
			}
		}

		/// A scratch project, the cook initialised over it as the application does.
		public void OpenProject(StringView leaf)
		{
			Dir.Set(leaf);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Create") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Cook.Initialize(Project, Builders);
		}

		/// The services over this bench; the creation owns them.
		public EditorAssetCreationServices Services()
		{
			let services = new EditorAssetCreationServices();
			services.Context = Context;
			services.Cook = Cook;
			services.Builders = Builders;
			let opened = Opened;
			services.OnOpenPage = new [=opened](instance) => { opened.Add(instance); };
			let created = Created;
			services.OnCreated = new [=created](instance) => { created.Add(instance); };
			return services;
		}

		public StringView Last => Said.IsEmpty ? "" : Said.Back;

		/// Pumps the cook until it is idle; bounded so a hang fails.
		public void PumpUntilIdle()
		{
			let watch = scope Stopwatch(true);
			while (!Cook.IsIdle && (watch.ElapsedMilliseconds < 60000))
			{
				Cook.Update();
				Thread.Sleep(1);
			}
			Cook.Update();
			Test.Assert(Cook.IsIdle);
		}
	}

	/// A creator's run: a uniquely named "Level" of CreatedThing in its target group.
	static Instance WriteLevel(AssetCreationContext at)
	{
		let group = at.Target;
		if (group == null)
			return null;
		return group.CreateInstance(group.UniqueInstanceName("Level", .. scope .()), typeof(CreatedThing).GetFullName(.. scope .()));
	}

	[Test]
	public static void ACreateWithNoProjectOrAFailedWriteSaysSoAndOpensNothing()
	{
		let bench = scope Bench();
		let failing = scope AssetCreator("Scene", "", typeof(CreatedThing), new (at) => null, true);
		let creation = scope EditorAssetCreation(bench.Services());

		creation.CreateAndOpen(failing);
		Test.Assert(bench.Last == "Create failed: no project is open.");

		bench.OpenProject("scratch_editor_asset_creation_refused");
		creation.SetProject(bench.Project);
		creation.CreateAndOpen(failing);
		Test.Assert(bench.Last == "Create failed: the Scene could not be written.");
		Test.Assert(bench.Said.Count == 2);
		Test.Assert(bench.Opened.IsEmpty);
		Test.Assert(bench.Created.IsEmpty);
		Test.Assert(!bench.Project.Settings.DefaultSceneId.IsSet);
		Test.Assert(bench.Project.Settings.DefaultScene.IsEmpty);
	}

	/// The flow File > New takes: the asset lands in the picked group, its page opens, the
	/// view hears of it, and a first scene becomes the default, written to the manifest; a
	/// second scene leaves the default alone.
	[Test]
	public static void AWrittenSceneOpensAndBecomesTheSavedDefaultOnlyWhenThereIsNone()
	{
		let bench = scope Bench();
		bench.OpenProject("scratch_editor_asset_creation_scene");
		let scene = scope AssetCreator("Scene", "", typeof(CreatedThing), new (at) => WriteLevel(at), true);
		let creation = scope EditorAssetCreation(bench.Services());
		creation.SetProject(bench.Project);
		let picked = bench.Project.SourceDb.RootGroup.CreateGroup("Scenes");

		creation.CreateAndOpen(scene, picked);
		Test.Assert(bench.Said.IsEmpty);
		Test.Assert(bench.Opened.Count == 1);
		let first = bench.Opened[0];
		Test.Assert(first.OwningGroup == picked);
		Test.Assert(bench.Created.Count == 1);
		Test.Assert(bench.Created[0] == first);
		Test.Assert(bench.Project.Settings.DefaultSceneId == first.Id);
		Test.Assert(bench.Project.Settings.DefaultScene == "Scenes/Level");

		// Saved: a fresh read of the manifest names it.
		{
			let reopened = EditorProject.Open(bench.Dir);
			Test.Assert(reopened != null);
			defer delete reopened;
			Test.Assert(reopened.Settings.DefaultSceneId == first.Id);
			Test.Assert(reopened.Settings.DefaultScene == "Scenes/Level");
		}

		creation.CreateAndOpen(scene, picked);
		Test.Assert(bench.Opened.Count == 2);
		Test.Assert(bench.Opened[1] != first);
		Test.Assert(bench.Created.Count == 2);
		Test.Assert(bench.Project.Settings.DefaultSceneId == first.Id);
		Test.Assert(bench.Project.Settings.DefaultScene == "Scenes/Level");
	}

	/// Only a creator that says so sets the default scene; a default named by path alone (an
	/// older manifest's) or by id alone counts as one.
	[Test]
	public static void ANonSceneOrAPathOnlyDefaultLeavesTheDefaultAlone()
	{
		let bench = scope Bench();
		bench.OpenProject("scratch_editor_asset_creation_nonscene");
		let thing = scope AssetCreator("Thing", "", typeof(CreatedThing), new (at) => WriteLevel(at));
		let scene = scope AssetCreator("Scene", "", typeof(CreatedThing), new (at) => WriteLevel(at), true);
		let creation = scope EditorAssetCreation(bench.Services());
		creation.SetProject(bench.Project);

		creation.CreateAndOpen(thing);
		Test.Assert(bench.Opened.Count == 1);
		Test.Assert(bench.Opened[0].OwningGroup == bench.Project.SourceDb.RootGroup); // no pick: the root
		Test.Assert(!bench.Project.Settings.DefaultSceneId.IsSet);
		Test.Assert(bench.Project.Settings.DefaultScene.IsEmpty);

		bench.Project.Settings.DefaultScene.Set("Old/Scene");
		creation.CreateAndOpen(scene);
		Test.Assert(bench.Opened.Count == 2);
		Test.Assert(!bench.Project.Settings.DefaultSceneId.IsSet);
		Test.Assert(bench.Project.Settings.DefaultScene == "Old/Scene");

		// And one named by id alone, its path not yet filled in.
		let named = bench.Opened[0].Id;
		bench.Project.Settings.DefaultScene.Clear();
		bench.Project.Settings.DefaultSceneId = named;
		creation.CreateAndOpen(scene);
		Test.Assert(bench.Opened.Count == 3);
		Test.Assert(bench.Project.Settings.DefaultSceneId == named);
		Test.Assert(bench.Project.Settings.DefaultScene.IsEmpty);
	}

	/// A create while a background reader holds the databases waits, says so, and runs, page
	/// and all, once the cook service's pump finds the lock released.
	[Test]
	public static void ACreateDuringACookWaitsAndRunsWhenItIsDone()
	{
		let bench = scope Bench();
		bench.OpenProject("scratch_editor_asset_creation_queued");
		let scene = scope AssetCreator("Scene", "", typeof(CreatedThing), new (at) => WriteLevel(at), true);
		let creation = scope EditorAssetCreation(bench.Services());
		creation.SetProject(bench.Project);

		bench.Locked = true;
		creation.CreateAndOpen(scene);
		Test.Assert(bench.Last == "Create queued until the current cook finishes.");
		Test.Assert(bench.Opened.IsEmpty);
		Test.Assert(bench.Created.IsEmpty);
		Test.Assert(bench.Project.SourceDb.RootGroup.Instances.IsEmpty);
		bench.Cook.Update();
		Test.Assert(bench.Opened.IsEmpty, "still locked");

		bench.Locked = false;
		bench.Cook.Update();
		Test.Assert(bench.Opened.Count == 1);
		Test.Assert(bench.Created.Count == 1);
		Test.Assert(bench.Project.Settings.DefaultSceneId == bench.Opened[0].Id);
		Test.Assert(bench.Said.Count == 1);
	}

	/// A type no builder cooks asks for no cook; one a builder cooks is cooked at once, through
	/// the cook service.
	[Test]
	public static void ATypeABuilderCooksIsCookedAtOnce()
	{
		let bench = scope Bench();
		bench.OpenProject("scratch_editor_asset_creation_cook");
		let thing = scope AssetCreator("Thing", "", typeof(CreatedThing), new (at) => WriteLevel(at));
		let creation = scope EditorAssetCreation(bench.Services());
		creation.SetProject(bench.Project);

		creation.CreateAndOpen(thing);
		Test.Assert(bench.Opened.Count == 1);
		Test.Assert(bench.Cook.IsIdle);
		bench.PumpUntilIdle();
		Test.Assert(bench.Cook.Revision == 0);

		bench.Builders.Register(new CreatedThingBuilder());
		creation.CreateAndOpen(thing);
		Test.Assert(bench.Opened.Count == 2);
		Test.Assert(!bench.Cook.IsIdle);
		bench.PumpUntilIdle();
		Test.Assert(bench.Cook.Revision == 1);
	}
}
