#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

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
		uint64 size)
	{
		let dxSrc = src as DxBuffer;
		let dxDst = dst as DxBuffer;
		if ((dxSrc == null) || (dxDst == null))
			return;

		mCmdList.CopyBufferRegion(dxDst.Handle, dstOffset, dxSrc.Handle, srcOffset, size);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		let dxSrc = src as DxBuffer;
		let dxTex = dst as DxTexture;
		if ((dxSrc == null) || (dxTex == null))
			return;

		let subresource = region.TextureMipLevel +
			region.TextureArrayLayer * dxTex.Desc.MipLevelCount;

		// A buffer side of a texture copy is a PLACED FOOTPRINT: the buffer has no format or
		// extent of its own, so the copy names them here.
		D3D12_TEXTURE_COPY_LOCATION srcLoc = .();
		srcLoc.pResource = dxSrc.Handle;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		srcLoc.PlacedFootprint.Offset = region.BufferOffset;
		srcLoc.PlacedFootprint.Footprint.Format = DxConversions.ToDxgiFormat(dxTex.Desc.Format);
		srcLoc.PlacedFootprint.Footprint.Width = region.TextureExtent.Width;
		srcLoc.PlacedFootprint.Footprint.Height = region.TextureExtent.Height;
		srcLoc.PlacedFootprint.Footprint.Depth = region.TextureExtent.Depth;
		srcLoc.PlacedFootprint.Footprint.RowPitch = region.BytesPerRow;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = .();
		dstLoc.pResource = dxTex.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dstLoc.SubresourceIndex = subresource;

		mCmdList.CopyTextureRegion(&dstLoc, region.TextureOrigin.X, region.TextureOrigin.Y,
			region.TextureOrigin.Z, &srcLoc, null);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		let dxTex = src as DxTexture;
		let dxDst = dst as DxBuffer;
		if ((dxTex == null) || (dxDst == null))
			return;

		let subresource = region.TextureMipLevel +
			region.TextureArrayLayer * dxTex.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = .();
		srcLoc.pResource = dxTex.Handle;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		srcLoc.SubresourceIndex = subresource;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = .();
		dstLoc.pResource = dxDst.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		dstLoc.PlacedFootprint.Offset = region.BufferOffset;
		dstLoc.PlacedFootprint.Footprint.Format = DxConversions.ToDxgiFormat(dxTex.Desc.Format);
		dstLoc.PlacedFootprint.Footprint.Width = region.TextureExtent.Width;
		dstLoc.PlacedFootprint.Footprint.Height = region.TextureExtent.Height;
		dstLoc.PlacedFootprint.Footprint.Depth = region.TextureExtent.Depth;
		dstLoc.PlacedFootprint.Footprint.RowPitch = region.BytesPerRow;

		// The origin moves to the SOURCE BOX here, because the destination is the buffer.
		D3D12_BOX srcBox = .();
		srcBox.left = region.TextureOrigin.X;
		srcBox.top = region.TextureOrigin.Y;
		srcBox.front = region.TextureOrigin.Z;
		srcBox.right = region.TextureOrigin.X + region.TextureExtent.Width;
		srcBox.bottom = region.TextureOrigin.Y + region.TextureExtent.Height;
		srcBox.back = region.TextureOrigin.Z + region.TextureExtent.Depth;

		mCmdList.CopyTextureRegion(&dstLoc, 0, 0, 0, &srcLoc, &srcBox);
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		let dxSrc = src as DxTexture;
		let dxDst = dst as DxTexture;
		if ((dxSrc == null) || (dxDst == null))
			return;

		let srcSub = region.SrcMipLevel + region.SrcArrayLayer * dxSrc.Desc.MipLevelCount;
		let dstSub = region.DstMipLevel + region.DstArrayLayer * dxDst.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = .();
		srcLoc.pResource = dxSrc.Handle;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		srcLoc.SubresourceIndex = srcSub;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = .();
		dstLoc.pResource = dxDst.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dstLoc.SubresourceIndex = dstSub;

		D3D12_BOX srcBox = .();
		srcBox.left = 0;
		srcBox.top = 0;
		srcBox.front = 0;
		srcBox.right = region.Extent.Width;
		srcBox.bottom = region.Extent.Height;
		srcBox.back = region.Extent.Depth;

		mCmdList.CopyTextureRegion(&dstLoc, 0, 0, 0, &srcLoc, &srcBox);
	}

	/// One subresource through the device's fullscreen triangle pipeline.
	///
	/// Expects the source subresource already in a shader resource state and the destination
	/// in render target. Both descriptors are TEMPORARY: the render target view comes from the
	/// device's RTV heap and goes back at the end, and the shader resource view is written
	/// into the CPU heap, staged into the shader visible one, and its CPU slot freed at once.
	private void BlitSubresource(DxTexture srcTex, uint32 srcMip, DxTexture dstTex, uint32 dstMip,
		uint32 dstWidth, uint32 dstHeight, DXGI_FORMAT dxgiFormat)
	{
		let blitRootSig = mDevice.BlitRootSignature;
		if (blitRootSig == null)
			return;

		let blitPso = mDevice.GetOrCreateBlitPSO(dxgiFormat);
		if (blitPso == null)
			return;

		let rtvHandle = mDevice.RtvHeap.Allocate();
		D3D12_RENDER_TARGET_VIEW_DESC rtvDesc = .();
		rtvDesc.Format = dxgiFormat;
		rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2D;
		rtvDesc.Texture2D.MipSlice = dstMip;
		mDevice.Handle.CreateRenderTargetView(dstTex.Handle, &rtvDesc, rtvHandle);

		let tempSrvOff = mDevice.CpuSrvHeap.Allocate(1);
		if (tempSrvOff < 0)
		{
			mDevice.RtvHeap.Free(rtvHandle);
			return;
		}

		let tempCpuHandle = mDevice.CpuSrvHeap.GetCpuHandle((uint32)tempSrvOff);
		D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = .();
		srvDesc.Format = dxgiFormat;
		srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2D;
		srvDesc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
		srvDesc.Texture2D.MostDetailedMip = srcMip;
		srvDesc.Texture2D.MipLevels = 1;
		mDevice.Handle.CreateShaderResourceView(srcTex.Handle, &srvDesc, tempCpuHandle);

		let stagedOff = mPool.SrvStaging.CopyFrom((uint32)tempSrvOff, 1);
		mDevice.CpuSrvHeap.Free((uint32)tempSrvOff, 1);
		if (stagedOff < 0)
		{
			mDevice.RtvHeap.Free(rtvHandle);
			return;
		}

		let srvGpuHandle = mDevice.GpuSrvHeap.GetGpuHandle((uint32)stagedOff);
		EnsureDescriptorHeaps();

		mCmdList.SetGraphicsRootSignature(blitRootSig);
		mCmdList.SetPipelineState(blitPso);
		mCmdList.SetGraphicsRootDescriptorTable(0, srvGpuHandle);

		var rtv = rtvHandle;
		mCmdList.OMSetRenderTargets(1, &rtv, FALSE, null);

		D3D12_VIEWPORT vp = .();
		vp.Width = (float)dstWidth;
		vp.Height = (float)dstHeight;
		vp.MaxDepth = 1.0f;
		mCmdList.RSSetViewports(1, &vp);

		D3D12_RECT sc = .();
		sc.right = (int32)dstWidth;
		sc.bottom = (int32)dstHeight;
		mCmdList.RSSetScissorRects(1, &sc);

		// Three vertices and no buffers: the vertex shader builds the triangle from its id.
		mCmdList.IASetPrimitiveTopology(.D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		mCmdList.DrawInstanced(3, 1, 0, 0);

		mDevice.RtvHeap.Free(rtvHandle);
	}

	public void Blit(ITexture src, ITexture dst)
	{
		let dxSrc = src as DxTexture;
		let dxDst = dst as DxTexture;
		if ((dxSrc == null) || (dxDst == null))
			return;

		let dxgiFormat = DxConversions.ToDxgiFormat(dxDst.Desc.Format);

		// The caller has both in copy states; a draw needs them shader readable and render
		// targetable, so they go there and straight back.
		D3D12_RESOURCE_BARRIER[2] barriers = .();
		barriers[0].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barriers[0].Transition.pResource = dxSrc.Handle;
		barriers[0].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
		barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_SOURCE;
		barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE |
			.D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
		barriers[1].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barriers[1].Transition.pResource = dxDst.Handle;
		barriers[1].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
		barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_DEST;
		barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;
		mCmdList.ResourceBarrier(2, &barriers[0]);

		BlitSubresource(dxSrc, 0, dxDst, 0, dxDst.Desc.Width, dxDst.Desc.Height, dxgiFormat);

		barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE |
			.D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
		barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_SOURCE;
		barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
		barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_DEST;
		mCmdList.ResourceBarrier(2, &barriers[0]);
	}

	/// Each mip drawn from the one above it.
	///
	/// Every transition is taken from what the TRACKER says the subresource is actually in,
	/// and recorded back. Hardcoding a before state and never telling the tracker left the
	/// resource in copy source after a GenerateMipmaps while the tracker still believed
	/// common, which is what the upload path leaves it in; the next barrier then declared the
	/// wrong before state and the debug layer rejected it once per mip.
	///
	/// This walks LAYER ZERO only, because the blit addresses a single mip, so an array or
	/// cube texture still gets only its first slice's chain built.
	public void GenerateMipmaps(ITexture texture)
	{
		let dxTex = texture as DxTexture;
		if (dxTex == null)
			return;

		let d = dxTex.Desc;
		if (d.MipLevelCount <= 1)
			return;

		let dxgiFormat = DxConversions.ToDxgiFormat(d.Format);
		const D3D12_RESOURCE_STATES cSrvState = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE |
			.D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;

		void Transition(uint32 mip, D3D12_RESOURCE_STATES after)
		{
			let before = dxTex.GetSubresourceState(mip, 0);
			if (before == after)
				return;

			D3D12_RESOURCE_BARRIER b = .();
			b.Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			b.Transition.pResource = dxTex.Handle;
			b.Transition.Subresource = mip;
			b.Transition.StateBefore = before;
			b.Transition.StateAfter = after;
			mCmdList.ResourceBarrier(1, &b);
			dxTex.SetSubresourceState(mip, 1, 0, 1, after);
		}

		for (uint32 mip = 1; mip < d.MipLevelCount; mip++)
		{
			let dstWidth = Math.Max(1, d.Width >> mip);
			let dstHeight = Math.Max(1, d.Height >> mip);

			// No restore per mip: mip N stays shader readable and is read again as the source
			// for N plus one, so the only transitions left are the ones that change something.
			Transition(mip - 1, cSrvState);
			Transition(mip, .D3D12_RESOURCE_STATE_RENDER_TARGET);
			BlitSubresource(dxTex, mip - 1, dxTex, mip, dstWidth, dstHeight, dxgiFormat);
		}

		// Settle the WHOLE resource, not just the mips walked above: on an array or cube
		// texture the loop touches only the first slice, so settling those alone would leave
		// the tracker permanently non uniform and every later reader of the single state
		// stale.
		DxTexture.TransitionWhole(mCmdList, dxTex, .D3D12_RESOURCE_STATE_COMMON);
	}
	public void ResolveTexture(ITexture src, ITexture dst)
	{
		let dxSrc = src as DxTexture;
		let dxDst = dst as DxTexture;
		if ((dxSrc == null) || (dxDst == null))
			return;

		// Barrier from the TRACKED state and record the result. Hardcoding copy source and
		// copy destination here desynced the tracker the moment a resolve target was used any
		// other way, an MSAA colour target resting in RENDER_TARGET rather than COPY_SOURCE.
		// Go through the whole texture helper rather than reading the current state directly:
		// that is only valid while the texture is uniform, and reading it in per subresource
		// mode reintroduces the very divergence this is fixing.
		DxTexture.TransitionWhole(mCmdList, dxSrc, .D3D12_RESOURCE_STATE_RESOLVE_SOURCE);
		DxTexture.TransitionWhole(mCmdList, dxDst, .D3D12_RESOURCE_STATE_RESOLVE_DEST);

		mCmdList.ResolveSubresource(dxDst.Handle, 0, dxSrc.Handle, 0,
			DxConversions.ToDxgiFormat(dxDst.Desc.Format));

		DxTexture.TransitionWhole(mCmdList, dxSrc, .D3D12_RESOURCE_STATE_COMMON);
		DxTexture.TransitionWhole(mCmdList, dxDst, .D3D12_RESOURCE_STATE_COMMON);
	}

	private static D3D12_RAYTRACING_GEOMETRY_FLAGS ToGeometryFlags(GeometryFlags flags)
	{
		D3D12_RAYTRACING_GEOMETRY_FLAGS result = .D3D12_RAYTRACING_GEOMETRY_FLAG_NONE;
		if (flags.HasFlag(.Opaque))
			result |= .D3D12_RAYTRACING_GEOMETRY_FLAG_OPAQUE;
		if (flags.HasFlag(.NoDuplicateAnyHitInvocation))
			result |= .D3D12_RAYTRACING_GEOMETRY_FLAG_NO_DUPLICATE_ANYHIT_INVOCATION;
		return result;
	}

	public void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs)
	{
		let dxAs = dst as DxAccelStruct;
		let dxScratch = scratchBuffer as DxBuffer;
		if ((dxAs == null) || (dxScratch == null))
			return;

		// Ray tracing lives on command list four, so the list is queried per call.
		ID3D12GraphicsCommandList4* cmdList4 = null;
		if (FAILED(mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4)) ||
			(cmdList4 == null))
			return;
		defer cmdList4.Release();

		let totalGeoms = triangles.Length + aabbs.Length;
		let geomDescs = scope List<D3D12_RAYTRACING_GEOMETRY_DESC>();
		geomDescs.Resize(totalGeoms);
		int idx = 0;

		for (let t in triangles)
		{
			geomDescs[idx] = .();
			geomDescs[idx].Type = .D3D12_RAYTRACING_GEOMETRY_TYPE_TRIANGLES;
			geomDescs[idx].Flags = ToGeometryFlags(t.Flags);

			if (let vb = t.VertexBuffer as DxBuffer)
			{
				geomDescs[idx].Triangles.VertexBuffer.StartAddress = vb.GpuAddress + t.VertexOffset;
				geomDescs[idx].Triangles.VertexBuffer.StrideInBytes = t.VertexStride;
				geomDescs[idx].Triangles.VertexCount = t.VertexCount;
				geomDescs[idx].Triangles.VertexFormat =
					DxConversions.ToDxgiVertexFormat(t.VertexFormat);
			}

			if (t.IndexBuffer != null)
			{
				if (let ib = t.IndexBuffer as DxBuffer)
				{
					geomDescs[idx].Triangles.IndexBuffer = ib.GpuAddress + t.IndexOffset;
					geomDescs[idx].Triangles.IndexCount = t.IndexCount;
					geomDescs[idx].Triangles.IndexFormat = (t.IndexFormat == .UInt16)
						? .DXGI_FORMAT_R16_UINT
						: .DXGI_FORMAT_R32_UINT;
				}
			}
			else
			{
				// UNKNOWN is how non indexed geometry is spelled, not a missing value.
				geomDescs[idx].Triangles.IndexFormat = .DXGI_FORMAT_UNKNOWN;
			}

			if (t.TransformBuffer != null)
			{
				if (let tb = t.TransformBuffer as DxBuffer)
					geomDescs[idx].Triangles.Transform3x4 = tb.GpuAddress + t.TransformOffset;
			}

			idx++;
		}

		for (let a in aabbs)
		{
			geomDescs[idx] = .();
			geomDescs[idx].Type = .D3D12_RAYTRACING_GEOMETRY_TYPE_PROCEDURAL_PRIMITIVE_AABBS;
			geomDescs[idx].Flags = ToGeometryFlags(a.Flags);

			if (let ab = a.AabbBuffer as DxBuffer)
			{
				geomDescs[idx].AABBs.AABBs.StartAddress = ab.GpuAddress + a.Offset;
				geomDescs[idx].AABBs.AABBs.StrideInBytes = a.Stride;
				geomDescs[idx].AABBs.AABBCount = a.Count;
			}

			idx++;
		}

		D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC buildDesc = .();
		buildDesc.DestAccelerationStructureData = dxAs.DeviceAddress;
		buildDesc.ScratchAccelerationStructureData = dxScratch.GpuAddress + scratchOffset;
		buildDesc.Inputs.Type = .D3D12_RAYTRACING_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL;
		buildDesc.Inputs.Flags =
			.D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PREFER_FAST_TRACE;
		buildDesc.Inputs.NumDescs = (uint32)totalGeoms;
		buildDesc.Inputs.DescsLayout = .D3D12_ELEMENTS_LAYOUT_ARRAY;
		buildDesc.Inputs.pGeometryDescs = geomDescs.Ptr;

		cmdList4.BuildRaytracingAccelerationStructure(&buildDesc, 0, null);
	}

	public void BuildTopLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, IBuffer instanceBuffer, uint64 instanceOffset, uint32 instanceCount)
	{
		let dxAs = dst as DxAccelStruct;
		let dxScratch = scratchBuffer as DxBuffer;
		let dxInstances = instanceBuffer as DxBuffer;
		if ((dxAs == null) || (dxScratch == null) || (dxInstances == null))
			return;

		ID3D12GraphicsCommandList4* cmdList4 = null;
		if (FAILED(mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4)) ||
			(cmdList4 == null))
			return;
		defer cmdList4.Release();

		D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC buildDesc = .();
		buildDesc.DestAccelerationStructureData = dxAs.DeviceAddress;
		buildDesc.ScratchAccelerationStructureData = dxScratch.GpuAddress + scratchOffset;
		buildDesc.Inputs.Type = .D3D12_RAYTRACING_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL;
		buildDesc.Inputs.Flags =
			.D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PREFER_FAST_TRACE;
		buildDesc.Inputs.NumDescs = instanceCount;
		buildDesc.Inputs.DescsLayout = .D3D12_ELEMENTS_LAYOUT_ARRAY;
		// The instances are read from a BUFFER here rather than from a description array.
		buildDesc.Inputs.InstanceDescs = dxInstances.GpuAddress + instanceOffset;

		cmdList4.BuildRaytracingAccelerationStructure(&buildDesc, 0, null);
	}

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline)
	{
		mCurrentRtPipeline = pipeline as DxRayTracingPipeline;
		if (mCurrentRtPipeline == null)
			return;

		EnsureDescriptorHeaps();

		ID3D12GraphicsCommandList4* cmdList4 = null;
		if (SUCCEEDED(mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID,
			(void**)&cmdList4)) && (cmdList4 != null))
		{
			cmdList4.SetPipelineState1(mCurrentRtPipeline.Handle);
			cmdList4.Release();
		}

		// Ray tracing binds through the COMPUTE root signature, not a third set of its own.
		if (let layout = mCurrentRtPipeline.PipelineLayout)
			mCmdList.SetComputeRootSignature(layout.Handle);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default)
	{
		let dxGroup = group as DxBindGroup;
		if ((dxGroup == null) || (mCurrentRtPipeline == null))
			return;

		let layout = mCurrentRtPipeline.PipelineLayout;
		if (layout == null)
			return;

		let dxLayout = dxGroup.Layout as DxBindGroupLayout;

		// The same three routes as the two pass encoders, through the compute root set.
		if ((dxGroup.CbvSrvUavOffset >= 0) && (dxLayout != null) && (dxLayout.CbvSrvUavCount > 0))
		{
			let rootIdx = layout.GetCbvSrvUavRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mPool.SrvStaging.CopyFrom((uint32)dxGroup.CbvSrvUavOffset,
					dxLayout.CbvSrvUavCount);
				if (stagedOffset >= 0)
				{
					mCmdList.SetComputeRootDescriptorTable((uint32)rootIdx,
						mGpuSrvHeap.GetGpuHandle((uint32)stagedOffset));
				}
			}
		}

		if ((dxGroup.GpuSamplerOffset >= 0) && (dxLayout != null) && (dxLayout.SamplerCount > 0))
		{
			let rootIdx = layout.GetSamplerRootIndex(index);
			if (rootIdx >= 0)
			{
				mCmdList.SetComputeRootDescriptorTable((uint32)rootIdx,
					mGpuSamplerHeap.GetGpuHandle((uint32)dxGroup.GpuSamplerOffset));
			}
		}

		let dynAddrs = dxGroup.DynamicGpuAddresses;
		int dynOffsetIdx = 0;

		for (let entry in layout.DynamicRootEntries)
		{
			if (entry.GroupIndex != index)
				continue;
			if (entry.DynamicIndex >= (uint32)dynAddrs.Length)
				continue;

			var gpuAddr = dynAddrs[(int)entry.DynamicIndex];
			if (dynOffsetIdx < dynamicOffsets.Length)
				gpuAddr += (uint64)dynamicOffsets[dynOffsetIdx];
			dynOffsetIdx++;

			switch (entry.ParamType)
			{
			case .D3D12_ROOT_PARAMETER_TYPE_CBV:
				mCmdList.SetComputeRootConstantBufferView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_SRV:
				mCmdList.SetComputeRootShaderResourceView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_UAV:
				mCmdList.SetComputeRootUnorderedAccessView((uint32)entry.RootParamIndex, gpuAddr);
			default:
			}
		}
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mCurrentRtPipeline == null)
			return;

		let layout = mCurrentRtPipeline.PipelineLayout;
		if ((layout == null) || (layout.PushConstantRootIndex < 0))
			return;

		mCmdList.SetComputeRoot32BitConstants((uint32)layout.PushConstantRootIndex, size / 4, data,
			offset / 4);
	}

	public void TraceRays(IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1)
	{
		ID3D12GraphicsCommandList4* cmdList4 = null;
		if (FAILED(mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4)) ||
			(cmdList4 == null))
			return;
		defer cmdList4.Release();

		D3D12_DISPATCH_RAYS_DESC dispatchDesc = .();

		// The raygen record is a SINGLE record, so it carries a size and no stride.
		if (let dxBuf = raygenSBT as DxBuffer)
		{
			dispatchDesc.RayGenerationShaderRecord.StartAddress = dxBuf.GpuAddress + raygenOffset;
			dispatchDesc.RayGenerationShaderRecord.SizeInBytes = raygenStride;
		}

		if (missSBT != null)
		{
			if (let dxBuf = missSBT as DxBuffer)
			{
				dispatchDesc.MissShaderTable.StartAddress = dxBuf.GpuAddress + missOffset;
				dispatchDesc.MissShaderTable.StrideInBytes = missStride;
				dispatchDesc.MissShaderTable.SizeInBytes = missStride; // one entry assumed
			}
		}

		if (hitSBT != null)
		{
			if (let dxBuf = hitSBT as DxBuffer)
			{
				dispatchDesc.HitGroupTable.StartAddress = dxBuf.GpuAddress + hitOffset;
				dispatchDesc.HitGroupTable.StrideInBytes = hitStride;
				dispatchDesc.HitGroupTable.SizeInBytes = hitStride; // one entry assumed
			}
		}

		dispatchDesc.Width = width;
		dispatchDesc.Height = height;
		dispatchDesc.Depth = depth;

		cmdList4.DispatchRays(&dispatchDesc);
	}
}

#endif // BF_PLATFORM_WINDOWS
