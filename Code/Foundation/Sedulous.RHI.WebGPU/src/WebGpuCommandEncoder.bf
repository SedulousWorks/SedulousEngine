using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// Records commands.
///
/// WebGPU encoders are ONE SHOT; this wrapper is reusable. After Finish, the next call
/// that needs an encoder lazily opens a fresh one, which is exactly the frame loop's
/// reset and re-encode shape.
///
/// Barriers are no-ops. WebGPU tracks hazards itself, so the RHI's explicit transitions
/// carry no information that could be acted on here.
///
/// Blit and GenerateMipmaps ride the internal fullscreen blit pass, WebGPU having no
/// image blit, though a same extent same format blit stays a plain copy. ResolveTexture
/// is a resolve only render pass: load the MSAA attachment, discard it, resolve out.
class WebGpuCommandEncoder : ICommandEncoder
{
	private WGPUDevice mDevice;
	/// BORROWED, owned by the device.
	private WebGpuBlitHelper mBlitHelper;

	private WGPUCommandEncoder mEncoder = null;
	private WebGpuRenderPassEncoder mRenderPass = new .() ~ delete _;
	private WebGpuComputePassEncoder mComputePass = new .() ~ delete _;
	private WebGpuCommandBuffer mCommandBuffer = new .() ~ delete _;
	private List<WebGpuRenderBundleEncoder> mBundleEncoders = new .() ~ DeleteContainerAndItems!(_);

	private WGPUBuffer mQueryScratch = null;
	private uint64 mQueryScratchSize = 0;

	public void Initialize(WGPUDevice device, WebGpuBlitHelper blitHelper)
	{
		mDevice = device;
		mBlitHelper = blitHelper;
	}

	public ~this()
	{
		if (mQueryScratch != null)
			wgpuBufferRelease(mQueryScratch);

		if (mEncoder != null)
			wgpuCommandEncoderRelease(mEncoder);
	}

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		EnsureOpen();

		WGPURenderPassColorAttachment[RhiLimits.MaxColorAttachments] colors = .();
		for (int i = 0; i < desc.ColorAttachments.Count; i++)
		{
			let attachment = desc.ColorAttachments[i];
			WGPURenderPassColorAttachment color = .();

			if (let view = attachment.View as WebGpuTextureView)
				color.view = view.Handle;
			if (let resolve = attachment.ResolveTarget as WebGpuTextureView)
				color.resolveTarget = resolve.Handle;

			color.loadOp = WebGpuConversions.ToWgpuLoadOp(attachment.LoadOp);
			color.storeOp = WebGpuConversions.ToWgpuStoreOp(attachment.StoreOp);
			color.clearValue = .() { r = attachment.ClearValue.R, g = attachment.ClearValue.G,
				b = attachment.ClearValue.B, a = attachment.ClearValue.A };
			colors[i] = color;
		}

		WGPURenderPassDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.colorAttachmentCount = (uint)desc.ColorAttachments.Count;
		wgpu.colorAttachments = &colors[0];

		WGPURenderPassDepthStencilAttachment depth = .();
		if (desc.DepthStencilAttachment.HasValue)
		{
			let attachment = desc.DepthStencilAttachment.Value;
			if (let view = attachment.View as WebGpuTextureView)
				depth.view = view.Handle;

			// The clear value must be FINITE even on a read only or load op plane. The
			// wgpu initialiser's sentinel is a NaN, which native wgpu ignores when it is
			// not clearing, but a browser rejects a non finite clear value
			// unconditionally. So the attachment's own value always goes through, which
			// is a finite one by default, and a read only depth pass validates in a
			// browser as well as natively.
			depth.depthClearValue = attachment.DepthClearValue;

			if (attachment.DepthReadOnly)
			{
				// A read only plane must leave its load and store ops undefined.
				depth.depthReadOnly = 1;
			}
			else
			{
				depth.depthLoadOp = WebGpuConversions.ToWgpuLoadOp(attachment.DepthLoadOp);
				depth.depthStoreOp = WebGpuConversions.ToWgpuStoreOp(attachment.DepthStoreOp);
			}

			// A view made with a default descriptor INHERITS the texture's format, its
			// own staying Undefined, so the format is resolved through the owner. Read
			// only off the view, a stencil capable attachment is misjudged as depth only
			// and the browser rejects the pass for the stencil ops it then omits.
			var dsFormat = TextureFormat.Undefined;
			if (let view = attachment.View as WebGpuTextureView)
			{
				dsFormat = view.Desc.Format;
				if ((dsFormat == .Undefined) && (view.Texture != null))
					dsFormat = view.Texture.Desc.Format;
			}

			if (HasStencil(dsFormat))
			{
				if (attachment.StencilReadOnly)
				{
					depth.stencilReadOnly = 1;
				}
				else
				{
					depth.stencilLoadOp =
						WebGpuConversions.ToWgpuLoadOp(attachment.StencilLoadOp);
					depth.stencilStoreOp =
						WebGpuConversions.ToWgpuStoreOp(attachment.StencilStoreOp);
					depth.stencilClearValue = attachment.StencilClearValue;
				}
			}

			wgpu.depthStencilAttachment = &depth;
		}

		if (let occlusion = desc.OcclusionQuerySet as WebGpuQuerySet)
			wgpu.occlusionQuerySet = occlusion.Handle;

		WGPUPassTimestampWrites timestamps = .();
		if (let timestampSet = desc.TimestampQuerySet as WebGpuQuerySet)
		{
			timestamps.querySet = timestampSet.Handle;
			timestamps.beginningOfPassWriteIndex = desc.BeginTimestampIndex;
			timestamps.endOfPassWriteIndex = desc.EndTimestampIndex;
			wgpu.timestampWrites = &timestamps;
		}

		let pass = wgpuCommandEncoderBeginRenderPass(mEncoder, &wgpu);
		mRenderPass.Begin(mDevice, pass);
		return mRenderPass;
	}

	public IComputePassEncoder BeginComputePass(StringView label = default)
	{
		EnsureOpen();

		WGPUComputePassDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(label);

		let pass = wgpuCommandEncoderBeginComputePass(mEncoder, &wgpu);
		mComputePass.Begin(mDevice, pass);
		return mComputePass;
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		let encoder = new WebGpuRenderBundleEncoder();
		if (encoder.Initialize(mDevice, desc) case .Err)
		{
			delete encoder;
			return null;
		}

		mBundleEncoders.Add(encoder);
		return encoder;
	}

	/// Nothing to do: WebGPU tracks hazards itself, so the RHI's explicit transitions
	/// carry no information that could be acted on here.
	public void Barrier(BarrierGroup group)
	{
	}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size)
	{
		let source = src as WebGpuBuffer;
		let destination = dst as WebGpuBuffer;
		if ((source == null) || (destination == null))
			return;

		EnsureOpen();
		wgpuCommandEncoderCopyBufferToBuffer(mEncoder, source.Handle, srcOffset,
			destination.Handle, dstOffset, size);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		EnsureOpen();
		var source = MakeBufferInfo(src, region);
		var destination = MakeTextureInfo(dst, region);
		WGPUExtent3D extent = .() { width = region.TextureExtent.Width,
			height = region.TextureExtent.Height, depthOrArrayLayers = region.TextureExtent.Depth };
		wgpuCommandEncoderCopyBufferToTexture(mEncoder, &source, &destination, &extent);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		EnsureOpen();
		var source = MakeTextureInfo(src, region);
		var destination = MakeBufferInfo(dst, region);
		WGPUExtent3D extent = .() { width = region.TextureExtent.Width,
			height = region.TextureExtent.Height, depthOrArrayLayers = region.TextureExtent.Depth };
		wgpuCommandEncoderCopyTextureToBuffer(mEncoder, &source, &destination, &extent);
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		let sourceTexture = src as WebGpuTexture;
		let destinationTexture = dst as WebGpuTexture;
		if ((sourceTexture == null) || (destinationTexture == null))
			return;

		EnsureOpen();

		WGPUTexelCopyTextureInfo source = .();
		source.texture = sourceTexture.Handle;
		source.mipLevel = region.SrcMipLevel;
		source.origin.z = region.SrcArrayLayer;

		WGPUTexelCopyTextureInfo destination = .();
		destination.texture = destinationTexture.Handle;
		destination.mipLevel = region.DstMipLevel;
		destination.origin.z = region.DstArrayLayer;

		WGPUExtent3D extent = .() { width = region.Extent.Width, height = region.Extent.Height,
			depthOrArrayLayers = region.Extent.Depth };
		wgpuCommandEncoderCopyTextureToTexture(mEncoder, &source, &destination, &extent);
	}

	public void Blit(ITexture src, ITexture dst)
	{
		let source = src as WebGpuTexture;
		let destination = dst as WebGpuTexture;
		if ((source == null) || (destination == null))
			return;

		// Same extent and same format is a plain COPY; anything else goes through the
		// fullscreen pass, which is what scales and converts.
		if ((source.Desc.Width == destination.Desc.Width)
			&& (source.Desc.Height == destination.Desc.Height)
			&& (source.Desc.Format == destination.Desc.Format))
		{
			TextureCopyRegion region = .();
			region.Extent = .() { Width = source.Desc.Width, Height = source.Desc.Height,
				Depth = 1 };
			CopyTextureToTexture(src, dst, region);
			return;
		}

		EnsureOpen();
		let sourceView = MipView(source, 0, 0);
		let destinationView = MipView(destination, 0, 0);
		mBlitHelper.Blit(mEncoder, sourceView, destinationView,
			WebGpuConversions.ToWgpuTextureFormat(destination.Desc.Format));
		wgpuTextureViewRelease(sourceView);
		wgpuTextureViewRelease(destinationView);
	}

	public void GenerateMipmaps(ITexture texture)
	{
		let wgpuTexture = texture as WebGpuTexture;
		if (wgpuTexture == null)
			return;

		// The blit CHAIN: each mip renders from the one above it, per array layer, a
		// cubemap being six layers. Texture creation widened the usage for exactly the
		// formats this can target, so anything else is not generatable here.
		if ((wgpuTexture.Desc.MipLevelCount < 2) || (wgpuTexture.Desc.Dimension != .Texture2D)
			|| !WebGpuConversions.IsBlitCapableFormat(wgpuTexture.Desc.Format))
			return;

		EnsureOpen();
		let format = WebGpuConversions.ToWgpuTextureFormat(wgpuTexture.Desc.Format);

		for (uint32 layer = 0; layer < wgpuTexture.Desc.ArrayLayerCount; layer++)
		{
			for (uint32 mip = 1; mip < wgpuTexture.Desc.MipLevelCount; mip++)
			{
				let sourceView = MipView(wgpuTexture, mip - 1, layer);
				let destinationView = MipView(wgpuTexture, mip, layer);
				mBlitHelper.Blit(mEncoder, sourceView, destinationView, format);
				wgpuTextureViewRelease(sourceView);
				wgpuTextureViewRelease(destinationView);
			}
		}
	}

	public void ResolveTexture(ITexture src, ITexture dst)
	{
		let source = src as WebGpuTexture;
		let destination = dst as WebGpuTexture;
		if ((source == null) || (destination == null))
			return;

		// WebGPU resolves through a pass's resolve target, so a standalone resolve is a
		// pass that loads the MSAA attachment, discards it, and resolves out.
		EnsureOpen();
		let sourceView = MipView(source, 0, 0);
		let destinationView = MipView(destination, 0, 0);

		WGPURenderPassColorAttachment color = .();
		color.view = sourceView;
		color.resolveTarget = destinationView;
		color.loadOp = .WGPULoadOp_Load;
		color.storeOp = .WGPUStoreOp_Discard; // the resolve IS the output

		WGPURenderPassDescriptor passDesc = .();
		passDesc.colorAttachmentCount = 1;
		passDesc.colorAttachments = &color;

		let pass = wgpuCommandEncoderBeginRenderPass(mEncoder, &passDesc);
		wgpuRenderPassEncoderEnd(pass);
		wgpuRenderPassEncoderRelease(pass);
		wgpuTextureViewRelease(sourceView);
		wgpuTextureViewRelease(destinationView);
	}

	/// Nothing to do: there is no WebGPU shape for it, queries being implicitly reset by
	/// the resolve semantics.
	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		let set = querySet as WebGpuQuerySet;
		if (set == null)
			return;

		EnsureOpen();
		// An encoder level timestamp is a wgpu-native EXTENSION. A browser has no
		// timestamp query feature and aborts on it, so the profiler's timings are simply
		// unavailable there rather than fatal.
		WebGpuApi.NativeOnly.EncoderWriteTimestamp(mEncoder, set.Handle, index);
	}

	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset)
	{
		let set = querySet as WebGpuQuerySet;
		let destination = dst as WebGpuBuffer;
		if ((set == null) || (destination == null))
			return;

		EnsureOpen();

		// WebGPU requires a QueryResolve usage on the destination, which a mappable
		// readback buffer can never carry, MapRead combining only with CopyDst. So the
		// resolve lands in an internal scratch buffer and is copied over, which keeps the
		// RHI's Vulkan shaped contract of resolving into any CopyDst buffer.
		let size = (uint64)count * sizeof(uint64);
		EnsureQueryScratch(size);
		wgpuCommandEncoderResolveQuerySet(mEncoder, set.Handle, first, count, mQueryScratch, 0);
		wgpuCommandEncoderCopyBufferToBuffer(mEncoder, mQueryScratch, 0, destination.Handle,
			dstOffset, size);
	}

	public void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0,
		float a = 1)
	{
		EnsureOpen();
		wgpuCommandEncoderPushDebugGroup(mEncoder, WebGpuConversions.ToWgpuStringView(label));
	}

	public void EndDebugLabel()
	{
		EnsureOpen();
		wgpuCommandEncoderPopDebugGroup(mEncoder);
	}

	public void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0,
		float a = 1)
	{
		EnsureOpen();
		wgpuCommandEncoderInsertDebugMarker(mEncoder,
			WebGpuConversions.ToWgpuStringView(label));
	}

	public ICommandBuffer Finish()
	{
		EnsureOpen();

		WGPUCommandBufferDescriptor wgpu = .();
		let commandBuffer = wgpuCommandEncoderFinish(mEncoder, &wgpu);
		wgpuCommandEncoderRelease(mEncoder);
		mEncoder = null; // the next use opens a fresh one

		mCommandBuffer.Adopt(commandBuffer);
		return mCommandBuffer;
	}

	/// Opens an encoder if there is not one, which is what makes this wrapper reusable
	/// across a one shot API.
	private void EnsureOpen()
	{
		if (mEncoder != null)
			return;

		WGPUCommandEncoderDescriptor wgpu = .();
		mEncoder = wgpuDeviceCreateCommandEncoder(mDevice, &wgpu);
	}

	private void EnsureQueryScratch(uint64 size)
	{
		if ((mQueryScratch != null) && (mQueryScratchSize >= size))
			return;

		if (mQueryScratch != null)
			wgpuBufferRelease(mQueryScratch);

		WGPUBufferDescriptor wgpu = .();
		wgpu.usage = WGPUBufferUsage_QueryResolve | WGPUBufferUsage_CopySrc;
		wgpu.size = size;
		mQueryScratch = wgpuDeviceCreateBuffer(mDevice, &wgpu);
		mQueryScratchSize = size;
	}

	private static WGPUTexelCopyBufferInfo MakeBufferInfo(IBuffer buffer,
		BufferTextureCopyRegion region)
	{
		WGPUTexelCopyBufferInfo info = .();
		if (let wgpuBuffer = buffer as WebGpuBuffer)
			info.buffer = wgpuBuffer.Handle;

		info.layout.offset = region.BufferOffset;
		info.layout.bytesPerRow = region.BytesPerRow;
		info.layout.rowsPerImage = region.RowsPerImage;
		return info;
	}

	private static WGPUTexelCopyTextureInfo MakeTextureInfo(ITexture texture,
		BufferTextureCopyRegion region)
	{
		WGPUTexelCopyTextureInfo info = .();
		if (let wgpuTexture = texture as WebGpuTexture)
			info.texture = wgpuTexture.Handle;

		info.mipLevel = region.TextureMipLevel;
		info.origin = .() { x = region.TextureOrigin.X, y = region.TextureOrigin.Y,
			z = region.TextureOrigin.Z };
		// A zero z means the layer is carried in the array field instead.
		info.origin.z = (region.TextureOrigin.Z != 0) ? region.TextureOrigin.Z
			: region.TextureArrayLayer;
		return info;
	}

	/// A single mip, single layer 2D view for the blit pass.
	private static WGPUTextureView MipView(WebGpuTexture texture, uint32 mipLevel,
		uint32 arrayLayer)
	{
		WGPUTextureViewDescriptor wgpu = .();
		wgpu.format = WebGpuConversions.ToWgpuTextureFormat(texture.Desc.Format);
		wgpu.dimension = .WGPUTextureViewDimension_2D;
		wgpu.baseMipLevel = mipLevel;
		wgpu.mipLevelCount = 1;
		wgpu.baseArrayLayer = arrayLayer;
		wgpu.arrayLayerCount = 1;
		wgpu.aspect = .WGPUTextureAspect_All;
		return wgpuTextureCreateView(texture.Handle, &wgpu);
	}

	private static bool HasStencil(TextureFormat format)
	{
		return (format == .Depth24PlusStencil8) || (format == .Depth32FloatStencil8)
			|| (format == .Stencil8);
	}
}
