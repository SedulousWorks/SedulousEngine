using System;
using Sedulous.Core;
using Sedulous.RHI;
using Samples.Framework;

namespace Samples.RHI.Sample011_MRT;

/// Multiple render targets: one pass writes colour and luminance at once, a second reads
/// both back and shows them side by side.
///
/// Two outputs from ONE fragment shader, which is what a deferred renderer's geometry pass
/// does. The composite pass is what proves both targets really were written.
class MRTSample : SampleApp
{
	private const String cGBufferShader = """
		struct VSInput { float3 Position : TEXCOORD0; float4 Color : TEXCOORD1; };
		struct PSInput { float4 Position : SV_POSITION; float4 Color : COLOR0; };
		struct PSOutput { float4 Color : SV_TARGET0; float4 Brightness : SV_TARGET1; };
		PSInput VSMain(VSInput i) { PSInput o; o.Position = float4(i.Position,1); o.Color = i.Color; return o; }
		PSOutput PSMain(PSInput i) { PSOutput o; o.Color = i.Color;
		    float lum = dot(i.Color.rgb, float3(0.299,0.587,0.114));
		    o.Brightness = float4(lum,lum,lum,1); return o; }
		""";

	private const String cCompositeShader = """
		Texture2D gColorTex : register(t0, space0);
		Texture2D gBrightTex : register(t1, space0);
		SamplerState gSampler : register(s0, space0);
		struct PSInput { float4 Position : SV_POSITION; float2 TexCoord : TEXCOORD0; };
		PSInput VSMain(uint vid : SV_VertexID) { PSInput o;
		    float2 uv = float2((vid << 1) & 2, vid & 2);
		    o.Position = float4(uv * 2.0 - 1.0, 0, 1); o.TexCoord = float2(uv.x, 1.0 - uv.y); return o; }
		float4 PSMain(PSInput i) : SV_TARGET {
		    float2 uv = i.TexCoord;
		    if (uv.x < 0.5) return gColorTex.Sample(gSampler, float2(uv.x*2, uv.y));
		    else return gBrightTex.Sample(gSampler, float2((uv.x-0.5)*2, uv.y)); }
		""";

	/// Two triangles, position then RGBA, one vertex per row. The second is translucent in
	/// its own right so the luminance target has something varied to show.
	private static float[42] sVertices = .(
		-0.5f, -0.5f, 0.0f,   1.0f, 0.2f, 0.2f, 1.0f,
		 0.5f, -0.5f, 0.0f,   1.0f, 0.2f, 0.2f, 1.0f,
		 0.0f,  0.6f, 0.0f,   1.0f, 0.8f, 0.2f, 1.0f,
		-0.3f, -0.3f, 0.0f,   0.2f, 0.3f, 1.0f, 1.0f,
		 0.7f, -0.1f, 0.0f,   0.2f, 0.3f, 1.0f, 1.0f,
		 0.2f,  0.5f, 0.0f,   0.2f, 0.8f, 1.0f, 1.0f);
	private static uint16[6] sIndices = .(0, 1, 2, 3, 4, 5);

	private Sedulous.Shaders.ShaderCompiler mCompiler = null;
	private IShaderModule mGBufferVertexShader = null;
	private IShaderModule mGBufferPixelShader = null;
	private IShaderModule mCompositeVertexShader = null;
	private IShaderModule mCompositePixelShader = null;
	private IBuffer mVertexBuffer = null;
	private IBuffer mIndexBuffer = null;
	private ISampler mSampler = null;
	private IPipelineLayout mGBufferPipelineLayout = null;
	private IPipelineLayout mCompositePipelineLayout = null;
	private IRenderPipeline mGBufferPipeline = null;
	private IRenderPipeline mCompositePipeline = null;
	private IBindGroupLayout mCompositeLayout = null;
	private IBindGroup mCompositeBindGroup = null;
	private ITexture mColorTarget = null;
	private ITexture mBrightnessTarget = null;
	private ITextureView mColorTargetView = null;
	private ITextureView mBrightnessTargetView = null;
	private ICommandPool mPool = null;
	private IFence mFence = null;
	private uint64 mFenceValue = 0;

	protected override StringView Title => "Sample011 - MRT";

	protected override void OnResize(uint32 width, uint32 height)
	{
		CreateRenderTargets();
	}

	/// The two offscreen targets and the bind group over them.
	///
	/// The BIND GROUP is rebuilt alongside them: it names the views, so a resize that
	/// replaced the textures without it would leave it pointing at freed ones.
	private void CreateRenderTargets()
	{
		if (mCompositeBindGroup != null) mDevice.DestroyBindGroup(ref mCompositeBindGroup);
		if (mColorTargetView != null) mDevice.DestroyTextureView(ref mColorTargetView);
		if (mColorTarget != null) mDevice.DestroyTexture(ref mColorTarget);
		if (mBrightnessTargetView != null) mDevice.DestroyTextureView(ref mBrightnessTargetView);
		if (mBrightnessTarget != null) mDevice.DestroyTexture(ref mBrightnessTarget);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = mWidth;
		textureDesc.Height = mHeight;
		// Written as a target in the first pass and read as a texture in the second.
		textureDesc.Usage = .RenderTarget | .Sampled;
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let colorTarget)))
			return;
		mColorTarget = colorTarget;
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let brightnessTarget)))
			return;
		mBrightnessTarget = brightnessTarget;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(mColorTarget, viewDesc) case .Ok(let colorView)))
			return;
		mColorTargetView = colorView;
		if (!(mDevice.CreateTextureView(mBrightnessTarget, viewDesc) case .Ok(let brightView)))
			return;
		mBrightnessTargetView = brightView;

		var entries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(mColorTargetView),
			BindGroupEntry.TextureEntry(mBrightnessTargetView),
			BindGroupEntry.SamplerEntry(mSampler));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = mCompositeLayout;
		groupDesc.Entries = entries;
		if (mDevice.CreateBindGroup(groupDesc) case .Ok(let bindGroup))
			mCompositeBindGroup = bindGroup;
	}

	protected override Result<void> OnInit()
	{
		mCompiler = new Sedulous.Shaders.ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
			return .Err;

		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cGBufferShader, .Vertex,
			"VSMain", "GBufVS") case .Ok(let gbufferVertex)))
			return .Err;
		mGBufferVertexShader = gbufferVertex;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cGBufferShader, .Fragment,
			"PSMain", "GBufPS") case .Ok(let gbufferPixel)))
			return .Err;
		mGBufferPixelShader = gbufferPixel;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cCompositeShader, .Vertex,
			"VSMain", "CompVS") case .Ok(let compositeVertex)))
			return .Err;
		mCompositeVertexShader = compositeVertex;
		if (!(ShaderHelpers.CompileToModule(mCompiler, mDevice, cCompositeShader, .Fragment,
			"PSMain", "CompPS") case .Ok(let compositePixel)))
			return .Err;
		mCompositePixelShader = compositePixel;

		if (CreateBuffers() case .Err)
			return .Err;
		if (CreateGBufferPipeline() case .Err)
			return .Err;
		if (CreateCompositePipeline() case .Err)
			return .Err;

		CreateRenderTargets();

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

		// Nearest and clamped: the composite samples the targets one to one, so filtering
		// would only blur what is meant to be an exact readback.
		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Nearest;
		samplerDesc.MagFilter = .Nearest;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;
		return .Ok;
	}

	private Result<void> CreateGBufferPipeline()
	{
		if (!(mDevice.CreatePipelineLayout(.()) case .Ok(let pipelineLayout)))
			return .Err;
		mGBufferPipelineLayout = pipelineLayout;

		var attributes = VertexAttribute[2](
			.() { Format = .Float32x3, Offset = 0, ShaderLocation = 0 },
			.() { Format = .Float32x4, Offset = 12, ShaderLocation = 1 });
		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = 28;
		vertexLayout.Attributes = attributes;
		var buffers = VertexBufferLayout[1](vertexLayout);

		// TWO targets, matching the fragment shader's two outputs. A pipeline declaring
		// one would not accept the shader.
		var targets = ColorTargetState[2](
			.() { Format = .RGBA8Unorm, WriteMask = .All },
			.() { Format = .RGBA8Unorm, WriteMask = .All });

		var desc = RenderPipelineDesc();
		desc.Layout = mGBufferPipelineLayout;
		desc.Vertex.Shader = .(mGBufferVertexShader, "VSMain", .Vertex);
		desc.Vertex.Buffers = buffers;
		var fragment = FragmentState();
		fragment.Shader = .(mGBufferPixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mGBufferPipeline = pipeline;
		return .Ok;
	}

	private Result<void> CreateCompositePipeline()
	{
		var layoutEntries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = layoutEntries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mCompositeLayout = layout;

		var layouts = IBindGroupLayout[1](mCompositeLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mCompositePipelineLayout = pipelineLayout;

		var colorTarget = ColorTargetState();
		colorTarget.Format = mSwapChain.Format;
		var targets = ColorTargetState[1](colorTarget);

		// NO vertex buffers: the fullscreen triangle is generated from the vertex index.
		var desc = RenderPipelineDesc();
		desc.Layout = mCompositePipelineLayout;
		desc.Vertex.Shader = .(mCompositeVertexShader, "VSMain", .Vertex);
		var fragment = FragmentState();
		fragment.Shader = .(mCompositePixelShader, "PSMain", .Fragment);
		fragment.Targets = targets;
		desc.Fragment = fragment;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return .Err;
		mCompositePipeline = pipeline;
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

		RecordGBufferPass(encoder);
		RecordCompositePass(encoder);

		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();
		mFenceValue++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mGraphicsQueue.Submit(buffers, mFence, mFenceValue);
		mSwapChain.Present(mGraphicsQueue).IgnoreError();
		mPool.DestroyEncoder(ref encoder);
	}

	private void RecordGBufferPass(ICommandEncoder encoder)
	{
		encoder.TransitionTexture(mColorTarget, .Undefined, .RenderTarget);
		encoder.TransitionTexture(mBrightnessTarget, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mColorTargetView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .(0.1f, 0.1f, 0.15f, 1.0f);

		var brightnessAttachment = ColorAttachment();
		brightnessAttachment.View = mBrightnessTargetView;
		brightnessAttachment.LoadOp = .Clear;
		brightnessAttachment.StoreOp = .Store;
		brightnessAttachment.ClearValue = ClearColor.Black;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);
		passDesc.ColorAttachments.Add(brightnessAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mGBufferPipeline);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		pass.SetVertexBuffer(0, mVertexBuffer, 0);
		pass.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
		pass.DrawIndexed(6);
		pass.End();

		// From written to readable, which is what the second pass needs and what the first
		// pass's targets are not yet.
		encoder.TransitionTexture(mColorTarget, .RenderTarget, .ShaderRead);
		encoder.TransitionTexture(mBrightnessTarget, .RenderTarget, .ShaderRead);
	}

	private void RecordCompositePass(ICommandEncoder encoder)
	{
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var colorAttachment = ColorAttachment();
		colorAttachment.View = mSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = ClearColor.Black;

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		pass.SetPipeline(mCompositePipeline);
		pass.SetBindGroup(0, mCompositeBindGroup);
		pass.SetViewport(0, 0, (float)mWidth, (float)mHeight, 0, 1);
		pass.SetScissor(0, 0, mWidth, mHeight);
		// Three vertices and no buffer: the shader builds a triangle that covers the
		// screen out of the vertex index alone.
		pass.Draw(3);
		pass.End();
	}

	protected override void OnShutdown()
	{
		if (mFence != null) mDevice.DestroyFence(ref mFence);
		if (mPool != null) mDevice.DestroyCommandPool(ref mPool);
		if (mCompositeBindGroup != null) mDevice.DestroyBindGroup(ref mCompositeBindGroup);
		if (mColorTargetView != null) mDevice.DestroyTextureView(ref mColorTargetView);
		if (mColorTarget != null) mDevice.DestroyTexture(ref mColorTarget);
		if (mBrightnessTargetView != null) mDevice.DestroyTextureView(ref mBrightnessTargetView);
		if (mBrightnessTarget != null) mDevice.DestroyTexture(ref mBrightnessTarget);
		if (mCompositePipeline != null) mDevice.DestroyRenderPipeline(ref mCompositePipeline);
		if (mGBufferPipeline != null) mDevice.DestroyRenderPipeline(ref mGBufferPipeline);
		if (mCompositeLayout != null) mDevice.DestroyBindGroupLayout(ref mCompositeLayout);
		if (mCompositePipelineLayout != null) mDevice.DestroyPipelineLayout(ref mCompositePipelineLayout);
		if (mGBufferPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mGBufferPipelineLayout);
		if (mSampler != null) mDevice.DestroySampler(ref mSampler);
		if (mIndexBuffer != null) mDevice.DestroyBuffer(ref mIndexBuffer);
		if (mVertexBuffer != null) mDevice.DestroyBuffer(ref mVertexBuffer);
		if (mCompositePixelShader != null) mDevice.DestroyShaderModule(ref mCompositePixelShader);
		if (mCompositeVertexShader != null) mDevice.DestroyShaderModule(ref mCompositeVertexShader);
		if (mGBufferPixelShader != null) mDevice.DestroyShaderModule(ref mGBufferPixelShader);
		if (mGBufferVertexShader != null) mDevice.DestroyShaderModule(ref mGBufferVertexShader);
		delete mCompiler;
		mCompiler = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope MRTSample();
		return app.Run(args);
	}
}
