namespace Sedulous.Resources;

using System;
using System.Collections;
using System.IO;
using System.Threading;

/// Default implementation of IResourceRegistry using in-memory dictionaries.
/// Thread-safe via Monitor. Can be populated programmatically or from a manifest.
///
/// Each registry has a name (protocol prefix) and a root path. Internal paths
/// are stored relative (e.g. "primitives/cube.mesh"). TryResolvePath prepends
/// the protocol prefix (e.g. "builtin://primitives/cube.mesh"). ResolvePath
/// combines root + relative to get an absolute filesystem path.
class ResourceRegistry : IResourceRegistry
{
	private Monitor mMonitor = new .() ~ delete _;
	private Dictionary<Guid, String> mIdToPath = new .() ~ DeleteDictionaryAndValues!(_);
	private Dictionary<String, Guid> mPathToId = new .() ~ delete _; // Keys shared with mIdToPath values
	private String mName = new .() ~ delete _;
	private String mRootPath = new .() ~ delete _;

	/// Creates a registry with a name (protocol) and root path.
	public this(StringView name = default, StringView rootPath = default)
	{
		if (name.Length > 0)
			mName.Set(name);
		if (rootPath.Length > 0)
			mRootPath.Set(rootPath);
	}

	/// Registry name, used as protocol prefix (e.g. "builtin", "project").
	public StringView Name => mName;

	/// Root path for resolving relative asset paths.
	public StringView RootPath => mRootPath;

	/// Sets the root path (can be changed after construction, e.g. when project changes).
	public void SetRootPath(StringView rootPath)
	{
		mRootPath.Set(rootPath);
	}

	/// Registers a resource mapping (GUID <-> relative path).
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

	/// Resolves GUID to protocol-prefixed path (e.g. "builtin://primitives/cube.mesh").
	public bool TryResolvePath(Guid id, String outPath)
	{
		using (mMonitor.Enter())
		{
			if (mIdToPath.TryGetValue(id, let path))
			{
				if (mName.Length > 0)
					outPath.AppendF("{}://{}", mName, path);
				else
					outPath.Set(path);
				return true;
			}
			return false;
		}
	}

	/// Resolves a path to its GUID. Accepts both relative and protocol-prefixed paths.
	public bool TryResolveId(StringView path, out Guid outId)
	{
		using (mMonitor.Enter())
		{
			// Strip protocol prefix if present
			var lookupPath = path;
			if (mName.Length > 0)
			{
				let prefix = scope String()..AppendF("{}://", mName);
				if (path.StartsWith(prefix))
					lookupPath = path.Substring(prefix.Length);
			}

			for (let kv in mPathToId)
			{
				if (StringView(kv.key) == lookupPath)
				{
					outId = kv.value;
					return true;
				}
			}
			outId = .();
			return false;
		}
	}

	/// Resolves a relative path to an absolute filesystem path.
	/// Returns true if the file exists at the resolved location.
	public bool ResolvePath(StringView relativePath, String outAbsolutePath)
	{
		if (mRootPath.Length == 0)
			return false;

		Path.InternalCombine(outAbsolutePath, mRootPath, relativePath);
		return File.Exists(outAbsolutePath);
	}

	/// Enumerates all registered entries. Caller must not modify the registry during enumeration.
	/// Appends (guid, relativePath) pairs to the output list.
	public void GetEntries(List<(Guid id, StringView path)> outEntries)
	{
		using (mMonitor.Enter())
		{
			for (let kv in mIdToPath)
				outEntries.Add((kv.key, kv.value));
		}
	}

	/// Enumerates entries whose relative path starts with the given folder prefix.
	/// prefix should be "" for root, or "folder/" for a subfolder (with trailing slash).
	/// Only returns direct children (no deeper nesting beyond the prefix level).
	public void GetEntriesInFolder(StringView prefix, List<(Guid id, StringView path, StringView name)> outEntries)
	{
		using (mMonitor.Enter())
		{
			let prefixLen = prefix.Length;
			for (let kv in mIdToPath)
			{
				let path = StringView(kv.value);
				if (prefixLen > 0 && !path.StartsWith(prefix))
					continue;

				// Get the part after the prefix
				let remainder = path[prefixLen...];

				// Only direct children (no further '/' in remainder)
				if (remainder.Contains('/'))
					continue;

				outEntries.Add((kv.key, path, remainder));
			}
		}
	}

	/// Saves the registry to a text file. Format: one "guid=relativePath" per line.
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
