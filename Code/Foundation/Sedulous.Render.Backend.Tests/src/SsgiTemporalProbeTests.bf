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

/// SSGI under a small, bright, moving light, measured at the pixel on real devices through the
/// full RenderFrame chain: a lantern sized glowing cube walks along a grey wall over a grey floor
/// under a dim ambient, as Lamplight's guard carries his lantern past a hedge. The few GI rays
/// that hit so small and bright a source flash far above the bounce around them; history kept
/// those flashes and faded them slowly on still pixels, so a speckled smear trailed the lantern.
/// Measured: the specks around the light, the floor just behind it against just ahead of it,
/// the frame to frame steadiness once it stops, and how mottled its glow on the wall is then
/// and how much its pixels flicker.
class SsgiTemporalProbeTests
{
	private const uint32 cSize = 192;
	/// Frames before the light sets off, frames it walks, and frames it then stands.
	private const uint32 cSettle = 30;
	private const uint32 cWalk = 90;
	private const uint32 cStill = 40;
	private const float cStart = -1.4f;
	/// Metres a frame, about the guard's walk at 40 frames a second.
	private const float cStep = 0.03f;
	/// The light's line, 0.4 m off the wall's face.
	private const float cLaneZ = -1.2f;

	private struct Measure
	{
		/// Mean speck pixels a frame around the moving light.
		public float Specks;
		/// Mean floor luma 0.6 m behind it while it walks, and 0.6 m ahead.
		public float Behind;
		public float Ahead;
		/// Mean frame to frame change near it once it stands.
		public float Wobble;
		/// The settled floor luma beside it once it stands.
		public float NearStill;
		/// How mottled the lit area is once it stands (Blotchiness).
		public float Blotch;
		/// Mean per pixel frame to frame change on the wall once it stands.
		public float Shimmer;
	}

	private static ViewCamera Camera()
	{
		var camera = ViewCamera();
		camera.Position = .(0.0f, 2.0f, 2.2f);
		camera.View = Float4x4.LookAtRH(camera.Position, .(0.0f, 0.2f, -1.0f), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.FarZ = 100.0f;
		return camera;
	}

	/// The pixel a world point lands on, rows from the top as the readback is laid out.
	private static void PixelOf(ViewCamera camera, Float3 world, out int32 px, out int32 py)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * (camera.View * camera.Projection);
		px = (int32)((clip.X / clip.W * 0.5f + 0.5f) * (float)cSize);
		py = (int32)((0.5f - clip.Y / clip.W * 0.5f) * (float)cSize);
	}

	private static float Luma(CapturedImage image, int32 x, int32 y)
	{
		let p = image.At((uint32)Math.Clamp(x, 0, (int32)cSize - 1), (uint32)Math.Clamp(y, 0, (int32)cSize - 1));
		return (float)((int32)p[0] + p[1] + p[2]); // widened first: a byte sum wraps at 256
	}

	private static float BoxLuma(CapturedImage image, int32 cx, int32 cy, int32 half)
	{
		double sum = 0.0;
		for (int32 y = cy - half; y <= cy + half; y++)
		{
			for (int32 x = cx - half; x <= cx + half; x++)
				sum += Luma(image, x, y);
		}
		return (float)(sum / ((2 * half + 1) * (2 * half + 1)));
	}

	/// Pixels in a box that stand well above the mean of their 5x5 neighbourhood: the flashes.
	private static uint32 Specks(CapturedImage image, int32 x0, int32 y0, int32 x1, int32 y1)
	{
		uint32 count = 0;
		for (int32 y = y0; y <= y1; y++)
		{
			for (int32 x = x0; x <= x1; x++)
			{
				if (Luma(image, x, y) > BoxLuma(image, x, y, 2) + 30.0f)
					count++;
			}
		}
		return count;
	}

	/// Mottling at the scale of a few to twenty pixels: the mean gap between a 5x5 and a 21x21
	/// box average of the luma over a box. Clouds that a history held to a noisy neighbourhood
	/// leaves read here; fine pixel noise and the smooth falloff of a glow mostly do not.
	private static float Blotchiness(CapturedImage image, int32 x0, int32 y0, int32 x1, int32 y1)
	{
		double sum = 0.0;
		uint32 n = 0;
		for (int32 y = y0; y <= y1; y += 2)
		{
			for (int32 x = x0; x <= x1; x += 2)
			{
				sum += Math.Abs(BoxLuma(image, x, y, 2) - BoxLuma(image, x, y, 10));
				n++;
			}
		}
		return (n > 0) ? (float)(sum / n) : 0.0f;
	}

	/// Walks the lantern past the wall and measures what it leaves; false when the frame could
	/// not be built.
	private static bool Run(BackendProbeFixture fixture, bool ssgiOn, out Measure result)
	{
		result = .();
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
		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return false;
		let ssgi = scope SsgiPass(device, shaders);
		if (ssgi.Initialize() case .Err)
			return false;
		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null, null, null, null);
		frame.SetSsgi(ssgi);

		let plane = Primitives.Plane(20.0f, 20.0f);
		defer delete plane;
		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let grey = MaterialPresets.CreatePbr("ssgi.grey", .(0.5f, 0.5f, 0.5f, 1.0f), 0.0f, 0.95f);
		defer delete grey;
		let glass = MaterialPresets.CreatePbr("ssgi.lantern", .(1.0f, 0.75f, 0.4f, 1.0f), 0.0f, 0.9f);
		defer delete glass;
		glass.SetDefaultColor("EmissiveColor", .(5.0f, 3.75f, 2.0f, 1.0f)); // the guard's glass

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(0.05f, 0.05f, 0.06f));
		// Each with an id of its own: the renderer keys last frame's transform (the motion
		// vectors) by it, and a shared id made every mesh look moved.
		let floor = scene.Add<MeshRenderData>();
		floor.EntityId = 1;
		floor.World = Float4x4.Identity();
		floor.WorldRadius = 15.0f;
		floor.Mesh = plane;
		floor.Material = grey;
		floor.Category = RenderCategories.Opaque;
		let wall = scene.Add<MeshRenderData>();
		wall.EntityId = 2;
		wall.World = Float4x4.Scale(.(20.0f, 4.0f, 0.2f)) * Float4x4.Translation(.(0.0f, 2.0f, -1.7f));
		wall.WorldCenter = .(0.0f, 2.0f, -1.7f);
		wall.WorldRadius = 11.0f;
		wall.Mesh = cube;
		wall.Material = grey;
		wall.Category = RenderCategories.Opaque;
		let lantern = scene.Add<MeshRenderData>();
		lantern.EntityId = 3;
		lantern.WorldRadius = 0.2f;
		lantern.Mesh = cube;
		lantern.Material = glass;
		lantern.Category = RenderCategories.Opaque;
		void Place(float x)
		{
			lantern.World = Float4x4.Scale(.(0.14f, 0.2f, 0.14f)) * Float4x4.Translation(.(x, 0.45f, cLaneZ));
			lantern.WorldCenter = .(x, 0.45f, cLaneZ);
		}
		Place(cStart);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "ssgi.lantern.target";
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
		defer device.WaitIdle();

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;
		settings.Post.TaaEnabled = false;
		settings.Post.SsgiEnabled = ssgiOn;
		settings.Post.NeedsMotion = true;

		let camera = Camera();
		double specks = 0.0, behind = 0.0, ahead = 0.0, wobble = 0.0, still = 0.0, shimmer = 0.0;
		uint32 shimmerSamples = 0, walkSamples = 0, stillSamples = 0;
		let lastWall = scope List<float>();
		var previous = -1.0f;
		var x = cStart;
		for (uint32 i < cSettle + cWalk + cStill)
		{
			if ((i >= cSettle) && (i < cSettle + cWalk))
			{
				x += cStep;
				Place(x);
			}
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return false;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.Begin(encoder, i % 2);
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

			let walking = (i >= cSettle + 30) && (i < cSettle + cWalk); // past the start-up
			let standing = i >= cSettle + cWalk + 20;
			if (!walking && !standing)
				continue;
			let image = RhiTestSupport.Readback(device, target, cSize, cSize);
			defer delete image;
			if ((image == null) || !image.Valid)
				return false;
			PixelOf(camera, .(x, 0.0f, cLaneZ + 0.3f), let lx, let ly); // the floor in front of it
			PixelOf(camera, .(x - 0.6f, 0.0f, cLaneZ + 0.1f), let bx, let by); // behind
			PixelOf(camera, .(x + 0.6f, 0.0f, cLaneZ + 0.1f), let ax, let ay); // ahead
			if (walking)
			{
				specks += Specks(image, lx - 30, ly - 30, lx + 30, ly + 12);
				behind += BoxLuma(image, bx, by, 3);
				ahead += BoxLuma(image, ax, ay, 3);
				walkSamples++;
				continue;
			}

			let near = BoxLuma(image, lx, ly, 3);
			// Each wall pixel around it against the last frame: a flicker a patch average hides.
			PixelOf(camera, .(x, 0.45f, cLaneZ), let cx, let cy);
			int index = 0;
			let compare = !lastWall.IsEmpty;
			for (int32 py = cy - 50; py <= cy + 10; py++)
			{
				for (int32 px = cx - 50; px <= cx + 50; px++)
				{
					if ((Math.Abs(px - cx) < 12) && (py > cy - 14))
						continue; // the glowing cube itself
					let luma = Luma(image, px, py);
					if (compare)
					{
						shimmer += Math.Abs(luma - lastWall[index]);
						lastWall[index] = luma;
						shimmerSamples++;
					}
					else
					{
						lastWall.Add(luma);
					}
					index++;
				}
			}
			if (i + 1 == cSettle + cWalk + cStill)
			{
				// The wall and floor around it, the glowing cube itself left out.
				result.Blotch = 0.5f * (Blotchiness(image, cx - 50, cy - 50, cx - 12, cy + 30)
					+ Blotchiness(image, cx + 12, cy - 50, cx + 50, cy + 30));
			}
			if (previous >= 0.0f)
				wobble += Math.Abs(near - previous);
			previous = near;
			still += near;
			stillSamples++;
		}
		result.Specks = (float)(specks / Math.Max(walkSamples, 1));
		result.Behind = (float)(behind / Math.Max(walkSamples, 1));
		result.Ahead = (float)(ahead / Math.Max(walkSamples, 1));
		result.Wobble = (float)(wobble / Math.Max(stillSamples - 1, 1));
		result.NearStill = (float)(still / Math.Max(stillSamples, 1));
		result.Shimmer = (float)(shimmer / Math.Max(shimmerSamples, 1));
		return true;
	}

	[Test]
	public static void ASmallBrightLightWalkingByAWallLeavesNoSpecksAndNoTrail()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
		{
			let fixture = scope BackendProbeFixture(kind);
			if (!fixture.Ready)
				continue;
			// The scene alone: what the speck count reads as edges.
			let builtOff = Run(fixture, false, let off);
			let builtOn = Run(fixture, true, let on);
			Test.Assert(builtOff && builtOn, scope $"{kind}: the lantern rendered");
			if (!builtOff || !builtOn)
				continue;
			Console.WriteLine(scope $"{kind}: specks a frame {on.Specks} ({off.Specks} without SSGI); floor behind {on.Behind} vs ahead {on.Ahead}; standing: floor {on.NearStill}, wobble {on.Wobble}, mottling {on.Blotch} ({off.Blotch} without SSGI), shimmer a pixel {on.Shimmer}");
			Test.Assert(on.NearStill > off.NearStill + 10.0f, scope $"{kind}: the bounce is there to see");
			// No trail: behind the light no brighter than ahead of it (the trusted history left
			// it 38.6 behind against 23.7 ahead). No flashes on top of the scene's own edges, and
			// as steady as before once it stands.
			Test.Assert(on.Behind <= on.Ahead * 1.15f + 3.0f, scope $"{kind}: a trail, {on.Behind} behind against {on.Ahead} ahead");
			Test.Assert(on.Specks <= off.Specks + 5.0f, scope $"{kind}: {on.Specks} specks against {off.Specks}");
			Test.Assert(on.Wobble <= 1.5f, scope $"{kind}: wobble {on.Wobble}");
			// No clouds: the tight clip alone held the history to a noisy neighbourhood and left
			// the glow mottled (3.6 in Raptor, the blotchy walls in Lamplight); the a-trous
			// denoise after the accumulate smooths it.
			Test.Assert(on.Blotch <= 2.8f, scope $"{kind}: mottling {on.Blotch}");
			// No flicker: with the history that close to the frame, two rays a pixel left the
			// wall beside the glow flickering once it stood; four rays of half the steps (the
			// same taps) settle it.
			Test.Assert(on.Shimmer <= 0.7f, scope $"{kind}: shimmer {on.Shimmer}");
		}
	}
}
