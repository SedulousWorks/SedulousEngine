using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;

// The handle's mutators are internal to this namespace: the manager builds and replaces
// products, nothing else does.
using internal Sedulous.Resource;

namespace Sedulous.Resource;

/// Binds identities to runtime products over a content database, caching the handles and
/// rebuilding them on demand.
///
/// It takes ONE database. Whether a host runs a single database or an authoring one and a
/// cooked one is the host's business, decided when it wires up a cook driver; nothing here
/// knows the difference.
///
/// It OWNS every handle it caches. Factories are borrowed and must outlive it.
class ResourceManager
{
	private IContentDatabase mDatabase;
	/// Shared, and optional: with none, an asynchronous bind degrades to a synchronous one
	/// and every caller keeps working.
	private JobSystem mJobs;
	private int mMainThreadId;
	private Dictionary<Guid, ResourceHandle> mHandles = new .() ~ delete _;
	private Dictionary<uint64, IResourceFactory> mFactories = new .() ~ delete _;

	/// Which resources a build consumed, and the reverse. The reverse is what a reload
	/// walks: rebuilding a child has to rebuild whatever was built from it.
	private Dictionary<Guid, List<Guid>> mDependencies = new .() ~ delete _;
	private Dictionary<Guid, List<Guid>> mDependents = new .() ~ delete _;

	/// What is building right now, so a factory that binds a child records the edge
	/// without being asked to.
	private List<Guid> mBuildStack = new .() ~ delete _;

	/// Loads in flight, and the decodes waiting to be turned into products. The pending
	/// map is main-thread only; the completed list is written by workers, so it is locked.
	private Dictionary<Guid, PendingLoad> mPending = new .() ~ delete _;
	private List<CompletedDecode> mCompleted = new .() ~ delete _;
	private Monitor mCompletedLock = new .() ~ delete _;

	/// The constructing thread is the main one: finalizing and pumping happen there.
	public this(IContentDatabase database, JobSystem jobs = null)
	{
		mDatabase = database;
		mJobs = jobs;
		mMainThreadId = Thread.CurrentThread.Id;
	}

	public ~this()
	{
		// Drain, so no decode job is still holding this manager when it goes. Waiting
		// participates in the pool, so a queued but unstarted decode still runs; its result
		// is then discarded rather than finalized, because finalizing would touch factories
		// and the GPU during teardown.
		if (mJobs != null)
		{
			for (let entry in mPending)
				mJobs.Wait(entry.value.Counter);
		}
		for (let entry in mPending)
			delete entry.value;
		for (let entry in mCompleted)
			delete entry.Decoded;

		for (let entry in mHandles)
			entry.value.Release();
		ClearEdges(mDependencies);
		ClearEdges(mDependents);
	}

	/// The backing database, for a caller resolving a content PATH to an identity before
	/// binding it.
	public IContentDatabase Database => mDatabase;

	public int HandleCount => mHandles.Count;

	/// Registers a factory. Registering a product type twice replaces the first, which is
	/// how a host overrides a default.
	public void AddFactory(IResourceFactory factory)
	{
		if (factory != null)
			mFactories[factory.ProductTypeId] = factory;
	}

	/// The stable id for a product type, which is what factories are keyed on.
	public static uint64 ProductTypeIdOf<T>() where T : class
	{
		return TypeIdOf(typeof(T).GetFullName(.. scope String()));
	}

	// ---- binding ----

	/// Binds an identity to a handle producing this type, building it if the cache has
	/// none. The handle is cached, so binding the same identity twice shares one product.
	public Proxy<T> Bind<T>(Guid id) where T : class
	{
		return .(BindHandle(ProductTypeIdOf<T>(), id));
	}

	public ResourceHandle BindHandle(uint64 productTypeId, Guid id)
	{
		// A factory that binds while a build is in flight is naming a dependency of the
		// thing being built.
		if (!mBuildStack.IsEmpty)
			RecordDependency(mBuildStack.Back, id);

		if (mHandles.TryGetValue(id, let cached))
		{
			// A SYNCHRONOUS bind of an identity that is decoding must hand back a finished
			// product, so the decode is completed inline rather than returned as pending.
			if (cached.State == .Pending)
			{
				CompletePending(id);
				return cached;
			}
			// A handle that was flushed is rebuilt in place, so proxies that survived the
			// flush recover rather than staying dead.
			if (cached.Product == null)
				BuildInto(cached, productTypeId, id);
			return cached;
		}

		let handle = new ResourceHandle();
		// Cached BEFORE the build, so a cyclic dependency finds the handle rather than
		// recursing until the stack runs out.
		mHandles[id] = handle;
		BuildInto(handle, productTypeId, id);
		return handle;
	}

	/// The handle for an identity if one is cached, without building anything.
	public ResourceHandle FindHandle(Guid id)
	{
		if (mHandles.TryGetValue(id, let handle))
			return handle;
		return null;
	}

	// ---- asynchronous binding ----

	/// Binds without waiting: the handle comes back immediately as Pending with no product,
	/// the decode runs on a worker, and Pump turns it into a product a frame or two later.
	///
	/// Degrades to a synchronous, immediately ready bind when there is no job system, no
	/// instance, no factory, or a factory that has not opted into the two stage path.
	/// Binding the same identity twice while it is in flight shares the one load.
	public Proxy<T> BindAsync<T>(Guid id) where T : class
	{
		return .(BindHandleAsync(ProductTypeIdOf<T>(), id));
	}

	public ResourceHandle BindHandleAsync(uint64 productTypeId, Guid id)
	{
		if (!mBuildStack.IsEmpty)
			RecordDependency(mBuildStack.Back, id);

		if (mHandles.TryGetValue(id, let cached))
		{
			// A live product or a load already in flight is shared as it is.
			if ((cached.Product != null) || (cached.State == .Pending))
				return cached;
			StartAsyncBuild(cached, productTypeId, id);
			return cached;
		}

		let handle = new ResourceHandle();
		mHandles[id] = handle;
		StartAsyncBuild(handle, productTypeId, id);
		return handle;
	}

	/// How many loads are still decoding or waiting to be finalized. A loading screen reads
	/// this to show progress.
	public int PendingCount => mPending.Count;

	/// Finalizes what has finished decoding, on the MAIN thread, oldest first, until the
	/// budget is spent. Tick once a frame BEFORE the subsystems update, so anything spawned
	/// this frame sees a ready resource.
	///
	/// With a pool of no workers, which is the single-threaded case, it also drives queued
	/// decodes inline: nothing else is going to run them.
	public void Pump(int maxToFinalize = 16)
	{
		AssertMainThread();

		var finalized = 0;
		while (finalized < maxToFinalize)
		{
			CompletedDecode entry = default;
			var have = false;
			using (mCompletedLock.Enter())
			{
				if (!mCompleted.IsEmpty)
				{
					entry = mCompleted[0];
					mCompleted.RemoveAt(0);
					have = true;
				}
			}

			if (!have)
			{
				// Nothing has run the decode, and with no workers nothing will.
				if ((mJobs != null) && (mJobs.WorkerCount == 0) && DriveOneInlineDecode())
					continue;
				break;
			}

			FinalizeCompleted(entry);
			finalized++;
		}

		ReapPending();
	}

	/// Blocks until every load in flight has finalized. For a loading screen or a test,
	/// never for the per-frame path.
	public void WaitAll()
	{
		AssertMainThread();

		// Bounded, because finalizing can start new loads: a composite that binds a child
		// asynchronously adds to the very set being drained.
		for (int guard < 4096)
		{
			var outstanding = false;
			if (mJobs != null)
			{
				for (let entry in mPending)
				{
					if (!entry.value.Finalized)
					{
						outstanding = true;
						// Waiting participates, so an unstarted decode runs here.
						mJobs.Wait(entry.value.Counter);
					}
				}
			}

			Pump(int.MaxValue);
			if (mPending.IsEmpty || !outstanding)
				break;
		}
	}

	// ---- reload ----

	/// Rebuilds a resource, and then everything built from it.
	///
	/// Holders see the new product without being told: they hold the handle, and the
	/// handle is what changed.
	public void Reload(Guid id)
	{
		let visited = scope List<Guid>();
		ReloadRecursive(id, visited);
	}

	/// Drops a product without dropping its handle, so proxies stay valid and the next
	/// bind rebuilds in place.
	public void Flush(Guid id)
	{
		if (mHandles.TryGetValue(id, let handle))
		{
			handle.Replace(null);
			handle.SetState(.Unloaded);
		}
	}

	/// Releases a handle nothing outside the cache is holding, and returns whether it did.
	///
	/// "Nothing outside" is the weak count: the cache's own reference is one, so anything
	/// above that is a stored proxy.
	public bool Purge(Guid id)
	{
		if (!mHandles.TryGetValue(id, let handle))
			return false;
		if (handle.Control.WeakCount > 1)
			return false;

		mHandles.Remove(id);
		ClearForwardDependencies(id);
		handle.Release();
		return true;
	}

	/// Every cached resource nothing outside is holding. Returns how many went.
	public int PurgeUnreferenced()
	{
		let candidates = scope List<Guid>();
		for (let entry in mHandles)
		{
			if (entry.value.Control.WeakCount <= 1)
				candidates.Add(entry.key);
		}

		var purged = 0;
		for (let id in candidates)
		{
			if (Purge(id))
				purged++;
		}
		return purged;
	}

	/// What a resource consumed when it was last built.
	public void GetDependencies(Guid id, List<Guid> outIds)
	{
		outIds.Clear();
		if (mDependencies.TryGetValue(id, let edges))
		{
			for (let edge in edges)
				outIds.Add(edge);
		}
	}

	/// What was built from a resource, which is what a reload has to follow.
	public void GetDependents(Guid id, List<Guid> outIds)
	{
		outIds.Clear();
		if (mDependents.TryGetValue(id, let edges))
		{
			for (let edge in edges)
				outIds.Add(edge);
		}
	}

	// ---- building ----

	private void BuildInto(ResourceHandle handle, uint64 productTypeId, Guid id)
	{
		// A rebuild may resolve different children than last time, so the old outgoing
		// edges go and are recorded fresh during this build.
		ClearForwardDependencies(id);

		handle.SetProductTypeId(productTypeId);
		handle.Replace(null);

		let instance = mDatabase.GetInstance(id);
		if (instance == null)
		{
			// A broken reference rather than a wiring mistake: the identity names nothing
			// in the database. Named, because a silently null handle is very hard to
			// diagnose from the symptom.
			GlobalLog(.Warning, "Resource: bind failed, no content instance for {}", id);
			handle.SetState(.Failed);
			return;
		}

		if (!mFactories.TryGetValue(productTypeId, let factory))
		{
			// A HOST wiring error, not a data error: nothing registered a factory for this
			// product type.
			GlobalLog(.Warning, "Resource: no factory registered for product type {}", productTypeId);
			handle.SetState(.Failed);
			return;
		}

		mBuildStack.Add(id);
		let product = factory.Create(this, instance);
		mBuildStack.PopBack();

		handle.Replace(product);
		handle.SetState((product != null) ? .Ready : .Failed);
	}

	private void ReloadRecursive(Guid id, List<Guid> visited)
	{
		// The guard is against cycles, which a composite resource graph can have.
		for (let seen in visited)
		{
			if (seen == id)
				return;
		}
		visited.Add(id);

		if (mHandles.TryGetValue(id, let handle))
			BuildInto(handle, handle.ProductTypeId, id);

		// Snapshotted, because rebuilding a dependent rewrites the very list being walked.
		let dependents = scope List<Guid>();
		GetDependents(id, dependents);
		for (let dependent in dependents)
			ReloadRecursive(dependent, visited);
	}

	// ---- asynchronous internals ----

	private void StartAsyncBuild(ResourceHandle handle, uint64 productTypeId, Guid id)
	{
		handle.SetProductTypeId(productTypeId);

		let instance = mDatabase.GetInstance(id);
		IResourceFactory factory = null;
		if (mFactories.TryGetValue(productTypeId, let found))
			factory = found;

		// Anything missing, and this is just a synchronous build.
		if ((mJobs == null) || (instance == null) || (factory == null) || !factory.SupportsAsync)
		{
			BuildInto(handle, productTypeId, id);
			return;
		}

		handle.Replace(null);
		handle.SetState(.Pending);
		// A rebuild resolves its children again, so the old edges go now.
		ClearForwardDependencies(id);

		let pending = new PendingLoad();
		pending.Handle = handle;
		pending.Id = id;
		mPending[id] = pending;

		// The job touches only what is safe to touch from a worker: the factory and
		// instance, which outlive the load, and the identity by value. It never reads the
		// handle or either map; those stay on the main thread. The result is handed back
		// through the locked list.
		// Captured BY VALUE. A by-reference capture would point at locals of this method,
		// and the job runs after it has returned.
		mJobs.Submit(new () =>
			{
				let decoded = factory.DecodeStage(instance);
				using (mCompletedLock.Enter())
				{
					mCompleted.Add(CompletedDecode()
						{
							Id = id,
							Handle = handle,
							Factory = factory,
							Decoded = decoded
						});
				}
			}, pending.Counter);
	}

	/// Turns one decoded entry into its product, on the main thread.
	private void FinalizeCompleted(CompletedDecode entry)
	{
		Object product = null;
		if (entry.Decoded != null)
		{
			// On the build stack, so a child bound during finalize records its edge.
			mBuildStack.Add(entry.Id);
			product = entry.Factory.FinalizeStage(this, entry.Decoded);
			mBuildStack.PopBack();
		}

		entry.Handle.Replace(product);
		entry.Handle.SetState((product != null) ? .Ready : .Failed);

		if (mPending.TryGetValue(entry.Id, let record))
			record.Finalized = true;

		if (product == null)
			return;

		// A child settling revives whatever was built while it was still pending, through
		// the same edge a reload uses. A composite built against a child that had no
		// product yet is rebuilt now that there is one, so the result composes rather than
		// staying half empty.
		let dependents = scope List<Guid>();
		GetDependents(entry.Id, dependents);
		for (let dependent in dependents)
			Reload(dependent);
	}

	/// Completes a load in flight and finalizes it, for a synchronous bind of an identity
	/// that is still decoding.
	private void CompletePending(Guid id)
	{
		if (mPending.TryGetValue(id, let record) && (mJobs != null))
			mJobs.Wait(record.Counter); // runs the decode here if no worker has

		Pump(int.MaxValue);
	}

	/// Runs one queued decode on this thread, for a pool with no workers.
	private bool DriveOneInlineDecode()
	{
		for (let entry in mPending)
		{
			if (!entry.value.Finalized && (entry.value.Counter.Value != 0))
			{
				mJobs.Wait(entry.value.Counter);
				return true;
			}
		}
		return false;
	}

	/// Drops the records of loads that have finalized.
	private void ReapPending()
	{
		let done = scope List<Guid>();
		for (let entry in mPending)
		{
			if (entry.value.Finalized && (entry.value.Counter.Value == 0))
				done.Add(entry.key);
		}
		for (let id in done)
		{
			delete mPending[id];
			mPending.Remove(id);
		}
	}

	/// Finalizing touches factories and, through them, the GPU. Both belong to one thread.
	private void AssertMainThread()
	{
		Debug.Assert(Thread.CurrentThread.Id == mMainThreadId,
			"the resource manager must be pumped on the thread that created it");
	}

	// ---- dependency edges ----

	private void RecordDependency(Guid dependent, Guid dependency)
	{
		if (dependent == dependency)
			return;
		AddEdge(mDependencies, dependent, dependency);
		AddEdge(mDependents, dependency, dependent);
	}

	/// Drops a resource's outgoing edges and the matching reverse entries.
	private void ClearForwardDependencies(Guid id)
	{
		if (!mDependencies.TryGetValue(id, let edges))
			return;

		for (let dependency in edges)
		{
			if (mDependents.TryGetValue(dependency, let reverse))
				reverse.Remove(id);
		}
		edges.Clear();
	}

	private static void AddEdge(Dictionary<Guid, List<Guid>> map, Guid key, Guid value)
	{
		if (!map.TryGetValue(key, var edges))
		{
			edges = new List<Guid>();
			map[key] = edges;
		}
		if (!edges.Contains(value))
			edges.Add(value);
	}

	private static void ClearEdges(Dictionary<Guid, List<Guid>> map)
	{
		for (let entry in map)
			delete entry.value;
		map.Clear();
	}
}
