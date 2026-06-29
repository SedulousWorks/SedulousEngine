using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Fluent builder for configuring a render graph pass.
/// Passed to the setup callback of AddRenderPass/AddComputePass/AddCopyPass.
public struct PassBuilder
{
	private RenderGraphPass mPass;

	public this(RenderGraphPass pass)
	{
		mPass = pass;
	}

	// === Texture reads ===

	/// Declare a texture read (sampled in shader)
	public Self ReadTexture(RGHandle handle, RGSubresourceRange subresource = default) mut
	{
		mPass.Accesses.Add(.(handle, .ReadTexture, subresource));
		return this;
	}

	/// Declare a depth/stencil read-only access (sampled in shader)
	public Self ReadDepth(RGHandle handle, RGSubresourceRange subresource = default) mut
	{
		mPass.DepthTarget = RGDepthTarget(handle)
		{
			DepthLoadOp = .Load,
			DepthStoreOp = .Store,
			ReadOnly = true,
			Subresource = subresource
		};
		mPass.Accesses.Add(.(handle, .ReadDepthStencil, subresource));
		return this;
	}

	// === Buffer reads ===

	/// Declare a buffer read (uniform or storage)
	public Self ReadBuffer(RGHandle handle) mut
	{
		mPass.Accesses.Add(.(handle, .ReadBuffer));
		return this;
	}

	// === Render targets ===

	/// Set a color target for this render pass
	public Self SetColorTarget(int32 slot, RGHandle handle, LoadOp loadOp = .Clear, StoreOp storeOp = .Store, ClearColor clearValue = .Black, RGSubresourceRange subresource = default) mut
	{
		let target = RGColorTarget(handle, loadOp, storeOp, clearValue, subresource);

		// Ensure list is big enough
		while (mPass.ColorTargets.Count <= slot)
			mPass.ColorTargets.Add(default);
		mPass.ColorTargets[slot] = target;

		// Add access record based on load/store semantics
		if (loadOp == .Load && storeOp == .Store)
			mPass.Accesses.Add(.(handle, .ReadWriteColorTarget, subresource));
		else if (storeOp == .Store)
			mPass.Accesses.Add(.(handle, .WriteColorTarget, subresource));

		return this;
	}

	/// Set the depth/stencil target for this render pass
	public Self SetDepthTarget(RGHandle handle, LoadOp loadOp = .Clear, StoreOp storeOp = .Store, float clearDepth = 1.0f, RGSubresourceRange subresource = default) mut
	{
		mPass.DepthTarget = RGDepthTarget(handle)
		{
			DepthLoadOp = loadOp,
			DepthStoreOp = storeOp,
			DepthClearValue = clearDepth,
			ReadOnly = false,
			// Stencil is DontCare by default — the engine doesn't use stencil
			// in any depth pass. This avoids ClearDepthStencilView including the
			// stencil flag, which would require the stencil plane to be in
			// DEPTH_WRITE state on D3D12.
			StencilLoadOp = .DontCare,
			StencilStoreOp = .DontCare,
			Subresource = subresource
		};

		// Add access record based on load/store semantics
		if (loadOp == .Load && storeOp == .Store)
			mPass.Accesses.Add(.(handle, .ReadWriteDepthTarget, subresource));
		else if (storeOp == .Store)
			mPass.Accesses.Add(.(handle, .WriteDepthTarget, subresource));

		return this;
	}

	/// Set a read-only depth target (depth test without write).
	/// Use this instead of SetDepthTarget when the pipeline state has DepthWriteEnabled=false.
	/// This transitions to DepthStencilRead (D3D12: DEPTH_READ) which prevents D3D12's
	/// implicit state promotion from desynchronizing barrier tracking.
	public Self SetReadOnlyDepthTarget(RGHandle handle, RGSubresourceRange subresource = default) mut
	{
		mPass.DepthTarget = RGDepthTarget(handle)
		{
			DepthLoadOp = .Load,
			DepthStoreOp = .Store,
			DepthClearValue = 1.0f,
			ReadOnly = true,
			Subresource = subresource
		};

		mPass.Accesses.Add(.(handle, .ReadDepthStencil, subresource));

		return this;
	}

	// === Storage (UAV) ===

	/// Declare a storage (UAV) write
	public Self WriteStorage(RGHandle handle, RGSubresourceRange subresource = default) mut
	{
		mPass.Accesses.Add(.(handle, .WriteStorage, subresource));
		return this;
	}

	/// Declare a storage (UAV) simultaneous read+write
	public Self ReadWriteStorage(RGHandle handle, RGSubresourceRange subresource = default) mut
	{
		mPass.Accesses.Add(.(handle, .ReadWriteStorage, subresource));
		return this;
	}

	// === Copy ===

	/// Declare a copy source
	public Self CopySrc(RGHandle handle) mut
	{
		mPass.Accesses.Add(.(handle, .ReadCopySrc));
		return this;
	}

	/// Declare a copy destination
	public Self CopyDst(RGHandle handle) mut
	{
		mPass.Accesses.Add(.(handle, .WriteCopyDst));
		return this;
	}

	// === Viewport ===

	/// Override the pass's viewport + scissor (a sub-rect of the attachment, e.g. split-screen).
	/// Without it the pass covers the full attachment.
	public Self SetViewport(int32 x, int32 y, uint32 w, uint32 h) mut
	{
		mPass.HasViewport = true;
		mPass.ViewportX = x;
		mPass.ViewportY = y;
		mPass.ViewportW = w;
		mPass.ViewportH = h;
		return this;
	}

	// === Dependencies ===

	/// Add an explicit dependency on another pass
	public Self DependsOn(PassHandle pass) mut
	{
		mPass.Dependencies.Add(pass);
		return this;
	}

	// === Flags ===

	/// Mark this pass as never-cullable (e.g., final output)
	public Self NeverCull() mut
	{
		mPass.NeverCull = true;
		return this;
	}

	/// Mark this pass as having side effects the graph cannot track
	public Self HasSideEffects() mut
	{
		mPass.HasSideEffects = true;
		return this;
	}

	/// Set a runtime condition - pass is skipped if this returns false
	public Self EnableIf(delegate bool() condition) mut
	{
		mPass.Condition = condition;
		return this;
	}

	// === Execute callbacks ===

	/// Set the render pass execute callback
	public Self SetExecute(RenderPassExecuteCallback callback) mut
	{
		mPass.ExecuteCallback = callback;
		return this;
	}

	/// Set the bundle pass execute callback (parallel command recording).
	/// The callback receives the command encoder (still recording, before
	/// BeginRenderPass) and fills the out-list with finished bundles.
	public Self SetBundleExecute(RenderBundlePassCallback callback) mut
	{
		mPass.BundleCallback = callback;
		return this;
	}

	/// Set the compute pass execute callback
	public Self SetComputeExecute(ComputePassExecuteCallback callback) mut
	{
		mPass.ComputeCallback = callback;
		return this;
	}

	/// Set the copy pass execute callback
	public Self SetCopyExecute(CopyPassExecuteCallback callback) mut
	{
		mPass.CopyCallback = callback;
		return this;
	}
}
