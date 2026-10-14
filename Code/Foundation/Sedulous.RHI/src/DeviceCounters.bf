using System;
using System.Threading;

namespace Sedulous.RHI;

/// A device's counts, for the profiler's counters: totals since it was made (a reader takes
/// differences per frame) and what it holds now.
struct DeviceCounters
{
	/// Draw calls of every kind; a bundle's each time it is executed.
	public uint64 Draws;
	/// Compute dispatches, and ray traces.
	public uint64 Dispatches;
	public uint64 RenderPasses;
	public uint64 ComputePasses;
	/// SetPipeline and SetBindGroup, render and compute.
	public uint64 PipelineBinds;
	public uint64 BindGroupBinds;
	/// Written through transfer batches.
	public uint64 TransferBytes;
	/// Held now: the GPU memory of the buffers and textures this device made (render targets,
	/// depth included, apart), and how many of each.
	public uint64 BufferBytes;
	public uint64 TextureBytes;
	public uint64 RenderTargetBytes;
	public uint64 Buffers;
	public uint64 Textures;
}

/// The counts a backend keeps for IDevice.Counters, bumped where it records and allocates.
/// Interlocked, so encoders on any recording thread (bundles are built on workers) may bump
/// them; they are tallies, nothing is published through them.
class DeviceCounterBlock
{
	private uint64 mDraws;
	private uint64 mDispatches;
	private uint64 mRenderPasses;
	private uint64 mComputePasses;
	private uint64 mPipelineBinds;
	private uint64 mBindGroupBinds;
	private uint64 mTransferBytes;
	private uint64 mBufferBytes;
	private uint64 mTextureBytes;
	private uint64 mRenderTargetBytes;
	private uint64 mBuffers;
	private uint64 mTextures;

	public void Draws(uint64 count = 1) => Interlocked.Add(ref mDraws, count);
	public void Dispatches(uint64 count = 1) => Interlocked.Add(ref mDispatches, count);
	public void RenderPass() => Interlocked.Increment(ref mRenderPasses);
	public void ComputePass() => Interlocked.Increment(ref mComputePasses);
	public void PipelineBinds(uint64 count = 1) => Interlocked.Add(ref mPipelineBinds, count);
	public void BindGroupBinds(uint64 count = 1) => Interlocked.Add(ref mBindGroupBinds, count);
	public void Transfer(uint64 bytes) => Interlocked.Add(ref mTransferBytes, bytes);

	public void BufferMade(uint64 bytes)
	{
		Interlocked.Add(ref mBufferBytes, bytes);
		Interlocked.Increment(ref mBuffers);
	}

	public void BufferFreed(uint64 bytes)
	{
		Interlocked.Sub(ref mBufferBytes, bytes);
		Interlocked.Decrement(ref mBuffers);
	}

	public void TextureMade(uint64 bytes, bool renderTarget)
	{
		if (renderTarget)
			Interlocked.Add(ref mRenderTargetBytes, bytes);
		else
			Interlocked.Add(ref mTextureBytes, bytes);
		Interlocked.Increment(ref mTextures);
	}

	public void TextureFreed(uint64 bytes, bool renderTarget)
	{
		if (renderTarget)
			Interlocked.Sub(ref mRenderTargetBytes, bytes);
		else
			Interlocked.Sub(ref mTextureBytes, bytes);
		Interlocked.Decrement(ref mTextures);
	}

	public DeviceCounters Snapshot()
	{
		var counters = DeviceCounters();
		counters.Draws = Volatile.Read(ref mDraws);
		counters.Dispatches = Volatile.Read(ref mDispatches);
		counters.RenderPasses = Volatile.Read(ref mRenderPasses);
		counters.ComputePasses = Volatile.Read(ref mComputePasses);
		counters.PipelineBinds = Volatile.Read(ref mPipelineBinds);
		counters.BindGroupBinds = Volatile.Read(ref mBindGroupBinds);
		counters.TransferBytes = Volatile.Read(ref mTransferBytes);
		counters.BufferBytes = Volatile.Read(ref mBufferBytes);
		counters.TextureBytes = Volatile.Read(ref mTextureBytes);
		counters.RenderTargetBytes = Volatile.Read(ref mRenderTargetBytes);
		counters.Buffers = Volatile.Read(ref mBuffers);
		counters.Textures = Volatile.Read(ref mTextures);
		return counters;
	}

	/// The bytes a texture takes, from its description: every mip of every layer at every
	/// sample. For a backend that cannot ask its driver (Vulkan asks); a driver may pad more.
	public static uint64 EstimateTextureBytes(TextureDesc desc)
	{
		let layers = (desc.Dimension == .Texture3D) ? (uint64)1 : (uint64)Math.Max(desc.ArrayLayerCount, 1);
		uint64 total = 0;
		var width = Math.Max(desc.Width, (uint32)1);
		var height = Math.Max(desc.Height, (uint32)1);
		var depth = Math.Max(desc.Depth, (uint32)1);
		for (uint32 mip < Math.Max(desc.MipLevelCount, (uint32)1))
		{
			let level = TextureFormats.IsCompressed(desc.Format)
				? TextureFormats.CompressedLevelBytes(desc.Format, width, height)
				: (uint64)width * height * TextureFormats.BytesPerPixel(desc.Format);
			total += level * depth;
			width = Math.Max(width / 2, (uint32)1);
			height = Math.Max(height / 2, (uint32)1);
			depth = Math.Max(depth / 2, (uint32)1);
		}
		return total * layers * (uint64)Math.Max(desc.SampleCount, (uint32)1);
	}

	/// Whether a texture counts as a render target, a colour or depth attachment.
	public static bool CountsAsRenderTarget(TextureDesc desc) =>
		(desc.Usage & (.RenderTarget | .DepthStencil)) != .None;
}

/// What a render bundle recorded, added to the device's counts each time the bundle runs (a
/// bundle is recorded once and replayed). Its own encoder's thread only.
struct RecordedCounts
{
	public uint64 Draws;
	public uint64 PipelineBinds;
	public uint64 BindGroupBinds;

	public void AddTo(DeviceCounterBlock block)
	{
		block.Draws(Draws);
		block.PipelineBinds(PipelineBinds);
		block.BindGroupBinds(BindGroupBinds);
	}
}
