using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample023_CubeMap;

/// What both shaders are handed each frame.
[CRepr]
struct PushData
{
	public float Time;
	public float AspectRatio;
	public float Pad0;
	public float Pad1;
}

/// Two things a plain 2D sampled texture cannot do: a CUBE MAP sampled by direction, and a
/// COMPARISON sampler that returns a shadow factor rather than a colour.
///
/// The skybox fills the screen by sampling the cube with a rotating direction. The small
/// quad in the corner samples a depth texture through SampleCmp, which is how shadow mapping
/// gets its filtering for free.
class CubeMapSample : SampleApp
{
	private const String cSkyboxShader = """
		TextureCube<float4> gCubeMap : register(t0, space0);
		SamplerState gSampler : register(s0, space0);
		struct PushConstants
		{
		    float Time;
		    float AspectRatio;
		    float2 _pad;
		};
		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);
		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 UV       : TEXCOORD0;
		};
		PSInput VSMain(uint vertexID : SV_VertexID)
		{
		    PSInput output;
		    float2 uv = float2((vertexID << 1) & 2, vertexID & 2);
		    output.Position = float4(uv * 2.0 - 1.0, 0.5, 1.0);
		    output.UV = uv;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET
		{
		    float2 ndc = input.UV * 2.0 - 1.0;
		    ndc.x *= pc.AspectRatio;
		    ndc.y = -ndc.y;
		    float c = cos(pc.Time * 0.3);
		    float s = sin(pc.Time * 0.3);
		    float3 dir = normalize(float3(ndc.x, ndc.y, 1.0));
		    float3 rotDir = float3(dir.x * c + dir.z * s, dir.y, -dir.x * s + dir.z * c);
		    return gCubeMap.Sample(gSampler, rotDir);
		}
		""";

	private const String cShadowShader = """
		Texture2D<float> gShadowMap : register(t0, space0);
		SamplerComparisonState gShadowSampler : register(s0, space0);
		struct PushConstants
		{
		    float Time;
		    float AspectRatio;
		    float2 _pad;
		};
		[[vk::push_constant]] ConstantBuffer<PushConstants> pc : register(b0, space1);
		struct VSInput
		{
		    float3 Position : TEXCOORD0;
		    float2 TexCoord : TEXCOORD1;
		};
		struct PSInput
		{
		    float4 Position : SV_POSITION;
		    float2 TexCoord : TEXCOORD0;
		};
		PSInput VSMain(VSInput input)
		{
		    PSInput output;
		    output.Position = float4(input.Position, 1.0);
		    output.TexCoord = input.TexCoord;
		    return output;
		}
		float4 PSMain(PSInput input) : SV_TARGET
		{
		    float compareValue = 0.5 + 0.4 * sin(pc.Time);
		    float shadow = gShadowMap.SampleCmpLevelZero(gShadowSampler, input.TexCoord, compareValue);
		    float3 litColor = float3(0.9, 0.85, 0.7);
		    float3 shadowColor = float3(0.1, 0.1, 0.2);
		    float3 color = lerp(shadowColor, litColor, shadow);
		    return float4(color, 1.0);
		}
		""";

	private const uint32 cFaceSize = 64;
	private const uint32 cDepthSize = 64;
	/// The value the depth texture is cleared to, which the comparison sweeps across.
	private const float cDepthClearValue = 0.5f;

	/// A small quad in the lower right, position then texture coordinate.
	private static float[30] sQuadVertices = .(
		0.3f, -0.9f, 0.0f,   0.0f, 1.0f,
		0.9f, -0.9f, 0.0f,   1.0f, 1.0f,
		0.9f, -0.3f, 0.0f,   1.0f, 0.0f,
		0.3f, -0.9f, 0.0f,   0.0f, 1.0f,
		0.9f, -0.3f, 0.0f,   1.0f, 0.0f,
		0.3f, -0.3f, 0.0f,   0.0f, 0.0f);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mSkyboxVertexShader = null;
	private IShaderModule mSkyboxPixelShader = null;
	private ITexture mCubeTexture = null;
	private ITextureView mCubeView = null;
	private ISampler mLinearSampler = null;
	private IBindGroupLayout mSkyboxLayout = null;
	private IBindGroup mSkyboxBindGroup = null;
	private IPipelineLayout mSkyboxPipelineLayout = null;
	private IRenderPipeline mSkyboxPipeline = null;

	private IShaderModule mShadowVertexShader = null;
	private IShaderModule mShadowPixelShader = null;
	private ITexture mDepthTexture = null;
	private ITextureView mDepthView = null;
	private ISampler mComparisonSampler = null;
	private IBuffer mQuadVertexBuffer = null;
	private IBindGroupLayout mShadowLayout = null;
	private IBindGroup mShadowBindGroup = null;
	private IPipelineLayout mShadowPipelineLayout = null;
	private IRenderPipeline mShadowPipeline = null;

	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample023 - Cube Map & Comparison Sampler";

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cSkyboxShader, .Vertex,
			"VSMain", "SkyboxVS") case .Ok(let skyboxVertex)))
			return .Err;
		mSkyboxVertexShader = skyboxVertex;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cSkyboxShader, .Fragment,
			"PSMain", "SkyboxPS") case .Ok(let skyboxPixel)))
			return .Err;
		mSkyboxPixelShader = skyboxPixel;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShadowShader, .Vertex,
			"VSMain", "ShadowVS") case .Ok(let shadowVertex)))
			return .Err;
		mShadowVertexShader = shadowVertex;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cShadowShader, .Fragment,
			"PSMain", "ShadowPS") case .Ok(let shadowPixel)))
			return .Err;
		mShadowPixelShader = shadowPixel;

		if (CreateCubeMap() case .Err)
			return .Err;
		if (CreateDepthTexture() case .Err)
			return .Err;
		if (CreateSamplers() case .Err)
			return .Err;
		if (CreateSkyboxPipeline() case .Err)
			return .Err;
		if (CreateShadowPipeline() case .Err)
			return .Err;

		if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return .Err;
		mPool = pool;
		if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			return .Err;
		mFence = fence;
		return .Ok;
	}

	/// A cube map is a 2D texture with SIX ARRAY LAYERS and a view that says so.
	///
	/// Nothing about the texture itself is special: the view's dimension is what makes the
	/// shader able to sample it by direction.
	private Result<void> CreateCubeMap()
	{
		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture2D;
		textureDesc.Format = .RGBA8UnormSrgb;
		textureDesc.Width = cFaceSize;
		textureDesc.Height = cFaceSize;
		textureDesc.ArrayLayerCount = 6;
		textureDesc.MipLevelCount = 1;
		textureDesc.SampleCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "CubeMapTex";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mCubeTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8UnormSrgb;
		viewDesc.Dimension = .TextureCube;
		viewDesc.BaseMipLevel = 0;
		viewDesc.MipLevelCount = 1;
		viewDesc.BaseArrayLayer = 0;
		viewDesc.ArrayLayerCount = 6;
		if (!(mDevice.CreateTextureView(mCubeTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mCubeView = view;

		// One colour per face, so which way the camera is pointing is unmistakable.
		uint8[6][4] faceColors = .(
			.(200, 60, 60, 255),   // +X red
			.(60, 200, 200, 255),  // -X cyan
			.(60, 200, 60, 255),   // +Y green
			.(200, 60, 200, 255),  // -Y magenta
			.(60, 60, 200, 255),   // +Z blue
			.(200, 200, 60, 255)); // -Z yellow

		let faceBytes = cFaceSize * cFaceSize * 4;
		let pixels = scope uint8[faceBytes];

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		for (uint32 face < 6)
		{
			for (uint32 y < cFaceSize)
			{
				for (uint32 x < cFaceSize)
				{
					// A radial falloff, so the faces are shaded rather than flat and the
					// seams between them are visible.
					let fx = ((float)x / (float)cFaceSize) * 2.0f - 1.0f;
					let fy = ((float)y / (float)cFaceSize) * 2.0f - 1.0f;
					let distance = Math.Min(1.0f, Math.Sqrt(fx * fx + fy * fy));
					let t = 1.0f - distance * 0.5f;

					let at = (y * cFaceSize + x) * 4;
					pixels[(int)at + 0] = (uint8)(faceColors[face][0] * t + 40 * (1.0f - t));
					pixels[(int)at + 1] = (uint8)(faceColors[face][1] * t + 40 * (1.0f - t));
					pixels[(int)at + 2] = (uint8)(faceColors[face][2] * t + 40 * (1.0f - t));
					pixels[(int)at + 3] = 255;
				}
			}

			var layout = TextureDataLayout();
			layout.BytesPerRow = cFaceSize * 4;
			layout.RowsPerImage = cFaceSize;
			// The ARRAY LAYER selects the face, which is the last argument.
			batch.WriteTexture(mCubeTexture, pixels, layout, .(cFaceSize, cFaceSize, 1), 0, face);
		}
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);
		return .Ok;
	}

	/// A depth texture that is both rendered into and SAMPLED, which is what a shadow map
	/// is.
	private Result<void> CreateDepthTexture()
	{
		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture2D;
		textureDesc.Format = .Depth32Float;
		textureDesc.Width = cDepthSize;
		textureDesc.Height = cDepthSize;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.MipLevelCount = 1;
		textureDesc.SampleCount = 1;
		textureDesc.Usage = .DepthStencil | .Sampled;
		textureDesc.Label = "ShadowDepthTex";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mDepthTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .Depth32Float;
		viewDesc.Dimension = .Texture2D;
		if (!(mDevice.CreateTextureView(mDepthTexture, viewDesc) case .Ok(let view)))
			return .Err;
		mDepthView = view;
		// Nothing is drawn into it: the frame clears it to a constant, which is enough for
		// the comparison to have something to compare against.
		return .Ok;
	}

	private Result<void> CreateSamplers()
	{
		var linearDesc = SamplerDesc();
		linearDesc.MinFilter = .Linear;
		linearDesc.MagFilter = .Linear;
		linearDesc.Label = "LinearSampler";
		if (!(mDevice.CreateSampler(linearDesc) case .Ok(let linear)))
			return .Err;
		mLinearSampler = linear;

		// A COMPARISON sampler: setting Compare is what turns it from one that returns a
		// value into one that returns the fraction of samples passing the test.
		var comparisonDesc = SamplerDesc();
		comparisonDesc.MinFilter = .Linear;
		comparisonDesc.MagFilter = .Linear;
		comparisonDesc.Compare = .LessEqual;
		comparisonDesc.Label = "ComparisonSampler";
		if (!(mDevice.CreateSampler(comparisonDesc) case .Ok(let comparison)))
			return .Err;
		mComparisonSampler = comparison;
		return .Ok;
	}

	private Result<void> CreateSkyboxPipeline()
	{
		var layoutEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Vertex | .Fragment, .TextureCube),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		layoutDesc.Label = "SkyboxBGL";
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mSkyboxLayout = layout;

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mCubeView),
			BindGroupEntry.SamplerEntry(mLinearSampler));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mSkyboxLayout;
		groupDesc.Entries = entries;
		groupDesc.Label = "SkyboxBG";
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mSkyboxBindGroup = bindGroup;

		var layouts = IBindGroupLayout[1](mSkyboxLayout);
		var pushConstants = PushConstantRange[1](
			.() { Stages = .Vertex | .Fragment, Offset = 0, Size = (uint32)sizeof(PushData) });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		pipelineLayoutDesc.Label = "SkyboxPL";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mSkyboxPipelineLayout = pipelineLayout;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mSkyboxPipelineLayout;
		desc.Vertex.Shader = .(mSkyboxVertexShader, "VSMain", .Vertex);
		var fragment = FragmentState();
		fragment.Shader = .(mSkyboxPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .TriangleList;
		desc.Label = "SkyboxPipeline";
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mSkyboxPipeline = pipeline;
		return .Ok;
	}

	private Result<void> CreateShadowPipeline()
	{
		var vertexDesc = BufferDesc();
		vertexDesc.Size = sizeof(float) * sQuadVertices.Count;
		vertexDesc.Usage = .Vertex | .CopyDst;
		vertexDesc.Memory = .GpuOnly;
		vertexDesc.Label = "ShadowQuadVB";
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;
		mQuadVertexBuffer = vertexBuffer;

		if (!(mGraphicsQueue.CreateTransferBatch() case .Ok(var batch)))
			return .Err;
		batch.WriteBuffer(mQuadVertexBuffer, 0,
			.((uint8*)&sQuadVertices[0], sizeof(float) * sQuadVertices.Count));
		batch.Submit().IgnoreError();
		mGraphicsQueue.DestroyTransferBatch(ref batch);

		// The texture is declared as a DEPTH sample type and the sampler as a COMPARISON
		// one. Both are needed: an ordinary sampler cannot be used with SampleCmp, and a
		// comparison sampler cannot read an ordinary colour texture.
		var layoutEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment, .Texture2D),
			.());
		layoutEntries[0].TextureSampleType = .Depth;
		layoutEntries[1].Binding = 0;
		layoutEntries[1].Visibility = .Fragment;
		layoutEntries[1].Type = .ComparisonSampler;

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		layoutDesc.Label = "ShadowBGL";
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mShadowLayout = layout;

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mDepthView),
			BindGroupEntry.SamplerEntry(mComparisonSampler));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mShadowLayout;
		groupDesc.Entries = entries;
		groupDesc.Label = "ShadowBG";
		if (!(mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup)))
			return .Err;
		mShadowBindGroup = bindGroup;

		var layouts = IBindGroupLayout[1](mShadowLayout);
		var pushConstants = PushConstantRange[1](
			.() { Stages = .Vertex | .Fragment, Offset = 0, Size = (uint32)sizeof(PushData) });
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		pipelineLayoutDesc.PushConstantRanges = pushConstants;
		pipelineLayoutDesc.Label = "ShadowPL";
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mShadowPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x2, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 20;
		vertexLayout.Attributes = attributes;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;

		var buffers = VertexBufferLayout[1](vertexLayout);
		var targets = ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mShadowPipelineLayout;
		desc.Vertex.Shader = .(mShadowVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
		var fragment = FragmentState();
		fragment.Shader = .(mShadowPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .TriangleList;
		desc.Label = "ShadowPipeline";
		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mShadowPipeline = pipeline;
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

		// A pass with a DEPTH ATTACHMENT AND NOTHING ELSE, which exists only to clear it:
		// the comparison sampler needs something in the texture to compare against.
		encoder.TransitionTexture(mDepthTexture, .Undefined, .DepthStencilWrite);
		{
			var depthAttachment = DepthStencilAttachment();
			depthAttachment.View = mDepthView;
			depthAttachment.DepthLoadOp = .Clear;
			depthAttachment.DepthStoreOp = .Store;
			depthAttachment.DepthClearValue = cDepthClearValue;

			var depthPassDesc = RenderPassDesc();
			depthPassDesc.DepthStencilAttachment = depthAttachment;
			let depthPass = encoder.BeginRenderPass(depthPassDesc);
			depthPass.End();
		}
		// From written to readable, which is the transition a shadow map makes every frame.
		encoder.TransitionTexture(mDepthTexture, .DepthStencilWrite, .ShaderRead);

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.05f, 0.05f, 0.08f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		var pushData = PushData();
		pushData.Time = mTotalTime;
		pushData.AspectRatio = (float)mWidth / (float)mHeight;

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);

		// The skybox: a screen covering triangle from the vertex index alone.
		pass.SetPipeline(mSkyboxPipeline);
		pass.SetBindGroup(0, mSkyboxBindGroup);
		pass.SetPushConstants(.Vertex | .Fragment, 0, (uint32)sizeof(PushData), &pushData);
		pass.Draw(3);

		// The comparison overlay on top of it.
		pass.SetPipeline(mShadowPipeline);
		pass.SetBindGroup(0, mShadowBindGroup);
		pass.SetPushConstants(.Vertex | .Fragment, 0, (uint32)sizeof(PushData), &pushData);
		pass.SetVertexBuffer(0, mQuadVertexBuffer, 0);
		pass.Draw(6);
		pass.End();

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);
		// Back to writable, so the next frame's clearing pass starts from the state it
		// expects rather than from a shader readable one.
		encoder.TransitionTexture(mDepthTexture, .ShaderRead, .DepthStencilWrite);

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
		if (mShadowPipeline != null) mDevice.DestroyRenderPipeline(ref mShadowPipeline);
		if (mShadowPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mShadowPipelineLayout);
		if (mShadowBindGroup != null) mDevice.DestroyBindGroup(ref mShadowBindGroup);
		if (mShadowLayout != null) mDevice.DestroyBindGroupLayout(ref mShadowLayout);
		if (mQuadVertexBuffer != null) mDevice.DestroyBuffer(ref mQuadVertexBuffer);
		if (mComparisonSampler != null) mDevice.DestroySampler(ref mComparisonSampler);
		if (mDepthView != null) mDevice.DestroyTextureView(ref mDepthView);
		if (mDepthTexture != null) mDevice.DestroyTexture(ref mDepthTexture);
		if (mSkyboxPipeline != null) mDevice.DestroyRenderPipeline(ref mSkyboxPipeline);
		if (mSkyboxPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mSkyboxPipelineLayout);
		if (mSkyboxBindGroup != null) mDevice.DestroyBindGroup(ref mSkyboxBindGroup);
		if (mSkyboxLayout != null) mDevice.DestroyBindGroupLayout(ref mSkyboxLayout);
		if (mLinearSampler != null) mDevice.DestroySampler(ref mLinearSampler);
		if (mCubeView != null) mDevice.DestroyTextureView(ref mCubeView);
		if (mCubeTexture != null) mDevice.DestroyTexture(ref mCubeTexture);
		if (mShadowPixelShader != null) mDevice.DestroyShaderModule(ref mShadowPixelShader);
		if (mShadowVertexShader != null) mDevice.DestroyShaderModule(ref mShadowVertexShader);
		if (mSkyboxPixelShader != null) mDevice.DestroyShaderModule(ref mSkyboxPixelShader);
		if (mSkyboxVertexShader != null) mDevice.DestroyShaderModule(ref mSkyboxVertexShader);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope CubeMapSample();
		return app.Run(args);
	}
}
