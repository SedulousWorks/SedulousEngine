namespace Sedulous.Engine.Core.Tests;

using System;

class EntityIterationTests
{
	[Test]
	public static void IterateEntities_Empty()
	{
		let scene = scope Scene();
		int32 count = 0;
		for (let entity in scene.Entities)
			count++;
		Test.Assert(count == 0);
	}

	[Test]
	public static void IterateEntities_AllAlive()
	{
		let scene = scope Scene();
		scene.CreateEntity("A");
		scene.CreateEntity("B");
		scene.CreateEntity("C");

		int32 count = 0;
		for (let entity in scene.Entities)
		{
			Test.Assert(scene.IsValid(entity));
			count++;
		}
		Test.Assert(count == 3);
	}

	[Test]
	public static void IterateEntities_SkipsDead()
	{
		let scene = scope Scene();
		scene.CreateEntity("A");
		let b = scene.CreateEntity("B");
		scene.CreateEntity("C");

		scene.DestroyEntity(b);

		int32 count = 0;
		for (let entity in scene.Entities)
			count++;
		Test.Assert(count == 2);
	}
}
