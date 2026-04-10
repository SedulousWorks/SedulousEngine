namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

/// Ordered chain of post-process effects.
/// Owned by Pipeline (per-view). Chains effects by creating transient intermediates
/// in the render graph. All resources are render-graph managed.
///
/// When the stack has active effects:
///   Scene passes write to "SceneHDR" (transient)
///   Effects chain: SceneHDR → [effect0] → [effect1] → ... → PipelineOutput
///
/// When the stack is empty or all effects disabled:
///   Scene passes write directly to "PipelineOutput" (no intermediates)
class PostProcessStack
{
	private List<PostProcessEffect> mEffects = new .() ~ DeleteContainerAndItems!(_);
	private PostProcessContext mContext = new .() ~ delete _;
	private RenderContext mRenderContext;

	/// Whether any effects are enabled.
	public bool HasActiveEffects
	{
		get
		{
			for (let effect in mEffects)
				if (effect.Enabled) return true;
			return false;
		}
	}

	/// Initializes the stack with a reference to the shared renderer.
	public void Initialize(RenderContext renderContext)
	{
		mRenderContext = renderContext;
	}

	/// Adds an effect to the end of the chain. Takes ownership.
	public Result<void> AddEffect(PostProcessEffect effect)
	{
		if (effect.OnInitialize(mRenderContext) case .Err)
			return .Err;

		mEffects.Add(effect);
		return .Ok;
	}

	/// Gets an effect by type.
	public T GetEffect<T>() where T : PostProcessEffect
	{
		for (let effect in mEffects)
		{
			if (let typed = effect as T)
				return typed;
		}
		return null;
	}

	/// Executes the post-process chain by emitting render graph passes.
	/// Returns the handle to the final output.
	///
	/// @param sceneColor The HDR scene color from scene passes ("SceneHDR").
	/// @param sceneDepth The scene depth buffer (for depth-aware effects).
	/// @param pipelineOutput The final pipeline output handle to write to.
	public void Execute(RenderGraph graph, RenderView view,
		RGHandle sceneColor, RGHandle sceneDepth, RGHandle pipelineOutput)
	{
		mContext.Clear();
		mContext.SceneDepth = sceneDepth;

		// Count active effects
		int activeCount = 0;
		for (let effect in mEffects)
			if (effect.Enabled) activeCount++;

		if (activeCount == 0)
			return;

		// Let effects declare auxiliary outputs
		for (let effect in mEffects)
		{
			if (!effect.Enabled) continue;
			effect.DeclareOutputs(graph, mContext);
		}

		// Chain effects
		var currentInput = sceneColor;
		int activeIndex = 0;

		for (let effect in mEffects)
		{
			if (!effect.Enabled) continue;
			activeIndex++;

			mContext.Input = currentInput;

			// Last active effect writes to PipelineOutput
			if (activeIndex == activeCount)
			{
				mContext.Output = pipelineOutput;
			}
			else
			{
				// Create transient intermediate
				let desc = RGTextureDesc(.RGBA16Float) { Usage = .RenderTarget | .Sampled };
				mContext.Output = graph.CreateTransient(scope $"PostFX_{effect.Name}", desc);
			}

			effect.AddPasses(graph, view, mRenderContext, mContext);

			currentInput = mContext.Output;
		}
	}

	/// Shuts down all effects and releases resources.
	public void Shutdown()
	{
		for (let effect in mEffects)
			effect.OnShutdown();
	}
}
