namespace Sedulous.Audio.Tests;

using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.Graph;

class AudioBusSystemTests
{
	[Test]
	public static void System_HasMasterBus()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		Test.Assert(system.Master != null);
		Test.Assert(system.Master.Name == "Master");
	}

	[Test]
	public static void System_HasDefaultBuses()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		Test.Assert(system.GetBus("Master") != null);
		Test.Assert(system.GetBus("SFX") != null);
		Test.Assert(system.GetBus("Music") != null);
	}

	[Test]
	public static void System_CreateBus()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		let bus = system.CreateBus("UI");
		Test.Assert(bus != null);
		Test.Assert(bus.Name == "UI");
		Test.Assert(bus.Parent == system.Master);
		Test.Assert(system.GetBus("UI") == bus);
	}

	[Test]
	public static void System_CreateBus_WithParent()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		let sfx = system.GetBus("SFX");
		let footsteps = system.CreateBus("Footsteps", sfx);

		Test.Assert(footsteps != null);
		Test.Assert(footsteps.Parent == sfx);
	}

	[Test]
	public static void System_CreateBus_DuplicateName_ReturnsSame()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		let bus1 = system.CreateBus("UI");
		let bus2 = system.CreateBus("UI");

		Test.Assert(bus1 == bus2);
	}

	[Test]
	public static void System_DestroyBus_ReparentsChildren()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		let parent = system.CreateBus("Parent");
		let child = system.CreateBus("Child", parent);

		// Child's parent is "Parent"
		Test.Assert(child.Parent == parent);

		// Destroy "Parent" - child should reparent to Master
		system.DestroyBus(parent);

		Test.Assert(system.GetBus("Parent") == null);
		Test.Assert(child.Parent == system.Master);
	}

	[Test]
	public static void System_CannotDestroyMaster()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		system.DestroyBus(system.Master);
		Test.Assert(system.Master != null);
		Test.Assert(system.GetBus("Master") != null);
	}

	[Test]
	public static void System_GetBus_NotFound_ReturnsNull()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		Test.Assert(system.GetBus("NonExistent") == null);
	}

	[Test]
	public static void System_GetBusNames()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		let names = scope List<StringView>();
		system.GetBusNames(names);

		Test.Assert(names.Count >= 3); // Master, SFX, Music
		bool hasMaster = false;
		bool hasSFX = false;
		bool hasMusic = false;
		for (let name in names)
		{
			if (name == "Master") hasMaster = true;
			if (name == "SFX") hasSFX = true;
			if (name == "Music") hasMusic = true;
		}
		Test.Assert(hasMaster);
		Test.Assert(hasSFX);
		Test.Assert(hasMusic);
	}

	[Test]
	public static void System_GraphAccess()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		Test.Assert(system.Graph == graph);
	}

	[Test]
	public static void System_SFXBus_ParentIsMaster()
	{
		let graph = scope AudioGraph();
		let system = scope AudioBusSystem(graph);

		let sfx = system.GetBus("SFX");
		Test.Assert(sfx.Parent == system.Master);
	}
}
