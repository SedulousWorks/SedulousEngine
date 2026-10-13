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

/// Ambient occlusion and TAA under an orthographic camera, at the pixel on real devices through
/// the whole frame chain. Both passes once assumed a perspective eye (a divide by view depth, a
/// view vector to the eye, a perspective depth linearization), so an orthographic view ran
/// without them.
/// - AO: an inside corner seen through an orthographic camera takes the occlusion a nearly
///   orthographic perspective view of it takes, GTAO and SSAO both.
/// - TAA: a still orthographic view settles on what it shows without TAA, its slanted edge
///   antialiased and nothing else changed: the jitter in the row an orthographic projection
///   needs (a constant shift, not one that grows with depth) and its linear depth in the
///   disocclusion test.
class OrthographicProbeTests
{
	private const uint32 cSize = 128;

	private struct Spec
	{
		public AoMode Ao;
		public bool Taa;
		public bool Perspective;
		public bool Coloured;
	}

	/// Two slabs meeting at a vertical edge (the corner of x and z at or above nought), seen from
	/// inside the corner along its bisector through an orthographic camera 4 m tall and 30 m back:
	/// the edge stands at the screen's centre column, a wall to each side. Flat white ambient, no
	/// lights. Rendered through forward and tonemap, plus AO or TAA when asked; THE CALLER OWNS
	/// what comes back, null when the frame could not be built.
	private static CapturedImage Render(BackendProbeFixture fixture, Spec spec)
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
		let tonemap = scope TonemapPass(device, shaders, 2);
		if (tonemap.Initialize() case .Err)
			return null;
		let ao = scope AoPass(device, shaders);
		if (ao.Initialize() case .Err)
			return null;
		let taa = scope TaaPass(device, shaders);
		if (taa.Initialize() case .Err)
			return null;
		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null,
			spec.Taa ? taa : null, ao, null);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let wallX = MaterialPresets.CreatePbr("probe.wallX", spec.Coloured ? .(0.8f, 0.05f, 0.05f, 1.0f) : .(0.5f, 0.5f, 0.5f, 1.0f), 0.0f, 0.9f);
		defer delete wallX;
		let wallZ = MaterialPresets.CreatePbr("probe.wallZ", spec.Coloured ? .(0.05f, 0.05f, 0.8f, 1.0f) : .(0.5f, 0.5f, 0.5f, 1.0f), 0.0f, 0.9f);
		defer delete wallZ;

		let scene = scope ExtractedScene();
		scene.SetAmbient(.(1.0f, 1.0f, 1.0f));
		var nextEntity = (uint64)1;
		void AddSlab(Float3 size, Float3 at, Float3 center, Material material)
		{
			let data = scene.Add<MeshRenderData>();
			data.EntityId = nextEntity++; // TAA keeps each draw's previous world by its entity
			data.World = Float4x4.Scale(size) * Float4x4.Translation(at);
			data.WorldCenter = center;
			data.WorldRadius = 6.0f;
			data.Mesh = cube;
			data.Material = material;
			data.Category = RenderCategories.Opaque;
		}
		AddSlab(.(0.1f, 8.0f, 8.0f), .(-0.05f, 0.0f, 4.0f), .(0.0f, 0.0f, 4.0f), wallX);
		AddSlab(.(8.0f, 8.0f, 0.1f), .(4.0f, 0.0f, -0.05f), .(4.0f, 0.0f, 0.0f), wallZ);

		var camera = ViewCamera();
		camera.Position = Normalized(Float3(1.0f, 0.0f, 1.0f)) * 30.0f;
		// Rolled a little when coloured, so the edge between the walls runs slanted across the
		// pixel centres (a pixel aligned edge gives a half pixel jitter nothing to antialias).
		let up = spec.Coloured ? Normalized(Float3(0.12f, 1.0f, -0.12f)) : Float3(0, 1, 0);
		camera.View = Float4x4.LookAtRH(camera.Position, .(0, 0, 0), up);
		// The same 4 m at the edge either way: seen from 30 m, about 7.6 degrees.
		camera.Projection = spec.Perspective ? Float4x4.PerspectiveFovRH(2.0f * Atan2(2.0f, 30.0f), 1.0f, 0.1f, 100.0f)
			: Float4x4.OrthographicRH(4.0f, 4.0f, 0.1f, 100.0f);
		camera.FarZ = 100.0f;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "orthographic.probe.target";
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
		settings.Post.BloomEnabled = false;
		settings.Post.AoMode = (uint32)spec.Ao;
		settings.Post.AoStrength = 1.0f;
		settings.Post.TaaEnabled = spec.Taa;
		settings.Post.NeedsMotion = spec.Taa;

		// TAA settles over its history on a still camera.
		let frames = spec.Taa ? (uint32)24 : (uint32)2;
		for (uint32 i < frames)
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
		device.WaitIdle();
		if ((image != null) && !image.Valid)
		{
			delete image;
			return null;
		}
		return image;
	}

	/// Mean r+g+b over columns [x0, x1), every row.
	private static float ColumnsMean(CapturedImage image, uint32 x0, uint32 x1)
	{
		double sum = 0.0;
		uint32 n = 0;
		for (uint32 x = x0; x < x1; x++)
		{
			for (uint32 y < image.Height)
			{
				let p = image.At(x, y);
				sum += (int32)p[0] + p[1] + p[2]; // widened first: a byte sum wraps at 256
				n++;
			}
		}
		return (n > 0) ? (float)(sum / n) : 0.0f;
	}

	/// How much AO takes off the edge and the open wall, on over off.
	private static void MeasureAo(BackendProbeFixture fixture, AoMode mode, bool perspective, out float edge, out float open, out float edgeOff)
	{
		edge = open = edgeOff = 0.0f;
		var spec = Spec();
		spec.Perspective = perspective;
		let off = Render(fixture, spec);
		defer delete off;
		spec.Ao = mode;
		let on = Render(fixture, spec);
		defer delete on;
		Test.Assert((off != null) && (on != null), scope $"{fixture.Kind}: the corner rendered");
		if ((off == null) || (on == null))
			return;
		let middle = cSize / 2;
		edgeOff = ColumnsMean(off, middle - 4, middle + 4);
		edge = ColumnsMean(on, middle - 4, middle + 4) / Math.Max(edgeOff, 1.0f);
		// The open wall, well over an AO radius (0.5 m, about 11 pixels here) from the edge.
		let openOff = ColumnsMean(off, 4, middle - 32) + ColumnsMean(off, middle + 32, cSize - 4);
		let openOn = ColumnsMean(on, 4, middle - 32) + ColumnsMean(on, middle + 32, cSize - 4);
		open = openOn / Math.Max(openOff, 1.0f);
	}

	/// The orthographic view against a perspective one that is nearly orthographic (the same 4 m
	/// across at the edge, seen from 30 m): the same occlusion. Before, the passes divided an
	/// orthographic view's x and y by its 30 m depth, and their samples landed in the wrong place
	/// (SSAO) or a pixel away (GTAO's radius).
	private static void ProbeAo(AoMode mode)
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
		{
			let fixture = scope BackendProbeFixture(kind);
			if (!fixture.Ready)
				continue;
			MeasureAo(fixture, mode, false, let edge, let open, let edgeOff);
			MeasureAo(fixture, mode, true, let referenceEdge, let referenceOpen, ?);
			Console.WriteLine(scope $"{kind} {mode}: AO on/off at the edge {edge} (perspective {referenceEdge}), on the open wall {open} (perspective {referenceOpen})");
			Test.Assert(edgeOff > 100.0f, scope $"{kind}: the walls are where we look");
			Test.Assert(edge < 0.99f, scope $"{kind}: the corner occludes itself");
			// Tight: the fixed passes match to 0.0015 (GTAO) and 0.0001 (SSAO), and an orthographic
			// flag forced off misses by 0.017 (SSAO) and 0.039 (GTAO).
			Test.Assert(Math.Abs(edge - referenceEdge) < 0.005f, scope $"{kind} {mode}: the edge {edge} against {referenceEdge}");
			Test.Assert(Math.Abs(open - referenceOpen) < 0.06f, scope $"{kind} {mode}: the open wall {open} against {referenceOpen}");
		}
	}

	[Test]
	public static void GtaoOccludesACornerAsANearlyOrthographicPerspectiveViewDoes() => ProbeAo(.GTAO);

	[Test]
	public static void SsaoOccludesACornerAsANearlyOrthographicPerspectiveViewDoes() => ProbeAo(.SSAO);

	/// A still orthographic view under TAA settles on what it shows without it.
	[Test]
	public static void AStillOrthographicViewUnderTaaSettlesOnWhatItShowsWithoutIt()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
		{
			let fixture = scope BackendProbeFixture(kind);
			if (!fixture.Ready)
				continue;
			// A red wall and a blue one: the edge between them is what the jitter antialiases.
			var spec = Spec();
			spec.Coloured = true;
			let still = Render(fixture, spec);
			defer delete still;
			spec.Taa = true;
			let resolved = Render(fixture, spec);
			defer delete resolved;
			Test.Assert((still != null) && (resolved != null), scope $"{kind}: the corner rendered");
			if ((still == null) || (resolved == null))
				continue;
			double diff = 0.0;
			uint32 lost = 0; // a pixel the history blacked out (a NaN, or a rejection gone wrong)
			for (uint32 y < cSize)
			{
				for (uint32 x < cSize)
				{
					let a = still.At(x, y);
					let b = resolved.At(x, y);
					let la = (int32)a[0] + a[1] + a[2];
					let lb = (int32)b[0] + b[1] + b[2];
					for (int c < 3)
						diff += Math.Abs((int32)a[c] - (int32)b[c]);
					if ((la > 100) && (lb < 20))
						lost++;
				}
			}
			let meanDiff = (float)(diff / (cSize * cSize));
			Console.WriteLine(scope $"{kind}: orthographic TAA mean colour difference {meanDiff}, pixels lost {lost}");
			Test.Assert(lost == 0, scope $"{kind}: {lost} pixels lost");
			// The jittered samples average back to the still image but for the slanted edge, which
			// they antialias (so TAA ran). A jitter that grew with depth (row 2 under orthographic,
			// 30 m back: thirty times the shift) smeared the edge over many pixels.
			Test.Assert(meanDiff > 0.1f, scope $"{kind}: TAA ran ({meanDiff})");
			Test.Assert(meanDiff < 4.0f, scope $"{kind}: the edge stays put ({meanDiff})");
		}
	}
}
