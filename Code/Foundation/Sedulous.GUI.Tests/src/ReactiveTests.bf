using System;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The reactive layer: properties that record their readers, computed values that recompute
/// lazily, and effects that rerun when what they read changes, batched on a scheduler; no manual
/// subscriptions.
class ReactiveTests
{
	[Test]
	public static void AnEffectRerunsWhenAPropertyItReadChangesAndNotOtherwise()
	{
		let score = scope Property<int>(1);
		let other = scope Property<int>(0);
		int seen = 0;
		let effect = scope Effect(new [&]() => { seen = score.Get(); });
		Test.Assert(seen == 1);
		Test.Assert(effect.RunCount == 1);
		score.Set(5);
		Test.Assert(seen == 5);
		Test.Assert(effect.RunCount == 2);
		score.Set(5); // the same value: nothing to do
		other.Set(3); // never read
		Test.Assert(effect.RunCount == 2);
	}

	[Test]
	public static void DependenciesAreFoundAgainOnEveryRun()
	{
		let useA = scope Property<bool>(true);
		let a = scope Property<int>(1);
		let b = scope Property<int>(2);
		int seen = 0;
		let effect = scope Effect(new [&]() => { seen = useA.Get() ? a.Get() : b.Get(); });
		Test.Assert(seen == 1);
		b.Set(20); // not read on this branch
		Test.Assert(effect.RunCount == 1);
		useA.Set(false);
		Test.Assert(seen == 20);
		a.Set(10); // no longer read
		Test.Assert(effect.RunCount == 2);
		b.Set(30);
		Test.Assert(seen == 30);
	}

	[Test]
	public static void AComputedValueRecomputesLazilyOncePerChange()
	{
		let price = scope Property<int>(3);
		let count = scope Property<int>(2);
		int evaluations = 0;
		let total = scope Computed<int>(new [&]() =>
			{
				evaluations++;
				return price.Get() * count.Get();
			});
		Test.Assert(evaluations == 0); // nothing read it yet
		Test.Assert(total.Get() == 6);
		Test.Assert(total.Get() == 6);
		Test.Assert(evaluations == 1);
		price.Set(4);
		count.Set(3);
		Test.Assert(total.IsStale);
		Test.Assert(evaluations == 1); // not until read
		Test.Assert(total.Get() == 12);
		Test.Assert(evaluations == 2);
		// An effect reading the computed reruns through it.
		int shown = 0;
		let effect = scope Effect(new [&]() => { shown = total.Get(); });
		count.Set(1);
		Test.Assert(shown == 4);
		Test.Assert(effect.RunCount == 2);
	}

	[Test]
	public static void ASchedulerBatchesChangesIntoOneRunPerEffect()
	{
		let scheduler = scope EffectScheduler();
		let a = scope Property<int>(0);
		let b = scope Property<int>(0);
		int runs = 0;
		let effect = scope Effect(new [&]() => { a.Get(); b.Get(); runs++; }, new [&]() => scheduler);
		Test.Assert(runs == 1); // the first run is at creation
		a.Set(1);
		b.Set(2);
		a.Set(3);
		Test.Assert(runs == 1);
		Test.Assert(scheduler.HasPending);
		Test.Assert(effect.IsQueued);
		Test.Assert(scheduler.Flush() == 1);
		Test.Assert(runs == 2);
		Test.Assert(!scheduler.HasPending);
	}

	[Test]
	public static void AnEffectDestroyedWhileQueuedIsNotRunAndTeardownUnlinksBothWays()
	{
		let scheduler = scope EffectScheduler();
		let a = scope Property<int>(0);
		{
			let effect = new Effect(new [&]() => { a.Get(); }, new [&]() => scheduler);
			Test.Assert(a.Changed.ObserverCount == 1);
			a.Set(1);
			Test.Assert(scheduler.HasPending);
			delete effect;
		}
		Test.Assert(!scheduler.HasPending);
		Test.Assert(a.Changed.ObserverCount == 0);
		Test.Assert(scheduler.Flush() == 0);

		// A source destroyed first leaves the effect with no dangling source.
		var source = new Property<int>(7);
		int seen = 0;
		let effect = scope Effect(new [&]() => { seen = (source != null) ? source.Get() : -1; });
		Test.Assert(effect.SourceCount == 1);
		DeleteAndNullify!(source);
		Test.Assert(effect.SourceCount == 0);
	}

	[Test]
	public static void AnEffectThatKeepsChangingWhatItReadsIsCutOff()
	{
		let scheduler = scope EffectScheduler();
		let a = scope Property<int>(0);
		let effect = scope Effect(new [&]() => { a.Set(a.Get() + 1); }, new [&]() => scheduler);
		scheduler.Flush();
		Test.Assert(effect.RunCount <= 18); // a few rounds, not forever
	}

	[Test]
	public static void AnUntrackedReadRecordsNothing()
	{
		let a = scope Property<int>(1);
		int runs = 0;
		let effect = scope Effect(new [&]() => { Observer.Untracked<int>(scope [&]() => a.Get()); runs++; });
		a.Set(2);
		Test.Assert(runs == 1);
		Test.Assert(effect.SourceCount == 0);
	}

	/// No scheduler: the effect would otherwise run again inside its own run, recursing.
	[Test]
	public static void AnEffectThatChangesWhatItReadRerunsAfterItselfNeverInsideItself()
	{
		let a = scope Property<int>(0);
		int depth = 0;
		int deepest = 0;
		let settles = scope Effect(new [&]() =>
			{
				depth++;
				deepest = Math.Max(deepest, depth);
				if (a.Get() < 3)
					a.Set(a.Peek() + 1);
				depth--;
			});
		Test.Assert(a.Peek() == 3);
		Test.Assert(deepest == 1);
		Test.Assert(settles.RunCount == 4); // 0, 1, 2, 3

		// One that never settles is cut off, still flat.
		let b = scope Property<int>(0);
		deepest = 0;
		let runaway = scope Effect(new [&]() =>
			{
				depth++;
				deepest = Math.Max(deepest, depth);
				b.Set(b.Get() + 1);
				depth--;
			});
		Test.Assert(deepest == 1);
		Test.Assert(runaway.RunCount <= 16);
	}

	/// Text has its own property: it owns its string and a read is a view of it.
	[Test]
	public static void AStringPropertyTellsItsReadersOfANewValueOnly()
	{
		let label = scope StringProperty("Save");
		let shown = scope String();
		let effect = scope Effect(new [&]() => { shown.Set(label.Get()); });
		Test.Assert(shown == "Save");
		Test.Assert(!label.Set("Save"));
		Test.Assert(effect.RunCount == 1);
		Test.Assert(label.Set("Save as"));
		Test.Assert(shown == "Save as");
		Test.Assert(effect.RunCount == 2);
	}
}
