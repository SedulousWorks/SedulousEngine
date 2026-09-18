using Sedulous.RHI;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// A recorded bundle: its command list, and the allocator behind it.
///
/// The ALLOCATOR is held alongside the list because a command allocator must outlive every
/// execution of what was recorded into it. Releasing it when recording finished would free
/// the memory the bundle's commands live in.
///
/// The root signature and pipeline state are remembered because D3D12 requires the PARENT
/// list to have both set before ExecuteBundle; a bundle does not carry its own.
class DxRenderBundle : IRenderBundle
{
	private ID3D12GraphicsCommandList* mList = null; // owned
	private ID3D12CommandAllocator* mAlloc = null; // owned, outlives execution
	private ID3D12RootSignature* mRootSig = null; // NOT owned, the layout's
	private ID3D12PipelineState* mPso = null; // NOT owned, the pipeline's

	public ID3D12GraphicsCommandList* Handle => mList;
	public ID3D12RootSignature* RootSig => mRootSig;
	public ID3D12PipelineState* Pso => mPso;

	public this(ID3D12GraphicsCommandList* list, ID3D12CommandAllocator* alloc,
		ID3D12RootSignature* rootSig = null, ID3D12PipelineState* pso = null)
	{
		mList = list;
		mAlloc = alloc;
		mRootSig = rootSig;
		mPso = pso;
	}

	public void Cleanup()
	{
		if (mList != null) { mList.Release(); mList = null; }
		if (mAlloc != null) { mAlloc.Release(); mAlloc = null; }
	}
}
