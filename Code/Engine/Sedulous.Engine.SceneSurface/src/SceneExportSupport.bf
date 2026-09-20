using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.SceneSurface;

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
	/// factory less ResourceManager whose every bind lands unresolved, plus the parked prefab
	/// instance ids. False when the stored stream does not load.
	public static bool ScanSceneReferences(Instance instance, ContentDatabase db, List<Guid> outResources, List<Guid> outPrefabs)
	{
		let scratch = scope Scene("__export_scan");
		EngineSceneComposition.AddAllSceneManagers(scratch);
		if (SceneStorage.LoadScene(instance, scratch) case .Err)
			return false;
		let collector = scope ResourceManager(db);
		SceneResolve.ResolveSceneResources(scratch, collector);
		collector.CollectUnresolved(outResources);
		scratch.ForEachPendingPrefabInstance(scope [&](pending) => { outPrefabs.Add(pending.PrefabId); });
		return true;
	}
}
