using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A guid moves as whatever primitive the backend prefers, rather than as a decomposed
/// struct. It is one value everywhere it is used, and it should read as one.
class GuidSerializationTests
{
	private static readonly Guid cGuid = Guid.Parse("2f1b8c74-9a3d-4e51-b6f0-1c2d3e4f5a6b").Value;

	[Test]
	public static void BinaryStoresSixteenRawBytes()
	{
		let stream = scope MemoryStream();
		var value = cGuid;
		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, ref value);
		}
		Test.Assert(stream.Size() == 16, "not the thirty six character string");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		Guid read = default;
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, ref read);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(read == cGuid);
	}

	/// The default, which a text backend inherits: readable, and copyable as one value.
	[Test]
	public static void TheDefaultStoresTheCanonicalString()
	{
		let stream = scope MemoryStream();
		var value = cGuid;
		{
			let writer = scope StringGuidSerializer(stream, .Write);
			Serialize(writer, ref value);
		}
		// A uint32 length prefix and thirty six characters.
		Test.Assert(stream.Size() == 4 + 36);

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let text = scope String();
		{
			let reader = scope BinaryReader(stream);
			Test.Assert(reader.ReadString(text));
		}
		Test.Assert(text == "2f1b8c74-9a3d-4e51-b6f0-1c2d3e4f5a6b");
	}

	[Test]
	public static void TheDefaultRoundTrips()
	{
		let stream = scope MemoryStream();
		var value = cGuid;
		{
			let writer = scope StringGuidSerializer(stream, .Write);
			Serialize(writer, ref value);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		Guid read = default;
		{
			let reader = scope StringGuidSerializer(stream, .Read);
			Serialize(reader, ref read);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(read == cGuid);
	}

	/// A guid that does not parse is corrupt data, not an empty guid. The value is left
	/// alone rather than zeroed, so a caller that ignores the status does not silently get
	/// Guid.Empty where a real one was meant to be.
	[Test]
	public static void AMalformedGuidFailsRatherThanReadingAsEmpty()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinaryWriter(stream);
			Test.Assert(writer.WriteString("not-a-guid"));
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		var value = cGuid;
		{
			let reader = scope StringGuidSerializer(stream, .Read);
			Serialize(reader, ref value);
			Test.Assert(!reader.IsOk);
			Test.Assert(reader.Status case .Err(.InvalidArgument));
		}
		Test.Assert(value == cGuid, "the value was left alone, not zeroed");
	}

	[Test]
	public static void AnEmptyGuidRoundTrips()
	{
		let stream = scope MemoryStream();
		var value = Guid.Empty;
		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, ref value);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		var read = cGuid;
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, ref read);
		}
		Test.Assert(read == Guid.Empty);
	}
}
