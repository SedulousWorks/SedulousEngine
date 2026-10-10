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
	private static void CollectCheckBoxes(View view, List<CheckBox> outBoxes)
	{
		if (let check = view as CheckBox)
			outBoxes.Add(check);
		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
				CollectCheckBoxes(group.GetChildAt(i), outBoxes);
		}
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
		CollectCheckBoxes(tabs.GetTab(5).Content, boxes);
		Test.Assert(boxes.Count == 2);
		Test.Assert(boxes[0].Text.Value == "Show the navmesh");
		Test.Assert(boxes[1].Text.Value == "Show the bake bounds");
		boxes[0].IsChecked.Value = true;
		Test.Assert(navigationFlag);
	}
}
