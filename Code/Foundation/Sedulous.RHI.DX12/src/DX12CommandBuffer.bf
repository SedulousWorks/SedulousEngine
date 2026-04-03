namespace Sedulous.RHI.DX12;

using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of ICommandBuffer.
/// Wraps a closed ID3D12GraphicsCommandList.
class DX12CommandBuffer : ICommandBuffer
{
	private ID3D12GraphicsCommandList* mCommandList;

	public this(ID3D12GraphicsCommandList* commandList)
	{
		mCommandList = commandList;
	}

	/// Releases the underlying command list COM object.
	public void ReleaseCommandList()
	{
		if (mCommandList != null)
		{
			mCommandList.Release();
			mCommandList = null;
		}
	}

	// --- Internal ---
	public ID3D12GraphicsCommandList* Handle => mCommandList;
}
