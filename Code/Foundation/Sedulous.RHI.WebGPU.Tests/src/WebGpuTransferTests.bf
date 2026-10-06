using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The upload paths, verified by reading the bytes back off the GPU.
///
/// A transfer batch is the bulk upload path; the per frame case below is the shape a
/// sample's frame actually has, where a lingering map would fail the next submit.
class WebGpuTransferTests
{
	[Test]
	public static void ABatchUploadsBuffersAndTextures()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let transferQueue = device.GetQueue(.Transfer, 0);
		var batch = transferQueue.CreateTransferBatch().GetValueOrDefault();
		Test.Assert(batch != null);

		var gpuDesc = BufferDesc();
		gpuDesc.Size = 64;
		gpuDesc.Usage = .Storage | .CopySrc | .CopyDst;
		gpuDesc.Memory = .GpuOnly;
		var gpuBuffer = device.CreateBuffer(gpuDesc).GetValueOrDefault();
		Test.Assert(gpuBuffer != null);

		uint8[64] pattern = .();
		for (int i = 0; i < 64; i++)
			pattern[i] = (uint8)(i * 3);

		batch.WriteBuffer(gpuBuffer, 0, .(&pattern[0], 64));

		// A texture rides the same batch: one 4x4 RGBA mip.
		var texDesc = TextureDesc();
		texDesc.Format = .RGBA8Unorm;
		texDesc.Width = 4;
		texDesc.Height = 4;
		texDesc.Usage = .CopyDst | .CopySrc;
		var texture = device.CreateTexture(texDesc).GetValueOrDefault();
		Test.Assert(texture != null);

		uint8[4 * 4 * 4] texels = .();
		for (int i = 0; i < texels.Count; i++)
			texels[i] = (uint8)(255 - i);

		TextureDataLayout layout = .();
		layout.BytesPerRow = 16;
		layout.RowsPerImage = 4;
		batch.WriteTexture(texture, .(&texels[0], texels.Count), layout, .(4, 4, 1));

		Test.Assert(batch.Submit() case .Ok, "the batch blocks until it has landed");

		// Read both back through the two copy paths.
		var readDesc = BufferDesc();
		readDesc.Size = 4 * 256;
		readDesc.Usage = .CopyDst;
		readDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var fence = device.CreateFence(0).GetValueOrDefault();
		let queue = device.GetQueue(.Graphics, 0);

		var encoder = pool.CreateEncoder().GetValueOrDefault();
		encoder.CopyBufferToBuffer(gpuBuffer, 0, readback, 0, 64);
		ICommandBuffer[1] first = .(encoder.Finish());
		queue.Submit(.(&first[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));

		var bytes = (uint8*)readback.Map();
		Test.Assert(bytes != null);
		Test.Assert(bytes[0] == 0);
		Test.Assert(bytes[21] == (uint8)(21 * 3));
		Test.Assert(bytes[63] == (uint8)(63 * 3));
		readback.Unmap();

		var textureEncoder = pool.CreateEncoder().GetValueOrDefault();
		BufferTextureCopyRegion region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 4;
		region.TextureExtent = .(4, 4, 1);
		textureEncoder.CopyTextureToBuffer(texture, readback, region);
		ICommandBuffer[1] second = .(textureEncoder.Finish());
		queue.Submit(.(&second[0], 1), fence, 2);
		Test.Assert(fence.Wait(2, uint64.MaxValue));

		bytes = (uint8*)readback.Map();
		Test.Assert(bytes != null);
		Test.Assert(bytes[0] == 255, "the first texel byte");
		Test.Assert(bytes[15] == (uint8)(255 - 15), "the last byte of row 0");
		// Row 1 starts at bytesPerRow, not at 16: the copy PADS its rows.
		Test.Assert(bytes[256 + 0] == (uint8)(255 - 16), "row 1 starts a stride in");
		readback.Unmap();

		Test.Assert(!device.IsLost());

		transferQueue.DestroyTransferBatch(ref batch);
		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref readback);
		device.DestroyTexture(ref texture);
		device.DestroyBuffer(ref gpuBuffer);
		device.Destroy();
	}

	/// A sample's frame shape: read back the LAST frame's results, then submit new work
	/// touching the same readback buffer. A pending or lingering map fails the submit
	/// with "buffer still mapped", which is what this catches.
	[Test]
	public static void APerFrameMapUnmapResubmitCycleStaysValid()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var sourceDesc = BufferDesc();
		sourceDesc.Size = 64;
		sourceDesc.Usage = .CopySrc | .CopyDst;
		sourceDesc.Memory = .CpuToGpu;
		var source = device.CreateBuffer(sourceDesc).GetValueOrDefault();
		Test.Assert(source != null);

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 64;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var fence = device.CreateFence(0).GetValueOrDefault();
		let queue = device.GetQueue(.Graphics, 0);

		for (uint64 frame = 1; frame <= 5; frame++)
		{
			if (frame > 1)
			{
				Test.Assert(fence.Wait(frame - 1, uint64.MaxValue));
				let mapped = readback.Map();
				Test.Assert(mapped != null);
				readback.Unmap();
			}

			var encoder = pool.CreateEncoder().GetValueOrDefault();
			encoder.CopyBufferToBuffer(source, 0, readback, 0, 64);
			ICommandBuffer[1] submitted = .(encoder.Finish());
			queue.Submit(.(&submitted[0], 1), fence, frame);
			pool.DestroyEncoder(ref encoder);
		}

		device.WaitIdle();
		Test.Assert(!device.IsLost(), "five frames of map, unmap and resubmit");

		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref readback);
		device.DestroyBuffer(ref source);
		device.Destroy();
	}

	/// Snowline's first web run: a block compressed texture's mip tail (its 2x2 and 1x1
	/// levels) was written at its size in texels, which WebGPU refuses ("copySize.width (2) is
	/// not a multiple of compressed texture format block width (4)"); every level must go up
	/// in whole blocks.
	[Test]
	public static void ACompressedTexturesWholeMipChainUploadsTheTailInWholeBlocks()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let errorsBefore = WebGpuDiagnostics.UncapturedErrorCount;
		let transferQueue = device.GetQueue(.Transfer, 0);
		var batch = transferQueue.CreateTransferBatch().GetValueOrDefault();
		Test.Assert(batch != null);

		let format = TextureFormat.BC1RGBAUnorm;
		var desc = TextureDesc();
		desc.Format = format;
		desc.Width = 16;
		desc.Height = 16;
		desc.MipLevelCount = 5; // 16, 8, 4, 2, 1
		desc.Usage = .CopyDst | .Sampled;
		var texture = device.CreateTexture(desc).GetValueOrDefault();
		Test.Assert(texture != null);

		// Each level as the texture resource lays it out: texel extent, block row pitch and
		// count.
		uint8[16 * 16] blocks = .();
		for (int i < blocks.Count)
			blocks[i] = (uint8)i;
		for (uint32 level < desc.MipLevelCount)
		{
			let w = Math.Max(desc.Width >> level, 1);
			let h = Math.Max(desc.Height >> level, 1);
			TextureDataLayout layout = .();
			layout.BytesPerRow = TextureFormats.CompressedRowPitch(format, w);
			layout.RowsPerImage = (h + TextureFormats.BlockHeight(format) - 1) / TextureFormats.BlockHeight(format);
			let bytes = (int)TextureFormats.CompressedLevelBytes(format, w, h);
			batch.WriteTexture(texture, .(&blocks[0], bytes), layout, .(w, h, 1), level, 0);
		}
		Test.Assert(batch.Submit() case .Ok);
		device.WaitIdle(); // the error callbacks arrive through the event pump

		Test.Assert(WebGpuDiagnostics.UncapturedErrorCount == errorsBefore,
			scope $"{WebGpuDiagnostics.UncapturedErrorCount - errorsBefore} WebGPU errors");
		Test.Assert(!device.IsLost());

		transferQueue.DestroyTransferBatch(ref batch);
		device.DestroyTexture(ref texture);
		device.Destroy();
	}

	/// Snowline's course pictures, 480 by 270 in BC1: WebGPU refused to make the texture ("not a
	/// multiple of the block width (4) and height (4)"). A compressed texture whose size is not
	/// whole blocks is made, and its whole mip chain uploads, with no error.
	[Test]
	public static void ACompressedTextureWhoseSizeIsNotWholeBlocksIsMadeAndUploads()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let errorsBefore = WebGpuDiagnostics.UncapturedErrorCount;
		let transferQueue = device.GetQueue(.Transfer, 0);
		var batch = transferQueue.CreateTransferBatch().GetValueOrDefault();
		Test.Assert(batch != null);

		let format = TextureFormat.BC1RGBAUnormSrgb;
		var desc = TextureDesc();
		desc.Format = format;
		desc.Width = 18;
		desc.Height = 10;
		desc.MipLevelCount = 5; // 18x10, 9x5, 4x2, 2x1, 1x1
		desc.Usage = .CopyDst | .Sampled;
		var texture = device.CreateTexture(desc).GetValueOrDefault();
		Test.Assert(texture != null);

		uint8[20 * 12] blocks = .();
		for (int i < blocks.Count)
			blocks[i] = (uint8)i;
		for (uint32 level < desc.MipLevelCount)
		{
			let w = Math.Max(desc.Width >> level, 1);
			let h = Math.Max(desc.Height >> level, 1);
			TextureDataLayout layout = .();
			layout.BytesPerRow = TextureFormats.CompressedRowPitch(format, w);
			layout.RowsPerImage = (h + TextureFormats.BlockHeight(format) - 1) / TextureFormats.BlockHeight(format);
			let bytes = (int)TextureFormats.CompressedLevelBytes(format, w, h);
			batch.WriteTexture(texture, .(&blocks[0], bytes), layout, .(w, h, 1), level, 0);
		}
		Test.Assert(batch.Submit() case .Ok);
		device.WaitIdle();

		Test.Assert(WebGpuDiagnostics.UncapturedErrorCount == errorsBefore,
			scope $"{WebGpuDiagnostics.UncapturedErrorCount - errorsBefore} WebGPU errors");
		Test.Assert(!device.IsLost());

		transferQueue.DestroyTransferBatch(ref batch);
		device.DestroyTexture(ref texture);
		device.Destroy();
	}
}
