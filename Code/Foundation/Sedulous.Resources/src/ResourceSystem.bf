using System;
using System.IO;
using System.Threading;
using System.Collections;
using Sedulous.Jobs;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Serialization;
using Sedulous.VFS;

namespace Sedulous.Resources;

/// Manages resource loading, caching, and hot-reload.
///
/// Architecture (post-VFS refactor):
///
///   - Byte access lives in `Sedulous.VFS` mounts. The system holds a mount table
///     keyed by URI scheme: `Mount("project", new FileSystemMount("/path"))`.
///   - GUID identity lives in `IResourceIndex` instances. The system holds a list
///     of indices; lookups walk them in registration order.
///   - Managers are byte-source-agnostic - they receive a `Stream`, not a path.
///
/// Resolution flow for `LoadResource("project://textures/foo.tex")`:
///   1. Cache by URI.
///   2. Parse scheme/locator. Look up mount by scheme.
///   3. `mount.Open(locator)` -> Stream.
///   4. Hand stream to the typed `IResourceManager`.
///   5. Cache by URI. If the mount is watchable, track the locator for hot reload.
class ResourceSystem
{
	private readonly ILogger mLogger;

	private readonly Monitor mLock = new .() ~ delete _;
	private readonly Dictionary<Type, IResourceManager> mManagers = new .() ~ delete _;
	private readonly ResourceCache mCache = new .() ~ delete _;

	// Mount table: scheme -> mount. The system does not own the mounts; callers
	// pass them in via Mount() and unmount/dispose them on shutdown.
	private readonly Dictionary<String, IMount> mMounts = new .() ~ DeleteDictionaryAndKeys!(_);

	// Per-mount change source tracking. Populated lazily when a mount is watchable.
	// Used to translate locator-level changes back into resource URIs.
	private readonly Dictionary<String, IChangeSource> mChangeSources = new .() ~ delete _;

	// Identity indices, queried in order. Not owned.
	private readonly List<IResourceIndex> mIndices = new .() ~ delete _;

	// Serialization
	private ISerializerProvider mSerializerProvider;
	private bool mOwnsSerializerProvider = false;

	// Hot reload
	private bool mHotReloadEnabled = false;
	private List<IResourceChangeListener> mListeners = new .() ~ delete _;
	private List<String> mChangedLocators = new .() ~ { for (let s in _) delete s; delete _; };

	public ResourceCache Cache => mCache;
	public ISerializerProvider SerializerProvider => mSerializerProvider;

	public this(ILogger logger)
	{
		mLogger = logger;
	}

	public ~this()
	{
		Shutdown();
	}

	public void Startup() { }

	public void Shutdown()
	{
		// Snapshot the resources before clearing - GetResources returns struct
		// copies of handles, so we must Unload before Clear() releases the
		// cache's refs (which may delete the resources).
		let resources = scope List<ResourceHandle<IResource>>();
		mCache.GetResources(resources);

		// Dedup by object identity, NOT by Id. The same instance can be
		// cached under multiple keys (LoadResource keys by URI; LoadByRef
		// cross-indexes the same object by GUID) - those must collapse to
		// one Unload. But two DISTINCT instances can legitimately share an
		// Id: rename an asset while a tab is open, then reopen the renamed
		// file - the registry GUID is preserved, so the still-open original
		// and the freshly-loaded copy carry the same Id. Dedup-by-Id would
		// drop one from `unique`, skip its manager.Unload, and leak it
		// (cache.Clear releases only its cache ref, leaving RefCount 1).
		// Reference identity unloads each distinct instance exactly once.
		let unique = scope List<ResourceHandle<IResource>>();
		for (var handle in resources)
		{
			let res = handle.Resource as Resource;
			if (res == null) continue;

			bool found = false;
			for (let existing in unique)
				if ((existing.Resource as Resource) === res) { found = true; break; }
			if (!found)
				unique.Add(handle);
		}

		for (var resource in unique)
		{
			if (let manager = GetManager(resource.Resource.GetType()))
				manager.Unload(ref resource);
		}

		mCache.Clear();

		if (mOwnsSerializerProvider && mSerializerProvider != null)
		{
			delete mSerializerProvider;
			mSerializerProvider = null;
		}
	}

	public void Update()
	{
		if (mHotReloadEnabled)
			PollHotReload();
	}

	// ==================== Serializer provider ====================

	public void SetSerializerProvider(ISerializerProvider provider, bool takeOwnership = true)
	{
		if (mOwnsSerializerProvider && mSerializerProvider != null)
			delete mSerializerProvider;

		mSerializerProvider = provider;
		mOwnsSerializerProvider = takeOwnership;

		using (mLock.Enter())
		{
			for (let kv in mManagers)
				kv.value.SerializerProvider = provider;
		}
	}

	// ==================== Mount table ====================

	/// Mounts an `IMount` under the given URI scheme. References to
	/// `<scheme>://locator` resolve through this mount.
	///
	/// The system does not take ownership - the caller deletes the mount after
	/// `Unmount` returns or after `Shutdown`.
	public void Mount(StringView scheme, IMount mount)
	{
		using (mLock.Enter())
		{
			let key = new String(scheme);
			if (mMounts.TryAdd(key, mount))
			{
				if (let watchable = mount as IWatchableMount)
					mChangeSources[key] = watchable.ChangeSource;
			}
			else
			{
				delete key;
				mLogger?.LogWarning("A mount is already registered for scheme '{0}'.", scheme);
			}
		}
	}

	/// Unmounts the mount registered for `scheme`. No-op if missing. Does not
	/// delete the mount (caller retains ownership).
	public void Unmount(StringView scheme)
	{
		using (mLock.Enter())
		{
			if (mMounts.TryGet(scope String(scheme), var storedKey, ?))
			{
				mChangeSources.Remove(storedKey);
				mMounts.Remove(storedKey);
				delete storedKey;
			}
		}
	}

	/// Returns the mount registered for `scheme`, or null.
	public IMount GetMount(StringView scheme)
	{
		using (mLock.Enter())
		{
			for (let kv in mMounts)
			{
				if (StringView(kv.key) == scheme)
					return kv.value;
			}
			return null;
		}
	}

	public int MountCount
	{
		get
		{
			using (mLock.Enter())
				return mMounts.Count;
		}
	}

	// ==================== Indices ====================

	public void AddIndex(IResourceIndex index)
	{
		using (mLock.Enter())
		{
			if (!mIndices.Contains(index))
				mIndices.Add(index);
		}
	}

	public void RemoveIndex(IResourceIndex index)
	{
		using (mLock.Enter())
			mIndices.Remove(index);
	}

	public int IndexCount
	{
		get { using (mLock.Enter()) return mIndices.Count; }
	}

	// ==================== Managers ====================

	public void AddResourceManager(IResourceManager manager)
	{
		using (mLock.Enter())
		{
			if (mManagers.ContainsKey(manager.ResourceType))
			{
				mLogger?.LogWarning("A resource manager has already been registered for type '{0}'.",
					manager.ResourceType.GetName(.. scope .()));
				return;
			}

			if (manager.SerializerProvider == null && mSerializerProvider != null)
				manager.SerializerProvider = mSerializerProvider;

			mManagers.Add(manager.ResourceType, manager);
		}
	}

	public void RemoveResourceManager(IResourceManager manager)
	{
		let toUnload = scope List<ResourceHandle<IResource>>();
		mCache.RemoveByType(manager.ResourceType, toUnload);

		let unique = scope List<ResourceHandle<IResource>>();
		for (var handle in toUnload)
		{
			let res = handle.Resource;
			if (res == null) continue;

			bool found = false;
			for (let existing in unique)
				if (existing.Resource.Id == res.Id) { found = true; break; }
			if (!found)
				unique.Add(handle);
		}

		for (var resource in unique)
			manager.Unload(ref resource);

		using (mLock.Enter())
		{
			if (mManagers.TryGet(manager.ResourceType, var type, ?))
				mManagers.Remove(type);
		}
	}

	// ==================== Change listeners ====================

	public void EnableHotReload()  { mHotReloadEnabled = true; }
	public void DisableHotReload() { mHotReloadEnabled = false; }
	public bool HotReloadEnabled => mHotReloadEnabled;

	/// Forces a cached resource to be reloaded from disk in place.
	/// Same path PollHotReload uses, triggered explicitly. The ref
	/// can carry a Guid, a Path, or both - URI resolution mirrors
	/// LoadByRef: prefer the index lookup by Guid, fall back to the
	/// ref's Path. Use cases: editor "discard unsaved in-memory edits"
	/// (re-reads the disk state into the existing resource object), or
	/// any code that knows a file changed without going through the
	/// mount's file-watcher.
	public Result<void, ResourceLoadError> ReloadResource(ResourceRef @ref)
	{
		// Resolve to URI. Same precedence as LoadByRef: index lookup
		// by Id wins over the ref's path so renamed assets reload
		// from their current location.
		String resolvedUri = null;
		String tempUri = null;
		defer { delete tempUri; }

		if (@ref.HasId)
		{
			tempUri = new String();
			if (ResolveUriFromId(@ref.Id, tempUri))
				resolvedUri = tempUri;
		}
		if (resolvedUri == null && @ref.HasPath)
			resolvedUri = @ref.Path;
		if (resolvedUri == null || resolvedUri.Length == 0)
			return .Err(.NotFound);

		return ReloadByUri(resolvedUri);
	}

	private Result<void, ResourceLoadError> ReloadByUri(StringView uri)
	{
		using (mLock.Enter())
		{
			let entries = scope List<CacheEntry>();
			mCache.GetByPath(uri, entries);
			if (entries.Count == 0) return .Err(.NotFound);

			// Split URI into scheme + locator to open a fresh stream
			// from the right mount.
			let sep = uri.IndexOf("://");
			if (sep <= 0) return .Err(.InvalidFormat);
			let scheme = uri.Substring(0, sep);
			let locator = uri.Substring(sep + 3);

			if (!mMounts.TryGetValueAlt(scheme, let mount)) return .Err(.NotFound);

			Result<void, ResourceLoadError> last = .Err(.NotFound);
			for (let entry in entries)
			{
				let manager = GetManager(entry.ResourceType);
				if (manager == null) continue;

				let resource = entry.Handle.Resource;
				if (resource == null) continue;

				let openResult = mount.Open(scope String(locator));
				// MountError -> ResourceLoadError mapping: mount-level
				// open failures surface as NotFound from this API.
				if (openResult case .Err) { last = .Err(.NotFound); continue; }
				let stream = openResult.Value;
				defer delete stream;

				let reload = manager.Reload(resource, .(stream, mount, scope String(locator)));
				if (reload case .Ok)
				{
					if (let r = resource as Resource)
						r.IncrementGeneration();
					mLogger?.LogInformation("Reloaded resource '{0}' ({1})",
						uri, entry.ResourceType.GetName(.. scope .()));
					for (let listener in mListeners)
						listener.OnResourceReloaded(uri, entry.ResourceType, resource);
					last = .Ok;
				}
				else if (reload case .Err(let err))
				{
					if (err != .NotSupported)
						mLogger?.LogWarning("Failed to reload resource '{0}': {1}", uri, err);
					last = .Err(err);
				}
			}
			return last;
		}
	}

	public void AddChangeListener(IResourceChangeListener listener)
	{
		if (!mListeners.Contains(listener))
			mListeners.Add(listener);
	}

	public void RemoveChangeListener(IResourceChangeListener listener)
	{
		mListeners.Remove(listener);
	}

	// ==================== Loading ====================

	/// Loads a resource by URI (`scheme://locator`).
	public Result<ResourceHandle<T>, ResourceLoadError> LoadResource<T>(
		StringView uri,
		bool fromCache = true,
		bool cacheIfLoaded = true) where T : IResource
	{
		// 1. Cache check (keyed by full URI).
		if (fromCache)
		{
			var key = ResourceCacheKey(uri, typeof(T));
			defer key.Dispose();
			let cached = mCache.Get(key);
			if (cached.IsValid)
				return ResourceHandle<T>((T)cached.Resource);
		}

		// 2. Manager lookup.
		let manager = GetManager<T>();
		if (manager == null)
			return .Err(.ManagerNotFound);

		// 3. URI -> (mount, locator).
		StringView scheme = default;
		StringView locator = default;
		if (!TryParseUri(uri, out scheme, out locator))
			return .Err(.NotFound);

		IMount mount = null;
		String mountKey = null;
		using (mLock.Enter())
		{
			for (let kv in mMounts)
			{
				if (StringView(kv.key) == scheme)
				{
					mount = kv.value;
					mountKey = kv.key;
					break;
				}
			}
		}
		if (mount == null)
			return .Err(.NotFound);

		// 4. Open + load.
		let openResult = mount.Open(locator);
		if (openResult case .Err)
			return .Err(.NotFound);
		let stream = openResult.Value;
		defer delete stream;

		let loadResult = manager.Load(.(stream, mount, locator));
		if (loadResult case .Err(let err))
			return .Err(err);

		var handle = loadResult.Value;

		// 5. Cache by URI.
		if (cacheIfLoaded)
		{
			var key = ResourceCacheKey(uri, typeof(T));
			defer key.Dispose();
			mCache.Set(key, handle);
		}

		// 6. Track for hot reload if the mount supports it.
		if (mHotReloadEnabled && mountKey != null)
		{
			if (mChangeSources.TryGetValue(mountKey, let cs))
				cs.Track(locator);
		}

		let result = ResourceHandle<T>((T)handle.Resource);
		handle.Release();
		return result;
	}

	public Job<Result<ResourceHandle<T>, ResourceLoadError>> LoadResourceAsync<T>(
		StringView uri,
		bool fromCache = true,
		bool cacheIfLoaded = true,
		delegate void(Result<ResourceHandle<T>, ResourceLoadError>) onCompleted = null,
		bool ownsDelegate = true) where T : IResource
	{
		let job = new LoadResourceJob<T>(this, uri, fromCache, cacheIfLoaded, .AutoRelease, onCompleted, ownsDelegate);
		JobSystem.Run(job);
		return job;
	}

	/// Loads a resource by `ResourceRef`. Resolution order:
	///   1. Cache by GUID, then by URI.
	///   2. Resolve URI from GUID via indices (preferred over the ref's path).
	///   3. Fall back to `ref.Path` if no index match.
	///   4. Load by URI; cross-index in cache under the GUID for future ID lookups.
	public Result<ResourceHandle<T>, ResourceLoadError> LoadByRef<T>(ResourceRef resourceRef) where T : IResource
	{
		if (resourceRef.HasId)
		{
			let guidStr = scope String();
			resourceRef.Id.ToString(guidStr);
			var key = ResourceCacheKey(guidStr, typeof(T));
			defer key.Dispose();
			let cached = mCache.Get(key);
			if (cached.IsValid)
				return ResourceHandle<T>((T)cached.Resource);
		}

		if (resourceRef.HasPath)
		{
			var key = ResourceCacheKey(resourceRef.Path, typeof(T));
			defer key.Dispose();
			let cached = mCache.Get(key);
			if (cached.IsValid)
				return ResourceHandle<T>((T)cached.Resource);
		}

		// Resolve URI: prefer index lookup over ref's path.
		String resolved = null;
		String tempUri = null;
		defer { delete tempUri; }

		if (resourceRef.HasId)
		{
			tempUri = new String();
			if (ResolveUriFromId(resourceRef.Id, tempUri))
				resolved = tempUri;
		}
		if (resolved == null && resourceRef.HasPath)
			resolved = resourceRef.Path;

		if (resolved == null || resolved.Length == 0)
			return .Err(.NotFound);

		let result = LoadResource<T>(resolved);
		if (result case .Ok(let handle) && resourceRef.HasId)
		{
			// Cross-index in cache by GUID so future ID-based lookups hit.
			let guidStr = scope String();
			resourceRef.Id.ToString(guidStr);
			var guidKey = ResourceCacheKey(guidStr, typeof(T));
			defer guidKey.Dispose();
			var guidHandle = ResourceHandle<IResource>(handle.Resource);
			mCache.Set(guidKey, guidHandle);
			guidHandle.Release();
		}
		return result;
	}

	/// Adds an already-loaded resource directly to the cache. Used for resources
	/// produced in memory rather than loaded from a mount.
	public Result<ResourceHandle<T>, ResourceLoadError> AddResource<T>(T resource, bool cache = true) where T : IResource
	{
		let manager = GetManager<T>();
		if (manager == null)
			return .Err(.ManagerNotFound);

		resource.AddRef();
		var handle = ResourceHandle<IResource>(resource);

		if (cache)
		{
			let guidStr = scope String();
			resource.Id.ToString(guidStr);
			var key = ResourceCacheKey(guidStr, typeof(T));
			defer key.Dispose();
			mCache.Set(key, handle);
		}

		let result = ResourceHandle<T>((T)handle.Resource);
		handle.Release();
		return result;
	}

	/// Re-keys cached entries from `oldUri` to `newUri` when an asset is
	/// renamed/moved. The loaded resource is unchanged - only its URI is -
	/// so the cache entry is moved, not evicted: refcounts are untouched,
	/// the resource keeps its shutdown teardown anchor (Shutdown only
	/// tears down cached resources), and a later open of the renamed file
	/// hits the cache under the new URI and reuses the same instance
	/// instead of constructing a duplicate that shares the (rename-
	/// preserved) Id.
	public void RecacheUri(StringView oldUri, StringView newUri)
	{
		mCache.RecacheByPath(oldUri, newUri);
	}

	public void UnloadResource<T>(ref ResourceHandle<IResource> resource) where T : IResource
	{
		mCache.Remove(resource);

		if (resource.Resource?.RefCount > 1)
			mLogger.LogWarning(scope $"Unloading resource '{resource.Resource.Id}' with RefCount {resource.Resource.RefCount}. Resource must be manually freed.");

		let manager = GetManager<T>();
		if (manager != null)
			manager.Unload(ref resource);
		else
			mLogger.LogWarning(scope $"ResourceManager for resource type '{resource.GetType().GetName(.. scope .())}' not found.");

		resource.Release();
	}

	// ==================== Hot reload internals ====================

	private void PollHotReload()
	{
		// Collect changes from every watchable mount. Each change source returns
		// locators in its own mount's space; we reconstruct the URI by combining
		// with the scheme the mount is registered under.
		using (mLock.Enter())
		{
			for (let kv in mChangeSources)
			{
				let scheme = kv.key;
				let cs = kv.value;

				if (!cs.Poll(mChangedLocators))
					continue;

				for (let locator in mChangedLocators)
				{
					let uri = scope String();
					uri.AppendF("{}://{}", scheme, locator);

					let entries = scope List<CacheEntry>();
					mCache.GetByPath(uri, entries);

					for (let entry in entries)
					{
						let manager = GetManager(entry.ResourceType);
						if (manager == null) continue;

						let resource = entry.Handle.Resource;
						if (resource == null) continue;

						// Open a fresh stream from the mount.
						let mount = mMounts[scheme];
						let openResult = mount.Open(locator);
						if (openResult case .Err) continue;
						let stream = openResult.Value;
						defer delete stream;

						let reload = manager.Reload(resource, .(stream, mount, locator));
						if (reload case .Ok)
						{
							if (let r = resource as Resource)
								r.IncrementGeneration();
							mLogger?.LogInformation("Hot-reloaded resource '{0}' ({1})",
								uri, entry.ResourceType.GetName(.. scope .()));
							for (let listener in mListeners)
								listener.OnResourceReloaded(uri, entry.ResourceType, resource);
						}
						else if (reload case .Err(let err))
						{
							if (err != .NotSupported)
								mLogger?.LogWarning("Failed to hot-reload resource '{0}': {1}", uri, err);
						}
					}
				}

				for (let s in mChangedLocators) delete s;
				mChangedLocators.Clear();
			}
		}
	}

	// ==================== Helpers ====================

	private IResourceManager GetManager<T>() where T : IResource
	{
		using (mLock.Enter())
		{
			if (mManagers.TryGetValue(typeof(T), let manager))
				return manager;
			return null;
		}
	}

	private IResourceManager GetManager(Type type)
	{
		using (mLock.Enter())
		{
			if (mManagers.ContainsKey(type))
				return mManagers[type];
			return null;
		}
	}

	/// Walks indices in order; returns true if any resolves `id`.
	private bool ResolveUriFromId(Guid id, String outUri)
	{
		using (mLock.Enter())
		{
			for (let index in mIndices)
			{
				if (index.TryResolveUri(id, outUri))
					return true;
			}
			return false;
		}
	}

	/// Parses `scheme://locator`. Returns false if the URI has no scheme.
	private static bool TryParseUri(StringView uri, out StringView scheme, out StringView locator)
	{
		let idx = uri.IndexOf("://");
		if (idx > 0)
		{
			scheme = uri[0..<idx];
			locator = uri[(idx + 3)...];
			return true;
		}
		scheme = default;
		locator = default;
		return false;
	}
}
