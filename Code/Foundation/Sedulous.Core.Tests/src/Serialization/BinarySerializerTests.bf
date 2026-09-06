using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

class BinarySerializerTests
{
	[Test]
	public static void ScalarsRoundTrip()
	{
		let stream = scope MemoryStream();

		var i = (int32)-7;
		var u = (uint64)0xFEEDFACEUL;
		var f = 0.25f;
		var b = true;
		{
			let writer = scope BinarySerializer(stream, .Write);
			Test.Assert(writer.Mode == .Write);
			Test.Assert(writer.IsWriting && !writer.IsReading);
			Serialize(writer, ref i);
			Serialize(writer, ref u);
			Serialize(writer, ref f);
			Serialize(writer, ref b);
			Test.Assert(writer.IsOk);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		int32 i2 = 0;
		uint64 u2 = 0;
		float f2 = 0;
		bool b2 = false;
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, ref i2);
			Serialize(reader, ref u2);
			Serialize(reader, ref f2);
			Serialize(reader, ref b2);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(i2 == -7);
		Test.Assert(u2 == 0xFEEDFACEUL);
		Test.Assert(f2 == 0.25f);
		Test.Assert(b2);
	}

	/// int is pointer sized, so it is stored at a fixed width. A file written by one target
	/// has to be readable by another, which a native-width store would break.
	[Test]
	public static void PointerSizedIntegersAreStoredAtAFixedWidth()
	{
		let stream = scope MemoryStream();
		var value = (int)-1234567890123;
		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, ref value);
		}
		Test.Assert(stream.Size() == 8, "int is stored as eight bytes whatever the target is");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		int read = 0;
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, ref read);
		}
		Test.Assert(read == -1234567890123);
	}

	/// Names carry nothing in a positional format, so keying a field must not change a
	/// single byte. If it did, a body could not key uniformly for both backends.
	[Test]
	public static void KeysCostNothingInBinary()
	{
		let bare = scope MemoryStream();
		var a = (int32)5;
		{
			let writer = scope BinarySerializer(bare, .Write);
			Serialize(writer, ref a);
		}

		let keyed = scope MemoryStream();
		var b = (int32)5;
		{
			let writer = scope BinarySerializer(keyed, .Write);
			writer.BeginObject();
			writer.Key("value");
			Serialize(writer, ref b);
			writer.EndObject();
		}

		Test.Assert(bare.Size() == keyed.Size());
		Test.Assert(bare.Bytes[0] == keyed.Bytes[0]);
	}

	[Test]
	public static void TextAndBlobRoundTrip()
	{
		let stream = scope MemoryStream();
		uint8[4] payload = .(9, 8, 7, 6);
		{
			let writer = scope BinarySerializer(stream, .Write);
			writer.Text(scope String("hello"));
			writer.Blob(&payload[0], 4);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let text = scope String();
		uint8[4] readBack = default;
		{
			let reader = scope BinarySerializer(stream, .Read);
			reader.Text(text);
			reader.Blob(&readBack[0], 4);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(text == "hello");
		for (int i < 4)
			Test.Assert(readBack[i] == payload[i]);
	}

	[Test]
	public static void ListsRoundTrip()
	{
		let stream = scope MemoryStream();
		let source = scope List<int32>()..Add(3)..Add(1)..Add(4)..Add(1)..Add(5);
		{
			let writer = scope BinarySerializer(stream, .Write);
			SerializeList(writer, source);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		// Pre-populated, to prove reading replaces rather than appends.
		let target = scope List<int32>()..Add(99);
		{
			let reader = scope BinarySerializer(stream, .Read);
			SerializeList(reader, target);
		}

		Test.Assert(target.Count == 5);
		for (int i < 5)
			Test.Assert(target[i] == source[i]);
	}

	/// A short read sets the status and it stays set, so a caller checks once at the end
	/// rather than after every field.
	[Test]
	public static void AShortReadFailsTheSerializerAndSticks()
	{
		let stream = scope MemoryStream();
		var value = (int32)1;
		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, ref value);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinarySerializer(stream, .Read);
		int32 first = 0;
		Serialize(reader, ref first);
		Test.Assert(reader.IsOk);

		int32 second = 0;
		Serialize(reader, ref second);
		Test.Assert(!reader.IsOk, "nothing was left to read");
		Test.Assert(reader.Status case .Err(.Internal));

		// Rewinding does not clear it: the payload is already known to be bad.
		Test.Assert(stream.Seek(0, .Begin) == 0);
		int32 third = 0;
		Serialize(reader, ref third);
		Test.Assert(!reader.IsOk);
	}

	/// FailPayload is for the invariant a positional format cannot express, and it lands in
	/// the same status a short read does.
	[Test]
	public static void FailPayloadIsReportedLikeAnyOtherFailure()
	{
		let stream = scope MemoryStream();
		let reader = scope BinarySerializer(stream, .Read);
		Test.Assert(reader.IsPayloadOk);

		reader.FailPayload(.InvalidArgument);
		Test.Assert(!reader.IsPayloadOk);
		Test.Assert(reader.Status case .Err(.InvalidArgument));

		// First failure wins; a later one does not overwrite the cause.
		reader.FailPayload(.OutOfRange);
		Test.Assert(reader.Status case .Err(.InvalidArgument));
	}

	[Test]
	public static void BinaryIsNotSelfDescribing()
	{
		let stream = scope MemoryStream();
		let writer = scope BinarySerializer(stream, .Write);
		Test.Assert(!writer.IsSelfDescribing, "a positional format needs explicit framing");
	}
}
