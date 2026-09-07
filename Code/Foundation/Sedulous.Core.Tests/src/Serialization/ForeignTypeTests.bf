using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// Serializing a type this project does not own.
class ForeignTypeTests
{
	/// The declaration says nothing about serialization: an extension supplies it, and the
	/// generated walker still finds the fields.
	[Test]
	public static void AnExtensionMakesAForeignTypeSerializable()
	{
		let stream = scope MemoryStream();
		let source = scope ForeignType();
		source.Alpha = 42;
		source.Beta = 1.5f;

		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)source);
			Test.Assert(writer.IsOk);
		}
		Test.Assert(stream.Size() == 8, "both fields, and nothing else");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope ForeignType();
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, (ISerializable)target);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(target.Alpha == 42);
		Test.Assert(target.Beta == 1.5f);
	}

	/// The extension adds the interface too, so the type can be passed as one.
	[Test]
	public static void TheExtensionAddsTheInterface()
	{
		ISerializable asInterface = scope ForeignType();
		Test.Assert(asInterface != null);
	}

	[Test]
	public static void ItIsRegisteredLikeAnyOtherSerializableType()
	{
		TestSerializables.RegisterAll();
		Test.Assert(GlobalSerializableRegistry.IsRegistered(ForeignType.TypeId));

		let created = GlobalSerializableRegistry.Create(ForeignType.TypeId);
		Test.Assert(created != null);
		defer delete created;
		Test.Assert(created is ForeignType);
	}
}
