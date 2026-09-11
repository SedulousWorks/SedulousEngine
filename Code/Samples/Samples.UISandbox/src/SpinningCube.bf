using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Samples.UISandbox;

/// A cube drawn through RAW RHI into a viewport's offscreen targets.
///
/// It is here to exercise one contract and nothing else: a UI panel hands out a colour and a
/// depth target and an encoder, and something outside the UI draws into them. A real renderer
/// would slot in exactly where this does.
class SpinningCube
{
	private const String cShaderSource = """
		#pragma pack_matrix(row_major)
		cbuffer Uniforms : register(b0) { float4x4 MVP; };
		struct VSIn { float3 Position : TEXCOORD0; float3 Color : TEXCOORD1; };
		struct PSIn { float4 Position : SV_POSITION; float3 Color : COLOR0; };
		PSIn VSMain(VSIn i) { PSIn o; o.Position = mul(float4(i.Position, 1.0), MVP); o.Color = i.Color; return o; }
		float4 PSMain(PSIn i) : SV_TARGET { return float4(i.Color, 1.0); }
		""";

	/// Eight corners, each its own colour, so every face reads differently as it turns.
	/// Position then colour, six floats a row.
	private static float[48] sVertices = .(
		-1, -1, -1,  0, 0, 0,
		 1, -1, -1,  1, 0, 0,
		 1,  1, -1,  1, 1, 0,
		-1,  1, -1,  0, 1, 0,
		-1, -1,  1,  0, 0, 1,
		 1, -1,  1,  1, 0, 1,
		 1,  1,  1,  1, 1, 1,
		-1,  1,  1,  0, 1, 1);

	private static uint16[36] sIndices = .(
		0, 1, 2, 0, 2, 3,
		4, 6, 5, 4, 7, 6,
		0, 4, 5, 0, 5, 1,
		3, 2, 6, 3, 6, 7,
		0, 3, 7, 0, 7, 4,
		1, 5, 6, 1, 6, 2);

	private const int cUniformSize = sizeof(Float4x4);

	/// BORROWED: the graphics device outlives this.
	private IDevice mDevice = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;

	/// ONE PER FRAME IN FLIGHT. Frame N plus one's write would otherwise clobber what frame N
	/// is still reading on the GPU.
	private List<IBuffer> mUniforms = new .() ~ delete _;
	private List<IBindGroup> mBindGroups = new .() ~ delete _;

	public bool IsReady => mPipeline != null;

	/// The formats come from the VIEWPORT, which owns the targets, so the pipeline and the
	/// attachments cannot disagree.
	public Result<void> Init(IDevice device, ShaderCompiler compiler, int32 frameCount,
		TextureFormat colorFormat, TextureFormat depthFormat)
	{
		mDevice = device;

		if (CompileShaders(compiler) case .Err)
			return .Err;

		if (CreateBuffers() case .Err)
			return .Err;

		if (CreateBindings(frameCount) case .Err)
			return .Err;

		return CreatePipeline(colorFormat, depthFormat);
	}

	private Result<void> CompileShaders(ShaderCompiler compiler)
	{
		if (!(Samples.Framework.ShaderHelpers.CompileToModule(compiler, mDevice, cShaderSource,
			.Vertex, "VSMain", "CubeVS") case .Ok(let vertexShader)))
			return .Err;

		mVertexShader = vertexShader;

		if (!(Samples.Framework.ShaderHelpers.CompileToModule(compiler, mDevice, cShaderSource,
			.Fragment, "PSMain", "CubePS") case .Ok(let pixelShader)))
			return .Err;

		mPixelShader = pixelShader;
		return .Ok;
	}

	private Result<void> CreateBuffers()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;

		mVertexBuffer = vertexBuffer;

		var indexDesc = BufferDesc();
		indexDesc.Size = sizeof(uint16) * sIndices.Count;
		indexDesc.Usage = .Index | .CopyDst;
		indexDesc.Memory = .GpuOnly;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
			return .Err;

		mIndexBuffer = indexBuffer;

		let queue = mDevice.GetQueue(.Graphics, 0);
		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;

		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertices[0], sizeof(float) * sVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sIndices[0], sizeof(uint16) * sIndices.Count));
		batch.Submit().IgnoreError();
		queue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	private Result<void> CreateBindings(int32 frameCount)
	{
		var layoutEntries = BindGroupLayoutEntry[1](BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let bindGroupLayout)))
			return .Err;

		mBindGroupLayout = bindGroupLayout;

		var layouts = IBindGroupLayout[1](mBindGroupLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;

		mPipelineLayout = pipelineLayout;

		for (int32 i < frameCount)
		{
			var uniformDesc = BufferDesc();
			uniformDesc.Size = cUniformSize;
			uniformDesc.Usage = .Uniform;
			uniformDesc.Memory = .CpuToGpu;
			if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniform)))
				return .Err;

			mUniforms.Add(uniform);

			var entries = BindGroupEntry[1](BindGroupEntry.BufferEntry(uniform, 0, cUniformSize));
			var groupDesc = BindGroupDesc();
			groupDesc.Layout = mBindGroupLayout;
			groupDesc.Entries = entries;
			if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
				return .Err;

			mBindGroups.Add(bindGroup);
		}

		return .Ok;
	}

	private Result<void> CreatePipeline(TextureFormat colorFormat, TextureFormat depthFormat)
	{
		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x3, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 24;
		vertexLayout.Attributes = attributes;

		var colorTarget = ColorTargetState();
		colorTarget.Format = colorFormat;

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

		var depthStencil = DepthStencilState();
		depthStencil.Format = depthFormat;
		depthStencil.DepthWriteEnabled = true;
		depthStencil.DepthCompare = .Less;
		desc.DepthStencil = depthStencil;

		// No culling, because the winding is not worth getting right for a demo cube and a
		// wrong-facing triangle would simply vanish.
		desc.Primitive.CullMode = .None;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;

		mPipeline = pipeline;
		return .Ok;
	}

	/// Records the cube into the targets the viewport already transitioned for us.
	public void Render(ICommandEncoder encoder, ITextureView colorView, ITextureView depthView,
		uint32 width, uint32 height, ClearColor clear, Float4x4 mvp, int32 frameIndex)
	{
		if ((mPipeline == null) || (frameIndex < 0) || (frameIndex >= mUniforms.Count))
			return;

		var matrix = mvp;
		let mapped = (uint8*)mUniforms[frameIndex].Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, &matrix, cUniformSize);
			mUniforms[frameIndex].Unmap();
		}

		var colorAttachment = ColorAttachment();
		colorAttachment.View = colorView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = clear;

		var depthAttachment = DepthStencilAttachment();
		depthAttachment.View = depthView;
		depthAttachment.DepthLoadOp = .Clear;
		depthAttachment.DepthStoreOp = .Store;
		depthAttachment.DepthClearValue = 1.0f;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.DepthStencilAttachment = depthAttachment;

		let pass = encoder.BeginRenderPass(passDesc);
		if (pass == null)
			return;

		pass.SetViewport(0, 0, (float)width, (float)height, 0, 1);
		pass.SetScissor(0, 0, width, height);
		pass.SetPipeline(mPipeline);
		pass.SetBindGroup(0, mBindGroups[frameIndex]);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed((uint32)sIndices.Count);
		pass.End();
	}

	/// Released while the device is still alive, which is why this is not a destructor.
	public void Shutdown()
	{
		if (mDevice == null)
			return;

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);

		for (var bindGroup in ref mBindGroups)
			mDevice.DestroyBindGroup(ref bindGroup);

		mBindGroups.Clear();

		for (var uniform in ref mUniforms)
			mDevice.DestroyBuffer(ref uniform);

		mUniforms.Clear();

		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mIndexBuffer != null) mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mPixelShader != null) mDevice.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice.DestroyShaderModule(ref mVertexShader);

		mDevice = null;
	}
}
