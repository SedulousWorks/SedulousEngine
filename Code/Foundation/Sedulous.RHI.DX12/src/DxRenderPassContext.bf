#if BF_PLATFORM_WINDOWS
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// What a render pass encoder needs, handed to it by the command encoder.
///
/// Borrowed pointers only, the same as the compute one: the encoder records into the command
/// encoder's list, stages through the pool's staging, and binds out of the device's heaps.
struct DxRenderPassContext
{
	public ID3D12GraphicsCommandList* CmdList = null;
	public DxDescriptorStaging SrvStaging = null;
	public DxGpuDescriptorHeap GpuSrvHeap = null;
	public DxGpuDescriptorHeap GpuSamplerHeap = null;
	/// The indirect signatures, cached on the device.
	public ID3D12CommandSignature* DrawSig = null;
	public ID3D12CommandSignature* DrawIndexedSig = null;
	public ID3D12CommandSignature* DispatchMeshSig = null;

	public this() {}
}

#endif // BF_PLATFORM_WINDOWS
