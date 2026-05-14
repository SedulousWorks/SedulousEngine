namespace Sedulous.Renderer;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;
using Sedulous.Profiler;

/// Temporal Anti-Aliasing effect.
/// Blends the current jittered frame with a reprojected history buffer using
/// motion vectors. Runs in HDR before tone mapping. Requires camera jitter
/// (Pipeline.TAAEnabled = true) and motion vectors from the forward pass.
///
/// Uses neighborhood clamping in YCoCg space to prevent ghosting, and
/// motion-adaptive blending to reduce blur during fast camera movement.
class TAAEffect : PostProcessEffect
{
	private Sedulous.RHI.IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;
	private ISampler mPointSampler;
	private ISampler mLinearSampler;
	private IBuffer mParamsBuffer;
	private IDevice mDevice;
	private RenderContext mRenderContext;

	/// Number of history color slots for the temporal ping-pong: one slot is
	/// read while the other is written each frame. The resolve algorithm
	/// (read previous -> blend with current -> write new) is fundamentally
	/// 2-slot; a larger count would only matter for variants that sample
	/// multiple frames back. Independent of MaxFramesInFlight (CPU/GPU
	/// pipelining is fence-driven, not slot-driven).
	private const int TAAHistoryCount = 2;

	// History ping-pong textures (persistent across frames, owned by effect)
	private ITexture[TAAHistoryCount] mHistoryTextures;
	private ITextureView[TAAHistoryCount] mHistoryViews;
	private uint32 mHistoryWidth;
	private uint32 mHistoryHeight;
	private int32 mHistoryIndex = 0;
	private uint32 mFrameCount = 0;

	// Per-frame bind groups (double-buffered)
	private const int MaxFrames = 2;
	private IBindGroup[MaxFrames] mBindGroups;

	/// History blend weight. Higher = more temporal stability, lower = more responsive.
	/// 0.95 = 95% history (default), 0.9 = less ghosting, 0.98 = very stable.
	public float BlendFactor = 0.95f;

	public override StringView Name => "TAA";

	public override Result<void> OnInitialize(RenderContext renderContext)
	{
		mRenderContext = renderContext;
		mDevice = renderContext.Device;
		let shaderSystem = renderContext.ShaderSystem;
		if (shaderSystem == null)
			return .Err;

		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err)
			return .Err;
		let vertModule = vertResult.Value;

		let fragResult = shaderSystem.GetShader("taa", .Fragment);
		if (fragResult case .Err)
			return .Err;
		let fragModule = fragResult.Value;

		// Bind group layout:
		// b0 = TAAParams
		// t0 = current color
		// t1 = history color
		// t2 = motion vectors
		// t3 = depth (current frame)
		// t4 = previous depth (last frame, for disocclusion testing)
		// s0 = point sampler
		// s1 = linear sampler
		BindGroupLayoutEntry[8] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment),
			.SampledTexture(1, .Fragment),
			.SampledTexture(2, .Fragment),
			.SampledTexture(3, .Fragment),
			.SampledTexture(4, .Fragment),
			.Sampler(0, .Fragment),
			.Sampler(1, .Fragment)
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "TAA BindGroup Layout", Entries = entries };
		if (mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		// Point sampler (for current color, motion vectors, depth)
		SamplerDesc pointDesc = .()
		{
			MinFilter = .Nearest, MagFilter = .Nearest, MipmapFilter = .Nearest,
			AddressU = .ClampToEdge, AddressV = .ClampToEdge, AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(pointDesc) case .Ok(let sampler))
			mPointSampler = sampler;
		else
			return .Err;

		// Linear sampler (for history sampling)
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
		BufferDesc bufDesc = .()
		{
			Label = "TAA Params",
			Size = TAAParams.Size,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
			mParamsBuffer = buf;
		else
			return .Err;

		// Render pipeline - 2 color targets: chain output + history buffer
		ColorTargetState[2] colorTargets = .(
			.() { Format = .RGBA16Float },
			.() { Format = .RGBA16Float }
		);

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "TAA Resolve Pipeline",
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

	public override void AddPasses(RenderGraph graph, RenderView view, RenderContext renderContext, PostProcessContext ctx)
	{
		using (Profiler.Begin("TAA"))
		{

		// Ensure history textures match viewport size
		if (view.Width != mHistoryWidth || view.Height != mHistoryHeight)
			RecreateHistoryTextures(view.Width, view.Height);

		bool historyReady = true;
		for (int i = 0; i < TAAHistoryCount; i++)
			if (mHistoryTextures[i] == null) { historyReady = false; break; }

		if (!historyReady)
		{
			// Can't run TAA without history - pass through
			// The stack handles this: output = input when we don't write
			return;
		}

		// Current history = read, next in the ring = write target.
		// For TAAHistoryCount == 2 this is the classic ping-pong; modulo
		// arithmetic keeps the swap correct if the count is ever increased.
		let readIdx = mHistoryIndex;
		let writeIdx = (int32)((mHistoryIndex + 1) % TAAHistoryCount);

		let input = ctx.Input;
		let output = ctx.Output;
		let motionVectors = ctx.MotionVectors;
		let depth = ctx.SceneDepth;
		let prevDepth = ctx.PrevSceneDepth;

		// Upload params
		TAAParams @params = .()
		{
			TexelSizeX = 1.0f / Math.Max(view.Width, 1),
			TexelSizeY = 1.0f / Math.Max(view.Height, 1),
			BlendFactor = BlendFactor,
			HistoryValid = (mFrameCount > 0) ? 1.0f : 0.0f,
			JitterOffsetX = view.JitterOffset.X,
			JitterOffsetY = view.JitterOffset.Y,
			PrevJitterOffsetX = view.PrevJitterOffset.X,
			PrevJitterOffsetY = view.PrevJitterOffset.Y,
			NearPlane = view.NearPlane,
			FarPlane = view.FarPlane,
			// Same gate as HistoryValid: prev depth comes from the same
			// ping-pong, so it's only valid after the first frame.
			PrevDepthValid = (prevDepth.IsValid && mFrameCount > 0) ? 1.0f : 0.0f
		};
		TransferHelper.WriteMappedBuffer(mParamsBuffer, 0, Span<uint8>((uint8*)&@params, TAAParams.Size));

		// Import history textures into the render graph
		let historyReadHandle = graph.ImportTarget("TAA_HistoryRead", mHistoryTextures[readIdx], mHistoryViews[readIdx]);
		let historyWriteHandle = graph.ImportTarget("TAA_HistoryWrite", mHistoryTextures[writeIdx], mHistoryViews[writeIdx]);

		// TAA resolve outputs to both the post-process chain (target 0) and
		// the history buffer (target 1) in a single pass via MRT.
		graph.AddRenderPass("TAA Resolve", scope (builder) => {
			builder
				.ReadTexture(input);
			if (motionVectors.IsValid)
				builder.ReadTexture(motionVectors);
			if (depth.IsValid)
				builder.ReadTexture(depth);
			if (prevDepth.IsValid)
				builder.ReadTexture(prevDepth);
			builder
				.ReadTexture(historyReadHandle)
				.SetColorTarget(0, output, .DontCare, .Store)
				.SetColorTarget(1, historyWriteHandle, .DontCare, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					ExecuteTAA(encoder, view, graph, input, historyReadHandle, motionVectors, depth, prevDepth);
				});
		});

		mHistoryIndex = writeIdx;
		mFrameCount++;

		} // TAA profiler scope
	}

	private void ExecuteTAA(IRenderPassEncoder encoder, RenderView view, RenderGraph graph,
		RGHandle inputHandle, RGHandle historyHandle, RGHandle motionHandle, RGHandle depthHandle,
		RGHandle prevDepthHandle)
	{
		let inputView = graph.GetTextureView(inputHandle);
		let historyView = graph.GetTextureView(historyHandle);
		if (inputView == null || historyView == null)
			return;

		ITextureView motionView = motionHandle.IsValid ? graph.GetTextureView(motionHandle) : null;
		ITextureView depthView = depthHandle.IsValid ? graph.GetDepthOnlyTextureView(depthHandle) : null;
		ITextureView prevDepthView = prevDepthHandle.IsValid ? graph.GetDepthOnlyTextureView(prevDepthHandle) : null;

		// Use black texture fallback if motion/depth not available. PrevDepth
		// gets the same fallback - the shader gates on PrevDepthValid (0)
		// so the texture contents won't be sampled meaningfully.
		let blackTex = mRenderContext?.MaterialSystem?.BlackTexture;
		if (motionView == null) motionView = blackTex;
		if (depthView == null) depthView = blackTex;
		if (prevDepthView == null) prevDepthView = blackTex;
		if (motionView == null || depthView == null || prevDepthView == null)
			return;

		let frameSlot = view.FrameIndex % MaxFrames;

		if (mBindGroups[frameSlot] != null)
			mDevice.DestroyBindGroup(ref mBindGroups[frameSlot]);

		BindGroupEntry[8] bgEntries = .(
			BindGroupEntry.Buffer(mParamsBuffer, 0, TAAParams.Size),
			BindGroupEntry.Texture(inputView),
			BindGroupEntry.Texture(historyView),
			BindGroupEntry.Texture(motionView),
			BindGroupEntry.Texture(depthView),
			BindGroupEntry.Texture(prevDepthView),
			BindGroupEntry.Sampler(mPointSampler),
			BindGroupEntry.Sampler(mLinearSampler)
		);

		BindGroupDesc bgDesc = .() { Label = "TAA BindGroup", Layout = mBindGroupLayout, Entries = bgEntries };
		if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
			mBindGroups[frameSlot] = bg;

		if (mBindGroups[frameSlot] == null)
			return;

		encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0, 1);
		encoder.SetScissor(0, 0, view.Width, view.Height);
		encoder.SetPipeline(mPipeline);
		encoder.SetBindGroup(0, mBindGroups[frameSlot], default);
		encoder.Draw(3, 1, 0, 0);
	}

	private void RecreateHistoryTextures(uint32 width, uint32 height)
	{
		if (mDevice == null || width == 0 || height == 0) return;

		// Wait for GPU before destroying
		bool hasAny = false;
		for (int i = 0; i < TAAHistoryCount; i++)
			if (mHistoryTextures[i] != null) { hasAny = true; break; }
		if (hasAny)
			mDevice.WaitIdle();

		for (int i = 0; i < TAAHistoryCount; i++)
		{
			if (mHistoryViews[i] != null) mDevice.DestroyTextureView(ref mHistoryViews[i]);
			if (mHistoryTextures[i] != null) mDevice.DestroyTexture(ref mHistoryTextures[i]);

			TextureDesc texDesc = .()
			{
				Label = "TAA History",
				Width = width, Height = height, Depth = 1,
				Format = .RGBA16Float,
				Usage = .RenderTarget | .Sampled,
				Dimension = .Texture2D,
				MipLevelCount = 1, ArrayLayerCount = 1, SampleCount = 1
			};

			if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
				mHistoryTextures[i] = tex;

			if (mHistoryTextures[i] != null)
			{
				if (mDevice.CreateTextureView(mHistoryTextures[i], .() { Format = .RGBA16Float }) case .Ok(let view))
					mHistoryViews[i] = view;
			}
		}

		mHistoryWidth = width;
		mHistoryHeight = height;
		mFrameCount = 0;
		mHistoryIndex = 0;
	}

	public override void OnShutdown()
	{
		if (mDevice == null) return;

		bool hasAny = false;
		for (int i = 0; i < TAAHistoryCount; i++)
			if (mHistoryTextures[i] != null) { hasAny = true; break; }
		if (hasAny)
			mDevice.WaitIdle();

		for (int i = 0; i < MaxFrames; i++)
			if (mBindGroups[i] != null)
				mDevice.DestroyBindGroup(ref mBindGroups[i]);

		for (int i = 0; i < TAAHistoryCount; i++)
		{
			if (mHistoryViews[i] != null) mDevice.DestroyTextureView(ref mHistoryViews[i]);
			if (mHistoryTextures[i] != null) mDevice.DestroyTexture(ref mHistoryTextures[i]);
		}

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
		if (mPointSampler != null) mDevice.DestroySampler(ref mPointSampler);
		if (mLinearSampler != null) mDevice.DestroySampler(ref mLinearSampler);
		if (mParamsBuffer != null) mDevice.DestroyBuffer(ref mParamsBuffer);
	}

	[CRepr]
	private struct TAAParams
	{
		public float TexelSizeX;
		public float TexelSizeY;
		public float BlendFactor;
		public float HistoryValid;
		public float JitterOffsetX;
		public float JitterOffsetY;
		public float PrevJitterOffsetX;
		public float PrevJitterOffsetY;
		/// Camera near/far for linearizing depth in the disocclusion test.
		public float NearPlane;
		public float FarPlane;
		/// 1.0 if PrevSceneDepth is available this frame, 0.0 otherwise
		/// (e.g. very first frame after recreate). Gates the disocclusion
		/// test - without prev depth, fall back to UV-bounds rejection only.
		public float PrevDepthValid;
		public float _Pad0;
		public const uint64 Size = 48;
	}
}
