using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

/// The buffer is deliberately smaller than the payload in every case, so each one crosses
/// the boundary several times. A buffer bigger than the data would never exercise a refill
/// or a flush.
class BufferedStreamTests
{
	[Test]
	public static void WriteThenReadRoundTrip()
	{
		let backing = scope MemoryStream();
		{
			let buffered = scope BufferedStream(backing, 8);
			for (int32 i < 20)
				Test.Assert(buffered.WriteValue<int32>(i + 100));
		}
		// The buffered stream flushed what it held when it went out of scope.
		Test.Assert(backing.Size() == 20 * 4);

		Test.Assert(backing.Seek(0, .Begin) == 0);
		for (int32 i < 20)
		{
			int32 value = -1;
			Test.Assert(backing.ReadValue(out value));
			Test.Assert(value == i + 100);
		}
	}

	[Test]
	public static void ReadRefillsAcrossTheBufferBoundary()
	{
		let backing = scope MemoryStream();
		for (int32 i < 100)
			Test.Assert(backing.WriteValue<uint8>((uint8)i));
		Test.Assert(backing.Seek(0, .Begin) == 0);

		let buffered = scope BufferedStream(backing, 7);
		for (int32 i < 100)
		{
			uint8 value = 0;
			Test.Assert(buffered.ReadValue(out value));
			Test.Assert(value == (uint8)i, scope $"byte {i}");
		}

		// Past the end it stops rather than looping or repeating the last buffer.
		uint8 extra = 0;
		Test.Assert(!buffered.ReadValue(out extra));
	}

	[Test]
	public static void WriteThenSeekThenReadOnOneStream()
	{
		let backing = scope MemoryStream();
		let buffered = scope BufferedStream(backing, 16);

		for (int32 i < 20)
			Test.Assert(buffered.WriteValue<int32>(i + 100));

		// Seeking flushes what is pending, so the read sees all of it.
		Test.Assert(buffered.Seek(0, .Begin) == 0);
		for (int32 i < 20)
		{
			int32 value = -1;
			Test.Assert(buffered.ReadValue(out value));
			Test.Assert(value == i + 100, scope $"value {i}");
		}
	}

	/// Switching from reading to writing has to hand back the bytes that were prefetched
	/// but never read. Without that the write lands wherever the prefetch happened to
	/// stop, which is up to the buffer size away from where the caller believes it is.
	[Test]
	public static void SwitchingFromReadToWriteRewindsTheUnreadPrefetch()
	{
		let backing = scope MemoryStream();
		for (int32 i < 40)
			Test.Assert(backing.WriteValue<uint8>((uint8)i));
		Test.Assert(backing.Seek(0, .Begin) == 0);

		{
			let buffered = scope BufferedStream(backing, 16);

			// Read four bytes. The buffer prefetched sixteen.
			for (int32 i < 4)
			{
				uint8 value = 0;
				Test.Assert(buffered.ReadValue(out value));
				Test.Assert(value == (uint8)i);
			}
			Test.Assert(buffered.Tell() == 4, "Tell must discount the unread prefetch");

			// Writing here must land at offset 4, not at 16.
			Test.Assert(buffered.WriteValue<uint8>(0xFF));
		}

		Test.Assert(backing.Seek(0, .Begin) == 0);
		uint8[40] bytes = default;
		Test.Assert(backing.Read(.(&bytes[0], 40)) == 40);
		Test.Assert(bytes[3] == 3);
		Test.Assert(bytes[4] == 0xFF, "the write landed where the reader had got to");
		Test.Assert(bytes[5] == 5, "and clobbered exactly one byte");
	}

	/// Tell has to answer for the caller's position, not the underlying stream's, in both
	/// directions: ahead of it while writing, behind it while reading.
	[Test]
	public static void TellAccountsForTheBufferInBothDirections()
	{
		let backing = scope MemoryStream();
		for (int32 i < 64)
			Test.Assert(backing.WriteValue<uint8>((uint8)i));
		Test.Assert(backing.Seek(0, .Begin) == 0);

		let buffered = scope BufferedStream(backing, 16);
		Test.Assert(buffered.Tell() == 0);

		uint8 value = 0;
		Test.Assert(buffered.ReadValue(out value));
		Test.Assert(buffered.Tell() == 1, "one byte read, fifteen still buffered");
		Test.Assert(backing.Tell() == 16, "the underlying stream really is ahead");

		Test.Assert(buffered.Seek(0, .Begin) == 0);
		Test.Assert(buffered.WriteValue<uint8>(1));
		Test.Assert(buffered.WriteValue<uint8>(2));
		Test.Assert(buffered.Tell() == 2, "two bytes pending, none written down yet");
		Test.Assert(backing.Tell() == 0, "the underlying stream has not moved");

		buffered.Flush();
		Test.Assert(buffered.Tell() == 2);
	}

	/// A write longer than the buffer has to spill through it rather than overrun it.
	[Test]
	public static void WritesLongerThanTheBufferSpillThrough()
	{
		let backing = scope MemoryStream();
		uint8[100] payload = default;
		for (int i < 100)
			payload[i] = (uint8)(i * 3);

		{
			let buffered = scope BufferedStream(backing, 8);
			Test.Assert(buffered.Write(.(&payload[0], 100)) == 100);
		}

		Test.Assert(backing.Size() == 100);
		Test.Assert(backing.Seek(0, .Begin) == 0);
		uint8[100] readBack = default;
		Test.Assert(backing.Read(.(&readBack[0], 100)) == 100);
		for (int i < 100)
			Test.Assert(readBack[i] == (uint8)(i * 3), scope $"byte {i}");
	}

	/// A buffer size of zero would divide the write loop by nothing to copy into, so it is
	/// clamped rather than trusted.
	[Test]
	public static void AZeroBufferSizeIsClamped()
	{
		let backing = scope MemoryStream();
		{
			let buffered = scope BufferedStream(backing, 0);
			for (int32 i < 10)
				Test.Assert(buffered.WriteValue<uint8>((uint8)i));
		}
		Test.Assert(backing.Size() == 10);
	}

	[Test]
	public static void ValidityFollowsTheUnderlyingStream()
	{
		let backing = scope MemoryStream();
		let buffered = scope BufferedStream(backing, 8);
		Test.Assert(buffered.IsValid);
		Test.Assert(buffered.Size() == backing.Size());
	}
}
