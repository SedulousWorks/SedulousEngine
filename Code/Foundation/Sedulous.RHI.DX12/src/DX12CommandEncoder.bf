namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

/// DX12 implementation of ICommandEncoder and IRayTracingEncoderExt.
/// Wraps an ID3D12GraphicsCommandList for recording commands.
class DX12CommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private DX12Device mDevice;
	private ID3D12GraphicsCommandList* mCmdList;
	private DX12CommandPool mPool;
	private DX12RenderPassEncoder mRenderPassEncoder;
	private DX12ComputePassEncoder mComputePassEncoder;
	private DX12RayTracingPipeline mCurrentRtPipeline;
	private bool mDescriptorHeapsSet;

	public this(DX12Device device, ID3D12GraphicsCommandList* cmdList, DX12CommandPool pool)
	{
		mDevice = device;
		mCmdList = cmdList;
		mPool = pool;
		mRenderPassEncoder = new DX12RenderPassEncoder(this);
		mComputePassEncoder = new DX12ComputePassEncoder(this);
	}

	public ~this()
	{
		delete mRenderPassEncoder;
		delete mComputePassEncoder;
	}

	// ===== Render Pass =====

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		EnsureDescriptorHeaps();

		// Timestamp at pass begin
		if (desc.TimestampQuerySet != null)
		{
			if (let qs = desc.TimestampQuerySet as DX12QuerySet)
				mCmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, desc.BeginTimestampIndex);
		}

		// Set render targets
		D3D12_CPU_DESCRIPTOR_HANDLE[8] rtvHandles = default;
		int rtvCount = 0;
		for (int i = 0; i < desc.ColorAttachments.Count && i < 8; i++)
		{
			let attach = desc.ColorAttachments[i];
			if (let dxView = attach.View as DX12TextureView)
			{
				rtvHandles[i] = dxView.GetRtv();
				rtvCount++;
			}
		}

		D3D12_CPU_DESCRIPTOR_HANDLE* dsvHandle = null;
		D3D12_CPU_DESCRIPTOR_HANDLE dsvStorage = default;
		if (desc.DepthStencilAttachment != null)
		{
			let dsAttach = desc.DepthStencilAttachment.Value;
			if (let dxView = dsAttach.View as DX12TextureView)
			{
				dsvStorage = dxView.GetDsv();
				dsvHandle = &dsvStorage;
			}
		}

		mCmdList.OMSetRenderTargets((uint32)rtvCount, &rtvHandles[0], FALSE, dsvHandle);

		// Clear render targets
		for (int i = 0; i < desc.ColorAttachments.Count && i < 8; i++)
		{
			let attach = desc.ColorAttachments[i];
			if (attach.LoadOp == .Clear)
			{
				float[4] color = .(attach.ClearValue.R, attach.ClearValue.G, attach.ClearValue.B, attach.ClearValue.A);
				mCmdList.ClearRenderTargetView(rtvHandles[i], &color[0], 0, null);
			}
		}

		// Clear depth/stencil
		if (desc.DepthStencilAttachment != null && dsvHandle != null)
		{
			let dsAttach = desc.DepthStencilAttachment.Value;
			D3D12_CLEAR_FLAGS clearFlags = default;
			bool needsClear = false;
			if (dsAttach.DepthLoadOp == .Clear) { clearFlags |= .D3D12_CLEAR_FLAG_DEPTH; needsClear = true; }
			if (dsAttach.StencilLoadOp == .Clear) { clearFlags |= .D3D12_CLEAR_FLAG_STENCIL; needsClear = true; }
			if (needsClear)
				mCmdList.ClearDepthStencilView(*dsvHandle, clearFlags,
					dsAttach.DepthClearValue, (uint8)dsAttach.StencilClearValue, 0, null);
		}

		mRenderPassEncoder.Begin(desc);
		return mRenderPassEncoder;
	}

	// ===== Compute Pass =====

	public IComputePassEncoder BeginComputePass(StringView label)
	{
		EnsureDescriptorHeaps();
		mComputePassEncoder.Begin();
		return mComputePassEncoder;
	}

	// ===== Barriers =====

	public void Barrier(BarrierGroup barriers)
	{
		int totalBarriers = barriers.BufferBarriers.Length + barriers.TextureBarriers.Length + barriers.MemoryBarriers.Length;
		if (totalBarriers == 0) return;

		D3D12_RESOURCE_BARRIER[] dxBarriers = scope D3D12_RESOURCE_BARRIER[totalBarriers];
		int idx = 0;

		for (let bb in barriers.BufferBarriers)
		{
			if (let dxBuf = bb.Buffer as DX12Buffer)
			{
				let oldState = ToResourceStates(bb.OldState);
				let newState = ToResourceStates(bb.NewState);
				if (oldState == newState) continue;

				dxBarriers[idx] = default;
				dxBarriers[idx].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
				dxBarriers[idx].Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
				dxBarriers[idx].Transition.pResource = dxBuf.Handle;
				dxBarriers[idx].Transition.StateBefore = oldState;
				dxBarriers[idx].Transition.StateAfter = newState;
				dxBarriers[idx].Transition.Subresource = 0xFFFFFFFF; // D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES
				dxBuf.State = newState;
				idx++;
			}
		}

		for (let tb in barriers.TextureBarriers)
		{
			if (let dxTex = tb.Texture as DX12Texture)
			{
				let oldState = ToResourceStates(tb.OldState);
				let newState = ToResourceStates(tb.NewState);
				if (oldState == newState) continue;

				dxBarriers[idx] = default;
				dxBarriers[idx].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
				dxBarriers[idx].Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
				dxBarriers[idx].Transition.pResource = dxTex.Handle;
				dxBarriers[idx].Transition.StateBefore = oldState;
				dxBarriers[idx].Transition.StateAfter = newState;
				dxBarriers[idx].Transition.Subresource = 0xFFFFFFFF;
				dxTex.State = newState;
				idx++;
			}
		}

		for (let mb in barriers.MemoryBarriers)
		{
			dxBarriers[idx] = default;
			dxBarriers[idx].Type = .D3D12_RESOURCE_BARRIER_TYPE_UAV;
			dxBarriers[idx].Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
			dxBarriers[idx].UAV.pResource = null; // Global UAV barrier
			idx++;
		}

		if (idx > 0)
			mCmdList.ResourceBarrier((uint32)idx, dxBarriers.CArray());
	}

	// ===== Copy Operations =====

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset, uint64 size)
	{
		let dxSrc = src as DX12Buffer;
		let dxDst = dst as DX12Buffer;
		if (dxSrc == null || dxDst == null) return;
		mCmdList.CopyBufferRegion(dxDst.Handle, dstOffset, dxSrc.Handle, srcOffset, size);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		let dxSrc = src as DX12Buffer;
		let dxTex = dst as DX12Texture;
		if (dxSrc == null || dxTex == null) return;

		let subresource = region.TextureMipLevel + region.TextureArrayLayer * dxTex.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = default;
		srcLoc.pResource = dxSrc.Handle;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		srcLoc.PlacedFootprint.Offset = region.BufferOffset;
		srcLoc.PlacedFootprint.Footprint.Format = DX12Conversions.ToDxgiFormat(dxTex.Desc.Format);
		srcLoc.PlacedFootprint.Footprint.Width = region.TextureExtent.Width;
		srcLoc.PlacedFootprint.Footprint.Height = region.TextureExtent.Height;
		srcLoc.PlacedFootprint.Footprint.Depth = region.TextureExtent.Depth;
		srcLoc.PlacedFootprint.Footprint.RowPitch = region.BytesPerRow;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = default;
		dstLoc.pResource = dxTex.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dstLoc.SubresourceIndex = subresource;

		mCmdList.CopyTextureRegion(&dstLoc, region.TextureOrigin.X, region.TextureOrigin.Y, region.TextureOrigin.Z, &srcLoc, null);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		let dxTex = src as DX12Texture;
		let dxDst = dst as DX12Buffer;
		if (dxTex == null || dxDst == null) return;

		let subresource = region.TextureMipLevel + region.TextureArrayLayer * dxTex.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = default;
		srcLoc.pResource = dxTex.Handle;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		srcLoc.SubresourceIndex = subresource;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = default;
		dstLoc.pResource = dxDst.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		dstLoc.PlacedFootprint.Offset = region.BufferOffset;
		dstLoc.PlacedFootprint.Footprint.Format = DX12Conversions.ToDxgiFormat(dxTex.Desc.Format);
		dstLoc.PlacedFootprint.Footprint.Width = region.TextureExtent.Width;
		dstLoc.PlacedFootprint.Footprint.Height = region.TextureExtent.Height;
		dstLoc.PlacedFootprint.Footprint.Depth = region.TextureExtent.Depth;
		dstLoc.PlacedFootprint.Footprint.RowPitch = region.BytesPerRow;

		D3D12_BOX srcBox = .()
		{
			left = region.TextureOrigin.X,
			top = region.TextureOrigin.Y,
			front = region.TextureOrigin.Z,
			right = region.TextureOrigin.X + region.TextureExtent.Width,
			bottom = region.TextureOrigin.Y + region.TextureExtent.Height,
			back = region.TextureOrigin.Z + region.TextureExtent.Depth
		};

		mCmdList.CopyTextureRegion(&dstLoc, 0, 0, 0, &srcLoc, &srcBox);
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		let dxSrc = src as DX12Texture;
		let dxDst = dst as DX12Texture;
		if (dxSrc == null || dxDst == null) return;

		let srcSubresource = region.SrcMipLevel + region.SrcArrayLayer * dxSrc.Desc.MipLevelCount;
		let dstSubresource = region.DstMipLevel + region.DstArrayLayer * dxDst.Desc.MipLevelCount;

		D3D12_TEXTURE_COPY_LOCATION srcLoc = default;
		srcLoc.pResource = dxSrc.Handle;
		srcLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		srcLoc.SubresourceIndex = srcSubresource;

		D3D12_TEXTURE_COPY_LOCATION dstLoc = default;
		dstLoc.pResource = dxDst.Handle;
		dstLoc.Type = .D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dstLoc.SubresourceIndex = dstSubresource;

		D3D12_BOX srcBox = .()
		{
			left = 0, top = 0, front = 0,
			right = region.Extent.Width,
			bottom = region.Extent.Height,
			back = region.Extent.Depth
		};

		mCmdList.CopyTextureRegion(&dstLoc, 0, 0, 0, &srcLoc, &srcBox);
	}

	// ===== Blit & Mipmap Generation =====

	public void Blit(ITexture src, ITexture dst)
	{
		let dxSrc = src as DX12Texture;
		let dxDst = dst as DX12Texture;
		if (dxSrc == null || dxDst == null) return;

		let dxgiFormat = DX12Conversions.ToDxgiFormat(dxDst.Desc.Format);

		// Caller has set textures to CopySrc/CopyDst. We internally transition to SRV/RTV for blit.
		D3D12_RESOURCE_BARRIER[2] barriers = default;

		barriers[0] = default;
		barriers[0].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barriers[0].Transition.pResource = dxSrc.Handle;
		barriers[0].Transition.Subresource = 0xFFFFFFFF;
		barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_SOURCE;
		barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE | .D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;

		barriers[1] = default;
		barriers[1].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barriers[1].Transition.pResource = dxDst.Handle;
		barriers[1].Transition.Subresource = 0xFFFFFFFF;
		barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_DEST;
		barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;

		mCmdList.ResourceBarrier(2, &barriers[0]);

		BlitSubresource(dxSrc, 0, dxDst, 0, dxDst.Desc.Width, dxDst.Desc.Height, dxgiFormat);

		// Transition back to CopySrc/CopyDst
		barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE | .D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
		barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_SOURCE;
		barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
		barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_DEST;

		mCmdList.ResourceBarrier(2, &barriers[0]);
	}

	public void GenerateMipmaps(ITexture texture)
	{
		let dxTex = texture as DX12Texture;
		if (dxTex == null) return;

		let desc = dxTex.Desc;
		if (desc.MipLevelCount <= 1) return;

		let dxgiFormat = DX12Conversions.ToDxgiFormat(desc.Format);

		// Texture enters in CopySrc+CopyDst state (DX12: all subresources in COPY_SOURCE).
		// For each mip: transition src->SRV, dst->RTV, blit, restore src->COPY_SOURCE.
		for (uint32 mip = 1; mip < desc.MipLevelCount; mip++)
		{
			uint32 dstWidth = Math.Max(1, desc.Width >> mip);
			uint32 dstHeight = Math.Max(1, desc.Height >> mip);

			// Pre-blit: src mip -> SRV, dst mip -> RTV
			D3D12_RESOURCE_BARRIER[2] barriers = default;

			barriers[0] = default;
			barriers[0].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			barriers[0].Transition.pResource = dxTex.Handle;
			barriers[0].Transition.Subresource = mip - 1;
			barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_SOURCE;
			barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE | .D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;

			barriers[1] = default;
			barriers[1].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			barriers[1].Transition.pResource = dxTex.Handle;
			barriers[1].Transition.Subresource = mip;
			barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_SOURCE;
			barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;

			mCmdList.ResourceBarrier(2, &barriers[0]);

			BlitSubresource(dxTex, mip - 1, dxTex, mip, dstWidth, dstHeight, dxgiFormat);

			// Post-blit: restore src mip -> COPY_SOURCE, dst mip -> COPY_SOURCE
			barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE | .D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
			barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_SOURCE;
			barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_SOURCE;

			mCmdList.ResourceBarrier(2, &barriers[0]);
		}
	}

	/// Blits one subresource using the fullscreen triangle pipeline.
	/// Expects src subresource in PIXEL_SHADER_RESOURCE state, dst subresource in RENDER_TARGET state.
	private void BlitSubresource(DX12Texture srcTex, uint32 srcMip, DX12Texture dstTex, uint32 dstMip,
		uint32 dstWidth, uint32 dstHeight, DXGI_FORMAT dxgiFormat)
	{
		let blitRootSig = mDevice.BlitRootSignature;
		if (blitRootSig == null) return;

		let blitPso = mDevice.GetOrCreateBlitPSO(dxgiFormat);
		if (blitPso == null) return;

		// Allocate temp RTV for destination mip
		var rtvHandle = mDevice.RtvHeap.Allocate();

		D3D12_RENDER_TARGET_VIEW_DESC rtvDesc = default;
		rtvDesc.Format = dxgiFormat;
		rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2D;
		rtvDesc.Texture2D.MipSlice = dstMip;
		mDevice.Handle.CreateRenderTargetView(dstTex.Handle, &rtvDesc, rtvHandle);

		// Allocate temp SRV in CPU heap, write descriptor there, then stage-copy to GPU heap.
		// The CPU heap slot is freed immediately (safe - GPU reads the staging copy).
		int32 tempSrvOffset = mDevice.CpuSrvHeap.Allocate(1);
		if (tempSrvOffset < 0) { mDevice.RtvHeap.Free(rtvHandle); return; }

		let tempCpuHandle = mDevice.CpuSrvHeap.GetCpuHandle((uint32)tempSrvOffset);

		D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = default;
		srvDesc.Format = dxgiFormat;
		srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2D;
		srvDesc.Shader4ComponentMapping = 5768; // D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING
		srvDesc.Texture2D.MostDetailedMip = srcMip;
		srvDesc.Texture2D.MipLevels = 1;
		mDevice.Handle.CreateShaderResourceView(srcTex.Handle, &srvDesc, tempCpuHandle);

		// Copy from CPU heap into GPU staging region, then free the CPU temp slot
		let stagedOffset = mPool.SrvStaging.CopyFrom((uint32)tempSrvOffset, 1);
		mDevice.CpuSrvHeap.Free((uint32)tempSrvOffset, 1);
		if (stagedOffset < 0) { mDevice.RtvHeap.Free(rtvHandle); return; }

		let srvGpuHandle = mDevice.GpuSrvHeap.GetGpuHandle((uint32)stagedOffset);

		EnsureDescriptorHeaps();

		// Set blit pipeline
		mCmdList.SetGraphicsRootSignature(blitRootSig);
		mCmdList.SetPipelineState(blitPso);
		mCmdList.SetGraphicsRootDescriptorTable(0, srvGpuHandle);
		mCmdList.OMSetRenderTargets(1, &rtvHandle, FALSE, null);

		D3D12_VIEWPORT viewport = .()
		{
			TopLeftX = 0, TopLeftY = 0,
			Width = (float)dstWidth, Height = (float)dstHeight,
			MinDepth = 0.0f, MaxDepth = 1.0f
		};
		mCmdList.RSSetViewports(1, &viewport);

		D3D12_RECT scissor = .()
		{
			left = 0, top = 0,
			right = (int32)dstWidth, bottom = (int32)dstHeight
		};
		mCmdList.RSSetScissorRects(1, &scissor);

		mCmdList.IASetPrimitiveTopology(.D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		mCmdList.DrawInstanced(3, 1, 0, 0);

		// Free RTV temp descriptor (CPU-only heap, no GPU lifetime concern)
		mDevice.RtvHeap.Free(rtvHandle);
	}

	// ===== MSAA Resolve =====

	public void ResolveTexture(ITexture src, ITexture dst)
	{
		let dxSrc = src as DX12Texture;
		let dxDst = dst as DX12Texture;
		if (dxSrc == null || dxDst == null) return;

		let dxgiFormat = DX12Conversions.ToDxgiFormat(dxDst.Desc.Format);

		// Transition src -> RESOLVE_SOURCE, dst -> RESOLVE_DEST
		D3D12_RESOURCE_BARRIER[2] barriers = default;

		barriers[0] = default;
		barriers[0].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barriers[0].Transition.pResource = dxSrc.Handle;
		barriers[0].Transition.Subresource = 0xFFFFFFFF;
		barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_SOURCE;
		barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_RESOLVE_SOURCE;

		barriers[1] = default;
		barriers[1].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barriers[1].Transition.pResource = dxDst.Handle;
		barriers[1].Transition.Subresource = 0xFFFFFFFF;
		barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_COPY_DEST;
		barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RESOLVE_DEST;

		mCmdList.ResourceBarrier(2, &barriers[0]);

		mCmdList.ResolveSubresource(dxDst.Handle, 0, dxSrc.Handle, 0, dxgiFormat);

		// Transition back
		barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_RESOLVE_SOURCE;
		barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_SOURCE;
		barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RESOLVE_DEST;
		barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_COPY_DEST;

		mCmdList.ResourceBarrier(2, &barriers[0]);
	}

	// ===== Queries =====

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
		// DX12 doesn't require explicit query reset - queries are implicitly reset when written.
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DX12QuerySet)
			mCmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, index);
	}

	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst, uint64 dstOffset)
	{
		let qs = querySet as DX12QuerySet;
		let dxDst = dst as DX12Buffer;
		if (qs == null || dxDst == null) return;
		mCmdList.ResolveQueryData(qs.Handle, DX12QuerySet.ToDx12QueryType(qs.Type),
			first, count, dxDst.Handle, dstOffset);
	}

	// ===== Debug Markers =====

	public void BeginDebugLabel(StringView label, float r, float g, float b, float a)
	{
		// PIX events would go here; no-op without PIX runtime
	}

	public void EndDebugLabel()
	{
	}

	public void InsertDebugLabel(StringView label, float r, float g, float b, float a)
	{
	}

	// ===== IRayTracingEncoderExt =====

	public void BuildBottomLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		Span<AccelStructGeometryTriangles> triangleGeometries,
		Span<AccelStructGeometryAABBs> aabbGeometries)
	{
		let dxAs = dst as DX12AccelStruct;
		let dxScratch = scratchBuffer as DX12Buffer;
		if (dxAs == null || dxScratch == null) return;

		// Query ID3D12GraphicsCommandList4
		ID3D12GraphicsCommandList4* cmdList4 = null;
		HRESULT hr = mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4);
		if (!SUCCEEDED(hr) || cmdList4 == null) return;
		defer cmdList4.Release();

		int totalGeoms = triangleGeometries.Length + aabbGeometries.Length;
		D3D12_RAYTRACING_GEOMETRY_DESC[] geomDescs = scope D3D12_RAYTRACING_GEOMETRY_DESC[totalGeoms];
		int idx = 0;

		for (let triGeom in triangleGeometries)
		{
			geomDescs[idx] = default;
			geomDescs[idx].Type = .D3D12_RAYTRACING_GEOMETRY_TYPE_TRIANGLES;
			geomDescs[idx].Flags = ToGeometryFlags(triGeom.Flags);

			ref D3D12_RAYTRACING_GEOMETRY_TRIANGLES_DESC tri = ref geomDescs[idx].Triangles;

			if (let vb = triGeom.VertexBuffer as DX12Buffer)
			{
				tri.VertexBuffer.StartAddress = vb.Handle.GetGPUVirtualAddress() + triGeom.VertexOffset;
				tri.VertexBuffer.StrideInBytes = triGeom.VertexStride;
				tri.VertexCount = triGeom.VertexCount;
				tri.VertexFormat = DX12Conversions.ToDxgiVertexFormat(triGeom.VertexFormat);
			}

			if (triGeom.IndexBuffer != null)
			{
				if (let ib = triGeom.IndexBuffer as DX12Buffer)
				{
					tri.IndexBuffer = ib.Handle.GetGPUVirtualAddress() + triGeom.IndexOffset;
					tri.IndexCount = triGeom.IndexCount;
					tri.IndexFormat = (triGeom.IndexFormat == .UInt16)
						? .DXGI_FORMAT_R16_UINT : .DXGI_FORMAT_R32_UINT;
				}
			}
			else
			{
				tri.IndexFormat = .DXGI_FORMAT_UNKNOWN;
			}

			if (triGeom.TransformBuffer != null)
			{
				if (let tb = triGeom.TransformBuffer as DX12Buffer)
					tri.Transform3x4 = tb.Handle.GetGPUVirtualAddress() + triGeom.TransformOffset;
			}

			idx++;
		}

		for (let aabbGeom in aabbGeometries)
		{
			geomDescs[idx] = default;
			geomDescs[idx].Type = .D3D12_RAYTRACING_GEOMETRY_TYPE_PROCEDURAL_PRIMITIVE_AABBS;
			geomDescs[idx].Flags = ToGeometryFlags(aabbGeom.Flags);

			if (let ab = aabbGeom.AABBBuffer as DX12Buffer)
			{
				geomDescs[idx].AABBs.AABBs.StartAddress = ab.Handle.GetGPUVirtualAddress() + aabbGeom.Offset;
				geomDescs[idx].AABBs.AABBs.StrideInBytes = aabbGeom.Stride;
				geomDescs[idx].AABBs.AABBCount = aabbGeom.Count;
			}

			idx++;
		}

		D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC buildDesc = default;
		buildDesc.DestAccelerationStructureData = dxAs.GpuAddress;
		buildDesc.ScratchAccelerationStructureData = dxScratch.Handle.GetGPUVirtualAddress() + scratchOffset;
		buildDesc.Inputs.Type = .D3D12_RAYTRACING_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL;
		buildDesc.Inputs.Flags = .D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PREFER_FAST_TRACE;
		buildDesc.Inputs.NumDescs = (uint32)totalGeoms;
		buildDesc.Inputs.DescsLayout = .D3D12_ELEMENTS_LAYOUT_ARRAY;
		buildDesc.Inputs.pGeometryDescs = geomDescs.CArray();

		cmdList4.BuildRaytracingAccelerationStructure(&buildDesc, 0, null);
	}

	public void BuildTopLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		IBuffer instanceBuffer, uint64 instanceOffset, uint32 instanceCount)
	{
		let dxAs = dst as DX12AccelStruct;
		let dxScratch = scratchBuffer as DX12Buffer;
		let dxInstances = instanceBuffer as DX12Buffer;
		if (dxAs == null || dxScratch == null || dxInstances == null) return;

		ID3D12GraphicsCommandList4* cmdList4 = null;
		HRESULT hr = mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4);
		if (!SUCCEEDED(hr) || cmdList4 == null) return;
		defer cmdList4.Release();

		D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC buildDesc = default;
		buildDesc.DestAccelerationStructureData = dxAs.GpuAddress;
		buildDesc.ScratchAccelerationStructureData = dxScratch.Handle.GetGPUVirtualAddress() + scratchOffset;
		buildDesc.Inputs.Type = .D3D12_RAYTRACING_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL;
		buildDesc.Inputs.Flags = .D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PREFER_FAST_TRACE;
		buildDesc.Inputs.NumDescs = instanceCount;
		buildDesc.Inputs.DescsLayout = .D3D12_ELEMENTS_LAYOUT_ARRAY;
		buildDesc.Inputs.InstanceDescs = dxInstances.Handle.GetGPUVirtualAddress() + instanceOffset;

		cmdList4.BuildRaytracingAccelerationStructure(&buildDesc, 0, null);
	}

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline)
	{
		mCurrentRtPipeline = pipeline as DX12RayTracingPipeline;
		if (mCurrentRtPipeline == null) return;

		EnsureDescriptorHeaps();

		ID3D12GraphicsCommandList4* cmdList4 = null;
		HRESULT hr = mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4);
		if (SUCCEEDED(hr) && cmdList4 != null)
		{
			cmdList4.SetPipelineState1(mCurrentRtPipeline.Handle);
			cmdList4.Release();
		}

		// Set the root signature for compute-style binding (RT uses compute root sig)
		let layout = mCurrentRtPipeline.Layout as DX12PipelineLayout;
		if (layout != null)
			mCmdList.SetComputeRootSignature(layout.Handle);
	}

	void IRayTracingEncoderExt.SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		let dxGroup = bindGroup as DX12BindGroup;
		if (dxGroup == null || mCurrentRtPipeline == null) return;

		let layout = mCurrentRtPipeline.Layout as DX12PipelineLayout;
		if (layout == null) return;

		let dxLayout = dxGroup.Layout as DX12BindGroupLayout;

		// RT uses compute root signature binding - copy-on-bind staging
		if (dxGroup.CbvSrvUavOffset >= 0 && dxLayout != null && dxLayout.CbvSrvUavCount > 0)
		{
			let rootIdx = layout.GetCbvSrvUavRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mPool.SrvStaging.CopyFrom(
					(uint32)dxGroup.CbvSrvUavOffset, dxLayout.CbvSrvUavCount);
				if (stagedOffset >= 0)
				{
					let gpuHandle = mDevice.GpuSrvHeap.GetGpuHandle((uint32)stagedOffset);
					mCmdList.SetComputeRootDescriptorTable((uint32)rootIdx, gpuHandle);
				}
			}
		}

		if (dxGroup.SamplerOffset >= 0 && dxLayout != null && dxLayout.SamplerCount > 0)
		{
			let rootIdx = layout.GetSamplerRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mPool.SamplerStaging.CopyFrom(
					(uint32)dxGroup.SamplerOffset, dxLayout.SamplerCount);
				if (stagedOffset >= 0)
				{
					let gpuHandle = mDevice.GpuSamplerHeap.GetGpuHandle((uint32)stagedOffset);
					mCmdList.SetComputeRootDescriptorTable((uint32)rootIdx, gpuHandle);
				}
			}
		}

		int dynOffsetIdx = 0;
		for (let entry in layout.DynamicRootEntries)
		{
			if (entry.GroupIndex != index) continue;
			if ((int)entry.DynamicIndex >= dxGroup.DynamicGpuAddresses.Count) continue;

			uint64 gpuAddr = dxGroup.DynamicGpuAddresses[(int)entry.DynamicIndex];
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

	void IRayTracingEncoderExt.SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mCurrentRtPipeline == null) return;
		let layout = mCurrentRtPipeline.Layout as DX12PipelineLayout;
		if (layout == null || layout.PushConstantRootIndex < 0) return;

		mCmdList.SetComputeRoot32BitConstants(
			(uint32)layout.PushConstantRootIndex,
			size / 4, data, offset / 4);
	}

	public void TraceRays(
		IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth)
	{
		ID3D12GraphicsCommandList4* cmdList4 = null;
		HRESULT hr = mCmdList.QueryInterface(ID3D12GraphicsCommandList4.IID, (void**)&cmdList4);
		if (!SUCCEEDED(hr) || cmdList4 == null) return;
		defer cmdList4.Release();

		D3D12_DISPATCH_RAYS_DESC dispatchDesc = default;

		// Raygen - single record
		if (let dxBuf = raygenSBT as DX12Buffer)
		{
			dispatchDesc.RayGenerationShaderRecord.StartAddress =
				dxBuf.Handle.GetGPUVirtualAddress() + raygenOffset;
			dispatchDesc.RayGenerationShaderRecord.SizeInBytes = raygenStride;
		}

		// Miss
		if (missSBT != null)
		{
			if (let dxBuf = missSBT as DX12Buffer)
			{
				dispatchDesc.MissShaderTable.StartAddress =
					dxBuf.Handle.GetGPUVirtualAddress() + missOffset;
				dispatchDesc.MissShaderTable.StrideInBytes = missStride;
				dispatchDesc.MissShaderTable.SizeInBytes = missStride; // Assume single entry
			}
		}

		// Hit group
		if (hitSBT != null)
		{
			if (let dxBuf = hitSBT as DX12Buffer)
			{
				dispatchDesc.HitGroupTable.StartAddress =
					dxBuf.Handle.GetGPUVirtualAddress() + hitOffset;
				dispatchDesc.HitGroupTable.StrideInBytes = hitStride;
				dispatchDesc.HitGroupTable.SizeInBytes = hitStride; // Assume single entry
			}
		}

		dispatchDesc.Width = width;
		dispatchDesc.Height = height;
		dispatchDesc.Depth = depth;

		cmdList4.DispatchRays(&dispatchDesc);
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

	// ===== Finish =====

	public ICommandBuffer Finish()
	{
		mCmdList.Close();
		let cb = new DX12CommandBuffer(mCmdList);
		mPool.TrackCommandBuffer(cb);
		return cb;
	}

	// ===== Internal =====

	public ID3D12GraphicsCommandList* CmdList => mCmdList;
	public DX12Device Device => mDevice;
	public DX12DescriptorStaging SrvStaging => mPool.SrvStaging;
	public DX12DescriptorStaging SamplerStaging => mPool.SamplerStaging;

	private void EnsureDescriptorHeaps()
	{
		if (mDescriptorHeapsSet) return;
		mDescriptorHeapsSet = true;

		ID3D12DescriptorHeap*[2] heaps = .(
			mDevice.GpuSrvHeap.Heap,
			mDevice.GpuSamplerHeap.Heap
		);
		mCmdList.SetDescriptorHeaps(2, &heaps[0]);
	}

	/// Converts RHI ResourceState to D3D12_RESOURCE_STATES.
	public static D3D12_RESOURCE_STATES ToResourceStates(ResourceState state)
	{
		if (state == .Undefined)
			return .D3D12_RESOURCE_STATE_COMMON;

		D3D12_RESOURCE_STATES result = .D3D12_RESOURCE_STATE_COMMON;

		if (state.HasFlag(.VertexBuffer))      result |= .D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;
		if (state.HasFlag(.IndexBuffer))        result |= .D3D12_RESOURCE_STATE_INDEX_BUFFER;
		if (state.HasFlag(.UniformBuffer))      result |= .D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;
		if (state.HasFlag(.ShaderRead))         result |= .D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE | .D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
		if (state.HasFlag(.ShaderWrite))        result |= .D3D12_RESOURCE_STATE_UNORDERED_ACCESS;
		if (state.HasFlag(.RenderTarget))       result |= .D3D12_RESOURCE_STATE_RENDER_TARGET;
		if (state.HasFlag(.DepthStencilWrite))  result |= .D3D12_RESOURCE_STATE_DEPTH_WRITE;
		if (state.HasFlag(.DepthStencilRead))   result |= .D3D12_RESOURCE_STATE_DEPTH_READ;
		if (state.HasFlag(.IndirectArgument))   result |= .D3D12_RESOURCE_STATE_INDIRECT_ARGUMENT;
		if (state.HasFlag(.CopySrc))            result |= .D3D12_RESOURCE_STATE_COPY_SOURCE;
		if (state.HasFlag(.CopyDst))            result |= .D3D12_RESOURCE_STATE_COPY_DEST;
		if (state.HasFlag(.Present))            result |= .D3D12_RESOURCE_STATE_PRESENT;
		if (state.HasFlag(.General))            result |= .D3D12_RESOURCE_STATE_COMMON;
		if (state.HasFlag(.AccelStructRead))    result |= .D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE;
		if (state.HasFlag(.AccelStructWrite))   result |= .D3D12_RESOURCE_STATE_UNORDERED_ACCESS;

		return result;
	}
}
