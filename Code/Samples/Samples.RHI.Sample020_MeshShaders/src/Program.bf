using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample020_MeshShaders;

/// What the mesh shader is handed each frame.
[CRepr]
struct PushData
{
	public float Time;
	public float AspectRatio;
	public float Pad0;
	public float Pad1;
}

/// A rotating triangle produced entirely by a MESH SHADER.
///
/// There is no vertex buffer, no index buffer and no vertex shader: the mesh shader emits
/// the vertices and the one triangle joining them. That is the point of the stage, and it is
/// why the pipeline is a mesh pipeline rather than a render pipeline.
class MeshShaderSample : SampleApp
{
	private const String cMeshShaderSource = """
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

	private const String cFragmentShaderSource = """
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

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mMeshModule = null;
	private IShaderModule mFragmentModule = null;
	private IPipelineLayout mPipelineLayout = null;
	private IMeshPipeline mMeshPipeline = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample020 - Mesh Shaders (Rotating Triangle)";

	protected override DeviceFeatures RequiredFeatures
	{
		get
		{
			var features = DeviceFeatures();
			features.MeshShaders = true;
			return features;
		}
	}

	protected override Result<void> OnInit()
	{
		if (!mDevice.Features.MeshShaders)
		{
			Console.Error.WriteLine("Sample020: this device does not support mesh shaders");
			return .Err;
		}

		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		// SHADER MODEL 6.5: the mesh stage does not exist below it, and the default 6.0
		// would fail to compile rather than fail to link.
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cMeshShaderSource, .Mesh,
			"MSMain", "MeshShader", "6_5") case .Ok(let meshModule)))
			return .Err;
		mMeshModule = meshModule;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cFragmentShaderSource,
			.Fragment, "PSMain", "FragmentShader") case .Ok(let fragmentModule)))
			return .Err;
		mFragmentModule = fragmentModule;

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

	private Result<void> CreatePipeline()
	{
		// Visible to the MESH stage, which is where the geometry is built.
		var pushConstants = PushConstantRange[1](
			.() { Stages = .Mesh, Offset = 0, Size = (uint32)sizeof(PushData) });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		pipelineLayoutDesc.Label = "MeshPipelineLayout";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		colorTarget.WriteMask = .All;
		var targets = ColorTargetState[1](colorTarget);

		var desc = MeshPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Mesh = .(mMeshModule, "MSMain", .Mesh);
		var fragment = FragmentState();
		fragment.Shader = .(mFragmentModule, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.ColorTargets = targets;
		desc.Label = "MeshShaderPipeline";

		if (!(mDevice.CreateMeshPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mMeshPipeline = pipeline;
		return .Ok;
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
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);

		// Mesh shading is an EXTENSION on the pass, not part of its base interface: a
		// backend without it simply does not offer this.
		if (let meshPass = pass as IMeshShaderPassExt)
		{
			meshPass.SetMeshPipeline(mMeshPipeline);

			// AFTER the pipeline is bound: push constants belong to the bound layout.
			var pushData = PushData();
			pushData.Time = mTotalTime;
			pushData.AspectRatio = (float)mWidth / (float)mHeight;
			// Through the PASS, not the extension: push constants belong to the pipeline
			// layout, which is the same one either way.
			pass.SetPushConstants(.Mesh, 0, (uint32)sizeof(PushData), &pushData);

			// ONE workgroup: the shader's numthreads is one, and it emits the whole
			// triangle by itself.
			meshPass.DrawMeshTasks(1, 1, 1);
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
		if (mMeshPipeline != null) mDevice.DestroyMeshPipeline(ref mMeshPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mFragmentModule != null) mDevice.DestroyShaderModule(ref mFragmentModule);
		if (mMeshModule != null) mDevice.DestroyShaderModule(ref mMeshModule);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MeshShaderSample();
		return app.Run(args);
	}
}
