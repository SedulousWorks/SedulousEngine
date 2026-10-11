using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// A view drawn at a scene size of its own and scaled into a rectangle of a target of another
/// shape: a fixed render resolution letterboxed into a wider window. The whole chain runs at
/// the scene size and one present pass scales the image into the rectangle, clearing the rest
/// of the target black.
///
/// The orientation probe's scene (a bright cube above, a dim plane below) at 32 x 32, into the
/// middle 64 x 64 of a 128 x 64 target, on each real backend (the web player presents through
/// WebGPU): the bars stay black, the rectangle holds the scene, and the present keeps it upright;
/// turned three quarters (a landscape game on a portrait screen), the scene's top lands on the
/// rectangle's left.
class ScaledViewProbeTests
{
	private const uint32 cTargetWidth = 128;
	private const uint32 cTargetHeight = 64;
	private const uint32 cScene = 32;
	/// The letterbox: the square scene fits the target's height, centred.
	private const int32 cRectX = 32;
	private const uint32 cRectSize = 64;

	[Test]
	public static void AScaledViewFillsItsRectangleUprightOrTurnedAndLeavesTheBarsBlack()
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
		let tonemap = scope TonemapPass(device, shaders, 2);
		Test.Assert(tonemap.Initialize() case .Ok);
		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null, null, null, null);

		let cubeMesh = Primitives.Cube(1.6f);
		defer delete cubeMesh;
		let planeMesh = Primitives.Plane(24.0f, 24.0f);
		defer delete planeMesh;
		let cubeMaterial = MaterialPresets.CreatePbr("probe.cube", .(1, 1, 1, 1), 0.0f, 0.6f);
		defer delete cubeMaterial;
		// 18% grey (linear 0.18), written as the sRGB colour it is entered as.
		let planeMaterial = MaterialPresets.CreatePbr("probe.plane", .(0.461f, 0.461f, 0.461f, 1), 0.0f, 0.8f);
		defer delete planeMaterial;

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		{
			let cube = scene.Add<MeshRenderData>();
			cube.World = Float4x4.Translation(.(0.0f, 2.2f, 0.0f));
			cube.WorldCenter = .(0.0f, 2.2f, 0.0f);
			cube.Mesh = cubeMesh;
			cube.Material = cubeMaterial;
			cube.Category = RenderCategories.Opaque;
			let plane = scene.Add<MeshRenderData>();
			plane.World = Float4x4.Translation(.(0.0f, -1.0f, 0.0f));
			plane.WorldCenter = .(0.0f, -1.0f, 0.0f);
			plane.Mesh = planeMesh;
			plane.Material = planeMaterial;
			plane.Category = RenderCategories.Opaque;
		}

		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0.5f, 7), .(0, 0.5f, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0.5f, 7);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cTargetWidth;
		textureDesc.Height = cTargetHeight;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "scaled.target";
		Test.Assert(device.CreateTexture(textureDesc) case .Ok(var target));
		defer device.DestroyTexture(ref target);
		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		Test.Assert(device.CreateTextureView(target, viewDesc) case .Ok(var targetView));
		defer device.DestroyTextureView(ref targetView);
		Test.Assert(device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer device.DestroyCommandPool(ref pool);
		Test.Assert(device.CreateFence(0) case .Ok(var fence));
		defer device.DestroyFence(ref fence);
		let queue = device.GetQueue(.Graphics);

		// Upright, then turned as a landscape game is on a portrait screen: the same square scene
		// and rectangle, so only the present's turn differs.
		uint64 submitted = 0; // the fence's value only rises
		for (let turn in ContentRotation[2](.None, .ThreeQuarter))
		{
			// The scene's clear is BLUE, so the bars being black is the present's clear, not the
			// scene's leaking out of its rectangle.
			var settings = ViewSettings();
			settings.Clear = .(0.0f, 0.0f, 1.0f, 1.0f);
			settings.TargetTexture = target;
			settings.TargetFinalState = .CopySrc;
			settings.Post.BloomEnabled = false;
			settings.ViewportX = cRectX;
			settings.ViewportY = 0;
			settings.ViewportWidth = cRectSize;
			settings.ViewportHeight = cRectSize;
			settings.Scene = .(cScene, cScene);
			settings.Scene.Rotation = turn;

			for (uint32 i < 2)
			{
				Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
				settings.TargetCurrentState = (submitted == 0) ? .Undefined : .CopySrc;
				frame.Begin(encoder, i % 2);
				frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cTargetWidth, cTargetHeight);
				frame.End();
				let commandBuffer = encoder.Finish();
				Test.Assert(commandBuffer != null);
				var buffers = ICommandBuffer[1](commandBuffer);
				submitted++;
				queue.Submit(.(&buffers[0], 1), fence, submitted);
				fence.Wait(submitted);
				pool.DestroyEncoder(ref encoder);
			}

			let image = RhiTestSupport.Readback(device, target, cTargetWidth, cTargetHeight);
			defer delete image;
			Test.Assert(image.Valid);

			double bars = 0.0;
			double top = 0.0;
			double bottom = 0.0;
			double left = 0.0;
			double right = 0.0;
			double blue = 0.0;
			for (uint32 y < cTargetHeight)
			{
				for (uint32 x < cTargetWidth)
				{
					let p = image.At(x, y);
					let inside = ((int32)x >= cRectX) && (x < (uint32)cRectX + cRectSize);
					// The objects by red and green alone, which the blue clear behind them has none of.
					let objects = (double)p[0] + p[1];
					if (!inside)
					{
						bars += objects + p[2];
						continue;
					}
					if (y < cTargetHeight / 2)
						top += objects;
					else
						bottom += objects;
					if ((int32)x < cRectX + (int32)(cRectSize / 2))
						left += objects;
					else
						right += objects;
					blue += p[2];
				}
			}

			let at = scope $"{kind} {turn}: top {top}, bottom {bottom}, left {left}, right {right}";
			Test.Assert(bars == 0.0, scope $"{at}: the bars are black ({bars})");
			Test.Assert(blue > 0.0, scope $"{at}: the scene's own clear fills the rectangle behind it");
			if (turn == .None)
			{
				Test.Assert(top > 20000.0, scope $"{at}: the cube lights the rectangle's top half");
				Test.Assert(bottom > top * 1.3, scope $"{at}: and the plane dominates below it: upright");
			}
			else
			{
				// Turned three quarters (the game's top on the screen's left): the cube on the
				// rectangle's left half, the plane on its right.
				Test.Assert(left > 20000.0, scope $"{at}: the cube lights the rectangle's left half");
				Test.Assert(right > left * 1.3, scope $"{at}: and the plane dominates its right: turned");
			}
		}
		device.WaitIdle();
	}
}
