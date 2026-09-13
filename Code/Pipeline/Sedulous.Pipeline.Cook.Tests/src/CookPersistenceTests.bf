using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Pipeline.Cook;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Cook.Tests;

/// What survives a session, what a failure leaves behind, and what a corrupt cache does.
class CookPersistenceTests
{
	[Test]
	public static void AFailureStaysDirtyAndAnOrphanIsSwept()
	{
		let fixture = scope CookFixture("scratch_cook_failure");
		let a = fixture.AddWidget("A", 5);

		let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs);

		CookWidgetBuilder.ShouldFail = true;
		defer { CookWidgetBuilder.ShouldFail = false; }
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			let stats = scope CookStats();
			driver.Execute(plan, stats);
			Test.Assert(stats.Failed == 1);
		}

		// A FAILED record never reads clean, so the next plan still wants it.
		Test.Assert(CookFixture.PlanDirty(driver) == 1);

		CookWidgetBuilder.ShouldFail = false;
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			driver.Execute(plan, scope CookStats());
		}
		Test.Assert(CookFixture.PlanDirty(driver) == 0);
		Test.Assert(fixture.CookedValue(a) == 5);

		// An ORPHAN: the source is deleted, so the plan sweeps its product and its record.
		Test.Assert(fixture.SourceDb.DeleteInstance(a) case .Ok);
		{
			let plan = scope CookPlan();
			driver.Plan(plan);
			Test.Assert(plan.Orphans.Count == 1);
			Test.Assert(plan.Orphans[0] == a);

			let stats = scope CookStats();
			driver.Execute(plan, stats);
			Test.Assert(stats.OrphansSwept == 1);
		}
		Test.Assert(fixture.CookedDb.GetInstance(a) == null);

		let after = scope CookPlan();
		driver.Plan(after);
		Test.Assert(after.Orphans.IsEmpty);
	}

	[Test]
	public static void TheDatabasePersistsAndCorruptionRePlansEverything()
	{
		let fixture = scope CookFixture("scratch_cook_persist");
		fixture.WriteSourceFile("a.txt", "123");
		fixture.AddWidget("A", 1, "a.txt");
		fixture.AddWidget("B", 2);

		{
			let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
				fixture.SourcesFs, fixture.CacheFs);
			let plan = scope CookPlan();
			driver.Plan(plan);
			driver.Execute(plan, scope CookStats());
		}

		// A FRESH session, meaning a new driver over re-opened databases, finds it all clean.
		fixture.Reopen();
		{
			let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
				fixture.SourcesFs, fixture.CacheFs);
			let plan = scope CookPlan();
			driver.Plan(plan);
			Test.Assert(plan.Dirty.IsEmpty);
			Test.Assert(plan.UpToDate == 2);
		}

		// A CORRUPT cache re-cooks everything rather than crashing or, worse, trusting half of
		// it: a cook that ran too much is slow, and one that ran too little is wrong.
		let garbage = scope List<uint8>() { 1, 2, 3, 4, 5, 6, 7 };
		Test.Assert(fixture.CacheFs.Save(CookDb.cDefaultName, garbage) case .Ok);
		{
			let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
				fixture.SourcesFs, fixture.CacheFs);
			let plan = scope CookPlan();
			driver.Plan(plan);
			Test.Assert(plan.Dirty.Count == 2);

			let stats = scope CookStats();
			driver.Execute(plan, stats);
			Test.Assert(stats.Cooked == 2);
		}
	}

	/// The regression a user found as a crash: the first large PARALLEL cook created product
	/// instances on worker threads at the same time, racing the database's group tree and its
	/// identity index. Products are pre-created serially now, and a worker only reads.
	[Test]
	public static void AWideLevelCooksInParallel()
	{
		let fixture = scope CookFixture("scratch_cook_parallel");
		const int32 cAssets = 48;

		let ids = scope List<Guid>();
		for (int32 i < cAssets)
		{
			let name = scope $"W{(char8)('a' + i % 26)}{(char8)('a' + (i / 26) % 26)}";
			ids.Add(fixture.AddWidget(name, i));
		}

		let jobs = scope JobSystem();
		let driver = scope CookDriver(fixture.SourceDb, fixture.CookedDb, fixture.Builders,
			fixture.SourcesFs, fixture.CacheFs, jobs);

		let plan = scope CookPlan();
		driver.Plan(plan);
		Test.Assert(plan.Dirty.Count == cAssets);

		let stats = scope CookStats();
		driver.Execute(plan, stats);
		Test.Assert(stats.Cooked == cAssets);
		Test.Assert(stats.Failed == 0);

		for (int32 i < cAssets)
			Test.Assert(fixture.CookedValue(ids[i]) == i);

		let after = scope CookPlan();
		driver.Plan(after);
		Test.Assert(after.Dirty.IsEmpty);
	}
}
