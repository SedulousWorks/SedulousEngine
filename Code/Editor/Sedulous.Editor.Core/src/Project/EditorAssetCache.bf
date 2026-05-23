namespace Sedulous.Editor.Core;

using System;
using System.IO;
using System.Collections;
using Sedulous.Serialization;

/// Per-asset editor-side state, stored separately from the asset files
/// themselves. Used for editor preferences that shouldn't be baked into
/// the persisted asset:
///   - Preview rig assignments on `.skinnedmesh` / `.animation` files
///     (clip + skeleton to render against).
///   - Animation-graph node layout (positions aren't in `.animgraph`).
///   - Particle preview camera, prop-anim preview source target, etc.
///
/// Storage: `<projectRoot>/.editor/asset-cache` written through the
/// project's `ISerializerProvider` (same format `.sedproj` uses).
/// Keyed by `assetUri -> (key -> value)` string bags. Writes Save()
/// inline so per-pick changes survive a crash without needing an
/// explicit flush from the page.
class EditorAssetCache
{
	private String mFilePath = new .() ~ delete _;
	private ISerializerProvider mSerializer;

	private Dictionary<String, Dictionary<String, String>> mEntries = new .() ~ {
		FreeEntries(_);
		delete _;
	};

	public bool IsOpen => mFilePath.Length > 0;

	public void SetSerializerProvider(ISerializerProvider provider) => mSerializer = provider;

	/// Open the cache for `projectDirectory`. Creates the `.editor/`
	/// folder if missing. Existing cache file is loaded; absent file is
	/// treated as empty.
	public Result<void> Open(StringView projectDirectory)
	{
		Close();

		let editorDir = scope String();
		Path.InternalCombine(editorDir, projectDirectory, ".editor");
		if (!Directory.Exists(editorDir))
		{
			if (Directory.CreateDirectory(editorDir) case .Err)
				return .Err;
		}

		Path.InternalCombine(mFilePath, editorDir, "asset-cache");
		if (File.Exists(mFilePath)) return Load();
		return .Ok;
	}

	public void Close()
	{
		if (IsOpen) Save();
		ClearAll();
		mFilePath.Clear();
	}

	/// Returns the cached value for `(assetUri, key)`, or an empty
	/// `StringView` if no entry exists.
	public StringView Get(StringView assetUri, StringView key)
	{
		if (mEntries.TryGetAlt(assetUri, ?, let bag))
		{
			if (bag.TryGetAlt(key, ?, let value))
				return value;
		}
		return "";
	}

	/// Writes `(assetUri, key) = value`. Persists immediately so a
	/// caller doesn't have to remember to flush.
	public void Set(StringView assetUri, StringView key, StringView value)
	{
		Dictionary<String, String> bag;
		if (!mEntries.TryGetAlt(assetUri, ?, out bag))
		{
			bag = new .();
			mEntries[new String(assetUri)] = bag;
		}
		if (bag.TryGetAlt(key, ?, let existing))
		{
			existing.Set(value);
		}
		else
		{
			bag[new String(key)] = new String(value);
		}
		Save();
	}

	/// Removes `(assetUri, key)` if present. Persists.
	public void Clear(StringView assetUri, StringView key)
	{
		if (!mEntries.TryGetAlt(assetUri, ?, let bag)) return;
		for (var kv in bag)
		{
			if (StringView(kv.key) == key)
			{
				delete kv.key;
				delete kv.value;
				@kv.Remove();
				Save();
				return;
			}
		}
	}

	public Result<void> Save()
	{
		if (!IsOpen || mSerializer == null) return .Err;
		let writer = mSerializer.CreateWriter();
		if (writer == null) return .Err;
		defer delete writer;
		Serialize(writer);
		let output = scope String();
		mSerializer.GetOutput(writer, output);
		return File.WriteAllText(mFilePath, output);
	}

	private Result<void> Load()
	{
		ClearAll();
		if (mSerializer == null) return .Err;

		let content = scope String();
		if (File.ReadAllText(mFilePath, content) case .Err) return .Err;
		let reader = mSerializer.CreateReader(content);
		if (reader == null) return .Err;
		defer delete reader;

		Serialize(reader);
		return .Ok;
	}

	private void Serialize(Serializer s)
	{
		var assetCount = (int32)mEntries.Count;
		s.BeginArray("Assets", ref assetCount);

		if (s.IsWriting)
		{
			for (let kv in mEntries)
			{
				s.BeginObject("");
				String uri = scope .(kv.key);
				s.String("uri", uri);
				var bagCount = (int32)kv.value.Count;
				s.BeginArray("entries", ref bagCount);
				for (let inner in kv.value)
				{
					s.BeginObject("");
					String k = scope .(inner.key);
					String v = scope .(inner.value);
					s.String("key", k);
					s.String("value", v);
					s.EndObject();
				}
				s.EndArray();
				s.EndObject();
			}
		}
		else
		{
			for (int32 i = 0; i < assetCount; i++)
			{
				s.BeginObject("");
				let uri = new String();
				s.String("uri", uri);
				let bag = new Dictionary<String, String>();
				int32 bagCount = 0;
				s.BeginArray("entries", ref bagCount);
				for (int32 j = 0; j < bagCount; j++)
				{
					s.BeginObject("");
					let k = new String();
					let v = new String();
					s.String("key", k);
					s.String("value", v);
					bag[k] = v;
					s.EndObject();
				}
				s.EndArray();
				mEntries[uri] = bag;
				s.EndObject();
			}
		}

		s.EndArray();
	}

	private static void FreeEntries(Dictionary<String, Dictionary<String, String>> entries)
	{
		for (let kv in entries)
		{
			delete kv.key;
			for (let inner in kv.value) { delete inner.key; delete inner.value; }
			delete kv.value;
		}
	}

	private void ClearAll()
	{
		FreeEntries(mEntries);
		mEntries.Clear();
	}
}
