using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// What a compute pass encoder needs, handed to it by the command encoder.
///
/// A pass encoder owns none of this. It records into the command encoder's list, stages
/// through the command pool's staging, and binds out of the device's heaps, so the context is
/// a bundle of borrowed pointers rather than a thing with a lifetime of its own.
struct DxComputePassContext
{
	public ID3D12GraphicsCommandList* CmdList = null;
	public DxDescriptorStaging SrvStaging = null;
	public DxGpuDescriptorHeap GpuSrvHeap = null;
	public DxGpuDescriptorHeap GpuSamplerHeap = null;
	/// The indirect dispatch signature, cached on the device.
	public ID3D12CommandSignature* DispatchSig = null;

	public this() {}
}
