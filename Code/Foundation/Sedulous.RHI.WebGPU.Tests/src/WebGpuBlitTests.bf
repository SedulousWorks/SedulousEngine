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

	/// Blit capability is the ALLOWLIST of WebGPU's renderable colour formats.
	///
	/// The predicate decides whether texture creation widens usage to RenderAttachment for a
	/// mip chain, so a format WebGPU cannot render must answer no or creation fails outright.
	/// As an exclusion list it named the BC formats and forgot ASTC and the 8 bit snorms.
	[Test]
	public static void BlitCapableIsTheRenderableColourFormatsOnly()
	{
		// No device needed for the predicate itself. Every compressed, depth and stencil
		// format must say no, whatever the enumerator.
		for (int raw = 0; raw <= (int)TextureFormat.ASTC8x8UnormSrgb; raw++)
		{
			let format = (TextureFormat)raw;
			if (TextureFormats.IsCompressed(format) || TextureFormats.IsDepthFormat(format)
				|| (format == .Stencil8) || (format == .Undefined))
			{
				Test.Assert(!WebGpuConversions.IsBlitCapableFormat(format),
					scope $"{format} must not be blit capable");
			}
		}

		// ASTC was the fall through the exclusion list missed; BC was always excluded.
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.ASTC4x4Unorm));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.ASTC8x8UnormSrgb));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.BC7RGBAUnormSrgb));

		// Not renderable in WebGPU core either.
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.R8Snorm));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.RG8Snorm));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.RGBA8Snorm));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.RGBA16Unorm));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.RGB9E5Float));
		Test.Assert(!WebGpuConversions.IsBlitCapableFormat(.RG11B10Float));

		// The renderable set the mip blit actually targets.
		Test.Assert(WebGpuConversions.IsBlitCapableFormat(.RGBA8Unorm));
		Test.Assert(WebGpuConversions.IsBlitCapableFormat(.RGBA8UnormSrgb));
		Test.Assert(WebGpuConversions.IsBlitCapableFormat(.BGRA8UnormSrgb));
		Test.Assert(WebGpuConversions.IsBlitCapableFormat(.RGBA16Float));
		Test.Assert(WebGpuConversions.IsBlitCapableFormat(.R32Float));
		Test.Assert(WebGpuConversions.IsBlitCapableFormat(.RGB10A2Unorm));

		// On a live device: a mip chained texture in a format that is NOT blit capable must
		// still be creatable, usage never widened, and GenerateMipmaps a clean no-op on it.
		let backend = scope WebGpuBackend();
		let device = WebGpuTestDevice.TryCreate(backend);
		if (device == null)
			return;
		defer backend.Destroy();

		var desc = TextureDesc();
		desc.Format = .RGBA8Snorm;
		desc.Width = 16;
		desc.Height = 16;
		desc.MipLevelCount = 3;
		desc.Usage = .Sampled | .CopyDst;
		var texture = device.CreateTexture(desc).GetValueOrDefault();
		Test.Assert(texture != null, "a non blit capable mip chain still creates");

		var pool = device.CreateCommandPool(.Graphics).GetValueOrDefault();
		var encoder = pool.CreateEncoder().GetValueOrDefault();
		encoder.GenerateMipmaps(texture); // not blit capable: a no-op, and no validation error
		ICommandBuffer[1] buffers = .(encoder.Finish());
		var fence = device.CreateFence(0).GetValueOrDefault();
		device.GetQueue(.Graphics, 0).Submit(.(&buffers[0], 1), fence, 1);
		Test.Assert(fence.Wait(1, uint64.MaxValue));
		Test.Assert(!device.IsLost());

		pool.DestroyEncoder(ref encoder);
		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyTexture(ref texture);
		device.Destroy();
	}
}
