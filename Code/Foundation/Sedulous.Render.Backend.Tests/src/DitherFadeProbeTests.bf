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

/// A mesh's dithered fade (MeshRenderData.Fade, the cutaway's knob) on real devices: it thins
/// the mesh's pixels by a screen door pattern.
///
/// Three cards side by side, solid, faded a half and faded out, with a solid card behind the
/// faded out one. The solid card is untouched, the half faded one keeps about half its pixels,
/// and the faded out one draws none and hides none of the card behind it, so it stayed out of
/// the depth prepass too. The two faded cards share one instanced draw, each with its own fade;
/// drawn apart (each its own material), each is a lone draw by the single path, which thins
/// them the same.
class DitherFadeProbeTests
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

	/// The lit pixels in the left, middle and right third of the frame, or null when the frame
	/// could not be built. The cards stand at three metres: solid on the left, `middleFade` in
	/// the middle, `rightFade` on the right (none when negative), and a wider solid card six
	/// metres away behind the right one. `apart`: the middle and right cards each have a
	/// material of their own, so neither batches.
	private static uint32[3]? RenderCards(BackendProbeFixture fixture, float middleFade,
		float rightFade, bool apart = false)
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
		let material = MaterialPresets.CreatePbr("dither.card", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.9f);
		defer delete material;
		let middleMaterial = MaterialPresets.CreatePbr("dither.middle", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.9f);
		defer delete middleMaterial;
		let rightMaterial = MaterialPresets.CreatePbr("dither.right", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.9f);
		defer delete rightMaterial;

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		var nextEntity = (uint64)1;
		bool Add(Float3 at, float scale, float fade, Material mat)
		{
			let data = scene.Add<MeshRenderData>();
			if (data == null)
				return false;
			data.World = Float4x4.Scale(.(scale, scale, scale)) * Float4x4.Translation(at);
			data.Mesh = card;
			data.Material = mat;
			data.Fade = fade;
			data.RendererId = meshRenderer.RendererId;
			// As extraction routes it: a faded opaque mesh draws Masked, out of the prepass.
			data.Category = (fade > 0.0f) ? RenderCategories.Masked : RenderCategories.Opaque;
			data.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(card),
				Internal.UnsafeCastToPtr(mat));
			data.WorldCenter = at;
			data.WorldRadius = scale;
			data.EntityId = nextEntity++;
			return true;
		}
		if (!Add(.(-1.15f, 0.0f, -3.0f), 1.0f, 0.0f, material) ||
			!Add(.(0.0f, 0.0f, -3.0f), 1.0f, middleFade, apart ? middleMaterial : material))
			return null;
		if ((rightFade >= 0.0f) &&
			!Add(.(1.15f, 0.0f, -3.0f), 1.0f, rightFade, apart ? rightMaterial : material))
			return null;
		if (!Add(.(2.3f, 0.0f, -6.0f), 1.6f, 0.0f, material))
			return null;

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
	public static void AFadedMeshThinsByItsFadeAndHidesNothingWhenFadedOut()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			ProbeOn(kind);
	}

	private static void ProbeOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		// Every card solid, none in front on the right.
		let solid = RenderCards(fixture, 0.0f, -1.0f);
		Test.Assert(solid != null, scope $"{kind}: the solid frame rendered");
		Test.Assert((solid.Value[0] > 0) && (solid.Value[1] > 0) && (solid.Value[2] > 0),
			scope $"{kind}: every card draws");

		let faded = RenderCards(fixture, 0.5f, 1.0f);
		Test.Assert(faded != null, scope $"{kind}: the faded frame rendered");
		let report = scope $"{kind}: lit thirds solid {solid.Value[0]} {solid.Value[1]} {solid.Value[2]}, faded {faded.Value[0]} {faded.Value[1]} {faded.Value[2]}";
		// The solid card: untouched.
		Test.Assert(faded.Value[0] == solid.Value[0], report);
		// Half faded: half of every 4x4 cell, so very nearly half the card.
		Test.Assert(faded.Value[1] * 10 >= solid.Value[1] * 4, report);
		Test.Assert(faded.Value[1] * 10 <= solid.Value[1] * 6, report);
		// Faded out: none of its pixels, and the card behind shows whole (no prepass depth).
		Test.Assert(faded.Value[2] == solid.Value[2], report);
		// Each a lone draw (the single path): thinned exactly as in the shared instanced draw.
		let apart = RenderCards(fixture, 0.5f, 1.0f, true);
		Test.Assert(apart != null, scope $"{kind}: the apart frame rendered");
		let apartReport = scope $"{report}, apart {apart.Value[0]} {apart.Value[1]} {apart.Value[2]}";
		Test.Assert(apart.Value[0] == faded.Value[0], apartReport);
		Test.Assert(apart.Value[1] == faded.Value[1], apartReport);
		Test.Assert(apart.Value[2] == faded.Value[2], apartReport);
	}
}
