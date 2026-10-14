using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.RHI.Null.Tests;

/// A device's counts for the profiler, which the null backend keeps like any other: totals of
/// what was recorded since it was made, and the memory its resources hold now.
class NullCounterTests
{
	/// A frame of known work counts what it did, a bundle each time it runs.
	[Test]
	public static void AFrameOfKnownWorkCountsWhatItDidABundleEachTimeItRuns()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		var pool = device.CreateCommandPool(.Graphics).Value;
		defer device.DestroyCommandPool(ref pool);
		var encoder = pool.CreateEncoder().Value;
		defer pool.DestroyEncoder(ref encoder);

		// A bundle of two draws and a bind, recorded once.
		let bundleEncoder = encoder.CreateRenderBundleEncoder(.());
		bundleEncoder.SetBindGroup(0, null, default);
		bundleEncoder.Draw(3, 1, 0, 0);
		bundleEncoder.DrawIndexed(6, 1, 0, 0, 0);
		let bundle = bundleEncoder.Finish();
		Test.Assert(device.Counters().Draws == 0, "recording a bundle draws nothing yet");

		let pass = encoder.BeginRenderPass(.());
		pass.SetPipeline(null);
		pass.SetBindGroup(0, null, default);
		pass.SetBindGroup(1, null, default);
		pass.Draw(3, 1, 0, 0);
		pass.DrawIndexed(36, 1, 0, 0, 0);
		pass.DrawIndirect(null, 0, 4, 16);
		IRenderBundle[2] bundles = .(bundle, bundle);
		pass.ExecuteBundles(bundles); // the bundle runs twice
		pass.End();
		let compute = encoder.BeginComputePass("counts");
		compute.SetPipeline(null);
		compute.Dispatch(8, 8, 1);
		compute.DispatchIndirect(null, 0);
		compute.End();
		var batch = device.GetQueue(.Graphics).CreateTransferBatch().Value;
		defer device.GetQueue(.Graphics).DestroyTransferBatch(ref batch);
		uint8[100] bytes = default;
		batch.WriteBuffer(null, 0, bytes);

		let counts = device.Counters();
		Test.Assert(counts.Draws == 2 + 4 + 2 * 2, scope $"{counts.Draws} draws: two direct, four indirect, the bundle's two twice");
		Test.Assert(counts.RenderPasses == 1);
		Test.Assert(counts.ComputePasses == 1);
		Test.Assert(counts.Dispatches == 2);
		Test.Assert(counts.PipelineBinds == 2, "render and compute");
		Test.Assert(counts.BindGroupBinds == 2 + 2, "the pass's two, the bundle's one twice");
		Test.Assert(counts.TransferBytes == 100);
		device.Destroy();
	}

	/// The memory held rises and falls with buffers and textures, render targets apart, and a
	/// texture's size counts every mip of every layer.
	[Test]
	public static void MemoryHeldRisesAndFallsWithBuffersAndTexturesRenderTargetsApart()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		var bufferDesc = BufferDesc();
		bufferDesc.Size = 1024;
		var buffer = device.CreateBuffer(bufferDesc).Value;
		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = 64;
		textureDesc.Height = 64;
		textureDesc.Usage = .Sampled;
		var texture = device.CreateTexture(textureDesc).Value;
		var target = device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 32, 32)).Value;

		var counts = device.Counters();
		Test.Assert((counts.BufferBytes == 1024) && (counts.Buffers == 1));
		Test.Assert(counts.TextureBytes == 64 * 64 * 4);
		Test.Assert(counts.RenderTargetBytes == 32 * 32 * 4);
		Test.Assert(counts.Textures == 2);

		device.DestroyTexture(ref target);
		device.DestroyBuffer(ref buffer);
		counts = device.Counters();
		Test.Assert((counts.BufferBytes == 0) && (counts.RenderTargetBytes == 0));
		Test.Assert(counts.TextureBytes == 64 * 64 * 4);
		Test.Assert(counts.Textures == 1);
		device.DestroyTexture(ref texture);
		Test.Assert(device.Counters().Textures == 0);

		// Every mip, every layer: a 64x64 RGBA8 with a full chain of 7 levels, 2 layers.
		textureDesc.MipLevelCount = 7;
		textureDesc.ArrayLayerCount = 2;
		Test.Assert(DeviceCounterBlock.EstimateTextureBytes(textureDesc) == 2 * 4 * (4096 + 1024 + 256 + 64 + 16 + 4 + 1));
		Test.Assert(!device.MemoryBudget(?, ?), "no driver to ask");
		device.Destroy();
	}
}
