namespace Sedulous.Render;

/// A run of slots handed out of the dynamic ring for this frame.
struct DynamicUniformRange
{
	/// The ABSOLUTE index of the first slot, which is what a structured buffer indexes by.
	public uint32 SlotIndex = 0;
	/// Its byte offset, which is what a dynamic offset binding or a vertex buffer offset
	/// takes.
	public uint32 ByteOffset = 0;
	/// Writable for the whole run.
	public void* Ptr = null;
	public bool Ok = false;

	public this() {}

	public this(uint32 slotIndex, uint32 byteOffset, void* ptr)
	{
		SlotIndex = slotIndex;
		ByteOffset = byteOffset;
		Ptr = ptr;
		Ok = true;
	}
}
