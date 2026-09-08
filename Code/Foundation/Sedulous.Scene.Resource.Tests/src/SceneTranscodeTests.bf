using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Xml.Serialization;

namespace Sedulous.Scene.Resource.Tests;

/// A source scene becoming the wire the player reads.
class SceneTranscodeTests
{
	private static void WriteTextScene(Scene scene, MemoryStream outStream)
	{
		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, scene, .Referenced, true, .Text);
		Test.Assert(serializer.IsOk);
		let text = scope String();
		serializer.GetOutput(text);
		outStream.Write(.((uint8*)text.Ptr, text.Length));
		outStream.Seek(0, .Begin);
	}

	[Test]
	public static void ATextSourceTranscodesToBinaryWithoutLosingAnything()
	{
		let source = scope Scene();
		source.SetName("world");
		let manager = source.AddSystem<HealthManager>();
		let world = source.AddSystem<WorldSystem>();
		world.Settings.Gravity = -4.5f;
		let player = source.CreateEntity("Player");
		source.SetParent(source.CreateEntity("Weapon"), player);
		manager.Add(player).Value = 12.0f;

		let text = scope MemoryStream();
		WriteTextScene(source, text);

		// Transcode through a scratch scene carrying the same systems.
		let scratch = scope Scene();
		scratch.AddSystem<HealthManager>();
		scratch.AddSystem<WorldSystem>();
		let binary = scope List<uint8>();
		Test.Assert(SceneTranscode.ToBinary(text, scratch, binary) case .Ok);
		Test.Assert(!binary.IsEmpty);

		// And the binary reads back as the same world.
		let buffer = scope MemoryStream();
		buffer.Write(binary);
		buffer.Seek(0, .Begin);
		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		let loadedWorld = loaded.AddSystem<WorldSystem>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, loaded, .Referenced, true, .Binary);

		Test.Assert(loaded.Name == "world");
		Test.Assert(loaded.FindEntityByPath("Player/Weapon").IsAssigned);
		Test.Assert(loadedManager.Get(loaded.FindEntityByName("Player")).Value == 12.0f);
		Test.Assert(loadedWorld.Settings.Gravity == -4.5f);
	}

	/// A stream that is ALREADY binary is copied through rather than round tripped:
	/// rewriting bytes that were fine could only lose something.
	[Test]
	public static void AnAlreadyBinaryStreamIsCopiedThrough()
	{
		let source = scope Scene();
		source.AddSystem<HealthManager>();
		source.CreateEntity("Solo");

		let binary = scope MemoryStream();
		{
			let writer = scope BinarySerializer(binary, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
		}
		binary.Seek(0, .Begin);
		let original = scope List<uint8>();
		original.AddRange(binary.Bytes);

		let scratch = scope Scene();
		scratch.AddSystem<HealthManager>();
		let output = scope List<uint8>();
		Test.Assert(SceneTranscode.ToBinary(binary, scratch, output) case .Ok);

		Test.Assert(output.Count == original.Count);
		Test.Assert(scratch.EntityCount == 0, "nothing was deserialized to copy bytes");
		for (int i = 0; i < output.Count; i++)
			Test.Assert(output[i] == original[i]);
	}

	/// A scratch scene MISSING a manager silently drops that component from a TEXT source.
	///
	/// Not a defect to fix but a constraint to know: a record whose manager is absent is
	/// preserved in the encoding it was captured in, and turning captured markup into the
	/// binary wire means understanding it, which means having the manager. So the scratch
	/// scene has to come from the full composition, and this pins what happens when it does
	/// not, so nobody discovers it from a shipped build with missing components.
	[Test]
	public static void ATextSourceLosesComponentsTheScratchSceneCannotUnderstand()
	{
		let source = scope Scene();
		let manager = source.AddSystem<HealthManager>();
		manager.Add(source.CreateEntity("Player")).Value = 5.0f;

		let text = scope MemoryStream();
		WriteTextScene(source, text);

		// A scratch scene that knows nothing about Health.
		let scratch = scope Scene();
		let binary = scope List<uint8>();
		Test.Assert(SceneTranscode.ToBinary(text, scratch, binary) case .Ok);
		Test.Assert(scratch.UnresolvedComponents.Length == 1, "it was preserved on the way in");

		// ...but could not be re-encoded on the way out.
		let buffer = scope MemoryStream();
		buffer.Write(binary);
		buffer.Seek(0, .Begin);
		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, loaded, .Referenced, true, .Binary);

		Test.Assert(loaded.FindEntityByName("Player").IsAssigned, "the entity survived");
		Test.Assert(loadedManager.Count == 0, "its component did not: give the scratch scene the manager");
	}

	/// With the manager present, which is what the full composition gives, nothing is lost.
	[Test]
	public static void AScratchSceneFromTheFullCompositionLosesNothing()
	{
		let source = scope Scene();
		let manager = source.AddSystem<HealthManager>();
		manager.Add(source.CreateEntity("Player")).Value = 5.0f;

		let text = scope MemoryStream();
		WriteTextScene(source, text);

		let scratch = scope Scene();
		scratch.AddSystem<HealthManager>();
		let binary = scope List<uint8>();
		Test.Assert(SceneTranscode.ToBinary(text, scratch, binary) case .Ok);

		let buffer = scope MemoryStream();
		buffer.Write(binary);
		buffer.Seek(0, .Begin);
		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, loaded, .Referenced, true, .Binary);

		Test.Assert(loadedManager.Count == 1);
		Test.Assert(loadedManager.Get(loaded.FindEntityByName("Player")).Value == 5.0f);
	}

	/// A BINARY source is the other way round: an unknown component is a blob, so it
	/// survives a scratch scene that cannot read it.
	[Test]
	public static void ABinarySourcePreservesComponentsTheScratchSceneCannotUnderstand()
	{
		let source = scope Scene();
		let manager = source.AddSystem<HealthManager>();
		manager.Add(source.CreateEntity("Player")).Value = 5.0f;

		let binarySource = scope MemoryStream();
		{
			let writer = scope BinarySerializer(binarySource, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
		}
		binarySource.Seek(0, .Begin);

		// Read it into a scratch scene with NO manager, then write it back out.
		let scratch = scope Scene();
		let reader = scope BinarySerializer(binarySource, .Read);
		SceneSerializer.SerializeScene(reader, scratch, .Referenced, true, .Binary);
		Test.Assert(scratch.UnresolvedComponents.Length == 1);

		let rewritten = scope MemoryStream();
		{
			let writer = scope BinarySerializer(rewritten, .Write);
			SceneSerializer.SerializeScene(writer, scratch, .Referenced, true, .Binary);
		}
		rewritten.Seek(0, .Begin);

		let loaded = scope Scene();
		let loadedManager = loaded.AddSystem<HealthManager>();
		let finalReader = scope BinarySerializer(rewritten, .Read);
		SceneSerializer.SerializeScene(finalReader, loaded, .Referenced, true, .Binary);

		Test.Assert(loadedManager.Count == 1, "a blob survives a build that cannot read it");
		Test.Assert(loadedManager.Get(loaded.FindEntityByName("Player")).Value == 5.0f);
	}
}
