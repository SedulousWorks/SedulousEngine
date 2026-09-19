using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample003_UniformBuffers;

/// A rotating cube: a uniform buffer for the matrix, push constants for a tint, and a depth
/// buffer so the far faces do not draw over the near ones.
class UniformBufferSample : SampleApp
{
	private const String cShaderSource = """
		cbuffer UBO : register(b0, space0) { row_major float4x4 MVP; };
		struct PushData { float4 Tint; };
		[[vk::push_constant]] ConstantBuffer<PushData> gPush : register(b0, space1);
		struct VSInput { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float3 Color : COLOR0; };
		PSInput VSMain(VSInput input) {
		    PSInput o; o.Position = mul(float4(input.Position, 1.0), MVP); o.Color = input.Color; return o;
		}
		float4 PSMain(PSInput input) : SV_TARGET { return float4(input.Color * gPush.Tint.rgb, 1.0); }
		""";

	/// Eight corners, each with its own colour so the faces are distinguishable.
	private static float[48] sCubeVertices = .(
		-0.5f, -0.5f, -0.5f,  1, 0, 0,
		 0.5f, -0.5f, -0.5f,  0, 1, 0,
		 0.5f,  0.5f, -0.5f,  0, 0, 1,
		-0.5f,  0.5f, -0.5f,  1, 1, 0,
		-0.5f, -0.5f,  0.5f,  1, 0, 1,
		 0.5f, -0.5f,  0.5f,  0, 1, 1,
		 0.5f,  0.5f,  0.5f,  1, 1, 1,
		-0.5f,  0.5f,  0.5f,  0.5f, 0.5f, 0.5f);

	private static uint16[36] sCubeIndices = .(
		0, 2, 1, 0, 3, 2,
		4, 5, 6, 4, 6, 7,
		4, 7, 3, 4, 3, 0,
		1, 2, 6, 1, 6, 5,
		3, 7, 6, 3, 6, 2,
		4, 0, 1, 4, 1, 5);

	/// One 4x4 of floats.
	private const uint64 cUniformSize = 64;

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mUniformBuffer = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private void* mUniformMapped = null;
	private DepthBuffer mDepthBuffer = new DepthBuffer() ~ delete _;

	protected override StringView Title => "Sample003 - Rotating Cube (Uniform Buffers)";

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
			"VSMain", "CubeVS") case .Ok(let vertexShader)))
			return .Err;
		mVertexShader = vertexShader;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShaderSource, .Fragment,
			"PSMain", "CubePS") case .Ok(let pixelShader)))
			return .Err;
		mPixelShader = pixelShader;

		if (CreateBuffers() case .Err)
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

	private Result<void> CreateBuffers()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sCubeVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * sCubeIndices.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;
		mIndexBuffer = indexBuffer;

		// CpuToGpu and PERSISTENTLY mapped: the matrix changes every frame, so a staging
		// copy per frame would cost more than the slower memory does.
		var uniformDesc = BufferDesc();
		uniformDesc.Size = cUniformSize;
		uniformDesc.Usage = .Uniform;
		uniformDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniformBuffer)))
			return .Err;
		mUniformBuffer = uniformBuffer;
		mUniformMapped = mUniformBuffer.Map();

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sCubeVertices[0], sizeof(float) * sCubeVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sCubeIndices[0], sizeof(uint16) * sCubeIndices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		var layoutEntries = BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let bindGroupLayout)))
			return .Err;
		mBindGroupLayout = bindGroupLayout;

		var entries = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mUniformBuffer, 0, cUniformSize));
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
		// Sixteen bytes for the tint, which is small enough to travel with the command
		// rather than through a buffer.
		var pushConstants = PushConstantRange[1](
			.() { Stages = .Vertex | .Fragment, Offset = 0, Size = 16 });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x3, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 24;
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
		// Clockwise front faces with back face culling, which is what the index winding
		// above describes.
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.FrontFace = .CW;
		desc.Primitive.CullMode = .Back;
		var depthStencil = DepthStencilState();
		depthStencil.Format = .Depth24PlusStencil8;
		depthStencil.DepthCompare = Depth.Nearer;
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
		colorAttachment.ClearValue = .(0.1f, 0.1f, 0.15f, 1.0f);

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = mDepthBuffer.View;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = Depth.ClearValue;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetBindGroup(0, mBindGroup);

		let pulse = Math.Sin(mTotalTime * 2.0f) * 0.3f + 0.7f;
		float[4] tint = .(pulse, pulse, pulse, 1.0f);
		pass.SetPushConstants(.Vertex | .Fragment, 0, 16, &tint[0]);

		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed(36);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	/// Writes this frame's matrix straight into the mapped buffer.
	///
	/// Row vector convention throughout, so the model, view and projection multiply in that
	/// order and the shader declares the matrix row_major.
	private void UpdateUniforms()
	{
		let aspect = (float)mWidth / (float)mHeight;
		let angle = mTotalTime * 1.2f;

		var model = Float4x4.RotationY(angle) * Float4x4.RotationX(angle * 0.7f);
		var view = Float4x4.LookAtRH(.(0, 1.5f, -3), .(0, 0, 0), .(0, 1, 0));
		var projection = Float4x4.PerspectiveFovRH(Math.DegreesToRadians(45.0f), aspect,
			0.1f, 100.0f);
		var mvp = model * view * projection;

		Internal.MemCpy(mUniformMapped, mvp.Data, (int)cUniformSize);
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
		let app = scope UniformBufferSample();
		return app.Run(args);
	}
}
