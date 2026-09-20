using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.SceneSurface;

namespace Sedulous.Editor.Mcp;

/// A scene's or prefab's DIRECT references, the way the export's reachability scan finds
/// them: the component resource Refs, through a factory less ResourceManager whose every
/// bind lands unresolved and whose unresolved set is therefore the Ref list, plus the parked
/// prefab instance ids. The scratch carries the full manager set, so no component's Refs
/// are invisible. Shared by asset_uses and project_health.
static class SceneReferences
{
	/// False when the stored stream does not load: project_health counts those, asset_uses
	/// skips them.
	public static bool Collect(Instance instance, ContentDatabase db, List<Guid> outResources,
		List<Guid> outPrefabs)
	{
		let scratch = scope Scene("references");
		EngineSceneComposition.AddAllSceneManagers(scratch);
		if (SceneStorage.LoadScene(instance, scratch) case .Err)
			return false;
		let collector = scope ResourceManager(db);
		SceneResolve.ResolveSceneResources(scratch, collector);
		collector.CollectUnresolved(outResources);
		scratch.ForEachPendingPrefabInstance(scope [&](pending) => { outPrefabs.Add(pending.PrefabId); });
		return true;
	}

	public static bool Contains(List<Guid> list, Guid id)
	{
		for (let entry in list)
			if (entry == id)
				return true;
		return false;
	}
}
