using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// A LIVE device on this machine: that one comes up at all, what it says it can do, and
/// that the factories behind it hand back real objects.
class WebGpuDeviceTests
{
	[Test]
	public static void AnAdapterCreatesALiveDevice()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		Test.Assert(device.Type == .WebGPU);
		Test.Assert(!device.IsLost(), "a device is not born lost");

		// Always 128, whichever way push constants go: SetPushConstants works through
		// native immediates or through the uniform buffer emulation, and reporting zero
		// under emulation would make a capability checking caller disable the very paths
		// the emulator exists to serve.
		Test.Assert(device.Features.MaxPushConstantSize == 128);

		// ONE WebGPU queue behind three RHI typed views, and nothing past index zero.
		Test.Assert(device.GetQueue(.Graphics, 0) != null);
		Test.Assert(device.GetQueue(.Compute, 0) != null);
		Test.Assert(device.GetQueue(.Transfer, 0) != null);
		Test.Assert(device.GetQueueCount(.Graphics) == 1);
		Test.Assert(device.GetQueue(.Graphics, 1) == null, "there is no second queue");

		device.WaitIdle();
		device.Destroy();
		device.Destroy(); // idempotent: the adapter destroys it again at teardown
	}

	/// WebGPU guarantees ONLY 1 and 4 for the renderer's colour and depth formats. 2x
	/// needs the adapter specific format features, which are not enabled, and creating a
	/// 2 sample texture aborts the device - so callers snap 2x to 1x off this answer.
	[Test]
	public static void OnlyOneAndFourSamplesAreOffered()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		Test.Assert(device.SupportsSampleCount(1));
		Test.Assert(device.SupportsSampleCount(4));
		Test.Assert(!device.SupportsSampleCount(2), "2x is not a WebGPU guarantee");
		Test.Assert(!device.SupportsSampleCount(8), "and 8x is not a WebGPU capability");
		Test.Assert(device.MaxColorDepthSampleCount == 4);
	}

	/// The format table is the SPEC's, not the driver's, so these are a check on the backend
	/// rather than on the machine. The classes that differ from the common colour case
	/// are the ones worth pinning.
	[Test]
	public static void TheFormatTableFollowsTheSpecClasses()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		Test.Assert(device.GetFormatSupport(.Undefined) == .Unsupported);

		// 16 bit norms have no core WebGPU equivalent at all.
		Test.Assert(device.GetFormatSupport(.RGBA16Unorm) == .Unsupported);

		// Depth is never a colour attachment.
		let depth = device.GetFormatSupport(.Depth32Float);
		Test.Assert(depth.HasFlag(.DepthStencil));
		Test.Assert(!depth.HasFlag(.ColorAttachment));

		// 32 bit float is renderable and storage, but NOT filterable in core.
		let float32 = device.GetFormatSupport(.RGBA32Float);
		Test.Assert(float32.HasFlag(.StorageTexture));
		Test.Assert(!float32.HasFlag(.LinearFilter));

		// An integer format is renderable, never blendable or filterable.
		let integer = device.GetFormatSupport(.RGBA8Uint);
		Test.Assert(integer.HasFlag(.ColorAttachment));
		Test.Assert(!integer.HasFlag(.BlendableColor));
		Test.Assert(!integer.HasFlag(.LinearFilter));

		// And the classic colour family is all four.
		let color = device.GetFormatSupport(.BGRA8UnormSrgb);
		Test.Assert(color.HasFlag(.Texture) && color.HasFlag(.ColorAttachment)
			&& color.HasFlag(.BlendableColor) && color.HasFlag(.LinearFilter));
	}

	/// The factories behind the device, which is what the rest of the backend is reached
	/// through. Each one is created and destroyed back through the device that made it.
	[Test]
	public static void TheDeviceMakesAndUnmakesResources()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var bufferDesc = BufferDesc();
		bufferDesc.Size = 256;
		bufferDesc.Usage = .Uniform;
		var buffer = device.CreateBuffer(bufferDesc).GetValueOrDefault();
		Test.Assert(buffer != null, "a uniform buffer");

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64);
		var texture = device.CreateTexture(textureDesc).GetValueOrDefault();
		Test.Assert(texture != null, "a render target");

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		var view = device.CreateTextureView(texture, viewDesc).GetValueOrDefault();
		Test.Assert(view != null, "and a view onto it");

		// No cache object exists in WebGPU, so creation SUCCEEDS with an empty stand in
		// rather than failing: the RHI treats caches as best effort.
		var cache = device.CreatePipelineCache(.()).GetValueOrDefault();
		Test.Assert(cache != null, "an empty pipeline cache");
		Test.Assert(cache.GetDataSize() == 0, "which has nothing to serve");

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		Test.Assert(pool != null, "a command pool");

		var fence = device.CreateFence(0).GetValueOrDefault();
		Test.Assert(fence != null, "a fence");

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyPipelineCache(ref cache);
		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref texture);
		device.DestroyBuffer(ref buffer);

		Test.Assert(fence == null, "and every destroy nulls what it took");
		Test.Assert(buffer == null);

		device.Destroy();
	}
}
