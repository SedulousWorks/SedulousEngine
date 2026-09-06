using System;
using System.Collections;
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
	private Dictionary<Guid, ResourceHandle> mHandles = new .() ~ delete _;
	private Dictionary<uint64, IResourceFactory> mFactories = new .() ~ delete _;

	/// Which resources a build consumed, and the reverse. The reverse is what a reload
	/// walks: rebuilding a child has to rebuild whatever was built from it.
	private Dictionary<Guid, List<Guid>> mDependencies = new .() ~ delete _;
	private Dictionary<Guid, List<Guid>> mDependents = new .() ~ delete _;

	/// What is building right now, so a factory that binds a child records the edge
	/// without being asked to.
	private List<Guid> mBuildStack = new .() ~ delete _;

	public this(IContentDatabase database)
	{
		mDatabase = database;
	}

	public ~this()
	{
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
