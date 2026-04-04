namespace EngineSandbox;

using System;
using Sedulous.Engine.App;
using Sedulous.Engine;
using Sedulous.Scenes;
using Sedulous.Runtime;

class SandboxApp : EngineApplication
{
	protected override void OnStartup()
	{
		Console.WriteLine("=== EngineSandbox OnStartup ===");

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();

		// Create a test scene
		let scene = sceneSub.CreateScene("TestScene");
		Console.WriteLine("Created scene: {0}", scene.Name);

		// Create some entities with hierarchy
		let root = scene.CreateEntity("Root");
		let child1 = scene.CreateEntity("Child1");
		let child2 = scene.CreateEntity("Child2");

		scene.SetParent(child1, root);
		scene.SetParent(child2, root);

		scene.SetLocalTransform(root, .()
		{
			Position = .(0, 0, 0),
			Rotation = .Identity,
			Scale = .One
		});

		scene.SetLocalTransform(child1, .()
		{
			Position = .(5, 0, 0),
			Rotation = .Identity,
			Scale = .One
		});

		scene.SetLocalTransform(child2, .()
		{
			Position = .(0, 5, 0),
			Rotation = .Identity,
			Scale = .One
		});

		Console.WriteLine("Entities: {0}", scene.EntityCount);
		Console.WriteLine("Root ID: {0}", scene.GetEntityId(root));

		// Run one update to propagate transforms
		scene.Update(0);

		let child1World = scene.GetWorldMatrix(child1);
		Console.WriteLine("Child1 world X: {0}", child1World.M41);

		Console.WriteLine("=== Engine running (close window to exit) ===");
	}

	protected override void OnShutdown()
	{
		Console.WriteLine("=== EngineSandbox OnShutdown ===");
	}
}
