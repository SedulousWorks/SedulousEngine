using System;
using Sedulous.Core.Logging;

namespace Sedulous.Core.Tests;

/// The composite. These cover the parts that only exist because it is a logger rather
/// than a sink list: each child keeps its own level and its own formatter.
class CompositeLoggerTests
{
	[Test]
	public static void FansOutToEveryChild()
	{
		let a = scope CapturingLogger(.Trace, "A");
		let b = scope CapturingLogger(.Trace, "B");

		let composite = scope CompositeLogger(.Trace);
		composite.Add(a);
		composite.Add(b);
		Test.Assert(composite.Count == 2);

		ILogger log = composite;
		log.LogInformation("hello {}", 1);

		Test.Assert(a.Count == 1);
		Test.Assert(b.Count == 1);
		Test.Assert(a.LastLine.Contains("hello 1"));
		Test.Assert(b.LastLine.Contains("hello 1"));
	}

	/// Each child applies its own filter, so a child can be quieter than the composite.
	/// This is the behaviour a sink list cannot express, because sinks have no level.
	[Test]
	public static void EachChildKeepsItsOwnLevel()
	{
		let chatty = scope CapturingLogger(.Trace, "Chatty");
		let quiet = scope CapturingLogger(.Error, "Quiet");

		let composite = scope CompositeLogger(.Trace);
		composite.Add(chatty);
		composite.Add(quiet);
		ILogger log = composite;

		log.LogInformation("routine");
		Test.Assert(chatty.Count == 1);
		Test.Assert(quiet.Count == 0);

		log.LogError("bad");
		Test.Assert(chatty.Count == 2);
		Test.Assert(quiet.Count == 1);
	}

	/// The composite's own level gates the whole fan-out, so a child cannot be louder
	/// than the composite even if its own level would allow it.
	[Test]
	public static void TheCompositeLevelGatesEverything()
	{
		let child = scope CapturingLogger(.Trace, "Child");
		let composite = scope CompositeLogger(.Error);
		composite.Add(child);
		ILogger log = composite;

		log.LogInformation("below the composite level");
		Test.Assert(child.Count == 0);

		log.LogCritical("above it");
		Test.Assert(child.Count == 1);
	}

	/// A filtered call at the composite level must not format either, or the composite
	/// would reintroduce the cost its children avoid.
	[Test]
	public static void AFilteredCompositeCallNeverFormats()
	{
		let child = scope CapturingLogger(.Trace);
		let composite = scope CompositeLogger(.Error);
		composite.Add(child);
		ILogger log = composite;

		FormatProbe.Reset();
		log.LogInformation("value {}", scope FormatProbe());
		Test.Assert(child.Count == 0);
		Test.Assert(FormatProbe.sRenderCount == 0);
	}

	[Test]
	public static void RemoveStopsDelivery()
	{
		let a = scope CapturingLogger(.Trace);
		let composite = scope CompositeLogger(.Trace);
		composite.Add(a);
		ILogger log = composite;

		log.LogError("first");
		Test.Assert(a.Count == 1);

		Test.Assert(composite.Remove(a));
		Test.Assert(composite.Count == 0);

		log.LogError("ignored");
		Test.Assert(a.Count == 1);

		// Removing something that is not there is not an error.
		Test.Assert(!composite.Remove(a));
	}

	[Test]
	public static void AnEmptyCompositeIsHarmless()
	{
		let composite = scope CompositeLogger(.Trace);
		ILogger log = composite;
		log.LogError("nowhere to go");
		Test.Assert(composite.Count == 0);
	}

	/// Adding null is ignored rather than storing a hole that would fault on dispatch.
	[Test]
	public static void AddingNullIsIgnored()
	{
		let composite = scope CompositeLogger(.Trace);
		composite.Add(null);
		Test.Assert(composite.Count == 0);
	}

	/// A composite can hold a composite, which is how a subsystem's own fan-out attaches
	/// to the application's without either knowing about the other.
	[Test]
	public static void CompositesNest()
	{
		let leaf = scope CapturingLogger(.Trace);
		let inner = scope CompositeLogger(.Trace);
		inner.Add(leaf);

		let outer = scope CompositeLogger(.Trace);
		outer.Add(inner);

		ILogger log = outer;
		log.LogWarning("through two levels");
		Test.Assert(leaf.Count == 1);
		Test.Assert(leaf.LastLine.Contains("through two levels"));
	}
}
