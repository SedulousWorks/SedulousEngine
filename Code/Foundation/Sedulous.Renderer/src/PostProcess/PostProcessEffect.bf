namespace Sedulous.Renderer;

using System;
using Sedulous.RenderGraph;

/// Base class for post-process effects.
/// Each effect adds one or more render graph passes that read from ctx.Input
/// and write to ctx.Output. Effects can also produce auxiliary textures
/// for downstream effects (e.g., bloom produces a texture consumed by tonemap).
///
/// Effects hold GPU state (shaders, constant buffers) and are built once.
/// Parameters are updated per-frame via public properties.
abstract class PostProcessEffect
{
	/// Effect name (used for debug labels and profiling).
	public abstract StringView Name { get; }

	/// Whether this effect is active. Disabled effects are skipped.
	public bool Enabled = true;

	/// Called once when the effect is added to the stack.
	/// Create GPU resources (shaders, samplers, constant buffers) here.
	public virtual Result<void> OnInitialize(RenderContext renderContext) { return .Ok; }

	/// Called when the effect is removed or the stack is destroyed.
	/// Release GPU resources created in OnInitialize.
	public virtual void OnShutdown() { }

	/// Declare any auxiliary textures this effect produces.
	/// Called before AddPasses so downstream effects can reference them via ctx.GetAux().
	public virtual void DeclareOutputs(RenderGraph graph, PostProcessContext ctx) { }

	/// Add render graph passes for this effect.
	/// Read from ctx.Input, write to ctx.Output.
	public abstract void AddPasses(RenderGraph graph, RenderView view, RenderContext renderContext, PostProcessContext ctx);
}
