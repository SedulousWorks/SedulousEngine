using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Render;

/// A chunked bump allocator for ONE frame's render data.
///
/// Everything allocated from it is valid until the reset, which keeps the chunks for the next
/// frame rather than handing them back: a renderer that allocated and freed the same few
/// megabytes every frame would spend its time in the allocator.
///
/// NO DESTRUCTORS ARE RUN. Only trivially destructible data goes in here, which every render
/// data type is, and the reset simply rewinds the cursor.
class FrameArena : ITypedAllocator
{
	private const int cDefaultChunkSize = 64 * 1024;
	/// At least what any render data needs, a four by four matrix being the widest.
	private const int cChunkAlign = 16;

	private struct Chunk
	{
		public uint8* Data;
		public int Size;
	}

	private List<Chunk> mChunks = new .() ~ delete _;
	private int mChunkSize;
	/// The chunk being filled.
	private int mCurrent = 0;
	/// The bump cursor within it.
	private int mOffset = 0;

	public this(int chunkSize = cDefaultChunkSize)
	{
		mChunkSize = chunkSize;
	}

	public ~this()
	{
		for (let chunk in mChunks)
			Internal.StdFree(chunk.Data);
	}

	public int ChunkCount => mChunks.Count;

	public void* Alloc(int size, int align) => Allocate(size, align);

	public void* AllocTyped(Type type, int size, int align)
	{
		let memory = Allocate(size, align);
		if (memory == null)
			return null;

		// Zeroed, because a bump allocator hands back whatever the last frame left and a
		// field the caller does not set has to read as nothing rather than as debris.
		Internal.MemSet(memory, 0, size);
		return memory;
	}

	/// NOTHING is freed individually: that is what an arena is.
	public void Free(void* ptr) {}

	public void* Allocate(int size, int alignment)
	{
		if (size <= 0)
			return null;

		let align = Max(alignment, 1);

		if (!mChunks.IsEmpty)
		{
			let aligned = Align(mOffset, align);
			if ((aligned + size) <= mChunks[mCurrent].Size)
			{
				mOffset = aligned + size;
				return mChunks[mCurrent].Data + aligned;
			}

			// This chunk is full, so try the ones already allocated before making another:
			// a frame that peaked last time has them lying ready.
			for (int i = mCurrent + 1; i < mChunks.Count; i++)
			{
				if (size <= mChunks[i].Size)
				{
					mCurrent = i;
					mOffset = size;
					return mChunks[i].Data;
				}
			}
		}

		// A single allocation larger than a chunk gets a chunk of its own.
		if (!AddChunk(Max(mChunkSize, Align(size, cChunkAlign))))
			return null;

		mCurrent = mChunks.Count - 1;
		mOffset = size;
		return mChunks[mCurrent].Data;
	}

	/// Rewinds to the first chunk, KEEPING every chunk for the next frame.
	public void Reset()
	{
		mCurrent = 0;
		mOffset = 0;
	}

	private bool AddChunk(int size)
	{
		let data = (uint8*)Internal.StdMalloc(size);
		if (data == null)
			return false;

		mChunks.Add(.() { Data = data, Size = size });
		return true;
	}

	private static int Align(int value, int alignment) => (value + alignment - 1) & ~(alignment - 1);
}
