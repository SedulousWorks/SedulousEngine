using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// Every text entry control, each shown in the configurations that actually differ: a plain
/// field, a placeholder, read only, multi line, a length cap, an input filter, and the affix
/// slots; then the password box, the numeric field and the editable label.
static class TextInputTab
{
	public static void Build(TabView tabView)
	{
		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		tabView.AddTab("Text Input", scroll);

		let demo = SandboxViews.VFlex(8.0f);
		demo.Padding = .(12, 8);
		scroll.AddView(demo);

		AddEditTexts(demo);

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "PasswordBox");
		AddPasswordBoxes(demo);

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "NumericField");
		AddNumericFields(demo);
		AddVectorRow(demo);

		demo.AddView(new Spacer(0.0f, 4.0f));
		AddSection(demo, "EditableLabel (double-click to edit)");
		AddEditableLabels(demo);
	}

	private static LayoutStyle Wide => SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(300)),
		SizeSpec.Wrap());

	private static LayoutStyle Narrow => SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(200)),
		SizeSpec.Wrap());

	private static void AddSection(FlexLayout demo, StringView title)
	{
		let label = new Label();
		label.SetText(title);
		demo.AddView(label);
		demo.AddView(new Separator());
	}

	private static void AddEditTexts(FlexLayout demo)
	{
		AddSection(demo, "EditText");

		{
			let field = new EditText();
			field.SetText("Editable text");
			demo.AddView(field, Wide);
		}
		{
			let field = new EditText();
			field.SetPlaceholder("Enter name...");
			demo.AddView(field, Wide);
		}
		{
			let field = new EditText();
			field.SetText("Read-only text");
			field.IsReadOnly.Value = true;
			demo.AddView(field, Wide);
		}
		{
			let field = new EditText();
			field.Multiline.Value = true;
			field.SetText("Line 1\nLine 2\nLine 3");
			demo.AddView(field,
				SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(300)), SizeSpec.Fixed(Unit.Px(80))));
		}
		{
			let field = new EditText();
			field.MaxLength.Value = 10;
			field.SetPlaceholder("Max 10 chars");
			demo.AddView(field, Wide);
		}
		{
			let field = new EditText();
			field.SetFilter(InputFilter.Digits());
			field.SetPlaceholder("Digits only");
			demo.AddView(field, Wide);
		}
		{
			let field = new EditText();
			field.SetPrefix("$");
			field.SetText("100");
			demo.AddView(field, Wide);
		}
		{
			let field = new EditText();
			field.SetSuffix("px");
			field.SetText("16");
			demo.AddView(field, Wide);
		}
	}

	private static void AddPasswordBoxes(FlexLayout demo)
	{
		{
			let field = new PasswordBox();
			field.SetPlaceholder("Password");
			demo.AddView(field, Wide);
		}
		{
			let field = new PasswordBox();
			field.PasswordChar.Value = '\u{25CF}';
			field.SetPlaceholder("Custom mask");
			demo.AddView(field, Wide);
		}
	}

	private static void AddNumericFields(FlexLayout demo)
	{
		{
			let field = MakeNumeric(0, 100, 42);
			demo.AddView(field, Narrow);
		}
		{
			let field = MakeNumeric(0, 100, 25);
			field.ShowSpinButtons.Value = false;
			demo.AddView(field, Narrow);
		}
		{
			let field = MakeNumeric(-10, 10, 0);
			field.SetStep(0.5);
			field.SetDecimalPlaces(1);
			demo.AddView(field, Narrow);
		}
		{
			let field = MakeNumeric(0, 999, 100);
			field.SetDecimalPlaces(0);
			demo.AddView(field, Narrow);
		}
		{
			let field = MakeNumeric(0, 360, 90);
			field.SetDecimalPlaces(1);
			field.SetSuffix("\u{00B0}");
			demo.AddView(field, Narrow);
		}
	}

	/// Min and max go in BEFORE the value, because setting a value outside the range clamps it.
	private static NumericField MakeNumeric(double min, double max, double value)
	{
		let field = new NumericField();
		field.SetMin(min);
		field.SetMax(max);
		field.SetValue(value);
		return field;
	}

	/// Three numeric fields wearing coloured axis letters, which is the shape every vector
	/// property editor ends up in.
	private static void AddVectorRow(FlexLayout demo)
	{
		let caption = new Label();
		caption.SetText("Float3 Editor");
		demo.AddView(caption);

		let row = SandboxViews.HFlex(4.0f);
		AddAxisField(row, "X", Color.Rgb(220, 80, 80), 1.06);
		AddAxisField(row, "Y", Color.Rgb(80, 200, 80), 0.0);
		AddAxisField(row, "Z", Color.Rgb(80, 120, 220), 2.17);
		demo.AddView(row,
			SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(400)), SizeSpec.Wrap()));
	}

	private static void AddAxisField(FlexLayout row, StringView axis, Color color, double value)
	{
		let field = MakeNumeric(-999, 999, value);
		field.SetStep(0.1);
		field.SetDecimalPlaces(2);
		field.ShowSpinButtons.Value = false;

		let prefix = new Label();
		prefix.SetText(axis);
		prefix.TextColor.Value = color;
		field.SetPrefix(prefix);

		row.AddView(field, SandboxViews.Grow(1));
	}

	private static void AddEditableLabels(FlexLayout demo)
	{
		{
			let label = new EditableLabel();
			label.SetText("Double-click me");
			label.SlowClickToEdit.Value = false;
			demo.AddView(label, Wide);
		}
		{
			let label = new EditableLabel();
			label.SetText("Slow-click me");
			label.DoubleClickToEdit.Value = false;
			demo.AddView(label, Wide);
		}
		{
			let label = new EditableLabel();
			label.SetText("With validation");
			// A rename that fails validation is REFUSED rather than corrected, so the label
			// keeps what it had and the user sees why.
			label.ValidateRename = new (text) => !text.Contains("bad");
			demo.AddView(label, Wide);
		}
	}
}
