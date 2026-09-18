using System;
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// Records draws into a BUNDLE, by delegating to a render pass encoder pointed at the bundle's
/// own command list.
///
/// A bundle is a small pre recorded command list a pass can replay, so the recording surface
/// is the same one a pass uses; only the list underneath differs. That is why this holds a
/// render pass encoder rather than duplicating every draw method's body.
///
/// It owns the list, the allocator and the bundle it finishes. The bundle takes its OWN
/// references to the first two, because it outlives nothing but is destroyed separately.
class DxRenderBundleEncoder : IRenderBundleEncoder
{
	private DxRenderPassEncoder mRec = null ~ delete _;
	private ID3D12GraphicsCommandList* mList = null; // owned
	private ID3D12CommandAllocator* mAlloc = null; // owned
	private DxRenderBundle mBundle = null; // owned once finished

	public this(DxRenderPassContext ctx, ID3D12GraphicsCommandList* list,
		ID3D12CommandAllocator* alloc)
	{
		mList = list;
		mAlloc = alloc;

		mRec = new DxRenderPassEncoder(ctx);
		// An empty description: a bundle has no attachments, this only resets the pipeline
		// tracking the recorder keeps.
		mRec.Begin(.());
	}

	public void SetPipeline(IRenderPipeline p) => mRec.SetPipeline(p);

	public void SetBindGroup(uint32 i, IBindGroup g, Span<uint32> d = default) =>
		mRec.SetBindGroup(i, g, d);

	public void SetPushConstants(ShaderStage s, uint32 o, uint32 sz, void* d) =>
		mRec.SetPushConstants(s, o, sz, d);

	public void SetVertexBuffer(uint32 slot, IBuffer b, uint64 o = 0) =>
		mRec.SetVertexBuffer(slot, b, o);

	public void SetIndexBuffer(IBuffer b, IndexFormat f, uint64 o = 0) =>
		mRec.SetIndexBuffer(b, f, o);

	public void Draw(uint32 v, uint32 inst = 1, uint32 fv = 0, uint32 fi = 0) =>
		mRec.Draw(v, inst, fv, fi);

	public void DrawIndexed(uint32 ic, uint32 inst = 1, uint32 fi = 0, int32 bv = 0,
		uint32 finst = 0) => mRec.DrawIndexed(ic, inst, fi, bv, finst);

	public void DrawIndirect(IBuffer b, uint64 o, uint32 dc = 1, uint32 st = 0) =>
		mRec.DrawIndirect(b, o, dc, st);

	public void DrawIndexedIndirect(IBuffer b, uint64 o, uint32 dc = 1, uint32 st = 0) =>
		mRec.DrawIndexedIndirect(b, o, dc, st);

	/// Closes the list and hands back the bundle. Idempotent: finishing twice answers the
	/// same bundle rather than closing a closed list.
	public IRenderBundle Finish()
	{
		if (mBundle != null)
			return mBundle;

		mList.Close();

		// The bundle takes references of its own, so it and this can be destroyed in either
		// order without the other's handles going out from under it.
		mList.AddRef();
		mAlloc.AddRef();

		// The root signature and pipeline state the recorder ended on, which the parent list
		// has to carry before this bundle runs.
		mBundle = new DxRenderBundle(mList, mAlloc, mRec.CurrentRootSig, mRec.CurrentPso);
		return mBundle;
	}

	public void Cleanup()
	{
		if (mBundle != null)
		{
			mBundle.Cleanup();
			delete mBundle;
			mBundle = null;
		}

		if (mList != null) { mList.Release(); mList = null; }
		if (mAlloc != null) { mAlloc.Release(); mAlloc = null; }
	}
}
