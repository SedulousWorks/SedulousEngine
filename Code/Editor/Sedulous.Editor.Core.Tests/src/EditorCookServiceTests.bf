using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The cook service: the mutation lock defers structural work, and a real project cooks
/// through the three phases on a background worker with the badges and the hot reload list
/// following.
static class EditorCookServiceTests
{
	[Test]
	public static void TheExternalMutationLockDefersRunWhenIdleUntilReleased()
	{
		// The app wires it to the job service: a background export reads the databases from
		// its worker, so structural mutations defer exactly as during a cook.
		let cook = scope EditorCookService();
		bool busy = false;
		cook.ExternalMutationLock = new [&busy]() => busy;
		Test.Assert(!cook.MutationLocked);
		int ran = 0;
		cook.RunWhenIdle(new [&ran]() => { ran++; });
		Test.Assert(ran == 1, "unlocked runs immediately");
		busy = true;
		Test.Assert(cook.MutationLocked);
		cook.RunWhenIdle(new [&ran]() => { ran++; });
		Test.Assert(ran == 1, "locked defers");
		cook.Update();
		Test.Assert(ran == 1, "still locked");
		busy = false;
		cook.Update();
		Test.Assert(ran == 2, "released: the deferred action replays");
	}

	/// Pumps until the cook is idle; bounded so a hang fails.
	private static void PumpUntilIdle(EditorCookService cook, List<String> lines)
	{
		int guard = 0;
		while (!cook.IsIdle && (guard++ < 4000000))
			cook.Update(scope [&](line) => { lines.Add(new String(line)); });
		cook.Update(scope [&](line) => { lines.Add(new String(line)); });
	}

	[Test]
	public static void AProjectCooksOnTheWorkerAndTheBadgesFollow()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_cook_service", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Cook") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders);
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);

		// A script dropped in through its importer: buildable, so it has a badge.
		let dropped = PathJoin(dir, "Mover.as", .. scope .());
		File.WriteAllText(dropped, "class Mover\n{\n\tEntity self;\n\tScene@ scene;\n\tvoid onUpdate(float dt) {}\n}\n").IgnoreError();
		let context = scope ImportContext(project.SourcesRoot(.. scope .()));
		let imported = importers.FindFor("as").Import(dropped, context, project.SourceDb.RootGroup, null, null, null);
		Test.Assert(imported case .Ok);
		let instance = imported.Value;
		let scene = project.SourceDb.RootGroup.CreateInstance("level", "Sedulous.Scene.Resource.SceneDocument");

		let cook = scope EditorCookService();
		Test.Assert(!cook.IsReady);
		cook.Initialize(project, builders);
		Test.Assert(cook.IsReady && cook.IsIdle);
		Test.Assert(cook.BadgeFor(instance) == .Missing, "never cooked");
		Test.Assert(cook.BadgeFor(scene) == .NoBuilder, "a scene stages, it does not cook");
		Test.Assert(cook.RecipeHashFor(instance.Id) == 0);

		int finished = 0;
		cook.OnCookFinished = new [&finished]() => { finished++; };
		let lines = scope List<String>();
		defer { ClearAndDeleteItems(lines); }
		cook.RequestCook();
		Test.Assert(cook.IsCooking && cook.MutationLocked && !cook.IsIdle);
		// A structural mutation while cooking defers; a second request is remembered.
		int deferred = 0;
		cook.RunWhenIdle(new [&deferred]() => { deferred++; });
		cook.RequestCook();
		Test.Assert(deferred == 0);
		PumpUntilIdle(cook, lines);

		Test.Assert(finished == 2, scope $"the remembered request re-issued: {finished} finishes");
		Test.Assert(deferred == 1, "the deferred mutation ran once the lock released");
		Test.Assert(cook.Revision == 2);
		Test.Assert(cook.BadgeFor(instance) == .Cooked);
		Test.Assert(cook.RecipeHashFor(instance.Id) != 0);
		Test.Assert(project.CookedDb.GetInstance(instance.Id) != null, "the product exists");
		bool sawPlanned = false;
		bool sawCooked = false;
		for (let line in lines)
		{
			if (line.StartsWith("cooking 1 asset"))
				sawPlanned = true;
			if (line.StartsWith("cooked ") && line.Contains("Mover"))
				sawCooked = true;
		}
		Test.Assert(sawPlanned && sawCooked, "the progress lines reached the status");

		// A scoped request for the same asset finds nothing to do and reports silently.
		lines.Clear();
		Guid[1] roots = .(instance.Id);
		cook.RequestCookFor(roots);
		PumpUntilIdle(cook, lines);
		Test.Assert(finished == 3);
		Test.Assert(cook.LastCookedCount == 0);
		cook.Shutdown();
		Test.Assert(!cook.IsReady);
	}
}
