using Sedulous.Core.Serialization;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core;

/// The one registration of every editor settings section type: the editor facing half's
/// and the headless project half's, both generated from the declarations. A section type
/// lives where its domain lives, but they are all registered here, because a section a store
/// cannot instantiate makes Load abort at that section and silently drop everything after it:
/// the empty project list incident. Once at startup, before the settings load.
static class EditorSerializables
{
	/// Into the global registry unless another is given.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		EditorProjectSerializables.RegisterAll(registry);
		EditorCoreSerializables.RegisterAll(registry);
	}
}

/// The editor facing half's [Serializable] types (the settings sections), generated.
[SerializableRegistry]
static class EditorCoreSerializables
{
}
