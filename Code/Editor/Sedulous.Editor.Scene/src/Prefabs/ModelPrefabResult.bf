using Sedulous.Content;

namespace Sedulous.Editor.Scene;

/// What generating a prefab or scene from a model manifest produced.
struct ModelPrefabResult
{
	/// The prefab or scene instance, borrowed from its database; null when generation failed.
	public Instance Instance = null;
	/// An existing instance was refreshed, on a re-import.
	public bool Regenerated = false;

	public this() {}
}
