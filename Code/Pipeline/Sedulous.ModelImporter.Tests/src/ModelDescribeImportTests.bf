using System;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter.Tests;

/// The review dialog's data: what an import WOULD create, and what a decision about it does.
class ModelDescribeImportTests
{
	private static int CountOf(ImportPlan plan, ImportResourceKind kind)
	{
		var count = 0;
		for (let entry in plan.Entries)
		{
			if (entry.Kind == kind)
				count++;
		}
		return count;
	}

	/// Everything is offered enabled under its own name, and an unfiltered import then
	/// creates an instance for EVERY entry: the plan and the fan out are the same list.
	[Test]
	public static void ThePlanListsTheFanOutAndTheImportMatchesIt()
	{
		let fixture = scope ImportFixture("scratch_model_describe");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let plan = scope ImportPlan();
		importer.DescribeImport(dropped, null, prepared, plan);
		Test.Assert(!plan.IsEmpty);

		for (let entry in plan.Entries)
		{
			Test.Assert(entry.Enabled);
			Test.Assert(entry.TargetName == entry.SourceName);
		}
		Test.Assert(CountOf(plan, .Mesh) == 2);
		Test.Assert(CountOf(plan, .Texture) == 2);
		Test.Assert(CountOf(plan, .Material) == 1);
		Test.Assert(CountOf(plan, .Skeleton) == 1);
		Test.Assert(CountOf(plan, .AnimationClip) == 1);
		Test.Assert(CountOf(plan, .Collision) == 0); // opt in, and the options say no

		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		let group = imported.Value.OwningGroup;
		for (let entry in plan.Entries)
			Test.Assert(group.GetInstance(entry.SourceName) != null, entry.SourceName);
	}

	/// A decision reaches the fan out: an unchecked clip is not created, a renamed mesh lands
	/// under the new name only, and the manifest keeps the shape of what survived.
	///
	/// Then the memory: the manifest STORED the decisions, and merging them onto a fresh plan
	/// reproduces them, so a re-import does not ask again what was already settled.
	[Test]
	public static void ASelectionFiltersAndRenamesAndIsRememberedForNextTime()
	{
		let fixture = scope ImportFixture("scratch_model_selection");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let options = scope ModelImportOptions();
		importer.DescribeImport(dropped, options, prepared, options.Selection);

		let meshSource = scope String();
		for (let entry in options.Selection.Entries)
		{
			if (entry.Kind == .AnimationClip)
				entry.Enabled = false;
			if ((entry.Kind == .Mesh) && meshSource.IsEmpty)
			{
				meshSource.Set(entry.SourceName);
				entry.TargetName.Set("hero.mesh");
			}
		}
		Test.Assert(!meshSource.IsEmpty);

		let target = fixture.RootGroup.CreateGroup("filtered");
		let imported = importer.Import(dropped, fixture.Context, target, options, prepared, null);
		Test.Assert(imported case .Ok);

		let group = imported.Value.OwningGroup;
		Test.Assert(group.GetInstance("hero.mesh") != null);
		Test.Assert(group.GetInstance(meshSource) == null);
		for (let instance in group.Instances)
			Test.Assert(instance.TypeName != "Sedulous.Animation.Pipeline.AnimationClipAsset");

		let manifest = ImportFixture.ReadManifest(imported.Value);
		Test.Assert(manifest != null);
		defer delete manifest;
		Test.Assert(manifest.Manifest.SkeletonGuid != Guid.Empty); // still selected
		Test.Assert(manifest.Manifest.AnimationGuid.IsEmpty);
		Test.Assert(manifest.Manifest.MeshGuid[0] != Guid.Empty);

		let stored = scope ImportPlan();
		importer.StoredSelection(target, dropped, stored);
		Test.Assert(!stored.IsEmpty);

		let fresh = scope ImportPlan();
		importer.DescribeImport(dropped, null, prepared, fresh);
		fresh.MergeStoredSelection(stored);

		var sawRenamedMesh = false;
		for (let entry in fresh.Entries)
		{
			if (entry.Kind == .AnimationClip)
				Test.Assert(!entry.Enabled);
			if (entry.SourceName == meshSource)
			{
				sawRenamedMesh = true;
				Test.Assert(entry.TargetName == "hero.mesh");
			}
		}
		Test.Assert(sawRenamedMesh);
	}
}
