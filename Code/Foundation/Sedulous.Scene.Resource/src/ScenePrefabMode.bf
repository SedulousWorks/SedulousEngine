namespace Sedulous.Scene.Resource;

/// How prefab instances are written into a scene stream.
enum ScenePrefabMode : uint8
{
	/// The instance's members are EXCLUDED from the plain entity and component arrays:
	/// they respawn from their prefab on load, and only the reference plus the deltas
	/// persist. What a saved scene uses.
	Referenced = 0,

	/// The members serialize flat like any other entity, with the instance state, member
	/// maps and baselines, written verbatim beside them. A restore then rebuilds the exact
	/// bookkeeping WITHOUT needing to resolve a payload, which is what makes a snapshot,
	/// such as entering play in an editor, self contained.
	Expanded = 1
}
