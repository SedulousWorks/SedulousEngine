using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The one registration of every editor settings section type, generated from the
/// declarations. A section type lives where its domain lives, but they are all registered
/// here, because a section a store cannot instantiate makes Load abort at that section and
/// silently drop everything after it: the empty project list incident. Once at startup,
/// before the settings load.
[SerializableRegistry]
static class EditorSerializables
{
}
