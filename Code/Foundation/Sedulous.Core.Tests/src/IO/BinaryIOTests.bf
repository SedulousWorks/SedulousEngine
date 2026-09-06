using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

class BinaryIOTests
{
	[Test]
	public static void ValuesAndStringsRoundTrip()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinaryWriter(stream);
			Test.Assert(writer.Write<int32>(-42));
			Test.Assert(writer.Write<uint64>(0xDEADBEEFCAFEUL));
			Test.Assert(writer.Write<float>(1.5f));
			Test.Assert(writer.Write<bool>(true));
			Test.Assert(writer.WriteString("hello"));
			Test.Assert(writer.WriteString(""));
			Test.Assert(writer.IsOk);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinaryReader(stream);

		int32 i = 0;
		uint64 u = 0;
		float f = 0;
		bool b = false;
		let text = scope String();
		let empty = scope String();

		Test.Assert(reader.Read(out i));
		Test.Assert(reader.Read(out u));
		Test.Assert(reader.Read(out f));
		Test.Assert(reader.Read(out b));
		Test.Assert(reader.ReadString(text));
		Test.Assert(reader.ReadString(empty));

		Test.Assert(i == -42);
		Test.Assert(u == 0xDEADBEEFCAFEUL);
		Test.Assert(f == 1.5f);
		Test.Assert(b);
		Test.Assert(text == "hello");
		Test.Assert(empty == "");
		Test.Assert(reader.IsOk);
	}

	/// The flag is sticky: once a transfer comes up short it stays not-ok, so a caller can
	/// read a whole record and test once at the end rather than at every field.
	[Test]
	public static void AShortReadSticks()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinaryWriter(stream);
			Test.Assert(writer.Write<int32>(7));
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinaryReader(stream);

		int32 first = 0;
		Test.Assert(reader.Read(out first));
		Test.Assert(first == 7);
		Test.Assert(reader.IsOk);

		// Nothing left, so this comes up short.
		int32 second = 0;
		Test.Assert(!reader.Read(out second));
		Test.Assert(!reader.IsOk);

		// And it stays not-ok even for a read that could otherwise have succeeded.
		Test.Assert(stream.Seek(0, .Begin) == 0);
		int32 third = 0;
		Test.Assert(!reader.Read(out third));
		Test.Assert(!reader.IsOk, "the flag never recovers");
	}

	/// The writer's flag sticks the same way. A stream that refuses the write is the only
	/// way to provoke it, since a MemoryStream always accepts.
	[Test]
	public static void AShortWriteSticks()
	{
		let stream = scope RefusingStream();
		let writer = scope BinaryWriter(stream);

		Test.Assert(!writer.Write<int32>(1));
		Test.Assert(!writer.IsOk);
		Test.Assert(!writer.Write<int32>(2), "still not ok on the next call");
	}

	/// A zero length transfer is not a failure, and must not set the flag.
	[Test]
	public static void EmptyTransfersDoNotSetTheFlag()
	{
		let stream = scope MemoryStream();
		let writer = scope BinaryWriter(stream);
		Test.Assert(writer.WriteBytes(Span<uint8>()));
		Test.Assert(writer.IsOk);

		let reader = scope BinaryReader(stream);
		Test.Assert(reader.ReadBytes(Span<uint8>()));
		Test.Assert(reader.IsOk);
	}

	/// A truncated string must not leave half of it in the output: the count says five
	/// characters and only two follow.
	[Test]
	public static void ATruncatedStringLeavesTheOutputEmpty()
	{
		let stream = scope MemoryStream();
		Test.Assert(stream.WriteValue<uint32>(5));
		Test.Assert(stream.WriteValue<uint8>((uint8)'h'));
		Test.Assert(stream.WriteValue<uint8>((uint8)'i'));
		Test.Assert(stream.Seek(0, .Begin) == 0);

		let reader = scope BinaryReader(stream);
		let text = scope String("stale contents");
		Test.Assert(!reader.ReadString(text));
		Test.Assert(text.IsEmpty, "a failed read leaves nothing behind, not a fragment");
		Test.Assert(!reader.IsOk);
	}

	/// A count longer than the stream is corrupt, and must be doubted before it is
	/// allocated. A large enough garbage count would otherwise take the process down before
	/// the short read was ever reported.
	[Test]
	public static void AnImpossibleStringLengthIsRefusedBeforeAllocating()
	{
		let stream = scope MemoryStream();
		Test.Assert(stream.WriteValue<uint32>(0xFFFFFFF0));
		Test.Assert(stream.WriteValue<uint8>((uint8)'x'));
		Test.Assert(stream.Seek(0, .Begin) == 0);

		let reader = scope BinaryReader(stream);
		let text = scope String("stale contents");
		Test.Assert(!reader.ReadString(text));
		Test.Assert(!reader.IsOk);
		Test.Assert(text.IsEmpty);
	}

	/// Both sides agree on the string encoding: a uint32 count of bytes, then the bytes.
	/// Anything else and a file written by one would not be readable by the other.
	[Test]
	public static void StringsAreLengthPrefixedInBytes()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinaryWriter(stream);
			Test.Assert(writer.WriteString("abc"));
		}

		Test.Assert(stream.Size() == 4 + 3);
		Test.Assert(stream.Seek(0, .Begin) == 0);

		uint32 length = 0;
		Test.Assert(stream.ReadValue(out length));
		Test.Assert(length == 3);
	}

}
