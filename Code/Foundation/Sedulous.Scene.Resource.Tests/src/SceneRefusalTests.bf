using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Scene.Resource.Tests;

/// What the reader REFUSES, and what it recovers from.
///
/// A serializer's refusals are worth as much as its successes: every one of these is a
/// stream that would otherwise be read as though it were ours, turning a count into an
/// allocation or a field into the wrong field.
class SceneRefusalTests
{
	private static Guid PrefabId => .(0xABCD, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

	/// A prefab section tagged with a retired layout is refused rather than parsed. The
	/// counts after the tag mean something different in the old layouts, so a misparse
	/// there allocates whatever number happened to be in the stream.
	[Test]
	public static void ARetiredPrefabSectionTagIsRefused()
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneStreamFormat.WriteHeader(writer);
			let name = scope String("world");
			Sedulous.Core.Serialization.Serialize(writer, "name", name);

			uint32 zero = 0;
			writer.Key("entities"); writer.BeginArray(ref zero); writer.EndArray();
			writer.Key("components"); writer.BeginArray(ref zero); writer.EndArray();
			writer.Key("systemSettings"); writer.BeginArray(ref zero); writer.EndArray();

			// One of the layouts that was retired.
			uint8 retiredTag = 2;
			SerializeValue(writer, "prefabMode", ref retiredTag);
		}
		buffer.Seek(0, .Begin);

		let scene = scope Scene();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, scene, .Referenced, true, .Binary);

		Test.Assert(!reader.IsOk, "the retired tag was refused");
		Test.Assert(reader.Status case .Err(.NotSupported));
	}

	/// A stream that stops mid record fails the read rather than inventing the rest.
	[Test]
	public static void ATruncatedStreamFailsTheRead()
	{
		let full = scope MemoryStream();
		{
			let source = scope Scene();
			source.AddSystem<HealthManager>();
			source.CreateEntity("A");
			source.SetParent(source.CreateEntity("B"), source.FindEntityByName("A"));
			let writer = scope BinarySerializer(full, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
		}

		// Cut it off part way through.
		let bytes = scope List<uint8>();
		bytes.AddRange(full.Bytes);
		let truncated = scope MemoryStream();
		truncated.Write(.(bytes.Ptr, bytes.Count / 2));
		truncated.Seek(0, .Begin);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let reader = scope BinarySerializer(truncated, .Read);
		SceneSerializer.SerializeScene(reader, scene, .Referenced, true, .Binary);

		Test.Assert(!reader.IsOk, "the read failed rather than completing on invented bytes");
	}

	/// A prefab payload with more than one root is refused. Parenting the extras under the
	/// first would invent a hierarchy nobody authored, and the deltas keyed on it would
	/// then describe a shape the template never had.
	[Test]
	public static void AMultiRootPrefabPayloadIsRefusedOnSpawn()
	{
		// A payload written by hand with two nil-parent entities.
		let payload = scope MemoryStream();
		{
			let writer = scope BinarySerializer(payload, .Write);
			SceneStreamFormat.WriteHeader(writer);
			let name = scope String("TwoRoots");
			Sedulous.Core.Serialization.Serialize(writer, "name", name);

			uint32 entityCount = 2;
			writer.Key("entities");
			writer.BeginArray(ref entityCount);
			for (uint32 i < entityCount)
			{
				var id = Guid((uint32)(i + 1), 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
				let entityName = scope:: String("Root");
				uint8 active = 1;
				var parentId = Guid();
				var transform = Transform();
				SerializeValue(writer, "id", ref id);
				Sedulous.Core.Serialization.Serialize(writer, "name", entityName);
				SerializeValue(writer, "active", ref active);
				SerializeValue(writer, "parent", ref parentId);
				SceneStreamFormat.SerializeTransform(writer, ref transform);
			}
			writer.EndArray();

			uint32 zero = 0;
			writer.Key("components"); writer.BeginArray(ref zero); writer.EndArray();
			writer.Key("systemSettings"); writer.BeginArray(ref zero); writer.EndArray();
			var tag = SceneStreamFormat.cPrefabWireReferenced;
			SerializeValue(writer, "prefabMode", ref tag);
			writer.Key("prefabInstances"); writer.BeginArray(ref zero); writer.EndArray();
		}
		payload.Seek(0, .Begin);

		let scene = scope Scene();
		scene.AddSystem<HealthManager>();
		let spawned = PrefabSpawn.Spawn(scene, payload, PrefabId);

		Test.Assert(!spawned.IsAssigned, "the multi root payload was refused");
		Test.Assert(scene.PrefabInstanceCount == 0, "and no instance was recorded");
	}

	/// A save carrying the SAME entity guid twice gets the duplicate a fresh id, so every
	/// entity stays uniquely addressable. Records addressed to the shared guid route to its
	/// first holder, which is the recoverable answer.
	[Test]
	public static void ADuplicateEntityGuidIsRecoveredWithAFreshId()
	{
		let shared = Guid(0x5EED, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneStreamFormat.WriteHeader(writer);
			let name = scope String("dup");
			Sedulous.Core.Serialization.Serialize(writer, "name", name);

			uint32 entityCount = 2;
			writer.Key("entities");
			writer.BeginArray(ref entityCount);
			for (uint32 i < entityCount)
			{
				var id = shared; // the same guid, twice
				let entityName = scope:: String((i == 0) ? "First" : "Second");
				uint8 active = 1;
				var parentId = Guid();
				var transform = Transform();
				SerializeValue(writer, "id", ref id);
				Sedulous.Core.Serialization.Serialize(writer, "name", entityName);
				SerializeValue(writer, "active", ref active);
				SerializeValue(writer, "parent", ref parentId);
				SceneStreamFormat.SerializeTransform(writer, ref transform);
			}
			writer.EndArray();

			uint32 zero = 0;
			writer.Key("components"); writer.BeginArray(ref zero); writer.EndArray();
			writer.Key("systemSettings"); writer.BeginArray(ref zero); writer.EndArray();
			var tag = SceneStreamFormat.cPrefabWireReferenced;
			SerializeValue(writer, "prefabMode", ref tag);
			writer.Key("prefabInstances"); writer.BeginArray(ref zero); writer.EndArray();
		}
		buffer.Seek(0, .Begin);

		let scene = scope Scene();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, scene, .Referenced, true, .Binary);

		Test.Assert(scene.EntityCount == 2, "both entities survived");
		let first = scene.FindEntityByName("First");
		let second = scene.FindEntityByName("Second");
		Test.Assert(first.IsAssigned && second.IsAssigned);
		Test.Assert(scene.GetEntityId(first) != scene.GetEntityId(second),
			"the duplicate was given a fresh id");
		Test.Assert(scene.FindEntity(shared) == first, "the shared guid routes to its first holder");
	}

	/// A guid minted AFTER a load never collides with one the load brought in. The
	/// generator is deterministic and loading does not advance it, so a fresh id can land
	/// on one already present unless the mint re-rolls.
	[Test]
	public static void AFreshGuidNeverCollidesWithALoadedOne()
	{
		// Take the ids a fresh scene would mint first.
		let reference = scope Scene();
		let taken = scope List<Guid>();
		for (int i < 4)
			taken.Add(reference.GetEntityId(reference.CreateEntity("x")));

		// A scene loaded with exactly those ids: the next mint must not repeat one.
		let scene = scope Scene();
		for (let id in taken)
			scene.CreateEntity(id, "loaded");

		for (int i < 8)
		{
			let minted = scene.CreateEntity("minted");
			let mintedId = scene.GetEntityId(minted);
			for (let existing in taken)
				Test.Assert(mintedId != existing, "a fresh id re-rolled past the loaded one");
		}

		Test.Assert(scene.EntityCount == 12, "every entity is distinct and addressable");
	}
}
