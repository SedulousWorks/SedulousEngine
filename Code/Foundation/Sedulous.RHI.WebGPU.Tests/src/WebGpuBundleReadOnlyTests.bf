using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// A render bundle that may write depth, executed in a pass that holds depth read-only, is named
/// with its pass: a browser's WebGPU refuses it and fails the whole submit, while native wgpu lets
/// it through, so nothing else here would say which bundle and which pass.
class WebGpuBundleReadOnlyTests
{
	[Test]
	public static void ABundleThatMayWriteDepthInAReadOnlyDepthPassIsNamed()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var depthDesc = TextureDesc.DepthBuffer(.Depth32Float, 4, 4);
		depthDesc.Usage = .DepthStencil | .Sampled; // a read-only depth pass needs Sampled
		var depthTexture = device.CreateTexture(depthDesc).GetValueOrDefault();
		Test.Assert(depthTexture != null);
		var depthViewDesc = TextureViewDesc();
		depthViewDesc.Format = .Depth32Float;
		var depthView = device.CreateTextureView(depthTexture, depthViewDesc).GetValueOrDefault();
		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();

		void Run(bool bundleDepthReadOnly, StringView bundleLabel)
		{
			let encoder = pool.CreateEncoder().GetValueOrDefault();
			Test.Assert(encoder != null);
			RenderBundleDesc bundleDesc = .();
			bundleDesc.DepthStencilFormat = .Depth32Float;
			bundleDesc.DepthReadOnly = bundleDepthReadOnly;
			bundleDesc.Width = 4;
			bundleDesc.Height = 4;
			bundleDesc.Label = bundleLabel;
			let bundleEncoder = encoder.CreateRenderBundleEncoder(bundleDesc);
			Test.Assert(bundleEncoder != null);
			let bundle = bundleEncoder.Finish();

			RenderPassDesc pass = .();
			pass.Label = "overlay";
			DepthStencilAttachment depth = .();
			depth.View = depthView;
			depth.DepthReadOnly = true;
			pass.DepthStencilAttachment = depth;
			let passEncoder = encoder.BeginRenderPass(pass);
			IRenderBundle[1] bundles = .(bundle);
			passEncoder.ExecuteBundles(.(&bundles[0], 1));
			passEncoder.End();
			encoder.Finish();
		}

		let ring = scope RingLogger(32, .Error);
		bool previousOwned = false;
		let previous = DetachGlobalLogger(out previousOwned);
		InitGlobalLogger(ring);

		Run(true, "reader");
		let afterMatching = ring.Count;
		Run(false, "writer");

		bool ringOwned = false;
		DetachGlobalLogger(out ringOwned); // the ring is the test's
		InitGlobalLogger(previous, previousOwned);

		Test.Assert(afterMatching == 0, "a read-only bundle fits a read-only pass");
		Test.Assert(ring.Count == 1, scope $"{ring.Count} errors");
		let message = ring.GetMessage(0, .. scope .());
		Test.Assert(message.Contains("'writer'") && message.Contains("depth") && message.Contains("'overlay'"), message);

		Test.Assert(!device.IsLost());
		device.DestroyCommandPool(ref pool);
		device.DestroyTextureView(ref depthView);
		device.DestroyTexture(ref depthTexture);
		device.Destroy();
	}
}
