using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// The fluent builder a pass's setup is handed, to declare what it reads, what it writes, what
/// it attaches, and what it records.
///
/// Every method answers the builder, so a setup reads as one statement. The pass is BORROWED:
/// the graph owns it, and a builder lives only for the setup call.
class PassBuilder
{
	private RenderGraphPass mPass;

	public this(RenderGraphPass pass)
	{
		mPass = pass;
	}

	// ---- reads ----

	public PassBuilder ReadTexture(RGHandle handle, RGSubresourceRange subresource = .())
	{
		mPass.Accesses.Add(.(handle, .ReadTexture, subresource));
		return this;
	}

	/// Samples a DEPTH texture in this pass's shader, a shadow map being the obvious one.
	///
	/// A read and a barrier like any texture read, NOT a depth attachment, but the layout it
	/// transitions to is the depth read one a depth sampler demands rather than the ordinary
	/// shader read.
	public PassBuilder SampleDepth(RGHandle handle, RGSubresourceRange subresource = .())
	{
		mPass.Accesses.Add(.(handle, .SampleDepthStencil, subresource));
		return this;
	}

	/// Attaches depth READ ONLY: the pass tests against it and does not write it, which is
	/// what lets the same texture be sampled while it is attached.
	public PassBuilder ReadDepth(RGHandle handle, RGSubresourceRange subresource = .())
	{
		var target = RGDepthTarget();
		target.Handle = handle;
		target.DepthLoadOp = .Load;
		target.DepthStoreOp = .Store;
		target.ReadOnly = true;
		target.Subresource = subresource;
		mPass.DepthTarget = target;

		mPass.Accesses.Add(.(handle, .ReadDepthStencil, subresource));
		return this;
	}

	public PassBuilder ReadBuffer(RGHandle handle)
	{
		mPass.Accesses.Add(.(handle, .ReadBuffer, .()));
		return this;
	}

	// ---- render targets ----

	public PassBuilder SetColorTarget(int32 slot, RGHandle handle, LoadOp loadOp = .Clear,
		StoreOp storeOp = .Store, ClearColor clearValue = .Black,
		RGSubresourceRange subresource = .())
	{
		var target = RGColorTarget();
		target.Handle = handle;
		target.LoadOp = loadOp;
		target.StoreOp = storeOp;
		target.ClearValue = clearValue;
		target.Subresource = subresource;

		while ((int32)mPass.ColorTargets.Count <= slot)
			mPass.ColorTargets.Add(.());
		mPass.ColorTargets[slot] = target;

		// Loading AND storing is a read write, which the barrier solver treats as a hazard
		// with itself rather than a state that happens to already match.
		if ((loadOp == .Load) && (storeOp == .Store))
			mPass.Accesses.Add(.(handle, .ReadWriteColorTarget, subresource));
		else if (storeOp == .Store)
			mPass.Accesses.Add(.(handle, .WriteColorTarget, subresource));

		return this;
	}

	/// The hardware MSAA resolve for a colour slot: the slot's multisampled target resolves
	/// into a single sampled one as the pass ends.
	///
	/// The multisampled target's store becomes a DISCARD, since its samples are not wanted
	/// once resolved, and the resolve target is registered as a write so the graph allocates
	/// and transitions it. Called AFTER the slot's colour target, whose store it rewrites.
	public PassBuilder SetResolveTarget(int32 slot, RGHandle resolveHandle,
		RGSubresourceRange subresource = .())
	{
		while ((int32)mPass.ColorTargets.Count <= slot)
			mPass.ColorTargets.Add(.());

		var target = mPass.ColorTargets[slot];
		target.ResolveHandle = resolveHandle;
		target.StoreOp = .DontCare;
		mPass.ColorTargets[slot] = target;

		mPass.Accesses.Add(.(resolveHandle, .WriteColorTarget, subresource));
		return this;
	}

	public PassBuilder SetDepthTarget(RGHandle handle, LoadOp loadOp = .Clear,
		StoreOp storeOp = .Store, float clearDepth = Depth.ClearValue, RGSubresourceRange subresource = .(),
		LoadOp stencilLoadOp = .DontCare, StoreOp stencilStoreOp = .DontCare,
		uint32 clearStencil = 0)
	{
		var target = RGDepthTarget();
		target.Handle = handle;
		target.DepthLoadOp = loadOp;
		target.DepthStoreOp = storeOp;
		target.DepthClearValue = clearDepth;
		target.ReadOnly = false;
		target.StencilLoadOp = stencilLoadOp;
		target.StencilStoreOp = stencilStoreOp;
		target.StencilClearValue = clearStencil;
		target.Subresource = subresource;
		mPass.DepthTarget = target;

		if ((loadOp == .Load) && (storeOp == .Store))
		{
			mPass.Accesses.Add(.(handle, .ReadWriteDepthTarget, subresource));
			return this;
		}

		// ANY depth attachment that is not read only is a write, INCLUDING one that discards:
		// a scratch depth or stencil used only within the pass is still written. The access
		// is what keeps the transient referenced and therefore allocated, and what drives its
		// transition; without it the resource counts down to nothing, is never allocated, and
		// the pass is dropped at the null attachment guard.
		mPass.Accesses.Add(.(handle, .WriteDepthTarget, subresource));
		return this;
	}

	/// Depth tested but not written, which transitions to the depth read layout.
	public PassBuilder SetReadOnlyDepthTarget(RGHandle handle, RGSubresourceRange subresource = .())
	{
		var target = RGDepthTarget();
		target.Handle = handle;
		target.DepthLoadOp = .Load;
		target.DepthStoreOp = .Store;
		target.DepthClearValue = Depth.ClearValue;
		target.ReadOnly = true;
		target.Subresource = subresource;
		mPass.DepthTarget = target;

		mPass.Accesses.Add(.(handle, .ReadDepthStencil, subresource));
		return this;
	}

	// ---- storage ----

	public PassBuilder WriteStorage(RGHandle handle, RGSubresourceRange subresource = .())
	{
		mPass.Accesses.Add(.(handle, .WriteStorage, subresource));
		return this;
	}

	public PassBuilder ReadWriteStorage(RGHandle handle, RGSubresourceRange subresource = .())
	{
		mPass.Accesses.Add(.(handle, .ReadWriteStorage, subresource));
		return this;
	}

	// ---- copies ----

	public PassBuilder CopySrc(RGHandle handle)
	{
		mPass.Accesses.Add(.(handle, .ReadCopySrc, .()));
		return this;
	}

	public PassBuilder CopyDst(RGHandle handle)
	{
		mPass.Accesses.Add(.(handle, .WriteCopyDst, .()));
		return this;
	}

	// ---- dependencies and flags ----

	/// An EXPLICIT dependency, for an ordering the declared accesses do not already imply.
	public PassBuilder DependsOn(PassHandle pass)
	{
		mPass.Dependencies.Add(pass);
		return this;
	}

	/// Overrides the pass's viewport and scissor with a sub rectangle of the attachment,
	/// which is what a split screen needs. Without it a pass covers the whole attachment.
	public PassBuilder SetViewport(int32 x, int32 y, uint32 width, uint32 height)
	{
		mPass.HasViewport = true;
		mPass.ViewportX = x;
		mPass.ViewportY = y;
		mPass.ViewportWidth = width;
		mPass.ViewportHeight = height;
		return this;
	}

	/// Keeps the pass even when nothing reads what it wrote.
	public PassBuilder NeverCull()
	{
		mPass.NeverCull = true;
		return this;
	}

	/// Says the pass does something the graph cannot see, so culling must keep it.
	public PassBuilder HasSideEffects()
	{
		mPass.HasSideEffects = true;
		return this;
	}

	/// A condition checked at execution time. THE PASS TAKES OWNERSHIP of the delegate.
	public PassBuilder EnableIf(delegate bool() condition)
	{
		delete mPass.Condition;
		mPass.Condition = condition;
		return this;
	}

	// ---- the body ----

	/// THE PASS TAKES OWNERSHIP of the callback, which is what lets a caller hand one over
	/// and forget it.
	public PassBuilder SetExecute(delegate void(IRenderPassEncoder) callback)
	{
		delete mPass.ExecuteCallback;
		mPass.ExecuteCallback = callback;
		return this;
	}

	/// A render pass whose body is RECORDED BUNDLES, which is what lets several threads
	/// record one pass. The graph begins the pass expecting secondary buffers and replays
	/// the bundles in the order the callback filled them in.
	public PassBuilder SetBundleExecute(delegate void(ICommandEncoder, List<IRenderBundle>) callback)
	{
		delete mPass.BundleCallback;
		mPass.BundleCallback = callback;
		return this;
	}

	public PassBuilder SetComputeExecute(delegate void(IComputePassEncoder) callback)
	{
		delete mPass.ComputeCallback;
		mPass.ComputeCallback = callback;
		return this;
	}

	public PassBuilder SetCopyExecute(delegate void(ICommandEncoder) callback)
	{
		delete mPass.CopyCallback;
		mPass.CopyCallback = callback;
		return this;
	}
}
