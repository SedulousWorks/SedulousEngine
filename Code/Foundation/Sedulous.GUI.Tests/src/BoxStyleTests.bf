using System;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

// The box properties from sheets, per property: several box shadows, transform functions about an
// origin, gradients with angles and stops, and a border per side; each parsed, applied to the
// node, and drawn.

/// The box properties a sheet sets: shadows, transforms, gradients and borders, applied and drawn.
class BoxStyleTests
{
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) => NodeFixtures.Near(a, b, epsilon);

	/// A 100 x 50 box styled by `css` (its rules on `box`), held by the caller: it releases it.
	private static UIWidget Styled(StringView css)
	{
		let w = StyleFixtures.Widget("box");
		w.Size = .(100.0f, 50.0f);
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, sheet);
		let rs = scope ResolvedStyle();
		sheet.Resolve(w, rs);
		ApplyStyle(w, rs);
		return w;
	}

	private static Float2 Mapped(Node node, Float2 p) => node.Transform.TransformPoint(p);

	[Test]
	public static void SeveralBoxShadowsOuterAndInsetWithSpread()
	{
		let w = Styled("box { box-shadow: 2px 4px 6px 1px rgba(0,0,0,0.5), inset 0 0 3px #ff0000; }");
		defer w.ReleaseRef();
		let area = w.Box;
		Test.Assert(area.Shadows.Count == 2);
		Test.Assert(Near(area.Shadows[0].Offset.X, 2.0f));
		Test.Assert(Near(area.Shadows[0].Offset.Y, 4.0f));
		Test.Assert(Near(area.Shadows[0].Blur, 6.0f));
		Test.Assert(Near(area.Shadows[0].Spread, 1.0f));
		Test.Assert(Near(area.Shadows[0].ShadowColor.A, 0.5f));
		Test.Assert(!area.Shadows[0].Inset);
		Test.Assert(area.Shadows[1].Inset);
		Test.Assert(Near(area.Shadows[1].ShadowColor.R, 1.0f));

		// Drawn: one box-shadow draw per shadow (the outer under the box, the inset over its fill).
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		w.Draw(dc);
		int shadowDraws = 0;
		for (let cmd in canvas.GetBatch().Commands)
			shadowDraws += (cmd.DrawMode == .BoxShadow) ? 1 : 0;
		Test.Assert(shadowDraws >= 1);

		// none clears them; a malformed list is not applied.
		{
			let none = Styled("box { box-shadow: none; }");
			defer none.ReleaseRef();
			Test.Assert(none.Box.Shadows.IsEmpty);
		}
		{
			let malformed = Styled("box { box-shadow: 1px; }");
			defer malformed.ReleaseRef();
			Test.Assert(malformed.Box.Shadows.IsEmpty);
		}
	}

	[Test]
	public static void TransformFunctionsApplyLeftToRightAboutTheOrigin()
	{
		// rotate(90deg) about the centre (50, 25): the top-left corner goes to (75, -25).
		{
			let w = Styled("box { transform: rotate(90deg); }");
			defer w.ReleaseRef();
			let p = Mapped(w, .(0.0f, 0.0f));
			Test.Assert(Near(p.X, 75.0f));
			Test.Assert(Near(p.Y, -25.0f));
		}
		// A translation in percentages of the box's own size, and in pixels.
		{
			let w = Styled("box { transform: translate(50%, 10px); }");
			defer w.ReleaseRef();
			let p = Mapped(w, .(0.0f, 0.0f));
			Test.Assert(Near(p.X, 50.0f));
			Test.Assert(Near(p.Y, 10.0f));
			// The percentage follows the size.
			w.Size = .(200.0f, 50.0f);
			Test.Assert(Near(Mapped(w, .(0.0f, 0.0f)).X, 100.0f));
		}
		// scale about the top-left corner, then skew about it.
		{
			let w = Styled("box { transform: scale(2, 3); transform-origin: left top; }");
			defer w.ReleaseRef();
			let p = Mapped(w, .(10.0f, 10.0f));
			Test.Assert(Near(p.X, 20.0f));
			Test.Assert(Near(p.Y, 30.0f));
		}
		{
			let w = Styled("box { transform: skewX(45deg); transform-origin: 0 0; }");
			defer w.ReleaseRef();
			let p = Mapped(w, .(0.0f, 10.0f));
			Test.Assert(Near(p.X, 10.0f)); // x moves by tan(45deg) * y
			Test.Assert(Near(p.Y, 10.0f));
		}
		// Order: translate then scale differs from scale then translate.
		{
			let a = Styled("box { transform: translate(10px, 0) scale(2); transform-origin: 0 0; }");
			defer a.ReleaseRef();
			let b = Styled("box { transform: scale(2) translate(10px, 0); transform-origin: 0 0; }");
			defer b.ReleaseRef();
			Test.Assert(Near(Mapped(a, .(0.0f, 0.0f)).X, 10.0f));
			Test.Assert(Near(Mapped(b, .(0.0f, 0.0f)).X, 20.0f));
		}
		// matrix(), and none.
		{
			let w = Styled("box { transform: matrix(1, 0, 0, 1, 5, 6); }");
			defer w.ReleaseRef();
			let p = Mapped(w, .(0.0f, 0.0f));
			Test.Assert(Near(p.X, 5.0f));
			Test.Assert(Near(p.Y, 6.0f));
			let none = Styled("box { transform: none; }");
			defer none.ReleaseRef();
			Test.Assert(none.Transform.IsIdentity);
		}
		// A transform moves hit testing with the drawing.
		{
			let w = Styled("box { transform: translate(200px, 0); }");
			defer w.ReleaseRef();
			Test.Assert(w.PointInside(.(250.0f, 25.0f)));
			Test.Assert(!w.PointInside(.(50.0f, 25.0f)));
		}
	}

	[Test]
	public static void GradientsFromSheetsTakeAnglesSidesAndStops()
	{
		{
			let w = Styled("box { background: linear-gradient(90deg, red, blue 75%), #00ff00; }");
			defer w.ReleaseRef();
			let area = w.Box;
			Test.Assert(Near(area.BackgroundColor.G, 1.0f)); // the bottom layer's colour
			Test.Assert(area.Layers.Count == 1);
			let g = area.Layers[0].Gradient;
			Test.Assert(g.Kind == .Linear);
			Test.Assert(Near(g.Angle, 1.5707963f));
			Test.Assert(g.Stops.Count == 2);
			Test.Assert(Near(g.Stops[0].Offset, 0.0f));
			Test.Assert(Near(g.Stops[1].Offset, 0.75f));
			Test.Assert(Near(g.Stops[1].Color.B, 1.0f));
		}
		{
			// `to bottom right` points down and right (135deg); unplaced stops space evenly.
			let w = Styled("box { background-image: linear-gradient(to bottom right, red, #00ff00, blue); }");
			defer w.ReleaseRef();
			Test.Assert(w.Box.Layers.Count == 1);
			let g = w.Box.Layers[0].Gradient;
			Test.Assert(Near(g.Angle, 2.3561945f));
			Test.Assert(g.Stops.Count == 3);
			Test.Assert(Near(g.Stops[1].Offset, 0.5f));
		}
		{
			let w = Styled("box { background-image: radial-gradient(circle, white, black), repeating-conic-gradient(from 90deg, red 0%, blue 25%); }");
			defer w.ReleaseRef();
			let area = w.Box;
			Test.Assert(area.Layers.Count == 2);
			Test.Assert(area.Layers[0].Gradient.Kind == .Radial);
			Test.Assert(area.Layers[1].Gradient.Kind == .Conic);
			Test.Assert(area.Layers[1].Gradient.Repeating);
			Test.Assert(Near(area.Layers[1].Gradient.Angle, 1.5707963f));
		}
		// A gradient with a single stop, or an unknown direction, is not applied.
		{
			let single = Styled("box { background-image: linear-gradient(red); }");
			defer single.ReleaseRef();
			Test.Assert(single.Box.Layers.IsEmpty);
			let nowhere = Styled("box { background-image: linear-gradient(to nowhere, red, blue); }");
			defer nowhere.ReleaseRef();
			Test.Assert(nowhere.Box.Layers.IsEmpty);
		}

		// Drawn through a gradient fill.
		let w = Styled("box { background-image: linear-gradient(red, blue); }");
		defer w.ReleaseRef();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		w.Draw(dc);
		Test.Assert(canvas.GetBatch().Vertices.Count > 0);
	}

	[Test]
	public static void ABorderPerSideEachItsOwnWidthStyleAndColour()
	{
		let w = Styled("box { border: 1px solid #808080; border-top: 3px solid red; border-left: 4px dashed blue; border-bottom-style: none; border-radius: 2 4 6 8; }");
		defer w.ReleaseRef();
		let area = w.Box;
		Test.Assert(Near(area.BorderWidths.Top, 3.0f));
		Test.Assert(Near(area.BorderWidths.Right, 1.0f));
		Test.Assert(Near(area.BorderWidths.Bottom, 0.0f)); // style none: no border
		Test.Assert(Near(area.BorderWidths.Left, 4.0f));
		Test.Assert(Near(area.BorderColors.Top.R, 1.0f));
		Test.Assert(Near(area.BorderColors.Left.B, 1.0f));
		Test.Assert(Near(area.BorderColors.Right.R, 128.0f / 255.0f));
		Test.Assert(Near(area.Radii.TopLeft, 2.0f));
		Test.Assert(Near(area.Radii.TopRight, 4.0f));
		Test.Assert(Near(area.Radii.BottomRight, 6.0f));
		Test.Assert(Near(area.Radii.BottomLeft, 8.0f));

		// border-width and border-color take one to four values, in CSS's side order.
		let sides = Styled("box { border-style: solid; border-width: 1 2 3; border-color: red blue; }");
		defer sides.ReleaseRef();
		Test.Assert(Near(sides.Box.BorderWidths.Left, 2.0f)); // three values: left = right
		Test.Assert(Near(sides.Box.BorderWidths.Bottom, 3.0f));
		Test.Assert(Near(sides.Box.BorderColors.Bottom.R, 1.0f)); // two values: bottom = top
		Test.Assert(Near(sides.Box.BorderColors.Left.B, 1.0f));

		// A radius in percent is of the box's smaller side.
		let round = Styled("box { border-radius: 50%; background-color: red; }");
		defer round.ReleaseRef();
		Test.Assert(Near(round.Box.Radii.TopLeft, 25.0f));
	}

	[Test]
	public static void ARepeatingGradientRepeatsTheSpanOfItsStops()
	{
		// Stops over the first quarter: the line is cut to that quarter, so across the box the
		// gradient parameter runs to 4 (four repeats), on VG's repeat spread.
		let w = Styled("box { background: repeating-linear-gradient(90deg, red 0%, blue 25%); }");
		defer w.ReleaseRef();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		w.Draw(dc);
		bool repeating = false;
		for (let cmd in canvas.GetBatch().Commands)
			repeating = repeating || (cmd.GradientSpread == .Repeat);
		Test.Assert(repeating);
		float maxU = 0.0f;
		for (let v in canvas.GetBatch().Vertices)
			maxU = Math.Max(maxU, v.TexCoord.X);
		Test.Assert(Math.Abs(maxU - 4.0f) < 0.05f * (1.0f + 4.0f)); // Approx(4).epsilon(0.05)
	}

	[Test]
	public static void ASharpOuterRingPaintsOnlyOutsideTheBoxSoABoxWithNoBackgroundShowsWhatIsBehindIt()
	{
		// A focus ring on a field with no background (a search field inside its frame).
		let w = Styled("box { box-shadow: 0 0 0 2px #ff00ff; }");
		defer w.ReleaseRef();
		let canvas = scope VGContext();
		let dc = scope DrawContext(canvas);
		w.Draw(dc);
		let batch = canvas.GetBatch();
		int ringTriangles = 0;
		int inside = 0;
		for (int i = 0; i + 2 < batch.Indices.Count; i += 3)
		{
			let a = batch.Vertices[(int)batch.Indices[i]];
			let b = batch.Vertices[(int)batch.Indices[i + 1]];
			let c = batch.Vertices[(int)batch.Indices[i + 2]];
			if ((a.Color.R != 1.0f) || (a.Color.G != 0.0f) || (a.Color.B != 1.0f))
				continue;
			ringTriangles++;
			let centre = Float2((a.Position.X + b.Position.X + c.Position.X) / 3.0f, (a.Position.Y + b.Position.Y + c.Position.Y) / 3.0f);
			// Inside the 100 x 50 box by more than the anti-aliasing fringe.
			if ((centre.X > 1.0f) && (centre.X < 99.0f) && (centre.Y > 1.0f) && (centre.Y < 49.0f))
				inside++;
		}
		Test.Assert(ringTriangles > 0);
		Test.Assert(inside == 0);
	}

	/// Two shapes smoothed along one outer curve leave the background's colour outside the border.
	[Test]
	public static void ABackgroundUnderASolidBorderIsOneBoxWithItSoNoBackgroundShowsPastARoundedCorner()
	{
		let w = Styled("box { background-color: #ff0000; border: 3px solid #000000; border-radius: 6px; }");
		defer w.ReleaseRef();
		let canvas = scope VGContext();
		canvas.SetAnalyticBoxes(true);
		let dc = scope DrawContext(canvas);
		w.Draw(dc);
		let batch = canvas.GetBatch();
		Test.Assert(batch.BoxVertices.Count == 6); // one quad
		Test.Assert(Math.Abs(batch.BoxVertices[0].Fill.R - 1.0f) < 0.001f);
		Test.Assert(Math.Abs(batch.BoxVertices[0].BorderTop.A - 1.0f) < 0.001f);

		// A dashed border is drawn apart, over the background.
		let dashed = Styled("box { background-color: #ff0000; border: 3px dashed #000000; border-radius: 6px; }");
		defer dashed.ReleaseRef();
		let other = scope VGContext();
		other.SetAnalyticBoxes(true);
		let odc = scope DrawContext(other);
		dashed.Draw(odc);
		Test.Assert(other.GetBatch().BoxVertices.Count == 6); // the background alone
		Test.Assert(Math.Abs(other.GetBatch().BoxVertices[0].BorderTop.A) < 0.001f);
	}
}
