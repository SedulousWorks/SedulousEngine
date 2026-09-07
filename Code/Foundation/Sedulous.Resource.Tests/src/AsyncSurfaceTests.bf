using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Resource.Tests;

/// The async surface a loading screen and a scene load are built out of: the ready
/// callback, the bind mode, the batch, and the pump budget.
///
/// Ported from Raptor's AsyncResourceTests.cpp cases that had no counterpart here, which
/// is how the absence of the surface stayed invisible: the tests were written against what
/// had been ported rather than against what Raptor has.
class AsyncSurfaceTests
{
	/// The transition, not the state: a handle that is already ready fires nothing, and a
	/// second pump must not fire it again.
	[Test]
	public static void OnReadyFiresOnceOnTheMainThread()
	{
		let fixture = scope ResourceFixture("scratch_async_onready");
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		let factory = scope AsyncProductFactory();
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 3, 1);
		let proxy = manager.BindAsync<TestProduct>(id);

		int32 readyCount = 0;
		int readyThread = 0;
		proxy.Handle.SetOnReady(new [&] () =>
		{
			readyCount++;
			readyThread = Thread.CurrentThread.Id;
		});

		manager.WaitAll();
		manager.Pump(); // A second pump must NOT fire it again.

		Test.Assert(readyCount == 1, scope $"fired {readyCount} times");
		Test.Assert(readyThread == Thread.CurrentThread.Id, "on the thread that pumps");
	}

	/// A callback set on a handle that is already ready never fires, because there is no
	/// transition left to observe.
	[Test]
	public static void OnReadyDoesNotFireForAnAlreadyReadyHandle()
	{
		let fixture = scope ResourceFixture("scratch_async_onready_late");
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope TestProductFactory();
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 2, 2);
		let proxy = manager.Bind<TestProduct>(id);
		Test.Assert(proxy.State == .Ready);

		int32 readyCount = 0;
		proxy.Handle.SetOnReady(new [&] () => { readyCount++; });
		manager.Pump();
		Test.Assert(readyCount == 0);
	}

	/// A factory that never migrated to the two stage path, and a manager with no pool,
	/// both have to build synchronously rather than leave a load pending forever.
	[Test]
	public static void BindAsyncFallsBackToASynchronousBuild()
	{
		let fixture = scope ResourceFixture("scratch_async_fallback");

		{
			let jobs = scope JobSystem(2);
			let manager = scope ResourceManager(fixture.Database, jobs);
			let factory = scope AsyncProductFactory();
			factory.SupportsAsyncStage = false;
			manager.AddFactory(factory);

			let id = fixture.Author("a", 5, 1);
			let proxy = manager.BindAsync<TestProduct>(id);

			Test.Assert(proxy.Get != null, "ready immediately, through the synchronous build");
			Test.Assert(proxy.State == .Ready);
			Test.Assert(proxy.Get.Area == 5);
			Test.Assert(manager.PendingCount == 0);
		}

		{
			// Supports async, but there is no pool to run a decode on.
			let manager = scope ResourceManager(fixture.Database);
			let factory = scope AsyncProductFactory();
			manager.AddFactory(factory);

			let id = fixture.Author("b", 6, 1);
			let proxy = manager.BindAsync<TestProduct>(id);

			Test.Assert(proxy.Get != null);
			Test.Assert(proxy.State == .Ready);
			Test.Assert(proxy.Get.Area == 6);
		}
	}

	/// A frame must not be spent finalizing everything that finished decoding: the budget
	/// caps the work and the rest resumes next tick.
	[Test]
	public static void PumpKeepsToItsBudgetAndResumesNextTick()
	{
		let fixture = scope ResourceFixture("scratch_async_budget");
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		let factory = scope AsyncProductFactory();
		// Each finalize costs more than the budget, so at most one fits in a pump.
		factory.FinalizeSleepMs = 5;
		manager.AddFactory(factory);

		const int cCount = 4;
		for (int i < cCount)
			manager.BindAsync<TestProduct>(fixture.Author(scope $"m{i}", (int32)i + 1, 1));

		int pumps = 0;
		while ((manager.PendingCount > 0) && (pumps < 10000))
		{
			manager.Pump(0.001); // A millisecond, against a five millisecond finalize.
			pumps++;
		}

		Test.Assert(manager.PendingCount == 0);
		Test.Assert(factory.Finalizes == cCount);
		Test.Assert(pumps >= cCount, scope $"finalized {cCount} in {pumps} pumps: the budget did nothing");
	}

	/// A scene load turns async binds on around resolving its resources, so a Ref that
	/// would have blocked decodes on a worker instead.
	[Test]
	public static void ARefBindsAsynchronouslyInsideTheScope()
	{
		let fixture = scope ResourceFixture("scratch_async_scope");
		let jobs = scope JobSystem(2);
		let manager = scope ResourceManager(fixture.Database, jobs);
		let factory = scope AsyncProductFactory();
		factory.Gate = new WaitEvent(); // Hold the decode so the pending state is observable.
		manager.AddFactory(factory);

		let id = fixture.Author("mesh", 5, 1);

		var reference = Ref<TestProduct>(id);
		{
			var scope_ = AsyncBindScope(manager);
			defer scope_.Dispose();
			Test.Assert(manager.AsyncBindsEnabled);
			reference.Bind(manager);
		}

		Test.Assert(!manager.AsyncBindsEnabled, "the scope put the mode back");
		Test.Assert(manager.PendingCount == 1, "routed through the async path");
		Test.Assert(reference.Get == null, "null while pending, which Proxy tolerates");

		factory.Gate.Set(true);
		manager.WaitAll();

		Test.Assert(manager.PendingCount == 0);
		Test.Assert(reference.Get != null, "and the same proxy now resolves");
		Test.Assert(reference.Get.Area == 5);
		reference.ClearBinding();
	}

	/// The mode is RESTORED rather than turned off, so a nested scope cannot switch it off
	/// for the outer one on the way out.
	[Test]
	public static void AsyncBindScopesNest()
	{
		let fixture = scope ResourceFixture("scratch_async_nest");
		let manager = scope ResourceManager(fixture.Database);

		Test.Assert(!manager.AsyncBindsEnabled);
		{
			var outer = AsyncBindScope(manager);
			defer outer.Dispose();
			{
				var inner = AsyncBindScope(manager);
				defer inner.Dispose();
				Test.Assert(manager.AsyncBindsEnabled);
			}
			Test.Assert(manager.AsyncBindsEnabled, "the inner scope restored, not cleared");
		}
		Test.Assert(!manager.AsyncBindsEnabled);
	}

	/// What a loading screen reads.
	[Test]
	public static void ABatchReportsProgressAsLoadsFinalize()
	{
		let fixture = scope ResourceFixture("scratch_async_batch");
		let jobs = scope JobSystem(3);
		let manager = scope ResourceManager(fixture.Database, jobs);
		let factory = scope AsyncProductFactory();
		factory.Gate = new WaitEvent(); // Hold every decode.
		manager.AddFactory(factory);

		for (int i < 3)
			manager.BindAsync<TestProduct>(fixture.Author(scope $"m{i}", (int32)i + 1, 1));

		var batch = AsyncLoadBatch(manager);
		batch.Snapshot();
		Test.Assert(batch.Total == 3);
		Test.Assert(batch.Remaining == 3);
		Test.Assert(batch.Progress == 0.0f);
		Test.Assert(!batch.IsComplete);

		factory.Gate.Set(true);
		batch.WaitComplete();

		Test.Assert(batch.IsComplete);
		Test.Assert(batch.Remaining == 0);
		Test.Assert(batch.Progress == 1.0f);
	}

	/// A batch with nothing in it is complete, not divided by zero.
	[Test]
	public static void AnEmptyBatchIsComplete()
	{
		let fixture = scope ResourceFixture("scratch_async_batch_empty");
		let manager = scope ResourceManager(fixture.Database);

		var batch = AsyncLoadBatch(manager);
		batch.Snapshot();
		Test.Assert(batch.Total == 0);
		Test.Assert(batch.IsComplete);
		Test.Assert(batch.Progress == 1.0f);
		Test.Assert(batch.Step(), "stepping an empty batch reports it done");
	}
}
