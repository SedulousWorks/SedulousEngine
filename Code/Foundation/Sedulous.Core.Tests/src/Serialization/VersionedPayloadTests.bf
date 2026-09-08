using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// Version envelopes: the stamp that says which layout a payload was written under.
///
/// ONE supported layout per type. The stamp exists to REFUSE anything else, not to migrate
/// it: a reader that guessed at an older layout would decode the wrong fields and hand back
/// a value that looks perfectly plausible.
class VersionedPayloadTests
{
	/// Declaring a version is how you opt in. It costs bytes in every payload, so a type
	/// that never needs to migrate should not be paying for one.
	[Test]
	public static void AnUnversionedTypeWritesNoEnvelope()
	{
		let plain = scope MemoryStream();
		{
			let writer = scope BinarySerializer(plain, .Write);
			let sample = scope SerializableSample();
			sample.Name.Set("");
			Serialize(writer, (ISerializable)sample);
		}

		// Id, weight, enabled, kind, three floats, a guid, and an empty prefixed string.
		Test.Assert(plain.Size() == 4 + 4 + 1 + 2 + 12 + 16 + 4);
	}

	[Test]
	public static void AVersionedTypeWritesItsChainFirst()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			let sample = scope VersionedSample();
			sample.Value = 9;
			Serialize(writer, (ISerializable)sample);
		}

		// A uint32 count, then one (uint64 id, uint32 version) pair, then the field.
		Test.Assert(stream.Size() == 4 + (8 + 4) + 4);

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinaryReader(stream);
		uint32 count = 0;
		uint64 typeId = 0;
		uint32 version = 0;
		int32 value = 0;
		Test.Assert(reader.Read(out count));
		Test.Assert(reader.Read(out typeId));
		Test.Assert(reader.Read(out version));
		Test.Assert(reader.Read(out value));

		Test.Assert(count == 1);
		Test.Assert(typeId == VersionedSample.TypeId);
		Test.Assert(version == 3);
		Test.Assert(value == 9);
	}

	[Test]
	public static void AVersionedTypeRoundTrips()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			let sample = scope VersionedSample();
			sample.Value = -321;
			Serialize(writer, (ISerializable)sample);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope VersionedSample();
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, (ISerializable)target);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(target.Value == -321);
	}

	/// A payload written under an older version is REFUSED, not migrated.
	///
	/// This is the whole bargain: bumping a data version means re-saving what was written
	/// under the old one. The alternative is a reader that quietly decodes the wrong
	/// fields, which fails much later and much less obviously.
	[Test]
	public static void StaleDataIsRefusedRatherThanMigrated()
	{
		let old = scope MemoryStream();
		{
			let writer = scope BinarySerializer(old, .Write);
			let sample = scope StaleVersionSample();
			sample.WriteVersion = 1;
			sample.Width = 42;
			sample.Height = 999;
			Serialize(writer, (ISerializable)sample);
		}

		Test.Assert(old.Seek(0, .Begin) == 0);
		let target = scope StaleVersionSample();
		let reader = scope BinarySerializer(old, .Read);
		Serialize(reader, (ISerializable)target);

		Test.Assert(!reader.IsOk, "the version one payload was refused");
		Test.Assert(reader.Status case .Err(.NotSupported));
	}

	/// A chain carrying MORE entries than the type declares is refused too: it describes a
	/// type hierarchy this build does not have, so the fields after it are not ours to read.
	[Test]
	public static void AChainWithExtraEntriesIsRefused()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SerializedDataVersion[2] chain = .(.(StaleVersionSample.TypeId, StaleVersionSample.CurrentVersion),
				.(0xBA5E, 1));
			BeginVersionedPayload(writer, .(&chain[0], 2));
			EndVersionedPayload(writer);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinarySerializer(stream, .Read);
		BeginVersionedPayload(reader, StaleVersionSample.TypeId, StaleVersionSample.CurrentVersion);
		Test.Assert(!reader.IsOk);
		Test.Assert(reader.Status case .Err(.NotSupported));
		EndVersionedPayload(reader);
	}

	/// And a chain naming a DIFFERENT type: the right version of the wrong thing is still
	/// the wrong thing.
	[Test]
	public static void AChainNamingAnotherTypeIsRefused()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			BeginVersionedPayload(writer, 0xF00D, StaleVersionSample.CurrentVersion);
			EndVersionedPayload(writer);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let reader = scope BinarySerializer(stream, .Read);
		BeginVersionedPayload(reader, StaleVersionSample.TypeId, StaleVersionSample.CurrentVersion);
		Test.Assert(!reader.IsOk);
		Test.Assert(reader.Status case .Err(.NotSupported));
		EndVersionedPayload(reader);
	}

	[Test]
	public static void CurrentDataReadsBothFields()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			let sample = scope StaleVersionSample();
			sample.Width = 7;
			sample.Height = 11;
			Serialize(writer, (ISerializable)sample);
		}
		Test.Assert(stream.Size() == 4 + (8 + 4) + 4 + 4, "the chain, then both fields");

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope StaleVersionSample();
		{
			let reader = scope BinarySerializer(stream, .Read);
			Serialize(reader, (ISerializable)target);
		}
		Test.Assert(target.Width == 7);
		Test.Assert(target.Height == 11);
	}

	/// Outside any payload there is no version, and asking for one that is not in the
	/// chain answers zero rather than the concrete type's.
	[Test]
	public static void VersionIsZeroOutsideAScopeAndForAbsentTypes()
	{
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		Test.Assert(ar.Version == 0);
		Test.Assert(ar.VersionOf(12345) == 0);

		SerializedDataVersion[1] chain = .(.(777, 4));
		ar.PushVersionScope(.(&chain[0], 1));
		Test.Assert(ar.Version == 4);
		Test.Assert(ar.VersionOf(777) == 4);
		Test.Assert(ar.VersionOf(778) == 0, "a type absent from the chain reads as unversioned");

		ar.PopVersionScope();
		Test.Assert(ar.Version == 0);
	}

	/// Scopes nest, and leaving one restores the one outside it.
	[Test]
	public static void ScopesNestAndRestore()
	{
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);

		SerializedDataVersion[1] outer = .(.(1, 10));
		SerializedDataVersion[1] inner = .(.(2, 20));

		ar.PushVersionScope(.(&outer[0], 1));
		Test.Assert(ar.Version == 10);

		ar.PushVersionScope(.(&inner[0], 1));
		Test.Assert(ar.Version == 20);
		Test.Assert(ar.VersionOf(1) == 0, "the outer scope's types are not visible from the inner one");

		ar.PopVersionScope();
		Test.Assert(ar.Version == 10, "the outer scope came back");

		ar.PopVersionScope();
		Test.Assert(ar.Version == 0);
	}

	/// A chain length that could not be real is a corrupt stream. Reading it out would
	/// desync everything after, so it fails instead.
	[Test]
	public static void AnImplausibleChainLengthFailsThePayload()
	{
		let stream = scope MemoryStream();
		Test.Assert(stream.WriteValue<uint32>(100000));
		Test.Assert(stream.Seek(0, .Begin) == 0);

		let reader = scope BinarySerializer(stream, .Read);
		BeginVersionedPayload(reader, 1, 1);
		Test.Assert(!reader.IsOk);
		Test.Assert(reader.Status case .Err(.OutOfRange));
		Test.Assert(reader.Version == 0, "no version came out of a chain that was not read");
		EndVersionedPayload(reader);
	}
}
