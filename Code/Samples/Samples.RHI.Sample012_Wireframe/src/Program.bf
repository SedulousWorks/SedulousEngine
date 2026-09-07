using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample012_Wireframe;

/// An icosahedron drawn as wireframe.
///
/// Wireframe is a FILL MODE on the pipeline rather than different geometry, and it is an
/// optional device feature: a backend without it silently draws solid, which is why the
/// shape is one with obvious internal edges.
class WireframeSample : SampleApp
{
	private const String cShaderSource = """
		cbuffer UBO : register(b0, space0) { row_major float4x4 MVP; };
		struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = mul(float4(i.Position,1), MVP); o.Color = i.Color; return o; }
		float4 PSMain(PSInput i) : SV_TARGET { return i.Color; }
		""";

	/// Twelve triangles' worth of shared corners.
	private const uint32 cIndexCount = 60;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mUniformBuffer = null;
	private void* mUniformMapped = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private DepthBuffer mDepthBuffer = new DepthBuffer() ~ delete _;

	protected override StringView Title => "Sample012 - Wireframe";

	/// Wireframe is not universal, so the device is asked for it explicitly. A device
	/// without it refuses here rather than quietly drawing solid.
	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.FillModeWireframe = true;
			return features;
		}
	}

	protected override void OnResize(uint32 width, uint32 height)
	{
		mDepthBuffer.Recreate(mDevice, width, height).IgnoreError();
	}

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Vertex,
			"VSMain", "VS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "PS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateGeometry() case .Err)
			return .Err;
		if (CreateBindings() case .Err)
			return .Err;

		mDepthBuffer.Recreate(mDevice, mWidth, mHeight).IgnoreError();

		if (CreatePipeline() case .Err)
			return .Err;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			return .Err;
		mFence = fence;
		return .Ok;
	}

	private Result<void> CreateGeometry()
	{
		// The twelve corners sit on three orthogonal golden rectangles, which is what makes
		// every edge the same length.
		let t = (1.0f + Math.Sqrt(5.0f)) / 2.0f;
		let s = 1.0f / Math.Sqrt(1.0f + t * t);
		let a = s;
		let b = t * s;

		float[84] vertices = .(
			-a,  b,  0.0f,   1.0f, 0.3f, 0.3f, 1.0f,
			 a,  b,  0.0f,   0.3f, 1.0f, 0.3f, 1.0f,
			-a, -b,  0.0f,   0.3f, 0.3f, 1.0f, 1.0f,
			 a, -b,  0.0f,   1.0f, 1.0f, 0.3f, 1.0f,
			 0.0f, -a,  b,   1.0f, 0.3f, 1.0f, 1.0f,
			 0.0f,  a,  b,   0.3f, 1.0f, 1.0f, 1.0f,
			 0.0f, -a, -b,   1.0f, 0.6f, 0.3f, 1.0f,
			 0.0f,  a, -b,   0.6f, 0.3f, 1.0f, 1.0f,
			 b,  0.0f, -a,   0.3f, 1.0f, 0.6f, 1.0f,
			 b,  0.0f,  a,   1.0f, 0.6f, 0.6f, 1.0f,
			-b,  0.0f, -a,   0.6f, 1.0f, 0.3f, 1.0f,
			-b,  0.0f,  a,   0.6f, 0.3f, 0.6f, 1.0f);

		uint16[60] indices = .(
			0, 11, 5,   0, 5, 1,    0, 1, 7,    0, 7, 10,   0, 10, 11,
			1, 5, 9,    5, 11, 4,   11, 10, 2,  10, 7, 6,   7, 1, 8,
			3, 9, 4,    3, 4, 2,    3, 2, 6,    3, 6, 8,    3, 8, 9,
			4, 9, 5,    2, 4, 11,   6, 2, 10,   8, 6, 7,    9, 8, 1);

		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * vertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * indices.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&vertices[0], sizeof(float) * vertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&indices[0], sizeof(uint16) * indices.Count));
		// BLOCKING, which matters here: the arrays are on the stack and go out of scope
		// the moment this returns.
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		var uniformDesc = BufferDesc();
		uniformDesc.Size = 256;
		uniformDesc.Usage = .Uniform;
		uniformDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniformBuffer)))
			return .Err;
		mUniformBuffer = uniformBuffer;
		mUniformMapped = mUniformBuffer.Map();

		var layoutEntries = BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mBindGroupLayout = layout;

		var entries = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mUniformBuffer, 0, 64));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mBindGroupLayout;
		groupDesc.Entries = entries;
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mBindGroup = bindGroup;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		var layouts = IBindGroupLayout[1](mBindGroupLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x4, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 28;
		vertexLayout.Attributes = attributes;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;

		var buffers = VertexBufferLayout[1](vertexLayout);
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(mVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
		var fragment = FragmentState();
		fragment.Shader = .(mPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;

		// Wireframe, and NO culling: the far side's edges are half the point of a
		// wireframe, so culling them would hide it.
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.FrontFace = .CCW;
		desc.Primitive.CullMode = .None;
		desc.Primitive.FillMode = .Wireframe;

		// Depth is TESTED but not written: with no culling the edges overlap constantly,
		// and writing depth would let a near edge erase a far one that shares a pixel.
		var depthStencil = DepthStencilState();
		depthStencil.Format = .Depth24PlusStencil8;
		depthStencil.DepthCompare = .LessEqual;
		depthStencil.DepthWriteEnabled = false;
		desc.DepthStencil = depthStencil;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		UpdateUniforms();

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mDepthBuffer.Texture, .Undefined, .DepthStencilWrite);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthBuffer.View;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetBindGroup(0, mBindGroup);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed(cIndexCount);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	private void UpdateUniforms()
	{
		let aspect = (float)mWidth / (float)mHeight;
		var model = Float4x4.RotationY(mTotalTime * 0.8f);

		// The view is written out rather than built from LookAt, to show what it is: the
		// INVERSE of the camera's transform, so a camera three units along +Z becomes a
		// translation of -3. A right handed projection needs geometry at negative view z.
		var view = Float4x4.Identity();
		view.M[3][2] = -3.0f;

		var projection = Float4x4.PerspectiveFovRH(Math.DegreesToRadians(45.0f), aspect,
			0.1f, 100.0f);
		var mvp = model * view * projection;
		Internal.MemCpy(mUniformMapped, mvp.Data, 64);
	}

	protected override void OnShutdown()
	{
		mDepthBuffer.Destroy(mDevice);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null) mDevice.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mUniformBuffer != null) mDevice.DestroyBuffer(ref mUniformBuffer);
		if (mIndexBuffer != null) mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null) mDevice.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice.DestroyShaderModule(ref mVertexShader);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope WireframeSample();
		return app.Run(args);
	}
}
