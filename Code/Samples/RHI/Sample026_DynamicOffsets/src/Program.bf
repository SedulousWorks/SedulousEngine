namespace Sample026_DynamicOffsets;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

/// Demonstrates dynamic uniform buffer offsets and blend constants.
/// Draws 4 quads, each reading from a different offset in one shared UBO.
/// Uses SetBlendConstant with BlendFactor.Constant for per-frame color modulation.
class DynamicOffsetSample : SampleApp
{
	const String cShaderSource = """
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

	[CRepr]
	struct ObjectData
	{
		public float[4] TintColor;
		public float[4] OffsetScale;
		// Pad to 256-byte alignment (D3D12 CBV minimum)
		public float[56] _pad;
	}

	private ShaderCompiler mShaderCompiler;
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private IShaderModule mVertexShader;
	private IShaderModule mPixelShader;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;
	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample026 — Dynamic Offsets & Blend Constants";

	protected override Result<void> OnInit()
	{
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err) return .Err;

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let vsBytecode = scope List<uint8>();
		let psBytecode = scope List<uint8>();
		let errors = scope String();

		if (mShaderCompiler.CompileVertex(cShaderSource, "VSMain", format, vsBytecode, errors) case .Err)
		{ Console.WriteLine("VS: {}", errors); return .Err; }
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{ Console.WriteLine("PS: {}", errors); return .Err; }

		let vsR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(vsBytecode.Ptr, vsBytecode.Count), Label = "DynVS" });
		if (vsR case .Err) return .Err;
		mVertexShader = vsR.Value;
		let psR = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "DynPS" });
		if (psR case .Err) return .Err;
		mPixelShader = psR.Value;

		// Unit quad vertices (will be transformed by UBO data)
		float[?] verts = .(
			-0.5f, -0.5f, 0.5f,
			 0.5f, -0.5f, 0.5f,
			 0.5f,  0.5f, 0.5f,
			-0.5f,  0.5f, 0.5f
		);
		uint16[6] indices = .(0, 1, 2, 0, 2, 3);

		uint32 vbSize = sizeof(decltype(verts));
		uint32 ibSize = sizeof(decltype(indices));

		let vbR = mDevice.CreateBuffer(BufferDesc() { Size = vbSize, Usage = .Vertex | .CopyDst, Memory = .GpuOnly, Label = "DynVB" });
		if (vbR case .Err) return .Err;
		mVertexBuffer = vbR.Value;
		let ibR = mDevice.CreateBuffer(BufferDesc() { Size = ibSize, Usage = .Index | .CopyDst, Memory = .GpuOnly, Label = "DynIB" });
		if (ibR case .Err) return .Err;
		mIndexBuffer = ibR.Value;

		let batchR = mGraphicsQueue.CreateTransferBatch();
		if (batchR case .Err) return .Err;
		var transfer = batchR.Value;
		transfer.WriteBuffer(mVertexBuffer, 0, Span<uint8>((uint8*)&verts[0], vbSize));
		transfer.WriteBuffer(mIndexBuffer, 0, Span<uint8>((uint8*)&indices[0], ibSize));
		transfer.Submit();
		mGraphicsQueue.DestroyTransferBatch(ref transfer);

		// Uniform buffer: 4 ObjectData structs (256 bytes each = 1024 total)
		uint32 ubSize = 256 * 4;
		let ubR = mDevice.CreateBuffer(BufferDesc() { Size = ubSize, Usage = .Uniform, Memory = .CpuToGpu, Label = "DynUBO" });
		if (ubR case .Err) return .Err;
		mUniformBuffer = ubR.Value;

		// Initialize UBO data
		UpdateUBO();

		// Bind group layout with dynamic offset UBO
		{
			let entries = scope BindGroupLayoutEntry[1];
			entries[0] = BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment, true);
			let r = mDevice.CreateBindGroupLayout(BindGroupLayoutDesc() { Entries = Span<BindGroupLayoutEntry>(entries), Label = "DynBGL" });
			if (r case .Err) return .Err;
			mBindGroupLayout = r.Value;
		}

		// Bind group (bind the whole buffer, dynamic offset selects the slice)
		{
			let entries = scope BindGroupEntry[1];
			entries[0] = BindGroupEntry.Buffer(mUniformBuffer, 0, 256);
			let r = mDevice.CreateBindGroup(BindGroupDesc() { Layout = mBindGroupLayout, Entries = Span<BindGroupEntry>(entries), Label = "DynBG" });
			if (r case .Err) return .Err;
			mBindGroup = r.Value;
		}

		// Pipeline layout
		{
			let bgls = scope IBindGroupLayout[1];
			bgls[0] = mBindGroupLayout;
			let r = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
			{
				BindGroupLayouts = Span<IBindGroupLayout>(bgls),
				Label = "DynPL"
			});
			if (r case .Err) return .Err;
			mPipelineLayout = r.Value;
		}

		// Pipeline with blend constant support
		let vertexAttribs = scope VertexAttribute[1];
		vertexAttribs[0] = VertexAttribute() { ShaderLocation = 0, Format = .Float32x3, Offset = 0 };
		let vertexLayouts = scope VertexBufferLayout[1];
		vertexLayouts[0] = VertexBufferLayout() { Stride = 12, StepMode = .Vertex, Attributes = Span<VertexAttribute>(vertexAttribs) };

		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All,
			Blend = BlendState()
			{
				Color = BlendComponent()
				{
					SrcFactor = .Constant,
					DstFactor = .OneMinusConstant,
					Operation = .Add
				},
				Alpha = BlendComponent()
				{
					SrcFactor = .One,
					DstFactor = .Zero,
					Operation = .Add
				}
			}
		};

		let pipR = mDevice.CreateRenderPipeline(RenderPipelineDesc()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertexShader, "VSMain"), Buffers = vertexLayouts },
			Fragment = .() { Shader = .(mPixelShader, "PSMain"), Targets = colorTargets },
			Primitive = PrimitiveState() { Topology = .TriangleList },
			Multisample = .(),
			Label = "DynPipeline"
		});
		if (pipR case .Err) return .Err;
		mPipeline = pipR.Value;

		let poolR = mDevice.CreateCommandPool(.Graphics);
		if (poolR case .Err) return .Err;
		mCommandPool = poolR.Value;

		let fenceR = mDevice.CreateFence(0);
		if (fenceR case .Err) return .Err;
		mFrameFence = fenceR.Value;

		return .Ok;
	}

	private void UpdateUBO()
	{
		let mapped = mUniformBuffer.Map();
		if (mapped == null) return;

		// 4 objects at different positions with different colors
		ObjectData[4] objs = default;

		// Red, top-left
		objs[0].TintColor = .(1.0f, 0.2f, 0.2f, 1.0f);
		objs[0].OffsetScale = .(-0.45f, 0.45f, 0.4f, 0.4f);

		// Green, top-right
		objs[1].TintColor = .(0.2f, 1.0f, 0.2f, 1.0f);
		objs[1].OffsetScale = .(0.45f, 0.45f, 0.4f, 0.4f);

		// Blue, bottom-left
		objs[2].TintColor = .(0.2f, 0.3f, 1.0f, 1.0f);
		objs[2].OffsetScale = .(-0.45f, -0.45f, 0.4f, 0.4f);

		// Yellow, bottom-right
		objs[3].TintColor = .(1.0f, 1.0f, 0.2f, 1.0f);
		objs[3].OffsetScale = .(0.45f, -0.45f, 0.4f, 0.4f);

		Internal.MemCpy(mapped, &objs[0], sizeof(decltype(objs)));
		mUniformBuffer.Unmap();
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0) mFrameFence.Wait(mFrameFenceValue);
		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encR = mCommandPool.CreateEncoder();
		if (encR case .Err) return;
		var encoder = encR.Value;

		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier() { Texture = mSwapChain.CurrentTexture, OldState = .Present, NewState = .RenderTarget };
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		let ca = scope ColorAttachment[1];
		ca[0] = ColorAttachment() { View = mSwapChain.CurrentTextureView, LoadOp = .Clear, StoreOp = .Store, ClearValue = ClearColor(0.08f, 0.08f, 0.12f, 1.0f) };

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(ca)
		});

		rp.SetPipeline(mPipeline);
		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);
		rp.SetVertexBuffer(0, mVertexBuffer, 0);
		rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);

		// Animate blend constant: pulsing between full visibility and half
		float pulse = 0.5f + 0.5f * Math.Sin(mTotalTime * 2.0f);
		rp.SetBlendConstant(pulse, pulse, pulse, 1.0f);

		// Draw 4 objects, each at a different dynamic offset
		for (uint32 i = 0; i < 4; i++)
		{
			let offsets = scope uint32[1];
			offsets[0] = i * 256;
			rp.SetBindGroup(0, mBindGroup, Span<uint32>(offsets));
			rp.DrawIndexed(6);
		}

		rp.End();

		texBarriers[0].OldState = .RenderTarget;
		texBarriers[0].NewState = .Present;
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		var cmdBuf = encoder.Finish();
		mFrameFenceValue++;
		mGraphicsQueue.Submit(Span<ICommandBuffer>(&cmdBuf, 1), mFrameFence, mFrameFenceValue);
		mSwapChain.Present(mGraphicsQueue);
		mCommandPool.DestroyEncoder(ref encoder);
	}

	protected override void OnShutdown()
	{
		if (mFrameFence != null) mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null) mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mPipeline != null) mDevice?.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroup != null) mDevice?.DestroyBindGroup(ref mBindGroup);
		if (mBindGroupLayout != null) mDevice?.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mUniformBuffer != null) mDevice?.DestroyBuffer(ref mUniformBuffer);
		if (mPixelShader != null) mDevice?.DestroyShaderModule(ref mPixelShader);
		if (mVertexShader != null) mDevice?.DestroyShaderModule(ref mVertexShader);
		if (mIndexBuffer != null) mDevice?.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice?.DestroyBuffer(ref mVertexBuffer);
		if (mShaderCompiler != null) { mShaderCompiler.Destroy(); delete mShaderCompiler; }
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope DynamicOffsetSample();
		return app.Run();
	}
}
