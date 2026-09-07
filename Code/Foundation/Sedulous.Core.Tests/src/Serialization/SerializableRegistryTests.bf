using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// The registry, and the polymorphic load it exists for.
class SerializableRegistryTests
{
	[Test]
	public static void RegisterAllFindsEveryDeclaredType()
	{
		GlobalSerializableRegistry.Clear();
		Test.Assert(GlobalSerializableRegistry.Count == 0);

		TestSerializables.RegisterAll();

		// Both attributed types, found without either being listed anywhere by hand.
		Test.Assert(GlobalSerializableRegistry.IsRegistered(SerializableSample.TypeId));
		Test.Assert(GlobalSerializableRegistry.IsRegistered(VersionedSample.TypeId));
		Test.Assert(GlobalSerializableRegistry.Count >= 2);
	}

	[Test]
	public static void CreatesByTypeId()
	{
		TestSerializables.RegisterAll();

		let created = GlobalSerializableRegistry.Create(SerializableSample.TypeId);
		Test.Assert(created != null);
		defer delete created;
		Test.Assert(created is SerializableSample);

		let versioned = GlobalSerializableRegistry.Create(VersionedSample.TypeId);
		Test.Assert(versioned != null);
		defer delete versioned;
		Test.Assert(versioned is VersionedSample);
	}

	/// A payload written by a build that had a type this one does not is the ordinary
	/// case, not an error. It answers null so the caller can skip the framed region.
	[Test]
	public static void AnUnknownIdCreatesNothing()
	{
		TestSerializables.RegisterAll();
		Test.Assert(GlobalSerializableRegistry.Create(0) == null);
		Test.Assert(!GlobalSerializableRegistry.IsRegistered(0));
	}

	/// Only what carries the attribute is registered. A hand-written ISerializable is
	/// serializable but not constructible by id, because nothing recorded an id for it.
	[Test]
	public static void OnlyAttributedTypesAreRegistered()
	{
		TestSerializables.RegisterAll();
		Test.Assert(GlobalSerializableRegistry.Create(TypeIdOf("Sedulous.Core.Tests.HandWrittenSample")) == null);
	}

	/// The whole point: a stream records which type wrote it, and the reader reconstructs
	/// that type without naming it.
	[Test]
	public static void APayloadRoundTripsWithoutTheReaderNamingTheType()
	{
		TestSerializables.RegisterAll();

		let stream = scope MemoryStream();
		{
			let source = scope VersionedSample();
			source.Value = 1234;

			let writer = scope BinarySerializer(stream, .Write);
			var typeId = VersionedSample.TypeId;
			Serialize(writer, ref typeId);
			writer.BeginFramedRegion();
			Serialize(writer, (ISerializable)source);
			writer.EndFramedRegion();
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		{
			let reader = scope BinarySerializer(stream, .Read);
			uint64 typeId = 0;
			Serialize(reader, ref typeId);

			let loaded = GlobalSerializableRegistry.Create(typeId);
			Test.Assert(loaded != null, "the id named a type the registry knows");
			defer delete loaded;

			reader.BeginFramedRegion();
			Serialize(reader, loaded);
			reader.EndFramedRegion();
			Test.Assert(reader.IsOk);

			// Only now does the test name the type, to check the answer.
			Test.Assert(loaded is VersionedSample);
			Test.Assert(((VersionedSample)loaded).Value == 1234);
		}
	}

	/// A type this build does not have is skipped whole rather than desyncing the stream,
	/// which is what the framed region buys.
	[Test]
	public static void AnUnknownPayloadIsSkippedAndTheStreamContinues()
	{
		TestSerializables.RegisterAll();

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			// Pretend a future build wrote a type this one has never heard of.
			var typeId = (uint64)0xABCDEF;
			Serialize(writer, ref typeId);
			writer.BeginFramedRegion();
			for (int32 i < 12)
			{
				var junk = i;
				Serialize(writer, ref junk);
			}
			writer.EndFramedRegion();

			var trailer = (int32)555;
			Serialize(writer, ref trailer);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		{
			let reader = scope BinarySerializer(stream, .Read);
			uint64 typeId = 0;
			Serialize(reader, ref typeId);
			Test.Assert(GlobalSerializableRegistry.Create(typeId) == null, "unknown, as intended");

			reader.BeginFramedRegion();
			reader.EndFramedRegion();

			int32 trailer = 0;
			Serialize(reader, ref trailer);
			Test.Assert(reader.IsOk);
			Test.Assert(trailer == 555, "the reader landed after the unknown payload");
		}
	}
}
