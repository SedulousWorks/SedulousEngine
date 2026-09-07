using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// A buffer backed by REAL CPU memory.
///
/// Actually allocating is what makes the null backend useful: a headless test can map a
/// buffer, write to it and read it back, which is most of what a copy or upload path needs
/// to be exercised without a GPU.
class NullBuffer : IBuffer
{
	private BufferDesc mDesc;
	private List<uint8> mData = new .() ~ delete _;

	public BufferDesc Desc => mDesc;

	public void Initialize(BufferDesc desc)
	{
		mDesc = desc;
		mData.Resize((int)desc.Size);
		if (!mData.IsEmpty)
			Internal.MemSet(mData.Ptr, 0, mData.Count);
	}

	/// Always mappable, whatever the memory location says: there is no device memory here
	/// to be unreachable from the CPU.
	public void* Map() => mData.IsEmpty ? null : mData.Ptr;

	public void Unmap() {}
}
