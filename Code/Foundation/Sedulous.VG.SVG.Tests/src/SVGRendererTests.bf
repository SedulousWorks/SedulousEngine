using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.VG.SVG;

namespace Sedulous.VG.SVG.Tests;

/// Drawing a parsed document into a context.
class SVGRendererTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// THE CALLER OWNS what comes back.
	private static SVGDocument Load(StringView content)
	{
		Test.Assert(SVGLoader.Load(content) case .Ok(let document), "the document did not load");
		return document;
	}

	/// The extent the emitted geometry actually covers, which is how a scale or a translate
	/// is observed from outside.
	private static Rectangle Extent(VGContext context)
	{
		let batch = context.GetBatch();
		Test.Assert(!batch.Vertices.IsEmpty, "nothing was drawn");

		var minimum = Float2(FloatMax, FloatMax);
		var maximum = Float2(-FloatMax, -FloatMax);
		for (let vertex in batch.Vertices)
		{
			minimum.X = Min(minimum.X, vertex.Position.X);
			minimum.Y = Min(minimum.Y, vertex.Position.Y);
			maximum.X = Max(maximum.X, vertex.Position.X);
			maximum.Y = Max(maximum.Y, vertex.Position.Y);
		}
		return .(minimum.X, minimum.Y, maximum.X - minimum.X, maximum.Y - minimum.Y);
	}

	private static bool AnyVertex(VGContext context) => !context.GetBatch().Vertices.IsEmpty;

	[Test]
	public static void AnEmptyDocumentDrawsNothing()
	{
		let context = scope VGContext();
		let document = scope SVGDocument(100, 100);

		SVGRenderer.Render(context, document, .(0, 0, 100, 100));
		Test.Assert(!AnyVertex(context));
	}

	/// The document's own size maps onto the bounds, so an icon authored at 24 units fills
	/// whatever box it is given.
	[Test]
	public static void TheDocumentScalesToTheBounds()
	{
		let document = Load("""
			<svg width="10" height="10"><rect x="0" y="0" width="10" height="10"/></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 100, 50));

		let extent = Extent(context);
		Test.Assert(Near(extent.Width, 100.0f, 1.5f), scope $"width was {extent.Width}");
		Test.Assert(Near(extent.Height, 50.0f, 1.5f), scope $"height was {extent.Height}");
	}

	[Test]
	public static void TheBoundsOriginOffsetsTheDrawing()
	{
		let document = Load("""
			<svg width="10" height="10"><rect x="0" y="0" width="10" height="10"/></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(20, 30, 10, 10));

		let extent = Extent(context);
		Test.Assert(Near(extent.X, 20.0f, 1.5f), scope $"x was {extent.X}");
		Test.Assert(Near(extent.Y, 30.0f, 1.5f), scope $"y was {extent.Y}");
	}

	/// A document that never stated a size is drawn at ITS OWN scale rather than divided by
	/// zero into nothing.
	[Test]
	public static void ADocumentWithoutASizeDrawsAtItsOwnScale()
	{
		let document = Load("<svg><rect x=\"0\" y=\"0\" width=\"10\" height=\"10\"/></svg>");
		defer delete document;
		Test.Assert(document.Width == 0.0f, "the size really is absent");

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 100, 100));

		let extent = Extent(context);
		Test.Assert(Near(extent.Width, 10.0f, 1.5f), "unscaled, not stretched to the bounds");
	}

	// ---- colour ----

	[Test]
	public static void TheFillColourReachesTheVertices()
	{
		let document = Load("""
			<svg width="10" height="10"><rect width="10" height="10" fill="#ff0000"/></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));

		for (let vertex in context.GetBatch().Vertices)
			Test.Assert((vertex.Color.R == 1.0f) && (vertex.Color.G == 0.0f));
	}

	/// A tint OVERRIDES every colour in the document, which is what recolours a monochrome
	/// icon to a theme.
	[Test]
	public static void ATintOverridesEveryColour()
	{
		let document = Load("""
			<svg width="10" height="10">
				<rect width="5" height="10" fill="#ff0000"/>
				<rect x="5" width="5" height="10" fill="#00ff00" stroke="#0000ff" stroke-width="1"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10), Color.White);

		Test.Assert(AnyVertex(context));
		for (let vertex in context.GetBatch().Vertices)
			Test.Assert((vertex.Color.R == 1.0f) && (vertex.Color.G == 1.0f) && (vertex.Color.B == 1.0f));
	}

	/// Including a gradient, which is not even looked up under a tint.
	[Test]
	public static void ATintOverridesAGradient()
	{
		let document = Load("""
			<svg width="10" height="10">
				<linearGradient id="fade"><stop offset="0" stop-color="#ff0000"/>
					<stop offset="1" stop-color="#0000ff"/></linearGradient>
				<rect width="10" height="10" fill="url(#fade)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10), Color.Green);

		Test.Assert(AnyVertex(context));
		for (let vertex in context.GetBatch().Vertices)
			Test.Assert((vertex.Color.R == 0.0f) && (vertex.Color.B == 0.0f));
	}

	/// An element with no fill and no stroke has nothing to draw.
	[Test]
	public static void AnUnfilledUnstrokedShapeDrawsNothing()
	{
		let document = Load("""
			<svg width="10" height="10"><rect width="10" height="10" fill="none"/></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));
		Test.Assert(!AnyVertex(context));
	}

	[Test]
	public static void AStrokeIsDrawnWithoutAFill()
	{
		let document = Load("""
			<svg width="10" height="10">
				<rect width="10" height="10" fill="none" stroke="#ff0000" stroke-width="2"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));

		Test.Assert(AnyVertex(context));
		for (let vertex in context.GetBatch().Vertices)
			Test.Assert(vertex.Color.R == 1.0f);
	}

	/// A stroke width of zero draws no stroke, rather than a degenerate ribbon.
	[Test]
	public static void AZeroStrokeWidthDrawsNoStroke()
	{
		let document = Load("""
			<svg width="10" height="10">
				<rect width="10" height="10" fill="none" stroke="#ff0000" stroke-width="0"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));
		Test.Assert(!AnyVertex(context));
	}

	// ---- gradients ----

	/// The stops reach the geometry. A gradient bakes its ramp into a texture and writes a
	/// LOOKUP PARAMETER per vertex rather than a colour, so the ramp is read per pixel:
	/// what the geometry carries is where along the ramp each vertex sits.
	[Test]
	public static void AGradientRampsAcrossThePath()
	{
		let document = Load("""
			<svg width="10" height="10">
				<linearGradient id="fade" x1="0" y1="0" x2="1" y2="0">
					<stop offset="0" stop-color="#ff0000"/>
					<stop offset="1" stop-color="#0000ff"/>
				</linearGradient>
				<rect width="10" height="10" fill="url(#fade)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));

		let batch = context.GetBatch();
		Test.Assert(!batch.Vertices.IsEmpty);

		var leftmost = batch.Vertices[0];
		var rightmost = batch.Vertices[0];
		for (let vertex in batch.Vertices)
		{
			if (vertex.Position.X < leftmost.Position.X) leftmost = vertex;
			if (vertex.Position.X > rightmost.Position.X) rightmost = vertex;
		}

		Test.Assert(batch.Textures.Count == 2, "the white texel and the baked ramp");
		Test.Assert(leftmost.TexCoord.X < 0.05f,
			scope $"the left edge sampled at {leftmost.TexCoord.X}, expected the first stop");
		Test.Assert(rightmost.TexCoord.X > 0.95f,
			scope $"the right edge sampled at {rightmost.TexCoord.X}, expected the last stop");
	}

	/// A gradient with no stops falls back to the element's own fill rather than drawing
	/// nothing.
	[Test]
	public static void AnEmptyGradientFallsBackToTheFill()
	{
		let document = Load("""
			<svg width="10" height="10">
				<linearGradient id="empty"></linearGradient>
				<rect width="10" height="10" fill="url(#empty)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));
		Test.Assert(AnyVertex(context), "the black stand in drew");
	}

	/// An unresolved reference does the same, so a file that names a gradient it never
	/// defines still shows its shapes.
	[Test]
	public static void AnUnresolvedReferenceFallsBackToTheFill()
	{
		let document = Load("""
			<svg width="10" height="10"><rect width="10" height="10" fill="url(#missing)"/></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));
		Test.Assert(AnyVertex(context));
	}

	/// The default units are a FRACTION of the shape's own bounds; user space units are
	/// document coordinates. A ramp declared over a hundred units covers only a tenth of a
	/// ten unit shape, so it stays near its first stop.
	[Test]
	public static void UserSpaceUnitsAreDocumentCoordinates()
	{
		let userSpace = Load("""
			<svg width="10" height="10">
				<linearGradient id="fade" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="100" y2="0">
					<stop offset="0" stop-color="#ff0000"/>
					<stop offset="1" stop-color="#0000ff"/>
				</linearGradient>
				<rect width="10" height="10" fill="url(#fade)"/>
			</svg>
			""");
		defer delete userSpace;

		let context = scope VGContext();
		SVGRenderer.Render(context, userSpace, .(0, 0, 10, 10));

		let batch = context.GetBatch();
		var rightmost = batch.Vertices[0];
		for (let vertex in batch.Vertices)
		{
			if (vertex.Position.X > rightmost.Position.X)
				rightmost = vertex;
		}

		Test.Assert(Near(rightmost.TexCoord.X, 0.1f, 0.02f),
			scope $"the right edge sampled at {rightmost.TexCoord.X}, expected a tenth along");
	}

	/// A radial gradient's fractional radius scales by the bounds' NORMALISED DIAGONAL, so
	/// it fits a non square box instead of following one axis.
	[Test]
	public static void ARadialRadiusFollowsTheNormalisedDiagonal()
	{
		let document = Load("""
			<svg width="40" height="10">
				<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
					<stop offset="0" stop-color="#ffffff"/>
					<stop offset="1" stop-color="#000000"/>
				</radialGradient>
				<rect width="40" height="10" fill="url(#glow)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		// A radial vertex carries its offset from the centre IN RADII only on the per pixel
		// path; the fallback flattens it to one scalar per vertex.
		context.SetPerPixelGradients(true);
		SVGRenderer.Render(context, document, .(0, 0, 40, 10));

		let batch = context.GetBatch();
		Test.Assert(!batch.Vertices.IsEmpty);

		// The radius is 0.5 * Sqrt((40*40 + 10*10) * 0.5), about 14.58, and the corner is
		// 20.6 away: 1.41 radii, past the last stop. Following the width alone would have
		// put the corner at almost exactly one, and the height alone at four.
		var farthest = 0.0f;
		for (let vertex in batch.Vertices)
			farthest = Max(farthest, Length(vertex.TexCoord));

		Test.Assert(Near(farthest, 1.41f, 0.06f), scope $"the corner sat at {farthest} radii");
	}

	/// Without the per pixel shaders a radial gradient falls back to ONE PARAMETER PER
	/// VERTEX, which for a shape whose corners all sit outside the radius is the last stop
	/// at every corner: the fill reads as flat. The context defaults to that fallback, so a
	/// caller whose renderer has the shaders has to say so.
	[Test]
	public static void ARadialGradientFlattensWithoutThePerPixelPath()
	{
		let document = Load("""
			<svg width="40" height="10">
				<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
					<stop offset="0" stop-color="#ffffff"/>
					<stop offset="1" stop-color="#000000"/>
				</radialGradient>
				<rect width="40" height="10" fill="url(#glow)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		Test.Assert(!context.PerPixelGradients, "off unless the host turns it on");
		SVGRenderer.Render(context, document, .(0, 0, 40, 10));

		for (let vertex in context.GetBatch().Vertices)
			Test.Assert(vertex.TexCoord.X > 0.99f, "every corner clamped to the end of the ramp");
	}

	// ---- structure ----

	/// Fully transparent: neither the element nor its children are drawn.
	[Test]
	public static void AZeroOpacityElementIsSkipped()
	{
		let document = Load("""
			<svg width="10" height="10">
				<g opacity="0"><rect width="10" height="10" fill="#ff0000"/></g>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));
		Test.Assert(!AnyVertex(context));
	}

	/// A partial opacity reaches the vertices' alpha.
	[Test]
	public static void APartialOpacityMultipliesTheAlpha()
	{
		let document = Load("""
			<svg width="10" height="10">
				<rect width="10" height="10" fill="#ff0000" opacity="0.5"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 10, 10));

		let batch = context.GetBatch();
		Test.Assert(!batch.Vertices.IsEmpty);
		Test.Assert(Near(batch.Vertices[0].Color.A, 0.5f));
	}

	/// A group's transform COMPOSES with what is already in effect, so a nested one
	/// accumulates down the tree rather than replacing its parent's.
	[Test]
	public static void NestedGroupTransformsCompose()
	{
		let document = Load("""
			<svg width="100" height="100">
				<g transform="translate(10, 0)">
					<g transform="translate(10, 0)">
						<rect width="10" height="10"/>
					</g>
				</g>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 100, 100));

		let extent = Extent(context);
		Test.Assert(Near(extent.X, 20.0f, 1.5f), scope $"x was {extent.X}, expected both moves");
	}

	/// A group's transform does not leak into its SIBLINGS.
	[Test]
	public static void AGroupTransformDoesNotEscapeTheGroup()
	{
		let moved = Load("""
			<svg width="100" height="100">
				<g transform="translate(50, 0)"><rect width="10" height="10"/></g>
				<rect width="10" height="10"/>
			</svg>
			""");
		defer delete moved;

		let context = scope VGContext();
		SVGRenderer.Render(context, moved, .(0, 0, 100, 100));

		let extent = Extent(context);
		Test.Assert(Near(extent.X, 0.0f, 1.5f), "the untransformed sibling stayed at the origin");
		Test.Assert(Near(extent.X + extent.Width, 60.0f, 1.5f), "and the moved one moved");
	}

	/// A rotation about a point leaves that point where it is, which is the defect the
	/// transform parser fixes.
	[Test]
	public static void ARotationAboutAPointKeepsThatPointFixed()
	{
		let document = Load("""
			<svg width="100" height="100">
				<rect x="45" y="45" width="10" height="10" transform="rotate(90, 50, 50)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.Render(context, document, .(0, 0, 100, 100));

		// A square centred on the pivot comes back onto itself.
		let extent = Extent(context);
		Test.Assert(Near(extent.X, 45.0f, 1.5f), scope $"x was {extent.X}");
		Test.Assert(Near(extent.Y, 45.0f, 1.5f), scope $"y was {extent.Y}");
	}

	/// Text needs a font service. Without one it is skipped rather than crashing, which is
	/// what a document rendered by a caller that never set one up does.
	[Test]
	public static void TextWithoutAFontServiceIsSkipped()
	{
		let document = Load("""
			<svg width="100" height="100"><text x="10" y="20" font-size="16">Hello</text></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		Test.Assert(context.FontService == null);

		SVGRenderer.Render(context, document, .(0, 0, 100, 100));
		Test.Assert(!AnyVertex(context));
	}

	/// One element on its own, which is what a caller drawing part of a document uses.
	[Test]
	public static void AnElementRendersOnItsOwn()
	{
		let document = Load("""
			<svg width="10" height="10"><rect x="1" y="1" width="8" height="8"/></svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.RenderElement(context, document.Elements[0]);

		let extent = Extent(context);
		Test.Assert(Near(extent.X, 1.0f, 1.5f), "no document scaling was applied");
		Test.Assert(Near(extent.Width, 8.0f, 1.5f));
	}

	/// Without a document there is nothing to resolve a reference against, so the element's
	/// own fill stands in.
	[Test]
	public static void AnElementWithoutItsDocumentUsesItsOwnFill()
	{
		let document = Load("""
			<svg width="10" height="10">
				<linearGradient id="fade"><stop offset="0" stop-color="#ff0000"/></linearGradient>
				<rect width="10" height="10" fill="url(#fade)"/>
			</svg>
			""");
		defer delete document;

		let context = scope VGContext();
		SVGRenderer.RenderElement(context, document.Elements[0]);

		Test.Assert(AnyVertex(context));
		for (let vertex in context.GetBatch().Vertices)
		{
			// The alpha varies: the antialiased fringe carries the same colour transparent.
			Test.Assert((vertex.Color.R == 0.0f) && (vertex.Color.G == 0.0f)
				&& (vertex.Color.B == 0.0f), "the stand in the loader recorded");
		}
	}
}
