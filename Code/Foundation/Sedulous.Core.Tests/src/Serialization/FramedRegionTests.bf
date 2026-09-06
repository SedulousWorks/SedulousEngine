using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// Framed regions are what let a build read a file containing a payload whose type it does
/// not have: the region is length prefixed, so it can be skipped or captured whole without
/// understanding a byte of it.
class FramedRegionTests
{
	[Test]
	public static void AFramedRegionIsLengthPrefixed()
	{
		let stream = scope MemoryStream();
		var inner = (int32)0x11223344;
		{
			let writer = scope BinarySerializer(stream, .Write);
			writer.BeginFramedRegion();
			Serialize(writer, ref inner);
			writer.EndFramedRegion();
		}

		// A uint32 length, then the four bytes it frames.
		Test.Assert(stream.Size() == 4 + 4);
		Test.Assert(stream.Seek(0, .Begin) == 0);
		uint32 length = 0;
		Test.Assert(stream.ReadValue(out length));
		Test.Assert(length == 4);
	}

	[Test]
	public static void AFramedRegionRoundTrips()
	{
		let stream = scope MemoryStream();
		var before = (int32)1;
		var inside = (int32)2;
		var after = (int32)3;
		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, ref before);
			writer.BeginFramedRegion();
			Serialize(writer, ref inside);
			writer.EndFramedRegion();
			Serialize(writer, ref after);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		int32 a = 0, b = 0, c = 0;
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, ref a);
			reader.BeginFramedRegion();
			Serialize(reader, ref b);
			reader.EndFramedRegion();
			Serialize(reader, ref c);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(a == 1);
		Test.Assert(b == 2);
		Test.Assert(c == 3);
	}

	/// The point of the frame: a reader that does not consume the region still lands on
	/// what follows it. Without the length prefix it would resume mid-payload.
	[Test]
	public static void AnUnreadRegionIsSkippedWhole()
	{
		let stream = scope MemoryStream();
		var after = (int32)0x5A5A5A5A;
		{
			let writer = scope BinarySerializer(stream, .Write);
			writer.BeginFramedRegion();
			for (int32 i < 20)
			{
				var value = i;
				Serialize(writer, ref value);
			}
			writer.EndFramedRegion();
			Serialize(writer, ref after);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		int32 read = 0;
		{
			let reader = scope BinarySerializer(stream, .Read);
			reader.BeginFramedRegion();
			// Not one byte of the region is read.
			reader.EndFramedRegion();
			Serialize(reader, ref read);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(read == 0x5A5A5A5A, "the reader landed after the region, not inside it");
	}

	/// Capturing an unknown region and writing it back must reproduce it byte for byte, or
	/// a build that does know the type would read something different than was stored.
	[Test]
	public static void RawRemainderRoundTripsAnUnknownRegionVerbatim()
	{
		let original = scope MemoryStream();
		var tail = (int32)77;
		{
			let writer = scope BinarySerializer(original, .Write);
			writer.BeginFramedRegion();
			for (int32 i < 8)
			{
				var value = i * 3;
				Serialize(writer, ref value);
			}
			writer.EndFramedRegion();
			Serialize(writer, ref tail);
		}

		// A build that cannot instantiate the type captures the region instead.
		let captured = scope List<uint8>();
		Test.Assert(original.Seek(0, .Begin) == 0);
		int32 readTail = 0;
		{
			let reader = scope BinarySerializer(original, .Read);
			reader.BeginFramedRegion();
			Test.Assert(reader.RawRemainder(captured));
			reader.EndFramedRegion();
			Serialize(reader, ref readTail);
		}
		Test.Assert(captured.Count == 8 * 4);
		Test.Assert(readTail == 77);

		// Writing it back out reproduces the original bytes exactly.
		let rewritten = scope MemoryStream();
		{
			let writer = scope BinarySerializer(rewritten, .Write);
			writer.BeginFramedRegion();
			Test.Assert(writer.RawRemainder(captured));
			writer.EndFramedRegion();
			Serialize(writer, ref tail);
		}

		Test.Assert(rewritten.Size() == original.Size());
		let a = original.Bytes;
		let b = rewritten.Bytes;
		for (int i < a.Length)
			Test.Assert(a[i] == b[i], scope $"byte {i}");
	}

	/// Binary needs an active frame to know where an unknown region ends, so outside one it
	/// says so rather than guessing.
	[Test]
	public static void RawRemainderNeedsAnActiveFrame()
	{
		let stream = scope MemoryStream();
		let reader = scope BinarySerializer(stream, .Read);
		let blob = scope List<uint8>();
		Test.Assert(!reader.RawRemainder(blob));
	}

	[Test]
	public static void FramedRegionsNest()
	{
		let stream = scope MemoryStream();
		var inner = (int32)42;
		var outerTail = (int32)7;
		{
			let writer = scope BinarySerializer(stream, .Write);
			writer.BeginFramedRegion();
			writer.BeginFramedRegion();
			Serialize(writer, ref inner);
			writer.EndFramedRegion();
			Serialize(writer, ref outerTail);
			writer.EndFramedRegion();
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		int32 a = 0, b = 0;
		{
			let reader = scope BinarySerializer(stream, .Read);
			reader.BeginFramedRegion();
			reader.BeginFramedRegion();
			Serialize(reader, ref a);
			reader.EndFramedRegion();
			Serialize(reader, ref b);
			reader.EndFramedRegion();
			Test.Assert(reader.IsOk);
		}
		Test.Assert(a == 42);
		Test.Assert(b == 7);
	}
}
