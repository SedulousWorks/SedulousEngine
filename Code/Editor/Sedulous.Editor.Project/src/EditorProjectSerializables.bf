using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Project;

/// The registration of every [Serializable] type in the headless project half (the recent
/// projects section, the export presets, roots and templates), generated from the
/// declarations. Hosts without an editor call it themselves; the editor reaches it through
/// EditorSerializables.
[SerializableRegistry]
static class EditorProjectSerializables
{
}
