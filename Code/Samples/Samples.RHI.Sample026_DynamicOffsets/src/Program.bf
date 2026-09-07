using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample026_DynamicOffsets;

/// One object's slice of the shared uniform buffer.
///
/// Padded to 256 bytes because that is the alignment a dynamic offset must satisfy on DX12,
/// which is the stricter of the two backends. The padding is what makes the offsets legal,
/// not the data.
[CRepr]
struct ObjectData
{
	public float[4] TintColor;
	public float[4] OffsetScale;
	public float[56] Padding;
}

/// Four quads reading four slices of ONE uniform buffer, over a blend whose factor is a
/// per frame constant.
///
/// Two things at once: a dynamic offset moving the window into the buffer between draws, and
/// a blend constant that is pipeline state changed by a command rather than by rebuilding
/// the pipeline.
class DynamicOffsetSample : SampleApp
{
	private const String cShaderSource = """
		cbuffer ObjectData : register(b0, space0)
		{
		    float4 TintColor;
		    float4 OffsetScale; // xy=offset, zw=scale
		};
		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		};
		struct PSInput
		{
		    float4 Position : SV_POSITION;
		};
		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    float2 pos = input.Position.xy * OffsetScale.zw + OffsetScale.xy;
		    output.Position = float4(pos, input.Position.z, 1.0);
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return TintColor;
		}
		""";

	private const int cObjectCount = 4;
	private const uint32 cObjectStride = 256;

	/// A unit quad, positions only. Everything that differs between the four comes from the
	/// uniform buffer.
	private static float[12] sVertices = .(
		-0.5f, -0.5f, 0.5f,
		 0.5f, -0.5f, 0.5f,
		 0.5f,  0.5f, 0.5f,
		-0.5f,  0.5f, 0.5f);
	private static uint16[6] sIndices = .(0, 1, 2, 0, 2, 3);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mVertexShader = null;
	private IShaderModule mPixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private IBuffer mUniformBuffer = null;
	private IBindGroupLayout mBindGroupLayout = null;
	private IBindGroup mBindGroup = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample026 - Dynamic Offsets & Blend Constants";

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
		if (CreatePipeline() case .Err)
			return .Err;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			return .Err;
		mFence = fence;

		UpdateUniforms();
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

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mVertexBuffer, 0,
			.((uint8*)&sVertices[0], sizeof(float) * sVertices.Count));
		batch.WriteBuffer(mIndexBuffer, 0,
			.((uint8*)&sIndices[0], sizeof(uint16) * sIndices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		var uniformDesc = BufferDesc();
		uniformDesc.Size = (uint64)cObjectCount * cObjectStride;
		uniformDesc.Usage = .Uniform;
		uniformDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniformBuffer)))
			return .Err;
		mUniformBuffer = uniformBuffer;
		return .Ok;
	}

	private Result<void> CreateBindings()
	{
		var entry = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment);
		entry.HasDynamicOffset = true;
		var layoutEntries = BindGroupLayoutEntry[1](entry);
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mBindGroupLayout = layout;

		// Sized to ONE object, not the whole buffer: the offset is what selects which.
		var entries = BindGroupEntry[1](
			BindGroupEntry.BufferEntry(mUniformBuffer, 0, (uint64)sizeof(ObjectData)));
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

		var attributes = VertexAttribute[1](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 12;
		vertexLayout.Attributes = attributes;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		colorTarget.WriteMask = .All;
		// The blend factors name the CONSTANT rather than the source alpha, which is what
		// makes the per frame constant do anything.
		colorTarget.Blend = BlendState()
			{
				Color = .() { SrcFactor = .Constant, DstFactor = .OneMinusConstant,
					Operation = .Add },
				Alpha = .() { SrcFactor = .One, DstFactor = .Zero, Operation = .Add }
			};

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

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mPipeline = pipeline;
		return .Ok;
	}

	/// Writes the four slices ONCE: none of it changes per frame, only the blend constant
	/// does.
	private void UpdateUniforms()
	{
		let mapped = mUniformBuffer.Map();
		if (mapped == null)
			return;

		float[4][4] tints = .(
			.(1.0f, 0.2f, 0.2f, 1.0f),
			.(0.2f, 1.0f, 0.2f, 1.0f),
			.(0.2f, 0.3f, 1.0f, 1.0f),
			.(1.0f, 1.0f, 0.2f, 1.0f));
		float[4][2] positions = .(
			.(-0.45f,  0.45f),
			.( 0.45f,  0.45f),
			.(-0.45f, -0.45f),
			.( 0.45f, -0.45f));

		var objects = scope ObjectData[cObjectCount];
		for (int i < cObjectCount)
		{
			objects[i] = .();
			objects[i].TintColor = tints[i];
			objects[i].OffsetScale[0] = positions[i][0];
			objects[i].OffsetScale[1] = positions[i][1];
			objects[i].OffsetScale[2] = 0.4f;
			objects[i].OffsetScale[3] = 0.4f;
		}
		Internal.MemCpy(mapped, &objects[0], cObjectCount * sizeof(ObjectData));
		mUniformBuffer.Unmap();
	}

	protected override void OnRender()
	{
		if (mFenceValue > 0)
			mFence.Wait(mFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err)
			return;

		mPool.Reset();
		if (!(mPool.CreateEncoder() case .Ok(var encoder)))
			return;

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.08f, 0.08f, 0.12f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// A COMMAND, not pipeline state: the quads pulse without any pipeline being
		// rebuilt, which is the point of a blend constant.
		let pulse = 0.5f + 0.5f * Math.Sin(mTotalTime * 2.0f);
		pass.SetBlendConstant(pulse, pulse, pulse, 1.0f);

		for (uint32 i < cObjectCount)
		{
			uint32 dynamicOffset = i * cObjectStride;
			pass.SetBindGroup(0, mBindGroup, .(&dynamicOffset, 1));
			pass.DrawIndexed(6);
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

	protected override void OnShutdown()
	{
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
		let app = scope DynamicOffsetSample();
		return app.Run(args);
	}
}
