using System;
using System.Threading;
using System.Collections;

namespace Sedulous.Resources;

/// Cache for loaded resources.
class ResourceCache
{
	private Monitor mMonitor = new .() ~ delete _;
	private Dictionary<ResourceCacheKey, ResourceHandle<IResource>> mResources = new .() ~ {
		for (var kv in _)
		{
			kv.key.Dispose();
		}
		delete _;
	};

	/// Caches a resource.
	public void Set(ResourceCacheKey key, ResourceHandle<IResource> handle)
	{
		using (mMonitor.Enter())
		{
			if (mResources.TryGetRefAlt(key, var keyPtr, var handlePtr))
			{
				// Replace existing - release old handle, reuse key
				var oldHandle = *handlePtr;
				oldHandle.Release();
				var h = handle;
				h.AddRef();
				*handlePtr = h;
			}
			else
			{
				// Clone the key so the cache owns its own copy
				var h = handle;
				h.AddRef();
				mResources[key.Clone()] = h;
			}
		}
	}

	/// Gets a cached resource by key.
	public ResourceHandle<IResource> Get(ResourceCacheKey key)
	{
		using (mMonitor.Enter())
		{
			if (mResources.TryGetValue(key, let handle))
				return handle;
			return default;
		}
	}

	/// Removes all cache entries for a resource and releases the cache's refs.
	public void Remove(ResourceHandle<IResource> handle)
	{
		using (mMonitor.Enter())
		{
			let keysToRemove = scope List<ResourceCacheKey>();
			for (var kv in mResources)
			{
				if (kv.value.Resource?.Id == handle.Resource?.Id)
					keysToRemove.Add(kv.key);
			}

			for (let key in keysToRemove)
			{
				if (mResources.TryGetValue(key, var h))
					h.Release();
				mResources.Remove(key);
				var k = key;
				k.Dispose();
			}
		}
	}

	/// Removes a resource by key.
	public void Remove(ResourceCacheKey key)
	{
		using (mMonitor.Enter())
		{
			if (mResources.TryGetRefAlt(key, var keyPtr, var handlePtr))
			{
				var storedKey = *keyPtr;
				var handle = *handlePtr;
				mResources.Remove(key);
				storedKey.Dispose();
				handle.Release();
			}
		}
	}

	/// Clears all cached resources.
	public void Clear()
	{
		using (mMonitor.Enter())
		{
			for (var kv in mResources)
			{
				var handle = kv.value;
				handle.Release();
				kv.key.Dispose();
			}
			mResources.Clear();
		}
	}

	/// Gets the number of cached resources.
	public int Count
	{
		get
		{
			using (mMonitor.Enter())
				return mResources.Count;
		}
	}

	public void GetResources(List<ResourceHandle<IResource>> resources)
	{
		using (mMonitor.Enter())
			resources.AddRange(mResources.Values);
	}

	/// Gets all resources of a specific type.
	public void GetResourcesByType(Type type, List<ResourceHandle<IResource>> resources)
	{
		using (mMonitor.Enter())
		{
			for (var kv in mResources)
			{
				if (kv.key.ResourceType == type)
					resources.Add(kv.value);
			}
		}
	}

	/// Finds all cached resources loaded from a given path.
	public void GetByPath(StringView path, List<CacheEntry> results)
	{
		using (mMonitor.Enter())
		{
			for (var kv in mResources)
			{
				if (kv.key.Path == path)
					results.Add(.(kv.key.ResourceType, kv.value));
			}
		}
	}

	/// Checks whether any cached resource uses the given path.
	public bool HasPath(StringView path)
	{
		using (mMonitor.Enter())
		{
			for (var kv in mResources)
			{
				if (kv.key.Path == path)
					return true;
			}
			return false;
		}
	}

	/// Removes all resources of a specific type from the cache.
	/// Returns the removed handles for unloading. Releases the cache's ref on each handle.
	public void RemoveByType(Type type, List<ResourceHandle<IResource>> removedHandles)
	{
		using (mMonitor.Enter())
		{
			List<ResourceCacheKey> keysToRemove = scope .();

			for (var kv in mResources)
			{
				if (kv.key.ResourceType == type)
				{
					keysToRemove.Add(kv.key);
					removedHandles.Add(kv.value);
				}
			}

			for (let key in keysToRemove)
			{
				var keyToDispose = key;
				if (mResources.TryGetValue(key, var handle))
				{
					handle.Release(); // Release cache's ref
				}
				mResources.Remove(key);
				keyToDispose.Dispose();
			}
		}
	}
}

/// Entry returned by ResourceCache.GetByPath.
struct CacheEntry
{
	public Type ResourceType;
	public ResourceHandle<IResource> Handle;

	public this(Type resourceType, ResourceHandle<IResource> handle)
	{
		ResourceType = resourceType;
		Handle = handle;
	}
}
