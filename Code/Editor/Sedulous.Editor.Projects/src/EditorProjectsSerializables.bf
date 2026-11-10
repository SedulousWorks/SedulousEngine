using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Projects;

/// The registration of every [Serializable] type in the project and build library (the recent
/// projects section and its entry), generated from the declarations. A host that has only this
/// library calls it itself; the editor reaches it through EditorSerializables.
[SerializableRegistry]
static class EditorProjectsSerializables
{
}
