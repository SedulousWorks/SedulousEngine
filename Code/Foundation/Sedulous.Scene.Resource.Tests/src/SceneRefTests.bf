using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// A field naming a scene (SceneRef): a reference to tooling, set by id and never bound, kept with
/// its component, and reported to a pruned export by the component's manager.
static class SceneRefTests
{
	[Test]
	public static void ASceneRefIsAReferenceToASceneThatNothingBinds()
	{
		let type = typeof(SceneRef);
		Test.Assert(ReferenceShape.Is(type));
		Test.Assert(ReferenceShape.IsIdReference(type));
		Test.Assert(!ReferenceShape.IsBound(type));
		Test.Assert(ReferenceShape.Target(type) == typeof(SceneDocument), "the picker offers scenes");

		// Assigned as a picker or an agent assigns a reference, with a manager at hand: the id is
		// taken and nothing is bound.
		var exit = SceneRef();
		let level = Guid.Create();
		let resources = scope ResourceManager(null);
		Test.Assert(ReferenceShape.Assign(type, &exit, level, resources) case .Ok);
		Test.Assert(exit.Id == level);
		Test.Assert(exit.IsSet);
		Test.Assert(resources.FindHandle(level) == null, "never bound");
		if (ReferenceShape.Id(type, &exit) case .Ok(let id))
			Test.Assert(id == level);
		else
			Test.Assert(false, "its id reads");
	}

	[Test]
	public static void AComponentKeepsItsSceneRefAndItsManagerReportsItForAnExport()
	{
		let level = Guid.Create();
		let source = scope Scene("hall");
		let exits = source.AddSystem<LevelExitManager>();
		let door = source.CreateEntity("Door");
		exits.Add(door).Next = .(level);
		exits.Add(source.CreateEntity("Wall")); // names none

		let unbound = scope List<Guid>();
		exits.CollectUnboundReferences(unbound);
		Test.Assert((unbound.Count == 1) && (unbound[0] == level), "the scene it names, and no nil");

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
		}
		buffer.Seek(0, .Begin);
		let loaded = scope Scene("hall");
		let loadedExits = loaded.AddSystem<LevelExitManager>();
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, loaded, .Referenced, true, .Binary);
		let back = loadedExits.Get(loaded.FindEntityByName("Door"));
		Test.Assert(back != null);
		Test.Assert(back.Next.Id == level, "kept with its component");
	}
}
