using System;
using Sedulous.Profiler;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The render graph's half of the profiler, without a GPU: on the Null device (no timestamps) a
/// graph's passes show as CPU scopes of the frame and no GPU lane is made. The GPU path is
/// probed on Vulkan and WebGPU in Render.Backend.Tests.
class RGProfilerTests
{
	/// A device without timestamps gets no GPU profiler, and nothing breaks: one never
	/// initialised measures nothing.
	[Test]
	public static void ADeviceWithoutTimestampsGetsNoGpuProfilerAndNothingBreaks()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		Test.Assert(!device.Features.TimestampQueries);
		let gpu = scope GraphProfiler();
		Test.Assert(gpu.Init(device, 2) case .Err);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var encoder = pool.CreateEncoder().Value;
		defer pool.DestroyEncoder(ref encoder);
		let profiler = scope Profiler();
		profiler.Arm();
		Test.Assert(!gpu.BeginFrame(encoder, 0, profiler));
		gpu.BeginPass(encoder, 0);
		gpu.EndPass(encoder);
		gpu.EndFrame(encoder);
		gpu.Destroy();
	}

	/// While armed, each executed pass is a CPU scope of the frame under its name, interned in
	/// the profiler's own table; a device without timestamps leaves the GPU lane empty.
	[Test]
	public static void WhileArmedEachExecutedPassIsACpuScopeOfTheFrame()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		var textureDesc = TextureDesc.RenderTarget(.BGRA8Unorm, 16, 16);
		textureDesc.Label = "RGProfilerTests.target";
		var target = device.CreateTexture(textureDesc).Value;
		defer device.DestroyTexture(ref target);
		var view = device.CreateTextureView(target, .() { Label = "RGProfilerTests.target" }).Value;
		defer device.DestroyTextureView(ref view);
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var encoder = pool.CreateEncoder().Value;
		defer pool.DestroyEncoder(ref encoder);

		let profiler = scope Profiler();
		profiler.Arm();
		InitGlobalProfiler(profiler);
		defer ShutdownGlobalProfiler();
		profiler.BeginFrame();
		{
			let graph = scope RenderGraph(device);
			graph.SetOutputSize(16, 16);
			graph.BeginFrame(0);
			let output = graph.ImportTarget("Out", target, view, ResourceState.Present);
			graph.AddRenderPass("rg.profiler.pass", scope (builder) =>
				{
					builder.SetColorTarget(0, output, .Clear, .Store);
					builder.NeverCull();
					builder.SetExecute(new (passEncoder) => {});
				});
			Test.Assert(graph.Execute(encoder) case .Ok);
			graph.EndFrame();
		}
		profiler.EndFrame();

		let frame = profiler.LatestFrame;
		Test.Assert(frame != null);
		var found = 0;
		for (let thread in frame.Threads)
		{
			for (let recorded in thread.Scopes)
			{
				if (profiler.NameOf(recorded.Name) == "rg.profiler.pass")
					found++;
			}
		}
		Test.Assert(found == 1, scope $"{found} pass scopes");
		Test.Assert(!frame.GpuValid, "no timestamps on this device: no GPU lane");
		Test.Assert(profiler.InternName("rg.profiler.pass") < profiler.NameCount, "interned once, in this profiler's table");
	}
}
