using Sedulous.Editor.Core;

namespace Sedulous.Editor.Navigation;

/// The Preferences contribution and the live toggle values.
static class NavigationEditorPreferences
{
	/// Registers the Navigation category into the Preferences dialog; from registerEditors.
	public static void Register(EditorContext context)
	{
		NavigationEditorSerializables.RegisterAll(); // idempotent belt for odd boot orders
		let contribution = new EditorSettingsContribution("Navigation");
		contribution.Bools.Add(new EditorSettingsBoolField("Parallel navmesh bake",
			"Bake navmesh tiles across worker threads. The output is byte-identical either way - this only trades bake latency.",
			new [=context]() => ParallelBakeEnabled(context),
			new [=context](value) =>
			{
				if (let store = context.UserEditorSettings)
				{
					store.Section<NavigationEditorSettings>().ParallelBake = value;
					store.MarkChanged<NavigationEditorSettings>();
				}
			}));
		context.RegisterEditorSettingsContribution(contribution);
	}

	/// The live toggle; the default applies when no store is wired, headless and in tests.
	public static bool ParallelBakeEnabled(EditorContext context)
	{
		let store = context.UserEditorSettings;
		if (store == null)
			return true;
		let section = store.Find<NavigationEditorSettings>();
		return (section == null) || section.ParallelBake;
	}
}
