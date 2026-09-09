using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// One pass: what it touches, what it attaches, what it depends on, and the body it records.
///
/// The pass OWNS its callbacks, which is what lets a builder hand one over and forget it.
class RenderGraphPass
{
	// ---- identity ----
	public String Name = new .() ~ delete _;
	public RGPassType Type;
	public QueueType QueueType = .Graphics;

	// ---- the declared work ----
	public List<RGResourceAccess> Accesses = new .() ~ delete _;
	public List<RGColorTarget> ColorTargets = new .() ~ delete _;
	public RGDepthTarget? DepthTarget = null;
	public List<PassHandle> Dependencies = new .() ~ delete _;

	// ---- an optional viewport override, otherwise the whole attachment is used ----
	public bool HasViewport = false;
	public int32 ViewportX = 0;
	public int32 ViewportY = 0;
	public uint32 ViewportWidth = 0;
	public uint32 ViewportHeight = 0;

	// ---- compile flags ----
	public bool IsCulled = false;
	public bool NeverCull = false;
	public bool HasSideEffects = false;
	/// An optional condition checked at execution time, so a pass can skip itself for a frame
	/// without being rebuilt out of the graph.
	public delegate bool() Condition = null ~ delete _;
	/// Assigned by the topological sort.
	public int32 ExecutionOrder = -1;

	// ---- the body, one of which is set per pass type ----
	public delegate void(IRenderPassEncoder) ExecuteCallback = null ~ delete _;
	/// A render pass whose body is RECORDED BUNDLES rather than commands, which is what lets
	/// several threads record one pass.
	public delegate void(ICommandEncoder, List<IRenderBundle>) BundleCallback = null ~ delete _;
	public delegate void(IComputePassEncoder) ComputeCallback = null ~ delete _;
	public delegate void(ICommandEncoder) CopyCallback = null ~ delete _;

	public this(StringView name, RGPassType type)
	{
		Name.Set(name);
		Type = type;
	}

	/// What this pass READS: its declared reads, plus every attachment it loads.
	///
	/// An attachment that loads is a read whether the pass said so or not, and the compiler
	/// reasons about accesses rather than about attachments.
	public void GetInputs(List<RGResourceAccess> outAccesses)
	{
		for (let access in Accesses)
		{
			if (access.IsRead)
				outAccesses.Add(access);
		}

		for (let target in ColorTargets)
		{
			if (target.LoadOp == .Load)
				outAccesses.Add(.(target.Handle, .ReadTexture, target.Subresource));
		}

		if (DepthTarget != null)
		{
			let depth = DepthTarget.Value;
			// Read only depth is a read even when it does not load: it is bound as an
			// attachment and sampled.
			if ((depth.DepthLoadOp == .Load) || depth.ReadOnly)
				outAccesses.Add(.(depth.Handle, .ReadDepthStencil, depth.Subresource));
		}
	}

	/// What this pass WRITES: its declared writes, plus every attachment it stores.
	public void GetOutputs(List<RGResourceAccess> outAccesses)
	{
		for (let access in Accesses)
		{
			if (access.IsWrite)
				outAccesses.Add(access);
		}

		for (let target in ColorTargets)
		{
			if (target.StoreOp == .Store)
				outAccesses.Add(.(target.Handle, .WriteColorTarget, target.Subresource));
		}

		if (DepthTarget != null)
		{
			let depth = DepthTarget.Value;
			if ((depth.DepthStoreOp == .Store) && !depth.ReadOnly)
				outAccesses.Add(.(depth.Handle, .WriteDepthTarget, depth.Subresource));
		}
	}

	/// Whether culling must keep this pass whatever the graph thinks of its outputs.
	public bool ShouldSurviveCulling => NeverCull || HasSideEffects;
}
