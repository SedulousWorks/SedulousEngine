using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// Each SUBMESH draws with its own material's program, on real devices.
///
/// A card of two submeshes, its left half's slot a PBR material and its right half's slot the
/// `unlit` shader in green, in a scene with no light: each slot drawing its own program, the
/// left half stays dark (PBR, lit by nothing) and the right half shows its green. Every slot used
/// to draw with the mesh's program over the slot's own material group: the right half came out
/// dark, or on WebGPU not at all. Drawn alone, and as an instanced set (a crowd's per slot
/// materials).
class SubmeshShaderProbeTests
{
	private const uint32 cSize = 96;

	/// A unit card in the XY plane facing +Z, its left half submesh 0 (slot 0) and its right
	/// half submesh 1 (slot 1). THE CALLER OWNS what comes back.
	private static StaticMesh SplitCard()
	{
		let mesh = new StaticMesh();
		let white = 0xFFFFFFFF;
		for (int half < 2)
		{
			let x0 = (half == 0) ? -0.5f : 0.0f;
			let x1 = x0 + 0.5f;
			mesh.Vertices.Add(.(.(x0, -0.5f, 0), .(0, 0, 1), .(0, 1), white, Float4(1, 0, 0, 1)));
			mesh.Vertices.Add(.(.(x1, -0.5f, 0), .(0, 0, 1), .(1, 1), white, Float4(1, 0, 0, 1)));
			mesh.Vertices.Add(.(.(x1, 0.5f, 0), .(0, 0, 1), .(1, 0), white, Float4(1, 0, 0, 1)));
			mesh.Vertices.Add(.(.(x0, 0.5f, 0), .(0, 0, 1), .(0, 0), white, Float4(1, 0, 0, 1)));
		}
		// The buffer appends through its own cursor within the count, so the count comes first.
		mesh.Indices.Resize(12);
		for (uint32 half < 2)
		{
			let a = half * 4;
			mesh.Indices.AddTriangle(a, a + 1, a + 2);
			mesh.Indices.AddTriangle(a, a + 2, a + 3);
		}
		mesh.GenerateTangents();
		mesh.Bounds = AABB.FromCenterExtents(.(0, 0, 0), .(0.5f, 0.5f, 0.01f));
		mesh.SubMeshes.Add(.(0, 6, 0, .Triangles));
		mesh.SubMeshes.Add(.(6, 6, 1, .Triangles));
		return mesh;
	}

	/// Green pixels either side of the frame's middle; both -1 when the frame could not be
	/// rendered.
	private struct Halves
	{
		public int Left = -1;
		public int Right = -1;
	}

	/// Renders the scene twice (the second frame's history is its own) and counts the green
	/// pixels in each half.
	private static Halves Render(BackendProbeFixture fixture, MeshRenderer meshRenderer, RenderFrame frame,
		ExtractedScene scene)
	{
		let device = fixture.Device;
		var halves = Halves();

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 0);
		camera.FarZ = 100.0f;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "submesh.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return halves;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return halves;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return halves;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return halves;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return halves;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;

		for (uint32 i = 0; i < 2; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return halves;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();
			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return halves;
			}
			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		let image = RhiTestSupport.Readback(device, target, cSize, cSize);
		defer delete image;
		device.WaitIdle();
		if ((image == null) || !image.Valid)
			return halves;

		halves.Left = 0;
		halves.Right = 0;
		for (uint32 y < cSize)
		{
			for (uint32 x < cSize)
			{
				let p = image.At(x, y);
				if ((p[1] > 80) && ((int)p[1] > (int)p[0] + 40) && ((int)p[1] > (int)p[2] + 40))
				{
					if (x < cSize / 2)
						halves.Left++;
					else
						halves.Right++;
				}
			}
		}
		return halves;
	}

	[Test]
	public static void EachSlotDrawsWithItsOwnMaterialsProgramAloneAndInstanced()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		Test.Assert(materials.Initialize(device) case .Ok);
		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok);
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(device, registry, 2);

		let card = SplitCard();
		defer delete card;
		let lit = MaterialPresets.CreatePbr("submesh.lit", .(0.8f, 0.8f, 0.8f, 1), 0.0f, 0.9f);
		defer delete lit;
		let green = MaterialPresets.CreateUnlit("submesh.green", .(0.1f, 0.9f, 0.1f, 1));
		defer delete green;
		Material[2] slots = .(lit, green);
		let batchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(card), Internal.UnsafeCastToPtr(lit));

		// Drawn alone.
		{
			let scene = scope ExtractedScene();
			scene.SetAmbient(.(0.0f, 0.0f, 0.0f)); // no light: PBR is dark, unlit is its colour
			let md = scene.Add<MeshRenderData>();
			md.World = Float4x4.Translation(.(0.0f, 0.0f, -1.5f));
			md.Mesh = card;
			md.Material = lit;
			md.SubmeshMaterials = &slots[0];
			md.SubmeshMaterialCount = 2;
			md.RendererId = meshRenderer.RendererId;
			md.Category = RenderCategories.Opaque;
			md.SortBatchKey = batchKey;
			md.WorldCenter = .(0.0f, 0.0f, -1.5f);
			md.WorldRadius = 1.0f;
			md.EntityId = 2;
			let halves = Render(fixture, meshRenderer, frame, scene);
			Test.Assert(halves.Right >= 0, scope $"{kind}: the card rendered");
			Test.Assert(halves.Right > (int)(cSize * cSize / 8), scope $"{kind}: alone, the right half is its own green ({halves.Right})");
			Test.Assert(halves.Left == 0, scope $"{kind}: alone, the left half is PBR, unlit ({halves.Left})");
		}

		// As an instanced set of one.
		{
			Float4x4[1] transforms = .(Float4x4.Translation(.(0.0f, 0.0f, -1.5f)));
			let scene = scope ExtractedScene();
			scene.SetAmbient(.(0.0f, 0.0f, 0.0f));
			let set = scene.Add<MultiMeshRenderData>();
			set.MultiMesh = true;
			set.Key = 0x5AB5;
			set.Transforms = &transforms[0];
			set.InstanceCount = 1;
			set.UploadCount = 1;
			set.Version = 1;
			set.Mesh = card;
			set.Material = lit;
			set.SubmeshMaterials = &slots[0];
			set.SubmeshMaterialCount = 2;
			set.RendererId = meshRenderer.RendererId;
			set.Category = RenderCategories.Opaque;
			set.SortBatchKey = batchKey;
			set.WorldCenter = .(0.0f, 0.0f, -1.5f);
			set.WorldRadius = 1.0f;
			let halves = Render(fixture, meshRenderer, frame, scene);
			Test.Assert(halves.Right >= 0, scope $"{kind}: the set rendered");
			Test.Assert(halves.Right > (int)(cSize * cSize / 8), scope $"{kind}: instanced, the right half is its own green ({halves.Right})");
			Test.Assert(halves.Left == 0, scope $"{kind}: instanced, the left half is PBR, unlit ({halves.Left})");
		}
	}
}
