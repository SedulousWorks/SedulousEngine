using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// GPU picking proven at the texel on real devices, through the FULL frame chain: the pick
/// system's cropped id pass, the graph copy, and the ring retired readback.
///
/// - A near cube over a far cube at the centre: the near one answers, by its own depth test,
///   with its entity index AND generation.
/// - Three identical cubes side by side, one instanced run: each column answers its own id,
///   the instance stepped ids being per instance, not per run.
/// - A pixel where nothing is drawn answers with no hits: the clear is nothing.
/// - A rect over the whole view answers every entity once.
/// - A second request on the same view in the same frame is answered independently.
class PickProbeTests
{
	private const uint32 cSize = 128;

	private class Item
	{
		public StaticMesh Mesh;
		public Material Material;
		public Float4x4 World = .Identity();
		public Float3 Center = .(0, 0, 0);
		public float Radius = 1.0f;
		public uint32 EntityIndex = 0;
		public uint32 Generation = 0;
	}

	private class Probe
	{
		public PickRect Rect;
		public uint32 Id = PickSystem.cInvalidRequest;
		public PickResult Result = new .() ~ delete _;
		public bool Answered = false;

		public this(PickRect rect) { Rect = rect; }
	}

	private static Item Cube(StaticMesh mesh, float radius, Float3 at, Material material,
		uint32 index, uint32 generation)
	{
		let item = new Item();
		item.Mesh = mesh;
		item.Material = material;
		item.World = Float4x4.Translation(at);
		item.Center = at;
		item.Radius = radius;
		item.EntityIndex = index;
		item.Generation = generation;
		return item;
	}

	private static ViewCamera Camera()
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, 0);
		camera.FarZ = 100.0f;
		return camera;
	}

	/// The view pixel, y down, a world point lands on.
	private static PickRect PixelRect(ViewCamera camera, Float3 world)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * camera.ViewProjection;
		let ndcX = clip.X / clip.W;
		let ndcY = clip.Y / clip.W;
		let px = Math.Clamp((ndcX * 0.5f + 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
		let py = Math.Clamp((0.5f - ndcY * 0.5f) * (float)cSize, 0.0f, (float)(cSize - 1));
		return .((int32)px, (int32)py, 1, 1);
	}

	/// Renders the scene for four frames with the probes requested before the first, and
	/// collects each probe's answer as it lands, on the ring retire two frames on.
	private static bool RenderAndPick(BackendProbeFixture fixture, List<Item> items,
		ViewCamera camera, List<Probe> probes)
	{
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return false;

		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return false;

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);

		// Declared BEFORE the frame, so destroyed after it: the readback buffers outlive the
		// graph.
		let pick = scope PickSystem(device);

		let frame = scope RenderFrame(device, registry, 2);
		frame.SetPick(pick);

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		for (let item in items)
		{
			let data = scene.Add<MeshRenderData>();
			data.World = item.World;
			data.WorldCenter = item.Center;
			data.WorldRadius = item.Radius;
			data.Mesh = item.Mesh;
			data.Material = item.Material;
			data.Category = RenderCategories.Opaque;
			data.EntityId = EntityTag.Pack(item.EntityIndex, item.Generation);
		}

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "pick.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return false;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return false;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return false;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return false;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return false;

		int viewportKey = 0;
		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;
		settings.ViewportKey = &viewportKey;

		for (let probe in probes)
		{
			probe.Id = pick.Request(&viewportKey, probe.Rect);
			if (probe.Id == PickSystem.cInvalidRequest)
				return false;
		}

		// Frame nought declares the passes; frame one is the other ring slot; frame two's
		// Begin retires them. One spare frame proves nothing answers twice.
		for (uint32 i = 0; i < 4; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return false;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;

			frame.Begin(encoder, i % 2);
			for (let probe in probes)
			{
				if (!probe.Answered && pick.TryTakeResult(probe.Id, probe.Result))
					probe.Answered = true;
			}
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return false;
			}

			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(.(&buffers[0], 1), fence, (uint64)i + 1);
			fence.Wait((uint64)i + 1);
			pool.DestroyEncoder(ref encoder);
		}

		device.WaitIdle();
		return true;
	}

	private static bool HitIs(PickResult r, uint32 index, uint32 generation)
	{
		return (r.Hits.Count == 1) && (r.Hits[0].EntityIndex == index)
			&& (r.Hits[0].Generation == generation);
	}

	private static bool Contains(PickResult r, uint32 index, uint32 generation)
	{
		for (let h in r.Hits)
		{
			if ((h.EntityIndex == index) && (h.Generation == generation))
				return true;
		}
		return false;
	}

	[Test]
	public static void EntityIdsUnderAPixelAndARectNearWinsInstancesDistinct()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		// A near red cube, entity 7 generation 3, over a far big blue cube, entity 200
		// generation 1, at the centre; three identical grey cubes, one instanced run of the
		// same mesh and material, in a row below.
		let red = MaterialPresets.CreatePbr("pick.red", .(1, 0, 0, 1), 0.0f, 0.9f);
		defer delete red;
		let blue = MaterialPresets.CreatePbr("pick.blue", .(0, 0, 1, 1), 0.0f, 0.9f);
		defer delete blue;
		let grey = MaterialPresets.CreatePbr("pick.grey", .(0.5f, 0.5f, 0.5f, 1), 0.0f, 0.9f);
		defer delete grey;
		let nearMesh = Primitives.Cube(0.6f);
		defer delete nearMesh;
		let farMesh = Primitives.Cube(3.0f);
		defer delete farMesh;
		let rowMesh = Primitives.Cube(1.2f);
		defer delete rowMesh;

		let items = scope List<Item>();
		defer { ClearAndDeleteItems!(items); }
		items.Add(Cube(nearMesh, 0.6f, .(0, 0, -3.0f), red, 7, 3));
		items.Add(Cube(farMesh, 3.0f, .(0, 0, -8.0f), blue, 200, 1));
		let rowAt = Float3[3](.(-2.4f, -3.2f, -7.0f), .(0.0f, -3.2f, -7.0f), .(2.4f, -3.2f, -7.0f));
		for (uint32 k < 3)
			items.Add(Cube(rowMesh, 1.2f, rowAt[k], grey, 30 + k, 2));
		let camera = Camera();

		let probes = scope List<Probe>();
		defer { ClearAndDeleteItems!(probes); }
		probes.Add(new Probe(.(cSize / 2, cSize / 2, 1, 1)));      // 0: centre
		probes.Add(new Probe(.(cSize / 2, cSize / 2 - 20, 1, 1))); // 1: the far cube only
		probes.Add(new Probe(PixelRect(camera, rowAt[0])));        // 2: row left
		probes.Add(new Probe(PixelRect(camera, rowAt[1])));        // 3: row middle
		probes.Add(new Probe(PixelRect(camera, rowAt[2])));        // 4: row right
		probes.Add(new Probe(.(1, 1, 1, 1)));                      // 5: nothing
		probes.Add(new Probe(.(0, 0, cSize, cSize)));              // 6: everything
		probes.Add(new Probe(.(cSize / 2, cSize / 2, 1, 1)));      // 7: the centre again

		Test.Assert(RenderAndPick(fixture, items, camera, probes), scope $"{kind}: rendered");

		for (int i < probes.Count)
		{
			Test.Assert(probes[i].Answered, scope $"{kind} probe {i}: answered");
			Test.Assert(probes[i].Result.Rendered, scope $"{kind} probe {i}: rendered");
		}
		Test.Assert(HitIs(probes[0].Result, 7, 3), scope $"{kind}: the near cube, with its generation");
		Test.Assert(HitIs(probes[1].Result, 200, 1), scope $"{kind}: the far cube shows around the near one");
		Test.Assert(HitIs(probes[2].Result, 30, 2), scope $"{kind}: each instance of the run answers itself");
		Test.Assert(HitIs(probes[3].Result, 31, 2), scope $"{kind}: row middle");
		Test.Assert(HitIs(probes[4].Result, 32, 2), scope $"{kind}: row right");
		Test.Assert(probes[5].Result.Hits.IsEmpty, scope $"{kind}: a corner nothing reached");
		Test.Assert(probes[6].Result.Hits.Count == 5, scope $"{kind}: every entity once");
		Test.Assert(Contains(probes[6].Result, 7, 3), scope $"{kind}: rect has the near cube");
		Test.Assert(Contains(probes[6].Result, 200, 1), scope $"{kind}: rect has the far cube");
		Test.Assert(Contains(probes[6].Result, 30, 2), scope $"{kind}: rect has row left");
		Test.Assert(Contains(probes[6].Result, 31, 2), scope $"{kind}: rect has row middle");
		Test.Assert(Contains(probes[6].Result, 32, 2), scope $"{kind}: rect has row right");
		Test.Assert(HitIs(probes[7].Result, 7, 3), scope $"{kind}: two requests, one frame, both answered");
	}
}
