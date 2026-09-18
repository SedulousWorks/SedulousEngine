using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// A binding that is bound as a ROOT DESCRIPTOR rather than through a table.
///
/// Dynamic offsets are the reason this exists: a root descriptor's address is set per draw, so
/// changing the offset costs a root parameter write instead of rewriting a descriptor table.
/// The encoder needs to know which root parameter to write, hence the index recorded here.
struct DynamicRootEntry
{
	public uint32 GroupIndex = 0;
	public uint32 DynamicIndex = 0;
	public int32 RootParamIndex = -1;
	public D3D12_ROOT_PARAMETER_TYPE ParamType = .D3D12_ROOT_PARAMETER_TYPE_CBV;

	public this() {}
}
