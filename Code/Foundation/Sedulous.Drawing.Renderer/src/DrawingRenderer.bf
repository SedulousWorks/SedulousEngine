namespace Sedulous.Drawing.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Drawing;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;
using Sedulous.Images;
using Sedulous.Textures;

/// Uniform buffer data for projection matrix.
[CRepr]
struct DrawingUniforms
{
	public Matrix Projection;
}

/// Handle to a single batch's data inside the shared per-frame buffers
/// for the standard (per-vertex) path. Returned by `DrawingRenderer.Prepare`;
/// passed to `DrawingRenderer.Render` to dispatch only that slice. Multiple
/// slices in a frame share one vertex/index/uniform buffer via byte offsets.
public struct DrawingRenderSlice
{
	public uint32 VertexByteOffset;
	public uint32 IndexByteOffset;
	public uint32 UniformByteOffset;
	public int32 DrawCommandStart;
	public int32 DrawCommandCount;
	public bool IsValid;

	public static DrawingRenderSlice Invalid => .() { IsValid = false };
}

/// Handle to a single batch's data for the instanced sprite path.
/// Returned by `PrepareInstanced`; passed to `RenderInstanced`.
public struct DrawingInstancedSlice
{
	public uint32 InstanceByteOffset;
	public uint32 InstanceCount;
	public uint32 UniformByteOffset;
	public bool IsValid;

	public static DrawingInstancedSlice Invalid => .() { IsValid = false };
}

/// Per-instance data for instanced sprite rendering.
/// Must match the shader's InstanceInput struct layout.
[CRepr]
public struct DrawingSpriteInstance
{
	public Vector2 Position;    // Screen position (top-left)
	public Vector2 Size;        // Width, height in pixels
	public Vector4 UVRect;      // minU, minV, maxU, maxV
	public Color32 Color;         // RGBA color
	public float Rotation;      // Rotation in radians
	public float _Pad0;         // Padding to 48 bytes
	public float _Pad1;
	public float _Pad2;

	public this(Vector2 position, Vector2 size, Vector4 uvRect, Color32 color, float rotation = 0)
	{
		Position = position;
		Size = size;
		UVRect = uvRect;
		Color = color;
		Rotation = rotation;
		_Pad0 = 0;
		_Pad1 = 0;
		_Pad2 = 0;
	}
}

/// Renders DrawContext/DrawBatch content using RHI.
/// Supports both per-vertex rendering (shapes, text) and GPU-instanced sprites.
/// Creates GPU textures on demand from ITexture.PixelData.
/// Does NOT own the device or swapchain - caller manages those.
public class DrawingRenderer : IDisposable
{
	private IDevice mDevice;
	private IQueue mQueue;
	private int32 mFrameCount;
	private TextureFormat mTargetFormat;
	private ShaderSystem mShaderSystem;  // Borrowed, not owned

	// Standard pipeline (per-vertex)
	private IShaderModule mVertShader;
	private IShaderModule mFragShader;
	private IBindGroupLayout mBindGroupLayout;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private IRenderPipeline mMsaaPipeline;

	// Instanced pipeline
	private IShaderModule mInstancedVertShader;
	private IShaderModule mInstancedFragShader;
	private IRenderPipeline mInstancedPipeline;
	private IRenderPipeline mInstancedMsaaPipeline;

	private uint32 mMsaaSampleCount = 4;

	// Per-frame resources for standard rendering
	private IBuffer[] mVertexBuffers;
	private IBuffer[] mIndexBuffers;
	private IBuffer[] mUniformBuffers;

	// Per-frame resources for instanced rendering
	private IBuffer[] mInstanceBuffers;
	private IBindGroup[] mInstancedBindGroups;

	// Sampler for texture sampling
	private ISampler mSampler;

	// Texture cache - maps Drawing.ITexture to GPU resources
	// Using list since ITexture doesn't implement IHashable
	private List<CachedTexture> mTextureCache = new .() ~ { for (var e in _) { e.Dispose(mDevice, mFrameCount); delete e; } delete _; };

	// Shared external texture cache (optional, not owned).
	private DrawingExternalTextureCache mExternalCache;

	// Textures from current batch (stored for bind group creation)
	private List<IImageData> mBatchTextures = new .() ~ delete _;

	/// Cached GPU resources for a Drawing.ITexture
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
			// Only destroy GPU resources if we own them
			if (!IsExternal)
			{
				if (GpuTextureView != null) device.DestroyTextureView(ref GpuTextureView);
				if (GpuTexture != null) device.DestroyTexture(ref GpuTexture);
			}
		}
	}

	// Batch data converted for GPU (standard mode). Accumulates across
	// every Prepare call in a frame; reset by BeginFrame.
	private List<DrawingRenderVertex> mVertices = new .() ~ delete _;
	private List<uint16> mIndices = new .() ~ delete _;
	private List<DrawCommand> mDrawCommands = new .() ~ delete _;

	// Instance data for instanced sprite rendering (also accumulates per
	// frame, reset by BeginFrame).
	private List<DrawingSpriteInstance> mSpriteInstances = new .() ~ delete _;

	// Per-frame ring offsets - reset by BeginFrame, advanced by each
	// Prepare / PrepareInstanced call. Bytes.
	private uint32[] mFrameVertexOffsets;
	private uint32[] mFrameIndexOffsets;
	private uint32[] mFrameInstanceOffsets;
	private uint32[] mFrameUniformSlotCount;

	// Buffer sizes
	private const int32 MAX_VERTICES = 65536;
	private const int32 MAX_INDICES = 65536 * 3;
	private const int32 MAX_SPRITE_INSTANCES = 16384;
	/// Maximum slices per frame across both standard + instanced paths.
	/// Each uniform slot holds one `DrawingUniforms` padded to UNIFORM_SLOT_SIZE
	/// for dynamic-offset alignment. 64 slots × 256 B = 16 KB.
	private const int32 MAX_UNIFORM_SLOTS = 64;
	/// Conservative dynamic-offset alignment (Vulkan minUniformBufferOffsetAlignment
	/// and D3D12 are both typically 256). `sizeof(DrawingUniforms)` is 64.
	private const int32 UNIFORM_SLOT_SIZE = 256;

	public bool IsInitialized { get; private set; }

	/// Initialize the renderer with a shader system.
	/// The shader system should be initialized with the path to shader files.
	public Result<void> Initialize(
		IDevice device,
		TextureFormat targetFormat,
		int32 frameCount,
		ShaderSystem shaderSystem)
	{
		using (SProfiler.Begin("DrawingRenderer.Initialize"))
		{
			mDevice = device;
			mQueue = device.GetQueue(.Graphics);
			mTargetFormat = targetFormat;
			mFrameCount = frameCount;
			mShaderSystem = shaderSystem;

			// Load shaders from files
			if (LoadShaders() case .Err)
				return .Err;

			// Create sampler
			if (CreateSampler() case .Err)
				return .Err;

			// Create bind group layout and pipeline layout
			if (CreateLayouts() case .Err)
				return .Err;

			// Create pipelines (standard and instanced)
			if (CreatePipelines() case .Err)
				return .Err;

			// Create per-frame resources
			if (CreatePerFrameResources() case .Err)
				return .Err;

			// Per-frame ring-offset state.
			mFrameVertexOffsets = new uint32[mFrameCount];
			mFrameIndexOffsets = new uint32[mFrameCount];
			mFrameInstanceOffsets = new uint32[mFrameCount];
			mFrameUniformSlotCount = new uint32[mFrameCount];

			IsInitialized = true;
			return .Ok;
		}
	}

	/// Get or create cached GPU resources for a Drawing.ITexture
	private CachedTexture GetOrCreateCachedTexture(IImageData texture)
	{
		if (texture == null)
			return null;

		// Check cache first
		for (let cached in mTextureCache)
		{
			if (cached.SourceTexture == texture)
			{
				// Check if external texture was updated in shared cache.
				if (cached.IsExternal && mExternalCache != null)
				{
					if (mExternalCache.TryGet(texture, var extEntry))
					{
						if (extEntry.Version != cached.ExternalVersion)
						{
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

		// Create new GPU texture from pixel data
		let pixelData = texture.PixelData;
		if (pixelData.Length == 0)
			return null;

		let width = texture.Width;
		let height = texture.Height;
		let format = TextureFormatUtils.Convert(texture.Format, texture.ColorSpace);

		// Create GPU texture
		TextureDesc textureDesc = TextureDesc.Texture2D(
			width, height, format, TextureUsage.Sampled | TextureUsage.CopyDst,
			label: "DrawingRenderer cached texture"
		);

		Sedulous.RHI.ITexture gpuTexture;
		if (mDevice.CreateTexture(textureDesc) case .Ok(let tex))
			gpuTexture = tex;
		else
			return null;

		// Upload pixel data
		TextureDataLayout dataLayout = .()
		{
			Offset = 0,
			BytesPerRow = width * (uint32)Image.GetBytesPerPixel(texture.Format),
			RowsPerImage = height
		};
		Extent3D writeSize = .(width, height, 1);
		TransferHelper.WriteTextureSync(mQueue, mDevice, gpuTexture, pixelData, dataLayout, writeSize);

		// Create texture view
		TextureViewDesc viewDesc = .() { Format = format };
		ITextureView gpuTextureView;
		if (mDevice.CreateTextureView(gpuTexture, viewDesc) case .Ok(let view))
			gpuTextureView = view;
		else
		{
			mDevice.DestroyTexture(ref gpuTexture);
			return null;
		}

		// Create and cache entry
		let cached = new CachedTexture();
		cached.SourceTexture = texture;
		cached.GpuTexture = gpuTexture;
		cached.GpuTextureView = gpuTextureView;
		cached.BindGroups = new IBindGroup[mFrameCount];
		mTextureCache.Add(cached);

		return cached;
	}

	/// Clear all cached textures
	public void ClearTextureCache()
	{
		for (var cached in mTextureCache)
		{
			cached.Dispose(mDevice, mFrameCount);
			delete cached;
		}
		mTextureCache.Clear();
	}

	/// Set the shared external texture cache. All DrawingRenderers sharing the same
	/// cache will automatically pick up external textures during rendering.
	public void SetExternalCache(DrawingExternalTextureCache cache)
	{
		mExternalCache = cache;
	}

	/// Register an external GPU texture. Updates the local cache for immediate
	/// use by this renderer, and registers with the shared cache so other
	/// renderers can pick it up once marked ready.
	public void RegisterExternalTexture(IImageData imageRef, ITextureView gpuTextureView)
	{
		if (imageRef == null || gpuTextureView == null) return;

		// Register with shared cache (starts as not-ready for other renderers).
		if (mExternalCache != null)
			mExternalCache.Register(imageRef, gpuTextureView);

		// Update local cache directly for immediate use by this renderer.
		for (let cached in mTextureCache)
		{
			if (cached.SourceTexture == imageRef)
			{
				if (!cached.IsExternal)
				{
					if (cached.GpuTextureView != null) { var v = cached.GpuTextureView; mDevice.DestroyTextureView(ref v); cached.GpuTextureView = null; }
					if (cached.GpuTexture != null) { var t = cached.GpuTexture; mDevice.DestroyTexture(ref t); cached.GpuTexture = null; }
				}
				cached.GpuTextureView = gpuTextureView;
				cached.GpuTexture = null;
				cached.IsExternal = true;
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

		let cached = new CachedTexture();
		cached.SourceTexture = imageRef;
		cached.GpuTexture = null;
		cached.GpuTextureView = gpuTextureView;
		cached.BindGroups = new IBindGroup[mFrameCount];
		cached.IsExternal = true;
		mTextureCache.Add(cached);
	}

	/// Unregister an external texture from the shared cache and local cache.
	public void UnregisterExternalTexture(IImageData imageRef)
	{
		if (imageRef == null) return;

		if (mExternalCache != null)
			mExternalCache.Unregister(imageRef);

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
	public void MarkExternalTextureReady(IImageData imageRef)
	{
		if (mExternalCache != null)
			mExternalCache.MarkReady(imageRef);
	}

	/// Reset per-frame ring-offset state for the given frame index.
	/// Call once per frame before the first Prepare / PrepareInstanced for
	/// that frame. Clears CPU scratch (GPU has already consumed last frame's
	/// data).
	public void BeginFrame(int32 frameIndex)
	{
		mFrameVertexOffsets[frameIndex] = 0;
		mFrameIndexOffsets[frameIndex] = 0;
		mFrameInstanceOffsets[frameIndex] = 0;
		mFrameUniformSlotCount[frameIndex] = 0;
		mVertices.Clear();
		mIndices.Clear();
		mDrawCommands.Clear();
		mSpriteInstances.Clear();
		mBatchTextures.Clear();
	}

	/// Upload one batch's vertices, indices, projection uniform, and draw
	/// commands into the shared frame buffers (standard per-vertex path).
	/// Returns a slice token that `Render` consumes to dispatch just this
	/// batch's draws out of the shared state.
	public DrawingRenderSlice Prepare(DrawBatch batch, int32 frameIndex, uint32 width, uint32 height)
	{
		using (SProfiler.Begin("DrawingRenderer.Prepare"))
		{
			let vertCountIn = (uint32)batch.Vertices.Count;
			let idxCountIn = (uint32)batch.Indices.Count;
			if (vertCountIn == 0 || idxCountIn == 0)
				return .Invalid;

			let vertByteSize = vertCountIn * (uint32)sizeof(DrawingRenderVertex);
			let idxByteSize = idxCountIn * (uint32)sizeof(uint16);
			let sliceVertOffset = mFrameVertexOffsets[frameIndex];
			let sliceIdxOffset = mFrameIndexOffsets[frameIndex];
			let sliceUniformSlot = mFrameUniformSlotCount[frameIndex];

			let maxVertBytes = (uint32)(MAX_VERTICES * sizeof(DrawingRenderVertex));
			let maxIdxBytes = (uint32)(MAX_INDICES * sizeof(uint16));
			let endVertOffset = sliceVertOffset + vertByteSize;
			let endIdxOffset = sliceIdxOffset + idxByteSize;
			let vertOverflow = endVertOffset > maxVertBytes;
			let idxOverflow = endIdxOffset > maxIdxBytes;
			let uniformOverflow = sliceUniformSlot >= (uint32)MAX_UNIFORM_SLOTS;
			if (vertOverflow || idxOverflow || uniformOverflow)
			{
				Console.WriteLine("DrawingRenderer: frame capacity exceeded, slice dropped");
				return .Invalid;
			}

			let sliceUniformOffset = sliceUniformSlot * (uint32)UNIFORM_SLOT_SIZE;
			let sliceCmdStart = (int32)mDrawCommands.Count;
			let textureBase = (int32)mBatchTextures.Count;

			// Convert vertices
			for (let v in batch.Vertices)
				mVertices.Add(.(v));

			// Copy indices
			for (let i in batch.Indices)
				mIndices.Add(i);

			// Store batch textures for multi-texture rendering. Cmd
			// TextureIndex is offset so it indexes into the shared
			// mBatchTextures rather than the per-batch list.
			for (let tex in batch.Textures)
				mBatchTextures.Add(tex);

			// Copy draw commands (with TextureIndex remapped).
			for (let cmd in batch.Commands)
			{
				var adjustedCmd = cmd;
				if (cmd.TextureIndex >= 0)
					adjustedCmd.TextureIndex = cmd.TextureIndex + textureBase;
				mDrawCommands.Add(adjustedCmd);
			}

			// Upload to GPU buffers - each slice writes to its own byte
			// offset so multiple slices in a frame don't overwrite each
			// other.
			let vertSliceData = Span<uint8>((uint8*)(&mVertices[(int)(sliceVertOffset / (uint32)sizeof(DrawingRenderVertex))]), (int)vertByteSize);
			TransferHelper.WriteMappedBuffer(mVertexBuffers[frameIndex], (uint64)sliceVertOffset, vertSliceData);

			let idxSliceData = Span<uint8>((uint8*)(&mIndices[(int)(sliceIdxOffset / (uint32)sizeof(uint16))]), (int)idxByteSize);
			TransferHelper.WriteMappedBuffer(mIndexBuffers[frameIndex], (uint64)sliceIdxOffset, idxSliceData);

			// Write this slice's projection into its uniform slot. The
			// uniform binding's dynamic offset (set at Render time) picks
			// the right slot.
			Matrix projection = Matrix.CreateOrthographicOffCenter(0, (float)width, (float)height, 0, -1, 1);
			DrawingUniforms uniforms = .() { Projection = projection };
			let uniformData = Span<uint8>((uint8*)&uniforms, sizeof(DrawingUniforms));
			TransferHelper.WriteMappedBuffer(mUniformBuffers[frameIndex], (uint64)sliceUniformOffset, uniformData);

			// Ensure GPU textures are created and bind groups are ready
			// for any newly-added batch textures.
			for (int32 texIdx = textureBase; texIdx < mBatchTextures.Count; texIdx++)
				UpdateTextureBindGroup(texIdx, frameIndex);

			// Advance ring offsets.
			mFrameVertexOffsets[frameIndex] = endVertOffset;
			mFrameIndexOffsets[frameIndex] = endIdxOffset;
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
	}

	/// Upload one batch of sprite instances + projection into the shared
	/// frame buffers and return a slice for `RenderInstanced`.
	public DrawingInstancedSlice PrepareInstanced(Span<DrawingSpriteInstance> instances, int32 frameIndex, uint32 width, uint32 height)
	{
		using (SProfiler.Begin("DrawingRenderer.PrepareInstanced"))
		{
			let countIn = (uint32)instances.Length;
			if (countIn == 0 || mInstanceBuffers == null)
				return .Invalid;

			let instByteSize = countIn * (uint32)sizeof(DrawingSpriteInstance);
			let sliceInstOffset = mFrameInstanceOffsets[frameIndex];
			let sliceUniformSlot = mFrameUniformSlotCount[frameIndex];

			let maxInstBytes = (uint32)(MAX_SPRITE_INSTANCES * sizeof(DrawingSpriteInstance));
			let endInstOffset = sliceInstOffset + instByteSize;
			let instOverflow = endInstOffset > maxInstBytes;
			let uniformOverflow = sliceUniformSlot >= (uint32)MAX_UNIFORM_SLOTS;
			if (instOverflow || uniformOverflow)
			{
				Console.WriteLine("DrawingRenderer: instanced frame capacity exceeded, slice dropped");
				return .Invalid;
			}

			let sliceUniformOffset = sliceUniformSlot * (uint32)UNIFORM_SLOT_SIZE;
			let cpuStart = (int)mSpriteInstances.Count;

			for (let inst in instances)
				mSpriteInstances.Add(inst);

			let instSliceData = Span<uint8>((uint8*)(&mSpriteInstances[cpuStart]), (int)instByteSize);
			TransferHelper.WriteMappedBuffer(mInstanceBuffers[frameIndex], (uint64)sliceInstOffset, instSliceData);

			Matrix projection = Matrix.CreateOrthographicOffCenter(0, (float)width, (float)height, 0, -1, 1);
			DrawingUniforms uniforms = .() { Projection = projection };
			let uniformData = Span<uint8>((uint8*)&uniforms, sizeof(DrawingUniforms));
			TransferHelper.WriteMappedBuffer(mUniformBuffers[frameIndex], (uint64)sliceUniformOffset, uniformData);

			// Update instanced bind group (only needs to happen once per frame
			// if it doesn't exist yet; bind group references the uniform buffer
			// with dynamic offset).
			UpdateInstancedBindGroup(frameIndex);

			mFrameInstanceOffsets[frameIndex] = endInstOffset;
			mFrameUniformSlotCount[frameIndex] = sliceUniformSlot + 1;

			return .()
			{
				InstanceByteOffset = sliceInstOffset,
				InstanceCount = countIn,
				UniformByteOffset = sliceUniformOffset,
				IsValid = true,
			};
		}
	}

	/// Render standard (per-vertex) content. Vertex / index offsets come
	/// from the slice; the uniform binding's dynamic offset selects the
	/// slice's projection slot.
	public void Render(IRenderPassEncoder renderPass, uint32 width, uint32 height, int32 frameIndex, DrawingRenderSlice slice, bool useMsaa = false)
	{
		using (SProfiler.Begin("DrawingRenderer.Render"))
		{
			if (!slice.IsValid || slice.DrawCommandCount == 0)
				return;

			renderPass.SetViewport(0, 0, width, height, 0, 1);
			renderPass.SetPipeline(useMsaa ? mMsaaPipeline : mPipeline);
			renderPass.SetVertexBuffer(0, mVertexBuffers[frameIndex], (uint64)slice.VertexByteOffset);
			renderPass.SetIndexBuffer(mIndexBuffers[frameIndex], .UInt16, (uint64)slice.IndexByteOffset);

			uint32[1] dynOffsets = .(slice.UniformByteOffset);

			// Track current texture to minimize bind group switches.
			// Use -2 as sentinel to force first bind group set.
			int32 currentTextureIndex = -2;

			// Process each draw command with its own scissor rect.
			let cmdEnd = slice.DrawCommandStart + slice.DrawCommandCount;
			for (int32 i = slice.DrawCommandStart; i < cmdEnd; i++)
			{
				let cmd = mDrawCommands[i];
				if (cmd.IndexCount == 0)
					continue;

				// Switch bind group if texture changed.
				// Note: texIdx of -1 (solid color) maps to texture 0 in GetBindGroupForTexture.
				let texIdx = cmd.TextureIndex;
				if (texIdx != currentTextureIndex)
				{
					let bindGroup = GetBindGroupForTexture(texIdx, frameIndex);
					if (bindGroup != null)
						renderPass.SetBindGroup(0, bindGroup, dynOffsets);
					currentTextureIndex = texIdx;
				}

				// Set scissor rect based on clip mode.
				if (cmd.ClipMode == .Scissor && cmd.ClipRect.Width > 0 && cmd.ClipRect.Height > 0)
				{
					// Conservative scissor rect calculation.
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
					// Empty/invalid clip rect - hide everything (match OpenGL glScissor(0,0,0,0)).
					renderPass.SetScissor(0, 0, 0, 0);
				}
				else
				{
					// No clipping - full viewport.
					renderPass.SetScissor(0, 0, width, height);
				}

				renderPass.DrawIndexed((uint32)cmd.IndexCount, 1, (uint32)cmd.StartIndex, 0, 0);
			}
		}
	}

	/// Render instanced sprites. Reads instance data at the slice's byte
	/// offset; uniform dynamic offset selects the slice's projection.
	public void RenderInstanced(IRenderPassEncoder renderPass, uint32 width, uint32 height, int32 frameIndex, DrawingInstancedSlice slice, bool useMsaa = false)
	{
		using (SProfiler.Begin("DrawingRenderer.RenderInstanced"))
		{
			if (!slice.IsValid || slice.InstanceCount == 0 || mInstancedPipeline == null)
				return;

			renderPass.SetViewport(0, 0, width, height, 0, 1);
			renderPass.SetScissor(0, 0, width, height);
			renderPass.SetPipeline(useMsaa ? mInstancedMsaaPipeline : mInstancedPipeline);

			uint32[1] dynOffsets = .(slice.UniformByteOffset);
			renderPass.SetBindGroup(0, mInstancedBindGroups[frameIndex], dynOffsets);
			renderPass.SetVertexBuffer(0, mInstanceBuffers[frameIndex], (uint64)slice.InstanceByteOffset);

			// Draw 6 vertices per sprite (2 triangles), N instances.
			renderPass.Draw(6, slice.InstanceCount, 0, 0);
		}
	}

	private Result<void> LoadShaders()
	{
		if (mShaderSystem == null)
			return .Err;

		// Load standard shaders (no instancing)
		let standardResult = mShaderSystem.GetShaderPair("drawing", .None);
		if (standardResult case .Ok(let stdShaders))
		{
			mVertShader = stdShaders.vert.Module;
			mFragShader = stdShaders.frag.Module;
		}
		else
		{
			Console.WriteLine("Failed to load standard drawing shaders");
			return .Err;
		}

		// Load instanced shaders
		let instancedResult = mShaderSystem.GetShaderPair("drawing", .Instanced);
		if (instancedResult case .Ok(let instShaders))
		{
			mInstancedVertShader = instShaders.vert.Module;
			mInstancedFragShader = instShaders.frag.Module;
		}
		else
		{
			Console.WriteLine("Failed to load instanced drawing shaders");
			return .Err;
		}

		return .Ok;
	}

	private Result<void> CreateSampler()
	{
		SamplerDesc samplerDesc = .();
		// Default values are already ClampToEdge and Linear

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
		// Dynamic offset lets multiple slices in a frame share one uniform buffer with
		// each slice's projection at a different offset.
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

		// Pipeline layout
		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		PipelineLayoutDesc pipelineLayoutDesc = .(layouts);
		if (mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout))
			mPipelineLayout = pipelineLayout;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreatePipelines()
	{
		// Create standard pipeline
		if (CreateStandardPipeline() case .Err)
			return .Err;

		// Create instanced pipeline
		if (CreateInstancedPipeline() case .Err)
			return .Err;

		return .Ok;
	}

	private Result<void> CreateStandardPipeline()
	{
		// Vertex layout: position (float2), texcoord (float2), color (float4)
		VertexAttribute[3] vertexAttributes = .(
			.(VertexFormat.Float2, 0, 0),   // Position
			.(VertexFormat.Float2, 8, 1),   // TexCoord
			.(VertexFormat.Float4, 16, 2)   // Color
		);
		VertexBufferLayout[1] vertexBuffers = .(
			.((uint64)sizeof(DrawingRenderVertex), vertexAttributes)
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

		// Create standard pipeline
		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipeline))
			mPipeline = pipeline;
		else
			return .Err;

		// Create MSAA pipeline variant
		pipelineDesc.Multisample.Count = mMsaaSampleCount;
		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let msaaPipeline))
			mMsaaPipeline = msaaPipeline;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreateInstancedPipeline()
	{
		if (mInstancedVertShader == null || mInstancedFragShader == null)
			return .Ok;  // Skip if instanced shaders not loaded

		// Instance layout: position (float2), size (float2), uvRect (float4), color (unorm8x4), rotation (float), padding
		VertexAttribute[8] instanceAttributes = .(
			.(VertexFormat.Float2, 0, 0),              // Position
			.(VertexFormat.Float2, 8, 1),              // Size
			.(VertexFormat.Float4, 16, 2),             // UVRect
			.(VertexFormat.UByte4Normalized, 32, 3),   // Color
			.(VertexFormat.Float, 36, 4),              // Rotation
			.(VertexFormat.Float, 40, 5),              // Pad0
			.(VertexFormat.Float, 44, 6),              // Pad1
			.(VertexFormat.Float, 48, 7)               // Pad2
		);
		VertexBufferLayout[1] instanceBuffers = .(
			.((uint64)sizeof(DrawingSpriteInstance), instanceAttributes, .Instance)
		);

		ColorTargetState[1] colorTargets = .(.(mTargetFormat, .AlphaBlend));

		RenderPipelineDesc pipelineDesc = .()
		{
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(mInstancedVertShader, "main"),
				Buffers = instanceBuffers
			},
			Fragment = .()
			{
				Shader = .(mInstancedFragShader, "main"),
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

		// Create instanced pipeline
		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipeline))
			mInstancedPipeline = pipeline;
		else
			return .Err;

		// Create instanced MSAA pipeline variant
		pipelineDesc.Multisample.Count = mMsaaSampleCount;
		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let msaaPipeline))
			mInstancedMsaaPipeline = msaaPipeline;
		else
			return .Err;

		return .Ok;
	}

	private Result<void> CreatePerFrameResources()
	{
		mVertexBuffers = new IBuffer[mFrameCount];
		mIndexBuffers = new IBuffer[mFrameCount];
		mUniformBuffers = new IBuffer[mFrameCount];
		mInstanceBuffers = new IBuffer[mFrameCount];
		mInstancedBindGroups = new IBindGroup[mFrameCount];

		for (int32 i = 0; i < mFrameCount; i++)
		{
			// Vertex buffer (host-visible for fast CPU writes)
			BufferDesc vertexDesc = .()
			{
				Size = (uint64)(MAX_VERTICES * sizeof(DrawingRenderVertex)),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(vertexDesc) case .Ok(let vb))
				mVertexBuffers[i] = vb;
			else
				return .Err;

			// Index buffer (host-visible for fast CPU writes)
			BufferDesc indexDesc = .()
			{
				Size = (uint64)(MAX_INDICES * sizeof(uint16)),
				Usage = .Index,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(indexDesc) case .Ok(let ib))
				mIndexBuffers[i] = ib;
			else
				return .Err;

			// Uniform buffer (host-visible for fast CPU writes)
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

			// Instance buffer for instanced sprites
			BufferDesc instanceDesc = .()
			{
				Size = (uint64)(MAX_SPRITE_INSTANCES * sizeof(DrawingSpriteInstance)),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(instanceDesc) case .Ok(let instBuf))
				mInstanceBuffers[i] = instBuf;
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

		// Get or create cached GPU texture
		let cached = GetOrCreateCachedTexture(texture);
		if (cached == null || cached.GpuTextureView == null)
			return;

		// Skip if bind group already exists for this frame
		if (cached.BindGroups[frameIndex] != null)
			return;

		// Create bind group
		BindGroupEntry[3] bindGroupEntries = .(
			BindGroupEntry.Buffer(mUniformBuffers[frameIndex], 0, (uint64)sizeof(DrawingUniforms)),
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

		// For solid color drawing (index -1), use texture 0 which contains the white pixel
		let effectiveIndex = (textureIndex < 0) ? 0 : textureIndex;
		if (effectiveIndex >= mBatchTextures.Count)
			return null;

		let texture = mBatchTextures[effectiveIndex];
		if (texture == null)
			return null;

		// Find cached texture
		for (let cached in mTextureCache)
		{
			if (cached.SourceTexture == texture)
				return cached.BindGroups[frameIndex];
		}
		return null;
	}

	private void UpdateInstancedBindGroup(int32 frameIndex)
	{
		// Skip if bind group is already valid
		if (mInstancedBindGroups[frameIndex] != null)
			return;

		// For instanced rendering, use the first texture from batch if available
		if (mBatchTextures.Count == 0)
			return;

		let cached = GetOrCreateCachedTexture(mBatchTextures[0]);
		if (cached == null || cached.GpuTextureView == null)
			return;

		BindGroupEntry[3] bindGroupEntries = .(
			BindGroupEntry.Buffer(mUniformBuffers[frameIndex], 0, (uint64)sizeof(DrawingUniforms)),
			BindGroupEntry.Texture(cached.GpuTextureView),
			BindGroupEntry.Sampler(mSampler)
		);
		BindGroupDesc bindGroupDesc = .(mBindGroupLayout, bindGroupEntries);
		if (mDevice.CreateBindGroup(bindGroupDesc) case .Ok(let group))
			mInstancedBindGroups[frameIndex] = group;
	}

	public void Dispose()
	{
		// Texture cache (includes bind groups)
		ClearTextureCache();

		if (mFrameVertexOffsets != null) { delete mFrameVertexOffsets; mFrameVertexOffsets = null; }
		if (mFrameIndexOffsets != null) { delete mFrameIndexOffsets; mFrameIndexOffsets = null; }
		if (mFrameInstanceOffsets != null) { delete mFrameInstanceOffsets; mFrameInstanceOffsets = null; }
		if (mFrameUniformSlotCount != null) { delete mFrameUniformSlotCount; mFrameUniformSlotCount = null; }

		// Per-frame resources
		if (mInstancedBindGroups != null)
		{
			for (var bg in ref mInstancedBindGroups)
				if (bg != null) mDevice.DestroyBindGroup(ref bg);
			delete mInstancedBindGroups;
			mInstancedBindGroups = null;
		}
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
		if (mInstanceBuffers != null)
		{
			for (var buf in ref mInstanceBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mInstanceBuffers;
			mInstanceBuffers = null;
		}

		// Instanced pipeline resources
		if (mInstancedMsaaPipeline != null) mDevice.DestroyRenderPipeline(ref mInstancedMsaaPipeline);
		if (mInstancedPipeline != null) mDevice.DestroyRenderPipeline(ref mInstancedPipeline);

		// Standard pipeline resources
		if (mMsaaPipeline != null) mDevice.DestroyRenderPipeline(ref mMsaaPipeline);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);

		// Sampler
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);

		// Note: Shader modules are owned by the shader system cache, not by us

		IsInitialized = false;
	}
}
