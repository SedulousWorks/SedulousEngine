namespace Sample020_MeshShaders;

using System;
using System.Collections;
using Sedulous.RHI;
using SampleFramework;

[CRepr]
struct PushData
{
	public float Time;
	public float AspectRatio;
	public float Pad0;
	public float Pad1;
}

class MeshShaderSample : SampleApp
{
	const String cMeshShaderSource = """
		struct PushConstants
		{
		    float Time;
		    float AspectRatio;
		    float Pad0, Pad1;
		};

		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space0);

		struct MeshOutput
		{
		    float4 Position : SV_POSITION;
		    float3 Color    : TEXCOORD0;
		};

		[outputtopology("triangle")]
		[numthreads(1, 1, 1)]
		void MSMain(out vertices MeshOutput verts[3], out indices uint3 tris[1])
		{
		    SetMeshOutputCounts(3, 1);

		    float angle = pc.Time * 0.5;
		    float c = cos(angle);
		    float s = sin(angle);

		    float2 positions[3] = {
		        float2( 0.0,  0.5),
		        float2(-0.5, -0.5),
		        float2( 0.5, -0.5)
		    };

		    float3 colors[3] = {
		        float3(1.0, 0.0, 0.0),
		        float3(0.0, 1.0, 0.0),
		        float3(0.0, 0.0, 1.0)
		    };

		    for (uint i = 0; i < 3; i++)
		    {
		        float2 p = positions[i];
		        float2 rotated = float2(p.x * c - p.y * s, p.x * s + p.y * c);
		        rotated.x /= pc.AspectRatio;

		        verts[i].Position = float4(rotated, 0.0, 1.0);
		        verts[i].Color = colors[i];
		    }

		    tris[0] = uint3(0, 1, 2);
		}
		""";

	const String cFragmentShaderSource = """
		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float3 Color    : TEXCOORD0;
		};

		float4 PSMain(PSInput input) : SV_TARGET
		{
		    return float4(input.Color, 1.0);
		}
		""";

	private ShaderCompiler mShaderCompiler;

	private IShaderModule mMeshShaderModule;
	private IShaderModule mFragmentShaderModule;

	private IPipelineLayout mPipelineLayout;
	private IMeshPipeline mMeshPipeline;

	private IMeshShaderExt mMeshExt;

	private ICommandPool mCommandPool;
	private IFence mFrameFence;
	private uint64 mFrameFenceValue;

	public this() { }

	protected override StringView Title => "Sample020 - Mesh Shaders (Rotating Triangle)";

	protected override DeviceFeatures RequiredFeatures => .() { MeshShaders = true };

	protected override Result<void> OnInit()
	{
		// Check mesh shader extension availability
		mMeshExt = mDevice.GetMeshShaderExt();
		if (mMeshExt == null)
		{
			Console.WriteLine("ERROR: Mesh shaders are not supported by this device/backend");
			return .Err;
		}

		// Shader compiler
		mShaderCompiler = new ShaderCompiler();
		if (mShaderCompiler.Init() case .Err)
		{
			Console.WriteLine("ERROR: ShaderCompiler.Init failed");
			return .Err;
		}

		let format = (mBackendType == .Vulkan) ? ShaderOutputFormat.SPIRV : ShaderOutputFormat.DXIL;
		let errors = scope String();

		// Compile mesh shader
		let msBytecode = scope List<uint8>();
		if (mShaderCompiler.CompileMesh(cMeshShaderSource, "MSMain", format, msBytecode, errors) case .Err)
		{
			Console.WriteLine("MS compile failed: {}", errors);
			return .Err;
		}

		let msResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(msBytecode.Ptr, msBytecode.Count), Label = "MeshShader" });
		if (msResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (MS) failed"); return .Err; }
		mMeshShaderModule = msResult.Value;

		// Compile fragment shader
		let psBytecode = scope List<uint8>();
		errors.Clear();
		if (mShaderCompiler.CompilePixel(cFragmentShaderSource, "PSMain", format, psBytecode, errors) case .Err)
		{
			Console.WriteLine("PS compile failed: {}", errors);
			return .Err;
		}

		let psResult = mDevice.CreateShaderModule(ShaderModuleDesc() { Code = Span<uint8>(psBytecode.Ptr, psBytecode.Count), Label = "FragmentShader" });
		if (psResult case .Err) { Console.WriteLine("ERROR: CreateShaderModule (PS) failed"); return .Err; }
		mFragmentShaderModule = psResult.Value;

		// Pipeline layout with push constants
		let pushRanges = scope PushConstantRange[1];
		pushRanges[0] = PushConstantRange() { Stages = .Mesh, Offset = 0, Size = 16 };

		let plResult = mDevice.CreatePipelineLayout(PipelineLayoutDesc()
		{
			PushConstantRanges = Span<PushConstantRange>(pushRanges),
			Label = "MeshPipelineLayout"
		});
		if (plResult case .Err) { Console.WriteLine("ERROR: CreatePipelineLayout failed"); return .Err; }
		mPipelineLayout = plResult.Value;

		// Create mesh pipeline
		let colorTargets = scope ColorTargetState[1];
		colorTargets[0] = ColorTargetState()
		{
			Format = mSwapChain.Format,
			WriteMask = .All
		};

		let meshPipResult = mMeshExt.CreateMeshPipeline(MeshPipelineDesc()
		{
			Layout = mPipelineLayout,
			Mesh = ProgrammableStage() { Module = mMeshShaderModule, EntryPoint = "MSMain", Stage = .Mesh },
			Fragment = ProgrammableStage() { Module = mFragmentShaderModule, EntryPoint = "PSMain", Stage = .Fragment },
			ColorTargets = Span<ColorTargetState>(colorTargets),
			Primitive = .(),
			Multisample = .(),
			Label = "MeshShaderPipeline"
		});
		if (meshPipResult case .Err) { Console.WriteLine("ERROR: CreateMeshPipeline failed"); return .Err; }
		mMeshPipeline = meshPipResult.Value;

		// Command pool and fence
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) { Console.WriteLine("ERROR: CreateCommandPool failed"); return .Err; }
		mCommandPool = poolResult.Value;

		let fenceResult = mDevice.CreateFence(0);
		if (fenceResult case .Err) { Console.WriteLine("ERROR: CreateFence failed"); return .Err; }
		mFrameFence = fenceResult.Value;
		mFrameFenceValue = 0;

		return .Ok;
	}

	protected override void OnRender()
	{
		if (mFrameFenceValue > 0)
			mFrameFence.Wait(mFrameFenceValue);

		if (mSwapChain.AcquireNextImage() case .Err) return;

		mCommandPool.Reset();
		let encoderResult = mCommandPool.CreateEncoder();
		if (encoderResult case .Err) return;
		var encoder = encoderResult.Value;

		// Barrier: present -> render target
		let texBarriers = scope TextureBarrier[1];
		texBarriers[0] = TextureBarrier()
		{
			Texture = mSwapChain.CurrentTexture,
			OldState = .Present,
			NewState = .RenderTarget
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(texBarriers) });

		// Begin render pass
		let colorAttachments = scope ColorAttachment[1];
		colorAttachments[0] = ColorAttachment()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.05f, 0.05f, 0.08f, 1.0f)
		};

		let rp = encoder.BeginRenderPass(RenderPassDesc()
		{
			ColorAttachments = .(colorAttachments)
		});

		rp.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0.0f, 1.0f);
		rp.SetScissor(0, 0, mWidth, mHeight);

		// Draw with mesh shader
		if (let meshPass = rp as IMeshShaderPassExt)
		{
			meshPass.SetMeshPipeline(mMeshPipeline);

			// Push constants (must be after pipeline is bound)
			var pushData = PushData()
			{
				Time = mTotalTime,
				AspectRatio = (float)mWidth / (float)mHeight,
				Pad0 = 0.0f,
				Pad1 = 0.0f
			};
			rp.SetPushConstants(.Mesh, 0, 16, &pushData);

			meshPass.DrawMeshTasks(1);
		}

		rp.End();

		// Barrier: render target -> present
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
		if (mFrameFence != null)
			mDevice?.DestroyFence(ref mFrameFence);
		if (mCommandPool != null)
			mDevice?.DestroyCommandPool(ref mCommandPool);
		if (mMeshPipeline != null && mMeshExt != null)
			mMeshExt.DestroyMeshPipeline(ref mMeshPipeline);
		if (mPipelineLayout != null)
			mDevice?.DestroyPipelineLayout(ref mPipelineLayout);
		if (mFragmentShaderModule != null)
			mDevice?.DestroyShaderModule(ref mFragmentShaderModule);
		if (mMeshShaderModule != null)
			mDevice?.DestroyShaderModule(ref mMeshShaderModule);
		if (mShaderCompiler != null)
		{
			mShaderCompiler.Destroy();
			delete mShaderCompiler;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MeshShaderSample();
		return app.Run();
	}
}
