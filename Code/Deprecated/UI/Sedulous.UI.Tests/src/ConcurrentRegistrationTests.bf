using System;
using System.Collections;
using System.Threading;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The registries are process wide and registered lazily, and the asset cook reaches that
/// lazy registration FROM JOB WORKERS: a UI document builder calls MarkupLoader.Initialize
/// per build, a theme builder goes through the style sheet loader, and the cook driver runs
/// builds through ParallelFor. Two builders at the same dependency level therefore race.
///
/// A plain "have I run yet" flag does not survive that. Both workers read false, both run the
/// registration, and two threads rehash the same dictionary, which surfaces as a heap
/// corruption abort while cooking a sample project.
static class ConcurrentRegistrationTests
{
	private const int cThreads = 8;

	/// Rounds, because a race is a probability and one attempt is not a test. Against the
	/// unguarded flags this trips within the first few.
	private const int cRounds = 200;

	/// The starting gate, and the count of workers waiting at it. STATIC rather than captured,
	/// so the workers touch the one location with no closure semantics in the way.
	private static bool sGate = false;
	private static int32 sWaiting = 0;

	[Test]
	public static void ConcurrentRegistrationLeavesTheRegistriesWhole()
	{
		// The single threaded truth to measure against. Asserting a COUNT rather than a crash
		// is what catches the quiet half of the race: a rehash that runs twice loses entries
		// rather than faulting.
		MarkupRegistry.Clear();
		UITypeRegistry.Clear();
		RegisterEverything();
		let expectedElements = MarkupRegistry.ElementCount;
		let expectedTypes = UITypeRegistry.Count;
		Test.Assert(expectedElements > 0, "the built-in vocabulary registered at all");
		Test.Assert(expectedTypes > 0, "the built-in types registered at all");

		for (int round < cRounds)
		{
			MarkupRegistry.Clear();
			UITypeRegistry.Clear();
			RaceOneRound();

			Test.Assert(MarkupRegistry.ElementCount == expectedElements,
				scope $"round {round}: {MarkupRegistry.ElementCount} elements, expected {expectedElements}");
			Test.Assert(UITypeRegistry.Count == expectedTypes,
				scope $"round {round}: {UITypeRegistry.Count} types, expected {expectedTypes}");
		}

		// And the tables still ANSWER, which a half built map need not.
		let flex = MarkupRegistry.CreateView("Flex");
		Test.Assert(flex != null, "the markup vocabulary survived the race");
		flex.ReleaseRef();
		Test.Assert(UITypeRegistry.Resolve("Flex") != null, "the type table survived the race");
		Test.Assert(DrawableFactoryRegistry.Get("color") != null,
			"the drawable factories survived the race");
	}

	/// Every worker registers at once.
	///
	/// The GATE is the whole point. Started without one, each thread finishes the registration
	/// before the next is even created, the threads never overlap, and the test passes against
	/// the broken code it exists to catch.
	private static void RaceOneRound()
	{
		Volatile.Write(ref sGate, false);
		Volatile.Write(ref sWaiting, 0);

		let threads = scope List<Thread>();
		for (int t < cThreads)
		{
			let thread = new Thread(new () =>
				{
					Interlocked.Increment(ref sWaiting);
					while (!Volatile.Read(ref sGate))
						Thread.SpinWait(1);

					RegisterEverything();
				});
			threads.Add(thread);
			thread.Start(false);
		}

		while (Volatile.Read(ref sWaiting) < cThreads)
			Thread.SpinWait(1);
		Volatile.Write(ref sGate, true);

		for (let thread in threads)
		{
			thread.Join();
			delete thread;
		}
	}

	/// Exactly what an asset builder does: the markup vocabulary, the type table the style
	/// sheet parser resolves selectors through, and the drawable factories.
	private static void RegisterEverything()
	{
		MarkupLoader.Initialize();
		UITypeRegistry.RegisterBuiltins();
		DrawableFactoryRegistry.RegisterBuiltins();
	}
}
