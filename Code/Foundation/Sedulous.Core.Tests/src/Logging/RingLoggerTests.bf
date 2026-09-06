using System;
using Sedulous.Core.Logging;

namespace Sedulous.Core.Tests;

/// Retained messages, for tools and in-app consoles. Raptor's equivalent case is
/// "log: RingLogSink keeps the most recent records".
class RingLoggerTests
{
	[Test]
	public static void KeepsTheMostRecentRecords()
	{
		let ring = scope RingLogger(3, .Trace);
		Test.Assert(ring.Count == 0);

		ILogger log = ring;
		for (int i < 5)
			log.LogInformation("m{}", i);

		// Capacity three, so the last three survive.
		Test.Assert(ring.Count == 3);
		Test.Assert(ring.GetMessage(0, .. scope String()).Contains("m2"));
		Test.Assert(ring.GetMessage(1, .. scope String()).Contains("m3"));
		Test.Assert(ring.GetMessage(2, .. scope String()).Contains("m4"));
		Test.Assert(ring.GetLevel(0) == .Information);
	}

	/// Index zero is the oldest, which only shows up once the ring has wrapped: before
	/// that, head is still zero and any indexing scheme agrees.
	[Test]
	public static void IndexZeroIsTheOldestAfterWrapping()
	{
		let ring = scope RingLogger(3, .Trace);
		ILogger log = ring;

		log.LogInformation("a");
		log.LogInformation("b");
		Test.Assert(ring.GetMessage(0, .. scope String()).Contains("a"));

		log.LogInformation("c");
		log.LogInformation("d");   // wraps, evicting "a"
		Test.Assert(ring.GetMessage(0, .. scope String()).Contains("b"));
		Test.Assert(ring.GetMessage(2, .. scope String()).Contains("d"));
	}

	[Test]
	public static void FiltersBeforeRetaining()
	{
		let ring = scope RingLogger(8, .Warning);
		ILogger log = ring;

		log.LogInformation("dropped");
		log.LogDebug("dropped");
		Test.Assert(ring.Count == 0);

		log.LogWarning("kept");
		Test.Assert(ring.Count == 1);
		Test.Assert(ring.GetLevel(0) == .Warning);
	}

	[Test]
	public static void ClearEmptiesIt()
	{
		let ring = scope RingLogger(3, .Trace);
		ILogger log = ring;
		log.LogInformation("a");
		log.LogInformation("b");
		Test.Assert(ring.Count == 2);

		ring.Clear();
		Test.Assert(ring.Count == 0);

		// And it still works afterwards, with the head reset.
		log.LogInformation("c");
		Test.Assert(ring.Count == 1);
		Test.Assert(ring.GetMessage(0, .. scope String()).Contains("c"));
	}

	/// A message longer than the record truncates rather than overflowing, and the
	/// result is still terminated so reading it back is safe.
	[Test]
	public static void LongMessagesTruncate()
	{
		let ring = scope RingLogger(2, .Trace);
		ILogger log = ring;

		let long = scope String();
		for (int i < LogRecord.MessageCapacity * 2)
			long.Append('x');
		log.LogInformation(long);

		Test.Assert(ring.Count == 1);
		Test.Assert(ring.GetMessage(0, .. scope String()).Length <= LogRecord.MessageCapacity);
		Test.Assert(ring.GetMessage(0, .. scope String()).Length > 0);
	}

	/// A capacity of zero or less would make the modulo divide by zero, so it clamps.
	[Test]
	public static void DegenerateCapacityIsClamped()
	{
		let ring = scope RingLogger(0, .Trace);
		ILogger log = ring;
		log.LogInformation("a");
		log.LogInformation("b");
		Test.Assert(ring.Count == 1);
		Test.Assert(ring.GetMessage(0, .. scope String()).Contains("b"));
	}
}
