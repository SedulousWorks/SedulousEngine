using System;
using System.Collections;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// Preferences shows a tab per category, not one long column: the editor's own, then one per
/// domain-contributed category, contributions naming the same category sharing its tab.
static class EditorPreferencesDialogTests
{
	/// Every view of type T under `view`, in tree order, through the visual children: a
	/// dialog's layout and a scroll view's content are those.
	private static void Collect<T>(View view, List<T> outViews) where T : View
	{
		if (let typed = view as T)
			outViews.Add(typed);
		if (let group = view as ViewGroup)
		{
			for (int i < group.VisualChildCount)
			{
				if (let child = group.GetVisualChild(i))
					Collect(child, outViews);
			}
		}
	}

	private static Button ButtonNamed(View view, StringView text)
	{
		let buttons = scope List<Button>();
		Collect(view, buttons);
		for (let button in buttons)
		{
			if (button.Text.Value == text)
				return button;
		}
		return null;
	}

	/// The user's preview resolutions are rows, one per entry of the store's section; Add
	/// appends one, Remove takes one out (applied on Save).
	[Test]
	public static void ThePreviewResolutionsAreRowsThatAddAndRemove()
	{
		let context = scope EditorContext();
		let store = scope Settings();
		let previews = store.Section<GamePreviewSettings>();
		previews.Seeded = true; // the user's own list, not the seeded one
		previews.Presets.Add(new .("Deck", 1280, 800));
		previews.Presets.Add(new .("Phone", 1080, 2400));

		let dialog = new EditorPreferencesDialog(context, store);
		defer dialog.ReleaseRef();
		Test.Assert(dialog.PreviewRowCount == 2);
		let add = ButtonNamed(dialog, "Add resolution");
		Test.Assert(add != null);
		add.FireClick();
		Test.Assert(dialog.PreviewRowCount == 3);
		let remove = ButtonNamed(dialog, "Remove");
		Test.Assert(remove != null);
		remove.FireClick();
		Test.Assert(dialog.PreviewRowCount == 2);
	}

	[Test]
	public static void ATabPerCategoryContributionsSharingTheirCategorys()
	{
		var navigationFlag = false;
		let context = scope EditorContext();
		void Contribute(StringView category, StringView label)
		{
			let contribution = new EditorSettingsContribution(category);
			contribution.Bools.Add(new EditorSettingsBoolField(label, "",
				new [&]() => navigationFlag, new [&](value) => { navigationFlag = value; }));
			context.RegisterEditorSettingsContribution(contribution);
		}
		Contribute("Navigation", "Show the navmesh");
		Contribute("Audio", "Mute in the background");
		Contribute("Navigation", "Show the bake bounds");
		let store = scope Settings();

		let dialog = new EditorPreferencesDialog(context, store);
		defer dialog.ReleaseRef();
		let tabs = dialog.Tabs;
		Test.Assert(tabs.TabCount == 7);
		Test.Assert(dialog.TabIndexOf("Appearance") == 0);
		Test.Assert(dialog.TabIndexOf("Export") == 1);
		Test.Assert(dialog.TabIndexOf("Agent access") == 2);
		Test.Assert(dialog.TabIndexOf("Game preview") == 3);
		Test.Assert(dialog.TabIndexOf("Shortcuts") == 4);
		Test.Assert(dialog.TabIndexOf("Navigation") == 5);
		Test.Assert(dialog.TabIndexOf("Audio") == 6);
		Test.Assert(tabs.SelectedIndex == 0);

		// Both Navigation fields are on its tab, and they still write through their closures.
		let boxes = scope List<CheckBox>();
		Collect(tabs.GetTab(5).Content, boxes);
		Test.Assert(boxes.Count == 2);
		Test.Assert(boxes[0].Text.Value == "Show the navmesh");
		Test.Assert(boxes[1].Text.Value == "Show the bake bounds");
		boxes[0].IsChecked.Value = true;
		Test.Assert(navigationFlag);
	}
}
