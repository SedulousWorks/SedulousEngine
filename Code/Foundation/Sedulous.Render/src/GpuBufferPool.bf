using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core;

namespace Sedulous.Render;

/// A chunked GPU buffer sub allocator.
///
/// Hands out ranges within large shared chunks rather than a buffer per allocation, which is
/// what keeps a scene of a thousand meshes from being a thousand buffers. Allocations bump
/// forward and last until the pool is cleared, and growth ADDS a chunk rather than
/// reallocating: an existing range keeps the buffer it was given, so growing never
/// invalidates one somebody is still drawing from.
class GpuBufferPool
{
	private struct Chunk
	{
		public IBuffer Buffer;
		public uint64 Used;
		public uint64 Size;
	}

	private IDevice mDevice;
	private BufferUsage mUsage;
	private uint64 mChunkSize;
	private String mLabel = new .() ~ delete _;

	private List<Chunk> mChunks = new .() ~ delete _;
	private int mCurrent = 0;

	public this(IDevice device, BufferUsage usage, uint64 chunkSize, StringView label)
	{
		mDevice = device;
		mUsage = usage;
		mChunkSize = chunkSize;
		mLabel.Set(label);
	}

	public ~this()
	{
		Clear();
	}

	public int ChunkCount => mChunks.Count;

	/// Sub allocates from the current chunk, adding one when it does not fit.
	public GpuBufferAlloc Allocate(uint64 size, uint64 alignment)
	{
		if (size == 0)
			return .();

		if (!mChunks.IsEmpty)
		{
			var chunk = mChunks[mCurrent];
			let aligned = AlignUp(chunk.Used, alignment);
			if ((aligned + size) <= chunk.Size)
			{
				chunk.Used = aligned + size;
				mChunks[mCurrent] = chunk;
				return .(chunk.Buffer, aligned);
			}
		}

		// A single allocation larger than a chunk gets a chunk of its own.
		if (!AddChunk(Max(size, mChunkSize)))
			return .();

		var chunk = mChunks[mCurrent];
		chunk.Used = size;
		mChunks[mCurrent] = chunk;
		return .(chunk.Buffer, 0);
	}

	public void Clear()
	{
		for (var chunk in ref mChunks)
		{
			if (chunk.Buffer != null)
				mDevice.DestroyBuffer(ref chunk.Buffer);
		}
		mChunks.Clear();
		mCurrent = 0;
	}

	private bool AddChunk(uint64 size)
	{
		var desc = BufferDesc();
		desc.Size = size;
		desc.Usage = mUsage;
		desc.Memory = .GpuOnly;
		desc.Label = mLabel;

		if (!(mDevice.CreateBuffer(desc) case .Ok(let buffer)))
			return false;

		mChunks.Add(.() { Buffer = buffer, Used = 0, Size = size });
		mCurrent = mChunks.Count - 1;
		return true;
	}

	private static uint64 AlignUp(uint64 value, uint64 alignment)
	{
		if (alignment <= 1)
			return value;
		return (value + alignment - 1) / alignment * alignment;
	}
}
