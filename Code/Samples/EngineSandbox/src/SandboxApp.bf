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
	// TEMPORARY: hardcoded geometry for testing until scene extraction exists
	private GPUMeshHandle mTriangleHandle;
	private ExtractedRenderData mRenderData ~ delete _;

	protected override void OnStartup()
	{
		Console.WriteLine("=== EngineSandbox OnStartup ===");

		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let pipeline = renderSub.Pipeline;

		// Upload a colored triangle to GPU
		// Vertex format: float3 position + float4 color = 28 bytes
		float[21] vertices = .(
			// Position           // Color (RGBA)
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
			IndexData = null,
			IndexDataSize = 0,
			IndexCount = 0,
			Bounds = .(.(-0.5f, -0.5f, 0), .(0.5f, 0.5f, 0))
		};

		if (pipeline.GPUResources.UploadMesh(meshDesc) case .Ok(let handle))
		{
			mTriangleHandle = handle;
			Console.WriteLine("Triangle uploaded to GPU");
		}
		else
		{
			Console.WriteLine("ERROR: Failed to upload triangle");
			return;
		}

		// Create render data with the triangle
		mRenderData = new ExtractedRenderData();
		mRenderData.AddMesh(RenderCategories.Opaque, .()
		{
			Base = .()
			{
				Position = .Zero,
				Bounds = .(.(-0.5f, -0.5f, 0), .(0.5f, 0.5f, 0)),
				MaterialSortKey = 0,
				SortOrder = 0,
				Flags = .None
			},
			WorldMatrix = .Identity,
			PrevWorldMatrix = .Identity,
			MeshHandle = mTriangleHandle,
			SubMeshIndex = 0,
			MaterialBindGroup = null,
			MaterialKey = 0
		});

		// Sort (trivial with one item, but establishes the pattern)
		mRenderData.SetView(.Identity, .Identity, .Zero, 0.1f, 100.0f,
			pipeline.OutputWidth, pipeline.OutputHeight);
		mRenderData.SortAndBatch();

		// TEMPORARY: provide render data to subsystem directly
		renderSub.FrameRenderData = mRenderData;

		Console.WriteLine("=== Engine running (close window to exit) ===");
	}

	protected override void OnShutdown()
	{
		Console.WriteLine("=== EngineSandbox OnShutdown ===");
	}
}
