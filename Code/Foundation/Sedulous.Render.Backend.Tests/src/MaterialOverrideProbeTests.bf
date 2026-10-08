using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// A mesh's own material properties (MeshRenderData.Overrides) on real devices: three cards
/// share one grey material and the middle one overrides its BaseColor. The middle card turns
/// red while its neighbours stay grey (the override is its own, not the material's); a new
/// value (a new version) turns it green; clearing it brings it back to grey, like its
/// neighbours. Over frames on one renderer, so the instance it keeps per mesh and slot is
/// applied again, not rebuilt.
class MaterialOverrideProbeTests
{
	private const uint32 cSize = 96;

	/// A unit card in the XY plane facing plus Z, toward a camera looking down minus Z.
	///
	/// THE CALLER OWNS what comes back.
	private static StaticMesh Card()
	{
		let mesh = new StaticMesh();
		let white = 0xFFFFFFFF;
		let n = Float3(0, 0, 1);
		let t = Float4(1, 0, 0, 1);
		mesh.Vertices.Add(.(.(-0.5f, -0.5f, 0), n, .(0, 1), white, t));
		mesh.Vertices.Add(.(.(0.5f, -0.5f, 0), n, .(1, 1), white, t));
		mesh.Vertices.Add(.(.(0.5f, 0.5f, 0), n, .(1, 0), white, t));
		mesh.Vertices.Add(.(.(-0.5f, 0.5f, 0), n, .(0, 0), white, t));
		// The buffer appends through its own cursor within the count, so the count comes first.
		mesh.Indices.Resize(6);
		mesh.Indices.AddTriangle(0, 1, 2);
		mesh.Indices.AddTriangle(0, 2, 3);
		mesh.GenerateTangents();
		mesh.Bounds = AABB.FromCenterExtents(.(0, 0, 0), .(0.5f, 0.5f, 0.01f));
		mesh.SubMeshes.Add(.(0, 6, 0, .Triangles));
		return mesh;
	}

	/// The mean colour of each third's lit pixels (left, middle and right card), or null when
	/// a third has none.
	private static Float3[3]? Measure(CapturedImage image)
	{
		Float3[3] mean = .(.(0, 0, 0), .(0, 0, 0), .(0, 0, 0));
		uint32[3] count = .(0, 0, 0);
		for (uint32 y < cSize)
		{
			for (uint32 x < cSize)
			{
				let p = image.At(x, y);
				if ((uint32)p[0] + p[1] + p[2] <= 30)
					continue;
				let c = Math.Min(x * 3 / cSize, 2);
				mean[c] = mean[c] + Float3((float)p[0], (float)p[1], (float)p[2]);
				count[c]++;
			}
		}
		for (int c < 3)
		{
			if (count[c] == 0)
				return null;
			mean[c] = mean[c] * (1.0f / (float)count[c]);
		}
		return mean;
	}

	/// Grey: its channels within a few steps of each other.
	private static bool Grey(Float3 c) =>
		(Math.Abs(c.X - c.Y) < 8.0f) && (Math.Abs(c.Y - c.Z) < 8.0f) && (c.X > 40.0f);

	private static String Describe(Float3[3] thirds, String into)
	{
		for (let c in thirds)
			into.AppendF(" ({:F0}, {:F0}, {:F0})", c.X, c.Y, c.Z);
		return into;
	}

	[Test]
	public static void OneMeshsOwnPropertyChangesItAloneFollowsItsVersionAndClears()
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
		Test.Assert(materials.Initialize(device) case .Ok, scope $"{kind}: materials");
		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		Test.Assert(meshRenderer.Initialize() case .Ok, scope $"{kind}: mesh renderer");
		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(device, registry, 2);

		let card = Card();
		defer delete card;
		let material = MaterialPresets.CreatePbr("override.card", .(0.6f, 0.6f, 0.6f, 1), 0.0f, 0.9f);
		defer delete material;

		var tint = MaterialPropertyOverride();
		tint.Slot = 0;
		tint.Size = sizeof(Float4);
		tint.Name = scope String("BaseColor");
		var overrides = MaterialPropertyOverride[1](tint);

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		MeshRenderData middle = null;
		for (int32 i = -1; i <= 1; i++)
		{
			let at = Float3(1.15f * (float)i, 0.0f, -3.0f);
			let data = scene.Add<MeshRenderData>();
			data.World = Float4x4.Translation(at);
			data.Mesh = card;
			data.Material = material;
			data.RendererId = meshRenderer.RendererId;
			data.Category = RenderCategories.Opaque;
			// The three would batch.
			data.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(card),
				Internal.UnsafeCastToPtr(material));
			data.WorldCenter = at;
			data.WorldRadius = 1.0f;
			data.EntityId = (uint64)(i + 2);
			if (i == 0)
				middle = data;
		}

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
		textureDesc.Label = "override.target";
		var target = device.CreateTexture(textureDesc).Value;
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var targetView = device.CreateTextureView(target, viewDesc).Value;
		defer device.DestroyTextureView(ref targetView);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var fence = device.CreateFence(0).Value;
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);
		Test.Assert(queue != null, scope $"{kind}: a graphics queue");

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;

		var submitted = (uint64)0;
		// Two frames (both in flight slots), then the image.
		Float3[3]? Render()
		{
			for (uint32 i < 2)
			{
				var encoder = pool.CreateEncoder().Value;
				settings.TargetCurrentState = (submitted == 0) ? .Undefined : .CopySrc;
				frame.Begin(encoder, (uint32)(submitted % 2));
				frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
				frame.End();
				let commandBuffer = encoder.Finish();
				Test.Assert(commandBuffer != null, scope $"{kind}: the frame recorded");
				var buffers = ICommandBuffer[1](commandBuffer);
				submitted++;
				queue.Submit(.(&buffers[0], 1), fence, submitted);
				fence.Wait(submitted);
				pool.DestroyEncoder(ref encoder);
			}
			let image = RhiTestSupport.Readback(device, target, cSize, cSize);
			defer delete image;
			if ((image == null) || !image.Valid)
				return null;
			return Measure(image);
		}

		// Red, for the middle card alone.
		overrides[0].Value = .(0.9f, 0.05f, 0.05f, 1.0f);
		middle.Overrides = &overrides[0];
		middle.OverrideCount = 1;
		middle.OverrideVersion = 1;
		let red = Render();
		Test.Assert(red != null, scope $"{kind}: the red frame rendered, every card lit");
		let redReport = scope $"{kind}: red frame thirds{Describe(red.Value, .. scope .())}";
		Test.Assert(Grey(red.Value[0]) && Grey(red.Value[2]), redReport);
		Test.Assert(red.Value[1].X > red.Value[1].Y * 3.0f, redReport);

		// A new value (a new version): green.
		overrides[0].Value = .(0.05f, 0.9f, 0.05f, 1.0f);
		middle.OverrideVersion = 2;
		let green = Render();
		Test.Assert(green != null, scope $"{kind}: the green frame rendered, every card lit");
		let greenReport = scope $"{kind}: green frame thirds{Describe(green.Value, .. scope .())}";
		Test.Assert(green.Value[1].Y > green.Value[1].X * 3.0f, greenReport);
		Test.Assert(Grey(green.Value[0]), greenReport);

		// Cleared: grey, as its neighbours.
		middle.Overrides = null;
		middle.OverrideCount = 0;
		middle.OverrideVersion = 3;
		let cleared = Render();
		Test.Assert(cleared != null, scope $"{kind}: the cleared frame rendered, every card lit");
		let clearedReport = scope $"{kind}: cleared frame thirds{Describe(cleared.Value, .. scope .())}";
		Test.Assert(Grey(cleared.Value[1]), clearedReport);
		Test.Assert(Math.Abs(cleared.Value[1].X - cleared.Value[0].X) < 8.0f, clearedReport);

		device.WaitIdle();
	}
}
