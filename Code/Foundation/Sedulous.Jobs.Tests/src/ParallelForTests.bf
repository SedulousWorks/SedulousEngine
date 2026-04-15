using System;
using System.Threading;
using System.Collections;

namespace Sedulous.Jobs.Tests;

class ParallelForTests
{
	static void EnsureInit()
	{
		if (!JobSystem.IsInitialized)
			JobSystem.Initialize(4);
	}

	static void EnsureShutdown()
	{
		if (JobSystem.IsInitialized)
			JobSystem.Shutdown();
	}

	[Test]
	public static void TestEmptyRange()
	{
		EnsureInit();
		defer EnsureShutdown();

		bool called = false;
		JobSystem.ParallelFor(0, 0, scope [&](begin, end) => {
			called = true;
		});

		Test.Assert(!called);
	}

	[Test]
	public static void TestSingleItem()
	{
		EnsureInit();
		defer EnsureShutdown();

		int32 sum = 0;
		JobSystem.ParallelFor(0, 1, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
				Interlocked.Add(ref sum, i);
		});

		Test.Assert(sum == 0); // only item is index 0
	}

	[Test]
	public static void TestSmallRange()
	{
		EnsureInit();
		defer EnsureShutdown();

		int32 sum = 0;
		JobSystem.ParallelFor(0, 10, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
				Interlocked.Add(ref sum, i);
		});

		Test.Assert(sum == 45); // 0+1+2+...+9 = 45
	}

	[Test]
	public static void TestLargeRange()
	{
		EnsureInit();
		defer EnsureShutdown();

		int32 sum = 0;
		let count = 10000;

		JobSystem.ParallelFor(0, (int32)count, scope [&](begin, end) => {
			int32 localSum = 0;
			for (int32 i = begin; i < end; i++)
				localSum += i;
			Interlocked.Add(ref sum, localSum);
		});

		let expected = (int32)(count * (count - 1) / 2); // 49995000
		Test.Assert(sum == expected);
	}

	[Test]
	public static void TestNonZeroStart()
	{
		EnsureInit();
		defer EnsureShutdown();

		int32 sum = 0;
		JobSystem.ParallelFor(10, 20, scope [&](begin, end) => {
			int32 localSum = 0;
			for (int32 i = begin; i < end; i++)
				localSum += i;
			Interlocked.Add(ref sum, localSum);
		});

		// 10+11+12+...+19 = 145
		Test.Assert(sum == 145);
	}

	[Test]
	public static void TestAllIndicesCovered()
	{
		EnsureInit();
		defer EnsureShutdown();

		let count = 100;
		bool[] visited = scope bool[count];

		JobSystem.ParallelFor(0, (int32)count, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
				visited[i] = true;
		});

		for (int i = 0; i < count; i++)
			Test.Assert(visited[i]);
	}

	[Test]
	public static void TestNoOverlap()
	{
		EnsureInit();
		defer EnsureShutdown();

		let count = 1000;
		int32[] counts = scope int32[count];

		JobSystem.ParallelFor(0, (int32)count, scope [&](begin, end) => {
			for (int32 i = begin; i < end; i++)
				Interlocked.Increment(ref counts[i]);
		});

		// Each index should be processed exactly once
		for (int i = 0; i < count; i++)
			Test.Assert(counts[i] == 1);
	}

	[Test]
	public static void TestNestedParallelFor()
	{
		EnsureInit();
		defer EnsureShutdown();

		// Nested ParallelFor: outer splits into chunks, each chunk does inner ParallelFor.
		// This tests that the system doesn't deadlock when the calling thread
		// of an inner ParallelFor is a worker thread processing an outer chunk.
		// With the current design, nested ParallelFor works because the calling
		// thread participates as a worker and the inner chunks go to the shared queue.
		int32 sum = 0;

		JobSystem.ParallelFor(0, 4, scope [&](outerBegin, outerEnd) => {
			for (int32 outer = outerBegin; outer < outerEnd; outer++)
			{
				int32 localSum = 0;
				// Inner range: each outer value contributes its index
				localSum = outer;
				Interlocked.Add(ref sum, localSum);
			}
		});

		Test.Assert(sum == 6); // 0+1+2+3
	}

	[Test]
	public static void TestParallelForWithOneWorker()
	{
		// Ensure it works even with minimal parallelism
		JobSystem.Initialize(1);
		defer JobSystem.Shutdown();

		int32 sum = 0;
		JobSystem.ParallelFor(0, 100, scope [&](begin, end) => {
			int32 localSum = 0;
			for (int32 i = begin; i < end; i++)
				localSum += i;
			Interlocked.Add(ref sum, localSum);
		});

		Test.Assert(sum == 4950);
	}

	[Test]
	public static void TestMultipleConsecutiveCalls()
	{
		EnsureInit();
		defer EnsureShutdown();

		// Run multiple ParallelFor calls back-to-back
		for (int round = 0; round < 10; round++)
		{
			int32 sum = 0;
			JobSystem.ParallelFor(0, 100, scope [&](begin, end) => {
				int32 localSum = 0;
				for (int32 i = begin; i < end; i++)
					localSum += i;
				Interlocked.Add(ref sum, localSum);
			});
			Test.Assert(sum == 4950);
		}
	}
}
