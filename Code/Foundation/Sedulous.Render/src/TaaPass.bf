using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Temporal antialiasing: this frame's jittered image blended with the accumulated history,
/// reprojected through the motion vectors.
///
/// Each view keeps a PING PONG pair of history targets: the resolve reads one and writes the
/// other, because a target cannot be both at once.
class TaaPass
{
	public const TextureFormat HistoryFormat = .RGBA16Float;
	public const int MaxViews = 8;

	/// One view's pair, and which of them is next to be written.
	private struct ViewHistory
	{
		public ITexture[2] Textures;
		public ITextureView[2] Views;
		public ResourceState[2] States;
		public uint32 Width;
		public uint32 Height;
		public uint32 Current;
		/// False until something has been accumulated, and again after a resize.
		public bool Valid;
	}

	private struct Entry
	{
		public IBindGroup BindGroup;
		public ITextureView Current;
		public uint64 Generation;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private uint64 mPipelineShaderVersion = 0;

	private ISampler mPointSampler = null;
	private ISampler mLinearSampler = null;

	private ViewHistory[MaxViews] mViews = .();
	/// Keyed by the history view being READ: it is stable for a given size, so this rebuilds
	/// only on a resize.
	private Dictionary<int, Entry> mBindGroups = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaders)
	{
		mDevice = device;
		mShaders = shaders;
	}

	public ~this()
	{
		Shutdown();
	}

	public TextureFormat Format => HistoryFormat;

	public Result<void> Initialize()
	{
		var entries = BindGroupLayoutEntry[6](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment),
			BindGroupLayoutEntry.Sampler(1, .Fragment));

		// The depth is read through the POINT sampler only, and a depth format may not be
		// declared filterable. One backend ignores the annotation; another rejects the pair.
		entries[3].TextureSampleType = .UnfilterableFloat;
		entries[4].SamplerNonFiltering = true;

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 6);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = sizeof(TaaPush);

		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		pipelineLayoutDesc.PushConstantRanges = .(&pushRange, 1);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		if (!(MakeSampler(.Nearest) case .Ok(let point)))
			return .Err;
		mPointSampler = point;
		if (!(MakeSampler(.Linear) case .Ok(let linear)))
			return .Err;
		mLinearSampler = linear;

		mPipeline = MakePipeline();
		if (mPipeline == null)
			return .Err;

		return .Ok;
	}

	/// Resolves one view: reads this frame's jittered image, the previous history, the motion
	/// and the depth; writes the resolved image and the next frame's history.
	///
	/// The input comes back unchanged when the view cannot be resolved, so the frame carries
	/// on with an aliased image rather than a missing one.
	public RGHandle DeclareTaa(RenderGraph graph, RGHandle current, RGHandle motion,
		RGHandle depth, uint32 viewIndex, uint32 width, uint32 height, float blendFactor,
		float varianceGamma, float motionScale, float nearPlane, float farPlane)
	{
		if ((viewIndex >= MaxViews) || (width == 0) || (height == 0))
			return current;

		let shaderVersion = mShaders.Version("taa");
		if (shaderVersion != mPipelineShaderVersion)
		{
			if (mPipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipeline);

			mPipeline = MakePipeline();
			mPipelineShaderVersion = shaderVersion;
		}

		if (mPipeline == null)
			return current;

		if (!EnsureHistory(ref mViews[viewIndex], width, height))
			return current;

		let currentSlot = mViews[viewIndex].Current;
		let previousSlot = currentSlot ^ 1;

		let resolved = graph.CreateTransient("taa.resolved", .(HistoryFormat, width, height));

		let historyPrevious = graph.ImportTarget("taa.histPrev",
			mViews[viewIndex].Textures[previousSlot], mViews[viewIndex].Views[previousSlot],
			ResourceState.ShaderRead, mViews[viewIndex].States[previousSlot]);
		mViews[viewIndex].States[previousSlot] = .ShaderRead;

		let historyCurrent = graph.ImportTarget("taa.histCur",
			mViews[viewIndex].Textures[currentSlot], mViews[viewIndex].Views[currentSlot],
			ResourceState.RenderTarget, mViews[viewIndex].States[currentSlot]);
		mViews[viewIndex].States[currentSlot] = .RenderTarget;

		var push = TaaPush();
		push.TexelSize = .(1.0f / (float)width, 1.0f / (float)height);
		push.BlendFactor = blendFactor;
		push.HistoryValid = mViews[viewIndex].Valid ? 1.0f : 0.0f;
		push.VarianceGamma = varianceGamma;
		push.MotionScale = motionScale;
		push.NearPlane = nearPlane;
		push.FarPlane = (farPlane > nearPlane) ? farPlane : 1000.0f;

		let previousView = mViews[viewIndex].Views[previousSlot];

		graph.AddRenderPass("taa", scope (builder) =>
			{
				builder.SetColorTarget(0, resolved, .Clear, .Store, .Black);
				builder.SetColorTarget(1, historyCurrent, .Clear, .Store, .Black);

				builder.ReadTexture(current);
				// Last frame's history, which orders this after whatever wrote it.
				builder.ReadTexture(historyPrevious);
				builder.ReadTexture(motion);
				builder.ReadTexture(depth);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(current),
							previousView, graph.GetTextureView(motion), graph.GetTextureView(depth),
							graph.GetTextureGeneration(current));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mPipeline);
						encoder.SetBindGroup(0, bindGroup);

						var constants = push;
						encoder.SetPushConstants(.Fragment, 0, sizeof(TaaPush), &constants);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		// What was written this frame is what the next one reads.
		mViews[viewIndex].Current = previousSlot;
		mViews[viewIndex].Valid = true;
		return resolved;
	}

	private Result<ISampler> MakeSampler(FilterMode filter)
	{
		var desc = SamplerDesc();
		desc.MinFilter = filter;
		desc.MagFilter = filter;
		desc.MipmapFilter = (filter == .Nearest) ? .Nearest : .Linear;
		desc.AddressU = .ClampToEdge;
		desc.AddressV = .ClampToEdge;
		desc.AddressW = .ClampToEdge;

		if (!(mDevice.CreateSampler(desc) case .Ok(let sampler)))
			return .Err;
		return .Ok(sampler);
	}

	/// A view's pair of history targets, recreated when the size changes.
	private bool EnsureHistory(ref ViewHistory history, uint32 width, uint32 height)
	{
		if ((history.Textures[0] != null) && (history.Width == width) && (history.Height == height))
			return true;

		DestroyHistory(ref history);

		for (int i < 2)
		{
			var textureDesc = TextureDesc();
			textureDesc.Format = HistoryFormat;
			textureDesc.Width = width;
			textureDesc.Height = height;
			textureDesc.Usage = .RenderTarget | .Sampled;
			textureDesc.Label = "taa.history";

			if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			{
				DestroyHistory(ref history);
				return false;
			}
			history.Textures[i] = texture;

			var viewDesc = TextureViewDesc();
			viewDesc.Format = HistoryFormat;
			viewDesc.Dimension = .Texture2D;

			if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			{
				DestroyHistory(ref history);
				return false;
			}
			history.Views[i] = view;
			history.States[i] = .Undefined;
		}

		history.Width = width;
		history.Height = height;
		history.Current = 0;
		// The size changed, so what was accumulated describes a different image.
		history.Valid = false;
		return true;
	}

	private void DestroyHistory(ref ViewHistory history)
	{
		for (int i < 2)
		{
			if (history.Views[i] != null)
				mDevice.DestroyTextureView(ref history.Views[i]);
			if (history.Textures[i] != null)
				mDevice.DestroyTexture(ref history.Textures[i]);
		}

		history.Width = 0;
		history.Height = 0;
		history.Valid = false;
	}

	private IRenderPipeline MakePipeline()
	{
		let vertex = mShaders.GetVariant("taa", .Vertex, .None);
		let fragment = mShaders.GetVariant("taa", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		// The resolved image and the history it becomes, written in one pass.
		var targets = ColorTargetState[2]();
		targets[0].Format = HistoryFormat;
		targets[1].Format = HistoryFormat;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&targets[0], 2);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "taa";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		return pipeline;
	}

	private IBindGroup EnsureBindGroup(ITextureView current, ITextureView historyPrevious,
		ITextureView motion, ITextureView depth, uint64 generation)
	{
		if ((current == null) || (historyPrevious == null) || (motion == null) || (depth == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(historyPrevious);
		if (mBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.Current == current)
				&& (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mDevice.DestroyBindGroup(ref existing.BindGroup);
		}

		var entries = BindGroupEntry[6](
			BindGroupEntry.TextureEntry(current),
			BindGroupEntry.TextureEntry(historyPrevious),
			BindGroupEntry.TextureEntry(motion),
			BindGroupEntry.TextureEntry(depth),
			BindGroupEntry.SamplerEntry(mPointSampler),
			BindGroupEntry.SamplerEntry(mLinearSampler));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 6);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[key] = .() { BindGroup = bindGroup, Current = current, Generation = generation };
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (var entry in ref mBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mBindGroups.Clear();

		for (int i < MaxViews)
			DestroyHistory(ref mViews[i]);

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mPointSampler != null)
			mDevice.DestroySampler(ref mPointSampler);
		if (mLinearSampler != null)
			mDevice.DestroySampler(ref mLinearSampler);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
