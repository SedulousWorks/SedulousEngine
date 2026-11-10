using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Composition;

/// What an export needs from the full scene composition, for every host that exports: the
/// scene streams transcoded to the binary wire, and a scene's direct references. Both load
/// over EVERY manager, since a hand kept set silently drops the records it does not cover.
static class SceneExportSupport
{
	public const String cSceneStream = "scene";

	/// Whether a content instance is a scene or a prefab document.
	public static bool IsSceneLike(Instance instance)
	{
		let name = instance.TypeName;
		return name.EndsWith(".SceneDocument") || name.EndsWith(".PrefabDocument");
	}

	/// Every scene's and prefab's TEXT source under `group` transcoded to the binary wire,
	/// by guid; a prefab without its settings, a scene with. The caller owns the lists.
	public static void CollectSceneStreams(Group group, Dictionary<Guid, List<uint8>> outStreams)
	{
		for (let instance in group.Instances)
		{
			if (!IsSceneLike(instance))
				continue;
			let stream = instance.ReadData(cSceneStream);
			if (stream == null)
				continue;
			defer delete stream;
			let scratch = scope Scene("__export_transcode");
			EngineSceneComposition.AddAllSceneManagers(scratch);
			let bytes = new List<uint8>();
			if (SceneTranscode.ToBinary(stream, scratch, bytes, instance.TypeName.EndsWith(".SceneDocument")) case .Ok)
			{
				if (outStreams.GetAndRemove(instance.Id) case .Ok(let old))
					delete old.value;
				outStreams[instance.Id] = bytes;
			}
			else
			{
				delete bytes;
			}
		}
		for (let child in group.Groups)
			CollectSceneStreams(child, outStreams);
	}

	/// A scene's or prefab's DIRECT references: the component resource Refs, through a
	/// factory less ResourceManager whose every bind lands unresolved, and the ids its systems
	/// name without binding (a behaviour's scene field), into `outResources`; the parked
	/// prefab instance ids into `outPrefabs`. False when the stored stream does not load.
	///
	/// The placed prefab instances are spawned from `db` before the scan, with the scene's
	/// overrides applied, so what an instance's override names (a mesh swapped on one
	/// placement) is a reference of the scene's. What the prefab itself
	/// names comes along too, which its own scan also finds. A prefab missing from `db` is
	/// skipped with the warning a scene load gives.
	public static bool ScanSceneReferences(Instance instance, ContentDatabase db, List<Guid> outResources, List<Guid> outPrefabs)
	{
		let scratch = scope Scene("__export_scan");
		EngineSceneComposition.AddAllSceneManagers(scratch);
		if (SceneStorage.LoadScene(instance, scratch) case .Err)
			return false;
		// The placed ids first: the spawn below takes the parked records.
		scratch.ForEachPendingPrefabInstance(scope [&](pending) => { outPrefabs.Add(pending.PrefabId); });
		if (scratch.PendingPrefabInstanceCount > 0)
		{
			// The spawn owns each stream it is handed; a nested prefab resolves through the
			// same reader, one level at a time.
			ScenePrefabs.PayloadResolver resolver = scope (prefabId) =>
			{
				let prefab = db.GetInstance(prefabId);
				return (prefab != null) ? prefab.ReadData(cSceneStream) : null;
			};
			ScenePrefabs.ResolveScenePrefabs(scratch, resolver);
		}
		let collector = scope ResourceManager(db);
		// Unresolved is the answer here: each bind would otherwise log a missing factory.
		collector.ReportsMissingFactories = false;
		SceneResolve.ResolveSceneResources(scratch, collector);
		collector.CollectUnresolved(outResources);
		let unbound = scope List<Guid>();
		for (let system in scratch.Systems)
			system.CollectUnboundReferences(unbound);
		for (let id in unbound)
		{
			if (!outResources.Contains(id))
				outResources.Add(id);
		}
		return true;
	}
}
