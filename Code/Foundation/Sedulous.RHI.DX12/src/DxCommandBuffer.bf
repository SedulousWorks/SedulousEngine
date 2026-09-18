#if BF_PLATFORM_WINDOWS
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// A finished recording, ready to submit.
///
/// UNLIKE the Vulkan backend, where the pool owns the buffer and recycles it on reset, a
/// D3D12 command list is a COM object this holds a reference to. Release gives it up.
class DxCommandBuffer : ICommandBuffer
{
	private ID3D12GraphicsCommandList* mCommandList;

	public this(ID3D12GraphicsCommandList* commandList) => mCommandList = commandList;

	public ID3D12GraphicsCommandList* Handle => mCommandList;

	public void Release()
	{
		if (mCommandList != null)
		{
			mCommandList.Release();
			mCommandList = null;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
