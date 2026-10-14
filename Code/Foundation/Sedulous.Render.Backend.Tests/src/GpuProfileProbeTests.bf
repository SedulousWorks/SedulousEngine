using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.Profiler;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;

namespace Sedulous.Render.Backend.Tests;

/// The profiler's GPU lane on real devices, through the whole RenderFrame: with the profiler
/// armed, a frame's passes come back a frame or two later tagged with that frame, on the CPU's
/// clock (inside the CPU span that recorded and waited for them), in order, under the names the
/// CPU lane gives the same passes; where the device counts pipeline statistics, the passes
/// drawing a cube count its twelve triangles. Vulkan aligns the clocks by calibrated
/// timestamps, WebGPU by one sync point, and has no statistics.
class GpuProfileProbeTests
{
	private const uint32 cSize = 128;
	private const uint32 cFrames = 8;

	private struct Measure
	{
		/// Frames whose GPU passes arrived, and the passes over them.
		public uint32 FramesWithGpu;
		public uint32 Passes;
		/// Passes not inside the CPU span of their frame, and passes that began before the one
		/// before them ended.
		public uint32 OutsideFrame;
		public uint32 OutOfOrder;
		/// GPU passes whose name no CPU scope of the frame has.
		public uint32 UnnamedOnCpu;
		/// Passes carrying pipeline statistics, and one frame's input primitives and fragments.
		public uint32 WithCounts;
		public uint64 Primitives;
		public uint64 Fragments;
		/// The device's counts over one frame (IDevice.Counters), fewest, and the render target
		/// memory held during the frames.
		public uint64 FewestDraws;
		public uint64 FewestPasses;
		public uint64 TargetBytes;
	}

	private static bool Run(BackendProbeFixture fixture, Profiler profiler, out Measure result)
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
		let frame = scope RenderFrame(device, registry, 2, null, tonemap, null, null, null, null, null, null, null);

		let cube = Primitives.Cube(1.0f);
		defer delete cube;
		let grey = MaterialPresets.CreatePbr("gpuprofile.grey", .(0.6f, 0.6f, 0.6f, 1.0f), 0.0f, 0.8f);
		defer delete grey;
		let scene = scope ExtractedScene();
		scene.SetAmbient(.(0.3f, 0.3f, 0.3f));
		let cubeData = scene.Add<MeshRenderData>();
		cubeData.EntityId = 1;
		cubeData.World = Float4x4.Identity();
		cubeData.WorldRadius = 1.0f;
		cubeData.Mesh = cube;
		cubeData.Material = grey;
		cubeData.Category = RenderCategories.Opaque;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .RenderTarget | .CopySrc;
		textureDesc.Label = "gpuprofile.target";
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
		var camera = ViewCamera();
		camera.Position = .(2.0f, 1.5f, 3.0f);
		camera.View = Float4x4.LookAtRH(camera.Position, .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);

		// Each profiler frame records, submits and waits for its GPU work, so every GPU pass of
		// frame k lies inside frame k's CPU span.
		profiler.Arm();
		uint64 firstFrame = 0;
		result.FewestDraws = uint64.MaxValue;
		result.FewestPasses = uint64.MaxValue;
		for (uint32 i < cFrames)
		{
			profiler.BeginFrame();
			if (i == 0)
				firstFrame = profiler.CurrentFrameNumber;
			if (!(pool.CreateEncoder() case .Ok(var encoder)))
				return false;
			settings.TargetCurrentState = (i == 0) ? .Undefined : .CopySrc;
			let before = device.Counters();
			frame.Begin(encoder, i % 2);
			frame.AddView(scene, camera, settings, targetView, .RGBA8Unorm, cSize, cSize);
			frame.End();
			let after = device.Counters();
			result.FewestDraws = Math.Min(result.FewestDraws, after.Draws - before.Draws);
			result.FewestPasses = Math.Min(result.FewestPasses, after.RenderPasses - before.RenderPasses);
			result.TargetBytes = after.RenderTargetBytes;
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
			profiler.EndFrame();
		}
		profiler.Disarm();

		// A slot's passes arrive when it comes round, two frames on: frames first to first + 5
		// have theirs by now. The clocks may disagree by a sync point's half round trip.
		let slack = ProfileClock.TicksPerSecond / 500; // 2 ms
		for (var k = firstFrame; k < firstFrame + cFrames - 2; k++)
		{
			let record = profiler.Frame(k);
			Test.Assert(record != null, scope $"frame {k} is kept");
			if ((record == null) || !record.GpuValid)
				continue;
			result.FramesWithGpu++;
			int64 previousEnd = 0;
			uint64 primitives = 0;
			uint64 fragments = 0;
			for (let pass in record.Gpu)
			{
				result.Passes++;
				if ((pass.BeginTick + slack < record.BeginTick) || (pass.EndTick > record.EndTick + slack))
					result.OutsideFrame++;
				if ((previousEnd != 0) && (pass.BeginTick + slack < previousEnd))
					result.OutOfOrder++;
				previousEnd = pass.EndTick;
				var named = false;
				for (let thread in record.Threads)
				{
					for (let recorded in thread.Scopes)
						named |= recorded.Name == pass.Name;
				}
				if (!named)
					result.UnnamedOnCpu++;
				if (pass.HasCounts)
				{
					result.WithCounts++;
					primitives += pass.Counts.InputPrimitives;
					fragments += pass.Counts.FragmentInvocations;
				}
			}
			result.Primitives = Math.Max(result.Primitives, primitives);
			result.Fragments = Math.Max(result.Fragments, fragments);
		}
		return true;
	}

	[Test]
	public static void AFramesGpuPassesComeBackTaggedInOrderOnTheCpusClock()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
		{
			let fixture = scope BackendProbeFixture(kind);
			if (!fixture.Ready)
				continue;
			if (!fixture.Device.Features.TimestampQueries)
			{
				Console.WriteLine(scope $"{kind}: no encoder timestamps, the GPU lane is absent; skipped");
				continue;
			}
			let profiler = scope Profiler();
			InitGlobalProfiler(profiler);
			defer ShutdownGlobalProfiler();
			let built = Run(fixture, profiler, let m);
			Test.Assert(built, scope $"{kind}: the frames rendered");
			if (!built)
				continue;
			Console.WriteLine(scope $"{kind}: {m.FramesWithGpu} frames with GPU passes, {m.Passes} passes, {m.OutsideFrame} outside their frame, {m.OutOfOrder} out of order, {m.WithCounts} with counts; one frame: {m.Primitives} primitives, {m.Fragments} fragments; the device counts at least {m.FewestDraws} draws and {m.FewestPasses} render passes a frame, {m.TargetBytes >> 10} KiB of render targets");
			Test.Assert(m.FramesWithGpu == cFrames - 2, scope $"{kind}: {m.FramesWithGpu} frames with GPU passes");
			Test.Assert(m.Passes >= m.FramesWithGpu);
			Test.Assert(m.OutsideFrame == 0, scope $"{kind}: {m.OutsideFrame} passes outside their frame");
			Test.Assert(m.OutOfOrder == 0, scope $"{kind}: {m.OutOfOrder} passes out of order");
			Test.Assert(m.UnnamedOnCpu == 0, scope $"{kind}: {m.UnnamedOnCpu} passes the CPU lane does not name");
			// The depth prepass and the forward pass draw the cube, the tonemap its triangle.
			Test.Assert(m.FewestDraws >= 3, scope $"{kind}: {m.FewestDraws} draws a frame");
			Test.Assert(m.FewestPasses >= 3, scope $"{kind}: {m.FewestPasses} render passes a frame");
			Test.Assert(m.TargetBytes >= cSize * cSize * 4, "the probe's own target, at least");
			if (fixture.Device.Features.PipelineStatisticsQueries)
			{
				Test.Assert(m.WithCounts == m.Passes);
				Test.Assert(m.Primitives >= 12, scope $"{kind}: {m.Primitives} primitives, the cube's twelve triangles at least once");
				Test.Assert(m.Fragments > 0);
			}
			else
			{
				Test.Assert(m.WithCounts == 0);
			}
		}
	}
}
