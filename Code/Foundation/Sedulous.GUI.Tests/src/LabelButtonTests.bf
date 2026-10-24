using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Label control tests: its text properties, and its box drawn (text is a no-op without a font).
/// (Raptor's button tests here come with the button.)
class LabelButtonTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	[Test]
	public static void LabelTextProperties()
	{
		let label = new Label();
		defer label.ReleaseRef();
		label.Text = "Hello";
		Test.Assert(label.Text == "Hello");
		label.TextColor = Color.Red;
		Test.Assert(Near(label.TextColor.R, 1.0f));
		Test.Assert(label.MeasureText().X == 0.0f); // no font yet -> zero measure
	}

	[Test]
	public static void LabelDrawsItsBoxTextIsANoOpWithoutAFont()
	{
		let label = new Label();
		defer label.ReleaseRef();
		label.Size = .(100.0f, 40.0f);
		label.Text = "Hi";
		label.SetBox(FilledBox(Color.Blue, scope NodeBox()));
		Test.Assert(WidgetFixtures.DrawnGeometry(label) > 0); // its fill
	}
}
