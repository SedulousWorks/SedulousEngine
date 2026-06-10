namespace Sedulous.VG.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.VG;
using Sedulous.Core.Mathematics;
using Sedulous.Images;
using Sedulous.Textures;

/// Uniform buffer data for projection matrix.
[CRepr]
struct VGUniforms
{
	public Matrix Projection;
}

/// A handle to a single batch's data inside a shared frame buffer.
/// Returned by `VGRenderer.Prepare`; passed to `VGRenderer.Render` to
/// dispatch just that slice. Multiple slices in a frame share one
/// `VGRenderer`'s vertex/index/uniform buffers via byte-offset
/// sub-allocation.
public struct VGRenderSlice
{
	/// Byte offset into the frame's vertex buffer.
	public uint32 VertexByteOffset;
	/// Byte offset into the frame's index buffer.
	public uint32 IndexByteOffset;
	/// Byte offset into the frame's uniform buffer (dynamic offset for
	/// the bind group's uniform binding).
	public uint32 UniformByteOffset;
	/// Range into the renderer's draw command list owned by this slice.
	public int32 DrawCommandStart;
	public int32 DrawCommandCount;
	/// False if the slice couldn't be allocated (capacity exceeded);
	/// `Render` treats invalid slices as no-ops.
	public bool IsValid;

	public static VGRenderSlice Invalid => .() { IsValid = false };
}

/// Renders VGContext/VGBatch content using RHI.
/// Creates GPU vertex/index buffers, uploads per-frame, and renders with alpha blending.
/// Creates GPU textures on demand from IImageData provided by the VGBatch.
/// Does NOT own the device or swapchain - caller manages those.
public class VGRenderer : IDisposable
{
	private IDevice mDevice;
	private IQueue mQueue;
	private int32 mFrameCount;
	private TextureFormat mTargetFormat;
	private ShaderSystem mShaderSystem;

	// Pipeline
	private IShaderModule mVertShader;
	private IShaderModule mFragShader;
	private IBindGroupLayout mBindGroupLayout;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;

	// Per-frame resources
	private IBuffer[] mVertexBuffers;
	private IBuffer[] mIndexBuffers;
	private IBuffer[] mUniformBuffers;

	// Sampler
	private ISampler mSampler;

	// Texture cache - maps IImageData to GPU resources.
	// Using a list since IImageData doesn't implement IHashable.
	private List<CachedTexture> mTextureCache = new .() ~ { for (var e in _) { e.Dispose(mDevice, mFrameCount); delete e; } delete _; };

	// Shared external texture cache (optional, not owned).
	private VGExternalTextureCache mExternalCache;

	// Textures from the current batch (stored for bind group creation during Render)
	private List<IImageData> mBatchTextures = new .() ~ delete _;

	/// Cached GPU resources for an IImageData.
	private class CachedTexture
	{
		public IImageData SourceTexture;
		public Sedulous.RHI.ITexture GpuTexture;
		public ITextureView GpuTextureView;
		public IBindGroup[] BindGroups;
		public bool IsExternal;  // If true, we don't own the GPU resources
		public int32 ExternalVersion; // For detecting shared cache updates

		public void Dispose(IDevice device, int32 frameCount)
		{
			if (BindGroups != null)
			{
				for (int i = 0; i < frameCount; i++)
					if (BindGroups[i] != null) { var bg = BindGroups[i]; device.DestroyBindGroup(ref bg); BindGroups[i] = null; }
				delete BindGroups;
			}
			if (!IsExternal)
			{
				if (GpuTextureView != null) device.DestroyTextureView(ref GpuTextureView);
				if (GpuTexture != null) device.DestroyTexture(ref GpuTexture);
			}
		}
	}

	// Batch data converted for GPU. Accumulates across all Prepare calls
	// within a frame (between BeginFrame and the next BeginFrame); each
	// slice's draw commands occupy a contiguous range.
	private List<VGRenderVertex> mVertices = new .() ~ delete _;
	private List<uint32> mIndices = new .() ~ delete _;
	private List<VGCommand> mDrawCommands = new .() ~ delete _;

	// Per-frame ring offsets (one entry per frame index). Reset by
	// BeginFrame; advanced by each Prepare call. Bytes.
	private uint32[] mFrameVertexOffsets;
	private uint32[] mFrameIndexOffsets;
	private uint32[] mFrameUniformSlotCount;

	// Buffer sizes
	private const int32 MAX_VERTICES = 131072;
	private const int32 MAX_INDICES = 131072 * 3;
	/// Per-frame maximum number of slices supported. Each uniform slot
	/// holds one `VGUniforms` padded to `UNIFORM_SLOT_SIZE` for dynamic-
	/// offset alignment. 64 slots × 256 B = 16 KB per uniform buffer.
	private const int32 MAX_UNIFORM_SLOTS = 64;
	/// Conservative dynamic-offset alignment. Vulkan minUniformBufferOffsetAlignment
	/// is typically 256; D3D12 is 256. `sizeof(VGUniforms)` is 64.
	private const int32 UNIFORM_SLOT_SIZE = 256;

	public bool IsInitialized { get; private set; }

	/// Initialize the renderer with a shader system.
	public Result<void> Initialize(
		IDevice device,
		TextureFormat targetFormat,
		int32 frameCount,
		ShaderSystem shaderSystem)
	{
		mDevice = device;
		mQueue = device.GetQueue(.Graphics);
		mTargetFormat = targetFormat;
		mFrameCount = frameCount;
		mShaderSystem = shaderSystem;

		if (LoadShaders() case .Err)
			return .Err;

		if (CreateSampler() case .Err)
			return .Err;

		if (CreateLayouts() case .Err)
			return .Err;

		if (CreatePipeline() case .Err)
			return .Err;

		if (CreatePerFrameResources() case .Err)
			return .Err;

		// Per-frame ring-offset state.
		mFrameVertexOffsets = new uint32[mFrameCount];
		mFrameIndexOffsets = new uint32[mFrameCount];
		mFrameUniformSlotCount = new uint32[mFrameCount];

		IsInitialized = true;
		return .Ok;
	}

	/// Get or create cached GPU resources for an IImageData.
	private CachedTexture GetOrCreateCachedTexture(IImageData texture)
	{
		if (texture == null)
			return null;

		for (let cached in mTextureCache)
		{
			if (cached.SourceTexture === texture)
			{
				// Check if external texture was updated in shared cache.
				if (cached.IsExternal && mExternalCache != null)
				{
					if (mExternalCache.TryGet(texture, var extEntry))
					{
						if (extEntry.Version != cached.ExternalVersion)
						{
							// Texture changed - update view and invalidate bind groups.
							cached.GpuTextureView = extEntry.TextureView;
							cached.ExternalVersion = extEntry.Version;
							if (cached.BindGroups != null)
							{
								for (int i = 0; i < mFrameCount; i++)
								{
									if (cached.BindGroups[i] != null)
									{
										var bg = cached.BindGroups[i];
										mDevice.DestroyBindGroup(ref bg);
										cached.BindGroups[i] = null;
									}
								}
							}
						}
					}
				}
				return cached;
			}
		}

		// Check shared external texture cache before trying pixel upload.
		// Only pick up entries that are marked ready (texture has been rendered to).
		if (mExternalCache != null)
		{
			if (mExternalCache.TryGet(texture, var extEntry) && extEntry.IsReady)
			{
				let cached = new CachedTexture();
				cached.SourceTexture = texture;
				cached.GpuTexture = null;
				cached.GpuTextureView = extEntry.TextureView;
				cached.BindGroups = new IBindGroup[mFrameCount];
				cached.IsExternal = true;
				cached.ExternalVersion = extEntry.Version;
				mTextureCache.Add(cached);
				return cached;
			}
		}

		let pixelData = texture.PixelData;
		if (pixelData.Length == 0)
			return null;

		let width = texture.Width;
		let height = texture.Height;
		let format = TextureFormatUtils.Convert(texture.Format, texture.ColorSpace);

		TextureDesc textureDesc = TextureDesc.Texture2D(
			width, height, format, TextureUsage.Sampled | TextureUsage.CopyDst,
			label: "VGRenderer cached texture"
		);

		Sedulous.RHI.ITexture gpuTexture;
		if (mDevice.CreateTexture(textureDesc) case .Ok(let tex))
			gpuTexture = tex;
		else
			return null;

		TextureDataLayout dataLayout = .()
		{
			Offset = 0,
			BytesPerRow = width * (uint32)Image.GetBytesPerPixel(texture.Format),
			RowsPerImage = height
		};
		Extent3D writeSize = .(width, height, 1);
		TransferHelper.WriteTextureSync(mQueue, mDevice, gpuTexture, pixelData, dataLayout, writeSize);

		TextureViewDesc viewDesc = .() { Format = format };
		ITextureView gpuTextureView;
		if (mDevice.CreateTextureView(gpuTexture, viewDesc) case .Ok(let view))
			gpuTextureView = view;
		else
		{
			mDevice.DestroyTexture(ref gpuTexture);
			return null;
		}

		let cached = new CachedTexture();
		cached.SourceTexture = texture;
		cached.GpuTexture = gpuTexture;
		cached.GpuTextureView = gpuTextureView;
		cached.BindGroups = new IBindGroup[mFrameCount];
		mTextureCache.Add(cached);

		return cached;
	}

	/// Clear all cached textures.
	public void ClearTextureCache()
	{
		for (var cached in mTextureCache)
		{
			cached.Dispose(mDevice, mFrameCount);
			delete cached;
		}
		mTextureCache.Clear();
	}

	/// Set the shared external texture cache. All VGRenderers sharing the same
	/// cache will automatically pick up external textures during rendering.
	public void SetExternalCache(VGExternalTextureCache cache)
	{
		mExternalCache = cache;
	}

	/// Register an external GPU texture. Updates the local cache for immediate
	/// use by this VGRenderer, and registers with the shared cache so other
	/// VGRenderers can pick it up once marked ready.
	public void RegisterExternalTexture(IImageData imageRef, ITextureView gpuTextureView)
	{
		if (imageRef == null || gpuTextureView == null) return;

		// Register with shared cache (starts as not-ready for other renderers).
		if (mExternalCache != null)
			mExternalCache.Register(imageRef, gpuTextureView);

		// Update local cache directly for immediate use by this renderer.
		for (let cached in mTextureCache)
		{
			if (cached.SourceTexture === imageRef)
			{
				if (!cached.IsExternal)
				{
					if (cached.GpuTextureView != null) { var v = cached.GpuTextureView; mDevice.DestroyTextureView(ref v); cached.GpuTextureView = null; }
					if (cached.GpuTexture != null) { var t = cached.GpuTexture; mDevice.DestroyTexture(ref t); cached.GpuTexture = null; }
				}
				cached.GpuTextureView = gpuTextureView;
				cached.GpuTexture = null;
				cached.IsExternal = true;
				// Invalidate bind groups so they get recreated with the new texture.
				if (cached.BindGroups != null)
				{
					for (int i = 0; i < mFrameCount; i++)
					{
						if (cached.BindGroups[i] != null)
						{
							var bg = cached.BindGroups[i];
							mDevice.DestroyBindGroup(ref bg);
							cached.BindGroups[i] = null;
						}
					}
				}
				return;
			}
		}

		// Not in local cache - create new entry.
		let cached = new CachedTexture();
		cached.SourceTexture = imageRef;
		cached.GpuTexture = null;
		cached.GpuTextureView = gpuTextureView;
		cached.BindGroups = new IBindGroup[mFrameCount];
		cached.IsExternal = true;
		mTextureCache.Add(cached);
	}

	/// Unregister an external texture from the shared cache.
	public void UnregisterExternalTexture(IImageData imageRef)
	{
		if (mExternalCache != null)
			mExternalCache.Unregister(imageRef);

		// Also remove local cached entry so stale bind groups aren't used.
		for (int i = 0; i < mTextureCache.Count; i++)
		{
			if (mTextureCache[i].SourceTexture === imageRef && mTextureCache[i].IsExternal)
			{
				let cached = mTextureCache[i];
				if (cached.BindGroups != null)
				{
					for (int j = 0; j < mFrameCount; j++)
					{
						if (cached.BindGroups[j] != null)
						{
							var bg = cached.BindGroups[j];
							mDevice.DestroyBindGroup(ref bg);
							cached.BindGroups[j] = null;
						}
					}
					delete cached.BindGroups;
					cached.BindGroups = null;
				}
				delete cached;
				mTextureCache.RemoveAt(i);
				return;
			}
		}
	}

	/// Mark an external texture as ready in the shared cache.
	/// Call after the texture has been rendered to and transitioned to ShaderRead.
	public void MarkExternalTextureReady(IImageData imageRef)
	{
		if (mExternalCache != null)
			mExternalCache.MarkReady(imageRef);
	}

	/// Reset per-frame ring-offset state for the given frame index.
	/// Call once per frame before the first `Prepare` for that frame.
	/// Frees prior frames' CPU-side draw commands + batch-texture refs;
	/// the GPU has already consumed the previous frame's data.
	public void BeginFrame(int32 frameIndex)
	{
		mFrameVertexOffsets[frameIndex] = 0;
		mFrameIndexOffsets[frameIndex] = 0;
		mFrameUniformSlotCount[frameIndex] = 0;
		mVertices.Clear();
		mIndices.Clear();
		mDrawCommands.Clear();
		mBatchTextures.Clear();
	}

	/// Upload one batch's vertices, indices, projection uniform, and
	/// draw commands into the shared frame buffers. Returns a slice
	/// token that `Render` consumes to dispatch just this batch's draws
	/// out of the shared state.
	///
	/// Multiple `Prepare` calls in a frame share one renderer; each gets
	/// its own non-overlapping byte ranges. Returns `VGRenderSlice.Invalid`
	/// when capacity (`MAX_VERTICES` / `MAX_INDICES` / `MAX_UNIFORM_SLOTS`)
	/// is exceeded - `Render` is a no-op for invalid slices.
	public VGRenderSlice Prepare(VGBatch batch, int32 frameIndex, uint32 width, uint32 height)
	{
		let vertCountIn = (uint32)batch.Vertices.Count;
		let idxCountIn = (uint32)batch.Indices.Count;
		if (vertCountIn == 0 || idxCountIn == 0)
			return .Invalid;

		// Capacity check.
		let vertByteSize = vertCountIn * (uint32)sizeof(VGRenderVertex);
		let idxByteSize = idxCountIn * (uint32)sizeof(uint32);
		let sliceVertOffset = mFrameVertexOffsets[frameIndex];
		let sliceIdxOffset = mFrameIndexOffsets[frameIndex];
		let sliceUniformSlot = mFrameUniformSlotCount[frameIndex];

		let maxVertBytes = (uint32)(MAX_VERTICES * sizeof(VGRenderVertex));
		let maxIdxBytes = (uint32)(MAX_INDICES * sizeof(uint32));
		let endVertOffset = sliceVertOffset + vertByteSize;
		let endIdxOffset = sliceIdxOffset + idxByteSize;
		let vertOverflow = endVertOffset > maxVertBytes;
		let idxOverflow = endIdxOffset > maxIdxBytes;
		let uniformOverflow = sliceUniformSlot >= (uint32)MAX_UNIFORM_SLOTS;
		if (vertOverflow || idxOverflow || uniformOverflow)
		{
			Console.WriteLine("VGRenderer: frame capacity exceeded, slice dropped");
			return .Invalid;
		}

		let sliceUniformOffset = sliceUniformSlot * (uint32)UNIFORM_SLOT_SIZE;
		let sliceCmdStart = (int32)mDrawCommands.Count;
		let textureBase = (int32)mBatchTextures.Count;

		// Append vertices / indices / textures / commands to CPU scratch.
		// Commands' TextureIndex is offset so it indexes into the shared
		// mBatchTextures rather than the per-batch list.
		for (let v in batch.Vertices)
			mVertices.Add(.(v));
		for (let i in batch.Indices)
			mIndices.Add(i);
		for (let tex in batch.Textures)
			mBatchTextures.Add(tex);
		for (let cmd in batch.Commands)
		{
			var adjustedCmd = cmd;
			if (cmd.TextureIndex >= 0)
				adjustedCmd.TextureIndex = cmd.TextureIndex + textureBase;
			mDrawCommands.Add(adjustedCmd);
		}

		// Upload this slice's vertex / index data at its byte offset.
		// Index data is taken from the freshly-appended tail of mIndices.
		let vertSliceData = Span<uint8>((uint8*)(&mVertices[(int)(sliceVertOffset / (uint32)sizeof(VGRenderVertex))]), (int)vertByteSize);
		TransferHelper.WriteMappedBuffer(mVertexBuffers[frameIndex], (uint64)sliceVertOffset, vertSliceData);

		let idxSliceData = Span<uint8>((uint8*)(&mIndices[(int)(sliceIdxOffset / (uint32)sizeof(uint32))]), (int)idxByteSize);
		TransferHelper.WriteMappedBuffer(mIndexBuffers[frameIndex], (uint64)sliceIdxOffset, idxSliceData);

		// Write this slice's projection into its uniform slot.
		Matrix projection = Matrix.CreateOrthographicOffCenter(0, (float)width, (float)height, 0, -1, 1);
		VGUniforms uniforms = .() { Projection = projection };
		let uniformData = Span<uint8>((uint8*)&uniforms, sizeof(VGUniforms));
		TransferHelper.WriteMappedBuffer(mUniformBuffers[frameIndex], (uint64)sliceUniformOffset, uniformData);

		// Bind groups for any newly-added batch textures.
		for (int32 texIdx = textureBase; texIdx < mBatchTextures.Count; texIdx++)
			UpdateTextureBindGroup(texIdx, frameIndex);

		// Advance ring offsets.
		mFrameVertexOffsets[frameIndex] = sliceVertOffset + vertByteSize;
		mFrameIndexOffsets[frameIndex] = sliceIdxOffset + idxByteSize;
		mFrameUniformSlotCount[frameIndex] = sliceUniformSlot + 1;

		return .()
		{
			VertexByteOffset = sliceVertOffset,
			IndexByteOffset = sliceIdxOffset,
			UniformByteOffset = sliceUniformOffset,
			DrawCommandStart = sliceCmdStart,
			DrawCommandCount = (int32)mDrawCommands.Count - sliceCmdStart,
			IsValid = true,
		};
	}

	/// Dispatch a slice's draws into the active render pass. Vertex /
	/// index buffer offsets come from the slice; the uniform binding's
	/// dynamic offset selects this slice's projection slot.
	public void Render(IRenderPassEncoder renderPass, uint32 width, uint32 height, int32 frameIndex, VGRenderSlice slice)
	{
		if (!slice.IsValid || slice.DrawCommandCount == 0)
			return;

		renderPass.SetViewport(0, 0, width, height, 0, 1);
		renderPass.SetPipeline(mPipeline);
		renderPass.SetVertexBuffer(0, mVertexBuffers[frameIndex], (uint64)slice.VertexByteOffset);
		renderPass.SetIndexBuffer(mIndexBuffers[frameIndex], .UInt32, (uint64)slice.IndexByteOffset);

		uint32[1] dynOffsets = .(slice.UniformByteOffset);

		// Track current texture to minimize bind group switches.
		// -2 sentinel forces first SetBindGroup so dynamic offset is set.
		int32 currentTextureIndex = -2;

		let cmdEnd = slice.DrawCommandStart + slice.DrawCommandCount;
		for (int32 i = slice.DrawCommandStart; i < cmdEnd; i++)
		{
			let cmd = mDrawCommands[i];
			if (cmd.IndexCount == 0)
				continue;

			let texIdx = cmd.TextureIndex;
			if (texIdx != currentTextureIndex)
			{
				let bindGroup = GetBindGroupForTexture(texIdx, frameIndex);
				if (bindGroup != null)
					renderPass.SetBindGroup(0, bindGroup, dynOffsets);
				currentTextureIndex = texIdx;
			}

			if (cmd.ClipMode == .Scissor && cmd.ClipRect.Width > 0 && cmd.ClipRect.Height > 0)
			{
				let startX = (int32)Math.Ceiling(Math.Max(0f, cmd.ClipRect.X));
				let startY = (int32)Math.Ceiling(Math.Max(0f, cmd.ClipRect.Y));
				let endX = (int32)Math.Floor(Math.Min(cmd.ClipRect.X + cmd.ClipRect.Width, (float)width));
				let endY = (int32)Math.Floor(Math.Min(cmd.ClipRect.Y + cmd.ClipRect.Height, (float)height));
				let w = (uint32)Math.Max(0, endX - startX);
				let h = (uint32)Math.Max(0, endY - startY);
				renderPass.SetScissor(startX, startY, w, h);
			}
			else if (cmd.ClipMode == .Scissor)
			{
				// Empty/invalid clip rect - hide everything
				renderPass.SetScissor(0, 0, 0, 0);
			}
			else
			{
				renderPass.SetScissor(0, 0, width, height);
			}

			renderPass.DrawIndexed((uint32)cmd.IndexCount, 1, (uint32)cmd.StartIndex, 0, 0);
		}
	}

	private Result<void> LoadShaders()
	{
		if (mShaderSystem == null)
			return .Err;

		let result = mShaderSystem.GetShaderPair("vg", .None);
		if (result case .Ok(let shaders))
		{
			mVertShader = shaders.vert.Module;
			mFragShader = shaders.frag.Module;
		}
		else
		{
			Console.WriteLine("Failed to load VG shaders");
			return .Err;
		}

		return .Ok;
	}

	private Result<void> CreateSampler()
	{
		SamplerDesc samplerDesc = .();
		if (mDevice.CreateSampler(samplerDesc) case .Ok(let sampler))
		{
			mSampler = sampler;
			return .Ok;
		}
		return .Err;
	}

	private Result<void> CreateLayouts()
	{
		// Bind group layout: uniform buffer (b0, dynamic offset), texture (t0), sampler (s0).
		// Dynamic offset lets multiple slices in a frame share one uniform buffer with each
		// slice's projection at a different offset.
		BindGroupLayoutEntry[3] layoutEntries = .(
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex, true),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment)
		);
		BindGroupLayoutDesc bindGroupLayoutDesc = .(layoutEntries);
		if (mDevice.CreateBindGroupLayout(bindGroupLayoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		PipelineLayoutDesc pipelineLayoutDesc = .(layouts);
		if (mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout))
			mPipelineLayout = pipelineLayout;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		// Vertex layout: position (float2), texcoord (float2), color (float4), coverage (float)
		VertexAttribute[4] vertexAttributes = .(
			.(VertexFormat.Float2, 0, 0),    // Position
			.(VertexFormat.Float2, 8, 1),    // TexCoord
			.(VertexFormat.Float4, 16, 2),   // Color
			.(VertexFormat.Float, 32, 3)     // Coverage
		);
		VertexBufferLayout[1] vertexBuffers = .(
			.((uint64)sizeof(VGRenderVertex), vertexAttributes)
		);

		ColorTargetState[1] colorTargets = .(.(mTargetFormat, .AlphaBlend));

		RenderPipelineDesc pipelineDesc = .()
		{
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(mVertShader, "main"),
				Buffers = vertexBuffers
			},
			Fragment = .()
			{
				Shader = .(mFragShader, "main"),
				Targets = colorTargets
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				FrontFace = .CCW,
				CullMode = .None
			},
			DepthStencil = null,
			Multisample = .()
			{
				Count = 1,
				Mask = uint32.MaxValue,
				AlphaToCoverageEnabled = false
			}
		};

		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipeline))
			mPipeline = pipeline;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreatePerFrameResources()
	{
		mVertexBuffers = new IBuffer[mFrameCount];
		mIndexBuffers = new IBuffer[mFrameCount];
		mUniformBuffers = new IBuffer[mFrameCount];

		for (int32 i = 0; i < mFrameCount; i++)
		{
			// Vertex buffer
			BufferDesc vertexDesc = .()
			{
				Size = (uint64)(MAX_VERTICES * sizeof(VGRenderVertex)),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(vertexDesc) case .Ok(let vb))
				mVertexBuffers[i] = vb;
			else
				return .Err;

			// Index buffer (uint32)
			BufferDesc indexDesc = .()
			{
				Size = (uint64)(MAX_INDICES * sizeof(uint32)),
				Usage = .Index,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(indexDesc) case .Ok(let ib))
				mIndexBuffers[i] = ib;
			else
				return .Err;

			// Uniform buffer - sized to hold MAX_UNIFORM_SLOTS slices.
			BufferDesc uniformDesc = .()
			{
				Size = (uint64)(MAX_UNIFORM_SLOTS * UNIFORM_SLOT_SIZE),
				Usage = .Uniform,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(uniformDesc) case .Ok(let ub))
				mUniformBuffers[i] = ub;
			else
				return .Err;
		}

		return .Ok;
	}

	private void UpdateTextureBindGroup(int32 textureIndex, int32 frameIndex)
	{
		if (textureIndex >= mBatchTextures.Count)
			return;

		let texture = mBatchTextures[textureIndex];
		if (texture == null)
			return;

		let cached = GetOrCreateCachedTexture(texture);
		if (cached == null || cached.GpuTextureView == null)
			return;

		// Skip if bind group already exists for this frame
		if (cached.BindGroups[frameIndex] != null)
			return;

		BindGroupEntry[3] bindGroupEntries = .(
			BindGroupEntry.Buffer(mUniformBuffers[frameIndex], 0, (uint64)sizeof(VGUniforms)),
			BindGroupEntry.Texture(cached.GpuTextureView),
			BindGroupEntry.Sampler(mSampler)
		);
		BindGroupDesc bindGroupDesc = .(mBindGroupLayout, bindGroupEntries);
		if (mDevice.CreateBindGroup(bindGroupDesc) case .Ok(let group))
			cached.BindGroups[frameIndex] = group;
	}

	private IBindGroup GetBindGroupForTexture(int32 textureIndex, int32 frameIndex)
	{
		if (mBatchTextures.Count == 0)
			return null;

		// For solid-color drawing (legacy index -1), use texture 0 (white fallback).
		let effectiveIndex = (textureIndex < 0) ? 0 : textureIndex;
		if (effectiveIndex >= mBatchTextures.Count)
			return null;

		let texture = mBatchTextures[effectiveIndex];
		if (texture == null)
			return null;

		for (let cached in mTextureCache)
		{
			if (cached.SourceTexture === texture)
				return cached.BindGroups[frameIndex];
		}
		return null;
	}

	public void Dispose()
	{
		// Texture cache (includes bind groups)
		ClearTextureCache();

		if (mFrameVertexOffsets != null) { delete mFrameVertexOffsets; mFrameVertexOffsets = null; }
		if (mFrameIndexOffsets != null) { delete mFrameIndexOffsets; mFrameIndexOffsets = null; }
		if (mFrameUniformSlotCount != null) { delete mFrameUniformSlotCount; mFrameUniformSlotCount = null; }

		if (mUniformBuffers != null)
		{
			for (var buf in ref mUniformBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mUniformBuffers;
			mUniformBuffers = null;
		}
		if (mIndexBuffers != null)
		{
			for (var buf in ref mIndexBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mIndexBuffers;
			mIndexBuffers = null;
		}
		if (mVertexBuffers != null)
		{
			for (var buf in ref mVertexBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mVertexBuffers;
			mVertexBuffers = null;
		}

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);

		IsInitialized = false;
	}
}
