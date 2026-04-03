namespace Sedulous.VG.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.VG;
using Sedulous.Core.Mathematics;

/// Uniform buffer data for projection matrix.
[CRepr]
struct VGUniforms
{
	public Matrix Projection;
}

/// Renders VGContext/VGBatch content using RHI.
/// Creates GPU vertex/index buffers, uploads per-frame, and renders with alpha blending.
/// Does NOT own the device or swapchain — caller manages those.
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
	private IBindGroup[] mBindGroups;

	// White pixel texture for solid color rendering
	private ITexture mWhiteTexture;
	private ITextureView mWhiteTextureView;
	private ISampler mSampler;

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

		if (CreateWhiteTexture() case .Err)
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

		// Upload to GPU buffers
		if (mVertices.Count > 0)
		{
			let vertexData = Span<uint8>((uint8*)mVertices.Ptr, mVertices.Count * sizeof(VGRenderVertex));
			TransferHelper.WriteMappedBuffer(mVertexBuffers[frameIndex], 0, vertexData);

			let indexData = Span<uint8>((uint8*)mIndices.Ptr, mIndices.Count * sizeof(uint32));
			TransferHelper.WriteMappedBuffer(mIndexBuffers[frameIndex], 0, indexData);
		}
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
		renderPass.SetBindGroup(0, mBindGroups[frameIndex]);

		for (let cmd in mDrawCommands)
		{
			if (cmd.IndexCount == 0)
				continue;

			// Set scissor rect based on clip mode
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

	private Result<void> CreateWhiteTexture()
	{
		// 1x1 white pixel texture for solid color rendering
		TextureDesc texDesc = TextureDesc.Texture2D(1, 1, .RGBA8Unorm, .Sampled | .CopyDst);
		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
			mWhiteTexture = tex;
		else
			return .Err;

		uint8[4] whitePixel = .(255, 255, 255, 255);
		TextureDataLayout layout = .() { BytesPerRow = 4, RowsPerImage = 1 };
		Extent3D size = .(1, 1, 1);
		TransferHelper.WriteTextureSync(mQueue, mDevice, mWhiteTexture, Span<uint8>(&whitePixel[0], 4), layout, size);

		TextureViewDesc viewDesc = .() { Format = .RGBA8Unorm };
		if (mDevice.CreateTextureView(mWhiteTexture, viewDesc) case .Ok(let view))
			mWhiteTextureView = view;
		else
			return .Err;

		return .Ok;
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
		mBindGroups = new IBindGroup[mFrameCount];

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

			// Bind group (uses white texture)
			BindGroupEntry[3] bindGroupEntries = .(
				BindGroupEntry.Buffer(mUniformBuffers[i], 0, (uint64)sizeof(VGUniforms)),
				BindGroupEntry.Texture(mWhiteTextureView),
				BindGroupEntry.Sampler(mSampler)
			);
			BindGroupDesc bindGroupDesc = .(mBindGroupLayout, bindGroupEntries);
			if (mDevice.CreateBindGroup(bindGroupDesc) case .Ok(let group))
				mBindGroups[i] = group;
			else
				return .Err;
		}

		return .Ok;
	}

	public void Dispose()
	{
		if (mBindGroups != null)
		{
			for (var bg in ref mBindGroups)
				if (bg != null) mDevice.DestroyBindGroup(ref bg);
			delete mBindGroups;
			mBindGroups = null;
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

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mWhiteTextureView != null) mDevice.DestroyTextureView(ref mWhiteTextureView);
		if (mWhiteTexture != null) mDevice.DestroyTexture(ref mWhiteTexture);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);

		IsInitialized = false;
	}
}
