using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The single value editors. Each is checked BOTH ways: the control driving the editor, which
/// is what a user does, and the editor driving the control, which is what an external change
/// does.
class ScalarEditorTests
{
	[Test]
	public static void ABoolRoundTripsThroughItsCheckBox()
	{
		var observed = false;
		let editor = scope BoolEditor("Enabled", false, new [&](value) => { observed = value; });

		Test.Assert(editor.Name == "Enabled");
		Test.Assert(!editor.Value);

		let checkBox = editor.EditorView as CheckBox;
		Test.Assert(checkBox != null);

		checkBox.IsChecked.Value = true;
		Test.Assert(editor.Value);
		Test.Assert(observed);

		editor.SetValue(false);
		Test.Assert(!checkBox.IsChecked.Value);
	}

	[Test]
	public static void AButtonEditorInvokesItsAction()
	{
		var clicks = 0;
		let editor = scope ButtonEditor("Add Condition", new [&]() => { clicks++; });

		let button = editor.EditorView as Button;
		Test.Assert(button != null);

		button.OnClick(button);
		Test.Assert(clicks == 1);

		editor.RefreshView(); // an action row has no value, so this does nothing
	}

	/// Enabling applies BEFORE the lazy view exists, so an editor built disabled never shows a
	/// live button for a frame.
	[Test]
	public static void AButtonEditorsEnabledStateSurvivesLazyCreation()
	{
		let editor = scope ButtonEditor("Revert", null);
		Test.Assert(editor.ButtonEnabled);

		editor.SetButtonEnabled(false);
		let view = editor.EditorView;
		Test.Assert(view != null);
		Test.Assert(!view.IsEnabled);

		editor.SetButtonEnabled(true);
		Test.Assert(view.IsEnabled);
	}

	[Test]
	public static void AStringRoundTripsThroughSubmit()
	{
		let observed = scope String();
		let editor = scope StringEditor("Label", "hello",
			new [&](value) => { observed.Set(value); });

		Test.Assert(editor.Value == "hello");

		let editText = editor.EditorView as EditText;
		Test.Assert(editText != null);
		Test.Assert(editText.Text == "hello");

		editText.SetText("world");
		editText.OnSubmit(editText);
		Test.Assert(editor.Value == "world");
		Test.Assert(observed == "world");

		editor.SetValue("again");
		Test.Assert(editText.Text == "again");
	}

	[Test]
	public static void AnIntRoundTripsWithNoDecimalPlaces()
	{
		int64 observed = 0;
		let editor = scope IntEditor("Count", 5, 0, 100, new [&](value) => { observed = value; });

		Test.Assert(editor.Value == 5);

		let field = editor.EditorView as NumericField;
		Test.Assert(field != null);
		Test.Assert(field.DecimalPlaces == 0);

		field.SetValue(42.0);
		Test.Assert(editor.Value == 42);
		Test.Assert(observed == 42);

		editor.SetValue(7);
		Test.Assert(field.Value == 7.0);
	}

	[Test]
	public static void AFloatRoundTripsAtItsDeclaredPrecision()
	{
		var observed = 0.0;
		let editor = scope FloatEditor("Scale", 1.0, 0.0, 10.0, 0.1, 3,
			new [&](value) => { observed = value; });

		Test.Assert(editor.Value == 1.0);

		let field = editor.EditorView as NumericField;
		Test.Assert(field != null);
		Test.Assert(field.DecimalPlaces == 3);

		field.SetValue(2.5);
		Test.Assert(editor.Value == 2.5);
		Test.Assert(observed == 2.5);

		editor.SetValue(4.25);
		Test.Assert(field.Value == 4.25);
	}

	[Test]
	public static void AnEnumRoundTripsThroughItsComboBox()
	{
		int32 observed = -1;
		StringView[3] items = .("Opaque", "Cutout", "Transparent");
		let editor = scope EnumEditor("Blend", 0, items, new [&](value) => { observed = value; });

		Test.Assert(editor.Value == 0);

		let combo = editor.EditorView as ComboBox;
		Test.Assert(combo != null);
		Test.Assert(combo.ItemCount == 3);

		combo.SetSelectedIndex(2);
		Test.Assert(editor.Value == 2);
		Test.Assert(observed == 2);

		editor.SetValue(1);
		Test.Assert(combo.SelectedIndex == 1);
	}

	/// A range is one value shown twice, so moving either control has to move the other.
	[Test]
	public static void ARangeKeepsItsSliderAndFieldInStep()
	{
		var observed = 0.0f;
		let editor = scope RangeEditor("Opacity", 0.5f, 0.0f, 1.0f, 0.0f,
			new [&](value) => { observed = value; });

		Test.Assert(editor.Value == 0.5f);

		let row = editor.EditorView as FlexLayout;
		Test.Assert(row != null);
		Test.Assert(row.ChildCount == 2, "a slider and a field");

		let slider = row.GetChildAt(0) as Slider;
		let field = row.GetChildAt(1) as NumericField;
		Test.Assert(slider != null);
		Test.Assert(field != null);

		slider.Value.Value = 0.75f;
		Test.Assert(editor.Value == 0.75f);
		Test.Assert(observed == 0.75f);
		Test.Assert(field.Value == 0.75, "the field followed the slider");

		field.SetValue(0.125);
		Test.Assert(editor.Value == 0.125f);
		Test.Assert(slider.Value.Value == 0.125f, "and the slider follows the field");

		editor.SetValue(0.25f);
		Test.Assert(slider.Value.Value == 0.25f);
		Test.Assert(field.Value == 0.25);
	}
}
