using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Pipeline.Cook;

namespace Sedulous.Pipeline.Cook.Tests;

/// What a plan decides needs cooking, and what a cook leaves behind.
class CookPlanTests
{
	[Test]
	public static void AFullCookThenACleanPlan()
	{
		let fixture = scope CookFixture("scratch_cook_full");
		fixture.WriteSourceFile("a.txt", "12345");
		let a = fixture.AddWidget("A", 10, "a.txt");
		let b = fixture.AddWidget("B", 20);

		let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);

		let plan = scope CookPlan();
		driver.Plan(plan);
		Test.Assert(plan.Dirty.Count == 2);
		Test.Assert(plan.UpToDate == 0);

		let stats = scope CookStats();
		driver.Execute(plan, stats);
		Test.Assert(stats.Cooked == 2);
		Test.Assert(stats.Failed == 0);

		// The hot reload handoff lists exactly what was rebuilt.
		Test.Assert(stats.CookedProducts.Count == 2);
		Test.Assert(stats.CookedProducts.Contains(a));
		Test.Assert(stats.CookedProducts.Contains(b));

		// A product carries its SOURCE's identity and the builder's product type, and its
		// content is what the bake produced.
		let productA = fixture.CookedDb.GetInstance(a);
		Test.Assert(productA != null);
		Test.Assert(productA.TypeName == "Sedulous.Pipeline.Cook.Tests.CookWidgetProduct");
		Test.Assert(fixture.CookedValue(a) == 15, "the setting of ten plus five file bytes");
		Test.Assert(fixture.CookedValue(b) == 20);

		// And the next plan finds nothing to do.
		let again = scope CookPlan();
		driver.Plan(again);
		Test.Assert(again.Dirty.IsEmpty);
		Test.Assert(again.UpToDate == 2);
	}

	[Test]
	public static void AnEditDirtiesExactlyItsConsumer()
	{
		let fixture = scope CookFixture("scratch_cook_edit");
		fixture.WriteSourceFile("a.txt", "12345");
		let a = fixture.AddWidget("A", 10, "a.txt");
		fixture.AddWidget("B", 20);

		let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			driver.Execute(plan, scope CookStats());
		}
		Test.Assert(CookFixture.PlanDirty(driver) == 0);

		// The FILE changes. A different size, so the stat memo cannot answer for it.
		fixture.WriteSourceFile("a.txt", "1234567");
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			Test.Assert(plan.Dirty.Count == 1);
			Test.Assert(plan.Dirty[0].Source == a);
			driver.Execute(plan, scope CookStats());
		}
		Test.Assert(fixture.CookedValue(a) == 17);

		// The SETTINGS change, which moves the envelope's hash rather than a file's.
		{
			let instance = fixture.SourceDb.GetInstance(a);
			let asset = scope CookWidgetAsset();
			asset.Quality = 11;
			asset.FileName.Set("a.txt");
			Test.Assert(instance.WriteObject(asset) case .Ok);
		}
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			Test.Assert(plan.Dirty.Count == 1);
			driver.Execute(plan, scope CookStats());
		}
		Test.Assert(fixture.CookedValue(a) == 18);

		// And a BUILDER version bump re-cooks every product of that builder, which is what
		// makes a cook logic change safe to ship.
		CookWidgetBuilder.CurrentVersion = 2;
		defer { CookWidgetBuilder.CurrentVersion = 1; }
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			Test.Assert(plan.Dirty.Count == 2);
		}
	}

	[Test]
	public static void AReadChainsAndAReferenceDoesNot()
	{
		let fixture = scope CookFixture("scratch_cook_chain");
		fixture.WriteSourceFile("tex.bin", "xx");
		let texture = fixture.AddWidget("Texture", 1, "tex.bin");

		// One asset READS the texture and another only REFERENCES it.
		let material = fixture.AddChain("Material", texture);
		let scene = fixture.AddChain("Scene", .Empty, texture);

		let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);

		let plan = scope CookPlan();
		driver.Plan(plan);
		Test.Assert(plan.Dirty.Count == 3);

		// Dependency ORDER: what is read cooks before what reads it.
		var textureIndex = -1;
		var materialIndex = -1;
		for (int i < plan.Dirty.Count)
		{
			if (plan.Dirty[i].Source == texture)
				textureIndex = i;
			if (plan.Dirty[i].Source == material)
				materialIndex = i;
		}
		Test.Assert((textureIndex >= 0) && (materialIndex >= 0));
		Test.Assert(textureIndex < materialIndex);

		driver.Execute(plan, scope CookStats());
		Test.Assert(CookFixture.PlanDirty(driver) == 0);

		// Editing the texture's file dirties the texture and what READS it, and leaves what
		// only refers to it alone: a reference orders the cook and says nothing about content.
		fixture.WriteSourceFile("tex.bin", "xxxx");
		let after = scope CookPlan();
		driver.Plan(after);
		Test.Assert(after.Dirty.Count == 2);
		for (let item in after.Dirty)
			Test.Assert(item.Source != scene);
	}
}
