namespace Sedulous.Shaders;

using System;
using System.IO;
using System.Collections;
using Sedulous.RHI;

/// Caches compiled shader bytecode in memory and on disk.
/// Three-tier lookup: memory cache → disk cache → compile.
class ShaderCache : IDisposable
{
	/// In-memory cache of compiled shaders.
	private Dictionary<ShaderVariantKey, ShaderModule> mMemoryCache = new .() ~ {
		for (let kv in _)
			delete kv.value;
		delete _;
	};

	/// Path to disk cache directory.
	private String mCachePath ~ delete _;

	private readonly IDevice mDevice = null;

	/// Whether disk caching is enabled.
	public bool DiskCacheEnabled => mCachePath != null && !mCachePath.IsEmpty;

	/// Number of shaders in memory cache.
	public int MemoryCacheCount => mMemoryCache.Count;

	/// Target format for disk cache.
	public ShaderTarget Target = .SPIRV;

	public this(IDevice device)
	{
		mDevice = device;
	}

	/// Sets the disk cache directory path.
	/// Creates the directory if it doesn't exist.
	public Result<void> SetCachePath(StringView path)
	{
		if (path.IsEmpty)
		{
			delete mCachePath;
			mCachePath = null;
			return .Ok;
		}

		delete mCachePath;
		mCachePath = new String(path);

		// Ensure directory exists
		if (!Directory.Exists(mCachePath))
		{
			if (Directory.CreateDirectory(mCachePath) case .Err)
				return .Err;
		}

		return .Ok;
	}

	/// Looks up a shader in the memory cache.
	public ShaderModule GetFromMemory(ShaderVariantKey key)
	{
		if (mMemoryCache.TryGetValue(key, let module))
			return module;
		return null;
	}

	/// Loads a shader from the disk cache.
	public Result<ShaderModule> LoadFromDisk(ShaderVariantKey key)
	{
		if (!DiskCacheEnabled)
			return .Err;

		String filename = scope .();
		key.GenerateCacheFilename(filename, Target == .SPIRV);

		String fullPath = scope .();
		Path.InternalCombine(fullPath, mCachePath, filename);

		if (!File.Exists(fullPath))
			return .Err;

		// Read bytecode from file
		List<uint8> bytecode = scope .();
		if (File.ReadAll(fullPath, bytecode) case .Err)
			return .Err;

		let module = new ShaderModule(key, bytecode, mDevice);

		// Also add to memory cache
		mMemoryCache[key] = module;
		return module;
	}

	/// Saves a shader to the disk cache.
	public Result<void> SaveToDisk(ShaderModule module)
	{
		if (!DiskCacheEnabled || !module.IsValid)
			return .Err;

		String filename = scope .();
		module.Key.GenerateCacheFilename(filename, Target == .SPIRV);

		String fullPath = scope .();
		Path.InternalCombine(fullPath, mCachePath, filename);

		// Write bytecode to file
		if (File.WriteAll(fullPath, module.Bytecode) case .Err)
			return .Err;

		return .Ok;
	}

	/// Adds a compiled shader to the memory cache.
	/// Optionally saves to disk cache as well.
	public void Add(ShaderModule module, bool saveToDisk = true)
	{
		// Remove existing entry if present
		if (mMemoryCache.TryGetValue(module.Key, let existing))
		{
			delete existing;
			mMemoryCache.Remove(module.Key);
		}

		mMemoryCache[module.Key] = module;

		if (saveToDisk)
			SaveToDisk(module);
	}

	/// Tries to get a shader from cache (memory first, then disk).
	public ShaderModule TryGet(ShaderVariantKey key)
	{
		// Check memory cache first
		if (let module = GetFromMemory(key))
			return module;

		// Try disk cache
		if (LoadFromDisk(key) case .Ok(let module))
			return module;

		return null;
	}

	/// Removes a shader from memory cache.
	public void RemoveFromMemory(ShaderVariantKey key)
	{
		if (mMemoryCache.TryGetValue(key, let module))
		{
			delete module;
			mMemoryCache.Remove(key);
		}
	}

	/// Removes a shader from disk cache.
	public void RemoveFromDisk(ShaderVariantKey key)
	{
		if (!DiskCacheEnabled)
			return;

		String filename = scope .();
		key.GenerateCacheFilename(filename, Target == .SPIRV);

		String fullPath = scope .();
		Path.InternalCombine(fullPath, mCachePath, filename);

		if (File.Exists(fullPath))
			File.Delete(fullPath);
	}

	/// Clears the memory cache.
	public void ClearMemory()
	{
		for (let kv in mMemoryCache)
			delete kv.value;
		mMemoryCache.Clear();
	}

	/// Clears the disk cache.
	public void ClearDisk()
	{
		if (!DiskCacheEnabled)
			return;

		// Delete all .spv and .dxil files in cache directory
		for (let entry in Directory.EnumerateFiles(mCachePath))
		{
			String filename = scope .();
			entry.GetFileName(filename);

			if (filename.EndsWith(".spv") || filename.EndsWith(".dxil"))
			{
				String fullPath = scope .();
				entry.GetFilePath(fullPath);
				File.Delete(fullPath);
			}
		}
	}

	/// Clears both memory and disk caches.
	public void ClearAll()
	{
		ClearMemory();
		ClearDisk();
	}

	/// Gets cache statistics.
	public void GetStats(String outStats)
	{
		outStats.AppendF("Memory cache: {} shaders\n", mMemoryCache.Count);
		outStats.AppendF("Disk cache: {}\n", DiskCacheEnabled ? mCachePath : "disabled");

		if (DiskCacheEnabled)
		{
			int diskCount = 0;
			int64 totalSize = 0;

			for (let entry in Directory.EnumerateFiles(mCachePath))
			{
				String filename = scope .();
				entry.GetFileName(filename);

				if (filename.EndsWith(".spv") || filename.EndsWith(".dxil"))
				{
					diskCount++;
					totalSize += entry.GetFileSize();
				}
			}

			outStats.AppendF("Disk files: {} ({} KB)\n", diskCount, totalSize / 1024);
		}
	}

	public void Dispose()
	{
		ClearMemory();
	}
}
