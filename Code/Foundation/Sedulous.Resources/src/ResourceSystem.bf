using System;
using System.Threading;
using System.Collections;
using Sedulous.Jobs;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Serialization;

namespace Sedulous.Resources;

/// Manages resource loading, caching, and lifecycle.
class ResourceSystem
{
	private readonly ILogger mLogger;

	private readonly Monitor mManagersMonitor = new .() ~ delete _;
	private readonly Dictionary<Type, IResourceManager> mManagers = new .() ~ delete _;
	private readonly ResourceCache mCache = new .() ~ delete _;
	private readonly List<IResourceRegistry> mRegistries = new .() ~ delete _;

	// Serialization
	private ISerializerProvider mSerializerProvider;
	private bool mOwnsSerializerProvider = false;

	// Hot-reload
	private FileWatcher mFileWatcher ~ delete _;
	private bool mHotReloadEnabled = false;
	private List<IResourceChangeListener> mListeners = new .() ~ delete _;
	private List<String> mChangedPaths = new .() ~ { for (let s in _) delete s; delete _; };

	/// Gets the resource cache.
	public ResourceCache Cache => mCache;

	/// Gets the serializer provider. Set via SetSerializerProvider().
	public ISerializerProvider SerializerProvider => mSerializerProvider;

	/// Sets the serializer provider used by resource managers for reading/writing data.
	/// @param provider The provider instance.
	/// @param takeOwnership If true, the ResourceSystem deletes the provider on shutdown.
	public void SetSerializerProvider(ISerializerProvider provider, bool takeOwnership = true)
	{
		if (mOwnsSerializerProvider && mSerializerProvider != null)
			delete mSerializerProvider;

		mSerializerProvider = provider;
		mOwnsSerializerProvider = takeOwnership;

		// Propagate to all registered managers
		using (mManagersMonitor.Enter())
		{
			for (let kv in mManagers)
				kv.value.SerializerProvider = provider;
		}
	}

	public this(ILogger logger)
	{
		mLogger = logger;
	}

	public ~this()
	{
		Shutdown();
	}

	/// Initializes the resource system.
	public void Startup() { }

	/// Shuts down the resource system.
	public void Shutdown()
	{
		// Snapshot the resources before clearing. GetResources returns struct copies
		// of handles (no AddRef), so we must unload before Clear() releases the
		// cache's refs (which may delete the resources).
		let resources = scope List<ResourceHandle<IResource>>();
		mCache.GetResources(resources);

		// Deduplicate: same resource may appear under multiple cache keys (path + GUID).
		// Build unique list before any Unload calls (which may delete resources).
		let unique = scope List<ResourceHandle<IResource>>();
		for (var handle in resources)
		{
			let res = handle.Resource;
			if (res == null) continue;

			bool found = false;
			for (let existing in unique)
			{
				if (existing.Resource.Id == res.Id)
				{
					found = true;
					break;
				}
			}
			if (!found)
				unique.Add(handle);
		}

		for (var resource in unique)
		{
			if (let manager = GetManager(resource.Resource.GetType()))
			{
				manager.Unload(ref resource);
			}
		}

		// Clear releases the cache's ref on each handle and disposes keys.
		mCache.Clear();

		// Clean up serializer provider
		if (mOwnsSerializerProvider && mSerializerProvider != null)
		{
			delete mSerializerProvider;
			mSerializerProvider = null;
		}
	}

	/// Updates the resource system.
	public void Update()
	{
		if (mHotReloadEnabled)
			PollHotReload();
	}

	/// Enables hot-reload: watches loaded resource files for changes and reloads automatically.
	public void EnableHotReload(double pollIntervalSeconds = 1.0)
	{
		if (mHotReloadEnabled)
			return;

		mHotReloadEnabled = true;
		if (mFileWatcher == null)
			mFileWatcher = new FileWatcher(pollIntervalSeconds);
		else
			mFileWatcher.PollIntervalSeconds = pollIntervalSeconds;
	}

	/// Disables hot-reload.
	public void DisableHotReload()
	{
		mHotReloadEnabled = false;
	}

	/// Whether hot-reload is currently enabled.
	public bool HotReloadEnabled => mHotReloadEnabled;

	/// Adds a listener that is notified when resources are reloaded.
	public void AddChangeListener(IResourceChangeListener listener)
	{
		if (!mListeners.Contains(listener))
			mListeners.Add(listener);
	}

	/// Removes a change listener.
	public void RemoveChangeListener(IResourceChangeListener listener)
	{
		mListeners.Remove(listener);
	}

	/// Polls for file changes and reloads affected resources.
	private void PollHotReload()
	{
		if (mFileWatcher == null)
			return;

		if (!mFileWatcher.Poll(mChangedPaths))
			return;

		let entries = scope List<CacheEntry>();

		for (let path in mChangedPaths)
		{
			entries.Clear();
			mCache.GetByPath(path, entries);

			for (let entry in entries)
			{
				let manager = GetManager(entry.ResourceType);
				if (manager == null)
					continue;

				let resource = entry.Handle.Resource;
				if (resource == null)
					continue;

				let result = manager.ReloadFromFile(resource, path);
				if (result case .Ok)
				{
					if (let res = resource as Resource)
						res.IncrementGeneration();
					mLogger?.LogInformation("Hot-reloaded resource '{0}' ({1})", path, entry.ResourceType.GetName(.. scope .()));
					for (let listener in mListeners)
						listener.OnResourceReloaded(path, entry.ResourceType, resource);
				}
				else if (result case .Err(let err))
				{
					if (err != .NotSupported)
						mLogger?.LogWarning("Failed to hot-reload resource '{0}': {1}", path, err);
				}
			}
		}

		for (let s in mChangedPaths)
			delete s;
		mChangedPaths.Clear();
	}

	/// Registers a resource manager.
	public void AddResourceManager(IResourceManager manager)
	{
		using (mManagersMonitor.Enter())
		{
			if (mManagers.ContainsKey(manager.ResourceType))
			{
				mLogger?.LogWarning("A resource manager has already been registered for type '{0}'.", manager.ResourceType.GetName(.. scope .()));
				return;
			}

			// Propagate serializer provider so managers can load files
			if (manager.SerializerProvider == null && mSerializerProvider != null)
				manager.SerializerProvider = mSerializerProvider;

			mManagers.Add(manager.ResourceType, manager);
		}
	}

	/// Unregisters a resource manager.
	/// Unloads all resources managed by this manager before removing it.
	public void RemoveResourceManager(IResourceManager manager)
	{
		// First, unload all resources of this type from the cache.
		// RemoveByType releases the cache's refs.
		List<ResourceHandle<IResource>> resourcesToUnload = scope .();
		mCache.RemoveByType(manager.ResourceType, resourcesToUnload);

		// Deduplicate: same resource may appear under multiple cache keys.
		// Build unique list before any Unload calls.
		let unique = scope List<ResourceHandle<IResource>>();
		for (var handle in resourcesToUnload)
		{
			let res = handle.Resource;
			if (res == null) continue;

			bool found = false;
			for (let existing in unique)
			{
				if (existing.Resource.Id == res.Id)
				{
					found = true;
					break;
				}
			}
			if (!found)
				unique.Add(handle);
		}

		for (var resource in unique)
		{
			manager.Unload(ref resource);
		}

		// Then remove the manager
		using (mManagersMonitor.Enter())
		{
			if (mManagers.TryGet(manager.ResourceType, var type, ?))
			{
				mManagers.Remove(type);
			}
		}
	}

	/// Adds a resource registry for GUID-to-path resolution.
	public void AddRegistry(IResourceRegistry registry)
	{
		using (mManagersMonitor.Enter())
		{
			if (!mRegistries.Contains(registry))
				mRegistries.Add(registry);
		}
	}

	/// Removes a resource registry.
	public void RemoveRegistry(IResourceRegistry registry)
	{
		using (mManagersMonitor.Enter())
		{
			mRegistries.Remove(registry);
		}
	}

	/// Gets the manager for a resource type.
	private IResourceManager GetManager<T>() where T : IResource
	{
		using (mManagersMonitor.Enter())
		{
			if (mManagers.TryGetValue(typeof(T), let manager))
				return manager;
			return null;
		}
	}

	private IResourceManager GetManager(Type type)
	{
		using (mManagersMonitor.Enter())
		{
			if (mManagers.ContainsKey(type))
			{
				return mManagers[type];
			}

			return null;
		}
	}

	/// Adds an already-loaded resource to the system.
	public Result<ResourceHandle<T>, ResourceLoadError> AddResource<T>(T resource, bool cache = true) where T : IResource
	{
		let manager = GetManager<T>();
		if (manager == null)
			return .Err(.ManagerNotFound);

		resource.AddRef(); // Manager's ownership ref - released in Unload
		var handle = ResourceHandle<IResource>(resource);

		if (cache)
		{
			String id = scope $"{resource.Id.ToString(.. scope .()):X}";
			var key = ResourceCacheKey(id, typeof(T));
			defer key.Dispose();
			mCache.Set(key, handle);
		}

		let result = ResourceHandle<T>((T)handle.Resource);
		handle.Release();
		return result;
	}

	/// Loads a resource synchronously.
	public Result<ResourceHandle<T>, ResourceLoadError> LoadResource<T>(
		StringView path,
		bool fromCache = true,
		bool cacheIfLoaded = true) where T : IResource
	{
		// Check cache first (by original path, including protocol)
		if (fromCache)
		{
			var key = ResourceCacheKey(path, typeof(T));
			defer key.Dispose();
			let handle = mCache.Get(key);
			if (handle.IsValid)
				return ResourceHandle<T>((T)handle.Resource);
		}

		// Resolve protocol-prefixed paths to absolute filesystem paths
		let resolvedPath = scope String();
		if (!ResolveProtocolPath(path, resolvedPath))
			return .Err(.NotFound);

		// Get manager
		let manager = GetManager<T>();
		if (manager == null)
			return .Err(.ManagerNotFound);

		// Load resource using absolute path
		let loadResult = manager.Load(resolvedPath);
		if (loadResult case .Err(let error))
			return .Err(error);

		var handle = loadResult.Value;

		// Cache by original path (with protocol) for consistent lookups
		if (cacheIfLoaded)
		{
			var key = ResourceCacheKey(path, typeof(T));
			defer key.Dispose();
			mCache.Set(key, handle);
		}

		// Track for hot-reload (absolute path)
		mFileWatcher?.Track(resolvedPath);

		// Build the caller's handle from the raw resource pointer, then release the
		// intermediate handle so its ref doesn't leak. The caller's handle and the
		// cache each hold their own ref.
		let result = ResourceHandle<T>((T)handle.Resource);
		handle.Release();
		return result;
	}

	/// Loads a resource asynchronously.
	public Job<Result<ResourceHandle<T>, ResourceLoadError>> LoadResourceAsync<T>(
		StringView path,
		bool fromCache = true,
		bool cacheIfLoaded = true,
		delegate void(Result<ResourceHandle<T>, ResourceLoadError>) onCompleted = null,
		bool ownsDelegate = true) where T : IResource
	{
		let job = new LoadResourceJob<T>(this, path, fromCache, cacheIfLoaded, .AutoRelease, onCompleted, ownsDelegate);
		// todo: we may need a addref to job here to return it
		JobSystem.Run(job);
		return job;
	}

	/// Unloads a resource.
	public void UnloadResource<T>(ref ResourceHandle<IResource> resource) where T : IResource
	{
		mCache.Remove(resource);

		// Untrack from hot-reload if no other cache entries use this path
		// (We don't have the path here, so the FileWatcher will simply fail to find
		// a matching cache entry on next poll - harmless. Explicit untracking happens
		// when we know the path.)

		if (resource.Resource?.RefCount > 1)
		{
			mLogger.LogWarning(scope $"Unloading resource '{resource.Resource.Id}' with RefCount {resource.Resource.RefCount}. Resource must be manually freed.");
		}

		let manager = GetManager<T>();
		if (manager != null)
			manager.Unload(ref resource);
		else
		{
			mLogger.LogWarning(scope $"ResourceManager for resource type '{resource.GetType().GetName(.. scope .())}' not found.");
		}

		resource.Release();
	}

	/// Loads a resource by reference (GUID + path).
	/// Resolution order:
	///   1. Cache by GUID string
	///   2. Cache by path
	///   3. Registry GUID-to-path resolution (preferred, gives full path)
	///   4. Fall back to ref path if registry didn't resolve
	///   5. Load from file by resolved path
	///   6. After successful load, also cache by GUID for future lookups
	public Result<ResourceHandle<T>, ResourceLoadError> LoadByRef<T>(ResourceRef resourceRef) where T : IResource
	{
		// 1. Try cache by GUID
		if (resourceRef.HasId)
		{
			let guidStr = scope String();
			resourceRef.Id.ToString(guidStr);
			var key = ResourceCacheKey(guidStr, typeof(T));
			defer key.Dispose();
			let handle = mCache.Get(key);
			if (handle.IsValid)
				return ResourceHandle<T>((T)handle.Resource);
		}

		// 2. Try cache by path
		if (resourceRef.HasPath)
		{
			var key = ResourceCacheKey(resourceRef.Path, typeof(T));
			defer key.Dispose();
			let handle = mCache.Get(key);
			if (handle.IsValid)
				return ResourceHandle<T>((T)handle.Resource);
		}

		// 3. Resolve path: prefer registry (full path) over ref path (may be relative)
		String resolvedPath = null;
		String tempPath = null;
		defer { delete tempPath; }

		if (resourceRef.HasId)
		{
			tempPath = new String();
			if (ResolvePathFromId(resourceRef.Id, tempPath))
				resolvedPath = tempPath;
		}

		// Fall back to ref path if registry lookup didn't resolve
		if (resolvedPath == null && resourceRef.HasPath)
			resolvedPath = resourceRef.Path;

		// 4. Load by path
		if (resolvedPath != null && resolvedPath.Length > 0)
		{
			let result = LoadResource<T>(resolvedPath);
			if (result case .Ok(let handle))
			{
				// Also cache by GUID for future ID-based lookups
				if (resourceRef.HasId)
				{
					let guidStr = scope String();
					resourceRef.Id.ToString(guidStr);
					var guidKey = ResourceCacheKey(guidStr, typeof(T));
					defer guidKey.Dispose();
					var guidHandle = ResourceHandle<IResource>(handle.Resource);
					mCache.Set(guidKey, guidHandle);
					guidHandle.Release();
				}
			}
			return result;
		}

		return .Err(.NotFound);
	}

	/// Resolves a GUID to a path by querying all registered registries.
	private bool ResolvePathFromId(Guid id, String outPath)
	{
		using (mManagersMonitor.Enter())
		{
			for (let registry in mRegistries)
			{
				if (registry.TryResolvePath(id, outPath))
					return true;
			}
			return false;
		}
	}

	/// Parses a protocol-prefixed path (e.g. "builtin://primitives/cube.mesh").
	/// Returns true if a protocol was found; sets protocol and relativePath.
	private static bool TryParseProtocol(StringView path, out StringView protocol, out StringView relativePath)
	{
		let idx = path.IndexOf("://");
		if (idx > 0)
		{
			protocol = path[0..<idx];
			relativePath = path[(idx + 3)...];
			return true;
		}
		protocol = default;
		relativePath = path;
		return false;
	}

	/// Finds a registry by name (protocol).
	private IResourceRegistry FindRegistry(StringView name)
	{
		using (mManagersMonitor.Enter())
		{
			for (let registry in mRegistries)
			{
				if (registry.Name == name)
					return registry;
			}
			return null;
		}
	}

	/// Resolves a protocol-prefixed path to an absolute filesystem path.
	/// If the path has no protocol, returns it unchanged (assumed absolute).
	/// Returns true if resolution succeeded.
	public bool ResolveProtocolPath(StringView path, String outAbsolutePath)
	{
		StringView protocol = default;
		StringView relativePath = default;

		if (TryParseProtocol(path, out protocol, out relativePath))
		{
			let registry = FindRegistry(protocol);
			if (registry != null)
				return registry.ResolvePath(relativePath, outAbsolutePath);
			return false;
		}

		// No protocol -- treat as absolute path
		outAbsolutePath.Set(path);
		return true;
	}

	/// Converts an absolute filesystem path to a protocol-prefixed path
	/// by matching against registered registry root paths.
	/// Returns true if a matching registry was found.
	/// If no match, outProtocolPath is set to the original absolute path.
	public bool TryMakeProtocolPath(StringView absolutePath, String outProtocolPath)
	{
		using (mManagersMonitor.Enter())
		{
			for (let registry in mRegistries)
			{
				let rootPath = registry.RootPath;
				if (rootPath.Length == 0)
					continue;

				// Normalize separators for comparison
				let normalizedAbsolute = scope String(absolutePath);
				normalizedAbsolute.Replace('\\', '/');
				let normalizedRoot = scope String(rootPath);
				normalizedRoot.Replace('\\', '/');
				if (!normalizedRoot.EndsWith('/'))
					normalizedRoot.Append('/');

				if (normalizedAbsolute.StartsWith(normalizedRoot, .OrdinalIgnoreCase))
				{
					let relativePart = absolutePath.Substring(normalizedRoot.Length);
					outProtocolPath.AppendF("{}://{}", registry.Name, relativePart);
					// Normalize to forward slashes
					outProtocolPath.Replace('\\', '/');
					return true;
				}
			}
		}

		// No matching registry - use absolute path as-is
		outProtocolPath.Set(absolutePath);
		return false;
	}
}
