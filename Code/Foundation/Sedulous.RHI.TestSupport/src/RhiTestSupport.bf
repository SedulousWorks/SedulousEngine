using System;
using Sedulous.RHI;

namespace Sedulous.RHI.TestSupport;

/// A small, backend agnostic substrate for offscreen render tests: make a device, and read a
/// rendered colour target back into something a test can probe.
///
/// STRUCTURAL probes only. A caller asserts PROPERTIES of the pixels, which is edge coverage,
/// brightness splits, colours agreeing, and never a difference against a stored image: a
/// golden image drifts across drivers and cards and then fails for reasons that are not the
/// code's. What lives here is only the reusable plumbing; each suite keeps its own render
/// setup and its own assertions.
static class RhiTestSupport
{
	/// A device off a backend's first adapter.
	///
	/// Null means the test should SKIP rather than fail: a machine with no adapter, or one
	/// where device creation does not go through, is a machine that cannot answer the
	/// question, which is different from answering it wrongly.
	public static IDevice MakeTestDevice(IBackend backend)
	{
		if (backend == null)
			return null;

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return null;

		if (!(adapters[0].CreateDevice(.()) case .Ok(let device)))
			return null;

		return device;
	}

	/// Reads back a colour target that has ALREADY been rendered and left in the copy source
	/// state.
	///
	/// It owns a command buffer for the copy and a readable staging buffer, blocks on a fence,
	/// and unpacks the aligned rows into a tightly packed image. DECOUPLED from the render
	/// command stream, the target being a persistent texture, so a caller renders however it
	/// likes and then asks for this.
	///
	/// An invalid image comes back on any failure, which a caller reads the same way it reads
	/// a null device.
	public static CapturedImage Readback(IDevice device, ITexture colorTarget, uint32 width,
		uint32 height)
	{
		let image = new CapturedImage();
		if ((colorTarget == null) || (width == 0) || (height == 0))
			return image;

		// Every backend wants 256 byte rows in the buffer, whatever the image's own width is: it is
		// DX12 that REQUIRES it, the placed footprint pitch being a multiple of 256, and the
		// others are happy to be handed the same.
		let bytesPerRow = (width * 4 + 255) & ~(uint32)255;

		var bufferDesc = BufferDesc();
		bufferDesc.Size = (uint64)bytesPerRow * height;
		bufferDesc.Usage = .CopyDst;
		bufferDesc.Memory = .GpuToCpu;
		bufferDesc.Label = "testsupport.readback";
		if (!(device.CreateBuffer(bufferDesc) case .Ok(var readback)))
			return image;

		defer device.DestroyBuffer(ref readback);

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return image;

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return image;

		defer device.DestroyCommandPool(ref pool);

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return image;

		defer device.DestroyFence(ref fence);

		if (!(pool.CreateEncoder() case .Ok(var encoder)))
			return image;

		// The encoder is destroyed only after the device has gone idle below, so the copy it
		// recorded is never freed out from under a submission still in flight.
		defer pool.DestroyEncoder(ref encoder);

		var region = BufferTextureCopyRegion();
		region.BytesPerRow = bytesPerRow;
		region.RowsPerImage = height;
		region.TextureExtent = .(width, height, 1);
		encoder.CopyTextureToBuffer(colorTarget, readback, region);

		let commandBuffer = encoder.Finish();
		if (commandBuffer == null)
		{
			device.WaitIdle();
			return image;
		}

		var buffers = ICommandBuffer[1](commandBuffer);
		queue.Submit(.(&buffers[0], 1), fence, 1);
		fence.Wait(1);

		let mapped = (uint8*)readback.Map();
		if (mapped != null)
		{
			image.Width = width;
			image.Height = height;
			image.Rgba.Count = (int)width * (int)height * 4;

			// Row by row, because the source rows are padded out to the alignment and the
			// destination's are not.
			for (uint32 y = 0; y < height; y++)
			{
				Internal.MemCpy(&image.Rgba[(int)y * (int)width * 4],
					mapped + (int)y * (int)bytesPerRow, (int)width * 4);
			}

			readback.Unmap();
			image.Valid = true;
		}

		device.WaitIdle();
		return image;
	}
}
