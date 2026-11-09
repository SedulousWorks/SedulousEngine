using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// An evicted resource reads unbound: its handle stays, Failed and empty, its product waits out
/// the frames in flight, and a reload of the identity revives the same handle.
class EvictTests
{
	[Test]
	public static void AHeldReferenceReadsUnboundAndTheProductWaitsOutTheFrames()
	{
		let fixture = scope ResourceFixture("scratch_resource_evict");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 3, 3);
		var held = Ref<TestProduct>(id);
		held.Bind(fixture.Manager);
		Test.Assert(held.Get.Area == 9);
		let handle = fixture.Manager.FindHandle(id);

		let destroyedBefore = TestProduct.Destroyed;
		fixture.Manager.Evict(id);
		Test.Assert(held.Get == null, "the held reference reads nothing");
		Test.Assert(held.State == .Failed);
		Test.Assert(fixture.Manager.FindHandle(id) === handle, "the handle stays registered");
		Test.Assert(fixture.Manager.HandleCount == 1);

		// Parked, not freed: a frame in flight may still read it.
		Test.Assert(fixture.Manager.GraveyardCount == 1);
		Test.Assert(TestProduct.Destroyed == destroyedBefore);
		for (int frame < 7)
		{
			fixture.Manager.CollectGarbage();
			Test.Assert(TestProduct.Destroyed == destroyedBefore, scope $"freed after {frame + 1} frames");
		}
		fixture.Manager.CollectGarbage();
		Test.Assert(fixture.Manager.GraveyardCount == 0);
		Test.Assert(TestProduct.Destroyed == destroyedBefore + 1, "and then freed");
	}

	/// The record deleted, the resource evicted, the record back under the same identity: a reload
	/// rebuilds into the handle the held reference has watched all along.
	[Test]
	public static void AReloadRevivesTheSameHandle()
	{
		let fixture = scope ResourceFixture("scratch_resource_evict_revive");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 5);
		let proxy = fixture.Manager.Bind<TestProduct>(id);
		let handle = proxy.Handle;
		Test.Assert(proxy.Get.Area == 10);

		Test.Assert(fixture.Database.DeleteInstance(id) case .Ok);
		fixture.Manager.Evict(id);
		Test.Assert(proxy.Get == null);
		fixture.Manager.Reload(id);
		Test.Assert(proxy.State == .Failed, "nothing to rebuild from while the record is gone");

		let back = fixture.Database.RootGroup.CreateInstanceWithId(id, "mesh", "Sedulous.Resource.Tests.TestSource");
		let source = scope TestSource();
		source.Width = 4;
		source.Height = 5;
		Test.Assert(back.WriteObject(source) case .Ok);

		fixture.Manager.Reload(id);
		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get.Area == 20, "the record that came back");
		Test.Assert(fixture.Manager.FindHandle(id) === handle, "into the same handle");
	}

	/// A load still decoding is finished before the eviction, so its product cannot land after it.
	[Test]
	public static void AnEvictionDuringALoadStays()
	{
		let fixture = scope ResourceFixture("scratch_resource_evict_pending");
		let factory = scope AsyncProductFactory();
		let tasks = scope TaskPool(2);
		let manager = scope ResourceManager(fixture.Database, tasks);
		factory.Gate = new WaitEvent();
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 4, 4);
		let proxy = manager.BindAsync<TestProduct>(id);
		Test.Assert(proxy.State == .Pending);

		factory.Gate.Set(true);
		manager.Evict(id);
		Test.Assert(proxy.State == .Failed, "finished, then evicted");
		manager.WaitAll();
		Test.Assert(proxy.State == .Failed);
		Test.Assert(proxy.Get == null);
		Test.Assert(manager.PendingCount == 0);
		Test.Assert(manager.GraveyardCount == 1, "the product the load made, parked");
	}

	[Test]
	public static void EvictingAnUnknownIdentityDoesNothing()
	{
		let fixture = scope ResourceFixture("scratch_resource_evict_unknown");
		let factory = scope TestProductFactory();
		fixture.Manager.AddFactory(factory);

		let id = fixture.Author("mesh", 1, 1);
		let proxy = fixture.Manager.Bind<TestProduct>(id);

		fixture.Manager.Evict(Guid.Create());
		fixture.Manager.Evict(Guid.Empty);
		Test.Assert(fixture.Manager.HandleCount == 1, "no handle made for it");
		Test.Assert(fixture.Manager.GraveyardCount == 0);
		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get.Area == 1);
	}
}
