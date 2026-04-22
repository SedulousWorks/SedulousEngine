namespace Sedulous.Engine.Core.Tests;

using System;
using Sedulous.Core.Mathematics;

class TransformTests
{
	[Test]
	public static void DefaultTransform_IsIdentity()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		let transform = scene.GetLocalTransform(entity);
		Test.Assert(transform.Position == .Zero);
		Test.Assert(transform.Scale == .One);

		let world = scene.GetWorldMatrix(entity);
		Test.Assert(world == .Identity);
	}

	[Test]
	public static void SetLocalTransform_UpdatesWorldMatrix()
	{
		let scene = scope Scene();
		let entity = scene.CreateEntity();

		scene.SetLocalTransform(entity, .()
		{
			Position = .(10, 20, 30),
			Rotation = .Identity,
			Scale = .One
		});

		// Run update to propagate transforms
		scene.Update(0);

		let world = scene.GetWorldMatrix(entity);
		// Translation should be in the matrix
		Test.Assert(Math.Abs(world.M41 - 10) < 0.001f);
		Test.Assert(Math.Abs(world.M42 - 20) < 0.001f);
		Test.Assert(Math.Abs(world.M43 - 30) < 0.001f);
	}

	[Test]
	public static void ParentChild_WorldMatrixInheritsParent()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity("Parent");
		let child = scene.CreateEntity("Child");

		scene.SetParent(child, parent);

		scene.SetLocalTransform(parent, .()
		{
			Position = .(100, 0, 0),
			Rotation = .Identity,
			Scale = .One
		});

		scene.SetLocalTransform(child, .()
		{
			Position = .(10, 0, 0),
			Rotation = .Identity,
			Scale = .One
		});

		scene.Update(0);

		let parentWorld = scene.GetWorldMatrix(parent);
		let childWorld = scene.GetWorldMatrix(child);

		// Parent at 100, child local at 10 -> child world at 110
		Test.Assert(Math.Abs(parentWorld.M41 - 100) < 0.001f);
		Test.Assert(Math.Abs(childWorld.M41 - 110) < 0.001f);
	}

	[Test]
	public static void ParentChild_ScaleInherits()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let child = scene.CreateEntity();

		scene.SetParent(child, parent);

		scene.SetLocalTransform(parent, .()
		{
			Position = .Zero,
			Rotation = .Identity,
			Scale = .(2, 2, 2)
		});

		scene.SetLocalTransform(child, .()
		{
			Position = .(5, 0, 0),
			Rotation = .Identity,
			Scale = .One
		});

		scene.Update(0);

		let childWorld = scene.GetWorldMatrix(child);
		// Child at local (5,0,0) with parent scale 2 -> world (10,0,0)
		Test.Assert(Math.Abs(childWorld.M41 - 10) < 0.001f);
	}

	[Test]
	public static void Unparent_BreaksInheritance()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let child = scene.CreateEntity();

		scene.SetParent(child, parent);
		scene.SetLocalTransform(parent, .() { Position = .(100, 0, 0), Rotation = .Identity, Scale = .One });
		scene.SetLocalTransform(child, .() { Position = .(10, 0, 0), Rotation = .Identity, Scale = .One });
		scene.Update(0);

		// Child world should be 110
		Test.Assert(Math.Abs(scene.GetWorldMatrix(child).M41 - 110) < 0.001f);

		// Unparent
		scene.SetParent(child, .Invalid);
		scene.Update(0);

		// Child world should now be just 10 (no parent)
		Test.Assert(Math.Abs(scene.GetWorldMatrix(child).M41 - 10) < 0.001f);
	}

	[Test]
	public static void SetParent_GetParent_Roundtrip()
	{
		let scene = scope Scene();
		let parent = scene.CreateEntity();
		let child = scene.CreateEntity();

		Test.Assert(scene.GetParent(child) == .Invalid);

		scene.SetParent(child, parent);
		Test.Assert(scene.GetParent(child) == parent);

		scene.SetParent(child, .Invalid);
		Test.Assert(scene.GetParent(child) == .Invalid);
	}

	[Test]
	public static void DeepHierarchy_PropagatesCorrectly()
	{
		let scene = scope Scene();
		let root = scene.CreateEntity();
		let mid = scene.CreateEntity();
		let leaf = scene.CreateEntity();

		scene.SetParent(mid, root);
		scene.SetParent(leaf, mid);

		scene.SetLocalTransform(root, .() { Position = .(1, 0, 0), Rotation = .Identity, Scale = .One });
		scene.SetLocalTransform(mid, .() { Position = .(2, 0, 0), Rotation = .Identity, Scale = .One });
		scene.SetLocalTransform(leaf, .() { Position = .(3, 0, 0), Rotation = .Identity, Scale = .One });

		scene.Update(0);

		Test.Assert(Math.Abs(scene.GetWorldMatrix(root).M41 - 1) < 0.001f);
		Test.Assert(Math.Abs(scene.GetWorldMatrix(mid).M41 - 3) < 0.001f);  // 1 + 2
		Test.Assert(Math.Abs(scene.GetWorldMatrix(leaf).M41 - 6) < 0.001f); // 1 + 2 + 3
	}
}
