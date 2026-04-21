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

	// Batch data converted for GPU
	private List<VGRenderVertex> mVertices = new .() ~ delete _;
	private List<uint32> mIndices = new .() ~ delete _;
	private List<VGCommand> mDrawCommands = new .() ~ delete _;

	// Buffer sizes
	private const int32 MAX_VERTICES = 131072;
	private const int32 MAX_INDICES = 131072 * 3;

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
							// Texture changed — update view and invalidate bind groups.
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
		let format = TextureFormatUtils.Convert(texture.Format);

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

		// Not in local cache — create new entry.
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

	/// Prepare batch data for rendering.
	/// Call this after drawing to VGContext and before the render pass.
	public void Prepare(VGBatch batch, int32 frameIndex)
	{
		// Convert vertices
		mVertices.Clear();
		for (let v in batch.Vertices)
			mVertices.Add(.(v));

		// Copy indices
		mIndices.Clear();
		for (let i in batch.Indices)
			mIndices.Add(i);

		// Copy draw commands
		mDrawCommands.Clear();
		for (let cmd in batch.Commands)
			mDrawCommands.Add(cmd);

		// Store batch textures for multi-texture rendering
		mBatchTextures.Clear();
		for (let tex in batch.Textures)
			mBatchTextures.Add(tex);

		// Upload to GPU buffers
		if (mVertices.Count > 0)
		{
			let vertexData = Span<uint8>((uint8*)mVertices.Ptr, mVertices.Count * sizeof(VGRenderVertex));
			TransferHelper.WriteMappedBuffer(mVertexBuffers[frameIndex], 0, vertexData);

			let indexData = Span<uint8>((uint8*)mIndices.Ptr, mIndices.Count * sizeof(uint32));
			TransferHelper.WriteMappedBuffer(mIndexBuffers[frameIndex], 0, indexData);
		}

		// Ensure GPU textures and bind groups exist for each batch texture
		for (int32 texIdx = 0; texIdx < mBatchTextures.Count; texIdx++)
			UpdateTextureBindGroup(texIdx, frameIndex);
	}

	/// Update the projection matrix for the given viewport size.
	public void UpdateProjection(uint32 width, uint32 height, int32 frameIndex)
	{
		Matrix projection = Matrix.CreateOrthographicOffCenter(0, (float)width, (float)height, 0, -1, 1);

		VGUniforms uniforms = .() { Projection = projection };
		let uniformData = Span<uint8>((uint8*)&uniforms, sizeof(VGUniforms));
		TransferHelper.WriteMappedBuffer(mUniformBuffers[frameIndex], 0, uniformData);
	}

	/// Render VG content to the current render pass.
	public void Render(IRenderPassEncoder renderPass, uint32 width, uint32 height, int32 frameIndex)
	{
		if (mIndices.Count == 0 || mDrawCommands.Count == 0)
			return;

		renderPass.SetViewport(0, 0, width, height, 0, 1);
		renderPass.SetPipeline(mPipeline);
		renderPass.SetVertexBuffer(0, mVertexBuffers[frameIndex], 0);
		renderPass.SetIndexBuffer(mIndexBuffers[frameIndex], .UInt32, 0);

		// Track current texture to minimize bind group switches.
		// Use -2 as sentinel to force first bind group set.
		int32 currentTextureIndex = -2;

		for (let cmd in mDrawCommands)
		{
			if (cmd.IndexCount == 0)
				continue;

			let texIdx = cmd.TextureIndex;
			if (texIdx != currentTextureIndex)
			{
				let bindGroup = GetBindGroupForTexture(texIdx, frameIndex);
				if (bindGroup != null)
					renderPass.SetBindGroup(0, bindGroup);
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
		// Bind group layout: uniform buffer (b0), texture (t0), sampler (s0)
		BindGroupLayoutEntry[3] layoutEntries = .(
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
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

			// Uniform buffer
			BufferDesc uniformDesc = .()
			{
				Size = (uint64)sizeof(VGUniforms),
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
