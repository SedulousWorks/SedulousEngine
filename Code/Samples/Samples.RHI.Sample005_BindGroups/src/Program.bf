using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample005_BindGroups;

/// A grid of lit cubes drawn from two bind groups: one shared, one per object.
///
/// The per object set uses a DYNAMIC OFFSET, so sixteen draws share one buffer and one bind
/// group and only the offset changes between them. That is the pattern a real renderer uses
/// for per draw data.
class BindGroupSample : SampleApp
{
	private const String cShaderSource = """
		cbuffer GlobalUBO : register(b0, space0) { row_major float4x4 VP; };
		cbuffer ObjectUBO : register(b0, space1) { row_major float4x4 Model; float4 ObjColor; };
		struct VSInput { float3 Position : TEXCOORD0; float3 Normal : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float3 Normal : NORMAL; float4 Color : COLOR; };
		PSInput VSMain(VSInput i) {
		    PSInput o;
		    float4 wp = mul(float4(i.Position, 1.0), Model);
		    o.Position = mul(wp, VP);
		    o.Normal = mul(i.Normal, (float3x3)Model);
		    o.Color = ObjColor;
		    return o;
		}
		float4 PSMain(PSInput i) : SV_TARGET {
		    float3 ld = normalize(float3(0.5, 1.0, -0.7));
		    float ndotl = max(dot(normalize(i.Normal), ld), 0.0);
		    return float4(i.Color.rgb * (0.2 + 0.8 * ndotl), 1.0);
		}
		""";

	private const int cGrid = 4;
	private const int cObjectCount = cGrid * cGrid;
	/// DX12's constant buffer view alignment, which is the larger of the two backends'
	/// requirements and so the one that works on both.
	private const uint32 cObjectStride = 256;

	/// Twenty four vertices rather than eight: each face needs its own normal, so corners
	/// cannot be shared.
	private static float[144] sCubeVertices = .(
		-0.5f, -0.5f, -0.5f,  0,  0, -1,   0.5f, -0.5f, -0.5f,  0,  0, -1,
		 0.5f,  0.5f, -0.5f,  0,  0, -1,  -0.5f,  0.5f, -0.5f,  0,  0, -1,
		 0.5f, -0.5f,  0.5f,  0,  0,  1,  -0.5f, -0.5f,  0.5f,  0,  0,  1,
		-0.5f,  0.5f,  0.5f,  0,  0,  1,   0.5f,  0.5f,  0.5f,  0,  0,  1,
		-0.5f, -0.5f,  0.5f, -1,  0,  0,  -0.5f, -0.5f, -0.5f, -1,  0,  0,
		-0.5f,  0.5f, -0.5f, -1,  0,  0,  -0.5f,  0.5f,  0.5f, -1,  0,  0,
		 0.5f, -0.5f, -0.5f,  1,  0,  0,   0.5f, -0.5f,  0.5f,  1,  0,  0,
		 0.5f,  0.5f,  0.5f,  1,  0,  0,   0.5f,  0.5f, -0.5f,  1,  0,  0,
		-0.5f,  0.5f, -0.5f,  0,  1,  0,   0.5f,  0.5f, -0.5f,  0,  1,  0,
		 0.5f,  0.5f,  0.5f,  0,  1,  0,  -0.5f,  0.5f,  0.5f,  0,  1,  0,
		-0.5f, -0.5f,  0.5f,  0, -1,  0,   0.5f, -0.5f,  0.5f,  0, -1,  0,
		 0.5f, -0.5f, -0.5f,  0, -1,  0,  -0.5f, -0.5f, -0.5f,  0, -1,  0);

	private static uint16[36] sCubeIndices = .(
		0, 1, 2, 0, 2, 3,       4, 5, 6, 4, 6, 7,
		8, 9, 10, 8, 10, 11,    12, 13, 14, 12, 14, 15,
		16, 17, 18, 16, 18, 19, 20, 21, 22, 20, 22, 23);

	private static float[64] sColors = .(
		1, 0.3f, 0.3f, 1,   0.3f, 1, 0.3f, 1,   0.3f, 0.3f, 1, 1,   1, 1, 0.3f, 1,
		1, 0.3f, 1, 1,     0.3f, 1, 1, 1,     1, 0.6f, 0.2f, 1,   0.6f, 0.2f, 1, 1,
		0.2f, 0.8f, 0.6f, 1, 0.8f, 0.8f, 0.8f, 1, 0.5f, 0.3f, 0.1f, 1, 0.9f, 0.5f, 0.7f, 1,
		0.4f, 0.7f, 0.2f, 1, 0.2f, 0.4f, 0.8f, 1, 0.8f, 0.4f, 0.4f, 1, 0.6f, 0.6f, 0.3f, 1);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mGlobalUniforms = null;
	private IBuffer mObjectUniforms = null;
	private void* mGlobalMapped = null;
	private void* mObjectMapped = null;
	private IBindGroupLayout mGlobalLayout = null;
	private IBindGroupLayout mObjectLayout = null;
	private IBindGroup mGlobalBindGroup = null;
	private IBindGroup mObjectBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;
	private DepthBuffer mDepthBuffer = new DepthBuffer() ~ delete _;

	protected override StringView Title => "Sample005 - Multiple Bind Groups";

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

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sCubeVertices[0], sizeof(float) * sCubeVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sCubeIndices[0], sizeof(uint16) * sCubeIndices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		var globalDesc = BufferDesc();
		globalDesc.Size = 256;
		globalDesc.Usage = .Uniform;
		globalDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(globalDesc) case .Ok(let globalBuffer)))
			return .Err;
		mGlobalUniforms = globalBuffer;
		mGlobalMapped = mGlobalUniforms.Map();

		// One buffer for every object, sliced by the dynamic offset.
		var objectDesc = BufferDesc();
		objectDesc.Size = (uint64)cObjectCount * cObjectStride;
		objectDesc.Usage = .Uniform;
		objectDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(objectDesc) case .Ok(let objectBuffer)))
			return .Err;
		mObjectUniforms = objectBuffer;
		mObjectMapped = mObjectUniforms.Map();
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		// Set 0: what every object shares.
		var globalEntries = BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var globalLayoutDesc = BindGroupLayoutDesc();
		globalLayoutDesc.Entries = globalEntries;
		if (!(mDevice.CreateBindGroupLayout(globalLayoutDesc) case .Ok(let globalLayout)))
			return .Err;
		mGlobalLayout = globalLayout;

		var globalBindings = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mGlobalUniforms, 0, 64));
		var globalGroupDesc = BindGroupDesc();
		globalGroupDesc.Layout = mGlobalLayout;
		globalGroupDesc.Entries = globalBindings;
		if (!(mDevice.CreateBindGroup(globalGroupDesc) case .Ok(let globalBindGroup)))
			return .Err;
		mGlobalBindGroup = globalBindGroup;

		// Set 1: per object, and DYNAMIC, which is what lets one bind group serve every
		// draw with only the offset changing.
		var objectEntry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);
		objectEntry.HasDynamicOffset = true;
		var objectEntries = BindGroupLayoutEntry[1](objectEntry);
		var objectLayoutDesc = BindGroupLayoutDesc();
		objectLayoutDesc.Entries = objectEntries;
		if (!(mDevice.CreateBindGroupLayout(objectLayoutDesc) case .Ok(let objectLayout)))
			return .Err;
		mObjectLayout = objectLayout;

		// The size is ONE slice, not the whole buffer: the offset picks which slice.
		var objectBindings = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mObjectUniforms, 0, cObjectStride));
		var objectGroupDesc = BindGroupDesc();
		objectGroupDesc.Layout = mObjectLayout;
		objectGroupDesc.Entries = objectBindings;
		if (!(mDevice.CreateBindGroup(objectGroupDesc) case .Ok(let objectBindGroup)))
			return .Err;
		mObjectBindGroup = objectBindGroup;
		return .Ok;
	}

	private Result<void> CreatePipeline()
	{
		var layouts = IBindGroupLayout[2](mGlobalLayout, mObjectLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
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
		colorAttachment.ClearValue = .(0.08f, 0.08f, 0.12f, 1.0f);

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
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		// Bound ONCE: it does not change between objects, which is the whole reason the
		// shared data is its own set.
		pass.SetBindGroup(0, mGlobalBindGroup);

		for (int i < cObjectCount)
		{
			uint32 dynamicOffset = (uint32)i * cObjectStride;
			pass.SetBindGroup(1, mObjectBindGroup, .(&dynamicOffset, 1));
			pass.DrawIndexed(36);
		}
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
		let cameraAngle = mTotalTime * 0.3f;
		let cameraDistance = 8.0f;
		var view = Float4x4.LookAtRH(
			.(Math.Sin(cameraAngle) * cameraDistance, 5.0f,
				-Math.Cos(cameraAngle) * cameraDistance),
			.(0, 0, 0), .(0, 1, 0));
		var projection = Float4x4.PerspectiveFovRH(Math.DegreesToRadians(45.0f), aspect,
			0.1f, 100.0f);
		var viewProjection = view * projection;
		Internal.MemCpy(mGlobalMapped, viewProjection.Data, 64);

		let spacing = 2.0f;
		let half = (cGrid - 1) * spacing * 0.5f;
		for (int row < cGrid)
		{
			for (int column < cGrid)
			{
				let index = row * cGrid + column;
				// Each spins at its own rate, so a per object buffer that failed to
				// advance would show as a frozen cube rather than a frozen grid.
				var model = Float4x4.RotationY(mTotalTime * (0.5f + index * 0.1f));
				// Row vector convention puts the translation in the last ROW.
				model.M[3][0] = column * spacing - half;
				model.M[3][1] = 0;
				model.M[3][2] = row * spacing - half;

				let destination = (uint8*)mObjectMapped + index * cObjectStride;
				Internal.MemCpy(destination, model.Data, 64);
				Internal.MemCpy(destination + 64, &sColors[index * 4], 16);
			}
		}
	}

	protected override void OnShutdown()
	{
		mDepthBuffer.Destroy(mDevice);
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mObjectBindGroup != null) mDevice.DestroyBindGroup(ref mObjectBindGroup);
		if (mGlobalBindGroup != null) mDevice.DestroyBindGroup(ref mGlobalBindGroup);
		if (mObjectLayout != null) mDevice.DestroyBindGroupLayout(ref mObjectLayout);
		if (mGlobalLayout != null) mDevice.DestroyBindGroupLayout(ref mGlobalLayout);
		if (mObjectUniforms != null) mDevice.DestroyBuffer(ref mObjectUniforms);
		if (mGlobalUniforms != null) mDevice.DestroyBuffer(ref mGlobalUniforms);
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
		let app = scope BindGroupSample();
		return app.Run(args);
	}
}
