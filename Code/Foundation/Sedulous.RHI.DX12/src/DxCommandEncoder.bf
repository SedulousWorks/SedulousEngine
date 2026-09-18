using System;
using System.Collections;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// Recording OUTSIDE a pass: barriers, copies, queries and acceleration structure builds, and
/// the entry point to the pass encoders.
///
/// The two pass encoders are held BY THE ENCODER and handed out by reference rather than
/// allocated per pass, because a frame opens many passes and each would otherwise cost an
/// allocation. That is why beginning a pass resets their tracking rather than constructing
/// them.
class DxCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private DxDevice mDevice = null; // NOT owned
	private ID3D12GraphicsCommandList* mCmdList = null; // NOT owned, the pool made it
	private DxCommandPool mPool = null; // NOT owned, the pool owns this
	private DxRayTracingPipeline mCurrentRtPipeline = null; // NOT owned
	private bool mDescriptorHeapsSet = false;

	private DxGpuDescriptorHeap mGpuSrvHeap = null; // NOT owned, the device's
	private DxGpuDescriptorHeap mGpuSamplerHeap = null;

	private DxRenderPassEncoder mRpe = null ~ delete _;
	private DxComputePassEncoder mCpe = null ~ delete _;
	private DxRenderPassContext mRpeCtx = .();

	public ID3D12GraphicsCommandList* CmdList => mCmdList;
	public DxDevice OwnerDevice => mDevice;
	public DxDescriptorStaging SrvStaging => mPool.SrvStaging;

	public this(DxDevice device, ID3D12GraphicsCommandList* cmdList, DxCommandPool pool,
		DxRenderPassContext rpeCtx, DxComputePassContext cpeCtx)
	{
		mDevice = device;
		mCmdList = cmdList;
		mPool = pool;
		mGpuSrvHeap = rpeCtx.GpuSrvHeap;
		mGpuSamplerHeap = rpeCtx.GpuSamplerHeap;
		mRpeCtx = rpeCtx;

		mRpe = new DxRenderPassEncoder(rpeCtx);
		mCpe = new DxComputePassEncoder(cpeCtx);
	}

	/// The shader visible heaps, set ONCE per list. D3D12 allows only one of each bound at a
	/// time and changing them mid list is a flush, so this is done lazily on the first pass
	/// and never again.
	private void EnsureDescriptorHeaps()
	{
		if (mDescriptorHeapsSet)
			return;
		mDescriptorHeapsSet = true;

		ID3D12DescriptorHeap*[2] heaps = .(mGpuSrvHeap.Heap, mGpuSamplerHeap.Heap);
		mCmdList.SetDescriptorHeaps(2, &heaps[0]);
	}

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		EnsureDescriptorHeaps();

		if (desc.TimestampQuerySet != null)
		{
			if (let qs = desc.TimestampQuerySet as DxQuerySet)
			{
				mCmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP,
					desc.BeginTimestampIndex);
			}
		}

		// The render target views are packed CONTIGUOUSLY, skipping any null view, and cleared
		// in the same pass so the handles stay aligned with the count. Writing at the loop
		// index while counting separately would, on a null gap, leave a null handle inside the
		// count handed to OMSetRenderTargets.
		D3D12_CPU_DESCRIPTOR_HANDLE[8] rtvHandles = .();
		uint32 rtvCount = 0;

		for (let att in ref desc.ColorAttachments)
		{
			if (rtvCount >= 8)
				break;

			let dxView = att.View as DxTextureView;
			if (dxView == null)
				continue;

			let rtv = dxView.GetRtv();
			rtvHandles[(int)rtvCount] = rtv;
			rtvCount++;

			if (att.LoadOp == .Clear)
			{
				float[4] color = .(att.ClearValue.R, att.ClearValue.G, att.ClearValue.B,
					att.ClearValue.A);
				mCmdList.ClearRenderTargetView(rtv, &color[0], 0, null);
			}
		}

		D3D12_CPU_DESCRIPTOR_HANDLE dsvStorage = .();
		D3D12_CPU_DESCRIPTOR_HANDLE* dsvPtr = null;
		if (desc.DepthStencilAttachment.HasValue)
		{
			if (let dxView = desc.DepthStencilAttachment.Value.View as DxTextureView)
			{
				dsvStorage = dxView.GetDsv();
				dsvPtr = &dsvStorage;
			}
		}

		mCmdList.OMSetRenderTargets(rtvCount, &rtvHandles[0], FALSE, dsvPtr);

		if (desc.DepthStencilAttachment.HasValue && (dsvPtr != null))
		{
			let dsAttach = desc.DepthStencilAttachment.Value;
			D3D12_CLEAR_FLAGS clearFlags = default;
			var needsClear = false;

			if (dsAttach.DepthLoadOp == .Clear)
			{
				clearFlags |= .D3D12_CLEAR_FLAG_DEPTH;
				needsClear = true;
			}
			if (dsAttach.StencilLoadOp == .Clear)
			{
				clearFlags |= .D3D12_CLEAR_FLAG_STENCIL;
				needsClear = true;
			}

			if (needsClear)
			{
				mCmdList.ClearDepthStencilView(*dsvPtr, clearFlags, dsAttach.DepthClearValue,
					(uint8)dsAttach.StencilClearValue, 0, null);
			}
		}

		mRpe.Begin(desc);
		return mRpe;
	}

	public IComputePassEncoder BeginComputePass(StringView label = default)
	{
		EnsureDescriptorHeaps();
		mCpe.Begin();
		return mCpe;
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		// Bundles are POOL scoped, owned by the pool and freed on its Reset, and creating one
		// needs no open list. The executing list's descriptor heaps are set by BeginRenderPass
		// before any ExecuteBundles.
		return mPool.CreateRenderBundleEncoder(desc);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DxQuerySet)
			mCmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, index);
	}

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
		// D3D12 needs no explicit reset: a query is reset implicitly when it is written.
	}

	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset)
	{
		let qs = querySet as DxQuerySet;
		let dxDst = dst as DxBuffer;
		if ((qs == null) || (dxDst == null))
			return;

		mCmdList.ResolveQueryData(qs.Handle, DxQuerySet.ToDxQueryType(qs.Type), first, count,
			dxDst.Handle, dstOffset);
	}

	// PIX events would go here. Without the PIX runtime there is nothing to emit, and the
	// Vulkan backend's labels are equally absent without the debug utils extension.
	public void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0,
		float a = 1) {}
	public void EndDebugLabel() {}
	public void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0,
		float a = 1) {}

	public ICommandBuffer Finish()
	{
		mCmdList.Close();
		mPool.MarkEncoderFinished(); // the list is closed, so the pool may Reset safely

		// The buffer is handed to the POOL to own, which frees it on Reset behind the fence.
		let cb = new DxCommandBuffer(mCmdList);
		mPool.TrackCommandBuffer(cb);
		return cb;
	}

	// ==================================================================
	// PARTIALLY PORTED. The barriers, the copies, the blit and mipmap paths, the resolve and
	// the whole ray tracing extension are still in RaptorCode/Foundation/RHI.DX12, which says
	// what remains. They answer as no-ops here rather than pretending to record.
	// ==================================================================

	/// One coalesced transition for a single subresource: where it started, where it ends.
	private struct CoalescedEntry
	{
		public ID3D12Resource* Resource;
		public uint32 Subresource;
		public D3D12_RESOURCE_STATES FirstBefore;
		public D3D12_RESOURCE_STATES LastAfter;
	}

	public void Barrier(BarrierGroup group)
	{
		let total = group.BufferBarriers.Length + group.TextureBarriers.Length +
			group.MemoryBarriers.Length;
		if (total == 0)
			return;

		let dxBarriers = scope List<D3D12_RESOURCE_BARRIER>();
		dxBarriers.Reserve(total);

		for (let bb in group.BufferBarriers)
		{
			let dxBuf = bb.Buffer as DxBuffer;
			if (dxBuf == null)
				continue;

			let oldState = ToResourceStates(bb.OldState);
			let newState = ToResourceStates(bb.NewState);
			if (oldState == newState)
				continue;

			D3D12_RESOURCE_BARRIER b = .();
			b.Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			b.Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
			b.Transition.pResource = dxBuf.Handle;
			b.Transition.StateBefore = oldState;
			b.Transition.StateAfter = newState;
			b.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
			dxBuf.SetState(newState);
			dxBarriers.Add(b);
		}

		// Texture barriers are COALESCED per resource and subresource before being emitted.
		// The solver can produce several for one texture in a single batch: ParticlePass
		// declares both ReadDepth and ReadTexture on SceneDepth, giving DEPTH_WRITE to
		// DEPTH_READ and then DEPTH_READ to SHADER_READ. D3D12 applies every barrier in one
		// call SIMULTANEOUSLY, so the second one's before state would not match reality.
		// Folding A to B and B to C into a single A to C is what makes the batch legal.
		let coalesced = scope List<CoalescedEntry>();
		coalesced.Reserve(group.TextureBarriers.Length);

		for (let tb in group.TextureBarriers)
		{
			let dxTex = tb.Texture as DxTexture;
			if (dxTex == null)
				continue;

			let newState = ToResourceStates(tb.NewState, dxTex.Desc.Format);

			// ALL_SUBRESOURCES is legal only when every subresource really is in one state. In
			// per subresource mode the single state is a stale leftover, so the barrier would
			// carry the wrong before state; the per subresource path below reads each real
			// state instead, and collapses the tracker back to uniform on the way out.
			let isWholeResource = (tb.MipLevelCount == uint32.MaxValue) &&
				(tb.ArrayLayerCount == uint32.MaxValue) && dxTex.HasUniformState;

			if (isWholeResource)
			{
				let resolvedOldState = dxTex.CurrentState;
				if (resolvedOldState == newState)
					continue;

				var found = false;
				for (var entry in ref coalesced)
				{
					if ((entry.Resource == dxTex.Handle) &&
						(entry.Subresource == D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES))
					{
						entry.LastAfter = newState;
						found = true;
						break;
					}
				}

				if (!found)
				{
					coalesced.Add(.() {
						Resource = dxTex.Handle,
						Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES,
						FirstBefore = resolvedOldState,
						LastAfter = newState
					});
				}

				dxTex.SetState(newState);
			}
			else
			{
				let mipCount = dxTex.Desc.MipLevelCount;
				let layerCount = dxTex.StateLayerCount;
				let baseMip = tb.BaseMipLevel;
				let mipEnd = Math.Min(baseMip + tb.MipLevelCount, mipCount);
				let baseLayer = tb.BaseArrayLayer;
				let layerEnd = Math.Min(baseLayer + tb.ArrayLayerCount, layerCount);

				for (uint32 layer = baseLayer; layer < layerEnd; layer++)
				{
					for (uint32 mip = baseMip; mip < mipEnd; mip++)
					{
						let resolvedOldState = dxTex.GetSubresourceState(mip, layer);
						let sub = mip + layer * mipCount;
						if (resolvedOldState == newState)
							continue;

						var found = false;
						for (var entry in ref coalesced)
						{
							if ((entry.Resource == dxTex.Handle) && (entry.Subresource == sub))
							{
								entry.LastAfter = newState;
								found = true;
								break;
							}
						}

						if (!found)
						{
							coalesced.Add(.() {
								Resource = dxTex.Handle,
								Subresource = sub,
								FirstBefore = resolvedOldState,
								LastAfter = newState
							});
						}
					}
				}

				dxTex.SetSubresourceState(baseMip, tb.MipLevelCount, baseLayer, tb.ArrayLayerCount,
					newState);
			}
		}

		for (let entry in coalesced)
		{
			if (entry.FirstBefore == entry.LastAfter)
				continue; // A to B to A, which cancelled out

			D3D12_RESOURCE_BARRIER b = .();
			b.Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			b.Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
			b.Transition.pResource = entry.Resource;
			b.Transition.StateBefore = entry.FirstBefore;
			b.Transition.StateAfter = entry.LastAfter;
			b.Transition.Subresource = entry.Subresource;
			dxBarriers.Add(b);
		}

		// A memory barrier is a global UAV barrier, which is the nearest D3D12 has.
		for (let mb in group.MemoryBarriers)
		{
			D3D12_RESOURCE_BARRIER b = .();
			b.Type = .D3D12_RESOURCE_BARRIER_TYPE_UAV;
			b.Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
			b.UAV.pResource = null;
			dxBarriers.Add(b);
		}

		if (!dxBarriers.IsEmpty)
			mCmdList.ResourceBarrier((uint32)dxBarriers.Count, dxBarriers.Ptr);
	}

	public static D3D12_RESOURCE_STATES ToResourceStates(ResourceState state) =>
		ToResourceStates(state, .Undefined);

	/// The RHI's state set as D3D12's, which needs the FORMAT: a depth texture being sampled
	/// goes to DEPTH_READ rather than to the shader resource states.
	public static D3D12_RESOURCE_STATES ToResourceStates(ResourceState state, TextureFormat format)
	{
		if (state == .Undefined)
			return .D3D12_RESOURCE_STATE_COMMON;

		D3D12_RESOURCE_STATES result = .D3D12_RESOURCE_STATE_COMMON;

		if (state.HasFlag(.VertexBuffer))
			result |= .D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;
		if (state.HasFlag(.IndexBuffer))
			result |= .D3D12_RESOURCE_STATE_INDEX_BUFFER;
		if (state.HasFlag(.UniformBuffer))
			result |= .D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;

		if (state.HasFlag(.ShaderRead))
		{
			if (TextureFormats.IsDepthFormat(format))
			{
				result |= .D3D12_RESOURCE_STATE_DEPTH_READ;
			}
			else
			{
				result |= .D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
				result |= .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
			}
		}

		if (state.HasFlag(.ShaderWrite))
			result |= .D3D12_RESOURCE_STATE_UNORDERED_ACCESS;
		if (state.HasFlag(.RenderTarget))
			result |= .D3D12_RESOURCE_STATE_RENDER_TARGET;
		if (state.HasFlag(.DepthStencilWrite))
			result |= .D3D12_RESOURCE_STATE_DEPTH_WRITE;
		if (state.HasFlag(.DepthStencilRead))
			result |= .D3D12_RESOURCE_STATE_DEPTH_READ;
		if (state.HasFlag(.IndirectArgument))
			result |= .D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT;
		if (state.HasFlag(.CopySrc))
			result |= .D3D12_RESOURCE_STATE_COPY_SOURCE;
		if (state.HasFlag(.CopyDst))
			result |= .D3D12_RESOURCE_STATE_COPY_DEST;
		if (state.HasFlag(.Present))
			result |= .D3D12_RESOURCE_STATE_PRESENT;
		if (state.HasFlag(.General))
			result |= .D3D12_RESOURCE_STATE_COMMON;
		if (state.HasFlag(.AccelStructRead))
			result |= .D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE;
		if (state.HasFlag(.AccelStructWrite))
			result |= .D3D12_RESOURCE_STATE_UNORDERED_ACCESS;

		return result;
	}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size) {}
	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region) {}

	public void Blit(ITexture src, ITexture dst) {}
	public void GenerateMipmaps(ITexture texture) {}
	public void ResolveTexture(ITexture src, ITexture dst) {}

	public void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs) {}
	public void BuildTopLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, IBuffer instanceBuffer, uint64 instanceOffset,
		uint32 instanceCount) {}
	public void SetRayTracingPipeline(IRayTracingPipeline pipeline) {}
	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default) {}
	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data) {}
	public void TraceRays(IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1) {}
}
