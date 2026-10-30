using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A colour picker 300 wide at the root's top left, counting its steps and its changes and keeping
/// the last colour it reported. The root and the picker go with it.
class PickerBed
{
	public SceneRoot Root = SceneFixtures.NewScene(400.0f, 400.0f) ~ _.ReleaseRef();
	public ColorPicker Picker = new .() ~ _.ReleaseRef();
	public int Steps = 0;
	public int Changes = 0;
	public Color Last = .();

	public this()
	{
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Picker.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(300.0f); });
		Root.AddChild(Picker);
		Picker.SetOnColorChanging(new (c) => { ++Steps; Last = c; });
		Picker.SetOnColorChanged(new (c) => { ++Changes; Last = c; });
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;

	/// A point `x`, `y` of the way across a node.
	public static Float2 Across(Node node, float x, float y)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * x, r.Y + r.Height * y);
	}
}

/// The colour widgets: HSV over sRGB values and back, a hex code written, a swatch clicked or
/// hatched when mixed, and a picker dragged (each step reported, then its end), typed into, its
/// hue kept through a grey, its alpha hidden where a colour has none.
class ColorPickerTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);
	private static bool Near(float a, float b, float epsilon) => TextFixtures.Near(a, b, epsilon);

	private static bool HexIs(Color color, bool alpha, StringView expected)
	{
		let text = scope String();
		FormatHexColor(color, alpha, text);
		return text == expected;
	}

	[Test]
	public static void HsvOverTheColoursValuesAndBackAndItsHex()
	{
		let red = ToHsv(.(1.0f, 0.0f, 0.0f, 1.0f));
		Test.Assert(Near(red.H, 0.0f));
		Test.Assert(Near(red.S, 1.0f));
		Test.Assert(Near(red.V, 1.0f));
		let teal = ToHsv(.(0.2f, 0.6f, 0.6f, 0.5f));
		Test.Assert(Near(teal.H, 180.0f));
		let back = FromHsv(teal);
		Test.Assert(Near(back.R, 0.2f));
		Test.Assert(Near(back.G, 0.6f));
		Test.Assert(Near(back.A, 0.5f));
		Test.Assert(Near(ToHsv(.(0.5f, 0.5f, 0.5f, 1.0f), 210.0f).H, 210.0f)); // a grey keeps the hue given

		Test.Assert(HexIs(.(1.0f, 0.5f, 0.0f, 1.0f), true, "#FF8000"));
		Test.Assert(HexIs(.(1.0f, 0.5f, 0.0f, 0.5f), true, "#FF800080"));
		Test.Assert(HexIs(.(1.0f, 0.5f, 0.0f, 0.5f), false, "#FF8000"));
	}

	[Test]
	public static void ASwatchIsClickedOrByReturnMixedItShowsNoColour()
	{
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		let swatch = new ColorSwatch();
		defer swatch.ReleaseRef();
		swatch.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(40.0f);
				s.Height = LayoutLength.Px(20.0f);
			});
		root.AddChild(swatch);
		root.UpdateLayout();
		int clicks = 0;
		swatch.SetOnClick(new [&] () => { ++clicks; });
		swatch.ColorValue = .(0.1f, 0.2f, 0.3f, 0.5f);
		Test.Assert(Near(swatch.ColorValue.B, 0.3f));
		let d = root.EventDispatcher;
		d.InjectMouseDown(.(10.0f, 10.0f), .Left);
		d.InjectMouseUp(.(10.0f, 10.0f), .Left);
		Test.Assert(clicks == 1);
		swatch.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(clicks == 2);
		swatch.IsMixed = true;
		Test.Assert(swatch.IsMixed);
	}

	[Test]
	public static void APickersPlaneAndStripsAreDraggedEachStepReportedThenTheEnd()
	{
		let bed = scope PickerBed();
		bed.Picker.ColorValue = .(1.0f, 0.0f, 0.0f, 1.0f);
		let plane = bed.Picker.Plane;
		bed.D.InjectMouseDown(PickerBed.Across(plane, 0.5f, 0.5f), .Left);
		bed.D.InjectMouseMove(PickerBed.Across(plane, 1.0f, 0.0f));
		bed.D.InjectMouseUp(PickerBed.Across(plane, 1.0f, 0.0f), .Left);
		Test.Assert(bed.Steps == 2);
		Test.Assert(bed.Changes == 1);
		Test.Assert(Near(bed.Last.R, 1.0f, 0.02f));
		Test.Assert(Near(bed.Last.G, 0.0f, 0.02f));

		// To the black corner and back out: the hue is kept.
		bed.D.InjectMouseDown(PickerBed.Across(plane, 0.5f, 1.0f), .Left);
		bed.D.InjectMouseUp(PickerBed.Across(plane, 0.5f, 1.0f), .Left);
		Test.Assert(Near(bed.Picker.ColorValue.R, 0.0f, 0.02f));
		bed.D.InjectMouseDown(PickerBed.Across(plane, 1.0f, 0.0f), .Left);
		bed.D.InjectMouseUp(PickerBed.Across(plane, 1.0f, 0.0f), .Left);
		Test.Assert(Near(bed.Picker.ColorValue.R, 1.0f, 0.02f));

		// A third of the hue strip: green.
		let hue = bed.Picker.HueStrip;
		bed.D.InjectMouseDown(PickerBed.Across(hue, 1.0f / 3.0f, 0.5f), .Left);
		bed.D.InjectMouseUp(PickerBed.Across(hue, 1.0f / 3.0f, 0.5f), .Left);
		Test.Assert(Near(bed.Picker.ColorValue.G, 1.0f, 0.03f));
		Test.Assert(bed.Picker.ColorValue.R < 0.1f);
		// Half the alpha strip.
		let alpha = bed.Picker.AlphaStrip;
		bed.D.InjectMouseDown(PickerBed.Across(alpha, 0.5f, 0.5f), .Left);
		bed.D.InjectMouseUp(PickerBed.Across(alpha, 0.5f, 0.5f), .Left);
		Test.Assert(Near(bed.Picker.ColorValue.A, 0.5f, 0.03f));
	}

	[Test]
	public static void APickerTypedIntoAHexCodeAChannelItsAlphaHiddenWhereAColourHasNone()
	{
		let bed = scope PickerBed();
		let hex = bed.Picker.HexField;
		hex.RequestFocus();
		hex.Model.SelectAll();
		bed.D.InjectText("#3366CC");
		bed.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(bed.Changes == 1);
		Test.Assert(Near(bed.Picker.ColorValue.B, 0.8f, 0.01f));
		Test.Assert(Math.Abs(bed.Picker.GetChannelField(1).Value - 102.0) < 1.2e-5 * 103.0);

		hex.Model.SelectAll();
		bed.D.InjectText("not a colour");
		bed.D.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(bed.Changes == 1);
		Test.Assert(hex.Text == "#3366CC"); // back to what it was

		let red = bed.Picker.GetChannelField(0);
		red.RequestFocus();
		bed.D.InjectKeyDown((uint32)KeyCode.Up); // one step: 0x34
		Test.Assert(Near(bed.Picker.ColorValue.R, 52.0f / 255.0f, 0.01f));
		Test.Assert(hex.Text == "#3466CC");

		bed.Picker.ShowsAlpha = false;
		Test.Assert(!bed.Picker.AlphaStrip.Displayed);
		Test.Assert(Near(bed.Picker.ColorValue.A, 1.0f));
	}

	[Test]
	public static void APickerGivenTheColourItOpenedWithShowsItBesideTheNewOneAClickOnItPutsItBack()
	{
		let bed = scope PickerBed();
		Test.Assert(bed.Picker.OriginalSwatch == null); // none given: no comparison
		let was = Color(0.2f, 0.4f, 0.8f, 1.0f);
		bed.Picker.ColorValue = was;
		bed.Picker.SetOriginal(was);
		let swatch = bed.Picker.OriginalSwatch;
		Test.Assert(swatch != null);
		Test.Assert(Near(swatch.ColorValue.B, 0.8f));
		bed.Picker.ColorValue = .(1.0f, 0.0f, 0.0f, 1.0f);
		let before = bed.Changes;
		bed.Picker.Revert();
		Test.Assert(bed.Changes == before + 1); // reported as a change
		Test.Assert(Math.Abs(bed.Picker.ColorValue.B - 0.8f) < 0.01f);
		Test.Assert(Math.Abs(bed.Picker.ColorValue.R - 0.2f) < 0.01f);
	}
}
