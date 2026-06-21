namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;
using Sedulous.Profiler;
using Sedulous.Core.Mathematics;

/// GPU-packed SSR parameters. Must match ssr.frag.hlsl SSRParams cbuffer.
[CRepr]
struct SSRParams
{
	public Matrix ViewMatrix;
	public Matrix ProjectionMatrix;
	public Matrix InvProjectionMatrix;
	public Matrix InvViewProjectionMatrix;
	public Vector2 ScreenSize;
	public Vector2 InvScreenSize;
	public float NearPlane;
	public float FarPlane;
	public float MaxDistance;
	public float Thickness;
	public int32 MaxSteps;
	public int32 BinarySteps;
	public Vector2 _Pad;

	public const uint64 Size = sizeof(Self);
}

/// Screen-Space Reflections effect.
/// Produces an "SSRTexture" auxiliary texture that the tonemap shader reads
/// to composite reflections. Does not modify the color chain directly.
///
/// Ray marches the depth buffer in screen space to find reflected geometry.
/// Falls back to zero (transparent) where the ray misses, so IBL probe
/// reflections show through naturally.
class SSREffect : PostProcessEffect
{
	private Sedulous.RHI.IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;
	private ISampler mPointSampler;
	private ISampler mLinearSampler;
	private IBuffer mParamsBuffer;
	private IDevice mDevice;
	private RenderContext mRenderContext;

	private const int MaxFrames = 2;
	private IBindGroup[MaxFrames] mBindGroups;

	/// Maximum ray march distance in world units.
	public float MaxDistance = 10.0f;

	/// Depth comparison thickness in world units.
	public float Thickness = 0.1f;

	/// Maximum linear ray march steps.
	public int32 MaxSteps = 32;

	/// Binary refinement steps after initial hit.
	public int32 BinarySteps = 8;

	public override StringView Name => "SSR";

	public override Result<void> OnInitialize(RenderContext renderContext)
	{
		mRenderContext = renderContext;
		mDevice = renderContext.Device;
		let shaderSystem = renderContext.ShaderSystem;
		if (shaderSystem == null)
			return .Err;

		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let vertModule = vertResult.Value;

		let fragResult = shaderSystem.GetShader("ssr", .Fragment);
		if (fragResult case .Err) return .Err;
		let fragModule = fragResult.Value;

		// Bind group layout:
		// b0 = SSRParams
		// t0 = SceneColor
		// t1 = SceneDepth
		// t2 = SceneNormals
		// s0 = PointSampler
		// s1 = LinearSampler
		BindGroupLayoutEntry[6] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment),
			.SampledTexture(1, .Fragment),
			.SampledTexture(2, .Fragment),
			.Sampler(0, .Fragment),
			.Sampler(1, .Fragment)
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "SSR BindGroup Layout", Entries = entries };
		if (mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		// Point sampler for depth/normal reads
		SamplerDesc pointDesc = .()
		{
			MinFilter = .Nearest, MagFilter = .Nearest, MipmapFilter = .Nearest,
			AddressU = .ClampToEdge, AddressV = .ClampToEdge, AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(pointDesc) case .Ok(let sampler))
			mPointSampler = sampler;
		else
			return .Err;

		// Linear sampler for scene color reads
		SamplerDesc linearDesc = .()
		{
			MinFilter = .Linear, MagFilter = .Linear, MipmapFilter = .Nearest,
			AddressU = .ClampToEdge, AddressV = .ClampToEdge, AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(linearDesc) case .Ok(let linSampler))
			mLinearSampler = linSampler;
		else
			return .Err;

		// Params buffer
		BufferDesc paramsBufDesc = .()
		{
			Label = "SSR Params",
			Size = SSRParams.Size,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(paramsBufDesc) case .Ok(let buf))
			mParamsBuffer = buf;
		else
			return .Err;

		// Render pipeline - output is RGBA16Float
		ColorTargetState[1] colorTargets = .(.() { Format = .RGBA16Float });

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "SSR Pipeline",
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(vertModule.Module, "main"), Buffers = default },
			Fragment = .() { Shader = .(fragModule.Module, "main"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, FrontFace = .CCW, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (mDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	public override void OnShutdown()
	{
		if (mDevice == null) return;

		for (int i = 0; i < MaxFrames; i++)
			if (mBindGroups[i] != null) mDevice.DestroyBindGroup(ref mBindGroups[i]);

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mPointSampler != null) mDevice.DestroySampler(ref mPointSampler);
		if (mLinearSampler != null) mDevice.DestroySampler(ref mLinearSampler);
		if (mParamsBuffer != null) mDevice.DestroyBuffer(ref mParamsBuffer);
	}

	public override void DeclareOutputs(RenderGraph graph, PostProcessContext ctx)
	{
		let desc = RGTextureDesc(.RGBA16Float) { Usage = .RenderTarget | .Sampled };
		let ssrHandle = graph.CreateTransient("SSRTexture", desc);
		ctx.SetAux("SSRTexture", ssrHandle);
	}

	public override void AddPasses(RenderGraph graph, RenderView view, RenderContext renderContext, PostProcessContext ctx)
	{
		using (Profiler.Begin("SSR"))
		{

		let ssrHandle = ctx.GetAux("SSRTexture");
		if (!ssrHandle.IsValid) return;

		let depthHandle = ctx.SceneDepth;
		let normalsHandle = ctx.SceneNormals;
		let inputHandle = ctx.Input;
		if (!depthHandle.IsValid || !normalsHandle.IsValid || !inputHandle.IsValid) return;

		// Upload params
		SSRParams @params = .()
		{
			ViewMatrix = view.ViewMatrix,
			ProjectionMatrix = view.ProjectionMatrix,
			InvProjectionMatrix = .Identity,
			InvViewProjectionMatrix = .Identity,
			ScreenSize = .(view.Width, view.Height),
			InvScreenSize = .(1.0f / Math.Max(view.Width, 1), 1.0f / Math.Max(view.Height, 1)),
			NearPlane = view.NearPlane,
			FarPlane = view.FarPlane,
			MaxDistance = MaxDistance,
			Thickness = Thickness,
			MaxSteps = MaxSteps,
			BinarySteps = BinarySteps
		};
		Matrix.Invert(view.ProjectionMatrix, out @params.InvProjectionMatrix);
		Matrix.Invert(view.ViewProjectionMatrix, out @params.InvViewProjectionMatrix);
		TransferHelper.WriteMappedBuffer(mParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, SSRParams.Size));

		graph.AddRenderPass("SSR", scope (builder) => {
			builder
				.ReadTexture(inputHandle)
				.ReadTexture(depthHandle)
				.ReadTexture(normalsHandle)
				.SetColorTarget(0, ssrHandle, .Clear, .Store, ClearColor(0, 0, 0, 0))
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteSSR(encoder, view, graph, inputHandle, depthHandle, normalsHandle);
				});
		});

		// Pass through color chain unchanged - tonemap reads SSRTexture aux
		ctx.Output = ctx.Input;

		} // SSR profiler scope
	}

	private void ExecuteSSR(IRenderPassEncoder encoder, RenderView view, RenderGraph graph,
		RGHandle inputHandle, RGHandle depthHandle, RGHandle normalsHandle)
	{
		let inputView = graph.GetTextureView(inputHandle);
		let depthView = graph.GetDepthOnlyTextureView(depthHandle);
		let normalsView = graph.GetTextureView(normalsHandle);
		if (inputView == null || depthView == null || normalsView == null) return;

		let frameSlot = view.FrameIndex % MaxFrames;

		if (mBindGroups[frameSlot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[frameSlot]);

		BindGroupEntry[6] bgEntries = .(
			BindGroupEntry.Buffer(mParamsBuffer, 0, SSRParams.Size),
			BindGroupEntry.Texture(inputView),
			BindGroupEntry.Texture(depthView),
			BindGroupEntry.Texture(normalsView),
			BindGroupEntry.Sampler(mPointSampler),
			BindGroupEntry.Sampler(mLinearSampler)
		);

		BindGroupDesc bgDesc = .() { Label = "SSR BindGroup", Layout = mBindGroupLayout, Entries = bgEntries };
		if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
			mBindGroups[frameSlot] = bg;

		if (mBindGroups[frameSlot] == null) return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0, 1);
		encoder.SetScissor(0, 0, view.Width, view.Height);
		encoder.SetPipeline(mPipeline);
		encoder.SetBindGroup(0, mBindGroups[frameSlot], default);
		encoder.Draw(3, 1, 0, 0);
	}
}
