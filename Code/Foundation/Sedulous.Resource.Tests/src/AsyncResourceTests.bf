using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// The two stage path: decode on a worker, finalize on the main thread.
class AsyncResourceTests
{
	[Test]
	public static void BindAsyncIsPendingUntilPumped()
	{
		let fixture = scope ResourceFixture("scratch_async_pending");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		factory.Gate = new WaitEvent();
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 4, 5);
		let proxy = manager.BindAsync<TestProduct>(id);

		// The handle exists at once, with nothing in it yet.
		Test.Assert(proxy.State == .Pending);
		Test.Assert(proxy.Get == null, "no product until it has been finalized");
		Test.Assert(manager.PendingCount == 1);

		// Let the decode through, then turn it into a product.
		factory.Gate.Set(true);
		manager.WaitAll();

		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get != null);
		Test.Assert(proxy.Get.Area == 20);
		Test.Assert(manager.PendingCount == 0, "the record was reaped");
	}

	/// The contract the two stages exist for: a decode CAN run on a worker while the main
	/// thread does something else, and everything touching the manager runs on the main one.
	///
	/// "Can", not "does". Waiting on this job system PARTICIPATES: a caller that waits runs
	/// the work itself rather than blocking, so WaitAll may well decode on the main thread,
	/// and that is the pool being efficient rather than a broken contract. The requirement
	/// on DecodeStage is that it touches nothing shared, not that it lands on a
	/// particular thread. So this waits by POLLING, which does not participate.
	[Test]
	public static void ADecodeCanRunOnAWorkerAndFinalizeOnTheMainThread()
	{
		let fixture = scope ResourceFixture("scratch_async_threads");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		manager.AddFactory(factory);

		let mainThreadId = Thread.CurrentThread.Id;
		let proxy = manager.BindAsync<TestProduct>(fixture.Author("mesh", 2, 2));

		// Polled rather than waited on, so the main thread never picks the work up itself.
		//
		// On the decode having RETURNED, not having started: a decode that is merely under
		// way has not pushed its result to the completed list, and pumping then finalizes
		// nothing. That raced, and failed about one run in twenty.
		for (int attempt < 2000)
		{
			if (factory.DecodesFinished > 0)
				break;
			Thread.Sleep(1);
		}

		Test.Assert(factory.Decodes == 1, "a worker ran the decode");
		Test.Assert(factory.DecodeThreadId != mainThreadId, "off the main thread");
		Test.Assert(factory.Finalizes == 0, "and nothing has been finalized yet");

		manager.Pump();
		Test.Assert(factory.Finalizes == 1);
		Test.Assert(factory.FinalizeThreadId == mainThreadId, "finalize is on the main thread");
		Test.Assert(proxy.State == .Ready);
	}

	/// No job system means no workers to decode on, so it builds synchronously and every
	/// caller keeps working unchanged.
	[Test]
	public static void WithoutAJobSystemItBuildsSynchronously()
	{
		let fixture = scope ResourceFixture("scratch_async_nojobs");
		let factory = scope AsyncProductFactory();
		let manager = scope ResourceManager(fixture.Database);
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<TestProduct>(fixture.Author("mesh", 3, 3));
		Test.Assert(proxy.State == .Ready, "ready immediately, with nothing to pump");
		Test.Assert(proxy.Get.Area == 9);
		Test.Assert(manager.PendingCount == 0);
	}

	/// A factory that has not opted in is built the old way, even asynchronously.
	[Test]
	public static void AFactoryThatHasNotOptedInBuildsSynchronously()
	{
		let fixture = scope ResourceFixture("scratch_async_optout");
		let factory = scope TestProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		// The plain factory: SupportsAsync is the interface default, which is false.
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<TestProduct>(fixture.Author("mesh", 2, 3));
		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get.Area == 6);
	}

	/// A synchronous bind of something still decoding has to hand back a finished product,
	/// so it completes the load inline rather than returning it pending.
	[Test]
	public static void ASynchronousBindCompletesAPendingLoad()
	{
		let fixture = scope ResourceFixture("scratch_async_upgrade");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		factory.Gate = new WaitEvent();
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 5, 5);
		let async = manager.BindAsync<TestProduct>(id);
		Test.Assert(async.State == .Pending);

		factory.Gate.Set(true);

		// A synchronous bind of the same identity must not come back empty.
		let sync = manager.Bind<TestProduct>(id);
		Test.Assert(sync.State == .Ready, "the pending load was completed inline");
		Test.Assert(sync.Get != null);
		Test.Assert(sync.Get.Area == 25);
		Test.Assert(async.Get === sync.Get, "and the pending proxy sees the same product");
	}

	/// Binding the same identity twice while it is in flight shares the one load rather
	/// than decoding it twice.
	[Test]
	public static void ConcurrentBindsShareOneLoad()
	{
		let fixture = scope ResourceFixture("scratch_async_share");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		factory.Gate = new WaitEvent();
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 2);
		let first = manager.BindAsync<TestProduct>(id);
		let second = manager.BindAsync<TestProduct>(id);

		Test.Assert(manager.PendingCount == 1, "one load, not two");
		Test.Assert(first.Handle == second.Handle);

		factory.Gate.Set(true);
		manager.WaitAll();

		Test.Assert(factory.Decodes == 1, "decoded once");
		Test.Assert(first.Get === second.Get);
	}

	/// A pool with no workers is the single threaded case, and it still has to finish: the
	/// pump drives the queued decode itself, because nothing else will.
	[Test]
	public static void APoolWithNoWorkersStillCompletes()
	{
		let fixture = scope ResourceFixture("scratch_async_zero");
		let jobs = scope JobSystem(0);
		Test.Assert(jobs.WorkerCount == 0);

		let factory = scope AsyncProductFactory();
		let manager = scope ResourceManager(fixture.Database, jobs);
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<TestProduct>(fixture.Author("mesh", 3, 4));
		Test.Assert(proxy.State == .Pending, "nothing has run it yet");

		manager.Pump();

		Test.Assert(proxy.State == .Ready, "the pump ran the decode itself");
		Test.Assert(proxy.Get.Area == 12);
		Test.Assert(factory.DecodeThreadId == Thread.CurrentThread.Id, "on this thread, since there is no other");
	}

	/// A decode that fails leaves the resource Failed rather than Pending forever.
	[Test]
	public static void AFailedDecodeSettlesAsFailed()
	{
		let fixture = scope ResourceFixture("scratch_async_fail");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		manager.AddFactory(factory);

		// An identity with no instance behind it cannot decode, so it falls back to the
		// synchronous path and fails there.
		let proxy = manager.BindAsync<TestProduct>(Guid.Create());
		manager.WaitAll();

		Test.Assert(proxy.State == .Failed);
		Test.Assert(proxy.Get == null);
		Test.Assert(manager.PendingCount == 0);
	}

	/// Failing on the far side of the thread hop. The existing failure cases all fail
	/// BEFORE a factory is reached (no instance, no factory registered); these are the
	/// factory itself declining, at each of the two stages.
	[Test]
	public static void ARefusedDecodeSettlesAsFailed()
	{
		let fixture = scope ResourceFixture("scratch_async_refuse_decode");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		factory.RefuseDecode = true;
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<TestProduct>(fixture.Author("mesh", 2, 2));
		manager.WaitAll();

		Test.Assert(factory.Decodes == 1, "the decode ran and declined");
		Test.Assert(factory.Finalizes == 0, "so there was nothing to finalize");
		Test.Assert(proxy.State == .Failed);
		Test.Assert(proxy.Get == null);
		Test.Assert(manager.PendingCount == 0, "a refusal settles rather than staying in flight");
	}

	[Test]
	public static void ARefusedFinalizeSettlesAsFailed()
	{
		let fixture = scope ResourceFixture("scratch_async_refuse_finalize");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		factory.RefuseFinalize = true;
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<TestProduct>(fixture.Author("mesh", 2, 2));
		manager.WaitAll();

		Test.Assert(factory.Decodes == 1);
		Test.Assert(factory.Finalizes == 1, "the finalize ran and declined");
		Test.Assert(proxy.State == .Failed, "a null product is a failure, not a ready nothing");
		Test.Assert(proxy.Get == null);
		Test.Assert(manager.PendingCount == 0);
	}

	/// The reason FinalizeCompleted reloads dependents. A composite built while its child
	/// was still decoding sees nothing; when the child settles, the composite is rebuilt
	/// through the dependency edge rather than staying half empty forever.
	[Test]
	public static void AChildSettlingRebuildsTheCompositeThatWaitedOnIt()
	{
		let fixture = scope ResourceFixture("scratch_async_revive");
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		let child = scope AsyncProductFactory();
		child.Gate = new WaitEvent();
		manager.AddFactory(child);

		let childId = fixture.Author("mesh", 3, 3);
		let parentId = fixture.Author("composite", 1, 1);
		let composite = scope CompositeFactory(childId);
		composite.Async = true;
		manager.AddFactory(composite);

		// The child is held in its decode, so the composite builds against nothing.
		let parent = manager.Bind<CompositeProduct>(parentId);
		Test.Assert(parent.State == .Ready, "the composite itself built");
		Test.Assert(parent.Get.ChildArea == 0, "but its child had not settled");
		Test.Assert(manager.PendingCount == 1);

		child.Gate.Set();
		manager.WaitAll();

		Test.Assert(parent.Get.ChildArea == 9, "the settled child rebuilt the composite");
		Test.Assert(composite.Builds == 2, "which is a rebuild, not the first build");
	}

	/// Several loads at once, which is what a scene load looks like.
	[Test]
	public static void ManyLoadsSettleTogether()
	{
		let fixture = scope ResourceFixture("scratch_async_many");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(4);
		let manager = scope ResourceManager(fixture.Database, jobs);
		manager.AddFactory(factory);

		let proxies = scope System.Collections.List<Proxy<TestProduct>>();
		for (int32 i < 8)
			proxies.Add(manager.BindAsync<TestProduct>(fixture.Author(scope $"a{i}", i + 1, 2)));

		Test.Assert(manager.PendingCount == 8);
		manager.WaitAll();

		Test.Assert(manager.PendingCount == 0);
		Test.Assert(factory.Decodes == 8);
		for (int32 i < 8)
		{
			Test.Assert(proxies[i].State == .Ready);
			Test.Assert(proxies[i].Get.Area == (i + 1) * 2, scope $"load {i}");
		}
	}

	/// Destroying the manager with a decode still in flight must DRAIN it.
	///
	/// The decode job holds the manager. Freeing the manager while a worker is inside one is
	/// a use after free that only shows up under load, so the destructor waits the jobs out
	/// and discards their results rather than finalising during teardown.
	[Test]
	public static void DestroyingTheManagerWithAnInFlightDecodeDrainsIt()
	{
		let fixture = scope ResourceFixture("scratch_async_teardown");
		let factory = scope AsyncProductFactory();
		let jobs = scope JobSystem(2);

		{
			let manager = scope ResourceManager(fixture.Database, jobs);
			manager.AddFactory(factory);
			manager.BindAsync<TestProduct>(fixture.Author("mesh", 2, 2));
			// Deliberately never pumped: the decode is left in flight and the destructor at
			// the end of this scope is what has to see it out.
		}

		Test.Assert(factory.DecodesFinished == 1, "the decode ran to completion during teardown");
	}
}
