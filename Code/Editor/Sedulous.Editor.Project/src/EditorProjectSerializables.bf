using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Project;

/// The registration of every [Serializable] type in the headless project half (the export
/// presets and roots), generated from the declarations; the recent projects section is
/// Sedulous.Editor.Projects', registered by EditorProjectsSerializables. Hosts without an editor
/// call it themselves; the editor reaches it through EditorSerializables.
[SerializableRegistry]
static class EditorProjectSerializables
{
}
