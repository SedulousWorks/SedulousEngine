using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Cook;

namespace Sedulous.ModelImporter.Tests;

/// An imported model through the incremental cook, which is the real pipeline path.
class ModelCookDriverTests
{
	/// The cook mirrors the source group tree, so the products are not all in one place.
	private static void CollectInstances(Group group, List<Instance> outInstances)
	{
		for (let instance in group.Instances)
			outInstances.Add(instance);
		for (let child in group.Groups)
			CollectInstances(child, outInstances);
	}

	private static Instance ImportCharacter(ImportFixture fixture)
	{
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		return imported.Value;
	}

	private static void CookEverything(ImportFixture fixture, int expectAtLeast)
	{
		let driver = scope CookDriver(fixture.Db, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);

		let plan = scope CookPlan();
		driver.Plan(plan);
		Test.Assert(plan.Dirty.Count >= expectAtLeast, scope $"planned {plan.Dirty.Count}");

		let stats = scope CookStats();
		driver.Execute(plan, stats);
		Test.Assert(stats.Failed == 0, scope $"{stats.Failed} failed");
		Test.Assert(stats.Cooked == plan.Dirty.Count);

		// Incremental: a second plan over the same sources finds nothing left to do.
		let again = scope CookPlan();
		driver.Plan(again);
		Test.Assert(again.Dirty.IsEmpty);
	}

	/// Every asset the fan out wrote cooks, and each product lands under its SOURCE's
	/// identity, which is what lets the manifest's recorded ids bind the cooked products.
	[Test]
	public static void TheWholeFanOutCooksAndProductsKeepTheSourceIdentities()
	{
		let fixture = scope ImportFixture("scratch_model_cook_driver");
		let manifestInstance = ImportCharacter(fixture);
		let group = manifestInstance.OwningGroup;

		CookEverything(fixture, group.Instances.Count);

		for (let instance in group.Instances)
		{
			let product = fixture.CookedDb.GetInstance(instance.Id);
			Test.Assert(product != null, scope String(instance.Name));
		}

		let manifest = ImportFixture.ReadManifest(manifestInstance);
		Test.Assert(manifest != null);
		defer delete manifest;

		// The mesh the manifest names is readable as a cooked product.
		let meshProduct = fixture.CookedDb.ReadObject(manifest.Manifest.MeshGuid[1]);
		Test.Assert(meshProduct != null);
		delete Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(meshProduct));
	}

	/// Delete the model's group, drop the file again, cook again.
	///
	/// The regression this pins: the second cook adopted a SAME NAMED product left behind by
	/// the first generation, which broke the rule that a product carries its source's
	/// identity, and the editor then read one product's bytes as another's type.
	[Test]
	public static void DeletingTheGroupAndReImportingKeepsTheIdentitiesClean()
	{
		let fixture = scope ImportFixture("scratch_model_recook");
		let first = ImportCharacter(fixture);
		CookEverything(fixture, first.OwningGroup.Instances.Count);

		Test.Assert(fixture.Db.DeleteGroup(first.OwningGroup) case .Ok);

		let second = ImportCharacter(fixture);
		let group = second.OwningGroup;
		CookEverything(fixture, group.Instances.Count);

		// EVERY cooked product answers to a source that still exists, and every source has
		// one: a product adopted from the previous generation would show up as either a
		// product with no source or a source whose product carries the wrong identity.
		let sources = scope List<Guid>();
		for (let instance in group.Instances)
		{
			sources.Add(instance.Id);
			Test.Assert(fixture.CookedDb.GetInstance(instance.Id) != null,
				scope String(instance.Name));
		}

		let products = scope List<Instance>();
		CollectInstances(fixture.CookedDb.RootGroup, products);
		for (let product in products)
			Test.Assert(sources.Contains(product.Id), scope String(product.Name));
	}
}
