using System;
using Sedulous.Core.Serialization;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;
using Sedulous.Editor.Look;

namespace Sedulous.Editor.Core;

/// The one registration of every editor settings section type: the editor facing half's,
/// the headless project half's, the project and build library's and the look's, each generated
/// from the declarations. A section type
/// lives where its domain lives, but they are all registered here, because a section a store
/// cannot instantiate makes Load abort at that section and silently drop everything after it:
/// the empty project list incident. Once at startup, before the settings load.
static class EditorSerializables
{
	/// Into the global registry unless another is given.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		EditorLookSerializables.RegisterAll(registry);
		EditorProjectsSerializables.RegisterAll(registry);
		EditorProjectSerializables.RegisterAll(registry);
		EditorCoreSerializables.RegisterAll(registry);
		// Hand written (it reads the version before its chord was text), so the generated
		// RegisterAll does not see it.
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(ShortcutOverrideEntry.TypeId, () => new ShortcutOverrideEntry());
		// What was saved before a section moved still loads under its current name. A rename is
		// one step, so each former name maps to where the type is now. The export presets and
		// roots moved from Editor.Core to the headless project half (961f2b37); the recent list
		// went there too, then on to the project and build library; the UI section went to the
		// look's library.
		for (let name in StringView[?]("ExportPresetSet", "ExportPreset", "ExportRootsSet"))
		{
			SerializableRenames.Register(scope $"Sedulous.Editor.Core.{name}", scope $"Sedulous.Editor.Project.{name}");
		}
		for (let name in StringView[?]("RecentProjectsSettings", "RecentProjectEntry"))
		{
			SerializableRenames.Register(scope $"Sedulous.Editor.Core.{name}", scope $"Sedulous.Editor.Projects.{name}");
			SerializableRenames.Register(scope $"Sedulous.Editor.Project.{name}", scope $"Sedulous.Editor.Projects.{name}");
		}
		SerializableRenames.Register("Sedulous.Editor.Core.EditorUiSettings", "Sedulous.Editor.Look.EditorUiSettings");
	}
}

/// The editor facing half's [Serializable] types (the settings sections), generated.
[SerializableRegistry]
static class EditorCoreSerializables
{
}
