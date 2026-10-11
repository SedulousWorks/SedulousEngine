using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// Add Component is a picker with a search field: the categories with their components,
/// narrowed as you type by a component's name or its category's; the first match is selected,
/// so typing and Enter adds it.
class ComponentPickerDialogTests
{
	private static ComponentChoice Choice(StringView label, StringView category, Type type, StringView description)
	{
		let choice = new ComponentChoice();
		choice.Label.Set(label);
		choice.Category.Set(category);
		choice.Type = type;
		choice.Description.Set(description);
		return choice;
	}

	[Test]
	public static void SearchByNameOrCategoryAndTheFirstMatchIsThePick()
	{
		// Stand-ins: the picker hands back the type it was given.
		let light = typeof(int32);
		let mesh = typeof(float);
		let body = typeof(bool);
		let choices = new List<ComponentChoice>();
		choices.Add(Choice("Light", "Rendering", light, "Lights the scene."));
		choices.Add(Choice("Mesh", "Rendering", mesh, "Draws a mesh."));
		choices.Add(Choice("Rigid Body", "Physics", body, ""));
		let picker = new ComponentPickerDialog(choices);
		defer picker.ReleaseRef();
		Type picked = null;
		picker.OnPicked = new [&picked](type) => { picked = type; };
		Test.Assert(picker.ShownComponentCount == 3);
		Test.Assert(picker.SelectedType == light, "the first, selected");
		Test.Assert(picker.DescriptionText == "Lights the scene.", "said under the list");

		void Type(StringView text)
		{
			picker.FilterField.SetText(text);
			picker.FilterField.OnTextChanged(picker.FilterField);
		}
		Type("MES");
		Test.Assert(picker.ShownComponentCount == 1);
		Test.Assert(picker.SelectedType == mesh);
		Test.Assert(picker.DescriptionText == "Draws a mesh.");
		Type("physics"); // a category finds all of it
		Test.Assert(picker.ShownComponentCount == 1);
		Test.Assert(picker.SelectedType == body);
		Type("nothing like it");
		Test.Assert(picker.ShownComponentCount == 0);
		Test.Assert(picker.SelectedType == null);
		picker.Pick();
		Test.Assert(picked == null, "nothing to add");

		Type("light");
		picker.FilterField.OnSubmit(picker.FilterField); // Enter adds the match
		Test.Assert(picked == light);
	}
}
