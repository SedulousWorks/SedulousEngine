using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

using static Sedulous.RHI.TextureFormatExt;

/// The render graph orchestrator.
/// All GPU work is declared as passes with resource accesses.
/// The graph compiles dependencies, culls unused work, inserts barriers,
/// and executes everything in a single Execute(encoder) call.
public class RenderGraph
{
	private IDevice mDevice;
	private RenderGraphConfig mConfig;

	// Resources
	private List<RenderGraphResource> mResources = new .() ~ {
		for (let r in _) delete r;
		delete _;
	};
	private List<int32> mFreeResourceSlots = new .() ~ delete _;

	// Passes
	private List<RenderGraphPass> mPasses = new .() ~ {
		for (let p in _) delete p;
		delete _;
	};

	// Compiled execution order
	private List<int32> mExecutionOrder = new .() ~ delete _;
	private bool mIsCompiled;

	// Barrier solver
	private BarrierSolver mBarrierSolver = new .() ~ delete _;

	// Transient texture pool
	private TransientTexturePool mTexturePool ~ delete _;

	// Deferred deletion queues (per frame slot)
	private List<List<DeferredDeletion>> mDeferredDeletions ~ {
		for (let list in _) { for (let d in list) d.Execute(mDevice); delete list; }
		delete _;
	};

	// Frame tracking
	private int32 mFrameIndex;
	private uint32 mOutputWidth = 1920;
	private uint32 mOutputHeight = 1080;

	struct DeferredDeletion
	{
		public ITexture Texture;
		public ITextureView View;
		public ITextureView View2;
		public IBuffer Buffer;

		public void Execute(IDevice device)
		{
			var tex = Texture;
			var view = View;
			var view2 = View2;
			var buf = Buffer;
			if (view2 != null) device.DestroyTextureView(ref view2);
			if (view != null) device.DestroyTextureView(ref view);
			if (tex != null) device.DestroyTexture(ref tex);
			if (buf != null) device.DestroyBuffer(ref buf);
		}
	}

	public this(IDevice device, RenderGraphConfig config = .())
	{
		mDevice = device;
		mConfig = config;

		if (device != null)
			mTexturePool = new TransientTexturePool(device);

		mDeferredDeletions = new .();
		for (int i = 0; i < config.FrameBufferCount; i++)
			mDeferredDeletions.Add(new List<DeferredDeletion>());
	}

	// === Output dimensions ===

	/// Set output dimensions for SizeMode resolution
	public void SetOutputSize(uint32 width, uint32 height)
	{
		mOutputWidth = width;
		mOutputHeight = height;
	}

	public uint32 OutputWidth => mOutputWidth;
	public uint32 OutputHeight => mOutputHeight;

	// === Frame lifecycle ===

	/// Begin a new frame. Flushes deferred deletions for this frame slot.
	public void BeginFrame(int32 frameIndex)
	{
		mFrameIndex = frameIndex;
		let slotIndex = frameIndex % (int32)mDeferredDeletions.Count;

		// Flush deferred deletions for this slot (GPU has finished with these by now)
		let deletions = mDeferredDeletions[slotIndex];
		for (let d in deletions)
			d.Execute(mDevice);
		deletions.Clear();

		// Clear passes from previous frame
		ClearPasses();

		// Remove transient and imported resources from previous frame (keep persistent)
		for (int i = 0; i < mResources.Count; i++)
		{
			let res = mResources[i];
			if (res == null) continue;

			if (res.Lifetime != .Persistent)
			{
				mFreeResourceSlots.Add((int32)i);
				delete res;
				mResources[i] = null;
			}
			else
			{
				res.ResetTracking();
			}
		}

		mIsCompiled = false;
	}

	/// Compile the graph: build dependencies, cull, sort, allocate.
	/// Can be called without an encoder for testing graph logic.
	public Result<void> Compile()
	{
		if (mPasses.Count == 0)
			return .Ok;

		BuildResourceReferences();
		CullPasses();
		BuildDependencies();
		if (TopologicalSort() case .Err)
			return .Err;
		AllocateTransientResources();

		mIsCompiled = true;
		return .Ok;
	}

	/// Compile and execute all passes into the provided command encoder.
	public Result<void> Execute(ICommandEncoder encoder)
	{
		if (!mIsCompiled)
		{
			if (Compile() case .Err)
				return .Err;
		}

		if (encoder == null)
			return .Ok; // Compile-only mode (for tests)

		// --- Execute ---
		mBarrierSolver.Reset(mResources);

		for (let passIdx in mExecutionOrder)
		{
			let pass = mPasses[passIdx];
			if (pass.IsCulled)
				continue;

			// Runtime conditional skip
			if (pass.Condition != null && !pass.Condition())
				continue;

			// Debug label
			encoder.BeginDebugLabel(pass.Name);

			// Emit barriers
			mBarrierSolver.EmitBarriers(pass, mResources, encoder);

			// Execute pass
			switch (pass.Type)
			{
			case .Render:
				ExecuteRenderPass(pass, encoder);
			case .Compute:
				ExecuteComputePass(pass, encoder);
			case .Copy:
				ExecuteCopyPass(pass, encoder);
			}

			// Transition ReadableAfterWrite resources to ShaderRead after the pass
			mBarrierSolver.EmitReadableAfterWriteBarriers(pass, mResources, encoder);

			encoder.EndDebugLabel();
		}

		// Final-state transitions (e.g., Present for swapchain)
		mBarrierSolver.EmitFinalTransitions(mResources, encoder);

		// Update persistent resource states
		mBarrierSolver.UpdatePersistentStates(mResources);

		// Return transient resources to pool
		ReturnTransientResources();

		return .Ok;
	}

	/// End the current frame
	public void EndFrame()
	{
		mIsCompiled = false;

		if (mTexturePool != null)
			mTexturePool.EndFrame();
	}

	/// Reset for multi-view rendering: clears passes but keeps persistent resource state
	public void Reset()
	{
		// Defer-delete transient resources before clearing
		ReturnTransientResources();
		ClearPasses();

		// Remove transient and imported resources, keep persistent
		for (int i = 0; i < mResources.Count; i++)
		{
			let res = mResources[i];
			if (res == null) continue;

			if (res.Lifetime != .Persistent)
			{
				mFreeResourceSlots.Add((int32)i);
				delete res;
				mResources[i] = null;
			}
			else
			{
				res.ResetTracking();
			}
		}

		mIsCompiled = false;
	}

	// === Resource creation ===

	/// Create a transient texture (per-frame, pooled)
	public RGHandle CreateTransient(StringView name, RGTextureDesc desc)
	{
		let res = new RenderGraphResource(name, .Texture, .Transient);
		var resolvedDesc = desc;
		resolvedDesc.Resolve(mOutputWidth, mOutputHeight);
		res.TextureDesc = resolvedDesc;
		return AddResource(res);
	}

	/// Create a transient buffer (per-frame)
	public RGHandle CreateTransientBuffer(StringView name, RGBufferDesc desc)
	{
		let res = new RenderGraphResource(name, .Buffer, .Transient);
		res.BufferDesc = desc;
		return AddResource(res);
	}

	/// Register a persistent texture (survives across frames)
	public RGHandle RegisterPersistent(StringView name, ITexture texture, ITextureView view)
	{
		let res = new RenderGraphResource(name, .Texture, .Persistent);
		res.Texture = texture;
		res.TextureView = view;
		let persistent = new PersistentResource(texture, view);
		res.PersistentData = persistent;
		return AddResource(res);
	}

	/// Register a ping-pong persistent texture pair (double-buffered, survives across frames)
	public RGHandle RegisterPersistentPingPong(StringView name, ITexture tex0, ITexture tex1, ITextureView view0, ITextureView view1)
	{
		let res = new RenderGraphResource(name, .Texture, .Persistent);
		res.Texture = tex0;
		res.TextureView = view0;
		let persistent = new PersistentResource(tex0, tex1, view0, view1);
		res.PersistentData = persistent;
		return AddResource(res);
	}

	/// Import an external texture for this frame (not owned by graph)
	public RGHandle ImportTarget(StringView name, ITexture texture, ITextureView view, ResourceState? finalState = null)
	{
		let res = new RenderGraphResource(name, .Texture, .Imported);
		res.Texture = texture;
		res.TextureView = view;
		res.FinalState = finalState;
		// Imported resources start in their current state
		res.LastKnownState = texture != null ? texture.InitialState : .Undefined;
		return AddResource(res);
	}

	/// Import an external buffer for this frame (not owned by graph)
	public RGHandle ImportBuffer(StringView name, IBuffer buffer)
	{
		let res = new RenderGraphResource(name, .Buffer, .Imported);
		res.Buffer = buffer;
		return AddResource(res);
	}

	/// Marks a resource to be transitioned to ShaderRead after the last pass that writes to it.
	/// Use for resources that will be sampled through bind groups created outside the graph
	/// (e.g., render-to-texture that a sprite feature samples without declaring ReadTexture).
	public void RequireReadableAfterWrite(RGHandle handle)
	{
		if (!handle.IsValid || handle.Index >= (uint32)mResources.Count)
			return;
		let res = mResources[handle.Index];
		if (res != null)
			res.ReadableAfterWrite = true;
	}

	// === Pass creation ===

	/// Add a render pass (draw commands)
	public PassHandle AddRenderPass(StringView name, delegate void(ref PassBuilder) setup)
	{
		let pass = new RenderGraphPass(name, .Render);
		var builder = PassBuilder(pass);
		setup(ref builder);
		return AddPass(pass);
	}

	/// Add a compute pass (dispatch commands)
	public PassHandle AddComputePass(StringView name, delegate void(ref PassBuilder) setup)
	{
		let pass = new RenderGraphPass(name, .Compute);
		var builder = PassBuilder(pass);
		setup(ref builder);
		return AddPass(pass);
	}

	/// Add a copy pass (transfer commands)
	public PassHandle AddCopyPass(StringView name, delegate void(ref PassBuilder) setup)
	{
		let pass = new RenderGraphPass(name, .Copy);
		var builder = PassBuilder(pass);
		setup(ref builder);
		return AddPass(pass);
	}

	// === Resource access (during execute callbacks) ===

	/// Get the GPU texture for a resource handle
	public ITexture GetTexture(RGHandle handle)
	{
		if (!handle.IsValid || handle.Index >= (uint32)mResources.Count)
			return null;
		let res = mResources[handle.Index];
		if (res == null || res.Generation != handle.Generation)
			return null;
		if (res.PersistentData != null)
			return res.PersistentData.Texture;
		return res.Texture;
	}

	/// Get the GPU texture view for a resource handle
	public ITextureView GetTextureView(RGHandle handle)
	{
		if (!handle.IsValid || handle.Index >= (uint32)mResources.Count)
			return null;
		let res = mResources[handle.Index];
		if (res == null || res.Generation != handle.Generation)
			return null;
		if (res.PersistentData != null)
			return res.PersistentData.TextureView;
		return res.TextureView;
	}

	/// Get the depth-only texture view for a depth/stencil resource (for shader sampling).
	public ITextureView GetDepthOnlyTextureView(RGHandle handle)
	{
		if (!handle.IsValid || handle.Index >= (uint32)mResources.Count)
			return null;
		let res = mResources[handle.Index];
		if (res == null || res.Generation != handle.Generation)
			return null;
		return res.DepthOnlyView;
	}

	/// Get the GPU buffer for a resource handle
	public IBuffer GetBuffer(RGHandle handle)
	{
		if (!handle.IsValid || handle.Index >= (uint32)mResources.Count)
			return null;
		let res = mResources[handle.Index];
		if (res == null || res.Generation != handle.Generation)
			return null;
		return res.Buffer;
	}

	/// Swap a ping-pong persistent resource
	public void SwapPingPong(RGHandle handle)
	{
		if (!handle.IsValid || handle.Index >= (uint32)mResources.Count)
			return;
		let res = mResources[handle.Index];
		if (res?.PersistentData != null)
		{
			res.PersistentData.Swap();
			res.Texture = res.PersistentData.Texture;
			res.TextureView = res.PersistentData.TextureView;
		}
	}

	// === Queries ===

	/// Number of passes added this frame
	public int PassCount => mPasses.Count;

	/// Number of resources
	public int ResourceCount
	{
		get
		{
			int count = 0;
			for (let r in mResources)
				if (r != null) count++;
			return count;
		}
	}

	/// Number of passes culled during compilation
	public int CulledPassCount
	{
		get
		{
			int count = 0;
			for (let p in mPasses)
				if (p.IsCulled) count++;
			return count;
		}
	}

	/// Get a resource handle by name
	public RGHandle GetResource(StringView name)
	{
		for (int i = 0; i < mResources.Count; i++)
		{
			let res = mResources[i];
			if (res != null && res.Name.Equals(name))
				return RGHandle((uint32)i, res.Generation);
		}
		return .Invalid;
	}

	/// The compiled execution order (valid after Execute)
	public List<int32> ExecutionOrder => mExecutionOrder;

	/// Access passes (for validation/debug tools)
	public List<RenderGraphPass> Passes => mPasses;

	/// Access resources (for validation/debug tools)
	public List<RenderGraphResource> Resources => mResources;

	// === Internal: Resource management ===

	private RGHandle AddResource(RenderGraphResource res)
	{
		if (mFreeResourceSlots.Count > 0)
		{
			let idx = mFreeResourceSlots.PopBack();
			mResources[idx] = res;
			return RGHandle((uint32)idx, res.Generation);
		}

		let idx = (uint32)mResources.Count;
		mResources.Add(res);
		return RGHandle(idx, res.Generation);
	}

	private PassHandle AddPass(RenderGraphPass pass)
	{
		let idx = (uint32)mPasses.Count;
		mPasses.Add(pass);
		return PassHandle(idx);
	}

	private void ClearPasses()
	{
		for (let p in mPasses)
			delete p;
		mPasses.Clear();
		mExecutionOrder.Clear();
	}

	// === Internal: Compilation pipeline ===

	/// Step 1: Build resource reference tracking
	private void BuildResourceReferences()
	{
		for (int passIdx = 0; passIdx < mPasses.Count; passIdx++)
		{
			let pass = mPasses[passIdx];
			let passHandle = PassHandle((uint32)passIdx);

			for (let access in pass.Accesses)
			{
				if (!access.Handle.IsValid || access.Handle.Index >= (uint32)mResources.Count)
					continue;

				let res = mResources[access.Handle.Index];
				if (res == null) continue;

				res.RefCount++;

				// Track first/last use pass for aliasing
				if (res.FirstUsePass < 0 || passIdx < res.FirstUsePass)
					res.FirstUsePass = (int32)passIdx;
				if (passIdx > res.LastUsePass)
					res.LastUsePass = (int32)passIdx;

				if (access.IsWrite)
				{
					res.FirstWriter = passHandle;
				}
				if (access.IsRead)
				{
					res.LastReader = passHandle;
				}
			}
		}
	}

	/// Step 2: Backward pass culling
	private void CullPasses()
	{
		// Mark all passes as culled initially
		for (let pass in mPasses)
			pass.IsCulled = true;

		// Mark NeverCull/HasSideEffects passes as alive
		for (let pass in mPasses)
		{
			if (pass.ShouldSurviveCulling)
				pass.IsCulled = false;
		}

		// Mark passes that write to imported resources with finalState as alive
		for (let pass in mPasses)
		{
			if (pass.IsCulled)
			{
				let outputs = scope List<RGResourceAccess>();
				pass.GetOutputs(outputs);
				for (let output in outputs)
				{
					if (output.Handle.IsValid && output.Handle.Index < (uint32)mResources.Count)
					{
						let res = mResources[output.Handle.Index];
						if (res != null && res.FinalState.HasValue)
						{
							pass.IsCulled = false;
							break;
						}
					}
				}
			}
		}

		// Backward propagation: if a pass is alive, its input writers are also alive
		bool changed = true;
		while (changed)
		{
			changed = false;
			for (let pass in mPasses)
			{
				if (pass.IsCulled) continue;

				let inputs = scope List<RGResourceAccess>();
				pass.GetInputs(inputs);

				for (let input in inputs)
				{
					if (!input.Handle.IsValid || input.Handle.Index >= (uint32)mResources.Count)
						continue;

					// Find the latest writer of this resource before this pass
					for (int i = mPasses.Count - 1; i >= 0; i--)
					{
						let candidatePass = mPasses[i];
						if (!candidatePass.IsCulled) continue;

						let candidateOutputs = scope List<RGResourceAccess>();
						candidatePass.GetOutputs(candidateOutputs);

						for (let output in candidateOutputs)
						{
							if (output.Handle == input.Handle)
							{
								// Check subresource overlap
								if (input.Subresource.IsAll || output.Subresource.IsAll ||
									input.Subresource.Overlaps(output.Subresource))
								{
									candidatePass.IsCulled = false;
									changed = true;
								}
							}
						}
					}
				}
			}
		}
	}

	/// Step 3: Build pass dependencies from resource flow
	private void BuildDependencies()
	{
		// For each resource, track the last writer pass index
		// Then add dependency: reader depends on latest writer
		for (int passIdx = 0; passIdx < mPasses.Count; passIdx++)
		{
			let pass = mPasses[passIdx];
			if (pass.IsCulled) continue;

			// Collect all resource handles this pass reads (from accesses + Load ops)
			List<RGHandle> readHandles = scope .();

			// Explicit reads from the access list
			for (let access in pass.Accesses)
			{
				if (!access.IsRead) continue;
				if (access.Handle.IsValid)
					readHandles.Add(access.Handle);
			}

			// Implicit reads from LoadOp.Load on color targets
			for (let ct in pass.ColorTargets)
			{
				if (ct.LoadOp == .Load && ct.Handle.IsValid)
					readHandles.Add(ct.Handle);
			}

			// Implicit read from LoadOp.Load on depth target
			if (pass.DepthTarget.HasValue)
			{
				let dt = pass.DepthTarget.Value;
				if (dt.DepthLoadOp == .Load && dt.Handle.IsValid)
					readHandles.Add(dt.Handle);
			}

			// Find dependencies for each read handle
			for (let readHandle in readHandles)
			{
				if (!readHandle.IsValid || readHandle.Index >= (uint32)mResources.Count)
					continue;

				// Find the latest non-culled writer before this pass
				for (int j = passIdx - 1; j >= 0; j--)
				{
					let writerPass = mPasses[j];
					if (writerPass.IsCulled) continue;

					bool writes = false;
					for (let writerAccess in writerPass.Accesses)
					{
						if (writerAccess.Handle == readHandle && writerAccess.IsWrite)
						{
							writes = true;
							break;
						}
					}

					if (writes)
					{
						AddDependencyIfNew(pass, PassHandle((uint32)j));
						break; // Only depend on the latest writer
					}
				}
			}
		}
	}

	/// Adds a dependency to a pass if it doesn't already exist
	private static void AddDependencyIfNew(RenderGraphPass pass, PassHandle dep)
	{
		for (let existing in pass.Dependencies)
			if (existing == dep) return;
		pass.Dependencies.Add(dep);
	}

	/// Step 4: Topological sort using Kahn's algorithm
	private Result<void> TopologicalSort()
	{
		mExecutionOrder.Clear();

		let passCount = mPasses.Count;
		int32[] inDegree = scope int32[passCount];
		List<List<int32>> adjacency = scope .();
		defer { for (let list in adjacency) delete list; }

		for (int i = 0; i < passCount; i++)
			adjacency.Add(new List<int32>());

		// Build adjacency and in-degree
		for (int i = 0; i < passCount; i++)
		{
			let pass = mPasses[i];
			if (pass.IsCulled) continue;

			for (let dep in pass.Dependencies)
			{
				if (dep.IsValid && dep.Index < (uint32)passCount)
				{
					adjacency[(int)dep.Index].Add((int32)i);
					inDegree[i]++;
				}
			}
		}

		// Find all nodes with zero in-degree
		let queue = scope List<int32>();
		for (int i = 0; i < passCount; i++)
		{
			if (!mPasses[i].IsCulled && inDegree[i] == 0)
				queue.Add((int32)i);
		}

		while (queue.Count > 0)
		{
			let node = queue[0];
			queue.RemoveAt(0);
			mExecutionOrder.Add(node);
			mPasses[node].ExecutionOrder = (int32)mExecutionOrder.Count - 1;

			for (let neighbor in adjacency[node])
			{
				inDegree[neighbor]--;
				if (inDegree[neighbor] == 0)
					queue.Add(neighbor);
			}
		}

		// Check for cycles
		int nonCulledCount = 0;
		for (let p in mPasses)
			if (!p.IsCulled) nonCulledCount++;

		if (mExecutionOrder.Count != nonCulledCount)
			return .Err; // Cycle detected

		return .Ok;
	}

	/// Step 5: Allocate GPU resources for transient textures/buffers
	private void AllocateTransientResources()
	{
		for (let res in mResources)
		{
			if (res == null) continue;
			if (res.Lifetime != .Transient) continue;
			if (res.RefCount == 0) continue; // Unused, skip

			if (res.ResourceType == .Texture && mDevice != null)
			{
				let rhiDesc = res.TextureDesc.ToTextureDesc(res.Name);

				// Try pool first
				if (mTexturePool != null && mTexturePool.TryAcquire(rhiDesc, let tex, let view))
				{
					res.Texture = tex;
					res.TextureView = view;

					// TODO: relabel the pooled texture's GPU debug name to match the
					// current resource name (res.Name). The pool reuses textures by
					// format/size, so RenderDoc may show a stale label from a prior
					// frame's transient. Requires ITexture.SetLabel or
					// IDevice.SetDebugName API that doesn't exist yet.

					// Recreate depth-only view for depth+stencil textures (not stored in pool)
					if (res.TextureDesc.Format.IsDepthFormat() && res.TextureDesc.Format.HasStencil())
					{
						if (mDevice.CreateTextureView(tex, TextureViewDesc()
						{
							Aspect = .DepthOnly,
							Label = "RGDepthOnlyView"
						}) case .Ok(let depthOnlyView))
							res.DepthOnlyView = depthOnlyView;
					}
				}
				else
				{
					res.AllocateTexture(mDevice);
				}
			}
			else if (res.ResourceType == .Buffer && mDevice != null)
			{
				res.AllocateBuffer(mDevice);
			}
		}
	}

	/// Return transient resources to pool or defer-delete them
	private void ReturnTransientResources()
	{
		let slotIndex = mFrameIndex % (int32)mDeferredDeletions.Count;
		let deletions = mDeferredDeletions[slotIndex];

		for (let res in mResources)
		{
			if (res == null) continue;
			if (res.Lifetime != .Transient) continue;

			if (res.ResourceType == .Texture && res.Texture != null)
			{
				if (mTexturePool != null)
				{
					let rhiDesc = res.TextureDesc.ToTextureDesc(res.Name);
					mTexturePool.ReturnToPool(rhiDesc, res.Texture, res.TextureView);
					// DepthOnlyView is not pooled - defer deletion (commands may still reference it)
					if (res.DepthOnlyView != null)
						deletions.Add(.() { View = res.DepthOnlyView });
				}
				else
				{
					deletions.Add(.() { Texture = res.Texture, View = res.TextureView, View2 = res.DepthOnlyView });
				}
				res.Texture = null;
				res.TextureView = null;
				res.DepthOnlyView = null;
			}
			else if (res.ResourceType == .Buffer && res.Buffer != null)
			{
				deletions.Add(.() { Buffer = res.Buffer });
				res.Buffer = null;
			}
		}
	}

	// === Internal: Pass execution ===

	private void ExecuteRenderPass(RenderGraphPass pass, ICommandEncoder encoder)
	{
		if (pass.ExecuteCallback == null)
			return;

		// Build RHI render pass descriptor
		var rpDesc = RenderPassDesc();
		rpDesc.Label = pass.Name;

		// Color attachments
		for (int i = 0; i < pass.ColorTargets.Count; i++)
		{
			let ct = pass.ColorTargets[i];
			let view = GetTextureView(ct.Handle);
			if (view == null) continue;

			// TODO: if subresource is not All, create a per-layer view
			rpDesc.ColorAttachments.Add(ColorAttachment()
			{
				View = view,
				LoadOp = ct.LoadOp,
				StoreOp = ct.StoreOp,
				ClearValue = ct.ClearValue
			});
		}

		// Depth attachment
		if (pass.DepthTarget.HasValue)
		{
			let dt = pass.DepthTarget.Value;
			let view = GetTextureView(dt.Handle);
			if (view != null)
			{
				rpDesc.DepthStencilAttachment = DepthStencilAttachment()
				{
					View = view,
					DepthLoadOp = dt.DepthLoadOp,
					DepthStoreOp = dt.DepthStoreOp,
					DepthClearValue = dt.DepthClearValue,
					DepthReadOnly = dt.ReadOnly,
					StencilLoadOp = dt.StencilLoadOp,
					StencilStoreOp = dt.StencilStoreOp,
					StencilClearValue = dt.StencilClearValue
				};
			}
		}

		let rp = encoder.BeginRenderPass(rpDesc);
		pass.ExecuteCallback(rp);
		rp.End();
	}

	private void ExecuteComputePass(RenderGraphPass pass, ICommandEncoder encoder)
	{
		if (pass.ComputeCallback == null)
			return;

		let cp = encoder.BeginComputePass(pass.Name);
		pass.ComputeCallback(cp);
		cp.End();
	}

	private void ExecuteCopyPass(RenderGraphPass pass, ICommandEncoder encoder)
	{
		if (pass.CopyCallback == null)
			return;

		pass.CopyCallback(encoder);
	}
}
