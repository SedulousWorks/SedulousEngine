using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// The comptime walker. Raptor has no equivalent: a type there is described by hand in
/// Serialize.cppm, or through the external RTTI module it has to be registered with.
class GeneratedSerializeTests
{
	private static void Fill(SerializableSample sample)
	{
		sample.Id = -42;
		sample.Weight = 1.5f;
		sample.Enabled = true;
		sample.Kind = .Beta;
		sample.Position = .(1.0f, 2.0f, 3.0f);
		sample.Name.Set("generated");
	}

	[Test]
	public static void AGeneratedBodyRoundTripsEveryField()
	{
		let stream = scope MemoryStream();
		let source = scope SerializableSample();
		Fill(source);

		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)source);
			Test.Assert(writer.IsOk);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope SerializableSample();
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, (ISerializable)target);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(target.Id == -42);
		Test.Assert(target.Weight == 1.5f);
		Test.Assert(target.Enabled);
		Test.Assert(target.Kind == .Beta);
		Test.Assert(target.Position == Float3(1.0f, 2.0f, 3.0f));
		Test.Assert(target.Name == "generated");
	}

	/// Applying the attribute is what makes the type serializable: nothing in the type
	/// says so, and the interface is added by the same pass that emits the body.
	[Test]
	public static void TheAttributeAddsTheInterface()
	{
		// The assignment is the assertion: it compiles only because the attribute added
		// the interface, since nothing in SerializableSample declares it.
		ISerializable asInterface = scope SerializableSample();
		Test.Assert(asInterface != null);
	}

	/// FIELD ORDER IS THE BINARY FORMAT. This reads the stream back by hand, in declaration
	/// order, so reordering the fields of SerializableSample fails here rather than
	/// silently changing what every stored file means.
	[Test]
	public static void FieldsAreWalkedInDeclarationOrder()
	{
		let stream = scope MemoryStream();
		let source = scope SerializableSample();
		Fill(source);
		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)source);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinaryReader(stream);

		int32 id = 0;
		float weight = 0;
		bool enabled = false;
		int16 kind = 0;
		float x = 0, y = 0, z = 0;
		let name = scope String();

		Test.Assert(reader.Read(out id));
		Test.Assert(reader.Read(out weight));
		Test.Assert(reader.Read(out enabled));
		Test.Assert(reader.Read(out kind));
		Test.Assert(reader.Read(out x));
		Test.Assert(reader.Read(out y));
		Test.Assert(reader.Read(out z));
		Test.Assert(reader.ReadString(name));

		Test.Assert(id == -42);
		Test.Assert(weight == 1.5f);
		Test.Assert(enabled);
		Test.Assert(kind == 300, "the enum kept its declared int16 width");
		Test.Assert(x == 1.0f);
		Test.Assert(y == 2.0f);
		Test.Assert(z == 3.0f);
		Test.Assert(name == "generated");
		Test.Assert(reader.IsOk);
		Test.Assert(stream.Tell() == stream.Size(), "the whole payload is accounted for");
	}

	/// The data version travels with the type, so a body that has to read an older layout
	/// has something to branch on.
	[Test]
	public static void TheDataVersionIsAvailableOnTheType()
	{
		Test.Assert(SerializableSample.DataVersion == 1);
	}

	/// The opt-out. A derived quantity must not be stored, or a hand-edited file could
	/// contradict itself.
	[Test]
	public static void AHandWrittenBodyStillWins()
	{
		let stream = scope MemoryStream();
		let source = scope HandWrittenSample();
		source.Celsius = 100.0f;
		Test.Assert(source.Fahrenheit == 212.0f);

		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)source);
		}
		Test.Assert(stream.Size() == 4, "only Celsius is stored");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope HandWrittenSample();
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, (ISerializable)target);
		}
		Test.Assert(target.Celsius == 100.0f);
		Test.Assert(target.Fahrenheit == 212.0f, "the derived value comes back from the stored one");
	}
}
