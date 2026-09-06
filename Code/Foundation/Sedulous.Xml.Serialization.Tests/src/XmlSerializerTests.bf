using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Sedulous.Xml.Serialization.Tests;

class XmlSerializerTests
{
	/// Writes with one serializer, reads back with another over the same text. This is the
	/// shape every test here uses, because a text format is only useful if what it wrote
	/// is what it reads.
	private static void Reparse(XmlSerializer writer, XmlDocument outDocument)
	{
		let text = scope String();
		writer.GetOutput(text);
		Test.Assert(outDocument.Parse(text) == .Ok, scope $"could not reparse: {text}");
	}

	[Test]
	public static void ScalarsAndStringsRoundTrip()
	{
		var i = (int32)-42;
		var u = (uint64)0xFEEDFACE;
		var f = 1.5f;
		var b = true;
		let s = scope String("hello");

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			Test.Assert(writer.IsSelfDescribing, "typed tags and names describe the structure");
			writer.Key("i"); Serialize(writer, ref i);
			writer.Key("u"); Serialize(writer, ref u);
			writer.Key("f"); Serialize(writer, ref f);
			writer.Key("b"); Serialize(writer, ref b);
			writer.Key("s"); Serialize(writer, s);
			Test.Assert(writer.IsOk);
			Reparse(writer, document);
		}

		int32 i2 = 0;
		uint64 u2 = 0;
		float f2 = 0;
		bool b2 = false;
		let s2 = scope String();
		{
			let reader = scope XmlSerializer(document);
			reader.Key("i"); Serialize(reader, ref i2);
			reader.Key("u"); Serialize(reader, ref u2);
			reader.Key("f"); Serialize(reader, ref f2);
			reader.Key("b"); Serialize(reader, ref b2);
			reader.Key("s"); Serialize(reader, s2);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(i2 == -42);
		Test.Assert(u2 == 0xFEEDFACE);
		Test.Assert(f2 == 1.5f);
		Test.Assert(b2);
		Test.Assert(s2 == "hello");
	}

	/// The tag names the kind and the name attribute names the field, which is what makes
	/// the document mean something to a person reading it.
	[Test]
	public static void TheDocumentIsReadable()
	{
		var value = (int32)7;
		let writer = scope XmlSerializer();
		writer.Key("width");
		Serialize(writer, ref value);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		let text = scope String();
		writer.GetOutput(text, settings);
		Test.Assert(text == "<root><i32 name=\"width\">7</i32></root>", scope $"got '{text}'");
	}

	/// The digits actually written, asserted exactly.
	///
	/// The round trip below passes on a platform whose shortest-form formatting happens to
	/// be sufficient and fails on one where it is not, so it cannot be trusted on its own
	/// to catch a formatting change. This pins the text.
	[Test]
	public static void FloatsAreWrittenWithEnoughDigits()
	{
		var value = 1.0f / 3.0f;
		let writer = scope XmlSerializer();
		writer.Key("v");
		Serialize(writer, ref value);

		var settings = XmlWriteSettings.Default;
		settings.CompactMode = true;
		let text = scope String();
		writer.GetOutput(text, settings);

		Test.Assert(text == "<root><f32 name=\"v\">0.333333343</f32></root>", scope $"got '{text}'");
	}

	/// A float has to come back as the SAME value, not a near one, or a round trip
	/// silently degrades every time a document is loaded and saved.
	[Test]
	public static void FloatsRoundTripExactly()
	{
		let awkward = scope float[](0.1f, 1.0f / 3.0f, 3.4028235e38f, 1.1754944e-38f, -0.0f);

		for (let original in awkward)
		{
			var value = original;
			let document = scope:: XmlDocument();
			{
				let writer = scope:: XmlSerializer();
				writer.Key("v");
				Serialize(writer, ref value);
				Reparse(writer, document);
			}

			float readBack = 0;
			let reader = scope:: XmlSerializer(document);
			reader.Key("v");
			Serialize(reader, ref readBack);
			// Compared as BITS: two floats that differ in the last place print the same at
			// the default precision, which is exactly how this hid.
			var expected = original;
			Test.Assert(readBack == expected,
				scope $"0x{*(uint32*)&expected:X} came back as 0x{*(uint32*)&readBack:X}");
		}
	}

	/// The same for doubles, which need seventeen digits rather than nine.
	[Test]
	public static void DoublesRoundTripExactly()
	{
		let awkward = scope double[](0.1, 1.0 / 3.0, 1.7976931348623157e308, 2.2250738585072014e-308, -0.0);

		for (let original in awkward)
		{
			var value = original;
			let document = scope:: XmlDocument();
			{
				let writer = scope:: XmlSerializer();
				writer.Key("v");
				Serialize(writer, ref value);
				Reparse(writer, document);
			}

			double readBack = 0;
			let reader = scope:: XmlSerializer(document);
			reader.Key("v");
			Serialize(reader, ref readBack);
			var expected = original;
			Test.Assert(readBack == expected,
				scope $"0x{*(uint64*)&expected:X} came back as 0x{*(uint64*)&readBack:X}");
		}
	}

	[Test]
	public static void NestedObjectRoundTrip()
	{
		var position = Float3(1.0f, 2.0f, 3.0f);

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("position");
			Serialize(writer, ref position);
			Reparse(writer, document);
		}

		Float3 readBack = default;
		let reader = scope XmlSerializer(document);
		reader.Key("position");
		Serialize(reader, ref readBack);
		Test.Assert(reader.IsOk);
		Test.Assert(readBack == Float3(1.0f, 2.0f, 3.0f));
	}

	[Test]
	public static void ListRoundTrip()
	{
		let source = scope List<int32>()..Add(3)..Add(1)..Add(4)..Add(1)..Add(5);

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("values");
			SerializeList(writer, source);
			Reparse(writer, document);
		}

		// Pre-populated, to prove a read replaces rather than appends.
		let target = scope List<int32>()..Add(99);
		let reader = scope XmlSerializer(document);
		reader.Key("values");
		SerializeList(reader, target);
		Test.Assert(reader.IsOk);

		Test.Assert(target.Count == 5);
		for (int i < 5)
			Test.Assert(target[i] == source[i]);
	}

	[Test]
	public static void ArrayOfObjectsRoundTrip()
	{
		let source = scope List<Float3>()..Add(.(1, 2, 3))..Add(.(4, 5, 6));

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("points");
			SerializeList(writer, source);
			Reparse(writer, document);
		}

		let target = scope List<Float3>();
		let reader = scope XmlSerializer(document);
		reader.Key("points");
		SerializeList(reader, target);
		Test.Assert(reader.IsOk);

		Test.Assert(target.Count == 2);
		Test.Assert(target[0] == Float3(1, 2, 3));
		Test.Assert(target[1] == Float3(4, 5, 6));
	}

	/// A positional float array, where nothing is keyed and order is the only thing
	/// telling the elements apart.
	[Test]
	public static void MatrixRoundTrip()
	{
		var matrix = Float4x4.Identity();
		matrix.M[0][3] = 7.0f;
		matrix.M[3][1] = -2.5f;

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("transform");
			Serialize(writer, ref matrix);
			Reparse(writer, document);
		}

		Float4x4 readBack = default;
		let reader = scope XmlSerializer(document);
		reader.Key("transform");
		Serialize(reader, ref readBack);
		Test.Assert(reader.IsOk);

		for (int row < 4)
		{
			for (int column < 4)
				Test.Assert(readBack.M[row][column] == matrix.M[row][column], scope $"[{row}][{column}]");
		}
	}

	/// A field that is not there fails the payload rather than reading as a default: a
	/// missing value and a zero are not the same thing.
	[Test]
	public static void AMissingFieldIsReported()
	{
		var value = (int32)1;
		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("present");
			Serialize(writer, ref value);
			Reparse(writer, document);
		}

		int32 readBack = 0;
		let reader = scope XmlSerializer(document);
		reader.Key("absent");
		Serialize(reader, ref readBack);
		Test.Assert(!reader.IsOk);
		Test.Assert(reader.Status case .Err(.NotFound));
	}

	/// The reason lookup searches FORWARD from the cursor rather than from the first
	/// child: the SAME key can appear several times in one scope, and restarting the
	/// search each time would read every one of them as the first.
	///
	/// Flat, deliberately. Nested objects each get their own scope, so within one of them
	/// every key is unique and restarting is indistinguishable from resuming. Only a
	/// repeated key group in a single scope tells the two apart.
	[Test]
	public static void RepeatedKeysInOneScopeStayDistinct()
	{
		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			for (int32 i < 3)
			{
				var value = i;
				writer.Key("item");
				Serialize(writer, ref value);
			}
			Reparse(writer, document);
		}

		let reader = scope XmlSerializer(document);
		for (int32 i < 3)
		{
			int32 value = -1;
			reader.Key("item");
			Serialize(reader, ref value);
			Test.Assert(value == i, scope $"read {value} where {i} was written");
		}
		Test.Assert(reader.IsOk);
	}

	/// The same thing through an array of keyed objects, which is the shape a manifest of
	/// records actually has.
	[Test]
	public static void RepeatedKeysAcrossArrayElementsStayDistinct()
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		names.Add(new String("first"));
		names.Add(new String("second"));
		names.Add(new String("third"));

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("items");
			uint32 count = (uint32)names.Count;
			writer.BeginArray(ref count);
			for (let name in names)
			{
				writer.BeginObject();
				writer.Key("name");
				Serialize(writer, name);
				var index = (int32)@name.Index;
				writer.Key("index");
				Serialize(writer, ref index);
				writer.EndObject();
			}
			writer.EndArray();
			Reparse(writer, document);
		}

		let reader = scope XmlSerializer(document);
		reader.Key("items");
		uint32 readCount = 0;
		reader.BeginArray(ref readCount);
		Test.Assert(readCount == 3);

		for (int32 i < (int32)readCount)
		{
			reader.BeginObject();
			let name = scope:: String();
			reader.Key("name");
			Serialize(reader, name);
			int32 index = -1;
			reader.Key("index");
			Serialize(reader, ref index);
			reader.EndObject();

			Test.Assert(name == names[i], scope $"element {i} read '{name}'");
			Test.Assert(index == i);
		}
		Test.Assert(reader.IsOk);
	}

	/// XML delimits itself, so framing is inherited as a no-op and changes not one byte.
	[Test]
	public static void FramedRegionsAreNoOps()
	{
		var value = (int32)5;

		let plain = scope String();
		{
			let writer = scope XmlSerializer();
			writer.Key("v");
			Serialize(writer, ref value);
			writer.GetOutput(plain);
		}

		let framed = scope String();
		{
			let writer = scope XmlSerializer();
			writer.BeginFramedRegion();
			writer.Key("v");
			Serialize(writer, ref value);
			writer.EndFramedRegion();
			writer.GetOutput(framed);
		}

		Test.Assert(plain == framed, "framing adds nothing to a self describing format");
	}

	/// A payload whose type this build cannot instantiate is captured whole and written
	/// back unchanged, so a document does not lose data by passing through a build that
	/// does not understand all of it.
	[Test]
	public static void RawRemainderCapturesAndReinjects()
	{
		// A document with a field this build knows and a payload it does not.
		let original = scope String();
		{
			let writer = scope XmlSerializer();
			writer.Key("known");
			var known = (int32)1;
			Serialize(writer, ref known);

			writer.Key("unknown");
			writer.BeginObject();
			writer.Key("a");
			var a = (int32)7;
			Serialize(writer, ref a);
			writer.Key("b");
			let b = scope String("payload");
			Serialize(writer, b);
			writer.EndObject();

			writer.GetOutput(original);
		}

		// Read the known field, then capture whatever is left without understanding it.
		let captured = scope List<uint8>();
		let source = scope XmlDocument();
		Test.Assert(source.Parse(original) == .Ok);
		{
			let reader = scope XmlSerializer(source);
			reader.Key("known");
			int32 known = 0;
			Serialize(reader, ref known);
			Test.Assert(known == 1);

			Test.Assert(reader.RawRemainder(captured));
			Test.Assert(!captured.IsEmpty);
			Test.Assert(reader.IsOk);
		}

		// Write it back out: the same field, then the payload verbatim.
		let rewritten = scope String();
		{
			let writer = scope XmlSerializer();
			writer.Key("known");
			var known = (int32)1;
			Serialize(writer, ref known);
			Test.Assert(writer.RawRemainder(captured));
			writer.GetOutput(rewritten);
		}

		Test.Assert(rewritten == original, scope $"got '{rewritten}'");

		// And a later build that DOES know the type reads it unchanged.
		let recovered = scope XmlDocument();
		Test.Assert(recovered.Parse(rewritten) == .Ok);
		let reader = scope XmlSerializer(recovered);
		reader.Key("known");
		int32 ignored = 0;
		Serialize(reader, ref ignored);
		reader.Key("unknown");
		reader.BeginObject();
		reader.Key("a");
		int32 a = 0;
		Serialize(reader, ref a);
		reader.EndObject();
		Test.Assert(a == 7, "the payload survived a build that could not read it");
	}

	[Test]
	public static void BlobsRoundTripAsHex()
	{
		uint8[4] payload = .(0x00, 0x0F, 0xA5, 0xFF);

		let document = scope XmlDocument();
		{
			let writer = scope XmlSerializer();
			writer.Key("data");
			writer.Blob(&payload[0], 4);

			var settings = XmlWriteSettings.Default;
			settings.CompactMode = true;
			let text = scope String();
			writer.GetOutput(text, settings);
			Test.Assert(text == "<root><blob name=\"data\">000fa5ff</blob></root>", scope $"got '{text}'");

			Reparse(writer, document);
		}

		uint8[4] readBack = default;
		let reader = scope XmlSerializer(document);
		reader.Key("data");
		reader.Blob(&readBack[0], 4);
		Test.Assert(reader.IsOk);
		for (int i < 4)
			Test.Assert(readBack[i] == payload[i]);
	}

	/// A blob whose text is the wrong length fails rather than filling part of the
	/// destination and leaving the rest as it was.
	[Test]
	public static void AWrongLengthBlobFails()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><blob name=\"data\">00ff</blob></root>") == .Ok);

		uint8[4] readBack = default;
		let reader = scope XmlSerializer(document);
		reader.Key("data");
		reader.Blob(&readBack[0], 4);
		Test.Assert(!reader.IsOk);
	}

	/// The format is meant to be edited by hand, so a value someone indented still reads.
	/// Anything past the number is still an error.
	[Test]
	public static void HandEditedWhitespaceIsTolerated()
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse("<root><i32 name=\"v\">  42  </i32></root>") == .Ok);

		int32 value = 0;
		let reader = scope XmlSerializer(document);
		reader.Key("v");
		Serialize(reader, ref value);
		Test.Assert(reader.IsOk);
		Test.Assert(value == 42);

		let garbage = scope XmlDocument();
		Test.Assert(garbage.Parse("<root><i32 name=\"v\">42abc</i32></root>") == .Ok);
		int32 ignored = 0;
		let strict = scope XmlSerializer(garbage);
		strict.Key("v");
		Serialize(strict, ref ignored);
		Test.Assert(!strict.IsOk, "trailing garbage is not a number");
	}
}
