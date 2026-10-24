using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// Label and Button control tests: text properties, click handling through the dispatcher,
/// control-state reaction, and CSS targeting the default `button` tag; a label's box drawn (text is
/// a no-op without a font).
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

	[Test]
	public static void AButtonsDefaultsTagAndCenteredText()
	{
		let btn = new Button();
		defer btn.ReleaseRef();
		Test.Assert(btn.Tag == "button"); // CSS `button` targets it
		btn.Text = "OK";
		Test.Assert(btn.Text == "OK");
		Test.Assert(!btn.HasOnClick);
	}

	[Test]
	public static void AButtonsClickCallbackFiresOnPressAndRelease()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = new Button();
		defer btn.ReleaseRef();
		btn.Size = .(100.0f, 100.0f);
		root.AddChild(btn);
		let d = root.EventDispatcher;

		int clicks = 0;
		btn.SetOnClick(new [&] () => { ++clicks; });
		Test.Assert(btn.HasOnClick);

		d.InjectMouseDown(.(50.0f, 50.0f), .Left);
		d.InjectMouseUp(.(50.0f, 50.0f), .Left);
		Test.Assert(clicks == 1);

		// Press on the button, release elsewhere: not a click.
		d.InjectMouseDown(.(50.0f, 50.0f), .Left);
		d.InjectMouseUp(.(300.0f, 300.0f), .Left);
		Test.Assert(clicks == 1);
	}

	[Test]
	public static void AButtonsStatesFollowThePointer()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = new Button();
		defer btn.ReleaseRef();
		btn.Size = .(100.0f, 100.0f);
		root.AddChild(btn);
		let d = root.EventDispatcher;

		Test.Assert(!btn.Hovered);
		d.InjectMouseMove(.(50.0f, 50.0f));
		Test.Assert(btn.Hovered);
		d.InjectMouseDown(.(50.0f, 50.0f), .Left);
		Test.Assert(btn.Pressed);
	}

	[Test]
	public static void AButtonIsStyledByCSSThroughTheDefaultTag()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		let btn = new Button();
		defer btn.ReleaseRef();
		btn.Size = .(100.0f, 100.0f);
		root.AddChild(btn);
		let d = root.EventDispatcher;

		let mgr = scope StyleManager();
		WidgetFixtures.UseSheet(mgr, "button { opacity: 1; } button:hover { opacity: 0.3; }");
		mgr.ApplyTree(root);
		Test.Assert(Near(btn.Alpha, 1.0f));

		d.InjectMouseMove(.(50.0f, 50.0f)); // hover
		mgr.ApplyTree(root); // resolved again: :hover applies
		Test.Assert(Near(btn.Alpha, 0.3f));
	}
}
