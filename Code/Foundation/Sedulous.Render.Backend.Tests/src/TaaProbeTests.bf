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

/// TAA under a moving camera, proven at the pixel on real devices through the full RenderFrame
/// chain. Bright bars on a dark wall; the camera slides sideways exactly one pixel's width a
/// frame, so each frame is the last one shifted a pixel. With exact motion vectors the resolved
/// image moves with the scene and stays as steady as under a still camera; with wrong ones the
/// history lands in the wrong place, the clip throws it away, and the jittered frame shows
/// through (PaperKid's chase camera: steady titles, jittery levels). And with a second view
/// drawn before it on alternate frames (PaperKid's minimap, a render texture every other
/// frame), the main view keeps its own history by its key, not by its place in the frame's
/// list.
class TaaProbeTests
{
	private const uint32 cSize = 128;
	private const float cWallDistance = 5.0f;
	private const float cFov = 1.0472f; // 60 degrees
	/// TAA settles over the first ones.
	private const uint32 cFrames = 32;
	/// The last frames, read back and compared.
	private const uint32 cKept = 6;

	/// The world width one pixel covers on the wall: one frame's camera step.
	private static float PixelStep() => 2.0f * cWallDistance * Math.Tan(cFov * 0.5f) / (float)cSize;

	/// A second view drawn on alternate frames BEFORE the main one, into a target of its own
	/// (TAA off, as a render texture's camera). `Keyed` gives both views a history key, as the
	/// render subsystem does; otherwise they are known by their place in the list.
	private struct SideView
	{
		public bool On = false;
		public bool Keyed = false;

		public this() {}

		public this(bool on, bool keyed)
		{
			On = on;
			Keyed = keyed;
		}
	}

	/// Renders cFrames with the camera stepping `step` along +X a frame (TAA on or off) and
	/// reads back the last cKept into `kept`.
	private static bool RenderSlide(BackendProbeFixture fixture, float step, bool taaOn, SideView side,
		List<CapturedImage> kept)
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

		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return false;

		let taa = scope TaaPass(device, shaders);
		if (taa.Initialize() case .Err)
			return false;

		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null,
			taaOn ? taa : null, null, null);

		// A dark wall and bright vertical bars just in front of it, 0.3 m apart, 0.1 m wide.
		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let dark = MaterialPresets.CreatePbr("taa.wall", .(0.05f, 0.05f, 0.05f, 1.0f), 0.0f, 0.9f);
		defer delete dark;
		let bright = MaterialPresets.CreatePbr("taa.bar", .(0.9f, 0.9f, 0.9f, 1.0f), 0.0f, 0.9f);
		defer delete bright;

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		// Each draw is its own entity: the renderer keeps each one's previous world matrix (the
		// motion vectors) by entity id, so draws sharing an id would take each other's.
		var nextEntity = (uint64)1;
		void AddSlab(Float3 size, Float3 at, Material material)
		{
			let data = scene.Add<MeshRenderData>();
			data.EntityId = nextEntity++;
			data.World = Float4x4.Scale(size) * Float4x4.Translation(at);
			data.WorldCenter = at;
			data.WorldRadius = Length(size);
			data.Mesh = cube;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
		}
		AddSlab(.(40.0f, 20.0f, 0.1f), .(0.0f, 0.0f, -cWallDistance - 0.05f), dark);
		for (int32 b = -20; b <= 20; b++)
			AddSlab(.(0.1f, 20.0f, 0.02f), .(0.3f * (float)b, 0.0f, -cWallDistance + 0.01f), bright);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "taa.probe.target";
		if (!(device.CreateTexture(textureDesc) case .Ok(var target)))
			return false;
		defer device.DestroyTexture(ref target);
		textureDesc.Label = "taa.probe.side";
		if (!(device.CreateTexture(textureDesc) case .Ok(var sideTarget)))
			return false;
		defer device.DestroyTexture(ref sideTarget);

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(target, viewDesc) case .Ok(var targetView)))
			return false;
		defer device.DestroyTextureView(ref targetView);
		if (!(device.CreateTextureView(sideTarget, viewDesc) case .Ok(var sideView)))
			return false;
		defer device.DestroyTextureView(ref sideView);

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return false;
		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return false;
		defer device.DestroyFence(ref fence);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return false;

		var settings = ViewSettings();
		settings.Clear = ClearColor.Black;
		settings.TargetTexture = target;
		settings.TargetFinalState = .CopySrc;
		settings.Post.BloomEnabled = false;
		settings.Post.TaaEnabled = taaOn;
		settings.Post.NeedsMotion = taaOn;
		settings.HistoryKey = side.Keyed ? 1 : 0;

		var sideSettings = ViewSettings();
		sideSettings.Clear = ClearColor.Black;
		sideSettings.TargetTexture = sideTarget;
		sideSettings.TargetFinalState = .CopySrc;
		sideSettings.Post.BloomEnabled = false;
		sideSettings.Post.TaaEnabled = false;
		sideSettings.HistoryKey = side.Keyed ? 2 : 0;
		var sideDrawn = false;

		// Looking down at the wall from above: nothing like the main view.
		var sideCamera = ViewCamera();
		sideCamera.Position = .(0.0f, 20.0f, -cWallDistance);
		sideCamera.View = Float4x4.LookAtRH(sideCamera.Position, .(0.0f, 0.0f, -cWallDistance), .(0, 0, -1));
		sideCamera.Projection = Float4x4.PerspectiveFovRH(cFov, 1.0f, 0.1f, 100.0f);

		for (uint32 i = 0; i < cFrames; i++)
		{
			let eye = Float3(step * (float)i, 0.0f, 0.0f);
			var camera = ViewCamera();
			camera.Position = eye;
			camera.View = Float4x4.LookAtRH(eye, eye + Float3(0, 0, -1), .(0, 1, 0));
			camera.Projection = Float4x4.PerspectiveFovRH(cFov, 1.0f, 0.1f, 100.0f);

			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return false;

			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			frame.SetDeltaSeconds(1.0f / 60.0f);
			frame.Begin(encoder, i % 2);
			if (side.On && (i % 2 == 0))
			{
				sideSettings.TargetCurrentState = sideDrawn ? .CopySrc : .Undefined;
				sideDrawn = true;
				frame.AddView(scene, sideCamera, sideSettings, sideView, .RGBA8Unorm, cSize, cSize);
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

			if (i + cKept >= cFrames)
				kept.Add(RhiTestSupport.Readback(device, target, cSize, cSize));
		}

		device.WaitIdle();
		return true;
	}

	/// How far the resolved image strays from moving with the scene: the mean difference
	/// between each frame and the one before shifted `shift` pixels left (the scene's motion),
	/// over the interior columns.
	private static float MeanStray(List<CapturedImage> frames, uint32 shift)
	{
		double sum = 0.0;
		var count = (uint32)0;
		for (int f = 1; f < frames.Count; f++)
		{
			for (uint32 y = 8; y + 8 < cSize; y++)
			{
				for (uint32 x = 8; x + 8 < cSize; x++)
				{
					let now = frames[f].At(x, y);
					let before = frames[f - 1].At(x + shift, y);
					for (int c < 3)
						sum += Math.Abs((int)now[c] - (int)before[c]);
					count++;
				}
			}
		}
		return (count > 0) ? (float)(sum / count) : 0.0f;
	}

	/// The stray of one run, or -1 when it did not render.
	private static float Stray(BackendProbeFixture fixture, float step, bool taaOn, SideView side, uint32 shift)
	{
		let frames = scope List<CapturedImage>();
		defer { for (let image in frames) delete image; }
		if (!RenderSlide(fixture, step, taaOn, side, frames) || (frames.Count != cKept))
			return -1.0f;
		for (let image in frames)
		{
			if ((image == null) || !image.Valid)
				return -1.0f;
		}
		return MeanStray(frames, shift);
	}

	[Test]
	public static void UnderACameraMovingAPixelAFrameTheResolvedImageMovesWithTheScene()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			SlideOn(kind);
	}

	private static void SlideOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let still = Stray(fixture, 0.0f, true, .(), 0);
		let moving = Stray(fixture, PixelStep(), true, .(), 1);
		let raw = Stray(fixture, PixelStep(), false, .(), 1);
		Test.Assert((still >= 0.0f) && (moving >= 0.0f) && (raw >= 0.0f), scope $"{kind}: rendered");
		// Under a camera moving one pixel a frame, the resolved image moves with the scene
		// nearly as steadily as under a still camera (resampling the history at sub pixel
		// positions costs a little). Dropping history by motion measured in UV made it five
		// times worse: the jitter showed through.
		Test.Assert(moving < still * 2.5f,
			scope $"{kind}: frame to frame stray, TAA still {still}, TAA moving {moving}, no TAA moving {raw}");
	}

	[Test]
	public static void AViewDrawnBeforeTheMainOneOnAlternateFramesLeavesItsHistoryAlone()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			SideViewOn(kind);
	}

	private static void SideViewOn(ProbeBackend kind)
	{
		let fixture = scope BackendProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let alone = Stray(fixture, 0.0f, true, .(), 0);
		let byOrder = Stray(fixture, 0.0f, true, .(true, false), 0);
		let byKey = Stray(fixture, 0.0f, true, .(true, true), 0);
		Test.Assert((alone >= 0.0f) && (byOrder >= 0.0f) && (byKey >= 0.0f), scope $"{kind}: rendered");
		let report = scope $"{kind}: still TAA stray, alone {alone}, with an alternate frame view before it by order {byOrder}, by key {byKey}";
		// Keyed, the main view keeps its history whatever is drawn before it: as steady as alone.
		Test.Assert(byKey < alone + 0.5f, report);
		// By order it alternates between two places, reading the other view's camera and history.
		Test.Assert(byOrder > alone * 3.0f, report);
	}
}
