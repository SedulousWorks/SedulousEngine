namespace EngineSandbox;

using System;
using Sedulous.Engine.App;
using Sedulous.Engine;
using Sedulous.Engine.Render;
using Sedulous.Scenes;
using Sedulous.Runtime;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;

class SandboxApp : EngineApplication
{
	protected override void OnStartup()
	{
		Console.WriteLine("=== EngineSandbox OnStartup ===");

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let pipeline = renderSub.Pipeline;

		// Create a test scene
		// RenderSubsystem auto-injects MeshComponentManager + CameraComponentManager via ISceneAware
		let scene = sceneSub.CreateScene("TestScene");
		Console.WriteLine("Created scene: {0}", scene.Name);

		// Upload a colored triangle to GPU
		float[21] vertices = .(
			 0.0f,  0.5f, 0.0f,  1.0f, 0.0f, 0.0f, 1.0f,  // Top - red
			 0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f, 1.0f,  // Bottom right - green
			-0.5f, -0.5f, 0.0f,  0.0f, 0.0f, 1.0f, 1.0f   // Bottom left - blue
		);

		MeshUploadDesc meshDesc = .()
		{
			VertexData = (uint8*)&vertices[0],
			VertexDataSize = (uint64)(vertices.Count * sizeof(float)),
			VertexCount = 3,
			VertexStride = 28,
			Bounds = .(.(-0.5f, -0.5f, 0), .(0.5f, 0.5f, 0))
		};

		GPUMeshHandle triangleHandle = .Invalid;
		if (pipeline.GPUResources.UploadMesh(meshDesc) case .Ok(let handle))
		{
			triangleHandle = handle;
			Console.WriteLine("Triangle uploaded to GPU");
		}
		else
		{
			Console.WriteLine("ERROR: Failed to upload triangle");
			return;
		}

		// Create a mesh entity with a MeshComponent
		let meshEntity = scene.CreateEntity("Triangle");
		let meshMgr = scene.GetModule<MeshComponentManager>();
		let meshCompHandle = meshMgr.CreateComponent(meshEntity);
		if (let meshComp = meshMgr.Get(meshCompHandle))
		{
			meshComp.MeshHandle = triangleHandle;
			meshComp.LocalBounds = .(.(-0.5f, -0.5f, 0), .(0.5f, 0.5f, 0));
			// No material yet — will render with unlit fallback
		}

		// Create a camera entity with a CameraComponent
		let cameraEntity = scene.CreateEntity("Camera");
		// Camera at (0, 0, 2) looking at the triangle at origin
		scene.SetLocalTransform(cameraEntity, Transform.CreateLookAt(.(0, 0, 2), .Zero));

		let cameraMgr = scene.GetModule<CameraComponentManager>();
		let cameraCompHandle = cameraMgr.CreateComponent(cameraEntity);
		if (let camera = cameraMgr.Get(cameraCompHandle))
		{
			camera.FieldOfView = 60.0f;
			camera.NearPlane = 0.1f;
			camera.FarPlane = 100.0f;
		}

		Console.WriteLine("Entities: {0}", scene.EntityCount);
		Console.WriteLine("=== Engine running (close window to exit) ===");
	}

	protected override void OnShutdown()
	{
		Console.WriteLine("=== EngineSandbox OnShutdown ===");
	}
}
