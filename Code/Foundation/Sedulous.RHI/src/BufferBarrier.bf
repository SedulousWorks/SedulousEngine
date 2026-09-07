namespace Sedulous.RHI;

/// A transition of part of a buffer between two uses.
struct BufferBarrier
{
	public IBuffer Buffer = null;
	public ResourceState OldState = .Undefined;
	public ResourceState NewState = .Undefined;
	public uint64 Offset = 0;
	/// The whole buffer from Offset, by default.
	public uint64 Size = uint64.MaxValue;

	public this() {}
}
