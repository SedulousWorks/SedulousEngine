using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// The orchestrator.
///
/// Work is DECLARED as passes with their resource accesses; the graph then works out the
/// dependencies from those declarations, culls whatever nothing consumes, sorts what is left,
/// allocates and pools the transient resources, inserts the barriers, and runs the pass
/// bodies into a command encoder.
///
/// Compile works with NO ENCODER, which is what makes the whole of the graph's logic testable
/// headless: culling, ordering and allocation are decided before a single command is recorded.
class RenderGraph
{
	private IDevice mDevice;
	private RenderGraphConfig mConfig;

	private List<RenderGraphResource> mResources = new .() ~ delete _;
	private List<int32> mFreeResourceSlots = new .() ~ delete _;
	private List<RenderGraphPass> mPasses = new .() ~ delete _;
	private List<int32> mExecutionOrder = new .() ~ delete _;
	private bool mIsCompiled = false;

	private BarrierSolver mBarrierSolver = new .() ~ delete _;
	private TransientTexturePool mTexturePool = null ~ delete _;
	/// One list per buffering slot: a deletion waits a whole cycle before it happens.
	private List<List<DeferredDeletion>> mDeferredDeletions = new .() ~ DeleteContainerAndItems!(_);
	/// The per subresource views made this frame, which live only as long as the pass that
	/// wanted them.
	private List<ITextureView> mSubresourceViews = new .() ~ delete _;

	private GraphProfiler mGpuProfiler = null ~ delete _;
	private int32 mLastProfiledPassCount = 0;
	private List<PassCpuTime> mPassCpu = new .() ~ delete _;

	private int32 mFrameIndex = 0;
	private uint32 mOutputWidth = 1920;
	private uint32 mOutputHeight = 1080;
	/// Stamped on each freshly created transient texture, so a consumer can tell one physical
	/// texture from the next even when the address comes back around.
	private uint64 mNextTransientGeneration = 0;

	/// The device is BORROWED and may be null, which is the headless path: everything
	/// compiles and nothing is allocated.
	public this(IDevice device, RenderGraphConfig config = .())
	{
		mDevice = device;
		mConfig = config;

		if (device != null)
			mTexturePool = new TransientTexturePool(device);

		let slots = (config.FrameBufferCount > 0) ? config.FrameBufferCount : 1;
		for (int32 i = 0; i < slots; i++)
			mDeferredDeletions.Add(new List<DeferredDeletion>());
	}

	public ~this()
	{
		for (let list in mDeferredDeletions)
		{
			for (var deletion in ref list)
				deletion.Execute(mDevice);
		}

		ClearAndDeleteItems!(mPasses);
		for (let resource in mResources)
		{
			if (resource != null)
				delete resource;
		}
	}

	// ---- the output size, which the relative size modes resolve against ----

	public void SetOutputSize(uint32 width, uint32 height)
	{
		mOutputWidth = width;
		mOutputHeight = height;
	}

	public uint32 OutputWidth => mOutputWidth;
	public uint32 OutputHeight => mOutputHeight;

	// ---- profiling ----

	/// Turns on per pass GPU timestamps. Lazy, since it needs the device, and idempotent.
	public void EnableGpuProfiling()
	{
		if ((mGpuProfiler != null) || (mDevice == null))
			return;

		let profiler = new GraphProfiler();
		if (profiler.Init(mDevice) case .Err)
		{
			delete profiler;
			return;
		}
		mGpuProfiler = profiler;

		let queue = mDevice.GetQueue(.Graphics, 0);
		if (queue != null)
			mGpuProfiler.SetTimestampPeriod(queue.TimestampPeriod());
	}

	/// The profiler, or null when it was never turned on. BORROWED. Its results are read
	/// once the GPU has finished the frame they came from.
	public GraphProfiler GpuProfiler => mGpuProfiler;
	public int32 LastProfiledPassCount => mLastProfiledPassCount;

	/// This frame's per pass CPU RECORD cost, gathered by name with the expensive first.
	public void AppendCpuPassReport(String outReport)
	{
		// VIEWS into the pass records, never copies. A copy here was allocated inside the loop
		// body, so it was freed at the end of the iteration that made it and the next
		// comparison read a dangling string.
		let names = scope List<StringView>();
		let ticks = scope List<int64>();
		let counts = scope List<int32>();
		var total = (int64)0;

		for (let pass in mPassCpu)
		{
			total += pass.Ticks;

			var found = -1;
			for (int i < names.Count)
			{
				if (names[i] == pass.Name)
				{
					found = i;
					break;
				}
			}

			if (found < 0)
			{
				names.Add(pass.Name);
				ticks.Add(pass.Ticks);
				counts.Add(1);
				continue;
			}

			ticks[found] += pass.Ticks;
			counts[found]++;
		}

		// A selection sort, because there are only ever a handful of distinct names.
		for (int i < names.Count)
		{
			for (int j = i + 1; j < names.Count; j++)
			{
				if (ticks[j] <= ticks[i])
					continue;

				Swap!(names[i], names[j]);
				Swap!(ticks[i], ticks[j]);
				Swap!(counts[i], counts[j]);
			}
		}

		outReport.Append("=== CPU by pass name (record cost, expensive first) ===\n");
		for (int i < names.Count)
			outReport.AppendF("  {} ms  (x{})  {}\n", ToMilliseconds(ticks[i]), counts[i], names[i]);
		outReport.AppendF("  --------\n  {} ms  TOTAL (pass record)\n", ToMilliseconds(total));
	}

	// ---- the frame ----

	public void BeginFrame(int32 frameIndex)
	{
		mFrameIndex = frameIndex;
		FlushDeferred(frameIndex);
		ClearPasses();
		RecycleNonPersistent();
		mIsCompiled = false;
	}

	/// Culls, orders and allocates. Safe with NO encoder, which is how the tests reach it.
	public Result<void> Compile()
	{
		if (mPasses.IsEmpty)
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

	/// Compiles if it has not been, then records into the encoder. A null encoder compiles
	/// and stops.
	public Result<void> Execute(ICommandEncoder encoder)
	{
		if (!mIsCompiled)
		{
			if (Compile() case .Err)
				return .Err;
		}

		if (encoder == null)
			return .Ok;

		mBarrierSolver.Reset(ResourceSpan());

		// The query set is reset up front, which has to happen outside any render pass.
		let profiling = (mGpuProfiler != null);
		if (profiling)
		{
			mGpuProfiler.BeginFrame(encoder);
			mPassCpu.Clear();
		}

		var profiledPassCount = (int32)0;
		for (let passIndex in mExecutionOrder)
		{
			let pass = mPasses[passIndex];
			if (pass.IsCulled)
				continue;
			if ((pass.Condition != null) && !pass.Condition())
				continue;

			let cpuStart = profiling ? Stopwatch.GetTimestamp() : 0;
			encoder.BeginDebugLabel(pass.Name);
			if (profiling)
				mGpuProfiler.BeginPass(encoder, profiledPassCount, pass.Name);

			mBarrierSolver.EmitBarriers(pass, ResourceSpan(), encoder);

			switch (pass.Type)
			{
			case .Render: ExecuteRenderPass(pass, encoder);
			case .Compute: ExecuteComputePass(pass, encoder);
			case .Copy: ExecuteCopyPass(pass, encoder);
			}

			mBarrierSolver.EmitReadableAfterWriteBarriers(pass, ResourceSpan(), encoder);
			if (profiling)
			{
				mGpuProfiler.EndPass(encoder, profiledPassCount);
				profiledPassCount++;
			}
			encoder.EndDebugLabel();

			if (profiling)
				mPassCpu.Add(.(pass.Name, Stopwatch.GetTimestamp() - cpuStart));
		}

		if (mGpuProfiler != null)
		{
			mGpuProfiler.Resolve(encoder, profiledPassCount);
			mLastProfiledPassCount = profiledPassCount;
		}

		mBarrierSolver.EmitFinalTransitions(ResourceSpan(), encoder);
		mBarrierSolver.UpdatePersistentStates(ResourceSpan());

		// The per subresource views made this frame go on the deferred list: the commands
		// that reference them have not run yet.
		if (!mSubresourceViews.IsEmpty)
		{
			let deletions = DeferredSlot();
			for (let view in mSubresourceViews)
			{
				var deletion = DeferredDeletion();
				deletion.View = view;
				deletions.Add(deletion);
			}
			mSubresourceViews.Clear();
		}

		ReturnTransientResources();
		return .Ok;
	}

	public void EndFrame()
	{
		mIsCompiled = false;
		if (mTexturePool != null)
			mTexturePool.EndFrame();
	}

	/// Clears the passes while KEEPING the persistent resources' state, which is what a
	/// second view rendered in the same frame needs.
	public void Reset()
	{
		ReturnTransientResources();
		ClearPasses();
		RecycleNonPersistent();
		mIsCompiled = false;
	}

	// ---- declaring resources ----

	public RGHandle CreateTransient(StringView name, RGTextureDesc desc)
	{
		let resource = new RenderGraphResource(name, .Texture, .Transient);
		var resolved = desc;
		resolved.Resolve(mOutputWidth, mOutputHeight);
		resource.TextureDesc = resolved;
		return AddResource(resource);
	}

	public RGHandle CreateTransientBuffer(StringView name, RGBufferDesc desc)
	{
		let resource = new RenderGraphResource(name, .Buffer, .Transient);
		resource.BufferDesc = desc;
		return AddResource(resource);
	}

	/// Registers a texture that survives frames. NOT OWNED: the caller made it and keeps it.
	public RGHandle RegisterPersistent(StringView name, ITexture texture, ITextureView view)
	{
		let resource = new RenderGraphResource(name, .Texture, .Persistent);
		resource.Texture = texture;
		resource.TextureView = view;
		resource.PersistentData = new PersistentResource(texture, view);
		return AddResource(resource);
	}

	/// The ping pong variant, which is what a temporal effect reads its history out of.
	public RGHandle RegisterPersistentPingPong(StringView name, ITexture first, ITexture second,
		ITextureView firstView, ITextureView secondView)
	{
		let resource = new RenderGraphResource(name, .Texture, .Persistent);
		resource.Texture = first;
		resource.TextureView = firstView;
		resource.PersistentData = new PersistentResource(first, second, firstView, secondView);
		return AddResource(resource);
	}

	/// Imports a texture the caller owns, such as the swap chain's image.
	///
	/// The CURRENT state says what it is in now, and without one the texture's own initial
	/// state is assumed; the FINAL state is what the graph leaves it in, which is how a
	/// presentable image is handed back ready to present.
	public RGHandle ImportTarget(StringView name, ITexture texture, ITextureView view,
		ResourceState? finalState = null, ResourceState? currentState = null)
	{
		let resource = new RenderGraphResource(name, .Texture, .Imported);
		resource.Texture = texture;
		resource.TextureView = view;
		resource.FinalState = finalState;
		resource.LastKnownState = (currentState != null)
			? currentState.Value
			: ((texture != null) ? texture.InitialState : .Undefined);
		return AddResource(resource);
	}

	/// The depth variant, carrying the depth only view a sampler needs.
	public RGHandle ImportTarget(StringView name, ITexture texture, ITextureView view,
		ITextureView depthOnlyView, ResourceState? finalState = null,
		ResourceState? currentState = null)
	{
		let handle = ImportTarget(name, texture, view, finalState, currentState);
		if (Resolve(handle) case .Ok(let resource))
			resource.DepthOnlyView = depthOnlyView;
		return handle;
	}

	public RGHandle ImportBuffer(StringView name, IBuffer buffer)
	{
		let resource = new RenderGraphResource(name, .Buffer, .Imported);
		resource.Buffer = buffer;
		return AddResource(resource);
	}

	/// Asks that this resource end up readable by a shader after whatever writes it, so
	/// something OUTSIDE the graph can sample it without knowing the graph's business.
	public void RequireReadableAfterWrite(RGHandle handle)
	{
		if (Resolve(handle) case .Ok(let resource))
			resource.ReadableAfterWrite = true;
	}

	// ---- declaring passes ----

	/// The setup delegate is called IMMEDIATELY with the builder and is not retained, so a
	/// scoped one is fine.
	public PassHandle AddRenderPass(StringView name, delegate void(PassBuilder) setup) =>
		AddPassOfType(name, .Render, setup);

	public PassHandle AddComputePass(StringView name, delegate void(PassBuilder) setup) =>
		AddPassOfType(name, .Compute, setup);

	public PassHandle AddCopyPass(StringView name, delegate void(PassBuilder) setup) =>
		AddPassOfType(name, .Copy, setup);

	// ---- reaching resources, which is what an execute body does ----

	public ITexture GetTexture(RGHandle handle)
	{
		if (!(ResolveChecked(handle) case .Ok(let resource)))
			return null;
		return (resource.PersistentData != null) ? resource.PersistentData.CurrentTexture : resource.Texture;
	}

	public ITextureView GetTextureView(RGHandle handle)
	{
		if (!(ResolveChecked(handle) case .Ok(let resource)))
			return null;
		return (resource.PersistentData != null) ? resource.PersistentData.CurrentView : resource.TextureView;
	}

	/// The identity of whatever physically backs this handle now.
	///
	/// For a transient it CHANGES when the graph allocates a different texture, on a resize
	/// say, even if the new view reuses a freed address. A bind group cache over the view has
	/// to key on this as well, or it serves a stale, destroyed texture. Zero when unresolved.
	public uint64 GetTextureGeneration(RGHandle handle)
	{
		if (ResolveChecked(handle) case .Ok(let resource))
			return resource.TextureGeneration;
		return 0;
	}

	public ITextureView GetDepthOnlyTextureView(RGHandle handle)
	{
		if (ResolveChecked(handle) case .Ok(let resource))
			return resource.DepthOnlyView;
		return null;
	}

	public IBuffer GetBuffer(RGHandle handle)
	{
		if (ResolveChecked(handle) case .Ok(let resource))
			return resource.Buffer;
		return null;
	}

	/// Swaps a ping pong resource's slots, so what was written last frame is now the history.
	public void SwapPingPong(RGHandle handle)
	{
		if (!(Resolve(handle) case .Ok(let resource)))
			return;
		if (resource.PersistentData == null)
			return;

		resource.PersistentData.Swap();
		resource.Texture = resource.PersistentData.CurrentTexture;
		resource.TextureView = resource.PersistentData.CurrentView;
	}

	// ---- queries ----

	public int PassCount => mPasses.Count;

	public int ResourceCount
	{
		get
		{
			var count = 0;
			for (let resource in mResources)
			{
				if (resource != null)
					count++;
			}
			return count;
		}
	}

	public int CulledPassCount
	{
		get
		{
			var count = 0;
			for (let pass in mPasses)
			{
				if (pass.IsCulled)
					count++;
			}
			return count;
		}
	}

	public RGHandle GetResource(StringView name)
	{
		for (int i < mResources.Count)
		{
			let resource = mResources[i];
			if ((resource != null) && (resource.Name == name))
				return .((uint32)i, resource.Generation);
		}
		return .Invalid;
	}

	public ResourceState GetResourceState(RGHandle handle)
	{
		if (ResolveChecked(handle) case .Ok(let resource))
			return resource.LastKnownState;
		return .Undefined;
	}

	public Span<int32> ExecutionOrder => .(mExecutionOrder.Ptr, mExecutionOrder.Count);
	public Span<RenderGraphPass> Passes => .(mPasses.Ptr, mPasses.Count);
	public Span<RenderGraphResource> Resources => ResourceSpan();

	// ---- internals ----

	private Span<RenderGraphResource> ResourceSpan() => .(mResources.Ptr, mResources.Count);

	private static double ToMilliseconds(int64 ticks) => ticks / 1000.0;

	private List<DeferredDeletion> DeferredSlot() =>
		mDeferredDeletions[mFrameIndex % mDeferredDeletions.Count];

	private void FlushDeferred(int32 frameIndex)
	{
		let deletions = mDeferredDeletions[frameIndex % mDeferredDeletions.Count];
		for (var deletion in ref deletions)
			deletion.Execute(mDevice);
		deletions.Clear();
	}

	/// Bounds AND generation, which is what tells a live handle from one whose slot has since
	/// been reused.
	private Result<RenderGraphResource> ResolveChecked(RGHandle handle)
	{
		if (!handle.IsValid || (handle.Index >= (uint32)mResources.Count))
			return .Err;

		let resource = mResources[(int)handle.Index];
		if ((resource == null) || (resource.Generation != handle.Generation))
			return .Err;

		return .Ok(resource);
	}

	/// Bounds only, for the mutators: a caller changing a resource it just declared should not
	/// have to have kept the generation straight.
	private Result<RenderGraphResource> Resolve(RGHandle handle)
	{
		if (!handle.IsValid || (handle.Index >= (uint32)mResources.Count))
			return .Err;

		let resource = mResources[(int)handle.Index];
		if (resource == null)
			return .Err;

		return .Ok(resource);
	}

	private RGHandle AddResource(RenderGraphResource resource)
	{
		if (!mFreeResourceSlots.IsEmpty)
		{
			let index = mFreeResourceSlots.PopBack();
			mResources[index] = resource;
			return .((uint32)index, resource.Generation);
		}

		let index = (uint32)mResources.Count;
		mResources.Add(resource);
		return .(index, resource.Generation);
	}

	private PassHandle AddPassOfType(StringView name, RGPassType type,
		delegate void(PassBuilder) setup)
	{
		let pass = new RenderGraphPass(name, type);
		let builder = scope PassBuilder(pass);
		setup(builder);

		let index = (uint32)mPasses.Count;
		mPasses.Add(pass);
		return .(index);
	}

	private void ClearPasses()
	{
		ClearAndDeleteItems!(mPasses);
		mExecutionOrder.Clear();
	}

	/// Frees everything but the persistent resources, whose slots and state carry over.
	private void RecycleNonPersistent()
	{
		for (int i < mResources.Count)
		{
			let resource = mResources[i];
			if (resource == null)
				continue;

			if (resource.Lifetime != .Persistent)
			{
				mFreeResourceSlots.Add((int32)i);
				delete resource;
				mResources[i] = null;
				continue;
			}

			resource.ResetTracking();
		}
	}

	// ---- compilation ----

	/// Counts the references and works out each resource's live range, which is what culling
	/// and allocation both read.
	private void BuildResourceReferences()
	{
		for (int passIndex < mPasses.Count)
		{
			let pass = mPasses[passIndex];
			let passHandle = PassHandle((uint32)passIndex);

			for (let access in pass.Accesses)
			{
				if (!access.Handle.IsValid || (access.Handle.Index >= (uint32)mResources.Count))
					continue;

				let resource = mResources[(int)access.Handle.Index];
				if (resource == null)
					continue;

				resource.RefCount++;
				if ((resource.FirstUsePass < 0) || ((int32)passIndex < resource.FirstUsePass))
					resource.FirstUsePass = (int32)passIndex;
				if ((int32)passIndex > resource.LastUsePass)
					resource.LastUsePass = (int32)passIndex;

				if (access.IsWrite)
					resource.FirstWriter = passHandle;
				if (access.IsRead)
					resource.LastReader = passHandle;
			}
		}
	}

	/// Culls everything, then keeps what has to live: passes that said so, passes writing an
	/// imported resource with a final state, and then everything a live pass reads from,
	/// propagated backward until it settles.
	private void CullPasses()
	{
		for (let pass in mPasses)
			pass.IsCulled = true;

		for (let pass in mPasses)
		{
			if (pass.ShouldSurviveCulling)
				pass.IsCulled = false;
		}

		// A pass writing an imported resource that was promised a final state stays: the
		// promise is to whoever owns that resource, not to the graph.
		for (let pass in mPasses)
		{
			if (!pass.IsCulled)
				continue;

			let outputs = scope List<RGResourceAccess>();
			pass.GetOutputs(outputs);

			for (let output in outputs)
			{
				if (!output.Handle.IsValid || (output.Handle.Index >= (uint32)mResources.Count))
					continue;

				let resource = mResources[(int)output.Handle.Index];
				if ((resource != null) && (resource.FinalState != null))
				{
					pass.IsCulled = false;
					break;
				}
			}
		}

		// Backward propagation: a live pass keeps alive whichever upstream writers produced
		// what it reads, and those keep their own upstreams, until nothing changes.
		var changed = true;
		while (changed)
		{
			changed = false;
			for (let pass in mPasses)
			{
				if (pass.IsCulled)
					continue;

				let inputs = scope List<RGResourceAccess>();
				pass.GetInputs(inputs);

				for (let input in inputs)
				{
					if (!input.Handle.IsValid || (input.Handle.Index >= (uint32)mResources.Count))
						continue;

					for (int i = mPasses.Count - 1; i >= 0; i--)
					{
						let candidate = mPasses[i];
						if (!candidate.IsCulled)
							continue;

						let outputs = scope:: List<RGResourceAccess>();
						candidate.GetOutputs(outputs);

						for (let output in outputs)
						{
							if (output.Handle != input.Handle)
								continue;
							if (!input.Subresource.IsAll && !output.Subresource.IsAll
								&& !input.Subresource.Overlaps(output.Subresource))
								continue;

							candidate.IsCulled = false;
							changed = true;
						}
					}
				}
			}
		}
	}

	/// Turns the declared accesses into edges: each read depends on the NEAREST earlier pass
	/// that wrote an overlapping part of the same resource.
	private void BuildDependencies()
	{
		for (int passIndex < mPasses.Count)
		{
			let pass = mPasses[passIndex];
			if (pass.IsCulled)
				continue;

			let reads = scope List<RGResourceAccess>();
			pass.GetInputs(reads);

			for (let read in reads)
			{
				if (!read.Handle.IsValid || (read.Handle.Index >= (uint32)mResources.Count))
					continue;

				let resource = mResources[(int)read.Handle.Index];
				let totalMips = (resource != null) ? resource.TotalMipLevels : 1;
				let totalLayers = (resource != null) ? resource.TotalArrayLayers : 1;

				for (int j = passIndex - 1; j >= 0; j--)
				{
					let writer = mPasses[j];
					if (writer.IsCulled)
						continue;

					let outputs = scope:: List<RGResourceAccess>();
					writer.GetOutputs(outputs);

					var overlaps = false;
					for (let output in outputs)
					{
						if (output.Handle != read.Handle)
							continue;
						if (read.Subresource.IsAll || output.Subresource.IsAll
							|| read.Subresource.Overlaps(output.Subresource, totalMips, totalLayers))
						{
							overlaps = true;
							break;
						}
					}

					// The NEAREST writer only: anything earlier is already ordered behind it.
					if (overlaps)
					{
						AddDependencyIfNew(pass, .((uint32)j));
						break;
					}
				}
			}
		}
	}

	private static void AddDependencyIfNew(RenderGraphPass pass, PassHandle dependency)
	{
		for (let existing in pass.Dependencies)
		{
			if (existing == dependency)
				return;
		}
		pass.Dependencies.Add(dependency);
	}

	/// Kahn's algorithm over the live passes. An order shorter than the live pass count means
	/// a CYCLE, which is a declaration error rather than something to run anyway.
	private Result<void> TopologicalSort()
	{
		mExecutionOrder.Clear();
		let passCount = mPasses.Count;

		let inDegree = scope List<int32>();
		inDegree.Resize(passCount);
		let adjacency = scope List<List<int32>>();
		defer { ClearAndDeleteItems!(adjacency); }
		for (int i < passCount)
			adjacency.Add(new List<int32>());

		for (int i < passCount)
		{
			let pass = mPasses[i];
			if (pass.IsCulled)
				continue;

			for (let dependency in pass.Dependencies)
			{
				if (dependency.IsValid && (dependency.Index < (uint32)passCount))
				{
					adjacency[(int)dependency.Index].Add((int32)i);
					inDegree[i]++;
				}
			}
		}

		let queue = scope List<int32>();
		for (int i < passCount)
		{
			if (!mPasses[i].IsCulled && (inDegree[i] == 0))
				queue.Add((int32)i);
		}

		while (!queue.IsEmpty)
		{
			let node = queue[0];
			queue.RemoveAt(0);

			mExecutionOrder.Add(node);
			mPasses[node].ExecutionOrder = (int32)mExecutionOrder.Count - 1;

			for (let neighbour in adjacency[node])
			{
				if (--inDegree[neighbour] == 0)
					queue.Add(neighbour);
			}
		}

		var liveCount = 0;
		for (let pass in mPasses)
		{
			if (!pass.IsCulled)
				liveCount++;
		}

		return (mExecutionOrder.Count == liveCount) ? .Ok : .Err;
	}

	/// Allocates whatever the live passes actually reference, out of the pool where it can be.
	private void AllocateTransientResources()
	{
		var allocationFailures = 0;
		String firstFailure = null;

		for (let resource in mResources)
		{
			if ((resource == null) || (resource.Lifetime != .Transient) || (resource.RefCount == 0))
				continue;
			if (mDevice == null)
				continue;

			if (resource.ResourceType == .Texture)
			{
				let desc = resource.TextureDesc.ToTextureDesc(resource.Name);

				if ((mTexturePool != null)
					&& mTexturePool.TryAcquire(desc, let texture, let view, let generation))
				{
					resource.Texture = texture;
					resource.TextureView = view;
					// A reused physical texture keeps the identity it had.
					resource.TextureGeneration = generation;
					CreateDepthOnlyView(resource);
					continue;
				}

				if (resource.AllocateTexture(mDevice) case .Err)
				{
					allocationFailures++;
					if (firstFailure == null)
						firstFailure = resource.Name;
				}
				// Freshly created, so a new identity whatever address it landed on.
				resource.TextureGeneration = ++mNextTransientGeneration;
			}
			else if (resource.ResourceType == .Buffer)
			{
				resource.AllocateBuffer(mDevice).IgnoreError();
			}
		}

		// One line per frame that had any failure. Sustained firing is a GPU memory leak
		// somewhere rather than a graph that asked for too much this once.
		if (allocationFailures > 0)
		{
			Console.Error.WriteLine(scope $"RenderGraph: {allocationFailures} transient texture allocation(s) failed, first '{firstFailure}'");
		}
	}

	/// The depth ONLY view of a pooled combined format texture, which the pool does not carry.
	private void CreateDepthOnlyView(RenderGraphResource resource)
	{
		if (!TextureFormats.IsDepthFormat(resource.TextureDesc.Format)
			|| !TextureFormats.HasStencil(resource.TextureDesc.Format))
			return;

		var desc = TextureViewDesc();
		desc.Aspect = .DepthOnly;
		desc.Label = "RGDepthOnlyView";
		if (mDevice.CreateTextureView(resource.Texture, desc) case .Ok(let view))
			resource.DepthOnlyView = view;
	}

	/// Hands the transient textures back to the pool, or to the deferred deletions.
	///
	/// ONLY A FULLY VALID texture is pooled. One with a null view, which is a partial or
	/// failed allocation, must never re-enter: a later acquire would hand it out, the render
	/// pass would drop that attachment, and the pass signature would then disagree with the
	/// pipelines recorded against it, permanently and keyed by size.
	private void ReturnTransientResources()
	{
		let deletions = DeferredSlot();

		for (let resource in mResources)
		{
			if ((resource == null) || (resource.Lifetime != .Transient))
				continue;

			if ((resource.ResourceType == .Texture) && (resource.Texture != null))
			{
				if ((mTexturePool != null) && (resource.TextureView != null))
				{
					let desc = resource.TextureDesc.ToTextureDesc(resource.Name);
					mTexturePool.ReturnToPool(desc, resource.Texture, resource.TextureView,
						resource.TextureGeneration);

					// The depth only view is not pooled with it: the next acquirer makes its
					// own from whichever format it asked for.
					if (resource.DepthOnlyView != null)
					{
						var deletion = DeferredDeletion();
						deletion.View = resource.DepthOnlyView;
						deletions.Add(deletion);
					}
				}
				else
				{
					var deletion = DeferredDeletion();
					deletion.Texture = resource.Texture;
					deletion.View = resource.TextureView;
					deletion.SecondView = resource.DepthOnlyView;
					deletions.Add(deletion);
				}

				resource.Texture = null;
				resource.TextureView = null;
				resource.DepthOnlyView = null;
			}
			else if ((resource.ResourceType == .Buffer) && (resource.Buffer != null))
			{
				var deletion = DeferredDeletion();
				deletion.Buffer = resource.Buffer;
				deletions.Add(deletion);
				resource.Buffer = null;
			}
		}
	}

	// ---- executing ----

	/// A view of one slice of a texture, for an attachment that named a subresource. It lives
	/// for the frame and is then deferred like anything else.
	private ITextureView CreateSubresourceView(RGHandle handle, RGSubresourceRange subresource)
	{
		if (mDevice == null)
			return null;

		let texture = GetTexture(handle);
		if (texture == null)
			return null;

		var desc = TextureViewDesc();
		desc.BaseMipLevel = subresource.BaseMipLevel;
		desc.MipLevelCount = (subresource.MipLevelCount == 0) ? 1 : subresource.MipLevelCount;
		desc.BaseArrayLayer = subresource.BaseArrayLayer;
		desc.ArrayLayerCount = (subresource.ArrayLayerCount == 0) ? 1 : subresource.ArrayLayerCount;
		desc.Dimension = (desc.ArrayLayerCount == 1) ? .Texture2D : .Texture2DArray;

		if (!(mDevice.CreateTextureView(texture, desc) case .Ok(let view)))
			return null;

		mSubresourceViews.Add(view);
		return view;
	}

	/// The full render area of a pass, from whichever attachment can say.
	///
	/// Bundles INHERIT the viewport and scissor from the pass they run in, since neither
	/// backend lets a bundle set them, so the pass has to.
	private bool PassRenderArea(RenderGraphPass pass, out uint32 outWidth, out uint32 outHeight)
	{
		for (let target in pass.ColorTargets)
		{
			if (AreaOf(target.Handle, out outWidth, out outHeight))
				return true;
		}

		if (pass.DepthTarget != null)
		{
			if (AreaOf(pass.DepthTarget.Value.Handle, out outWidth, out outHeight))
				return true;
		}

		outWidth = 0;
		outHeight = 0;
		return false;
	}

	/// The declared size first, then the backing texture's: a transient knows its dimensions
	/// before anything is allocated.
	private bool AreaOf(RGHandle handle, out uint32 outWidth, out uint32 outHeight)
	{
		outWidth = 0;
		outHeight = 0;

		if (Resolve(handle) case .Ok(let resource))
		{
			if ((resource.TextureDesc.Width > 0) && (resource.TextureDesc.Height > 0))
			{
				outWidth = resource.TextureDesc.Width;
				outHeight = resource.TextureDesc.Height;
				return true;
			}
		}

		let view = GetTextureView(handle);
		if ((view == null) || (view.Texture == null))
			return false;

		if ((view.Texture.Desc.Width == 0) || (view.Texture.Desc.Height == 0))
			return false;

		outWidth = view.Texture.Desc.Width;
		outHeight = view.Texture.Desc.Height;
		return true;
	}

	private void ExecuteRenderPass(RenderGraphPass pass, ICommandEncoder encoder)
	{
		let hasBundles = (pass.BundleCallback != null);
		if ((pass.ExecuteCallback == null) && !hasBundles)
			return;

		// If ANY declared attachment failed to resolve to a view, which a transient
		// allocation failure during a rapid resize produces, the WHOLE PASS is skipped.
		// Beginning it with only the survivors would change the attachment count and formats
		// away from the fixed signature the pipelines and bundles were recorded against.
		// Dropping one frame's pass beats corrupting every frame after it.
		for (let target in pass.ColorTargets)
		{
			if (GetTextureView(target.Handle) == null)
				return;
		}
		if ((pass.DepthTarget != null) && (GetTextureView(pass.DepthTarget.Value.Handle) == null))
			return;

		// A bundle pass records its bundles NOW, while the encoder is still recording and
		// before the pass begins, because that is the only time a bundle can be made.
		let bundles = scope List<IRenderBundle>();
		if (hasBundles)
			pass.BundleCallback(encoder, bundles);

		var desc = RenderPassDesc();
		desc.Label = pass.Name;
		if (hasBundles)
			desc.Contents = .SecondaryCommandBuffers;

		for (let target in pass.ColorTargets)
		{
			var view = GetTextureView(target.Handle);
			if (view == null)
				continue;

			if (!target.Subresource.IsAll)
			{
				let subView = CreateSubresourceView(target.Handle, target.Subresource);
				if (subView != null)
					view = subView;
			}

			var attachment = ColorAttachment();
			attachment.View = view;
			attachment.LoadOp = target.LoadOp;
			attachment.StoreOp = target.StoreOp;
			attachment.ClearValue = target.ClearValue;

			// The hardware resolve, over the whole subresource: resolving a slice is not
			// something the scene pass needs.
			if (target.ResolveHandle.IsValid)
			{
				let resolveView = GetTextureView(target.ResolveHandle);
				if (resolveView != null)
					attachment.ResolveTarget = resolveView;
			}

			desc.ColorAttachments.Add(attachment);
		}

		if (pass.DepthTarget != null)
		{
			let depth = pass.DepthTarget.Value;
			var view = GetTextureView(depth.Handle);
			if (view != null)
			{
				if (!depth.Subresource.IsAll)
				{
					let subView = CreateSubresourceView(depth.Handle, depth.Subresource);
					if (subView != null)
						view = subView;
				}

				var attachment = DepthStencilAttachment();
				attachment.View = view;
				attachment.DepthLoadOp = depth.DepthLoadOp;
				attachment.DepthStoreOp = depth.DepthStoreOp;
				attachment.DepthClearValue = depth.DepthClearValue;
				attachment.DepthReadOnly = depth.ReadOnly;
				attachment.StencilLoadOp = depth.StencilLoadOp;
				attachment.StencilStoreOp = depth.StencilStoreOp;
				attachment.StencilClearValue = depth.StencilClearValue;
				desc.DepthStencilAttachment = attachment;
			}
		}

		let renderPass = encoder.BeginRenderPass(desc);

		// The pass's own viewport if it set one, else the whole attachment.
		var viewportX = (int32)0;
		var viewportY = (int32)0;
		var viewportWidth = (uint32)0;
		var viewportHeight = (uint32)0;
		if (pass.HasViewport)
		{
			viewportX = pass.ViewportX;
			viewportY = pass.ViewportY;
			viewportWidth = pass.ViewportWidth;
			viewportHeight = pass.ViewportHeight;
		}
		else
		{
			PassRenderArea(pass, out viewportWidth, out viewportHeight);
		}

		if ((viewportWidth > 0) && (viewportHeight > 0))
		{
			renderPass.SetViewport((float)viewportX, (float)viewportY, (float)viewportWidth,
				(float)viewportHeight);
			renderPass.SetScissor(viewportX, viewportY, viewportWidth, viewportHeight);
		}

		if (hasBundles)
		{
			if (!bundles.IsEmpty)
				renderPass.ExecuteBundles(.(bundles.Ptr, bundles.Count));
		}
		else
		{
			pass.ExecuteCallback(renderPass);
		}

		renderPass.End();
	}

	private void ExecuteComputePass(RenderGraphPass pass, ICommandEncoder encoder)
	{
		if (pass.ComputeCallback == null)
			return;

		let computePass = encoder.BeginComputePass(pass.Name);
		pass.ComputeCallback(computePass);
		computePass.End();
	}

	/// A copy pass records straight into the encoder: there is no pass to begin.
	private void ExecuteCopyPass(RenderGraphPass pass, ICommandEncoder encoder)
	{
		if (pass.CopyCallback == null)
			return;

		pass.CopyCallback(encoder);
	}
}
