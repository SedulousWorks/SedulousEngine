using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core;

namespace Sedulous.Render;

/// A chunked GPU buffer sub allocator.
///
/// Hands out ranges within large shared chunks rather than a buffer per allocation, which is
/// what keeps a scene of a thousand meshes from being a thousand buffers. A range given back
/// (Free, once the GPU is done with it) is reused by a later allocation that fits; otherwise
/// allocations bump forward, and growth ADDS a chunk rather than reallocating: an existing
/// range keeps the buffer it was given, so growing never invalidates one somebody is still
/// drawing from.
class GpuBufferPool
{
	private struct Chunk
	{
		public IBuffer Buffer;
		public uint64 Used;
		public uint64 Size;
	}

	/// A range given back and waiting to be reused.
	private struct Range
	{
		public IBuffer Buffer;
		public uint64 Offset;
		public uint64 Size;
	}

	private IDevice mDevice;
	private BufferUsage mUsage;
	private uint64 mChunkSize;
	private String mLabel = new .() ~ delete _;

	private List<Chunk> mChunks = new .() ~ delete _;
	private int mCurrent = 0;
	private List<Range> mFree = new .() ~ delete _;

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

	/// Bytes given back and waiting to be reused.
	public uint64 FreeBytes
	{
		get
		{
			uint64 total = 0;
			for (let range in mFree)
				total += range.Size;
			return total;
		}
	}

	/// Sub allocates from a range given back that it fits in, else from the current chunk,
	/// adding one when it does not fit.
	public GpuBufferAlloc Allocate(uint64 size, uint64 alignment)
	{
		if (size == 0)
			return .();

		// What freed ranges left is reused first, rather than leaked behind the bump pointer.
		for (int i = 0; i < mFree.Count; i++)
		{
			var range = mFree[i];
			let aligned = AlignUp(range.Offset, alignment);
			let end = range.Offset + range.Size;
			if ((aligned + size) > end)
				continue;

			let result = GpuBufferAlloc(range.Buffer, aligned);
			if (aligned > range.Offset)
			{
				// The alignment gap stays free in front, and any tail behind becomes its own range.
				range.Size = aligned - range.Offset;
				mFree[i] = range;
				if ((aligned + size) < end)
					mFree.Add(.() { Buffer = range.Buffer, Offset = aligned + size, Size = end - (aligned + size) });
			}
			else if ((aligned + size) < end)
			{
				range.Offset = aligned + size;
				range.Size = end - range.Offset;
				mFree[i] = range;
			}
			else
			{
				mFree.RemoveAtFast(i);
			}
			return result;
		}

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

	/// Gives a range back for reuse. The caller frees it only once no frame in flight reads it.
	public void Free(GpuBufferAlloc alloc, uint64 size)
	{
		if (!alloc.Ok || (size == 0))
			return;

		// Merged with a free neighbour in the same buffer, so freed ranges do not crumble.
		for (var range in ref mFree)
		{
			if (range.Buffer != alloc.Buffer)
				continue;
			if ((range.Offset + range.Size) == alloc.Offset)
			{
				range.Size += size;
				return;
			}
			if ((alloc.Offset + size) == range.Offset)
			{
				range.Offset = alloc.Offset;
				range.Size += size;
				return;
			}
		}
		mFree.Add(.() { Buffer = alloc.Buffer, Offset = alloc.Offset, Size = size });
	}

	public void Clear()
	{
		mFree.Clear();
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
