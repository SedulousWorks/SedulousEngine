namespace TowerDefense;

using System;
using System.Collections;
using System.IO;
using Sedulous.Resources;

/// Lightweight model reference data - just GUIDs and protocol paths.
/// Used by runtime systems to construct ResourceRefs for entity creation.
/// Populated from ModelRegistry on first run, loaded from file on cached runs.
class ModelManifestEntry
{
	public String Name = new .() ~ delete _;
	public Guid MeshGuid;
	public String MeshPath = new .() ~ delete _;
	public List<Guid> MaterialGuids = new .() ~ delete _;
	public List<String> MaterialPaths = new .() ~ { for (let s in _) delete s; delete _; };

	public ResourceRef GetMeshRef()
	{
		return ResourceRef(MeshGuid, MeshPath);
	}

	public ResourceRef GetMaterialRef(int32 slot)
	{
		if (slot >= 0 && slot < MaterialGuids.Count)
			return ResourceRef(MaterialGuids[slot], MaterialPaths[slot]);
		return .();
	}

	public int32 MaterialCount => (int32)MaterialGuids.Count;
}

/// Maps model names to their resource GUIDs and paths.
/// Serialized to/from a simple text file.
class ModelManifest
{
	private Dictionary<String, ModelManifestEntry> mEntries = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};

	/// Gets an entry by model name, or null if not found.
	public ModelManifestEntry Get(StringView name)
	{
		if (mEntries.TryGetValue(scope String(name), let entry))
			return entry;
		return null;
	}

	/// Adds an entry. Takes ownership.
	public void Add(ModelManifestEntry entry)
	{
		mEntries[new String(entry.Name)] = entry;
	}

	/// Saves the manifest to a text file.
	/// Format: name=meshGuid:meshPath|matGuid1:matPath1,matGuid2:matPath2
	public Result<void> SaveToFile(StringView path)
	{
		let sb = scope String();

		for (let kv in mEntries)
		{
			let entry = kv.value;
			sb.AppendF("{}={}:{}", entry.Name, entry.MeshGuid, entry.MeshPath);
			if (entry.MaterialGuids.Count > 0)
			{
				sb.Append('|');
				for (int i = 0; i < entry.MaterialGuids.Count; i++)
				{
					if (i > 0) sb.Append(',');
					sb.AppendF("{}:{}", entry.MaterialGuids[i], entry.MaterialPaths[i]);
				}
			}
			sb.Append('\n');
		}

		return File.WriteAllText(path, sb);
	}

	/// Loads the manifest from a text file.
	public Result<void> LoadFromFile(StringView path)
	{
		let text = scope String();
		if (File.ReadAllText(path, text) case .Err)
			return .Err;

		for (let line in text.Split('\n'))
		{
			if (line.IsEmpty) continue;

			let eqIdx = line.IndexOf('=');
			if (eqIdx < 0) continue;

			let name = line[...(eqIdx - 1)];
			let rest = line[(eqIdx + 1)...];

			let entry = new ModelManifestEntry();
			entry.Name.Set(name);

			// Parse mesh part (before |) and optional materials (after |)
			let pipeIdx = rest.IndexOf('|');
			StringView meshPart = (pipeIdx >= 0) ? rest[...(pipeIdx - 1)] : rest;
			StringView matsPart = (pipeIdx >= 0) ? rest[(pipeIdx + 1)...] : default;

			// Parse mesh: guid:path
			let meshColonIdx = meshPart.IndexOf(':');
			if (meshColonIdx >= 0)
			{
				let guidStr = scope String(meshPart[...(meshColonIdx - 1)]);
				if (Guid.Parse(guidStr) case .Ok(let guid))
					entry.MeshGuid = guid;
				entry.MeshPath.Set(meshPart[(meshColonIdx + 1)...]);
			}

			// Parse materials: guid1:path1,guid2:path2
			if (matsPart.Length > 0)
			{
				for (let matEntry in matsPart.Split(','))
				{
					if (matEntry.IsEmpty) continue;
					let colonIdx = matEntry.IndexOf(':');
					if (colonIdx < 0) continue;

					let matGuidStr = scope String(matEntry[...(colonIdx - 1)]);
					if (Guid.Parse(matGuidStr) case .Ok(let matGuid))
					{
						entry.MaterialGuids.Add(matGuid);
						entry.MaterialPaths.Add(new String(matEntry[(colonIdx + 1)...]));
					}
				}
			}

			mEntries[new String(name)] = entry;
		}

		return .Ok;
	}

	/// Builds a manifest from a ModelRegistry (after models are loaded).
	public static ModelManifest BuildFromRegistry(ModelRegistry registry)
	{
		let manifest = new ModelManifest();

		for (let loaded in registry.[Friend]mLoadedModels)
		{
			let entry = new ModelManifestEntry();
			entry.Name.Set(loaded.Name);
			entry.MeshGuid = loaded.MeshResource.Id;
			entry.MeshPath.Set(loaded.MeshRefPath);

			for (let matRef in loaded.MaterialRefs)
			{
				entry.MaterialGuids.Add(matRef.Id);
				entry.MaterialPaths.Add(new String(matRef.Path));
			}

			manifest.Add(entry);
		}

		return manifest;
	}
}
