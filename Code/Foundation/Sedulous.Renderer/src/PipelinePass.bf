namespace Sedulous.Renderer;

using System;
using Sedulous.RenderGraph;

/// Base class for pipeline passes.
/// A pipeline pass adds one or more render graph nodes (render, compute, or copy)
/// during its AddPasses call. The render graph handles ordering, barriers, and
/// resource lifetime automatically based on declared resource access.
///
/// Examples:
///   - DepthPrepass: adds a render pass that writes SceneDepth
///   - ForwardOpaque: adds a render pass that reads SceneDepth, writes SceneColor
///   - GPUSkinning: adds a compute pass that reads bone buffers, writes skinned vertices
///   - ClusterCulling: adds a compute pass that reads lights, writes cluster grid
public abstract class PipelinePass
{
	/// Pass name (used for debug labels and identification).
	public abstract StringView Name { get; }

	/// Called once when the pass is added to the pipeline.
	/// Use this to create pipelines, bind group layouts, samplers, etc.
	public virtual Result<void> OnInitialize(Pipeline pipeline) { return .Ok; }

	/// Called when the pass is removed or the pipeline shuts down.
	/// Release GPU resources created in OnInitialize.
	public virtual void OnShutdown() { }

	/// Called when the output size changes.
	/// Recreate any size-dependent resources (render targets created outside the graph).
	public virtual void OnResize(uint32 width, uint32 height) { }

	/// Called each frame to add nodes to the render graph.
	/// Declare resources, add render/compute/copy passes, set execute callbacks.
	/// The render graph handles ordering based on resource dependencies.
	///
	/// @param graph The render graph to add nodes to.
	/// @param view The current view being rendered (camera, viewport, extracted data).
	/// @param pipeline The pipeline (access to GPUResources, PerFrameResources, Device).
	public abstract void AddPasses(Sedulous.RenderGraph.RenderGraph graph, RenderView view, Pipeline pipeline);
}
