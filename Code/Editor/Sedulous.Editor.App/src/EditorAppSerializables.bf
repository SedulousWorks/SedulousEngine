using Sedulous.Core.Serialization;

namespace Sedulous.Editor.App;

/// Registers the app-side settings section types; once at startup, before any store loads.
/// The generated RegisterAll covers the [Serializable] sections in this namespace; the
/// hand-written dock layout section is added beside it.
[SerializableRegistry]
static class EditorAppSerializables
{
	public static void RegisterEditorProjectSettingsTypes(SerializableRegistry registry = null)
	{
		RegisterAll(registry);
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf(typeof(EditorDockLayoutSettings).GetFullName(.. scope .())), () => new EditorDockLayoutSettings());
	}
}
