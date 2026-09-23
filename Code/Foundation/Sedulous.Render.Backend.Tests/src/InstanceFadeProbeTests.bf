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

/// The per instance distance fade at the texel on real devices.
///
/// Three cards of ONE instanced set at three, six and twelve metres under a four to eight
/// metre window. The near one, at a density of one, draws; the middle one sits at a density
/// of a half with a rank of a half and collapses; the far one is past the window. With no
/// window at all, three draw.
///
/// The dissolve is per INSTANCE, at the instance's own distance, which is the seam free
/// replacement for the per chunk fade.
class InstanceFadeProbeTests
{
	private const uint32 cSize = 128;

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

	/// The lit pixels in the left, middle and right third of the frame, or null when the
	/// frame could not be built.
	private static uint32[3]? RenderCards(BackendProbeFixture fixture, float fadeStart,
		float fadeEnd)
	{
		let device = fixture.Device;
		let shaders = fixture.Shaders;

		let psoCache = scope PipelineStateCache(shaders, device);
		let materials = scope MaterialSystem();
		if (materials.Initialize(device) case .Err)
			return null;

		let meshRenderer = scope MeshRenderer(device, shaders, psoCache, materials, 2);
		if (meshRenderer.Initialize() case .Err)
			return null;

		let registry = scope RendererRegistry();
		registry.Register(meshRenderer);
		let frame = scope RenderFrame(device, registry, 2);

		let card = Card();
		defer delete card;
		let material = MaterialPresets.CreatePbr("fade.card", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.9f);
		defer delete material;

		// The instance order IS the rank order: the near card ranks a sixth, the middle a half
		// and the far five sixths.
		Float4x4[3] transforms = .(
			Float4x4.Translation(.(-1.6f, 0.0f, -3.0f)),
			Float4x4.Translation(.(0.0f, 0.0f, -6.0f)),
			Float4x4.Translation(.(3.2f, 0.0f, -12.0f)));

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		let set = scene.Add<MultiMeshRenderData>();
		if (set == null)
			return null;
		set.MultiMesh = true;
		set.Key = 0x7ADE;
		set.Transforms = &transforms[0];
		set.InstanceCount = 3;
		set.UploadCount = 3;
		set.Version = 1;
		set.Mesh = card;
		set.Material = material;
		set.RendererId = meshRenderer.RendererId;
		set.Category = RenderCategories.Opaque;
		// Every producer stamps this at extraction.
		set.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(card),
			Internal.UnsafeCastToPtr(material));
		set.WorldCenter = .(0, 0, -7);
		set.WorldRadius = 10.0f;
		set.FadeStart = fadeStart;
		set.FadeEnd = fadeEnd;

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
		textureDesc.Label = "fade.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return null;
		defer device.DestroyTexture(ref target);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return null;
		defer device.DestroyTextureView(ref targetView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return null;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return null;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return null;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.TaaEnabled = false;
		settings.Post.BloomEnabled = false;

		for (uint32 i = 0; i < 2; i++)
		{
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return null;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();

			let commandBuffer = encoder.Finish();
			if (commandBuffer == null)
			{
				pool.DestroyEncoder(ref encoder);
				return null;
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
			return null;

		uint32[3] columns = .(0, 0, 0);
		for (uint32 y < cSize)
		{
			for (uint32 x < cSize)
			{
				if (image.Luma(x, y) > 30)
					columns[Math.Min(x * 3 / cSize, 2)]++;
			}
		}
		return columns;
	}

	[Test]
	public static void ASetsCardsDissolveByTheirOwnDistanceAndRank()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		// No window at all: every card draws.
		let all = RenderCards(fixture, 0.0f, 0.0f);
		Test.Assert(all != null, scope $"{kind}: the unfaded frame rendered");
		Test.Assert(all.Value[0] > 0, scope $"{kind}: the near card");
		Test.Assert(all.Value[1] > 0, scope $"{kind}: the middle card");
		Test.Assert(all.Value[2] > 0, scope $"{kind}: the far card");

		let faded = RenderCards(fixture, 4.0f, 8.0f);
		Test.Assert(faded != null, scope $"{kind}: the faded frame rendered");
		// Inside the window, so untouched.
		Test.Assert(faded.Value[0] == all.Value[0], scope $"{kind}: the near card is untouched");
		// A density of a half at a rank of a half: collapsed.
		Test.Assert(faded.Value[1] == 0, scope $"{kind}: the middle card dissolved");
		// And past the window entirely.
		Test.Assert(faded.Value[2] == 0, scope $"{kind}: the far card is gone");
	}
}
