using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Engine.SceneSurface;

namespace Sedulous.Editor.Mcp;

/// A scene's or prefab's DIRECT references, the way the export's reachability scan finds
/// them, over the full manager set. Shared by asset_uses, project_health and project_export.
static class SceneReferences
{
	/// False when the stored stream does not load: project_health counts those, asset_uses
	/// skips them.
	public static bool Collect(Instance instance, ContentDatabase db, List<Guid> outResources, List<Guid> outPrefabs)
		=> SceneExportSupport.ScanSceneReferences(instance, db, outResources, outPrefabs);

	public static bool Contains(List<Guid> list, Guid id) => list.Contains(id);
}
