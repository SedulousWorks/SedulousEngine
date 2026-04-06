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
			Subresource = subresource
		};

		// Add access record based on load/store semantics
		if (loadOp == .Load && storeOp == .Store)
			mPass.Accesses.Add(.(handle, .ReadWriteDepthTarget, subresource));
		else if (storeOp == .Store)
			mPass.Accesses.Add(.(handle, .WriteDepthTarget, subresource));

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

	/// Set a runtime condition — pass is skipped if this returns false
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
