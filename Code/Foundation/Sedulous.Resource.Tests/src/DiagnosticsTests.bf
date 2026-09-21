using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// What the cache can be asked about itself: what failed to resolve, what is resident, and
/// what is only resident because the cache is holding it.
///
/// Unresolved binds are enumerable and heal off the list; the live-product report counts
/// by type and flags cache-only handles.
class DiagnosticsTests
{
	/// A bind against an identity with no backing instance stays cached with no product.
	/// That is an editor page pointing at something not yet cooked, and the list of those
	/// IS the cook queue, so it has to be enumerable and it has to empty as they land.
	[Test]
	public static void UnresolvedBindsAreEnumerableAndHealOffTheList()
	{
		let fixture = scope ResourceFixture("scratch_resource_unresolved");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let good = fixture.Author("steel", 8, 8);
		let resolved = fixture.Manager.Bind<TestProduct>(good);
		Test.Assert(resolved.Get != null);

		let missing = Guid(7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7);
		let pending = fixture.Manager.Bind<TestProduct>(missing);
		Test.Assert(pending.Get == null);

		let unresolved = scope List<Guid>();
		fixture.Manager.CollectUnresolved(unresolved);
		Test.Assert(unresolved.Count == 1, scope $"got {unresolved.Count}");
		Test.Assert(unresolved[0] == missing);
		Test.Assert(!unresolved.Contains(good), "what built is not on the list");

		// The instance appears, as though a cook had landed. After the reload the identity
		// resolves, drops off the list, and the ORIGINAL proxy heals through the handle
		// without being rebound.
		let late = fixture.Database.RootGroup.CreateInstanceWithId(missing, "late",
			"Sedulous.Resource.Tests.TestSource");
		Test.Assert(late != null);
		let source = scope TestSource();
		source.Width = 4;
		source.Height = 4;
		late.WriteObject(source).IgnoreError();

		fixture.Manager.Reload(missing);
		Test.Assert(pending.Get != null, "the proxy that was held all along");
		Test.Assert(pending.Get.Area == 16);

		unresolved.Clear();
		fixture.Manager.CollectUnresolved(unresolved);
		Test.Assert(unresolved.IsEmpty);
	}

	/// Unreferenced is the column that matters: a product nothing outside the cache holds
	/// is exactly what a purge would release, which is what an eviction policy has to be
	/// designed against rather than guessed at.
	[Test]
	public static void TheLiveProductReportFlagsCacheOnlyHandles()
	{
		let fixture = scope ResourceFixture("scratch_resource_report");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);
		let id = fixture.Author("steel", 8, 8);

		let rows = scope List<LiveProductRow>();
		fixture.Manager.ReportLiveProducts(rows);
		Test.Assert(rows.IsEmpty, "nothing bound yet");

		{
			var proxy = fixture.Manager.Bind<TestProduct>(id);
			proxy.Retain();
			defer proxy.Forget();
			Test.Assert(proxy.Get != null);

			fixture.Manager.ReportLiveProducts(rows);
			Test.Assert(rows.Count == 1, scope $"got {rows.Count} rows");
			Test.Assert(rows[0].Live == 1);
			Test.Assert(rows[0].Pending == 0 && rows[0].Failed == 0);
			Test.Assert(rows[0].Unreferenced == 0, "something outside the cache holds it");
		}

		fixture.Manager.ReportLiveProducts(rows);
		Test.Assert(rows.Count == 1);
		Test.Assert(rows[0].Live == 1);
		Test.Assert(rows[0].Unreferenced == 1, "the cache is now the only owner");
	}

	/// A handle whose product never built counts as failed rather than live, so the report
	/// does not make a broken reference look resident.
	[Test]
	public static void AFailedHandleIsCountedSeparately()
	{
		let fixture = scope ResourceFixture("scratch_resource_report_failed");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		fixture.Manager.Bind<TestProduct>(Guid(9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9));

		let rows = scope List<LiveProductRow>();
		fixture.Manager.ReportLiveProducts(rows);
		Test.Assert(rows.Count == 1);
		Test.Assert(rows[0].Failed == 1);
		Test.Assert(rows[0].Live == 0);
	}

	[Test]
	public static void FactoriesAreCountedAndQueryable()
	{
		let fixture = scope ResourceFixture("scratch_resource_factories");
		Test.Assert(fixture.Manager.FactoryCount == 0);
		Test.Assert(!fixture.Manager.HasFactory(ResourceManager.ProductTypeIdOf<TestProduct>()));

		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		Test.Assert(fixture.Manager.FactoryCount == 1);
		Test.Assert(fixture.Manager.HasFactory(ResourceManager.ProductTypeIdOf<TestProduct>()));
		Test.Assert(!fixture.Manager.HasFactory(0), "and nothing else");
	}
}
