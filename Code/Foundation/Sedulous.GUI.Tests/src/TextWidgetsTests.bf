using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// The text widgets beyond the ported tests: each built by its tag through its GUI table, with its
/// role, and its reflected properties set by a sheet's CSS names; a run of typing undone as one step
/// and redone; a copy and a paste from the context menu, its items lit where they would do
/// something; a password's mask under the caret and kept from the IME; a triple click and a
/// password's double click selecting all; a value cut short scrolling back; a text area's measured
/// lines and its wheel; a number field clamped at its minimum, let past its maximum and written
/// with its step's decimals; an editable label turned multiline; a colour through HSV and its hex
/// code and back.
class TextWidgetsTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1.2e-5 * (1.0 + Math.Max(Math.Abs(a), Math.Abs(b)));
	private static uint32 Key(KeyCode k) => (uint32)k;

	private static Float2 Centre(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	[Test]
	public static void EachTextWidgetTypeIsMadeByItsCreatorUnderItsTypesNameWithItsTagAndRole()
	{
		GuiTypeInfo[6] elements = .(TextField.StaticGuiType, TextArea.StaticGuiType, NumberField.StaticGuiType,
			EditableLabel.StaticGuiType, ColorSwatch.StaticGuiType, ColorPicker.StaticGuiType);
		String[6] tags = .("TextField", "TextArea", "NumberField", "EditableLabel", "ColorSwatch", "ColorPicker");
		String[6] cssTags = .("textfield", "textarea", "numberfield", "editablelabel", "colorswatch", "colorpicker");
		String[6] roles = .("textbox", "textarea", "spinbutton", "label", "button", "group");
		for (int i = 0; i < elements.Count; i++)
		{
			let info = elements[i];
			Test.Assert(info.Tag == tags[i], scope $"{tags[i]}: tagged {info.Tag}");
			Test.Assert(info.CanCreate);
			let made = info.Create() as Node;
			Test.Assert(made != null);
			Test.Assert(made.GetType() == info.Type);
			Test.Assert(made.GuiType == info); // an instance answers for its own type
			let widget = made as UIWidget;
			Test.Assert(widget.Tag == cssTags[i]); // what a sheet selects it by
			Test.Assert(widget.AccessRoleName == roles[i], scope $"{tags[i]}: role {widget.AccessRoleName}");
			made.ReleaseRef();
		}
		// Reflected, but no element: markup builds neither by a tag.
		Test.Assert(!TextEditBase.StaticGuiType.CanCreate);
		Test.Assert(!SpinButton.StaticGuiType.CanCreate);
		Test.Assert(NumberField.StaticGuiType.Is(TextField.StaticGuiType));
		Test.Assert(TextArea.StaticGuiType.Is(TextEditBase.StaticGuiType));
		Test.Assert(EditableLabel.StaticGuiType.Is(Label.StaticGuiType));
		Test.Assert(SpinButton.StaticGuiType.Is(ButtonBase.StaticGuiType));
	}

	[Test]
	public static void TheReflectedPropertiesCarryTheirCssNamesFlagsAndAccessNames()
	{
		let placeholder = TextField.StaticGuiType.FindCss("placeholder");
		Test.Assert(placeholder != null);
		Test.Assert(placeholder.IsTranslatable);
		Test.Assert(placeholder.Access == "description");
		let text = TextField.StaticGuiType.FindCss("text");
		Test.Assert(text != null);
		Test.Assert(text.IsTwoWay);
		Test.Assert(text.Access == "value");
		Test.Assert(TextField.StaticGuiType.FindCss("password").Access == "secret");
		Test.Assert(TextField.StaticGuiType.FindCss("max-length") != null);
		Test.Assert(TextField.StaticGuiType.FindCss("read-only") != null);
		Test.Assert(TextField.StaticGuiType.FindCss("input-filter") != null);
		Test.Assert(TextArea.StaticGuiType.FindCss("rows") != null);
		Test.Assert(TextArea.StaticGuiType.FindCss("password") == null); // a field's, not an area's
		let value = NumberField.StaticGuiType.FindCss("value");
		Test.Assert(value.IsTwoWay);
		Test.Assert(value.Access == "value");
		Test.Assert(NumberField.StaticGuiType.FindCss("min").Access == "min");
		Test.Assert(NumberField.StaticGuiType.FindCss("max").Access == "max");
		Test.Assert(NumberField.StaticGuiType.FindCss("step").Access == "step");
		String[6] numberCss = .("page", "integer", "prefix", "suffix", "allow-greater", "allow-lesser");
		for (let css in numberCss)
			Test.Assert(NumberField.StaticGuiType.FindCss(css) != null, css);
		Test.Assert(ColorPicker.StaticGuiType.FindCss("color-value").IsTwoWay);
		Test.Assert(ColorPicker.StaticGuiType.FindCss("shows-alpha") != null);
		Test.Assert(!ColorSwatch.StaticGuiType.FindCss("color-value").IsTwoWay);
	}

	[Test]
	public static void ASheetSetsEachTextWidgetsReflectedPropertiesByTheirCssNames()
	{
		let root = SceneFixtures.NewScene(600.0f, 600.0f);
		defer root.ReleaseRef();
		let field = new TextField();
		defer field.ReleaseRef();
		let area = new TextArea();
		defer area.ReleaseRef();
		let number = new NumberField();
		defer number.ReleaseRef();
		let swatch = new ColorSwatch();
		defer swatch.ReleaseRef();
		let picker = new ColorPicker();
		defer picker.ReleaseRef();
		UIWidget[5] widgets = .(field, area, number, swatch, picker);
		for (let w in widgets)
			root.AddChild(w);
		let styles = scope StyleManager();
		WidgetFixtures.UseSheet(styles, """
			textfield { max-length: 3; read-only: true; input-filter: digits; password: true; placeholder: Name; }
			textarea { rows: 5; }
			numberfield { min: -10; max: 10; step: 0.1; page: 2; allow-greater: true; }
			colorswatch { color-value: #ff0000; }
			colorpicker { shows-alpha: false; color-value: #3366cc; }
			""");
		styles.ApplyTree(root);
		Test.Assert(field.MaxLength == 3);
		Test.Assert(field.IsReadOnly);
		Test.Assert(field.InputFilterName == "digits");
		Test.Assert(field.IsPassword);
		Test.Assert(field.IsTextInputSecret);
		Test.Assert(field.Placeholder == "Name");
		Test.Assert(area.Rows == 5);
		Test.Assert(Near(number.Min, -10.0));
		Test.Assert(Near(number.Max, 10.0));
		Test.Assert(Near(number.Step, 0.1));
		Test.Assert(Near(number.Page, 2.0));
		Test.Assert(number.AllowGreater);
		Test.Assert(Near(swatch.ColorValue.R, 1.0f));
		Test.Assert(Near(swatch.ColorValue.G, 0.0f));
		Test.Assert(!picker.ShowsAlpha);
		Test.Assert(!picker.AlphaStrip.Displayed);
		Test.Assert(picker.HexField.Text == "#3366CC");
	}

	[Test]
	public static void ARunOfTypingIsUndoneAsOneStepAMoveEndsTheRunRedoBringsItBack()
	{
		let fx = scope FieldBed();
		fx.D.InjectText("a");
		fx.D.InjectText("b");
		fx.D.InjectText("c"); // one run: no time passed between them
		fx.D.InjectKeyDown(Key(.Z), KeyModCtrl);
		Test.Assert(fx.Field.Text.Length == 0);
		fx.D.InjectKeyDown(Key(.Z), KeyModCtrl | KeyModShift);
		Test.Assert(fx.Field.Text == "abc");
		fx.D.InjectKeyDown(Key(.Left)); // a move ends the run
		fx.D.InjectText("d");
		Test.Assert(fx.Field.Text == "abdc");
		fx.D.InjectKeyDown(Key(.Z), KeyModCtrl);
		Test.Assert(fx.Field.Text == "abc");
		fx.D.InjectKeyDown(Key(.Z), KeyModCtrl);
		Test.Assert(fx.Field.Text.Length == 0);
		fx.D.InjectKeyDown(Key(.Y), KeyModCtrl);
		Test.Assert(fx.Field.Text == "abc");
	}

	[Test]
	public static void ACopyAndAPasteFromTheContextMenuGoThroughTheClipboardEachItemLitWhereItWouldDoSomething()
	{
		let clip = scope TestClipboard();
		let fx = scope FieldBed("hello");
		fx.D.Clipboard = clip;
		fx.Field.Caret = 0;
		fx.D.InjectKeyDown(Key(.Right), KeyModShift);
		fx.D.InjectKeyDown(Key(.Right), KeyModShift); // "he" selected
		fx.D.InjectContextMenu();
		let menu = fx.Field.ContextMenu;
		Test.Assert((menu != null) && menu.IsOpen);
		let cut = menu.GetChildAt(0) as MenuItem;
		let copy = menu.GetChildAt(1) as MenuItem;
		let paste = menu.GetChildAt(2) as MenuItem;
		let all = menu.GetChildAt(4) as MenuItem;
		Test.Assert((cut != null) && (copy != null) && (paste != null) && (all != null));
		Test.Assert(cut.Enabled);
		Test.Assert(copy.Enabled);
		Test.Assert(!paste.Enabled); // the clipboard is empty
		Test.Assert(all.Enabled);
		Test.Assert(copy.Shortcut == "Ctrl+C");
		copy.HandleActivate();
		Test.Assert(clip.Text == "he");
		Test.Assert(!menu.IsOpen);

		fx.D.InjectKeyDown(Key(.End));
		fx.D.InjectContextMenu();
		Test.Assert(!cut.Enabled); // nothing selected
		Test.Assert(!copy.Enabled);
		Test.Assert(paste.Enabled);
		paste.HandleActivate();
		Test.Assert(fx.Field.Text == "hellohe");

		// Read only: what would edit is off, what would copy on.
		fx.Field.IsReadOnly = true;
		fx.Field.SelectAll();
		fx.D.InjectContextMenu();
		Test.Assert(!cut.Enabled);
		Test.Assert(copy.Enabled);
		Test.Assert(!paste.Enabled);
		Test.Assert(all.Enabled);
	}

	[Test]
	public static void APasswordsMaskStandsUnderTheCaretAndKeepsTheIMEOutUnmaskedItIsTheTextAgain()
	{
		let fx = scope FieldBed();
		fx.Field.IsPassword = true;
		fx.D.InjectText("s\u{00E9}cret");
		Test.Assert(fx.D.IsTextInputSecret);
		Test.Assert(!fx.Field.Model.CopyAllowed);
		// Each mark three bytes (18px): a press at 19 is after the first.
		fx.D.InjectMouseDown(.(19.0f, 12.0f), .Left);
		fx.D.InjectMouseUp(.(19.0f, 12.0f), .Left);
		Test.Assert(fx.Field.Caret == 1);
		Test.Assert(!fx.D.InjectComposition("xyz", 1)); // no IME in a password
		Test.Assert(fx.Field.Text == "s\u{00E9}cret");

		fx.Field.IsPassword = false;
		Test.Assert(!fx.D.IsTextInputSecret);
		Test.Assert(fx.Field.Model.CopyAllowed);
		// Unmasked, 19 is just past the é (s 0 to 6, é 6 to 18). A press elsewhere first, so the
		// next is no double click.
		fx.D.InjectMouseDown(.(150.0f, 12.0f), .Left);
		fx.D.InjectMouseUp(.(150.0f, 12.0f), .Left);
		fx.D.InjectMouseDown(.(19.0f, 12.0f), .Left);
		fx.D.InjectMouseUp(.(19.0f, 12.0f), .Left);
		Test.Assert(fx.Field.Caret == 3);

		// Nor does a read-only field compose.
		fx.Field.IsReadOnly = true;
		Test.Assert(!fx.D.InjectComposition("xyz", 1));
	}

	[Test]
	public static void ATripleClickSelectsEverythingAPasswordsDoubleClickSelectsAllOfIt()
	{
		{
			let fx = scope FieldBed("foo bar baz");
			let pos = Float2(5.0f * 6.0f + 3.0f, 12.0f);
			for (int i = 0; i < 3; i++)
			{
				fx.D.InjectMouseDown(pos, .Left);
				fx.D.InjectMouseUp(pos, .Left);
			}
			Test.Assert(fx.Field.SelectedText == "foo bar baz");
		}
		{
			let fx = scope FieldBed("ab cd");
			fx.Field.IsPassword = true;
			let pos = Float2(18.0f + 3.0f, 12.0f); // on the second mark
			fx.D.InjectMouseDown(pos, .Left);
			fx.D.InjectMouseUp(pos, .Left);
			fx.D.InjectMouseDown(pos, .Left);
			Test.Assert(fx.Field.SelectedText == "ab cd"); // a password is one word
		}
	}

	[Test]
	public static void AValueCutShortScrollsBackByTheLeastThatShowsTheCaret()
	{
		let fx = scope FieldBed(); // 200 wide, 6px a byte; the view is 198.5
		fx.D.InjectText("0123456789012345678901234567890123456789"); // 240px
		Test.Assert(Near(fx.Field.ScrollX, 240.0f - 198.5f));
		fx.D.InjectKeyDown(Key(.Backspace)); // 234px: no further than the text needs
		Test.Assert(Near(fx.Field.ScrollX, 234.0f - 198.5f));
		for (int i = 0; i < 9; i++)
			fx.D.InjectKeyDown(Key(.Backspace)); // 180px: it fits
		Test.Assert(Near(fx.Field.ScrollX, 0.0f));
	}

	[Test]
	public static void ATextAreaMeasuresItsWrappedLinesAndItsWheelScrollsItWithinItsText()
	{
		{
			// "alpha beta gamma" at 54 wide: three lines of 12.
			let bed = scope AreaBed("alpha beta gamma");
			let size = bed.Area.MeasureText(54.0f);
			Test.Assert(Near(size.Y, 36.0f));
			Test.Assert(size.X <= 54.0f);
			bed.Area.Text = "";
			let empty = bed.Area.MeasureText(54.0f);
			Test.Assert(Near(empty.X, 0.0f));
			Test.Assert(Near(empty.Y, 12.0f)); // a line tall
		}
		{
			let bed = scope AreaBed("1\n2\n3\n4\n5\n6\n7\n8"); // 96 tall in 36
			bed.D.InjectKeyDown(Key(.Home), KeyModCtrl);
			Test.Assert(Near(bed.Area.ScrollY, 0.0f));
			bed.D.InjectMouseWheel(.(10.0f, 10.0f), .(0.0f, -1.0f)); // three lines a notch
			Test.Assert(Near(bed.Area.ScrollY, 36.0f));
			bed.D.InjectMouseWheel(.(10.0f, 10.0f), .(0.0f, -1.0f));
			Test.Assert(Near(bed.Area.ScrollY, 60.0f)); // no further than its text
			bed.D.InjectMouseWheel(.(10.0f, 10.0f), .(0.0f, -1.0f)); // at its end it stays
			Test.Assert(Near(bed.Area.ScrollY, 60.0f));
		}
	}

	[Test]
	public static void ANumberFieldIsClampedAtItsMinimumLetPastItsMaximumAndWrittenWithItsStepsDecimals()
	{
		{
			let b = scope NumberBed();
			b.D.InjectMouseMove(Centre(b.Field.DownButton));
			b.D.InjectMouseDown(Centre(b.Field.DownButton), .Left);
			b.D.InjectMouseUp(Centre(b.Field.DownButton), .Left);
			Test.Assert(Near(b.Field.Value, 0.0)); // at its minimum already
			Test.Assert(b.Changes == 0);
			Test.Assert(b.Inputs == 0);

			b.Field.AllowGreater = true;
			b.ClickToEdit();
			b.D.InjectText("150");
			b.D.InjectKeyDown(Key(.Return));
			Test.Assert(Near(b.Field.Value, 150.0));
			Test.Assert(b.Field.Text == "150");
			Test.Assert(b.Changes == 1);
		}
		{
			let b = scope NumberBed();
			b.Field.Min = -10.0;
			b.Field.Max = 10.0;
			b.Field.Step = 0.1;
			b.Field.Value = 2.25;
			b.Field.Suffix = " m";
			Test.Assert(Near(b.Field.Value, 2.3)); // to the step
			Test.Assert(b.Field.Text == "2.3 m");
			let text = scope String();
			b.Field.FormatValue(-1.25, text);
			Test.Assert(text == "-1.3 m"); // halves away from zero
		}
	}

	[Test]
	public static void AnEditableLabelTurnedMultilineEditsInATextAreaFromThenOnAndNotWhileEditing()
	{
		let b = scope EditableBed();
		b.Editable.BeginEdit();
		Test.Assert(b.Editable.Editor is TextField);
		b.Editable.EndEdit(false);
		b.Editable.IsMultiline = true;
		Test.Assert(b.Editable.Editor == null); // the field it had goes
		b.Editable.BeginEdit();
		Test.Assert(b.Editable.Editor is TextArea);
		b.Editable.IsMultiline = false; // not while editing
		Test.Assert(b.Editable.IsMultiline);
		Test.Assert(b.Editable.EndEdit(true));
		Test.Assert(b.Commits == 0); // the same text: nothing to commit
		Test.Assert(b.Editable.Text == "layer 1");
	}

	[Test]
	public static void AColourGoesThroughHsvAndItsHexCodeAndBackUnchanged()
	{
		String[4] codes = .("#3366CC", "#FF8000", "#12AB9F", "#808080");
		let text = scope String();
		for (let code in codes)
		{
			let parsed = ParseColor(code);
			Test.Assert(parsed.HasValue, code);
			text.Clear();
			FormatHexColor(FromHsv(ToHsv(parsed.Value)), false, text);
			Test.Assert(text == code, scope $"{code}: {text}");
		}
		let translucent = ParseColor("#3366CC80");
		Test.Assert(translucent.HasValue);
		text.Clear();
		FormatHexColor(FromHsv(ToHsv(translucent.Value)), true, text);
		Test.Assert(text == "#3366CC80");
		text.Clear();
		FormatHexColor(translucent.Value, false, text);
		Test.Assert(text == "#3366CC");

		// A picker set to a colour shows its code, and gives the colour back.
		let bed = scope PickerBed();
		bed.Picker.ColorValue = ParseColor("#12AB9F").Value;
		Test.Assert(bed.Picker.HexField.Text == "#12AB9F");
		text.Clear();
		FormatHexColor(bed.Picker.ColorValue, true, text);
		Test.Assert(text == "#12AB9F");
		Test.Assert(bed.Steps == 0); // code reports nothing
		Test.Assert(bed.Changes == 0);
	}
}
