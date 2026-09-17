using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;
using cimgui_Beef;

namespace Sedulous.Extensions.Imgui;

/// A Dear ImGui renderer on the engine's own RHI, rather than one of the stock backends.
///
/// It owns the pipeline, the font atlas and the per frame geometry, and records one draw list
/// into a render pass that LOADS what is already there: the interface is drawn over the scene,
/// never instead of it.
class ImguiRenderer
{
	/// The most frames the engine ever has in flight, which bounds the slot table.
	private const int cMaxFramesInFlight = 4;

	private IDevice mDevice = null;
	private ShaderSystem mShaders = null;
	private uint32 mFramesInFlight = 2;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private TextureFormat mPipelineFormat = .Undefined;

	private ITexture mFontTexture = null;
	private ITextureView mFontView = null;
	private IBuffer mFontStaging = null;
	private ISampler mSampler = null;
	private uint32 mFontWidth = 0;
	private uint32 mFontHeight = 0;
	private bool mFontDirty = true;
#if BF_PLATFORM_WASM
	/// The web startup re-record window; see UploadTexture.
	private const uint32 cFontUploadFrames = 20;
	private uint32 mFontUploadFrames = 0;
#endif

	private ImguiFrameSlot[cMaxFramesInFlight] mFrames = .(new .(), new .(), new .(), new .())
		~ { for (let slot in _) delete slot; }

	/// Bind groups replaced mid frame, held until every frame that could still name them has
	/// been through. Raptor never needs this: it reads the atlas at startup, so its bind groups
	/// are made once and only ever destroyed at shutdown. The library asks for its texture on a
	/// frame here instead, which means rebinding while the previous frame's command buffer is
	/// still recorded against the old set.
	private List<(IBindGroup Group, uint32 FramesLeft)> mRetired = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = Math.Clamp(framesInFlight, 1, (uint32)cMaxFramesInFlight);
	}

	public ~this()
	{
		Shutdown();
	}

	/// The projection, the font and the sampler are ONE set: everything the interface draws
	/// uses the same atlas, so there is nothing to rebind between draws but the scissor.
	public Result<void> Initialize()
	{
		let entries = scope BindGroupLayoutEntry[](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		BindGroupLayoutDesc layoutDesc = .();
		layoutDesc.Entries = entries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(out mLayout)))
			return .Err;

		let layouts = scope IBindGroupLayout[](mLayout);
		PipelineLayoutDesc pipelineLayoutDesc = .();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(out mPipelineLayout)))
			return .Err;

		SamplerDesc samplerDesc = .();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "imgui.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(out mSampler)))
			return .Err;

		// The projection is per SLOT rather than shared: a frame still in flight would
		// otherwise have its matrix overwritten by the one being recorded.
		for (uint32 i < mFramesInFlight)
		{
			BufferDesc projectionDesc = .();
			projectionDesc.Size = sizeof(Float4x4);
			projectionDesc.Usage = .Uniform;
			projectionDesc.Memory = .CpuToGpu;
			projectionDesc.Label = "imgui.proj";
			if (!(mDevice.CreateBuffer(projectionDesc) case .Ok(let projection)))
				return .Err;
			mFrames[i].Projection = projection;
		}

		// The bindings wait for the ATLAS, which the library hands over as a request on a later
		// frame rather than at startup.
		return .Ok;
	}

	/// Records the built draw data onto the target.
	///
	/// The font upload and the buffer fills happen on the frame's own encoder BEFORE the pass
	/// opens, because a copy cannot be recorded inside a render pass.
	public void Render(ICommandEncoder encoder, ITextureView target, TextureFormat targetFormat,
		uint32 width, uint32 height, ImDrawData* drawData, uint32 frameIndex)
	{
		if ((target == null) || (drawData == null))
			return;

		TickRetired();
		ServiceTextures(encoder, drawData);
		let pipeline = EnsurePipeline(targetFormat);
		if (pipeline == null)
			return;
		if ((drawData.TotalVtxCount <= 0) || (drawData.CmdListsCount <= 0))
			return;

		let slot = mFrames[frameIndex % mFramesInFlight];
		if (slot.Bindings == null)
			return; // no atlas yet, so there is nothing the draws could sample
		if (UploadGeometry(slot, drawData) case .Err)
			return;

		// Off centre orthographic with Y running DOWN, which is the space the interface is
		// laid out in, written row major for the engine's row vectors.
		let displayWidth = (drawData.DisplaySize.x > 0.0f) ? drawData.DisplaySize.x : (float)width;
		let displayHeight = (drawData.DisplaySize.y > 0.0f) ? drawData.DisplaySize.y : (float)height;

		Float4x4 projection = .();
		projection.M[0][0] = 2.0f / displayWidth;
		projection.M[1][1] = -2.0f / displayHeight;
		projection.M[2][2] = 1.0f;
		projection.M[3][3] = 1.0f;
		projection.M[3][0] = -1.0f;
		projection.M[3][1] = 1.0f;

		let mappedProjection = slot.Projection.Map();
		if (mappedProjection != null)
		{
			Internal.MemCpy(mappedProjection, &projection, sizeof(Float4x4));
			slot.Projection.Unmap();
		}

		ColorAttachment attachment = .();
		attachment.View = target;
		attachment.LoadOp = .Load; // OVER the scene, never instead of it
		attachment.StoreOp = .Store;

		RenderPassDesc passDesc = .();
		passDesc.ColorAttachments.Add(attachment);
		passDesc.Label = "imgui";

		let pass = encoder.BeginRenderPass(passDesc);
		if (pass == null)
			return;

		pass.SetViewport(0.0f, 0.0f, (float)width, (float)height);
		pass.SetPipeline(pipeline);
		pass.SetVertexBuffer(0, slot.Vertices, 0);
		pass.SetIndexBuffer(slot.Indices, .UInt16, 0);

		let clipOffset = drawData.DisplayPos;
		uint32 globalVertex = 0;
		uint32 globalIndex = 0;
		for (int32 n < drawData.CmdListsCount)
		{
			let commandList = drawData.CmdLists.Data[n];
			for (int32 c < commandList.CmdBuffer.Size)
			{
				let command = commandList.CmdBuffer.Data[c];
				if ((command.ElemCount == 0) || (command.UserCallback != null))
					continue;

				// CLAMPED to the real target: the display size is one frame stale across a
				// resize, and a scissor outside the attachment drops the whole command buffer
				// on a validating backend.
				var x0 = (int32)(command.ClipRect.x - clipOffset.x);
				var y0 = (int32)(command.ClipRect.y - clipOffset.y);
				var x1 = (int32)(command.ClipRect.z - clipOffset.x);
				var y1 = (int32)(command.ClipRect.w - clipOffset.y);
				x0 = Math.Max(x0, 0);
				y0 = Math.Max(y0, 0);
				x1 = Math.Min(x1, (int32)width);
				y1 = Math.Min(y1, (int32)height);
				if ((x1 <= x0) || (y1 <= y0))
					continue;

				pass.SetScissor(x0, y0, (uint32)(x1 - x0), (uint32)(y1 - y0));
				pass.SetBindGroup(0, slot.Bindings, .());
				pass.DrawIndexed(command.ElemCount, 1, command.IdxOffset + globalIndex,
					(int32)(command.VtxOffset + globalVertex), 0);
			}
			globalVertex += (uint32)commandList.VtxBuffer.Size;
			globalIndex += (uint32)commandList.IdxBuffer.Size;
		}
		pass.End();
	}

	/// Services the interface's TEXTURE REQUESTS, which is how this version of the library
	/// hands its font atlas over.
	///
	/// The atlas is no longer a thing the renderer reaches in and reads at startup: the library
	/// asks for a texture when it has one ready, and asks again whenever it repacks. Answering
	/// the request is what makes a font appear at all.
	private void ServiceTextures(ICommandEncoder encoder, ImDrawData* drawData)
	{
		if (drawData.Textures == null)
			return;

		let textures = drawData.Textures;
		for (int32 i < textures.Size)
		{
			let texture = textures.Data[i];
			if (texture == null)
				continue;
			if ((texture.Status != .ImTextureStatus_WantCreate)
				&& (texture.Status != .ImTextureStatus_WantUpdates))
			{
				continue;
			}
			UploadTexture(encoder, texture);
		}
	}

	/// Creates the one atlas this renderer keeps, and uploads its pixels.
	///
	/// ONE only: the samples bind a single font atlas, so a request for a second is answered
	/// with the same texture rather than growing a table nothing would index.
	private void UploadTexture(ICommandEncoder encoder, ImTextureData* texture)
	{
		if ((texture.Pixels == null) || (texture.Width <= 0) || (texture.Height <= 0))
			return;

		let width = (uint32)texture.Width;
		let height = (uint32)texture.Height;
		let bytes = (uint64)width * (uint64)height * 4;

		if ((mFontTexture == null) || (mFontWidth != width) || (mFontHeight != height))
		{
			DestroyFont();

			TextureDesc textureDesc = .();
			textureDesc.Format = .RGBA8Unorm;
			textureDesc.Width = width;
			textureDesc.Height = height;
			textureDesc.Usage = .Sampled | .CopyDst;
			textureDesc.Label = "imgui.font";
			if (!(mDevice.CreateTexture(textureDesc) case .Ok(out mFontTexture)))
				return;

			TextureViewDesc viewDesc = .();
			viewDesc.Format = .RGBA8Unorm;
			viewDesc.Dimension = .Texture2D;
			if (!(mDevice.CreateTextureView(mFontTexture, viewDesc) case .Ok(out mFontView)))
				return;

			BufferDesc stagingDesc = .();
			stagingDesc.Size = bytes;
			stagingDesc.Usage = .CopySrc;
			stagingDesc.Memory = .CpuToGpu;
			stagingDesc.Label = "imgui.fontStaging";
			if (!(mDevice.CreateBuffer(stagingDesc) case .Ok(out mFontStaging)))
				return;

			mFontWidth = width;
			mFontHeight = height;
			mFontDirty = true;
		}

		let mapped = mFontStaging.Map();
		if (mapped == null)
			return;
		Internal.MemCpy(mapped, texture.Pixels, (int)bytes);
		mFontStaging.Unmap();

		// UNDEFINED on the first upload and readable afterwards: re-declaring a live texture as
		// undefined would let a driver discard what is already in it.
		encoder.TransitionTexture(mFontTexture, mFontDirty ? .Undefined : .ShaderRead, .CopyDst);

		BufferTextureCopyRegion region = .();
		region.BufferOffset = 0;
		region.BytesPerRow = width * 4;
		region.RowsPerImage = height;
		region.TextureExtent = .(width, height, 1);
		encoder.CopyBufferToTexture(mFontStaging, mFontTexture, region);

		encoder.TransitionTexture(mFontTexture, .CopyDst, .ShaderRead);
		mFontDirty = false;

		// The identity only has to be NON ZERO: one atlas is bound for everything, so nothing
		// ever looks it up.
		ImTextureData_SetTexID(texture, 1);

#if BF_PLATFORM_WASM
		// Status OK is the LATCH: ImGui stops asking once it is set, so the copy above is
		// recorded exactly once. A web startup submit can still be dropped, and losing that
		// one shot copy while the latch says done leaves ImGui rendering an empty atlas
		// forever. Re-record the (tiny) copy for the first frames instead, which is the same
		// startup window the IBL env bake and the probe captures use.
		mFontUploadFrames++;
		if (mFontUploadFrames >= cFontUploadFrames)
			ImTextureData_SetStatus(texture, .ImTextureStatus_OK);
#else
		ImTextureData_SetStatus(texture, .ImTextureStatus_OK);
#endif

		RebuildBindings();
	}

	/// Rebinds the slots onto the atlas that now exists.
	private void RebuildBindings()
	{
		if ((mFontView == null) || (mSampler == null))
			return;

		for (uint32 i < mFramesInFlight)
		{
			let slot = mFrames[i];
			if (slot.Projection == null)
				continue;
			if (slot.Bindings != null)
				Retire(ref slot.Bindings);

			let bindings = scope BindGroupEntry[](
				BindGroupEntry.BufferEntry(slot.Projection, 0, sizeof(Float4x4)),
				BindGroupEntry.TextureEntry(mFontView),
				BindGroupEntry.SamplerEntry(mSampler));

			BindGroupDesc bindGroupDesc = .();
			bindGroupDesc.Layout = mLayout;
			bindGroupDesc.Entries = bindings;
			if (mDevice.CreateBindGroup(bindGroupDesc) case .Ok(let group))
				slot.Bindings = group;
		}
	}

	/// Holds a replaced bind group for a full round of frames before freeing it.
	///
	/// One more than the frames in flight, so the slot that recorded against it has come round
	/// and been re-recorded before the set goes.
	private void Retire(ref IBindGroup group)
	{
		if (group == null)
			return;
		mRetired.Add((group, mFramesInFlight + 1));
		group = null;
	}

	private void TickRetired()
	{
		for (int i = mRetired.Count - 1; i >= 0; i--)
		{
			if (mRetired[i].FramesLeft > 1)
			{
				mRetired[i].FramesLeft--;
				continue;
			}

			var group = mRetired[i].Group;
			mDevice.DestroyBindGroup(ref group);
			mRetired.RemoveAtFast(i);
		}
	}

	/// Frees what is still held. The CALLER must have idled the device first, which Shutdown
	/// does: there is no later frame to wait for.
	private void FlushRetired()
	{
		for (var entry in ref mRetired)
			mDevice.DestroyBindGroup(ref entry.Group);
		mRetired.Clear();
	}

	private void DestroyFont()
	{
		if (mFontStaging != null)
			mDevice.DestroyBuffer(ref mFontStaging);
		if (mFontView != null)
			mDevice.DestroyTextureView(ref mFontView);
		if (mFontTexture != null)
			mDevice.DestroyTexture(ref mFontTexture);
	}

	private Result<void> UploadGeometry(ImguiFrameSlot slot, ImDrawData* drawData)
	{
		let vertexBytes = (uint64)drawData.TotalVtxCount * sizeof(ImDrawVert);
		let indexBytes = (uint64)drawData.TotalIdxCount * sizeof(uint16);
		if ((vertexBytes == 0) || (indexBytes == 0))
			return .Err;

		if (EnsureBuffer(ref slot.Vertices, ref slot.VertexCapacity, vertexBytes, .Vertex)
			case .Err)
		{
			return .Err;
		}
		if (EnsureBuffer(ref slot.Indices, ref slot.IndexCapacity, indexBytes, .Index) case .Err)
			return .Err;

		let vertexDestination = (uint8*)slot.Vertices.Map();
		let indexDestination = (uint8*)slot.Indices.Map();
		if ((vertexDestination == null) || (indexDestination == null))
		{
			if (vertexDestination != null)
				slot.Vertices.Unmap();
			if (indexDestination != null)
				slot.Indices.Unmap();
			return .Err;
		}

		// The lists are CONCATENATED into one pair of buffers, which is why the draw calls
		// carry a running vertex and index offset.
		uint64 vertexOffset = 0;
		uint64 indexOffset = 0;
		for (int32 n < drawData.CmdListsCount)
		{
			let commandList = drawData.CmdLists.Data[n];
			let listVertexBytes = (uint64)commandList.VtxBuffer.Size * sizeof(ImDrawVert);
			let listIndexBytes = (uint64)commandList.IdxBuffer.Size * sizeof(uint16);
			Internal.MemCpy(vertexDestination + vertexOffset, commandList.VtxBuffer.Data,
				(int)listVertexBytes);
			vertexOffset += listVertexBytes;
			Internal.MemCpy(indexDestination + indexOffset, commandList.IdxBuffer.Data,
				(int)listIndexBytes);
			indexOffset += listIndexBytes;
		}

		slot.Vertices.Unmap();
		slot.Indices.Unmap();
		return .Ok;
	}

	/// Grows a slot's buffer, with HEADROOM and rounded up, so a panel opening does not
	/// reallocate every frame while it animates open.
	private Result<void> EnsureBuffer(ref IBuffer buffer, ref uint64 capacity, uint64 bytes,
		BufferUsage usage)
	{
		if ((buffer != null) && (capacity >= bytes))
			return .Ok;

		if (buffer != null)
			mDevice.DestroyBuffer(ref buffer);

		let want = (bytes + (bytes / 2) + 0xFFFF) & ~(uint64)0xFFFF;
		BufferDesc desc = .();
		desc.Size = want;
		desc.Usage = usage;
		desc.Memory = .CpuToGpu;
		desc.Label = "imgui.geom";
		if (!(mDevice.CreateBuffer(desc) case .Ok(let created)))
		{
			buffer = null;
			capacity = 0;
			return .Err;
		}
		buffer = created;
		capacity = want;
		return .Ok;
	}

	/// The pipeline follows the TARGET's format: a window whose swapchain came back in another
	/// format after a device loss gets a pipeline that matches it.
	private IRenderPipeline EnsurePipeline(TextureFormat format)
	{
		if ((mPipeline != null) && (mPipelineFormat == format))
			return mPipeline;

		let vertexShader = mShaders.GetVariant("imgui", .Vertex, .None);
		let fragmentShader = mShaders.GetVariant("imgui", .Fragment, .None);
		if ((vertexShader == null) || (fragmentShader == null))
			return null;

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);

		// The vertex is two floats of position, two of texture coordinate and a packed colour,
		// which is the layout the interface builds its lists in.
		let attributes = scope VertexAttribute[](
			.(.Float32x2, 0, 0),
			.(.Float32x2, 8, 1),
			.(.Unorm8x4, 16, 2));

		VertexBufferLayout vertexLayout = .();
		vertexLayout.Stride = sizeof(ImDrawVert);
		vertexLayout.StepMode = .Vertex;
		vertexLayout.Attributes = attributes;

		ColorTargetState colorTarget = .();
		colorTarget.Format = format;
		colorTarget.Blend = BlendState.AlphaBlend;

		let targets = scope ColorTargetState[](colorTarget);
		let buffers = scope VertexBufferLayout[](vertexLayout);

		RenderPipelineDesc desc = .();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertexShader, "main", .Vertex);
		desc.Vertex.Buffers = buffers;
		FragmentState fragment = .();
		fragment.Shader = .(fragmentShader, "main", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "imgui";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(out mPipeline)))
		{
			mPipeline = null;
			return null;
		}
		mPipelineFormat = format;
		return mPipeline;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		FlushRetired();
		for (let slot in mFrames)
		{
			if (slot.Bindings != null)
				mDevice.DestroyBindGroup(ref slot.Bindings);
			if (slot.Projection != null)
				mDevice.DestroyBuffer(ref slot.Projection);
			if (slot.Vertices != null)
				mDevice.DestroyBuffer(ref slot.Vertices);
			if (slot.Indices != null)
				mDevice.DestroyBuffer(ref slot.Indices);
		}

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		DestroyFont();
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
