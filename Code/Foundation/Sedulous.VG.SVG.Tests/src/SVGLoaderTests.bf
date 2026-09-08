using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.VG.SVG;

namespace Sedulous.VG.SVG.Tests;

/// Reading a document out of its text.
class SVGLoaderTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// THE CALLER OWNS what comes back.
	private static SVGDocument Load(StringView content)
	{
		Test.Assert(SVGLoader.Load(content) case .Ok(let document), "the document did not load");
		return document;
	}

	private static int CountOf(Path path, PathCommand wanted)
	{
		var count = 0;
		for (let command in path.Commands)
		{
			if (command == wanted)
				count++;
		}
		return count;
	}

	[Test]
	public static void TheDocumentTakesItsStatedSize()
	{
		let document = Load("<svg width=\"100\" height=\"50\"></svg>");
		defer delete document;

		Test.Assert(document.Width == 100.0f);
		Test.Assert(document.Height == 50.0f);
	}

	/// A trailing unit is dropped: everything here is in user units anyway, and refusing
	/// one would fail on files that are otherwise fine.
	[Test]
	public static void AUnitSuffixIsIgnored()
	{
		let document = Load("<svg width=\"100px\" height=\"50px\"></svg>");
		defer delete document;
		Test.Assert(document.Width == 100.0f);
		Test.Assert(document.Height == 50.0f);
	}

	/// The view box is the FALLBACK. Its third and fourth numbers are the extent; the
	/// first two are the origin.
	[Test]
	public static void TheViewBoxSuppliesAMissingSize()
	{
		let document = Load("<svg viewBox=\"0 0 24 24\"></svg>");
		defer delete document;
		Test.Assert(document.Width == 24.0f);
		Test.Assert(document.Height == 24.0f);

		let offset = Load("<svg viewBox=\"-10 -10 200 100\"></svg>");
		defer delete offset;
		Test.Assert(offset.Width == 200.0f, "the extent, not the origin");
		Test.Assert(offset.Height == 100.0f);
	}

	/// An explicit size WINS over the view box.
	[Test]
	public static void AnExplicitSizeBeatsTheViewBox()
	{
		let document = Load("<svg width=\"48\" height=\"48\" viewBox=\"0 0 24 24\"></svg>");
		defer delete document;
		Test.Assert(document.Width == 48.0f);
	}

	/// Text that is not an SVG document at all fails rather than producing an empty one.
	[Test]
	public static void SomethingThatIsNotAnSvgFails()
	{
		Test.Assert(SVGLoader.Load("") case .Err);
		Test.Assert(SVGLoader.Load("hello") case .Err);
		Test.Assert(SVGLoader.Load("<html><body></body></html>") case .Err);
	}

	// ---- shapes ----

	[Test]
	public static void EveryShapeTagBecomesGeometry()
	{
		let document = Load("""
			<svg width="100" height="100">
				<path d="M 0 0 L 10 10"/>
				<rect x="0" y="0" width="10" height="10"/>
				<circle cx="5" cy="5" r="5"/>
				<ellipse cx="5" cy="5" rx="5" ry="3"/>
				<line x1="0" y1="0" x2="10" y2="10"/>
				<polygon points="0,0 10,0 5,10"/>
				<polyline points="0,0 10,0 5,10"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 7);
		for (let element in document.Elements)
			Test.Assert(element.Path != null, scope $"{element.Type} has no geometry");

		Test.Assert(document.Elements[0].Type == .Path);
		Test.Assert(document.Elements[1].Type == .Rectangle);
		Test.Assert(document.Elements[2].Type == .Circle);
		Test.Assert(document.Elements[3].Type == .Ellipse);
		Test.Assert(document.Elements[4].Type == .Line);
		Test.Assert(document.Elements[5].Type == .Polygon);
		Test.Assert(document.Elements[6].Type == .Polyline);
	}

	/// A polygon closes and a polyline does not, which is the only difference between them.
	[Test]
	public static void APolygonClosesAndAPolylineDoesNot()
	{
		let document = Load("""
			<svg><polygon points="0,0 10,0 5,10"/><polyline points="0,0 10,0 5,10"/></svg>
			""");
		defer delete document;

		Test.Assert(CountOf(document.Elements[0].Path, .Close) == 1);
		Test.Assert(CountOf(document.Elements[1].Path, .Close) == 0);
	}

	/// A trailing lone number is dropped rather than paired with a zero, which would put a
	/// stray vertex on the axis.
	[Test]
	public static void AnOddPointListDropsItsTrailingNumber()
	{
		let document = Load("<svg><polyline points=\"0,0 10,0 5\"/></svg>");
		defer delete document;
		Test.Assert(document.Elements[0].Path.PointCount == 2);
	}

	/// Either radius alone implies the other, so rx="4" is a uniformly rounded rectangle.
	[Test]
	public static void EitherCornerRadiusImpliesTheOther()
	{
		let document = Load("""
			<svg>
				<rect width="20" height="20" rx="4"/>
				<rect width="20" height="20" ry="4"/>
				<rect width="20" height="20"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(CountOf(document.Elements[0].Path, .CubicTo) == 4, "rounded from rx alone");
		Test.Assert(CountOf(document.Elements[1].Path, .CubicTo) == 4, "and from ry alone");
		Test.Assert(CountOf(document.Elements[2].Path, .CubicTo) == 0, "square without either");
	}

	// ---- style ----

	/// The SVG default fill is BLACK, not nothing: an element with no fill attribute still
	/// draws.
	[Test]
	public static void TheDefaultFillIsBlack()
	{
		let document = Load("<svg><rect width=\"10\" height=\"10\"/></svg>");
		defer delete document;

		Test.Assert(document.Elements[0].FillColor != null);
		Test.Assert(document.Elements[0].FillColor.Value == Color.Black);
	}

	/// Explicitly none is DIFFERENT from absent, and draws nothing.
	[Test]
	public static void AnExplicitNoneFillDrawsNothing()
	{
		let document = Load("<svg><rect width=\"10\" height=\"10\" fill=\"none\"/></svg>");
		defer delete document;
		Test.Assert(document.Elements[0].FillColor == null);
	}

	[Test]
	public static void TheStyleAttributesAreRead()
	{
		let document = Load("""
			<svg>
				<rect width="10" height="10" fill="#ff0000" stroke="blue"
					stroke-width="3" opacity="0.5"/>
			</svg>
			""");
		defer delete document;

		let element = document.Elements[0];
		Test.Assert(element.FillColor.Value == Color.Red);
		Test.Assert(element.StrokeColor.Value == Color.Blue);
		Test.Assert(element.StrokeWidth == 3.0f);
		Test.Assert(Near(element.Opacity, 0.5f));
	}

	/// A stroke of none leaves no stroke colour, so nothing is stroked.
	[Test]
	public static void AStrokeOfNoneLeavesNoStroke()
	{
		let document = Load("<svg><rect width=\"10\" height=\"10\" stroke=\"none\"/></svg>");
		defer delete document;
		Test.Assert(document.Elements[0].StrokeColor == null);
	}

	[Test]
	public static void ATransformAttributeIsParsed()
	{
		let document = Load("""
			<svg><rect width="10" height="10" transform="translate(5, 5)"/></svg>
			""");
		defer delete document;

		let moved = TransformPoint2D(.(0, 0), document.Elements[0].Transform);
		Test.Assert(Near(moved.X, 5.0f) && Near(moved.Y, 5.0f));
	}

	/// A transform that does not parse leaves the element UNTRANSFORMED rather than
	/// somewhere arbitrary.
	[Test]
	public static void AMalformedTransformIsIgnored()
	{
		let document = Load("<svg><rect width=\"10\" height=\"10\" transform=\"wobble(1)\"/></svg>");
		defer delete document;
		Test.Assert(document.Elements[0].Transform == Float4x4.Identity());
	}

	// ---- structure ----

	[Test]
	public static void AGroupHoldsItsChildren()
	{
		let document = Load("""
			<svg>
				<g transform="translate(10, 10)">
					<rect width="10" height="10"/>
					<circle cx="5" cy="5" r="5"/>
				</g>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 1);
		let group = document.Elements[0];
		Test.Assert(group.Type == .Group);
		Test.Assert(group.IsGroup);
		Test.Assert(group.Children.Count == 2);
	}

	[Test]
	public static void GroupsNest()
	{
		let document = Load("""
			<svg><g><g><rect width="10" height="10"/></g></g></svg>
			""");
		defer delete document;

		Test.Assert(document.Elements[0].Children[0].Children.Count == 1);
		Test.Assert(document.Elements[0].Children[0].Children[0].Type == .Rectangle);
	}

	/// An empty group is not a group: there is nothing to draw.
	[Test]
	public static void AnEmptyGroupIsNotAGroup()
	{
		let document = Load("<svg><g/></svg>");
		defer delete document;
		Test.Assert(document.Elements[0].Type == .Group);
		Test.Assert(!document.Elements[0].IsGroup);
	}

	/// An unrecognised tag is SKIPPED rather than failing the document. Real files carry
	/// editor metadata that no renderer needs.
	[Test]
	public static void UnrecognisedTagsAreSkipped()
	{
		let document = Load("""
			<svg width="100" height="100">
				<metadata><rdf:RDF>whatever</rdf:RDF></metadata>
				<sodipodi:namedview id="base" pagecolor="#ffffff"/>
				<rect width="10" height="10"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 1, "only the rectangle");
		Test.Assert(document.Elements[0].Type == .Rectangle);
	}

	/// An unrecognised tag takes its CHILDREN with it. Skipping only the opening tag would
	/// leave them at this level and let the block's closing tag end it, dropping every
	/// sibling that follows.
	[Test]
	public static void AnUnrecognisedTagTakesItsSubtreeWithIt()
	{
		let document = Load("""
			<svg>
				<style type="text/css">.cls { fill: red; }</style>
				<desc>An icon <with/> markup inside its description</desc>
				<rect width="10" height="10"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 1, "the rectangle survived the two blocks");
		Test.Assert(document.Elements[0].Type == .Rectangle);
	}

	/// Same named blocks NEST, so the first closing tag is not necessarily the match.
	[Test]
	public static void NestedUnrecognisedTagsSkipAsAWhole()
	{
		let document = Load("""
			<svg>
				<metadata><metadata>inner</metadata>outer</metadata>
				<rect width="10" height="10"/>
			</svg>
			""");
		defer delete document;
		Test.Assert(document.Elements.Count == 1);
	}

	/// A tag whose name merely STARTS with the skipped one does not close it.
	[Test]
	public static void ALongerNameDoesNotCloseTheSkippedTag()
	{
		let document = Load("""
			<svg>
				<lineDefinitions><line x1="0" y1="0" x2="1" y2="1"/></lineDefinitions>
				<rect width="10" height="10"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 1, "the line inside the block was skipped too");
		Test.Assert(document.Elements[0].Type == .Rectangle);
	}

	/// A comment is stepped over as one unit, so markup inside it is not drawn.
	[Test]
	public static void CommentedOutMarkupIsNotDrawn()
	{
		let document = Load("""
			<svg>
				<!-- <circle cx="5" cy="5" r="5"/> a > b -->
				<rect width="10" height="10"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 1);
		Test.Assert(document.Elements[0].Type == .Rectangle);
	}

	/// An XML declaration and a doctype have no closing tag to look for.
	[Test]
	public static void ADeclarationAndDoctypeAreStepped()
	{
		let document = Load("""
			<?xml version="1.0" encoding="UTF-8"?>
			<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
			<svg width="100" height="100"><rect width="10" height="10"/></svg>
			""");
		defer delete document;

		Test.Assert(document.Width == 100.0f);
		Test.Assert(document.Elements.Count == 1);
	}

	[Test]
	public static void BothQuoteStylesWork()
	{
		let document = Load("<svg width='100' height=\"50\"><rect width='10' height='10'/></svg>");
		defer delete document;

		Test.Assert(document.Width == 100.0f);
		Test.Assert(document.Height == 50.0f);
		Test.Assert(document.Elements.Count == 1);
	}

	// ---- text ----

	[Test]
	public static void ATextElementCarriesItsContentAndStyle()
	{
		let document = Load("""
			<svg><text x="10" y="20" font-size="24" text-anchor="middle"
				font-weight="bold">Hello</text></svg>
			""");
		defer delete document;

		let element = document.Elements[0];
		Test.Assert(element.Type == .Text);
		Test.Assert(element.TextContent == "Hello");
		Test.Assert(element.TextX == 10.0f);
		Test.Assert(element.TextY == 20.0f);
		Test.Assert(element.FontSize == 24.0f);
		Test.Assert(element.TextAnchor == .Middle);
		Test.Assert(element.FontBold);
	}

	/// Runs of whitespace collapse to single spaces and the ends are trimmed, so text laid
	/// out across several lines reads as one line rather than carrying the indentation.
	[Test]
	public static void TextWhitespaceIsCollapsed()
	{
		let document = Load("<svg><text x=\"0\" y=\"0\">\n\t  Hello   world\n\t</text></svg>");
		defer delete document;
		Test.Assert(document.Elements[0].TextContent == "Hello   world");
	}

	// ---- gradients ----

	/// A gradient registers on the DOCUMENT rather than becoming an element, so several
	/// elements can reference one.
	[Test]
	public static void AGradientRegistersOnTheDocument()
	{
		let document = Load("""
			<svg>
				<defs>
					<linearGradient id="fade" x1="0" y1="0" x2="1" y2="0">
						<stop offset="0" stop-color="#ff0000"/>
						<stop offset="1" stop-color="#0000ff"/>
					</linearGradient>
				</defs>
				<rect width="10" height="10" fill="url(#fade)"/>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Elements.Count == 1, "the defs block emits no elements");
		Test.Assert(document.Gradients.Count == 1);
		Test.Assert(document.Elements[0].FillGradientId == "fade");
		// Black stands in until the reference resolves, so it still draws.
		Test.Assert(document.Elements[0].FillColor.Value == Color.Black);

		Test.Assert(document.Gradients.TryGetValue(scope String("fade"), let gradient));
		Test.Assert(!gradient.Radial);
		Test.Assert(gradient.Stops.Count == 2);
		Test.Assert(gradient.Stops[0].Color == Color.Red);
		Test.Assert(gradient.Stops[1].Color == Color.Blue);
	}

	[Test]
	public static void ARadialGradientTakesItsCircle()
	{
		let document = Load("""
			<svg><radialGradient id="glow" cx="0.3" cy="0.7" r="0.8">
				<stop offset="0" stop-color="white"/>
			</radialGradient></svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.TryGetValue(scope String("glow"), let gradient));
		Test.Assert(gradient.Radial);
		Test.Assert(Near(gradient.Cx, 0.3f));
		Test.Assert(Near(gradient.Cy, 0.7f));
		Test.Assert(Near(gradient.R, 0.8f));
	}

	/// A percentage becomes a fraction, which is what the geometry is in.
	[Test]
	public static void PercentagesBecomeFractions()
	{
		let document = Load("""
			<svg><linearGradient id="g" x1="0%" x2="50%">
				<stop offset="25%" stop-color="red"/>
			</linearGradient></svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.TryGetValue(scope String("g"), let gradient));
		Test.Assert(Near(gradient.X2, 0.5f));
		Test.Assert(Near(gradient.Stops[0].Offset, 0.25f));
	}

	/// The style form overrides the attributes, because that is what editors export and
	/// what CSS says.
	[Test]
	public static void AStopStyleOverridesItsAttributes()
	{
		let document = Load("""
			<svg><linearGradient id="g">
				<stop offset="0" stop-color="red" style="stop-color:#0000ff;stop-opacity:0.5"/>
			</linearGradient></svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.TryGetValue(scope String("g"), let gradient));
		let stop = gradient.Stops[0];
		Test.Assert(stop.Color.B == 1.0f, "the style's colour won");
		Test.Assert(Near(stop.Color.A, 0.5f), "and its opacity");
	}

	/// The stop opacity MULTIPLIES the colour's own alpha rather than replacing it.
	[Test]
	public static void TheStopOpacityMultipliesTheColoursAlpha()
	{
		let document = Load("""
			<svg><linearGradient id="g">
				<stop offset="0" stop-color="#ff000080" stop-opacity="0.5"/>
			</linearGradient></svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.TryGetValue(scope String("g"), let gradient));
		Test.Assert(Near(gradient.Stops[0].Color.A, (128.0f / 255.0f) * 0.5f, 0.01f));
	}

	[Test]
	public static void TheSpreadMethodIsRead()
	{
		let document = Load("""
			<svg>
				<linearGradient id="a" spreadMethod="repeat"><stop offset="0"/></linearGradient>
				<linearGradient id="b" spreadMethod="reflect"><stop offset="0"/></linearGradient>
				<linearGradient id="c"><stop offset="0"/></linearGradient>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.TryGetValue(scope String("a"), let repeated));
		Test.Assert(repeated.Spread == .Repeat);
		Test.Assert(document.Gradients.TryGetValue(scope String("b"), let reflected));
		Test.Assert(reflected.Spread == .Reflect);
		Test.Assert(document.Gradients.TryGetValue(scope String("c"), let padded));
		Test.Assert(padded.Spread == .Pad, "padded by default");
	}

	[Test]
	public static void UserSpaceUnitsAreRecorded()
	{
		let document = Load("""
			<svg><linearGradient id="g" gradientUnits="userSpaceOnUse" x1="0" x2="100">
				<stop offset="0"/>
			</linearGradient></svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.TryGetValue(scope String("g"), let gradient));
		Test.Assert(gradient.UserSpace);
		Test.Assert(Near(gradient.X2, 100.0f), "document coordinates, not a fraction");
	}

	/// An UNNAMED gradient can never be referenced, so there is nothing to keep.
	[Test]
	public static void AnUnnamedGradientIsDiscarded()
	{
		let document = Load("<svg><linearGradient><stop offset=\"0\"/></linearGradient></svg>");
		defer delete document;
		Test.Assert(document.Gradients.Count == 0);
		Test.Assert(document.Elements.Count == 0);
	}

	/// A repeated id REPLACES, which is what a later definition means.
	[Test]
	public static void ARepeatedGradientIdReplaces()
	{
		let document = Load("""
			<svg>
				<linearGradient id="g"><stop offset="0" stop-color="red"/></linearGradient>
				<linearGradient id="g"><stop offset="0" stop-color="blue"/></linearGradient>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Gradients.Count == 1);
		Test.Assert(document.Gradients.TryGetValue(scope String("g"), let gradient));
		Test.Assert(gradient.Stops[0].Color == Color.Blue);
	}

	/// A realistic icon: a view box, a group, a transform, and a couple of shapes.
	[Test]
	public static void ARealisticIconLoads()
	{
		let document = Load("""
			<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
				stroke="currentColor" stroke-width="2">
				<path d="M3 12h18M12 3v18"/>
				<g transform="translate(2,2)">
					<circle cx="10" cy="10" r="8" fill="#3366cc"/>
				</g>
			</svg>
			""");
		defer delete document;

		Test.Assert(document.Width == 24.0f);
		Test.Assert(document.Height == 24.0f);
		Test.Assert(document.Elements.Count == 2);
		Test.Assert(document.Elements[0].Path != null);
		Test.Assert(document.Elements[1].IsGroup);
		Test.Assert(document.Elements[1].Children[0].Type == .Circle);
	}
}
