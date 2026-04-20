using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A single pass in the render graph
public class RenderGraphPass
{
	/// Pass name (for debug labels and identification)
	public String Name ~ delete _;
	/// Pass type (Render, Compute, Copy)
	public RGPassType Type;
	/// Queue type (for future async compute support)
	public QueueType QueueType = .Graphics;

	/// All resource accesses declared by this pass
	public List<RGResourceAccess> Accesses = new .() ~ delete _;

	/// Color target attachments (for render passes)
	public List<RGColorTarget> ColorTargets = new .() ~ delete _;
	/// Depth/stencil target attachment (for render passes)
	public RGDepthTarget? DepthTarget;

	/// Explicit pass dependencies
	public List<PassHandle> Dependencies = new .() ~ delete _;

	/// Whether this pass was culled during compilation
	public bool IsCulled;
	/// If true, this pass is never culled (e.g., final output)
	public bool NeverCull;
	/// If true, this pass has side effects the graph cannot track
	public bool HasSideEffects;
	/// Optional runtime condition - pass is skipped if this returns false
	public delegate bool() Condition ~ delete _;
	/// Execution order assigned during topological sort (-1 = not scheduled)
	public int32 ExecutionOrder = -1;

	/// Typed callbacks for execution
	public RenderPassExecuteCallback ExecuteCallback ~ delete _;
	public ComputePassExecuteCallback ComputeCallback ~ delete _;
	public CopyPassExecuteCallback CopyCallback ~ delete _;

	public this(StringView name, RGPassType type)
	{
		Name = new String(name);
		Type = type;
	}

	/// Collect all resource handles that this pass reads from
	public void GetInputs(List<RGResourceAccess> outputs)
	{
		for (let access in Accesses)
		{
			if (access.IsRead)
				outputs.Add(access);
		}

		// Color attachments with Load = read input
		for (let ct in ColorTargets)
		{
			if (ct.LoadOp == .Load)
				outputs.Add(.(ct.Handle, .ReadTexture, ct.Subresource));
		}

		// Depth with Load = read input
		if (DepthTarget.HasValue)
		{
			let dt = DepthTarget.Value;
			if (dt.DepthLoadOp == .Load || dt.ReadOnly)
				outputs.Add(.(dt.Handle, .ReadDepthStencil, dt.Subresource));
		}
	}

	/// Collect all resource handles that this pass writes to
	public void GetOutputs(List<RGResourceAccess> outputs)
	{
		for (let access in Accesses)
		{
			if (access.IsWrite)
				outputs.Add(access);
		}

		// Color attachments with Store = write output
		for (let ct in ColorTargets)
		{
			if (ct.StoreOp == .Store)
				outputs.Add(.(ct.Handle, .WriteColorTarget, ct.Subresource));
		}

		// Depth with Store = write output
		if (DepthTarget.HasValue)
		{
			let dt = DepthTarget.Value;
			if (dt.DepthStoreOp == .Store && !dt.ReadOnly)
				outputs.Add(.(dt.Handle, .WriteDepthTarget, dt.Subresource));
		}
	}

	/// Whether this pass should survive culling
	public bool ShouldSurviveCulling => NeverCull || HasSideEffects;
}
