using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;
using cimgui_Beef;

namespace Imgui;

/// A Dear ImGui renderer on the engine's own RHI, rather than one of the stock backends.
///
/// It owns the pipeline, the font atlas and the per frame geometry. Prepare readies a frame's
/// draw data before a pass and Draw records it into one (the render subsystem's shared overlay
/// pass, the window turned onto the target when the swapchain is pre-rotated); Render does both
/// in a pass of its own that LOADS what is already there. The interface is drawn over the scene,
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
	private TextureFormat mPipelineDepthStencil = .Undefined;

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
	/// been through. Reading the atlas once at startup would make the bind groups once and
	/// destroy them only at shutdown; the library asks for its texture on a frame here
	/// instead, which means rebinding while the previous frame's command buffer is still
	/// recorded against the old set.
	private List<(IBindGroup Group, uint32 FramesLeft)> mRetired = new .() ~ delete _;

	/// What Prepare readied for the next Draw, one of mFrames.
	private ImguiFrameSlot mPrepared = null;

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

	/// The projection a vertex in window pixels takes to clip space on a target of `target`
	/// pixels that the window is drawn into turned (`windowToTarget`: the overlay view's
	/// WindowToTargetTransform, the identity when nothing is turned): the turn, then the
	/// target's orthographic map (0..width, 0..height, Y down). Row vectors.
	public static Float4x4 Projection(Float2 target, Float4x4 windowToTarget)
	{
		Float4x4 ortho = .();
		ortho.M[0][0] = 2.0f / target.X;
		ortho.M[1][1] = -2.0f / target.Y;
		ortho.M[2][2] = 1.0f;
		ortho.M[3][3] = 1.0f;
		ortho.M[3][0] = -1.0f;
		ortho.M[3][1] = 1.0f;
		return windowToTarget * ortho;
	}

	/// The scissor for a draw's clip rectangle, in window pixels, on the target: turned with the
	/// window (`turn`, the window `window` pixels) and kept inside the target, since a scissor
	/// outside the attachment drops the whole command buffer on a validating backend. False when
	/// nothing of it is left.
	public static bool Scissor(Rectangle clip, ContentRotation turn, Float2 window, uint32 targetWidth,
		uint32 targetHeight, out uint32 x, out uint32 y, out uint32 width, out uint32 height)
	{
		x = 0;
		y = 0;
		width = 0;
		height = 0;
		let r = ContentFit.TurnRectangle(clip, turn, window);
		let x0 = Math.Max(r.X, 0.0f);
		let y0 = Math.Max(r.Y, 0.0f);
		let x1 = Math.Min(r.X + r.Width, (float)targetWidth);
		let y1 = Math.Min(r.Y + r.Height, (float)targetHeight);
		if ((x1 <= x0) || (y1 <= y0))
			return false;
		x = (uint32)x0;
		y = (uint32)y0;
		width = (uint32)x1 - x;
		height = (uint32)y1 - y;
		return (width > 0) && (height > 0);
	}

	/// Readies `drawData` for a pass on a target of `targetFormat` (with `depthStencilFormat`'s
	/// attachment, Undefined for none) and `target` pixels: the font, the geometry and the
	/// projection, recorded on `encoder` BEFORE the pass opens, because a copy cannot be recorded
	/// inside one. False when there is nothing to draw; Draw then draws nothing.
	public bool Prepare(ICommandEncoder encoder, TextureFormat targetFormat, TextureFormat depthStencilFormat,
		Float2 target, Float4x4 windowToTarget, ImDrawData* drawData, uint32 frameIndex)
	{
		mPrepared = null;
		if (drawData == null)
			return false;

		TickRetired();
		ServiceTextures(encoder, drawData);
		let pipeline = EnsurePipeline(targetFormat, depthStencilFormat);
		if (pipeline == null)
			return false;
		if ((drawData.TotalVtxCount <= 0) || (drawData.CmdListsCount <= 0))
			return false;

		let slot = mFrames[frameIndex % mFramesInFlight];
		if (slot.Bindings == null)
			return false; // no atlas yet, so there is nothing the draws could sample
		if (UploadGeometry(slot, drawData) case .Err)
			return false;

		let projection = Projection(target, windowToTarget);
		let mappedProjection = slot.Projection.Map();
		if (mappedProjection != null)
		{
			var copy = projection;
			Internal.MemCpy(mappedProjection, &copy, sizeof(Float4x4));
			slot.Projection.Unmap();
		}
		mPrepared = slot;
		return true;
	}

	/// Draws what Prepare readied into the open `pass` on a `targetWidth` x `targetHeight`
	/// target, the window (`window` pixels) drawn into it turned by `turn`.
	public void Draw(IRenderPassEncoder pass, ImDrawData* drawData, ContentRotation turn, Float2 window,
		uint32 targetWidth, uint32 targetHeight)
	{
		let slot = mPrepared;
		mPrepared = null;
		if ((slot == null) || (drawData == null))
			return;

		pass.SetViewport(0.0f, 0.0f, (float)targetWidth, (float)targetHeight);
		pass.SetPipeline(mPipeline);
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

				let clip = Rectangle(command.ClipRect.x - clipOffset.x, command.ClipRect.y - clipOffset.y,
					command.ClipRect.z - command.ClipRect.x, command.ClipRect.w - command.ClipRect.y);
				if (!Scissor(clip, turn, window, targetWidth, targetHeight, let x, let y, let w, let h))
					continue;

				pass.SetScissor((int32)x, (int32)y, w, h);
				pass.SetBindGroup(0, slot.Bindings, .());
				pass.DrawIndexed(command.ElemCount, 1, command.IdxOffset + globalIndex,
					(int32)(command.VtxOffset + globalVertex), 0);
			}
			globalVertex += (uint32)commandList.VtxBuffer.Size;
			globalIndex += (uint32)commandList.IdxBuffer.Size;
		}
	}

	/// Records the built draw data in a render pass of its own on `target`, LOADED and drawn over
	/// the scene, for an application with no render subsystem whose overlays would draw it.
	public void Render(ICommandEncoder encoder, ITextureView target, TextureFormat targetFormat,
		uint32 width, uint32 height, ImDrawData* drawData, uint32 frameIndex)
	{
		if ((target == null) || (width == 0) || (height == 0))
			return;

		// The projection spans the display size the interface laid out for, which trails the
		// target by a frame across a resize (it is set at NewFrame); the scissors keep to the
		// target.
		let size = Float2((float)width, (float)height);
		let display = ((drawData != null) && (drawData.DisplaySize.x > 0.0f) && (drawData.DisplaySize.y > 0.0f))
			? Float2(drawData.DisplaySize.x, drawData.DisplaySize.y)
			: size;
		if (!Prepare(encoder, targetFormat, .Undefined, display, Float4x4.Identity(), drawData, frameIndex))
			return;

		ColorAttachment attachment = .();
		attachment.View = target;
		attachment.LoadOp = .Load; // OVER the scene, never instead of it
		attachment.StoreOp = .Store;

		RenderPassDesc passDesc = .();
		passDesc.ColorAttachments.Add(attachment);
		passDesc.Label = "imgui";

		let pass = encoder.BeginRenderPass(passDesc);
		if (pass == null)
		{
			mPrepared = null;
			return;
		}
		Draw(pass, drawData, .None, display, width, height);
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
	/// format after a device loss gets a pipeline that matches it. `depthStencilFormat` is the
	/// pass's depth attachment (Undefined for none: a pass of its own), which the interface
	/// neither tests nor writes.
	private IRenderPipeline EnsurePipeline(TextureFormat format, TextureFormat depthStencilFormat)
	{
		if ((mPipeline != null) && (mPipelineFormat == format) && (mPipelineDepthStencil == depthStencilFormat))
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
		desc.Vertex.Shader = .(vertexShader, .Vertex);
		desc.Vertex.Buffers = buffers;
		FragmentState fragment = .();
		fragment.Shader = .(fragmentShader, .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		if (depthStencilFormat != .Undefined)
		{
			DepthStencilState depthStencil = .();
			depthStencil.Format = depthStencilFormat;
			depthStencil.DepthTestEnabled = false;
			depthStencil.DepthWriteEnabled = false;
			depthStencil.DepthCompare = .Always;
			desc.DepthStencil = depthStencil;
		}
		desc.Label = "imgui";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(out mPipeline)))
		{
			mPipeline = null;
			return null;
		}
		mPipelineFormat = format;
		mPipelineDepthStencil = depthStencilFormat;
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
