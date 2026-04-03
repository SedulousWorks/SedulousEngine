namespace Sedulous.Resources;

using System;
using System.Collections;
using System.IO;
using System.Threading;

/// Default implementation of IResourceRegistry using in-memory dictionaries.
/// Thread-safe via Monitor. Can be populated programmatically or from a manifest.
class ResourceRegistry : IResourceRegistry
{
	private Monitor mMonitor = new .() ~ delete _;
	private Dictionary<Guid, String> mIdToPath = new .() ~ DeleteDictionaryAndValues!(_);
	private Dictionary<String, Guid> mPathToId = new .() ~ delete _; // Keys shared with mIdToPath values

	/// Registers a resource mapping (GUID <-> path).
	/// Replaces any existing mapping for the same GUID.
	public void Register(Guid id, StringView path)
	{
		using (mMonitor.Enter())
		{
			// Remove old mapping if exists
			if (mIdToPath.TryGetValue(id, let existingPath))
			{
				mPathToId.Remove(existingPath);
				delete existingPath;
				mIdToPath.Remove(id);
			}

			let pathStr = new String(path);
			pathStr.Replace('\\', '/');
			mIdToPath[id] = pathStr;
			mPathToId[pathStr] = id; // Shares the same String object
		}
	}

	/// Unregisters a resource mapping by GUID.
	public void Unregister(Guid id)
	{
		using (mMonitor.Enter())
		{
			if (mIdToPath.TryGetValue(id, let path))
			{
				mPathToId.Remove(path);
				delete path;
				mIdToPath.Remove(id);
			}
		}
	}

	/// Gets the number of registered mappings.
	public int Count
	{
		get
		{
			using (mMonitor.Enter())
				return mIdToPath.Count;
		}
	}

	public bool TryResolvePath(Guid id, String outPath)
	{
		using (mMonitor.Enter())
		{
			if (mIdToPath.TryGetValue(id, let path))
			{
				outPath.Set(path);
				return true;
			}
			return false;
		}
	}

	public bool TryResolveId(StringView path, out Guid outId)
	{
		using (mMonitor.Enter())
		{
			for (let kv in mPathToId)
			{
				if (StringView(kv.key) == path)
				{
					outId = kv.value;
					return true;
				}
			}
			outId = .();
			return false;
		}
	}

	/// Saves the registry to a text file. Format: one "guid=path" per line.
	public Result<void> SaveToFile(StringView filePath)
	{
		using (mMonitor.Enter())
		{
			let stream = scope StreamWriter();
			if (stream.Create(filePath) case .Err)
				return .Err;

			for (let kv in mIdToPath)
			{
				let guidStr = scope String();
				kv.key.ToString(guidStr);
				stream.WriteLine(scope $"{guidStr}={kv.value}");
			}

			return .Ok;
		}
	}

	/// Loads the registry from a text file. Appends to existing entries.
	public Result<void> LoadFromFile(StringView filePath)
	{
		let stream = scope StreamReader();
		if (stream.Open(filePath) case .Err)
			return .Err;

		let line = scope String();
		while (stream.ReadLine(line) case .Ok)
		{
			defer { line.Clear(); }

			if (line.IsEmpty)
				continue;

			let eqIdx = line.IndexOf('=');
			if (eqIdx <= 0)
				continue;

			let guidStr = StringView(line, 0, eqIdx);
			let path = StringView(line, eqIdx + 1);

			if (Guid.Parse(guidStr) case .Ok(let guid))
				Register(guid, path);
		}

		return .Ok;
	}
}
