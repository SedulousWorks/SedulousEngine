using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// A 300 px wide view at the root's corner: its strip's alpha stops on y 0 to 12, the bar on 12 to
/// 36, its colour stops on 36 to 48; time t at x = 300 t. The root goes with it.
class GradientBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public GradientView View = new .() ~ _.ReleaseRef();
	public int Changing = 0;
	public List<ColorGradient> Changed = new .() ~ DeleteContainerAndItems!(_);
	public int Cancelled = 0;

	public this()
	{
		Root = NewRoot(500.0f, 400.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		View.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(300.0f); });
		Root.AddChild(View);
		let value = scope ColorGradient();
		value.Colors.Add(GradientColorStop(0.0f, Color(1.0f, 0.0f, 0.0f, 1.0f)));
		value.Colors.Add(GradientColorStop(1.0f, Color(0.0f, 0.0f, 1.0f, 1.0f)));
		value.Alphas.Add(GradientAlphaStop(0.0f, 1.0f));
		value.Alphas.Add(GradientAlphaStop(1.0f, 0.0f));
		View.Value = value;
		View.SetOnGradientChanging(new (v) => { ++Changing; });
		View.SetOnGradientChanged(new (v) =>
			{
				let copy = new ColorGradient();
				copy.Set(v);
				Changed.Add(copy);
			});
		View.SetOnGradientCancelled(new () => { ++Cancelled; });
		Root.UpdateLayout();
	}

	public EventDispatcher D => Root.EventDispatcher;
	public ColorGradient V => View.Value;
	public static Float2 Colour(float t) => .(300.0f * t, 44.0f);
	public static Float2 Alpha(float t) => .(300.0f * t, 4.0f);

	public void Frame()
	{
		Root.UpdateLayout();
	}

	public void Press(Float2 at)
	{
		D.InjectMouseMove(at);
		D.InjectMouseDown(at, .Left);
	}

	public void Drag(Float2 from, Float2 to)
	{
		Press(from);
		D.InjectMouseMove(.((from.X + to.X) * 0.5f, (from.Y + to.Y) * 0.5f));
		D.InjectMouseMove(to);
		D.InjectMouseUp(to, .Left);
	}

	public void Click(Float2 at)
	{
		Press(at);
		D.InjectMouseUp(at, .Left);
	}

	public void Pause()
	{
		D.InjectMouseMove(.(490.0f, 390.0f));
		D.InjectMouseDown(.(490.0f, 390.0f), .Left);
		D.InjectMouseUp(.(490.0f, 390.0f), .Left);
	}

	public static Float2 Centre(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}

	public static Float2 Shifted(Float2 at, float dx, float dy) => .(at.X + dx, at.Y + dy);
}

/// The gradient view: one of Core's gradients edited as a value, each gesture reported as it goes and
/// once at its end, or given up: a click adds a stop of what is there (alpha above, colour below), a
/// drag moves one (sorted again as it passes) or pulls it off (never a kind's last); the picker edits
/// a colour stop, the fields an alpha and a place, the drop-down the blend.
class GradientViewTests
{
	[Test]
	public static void AClickOnTheStripAddsAStopOfWhatTheGradientHasThereOneChange()
	{
		let bed = scope GradientBed();
		bed.Click(GradientBed.Colour(0.5f));
		Test.Assert(bed.V.Colors.Count == 3);
		CheckNear(bed.V.Colors[1].Time, 0.5f);
		CheckNear(bed.V.Colors[1].Color.R, 0.5f); // halfway from red to blue, sRGB blended
		CheckNear(bed.V.Colors[1].Color.B, 0.5f);
		Test.Assert(bed.V.Colors[1].Color.A == 1.0f);
		Test.Assert(bed.View.Selected == GradientStopRef(false, 1));
		Test.Assert(bed.Changed.Count == 1);

		bed.Pause();
		bed.Click(GradientBed.Alpha(0.25f));
		Test.Assert(bed.V.Alphas.Count == 3);
		CheckNear(bed.V.Alphas[1].Alpha, 0.75f);
		Test.Assert(bed.View.Selected == GradientStopRef(true, 1));
		Test.Assert(bed.Changed.Count == 2);

		// Full: nothing added.
		bed.View.MaxStops = 3;
		bed.Pause();
		bed.Click(GradientBed.Alpha(0.75f));
		Test.Assert(bed.V.Alphas.Count == 3);
		Test.Assert(bed.Changed.Count == 2);
	}

	[Test]
	public static void ADragMovesAStopSortedAgainAsItPassesAPressThatDoesNotMoveChangesNothing()
	{
		let bed = scope GradientBed();
		bed.Click(GradientBed.Colour(0.0f)); // selects the first, changes nothing
		Test.Assert(bed.View.Selected == GradientStopRef(false, 0));
		Test.Assert(bed.Changed.IsEmpty);
		bed.Pause();
		bed.Drag(GradientBed.Colour(0.0f), GradientBed.Shifted(GradientBed.Colour(1.0f), 40.0f, 0.0f)); // past the other, past the end
		Test.Assert(bed.V.Colors.Count == 2);
		CheckNear(bed.V.Colors[1].Time, 1.0f);
		CheckNear(bed.V.Colors[1].Color.R, 1.0f); // red, now second
		Test.Assert(bed.View.Selected == GradientStopRef(false, 1));
		Test.Assert(bed.Changing >= 1);
		Test.Assert(bed.Changed.Count == 1);
	}

	[Test]
	public static void AStopPulledOffTheStripGoesBackOnItReturnsAKindsLastStaysEscapeGivesADragUp()
	{
		let bed = scope GradientBed();
		bed.Press(GradientBed.Shifted(GradientBed.Alpha(1.0f), -2.0f, 0.0f));
		bed.D.InjectMouseMove(.(280.0f, 120.0f)); // well below
		Test.Assert(bed.V.Alphas.Count == 1);
		bed.D.InjectMouseMove(.(280.0f, 20.0f)); // back
		Test.Assert(bed.V.Alphas.Count == 2);
		bed.D.InjectMouseMove(.(280.0f, -60.0f));
		bed.D.InjectMouseUp(.(280.0f, -60.0f), .Left);
		Test.Assert(bed.V.Alphas.Count == 1);
		Test.Assert(bed.Changed.Count == 1);

		bed.Pause();
		bed.Press(GradientBed.Shifted(GradientBed.Alpha(0.0f), 2.0f, 0.0f)); // the last alpha stop
		bed.D.InjectMouseMove(.(10.0f, 150.0f));
		bed.D.InjectMouseUp(.(10.0f, 150.0f), .Left);
		Test.Assert(bed.V.Alphas.Count == 1);

		bed.Pause();
		bed.Press(GradientBed.Shifted(GradientBed.Colour(1.0f), -2.0f, 0.0f));
		bed.D.InjectMouseMove(GradientBed.Colour(0.5f));
		CheckNear(bed.V.Colors[0].Time, 0.0f);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(bed.Cancelled == 1);
		CheckNear(bed.V.Colors[1].Time, 1.0f);
		bed.D.InjectMouseUp(GradientBed.Colour(0.5f), .Left);
		CheckNear(bed.V.Colors[1].Time, 1.0f);
		let before = bed.Changed.Count;
		Test.Assert(before == 2); // the last-stop attempt moved it, so it changed once
	}

	[Test]
	public static void TheSelectedStopsPlaceAndAnAlphaStopsAlphaAreFieldsTheBlendADropDown()
	{
		let bed = scope GradientBed();
		bed.Click(GradientBed.Shifted(GradientBed.Alpha(1.0f), -2.0f, 0.0f));
		Test.Assert(bed.View.Selected == GradientStopRef(true, 1));
		Test.Assert(bed.View.AlphaField.Displayed);
		Test.Assert(!bed.View.Swatch.Displayed);
		bed.Frame();

		void Type(NumberField field, StringView text)
		{
			let r = field.ScreenBounds;
			let at = Float2(r.X + 12.0f, r.Y + r.Height * 0.5f);
			bed.Pause();
			bed.Click(at);
			bed.D.InjectText(text);
			bed.D.InjectKeyDown((uint32)KeyCode.Return);
		}
		Type(bed.View.AlphaField, "0.5");
		CheckNear(bed.V.Alphas[1].Alpha, 0.5f);
		Test.Assert(bed.Changed.Count == 1);
		Type(bed.View.TimeField, "0.4");
		CheckNear(bed.V.Alphas[1].Time, 0.4f);
		Test.Assert(bed.Changed.Count == 2);

		bed.View.InterpolationBox.SelectedIndex = 2;
		Test.Assert(bed.V.Interpolation == .OkLab);
		Test.Assert(bed.Changed.Count == 3);

		// A colour stop shows its swatch instead.
		bed.View.Select(GradientStopRef(false, 0));
		Test.Assert(!bed.View.AlphaField.Displayed);
		Test.Assert(bed.View.Swatch.Displayed);
		Test.Assert(bed.Changed.Count == 3); // showing a selection is no change
	}

	[Test]
	public static void ADoubleClickOnAColourStopOpensThePickerItsDragsPreviewClosingChangesOnceEscapeGivesUp()
	{
		let bed = scope GradientBed();
		bed.Click(GradientBed.Shifted(GradientBed.Colour(0.0f), 2.0f, 0.0f));
		bed.Click(GradientBed.Shifted(GradientBed.Colour(0.0f), 2.0f, 0.0f));
		let picker = bed.View.Picker;
		Test.Assert(picker != null);
		CheckNear(picker.ColorValue.R, 1.0f);
		Test.Assert(!picker.ShowsAlpha);
		Test.Assert(bed.Changed.IsEmpty);

		let r = picker.Plane.ScreenBounds;
		bed.D.InjectMouseDown(.(r.X + 5.0f, r.Y + r.Height * 0.5f), .Left);
		bed.D.InjectMouseUp(.(r.X + 5.0f, r.Y + r.Height * 0.5f), .Left);
		Test.Assert(bed.Changing >= 1);
		Test.Assert(bed.Changed.IsEmpty);
		Test.Assert(bed.V.Colors[0].Color.R < 0.9f); // previewed
		bed.D.ClosePopup(bed.View.Picker.Parent);
		Test.Assert(bed.Changed.Count == 1);
		Test.Assert(bed.V.Colors[0].Color.A == 1.0f);

		let picked = bed.V.Colors[0].Color;
		bed.Frame();
		bed.Pause();
		bed.Click(GradientBed.Centre(bed.View.Swatch));
		Test.Assert(bed.View.Picker != null);
		let again = bed.View.Picker.Plane.ScreenBounds;
		bed.D.InjectMouseDown(.(again.Right - 5.0f, again.Y + 5.0f), .Left);
		bed.D.InjectMouseUp(.(again.Right - 5.0f, again.Y + 5.0f), .Left);
		bed.D.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(bed.View.Picker == null);
		Test.Assert(bed.Cancelled == 1);
		Test.Assert(bed.V.Colors[0].Color == picked);
		Test.Assert(bed.Changed.Count == 1);
	}

	[Test]
	public static void DeleteTakesTheSelectedStopAwayNeverAKindsLast()
	{
		let bed = scope GradientBed();
		bed.Click(GradientBed.Shifted(GradientBed.Colour(1.0f), -2.0f, 0.0f));
		bed.D.InjectKeyDown((uint32)KeyCode.Delete);
		Test.Assert(bed.V.Colors.Count == 1);
		Test.Assert(!bed.View.Selected.IsValid);
		bed.View.Select(GradientStopRef(false, 0));
		Test.Assert(!bed.View.RemoveSelected());
		Test.Assert(bed.Changed.Count == 1);
	}

	// What no Raptor test covers: AddStop from code, a selection past the end cleared, and the value
	// set from code reporting nothing.
	[Test]
	public static void AStopAddedFromCodeIsOneChangeAndAValueSetFromCodeReportsNothing()
	{
		let bed = scope GradientBed();
		Test.Assert(bed.View.AddStop(true, 0.5f));
		Test.Assert(bed.V.Alphas.Count == 3);
		CheckNear(bed.V.Alphas[1].Alpha, 0.5f);
		Test.Assert(bed.View.Selected == GradientStopRef(true, 1));
		Test.Assert(bed.Changed.Count == 1);
		bed.View.Select(GradientStopRef(true, 7)); // past its kind's end: none
		Test.Assert(!bed.View.Selected.IsValid);
		let plain = scope ColorGradient();
		plain.Colors.Add(GradientColorStop(0.0f, Color(0.0f, 1.0f, 0.0f, 1.0f)));
		bed.View.Value = plain;
		Test.Assert(bed.V.Equals(plain));
		Test.Assert(bed.Changed.Count == 1);
	}
}
