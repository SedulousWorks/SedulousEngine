using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// Mip generation and a scaling blit, which WebGPU has no image blit for.
///
/// Both go through an internal fullscreen RENDER PASS instead - see WebGpuBlitHelper -
/// so this is the case that proves that pass samples and writes what it should, rather
/// than that a call was made.
class WebGpuBlitTests
{
	[Test]
	public static void AMipChainAndAScalingBlitCarryTheColour()
	{
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		let queue = device.GetQueue(.Graphics, 0);

		// An 8x8 texture with a four mip chain, solid green at mip 0.
		var mipDesc = TextureDesc();
		mipDesc.Format = .RGBA8Unorm;
		mipDesc.Width = 8;
		mipDesc.Height = 8;
		mipDesc.MipLevelCount = 4;
		mipDesc.Usage = .Sampled | .CopyDst | .CopySrc;
		var mipTexture = device.CreateTexture(mipDesc).GetValueOrDefault();
		Test.Assert(mipTexture != null);

		uint8[8 * 8 * 4] texels = .();
		for (int i = 0; i < 64; i++)
		{
			texels[i * 4 + 0] = 0;
			texels[i * 4 + 1] = 255;
			texels[i * 4 + 2] = 0;
			texels[i * 4 + 3] = 255;
		}

		var batch = queue.CreateTransferBatch().GetValueOrDefault();
		TextureDataLayout layout = .();
		layout.BytesPerRow = 32;
		layout.RowsPerImage = 8;
		batch.WriteTexture(mipTexture, .(&texels[0], texels.Count), layout, .(8, 8, 1));
		Test.Assert(batch.Submit() case .Ok);
		queue.DestroyTransferBatch(ref batch);

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var fence = device.CreateFence(0).GetValueOrDefault();

		var readbackDesc = BufferDesc();
		readbackDesc.Size = 4 * 256; // sized for the 4x4 blit readback below too
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		var readback = device.CreateBuffer(readbackDesc).GetValueOrDefault();
		Test.Assert(readback != null);

		// Mip 3 is 1x1. A solid colour chain has to stay solid through every level, so a
		// downsample that sampled the wrong level or the wrong place shows up here.
		var encoder = pool.CreateEncoder().GetValueOrDefault();
		encoder.GenerateMipmaps(mipTexture);

		BufferTextureCopyRegion region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 1;
		region.TextureMipLevel = 3;
		region.TextureExtent = .(1, 1, 1);
		encoder.CopyTextureToBuffer(mipTexture, readback, region);

		ICommandBuffer[1] first = .(encoder.Finish());
		queue.Submit(.(&first[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));

		var pixel = (uint8*)readback.Map();
		Test.Assert(pixel != null);
		Test.Assert(pixel[0] == 0, "R");
		Test.Assert(pixel[1] == 255, "G survived three downsamples");
		Test.Assert(pixel[2] == 0, "B");
		Test.Assert(pixel[3] == 255, "A");
		readback.Unmap();

		// The scaling blit: the 8x8 green source into a 4x4 target of a DIFFERENT format,
		// which is the case a copy could not serve.
		var blitDesc = TextureDesc.RenderTarget(.BGRA8Unorm, 4, 4);
		blitDesc.Usage = .RenderTarget | .CopySrc;
		var blitTarget = device.CreateTexture(blitDesc).GetValueOrDefault();
		Test.Assert(blitTarget != null);

		var blitEncoder = pool.CreateEncoder().GetValueOrDefault();
		blitEncoder.Blit(mipTexture, blitTarget);

		region = .();
		region.BytesPerRow = 256;
		region.RowsPerImage = 4;
		region.TextureExtent = .(4, 4, 1);
		blitEncoder.CopyTextureToBuffer(blitTarget, readback, region);

		ICommandBuffer[1] second = .(blitEncoder.Finish());
		queue.Submit(.(&second[0], 1), fence, 2);
		Test.Assert(fence.Wait(2, uint64.MaxValue));

		pixel = (uint8*)readback.Map();
		Test.Assert(pixel != null);
		// BGRA order now, so the channels come back swapped from the source's RGBA.
		Test.Assert(pixel[0] == 0, "B");
		Test.Assert(pixel[1] == 255, "G");
		Test.Assert(pixel[2] == 0, "R");
		readback.Unmap();

		Test.Assert(!device.IsLost());

		device.DestroyFence(ref fence);
		device.DestroyBuffer(ref readback);
		device.DestroyCommandPool(ref pool);
		device.DestroyTexture(ref blitTarget);
		device.DestroyTexture(ref mipTexture);
		device.Destroy();
	}
}
