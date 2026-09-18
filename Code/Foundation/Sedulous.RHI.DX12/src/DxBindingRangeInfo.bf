using Sedulous.RHI;

namespace Sedulous.RHI.DX12;

/// One binding of a layout, resolved to WHERE it sits in a descriptor table.
///
/// D3D12 binds tables of contiguous descriptors rather than individual resources, so a layout
/// has to decide each binding's offset within its table up front. Samplers are counted
/// separately because they live in their own heap and their own table.
struct DxBindingRangeInfo
{
	public uint32 Binding = 0;
	public BindingType Type = .UniformBuffer;
	public uint32 Count = 0;
	/// Offset within this group's table, in descriptors.
	public uint32 HeapOffset = 0;
	public bool IsSampler = false;
	public bool HasDynamicOffset = false;
	public uint32 StorageBufferStride = 0;

	public this() {}
}
