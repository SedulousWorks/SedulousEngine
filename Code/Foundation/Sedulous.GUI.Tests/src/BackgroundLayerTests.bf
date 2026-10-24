using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A 40 by 20 picture for any raster, and a 24 by 12 SVG for any SVG (each SVG asked remembered).
class LayerPictures : IResourceProvider
{
	public OwnedImageData Img ~ delete _;
	public SVGDocument Svg = new .(24.0f, 12.0f) ~ delete _;
	public List<String> SvgsAsked = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		let pixels = new uint8[40 * 20 * 4];
		defer delete pixels;
		Img = new OwnedImageData(40, 20, .RGBA8, Span<uint8>(pixels));
	}

	public override ImageData LoadImage(StringView path) => Img;

	public override bool LoadText(StringView path, String outText) => false;

	public override SVGDocument LoadSvg(StringView path)
	{
		SvgsAsked.Add(new String(path));
		return Svg;
	}
}

/// background-size and background-position: an image layer fills its box unless sized (cover,
/// contain, lengths, auto), and is placed by percentages of the room left over or by lengths
/// from the box's edge.
class BackgroundLayerTests
{
	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	private static void CheckRect(Rectangle r, float x, float y, float w, float h)
	{
		Test.Assert(Near(r.X, x), scope $"x was {r.X}, expected {x}");
		Test.Assert(Near(r.Y, y), scope $"y was {r.Y}, expected {y}");
		Test.Assert(Near(r.Width, w), scope $"width was {r.Width}, expected {w}");
		Test.Assert(Near(r.Height, h), scope $"height was {r.Height}, expected {h}");
	}

	[Test]
	public static void AnImageLayerSizedAndPlacedInItsBox()
	{
		let area = Rectangle(10.0f, 10.0f, 100.0f, 100.0f);
		let layer = scope BoxLayer();
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 10.0f, 10.0f, 100.0f, 100.0f); // no size: filled
		layer.Size = .Cover; // 5x: 200 by 100, from the top left
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 10.0f, 10.0f, 200.0f, 100.0f);
		layer.X = LayerLength(0.0f, 50.0f, false); // centred: half the room (-100) left over
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), -40.0f, 10.0f, 200.0f, 100.0f);
		layer.Size = .Contain; // 2.5x: 100 by 50
		layer.Y = LayerLength(0.0f, 100.0f, false);
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 10.0f, 60.0f, 100.0f, 50.0f);
		layer.Size = .Lengths; // 50% wide, its height from the aspect
		layer.Width = LayerLength(0.0f, 50.0f, false);
		layer.Height = LayerLength(0.0f, 0.0f, true);
		layer.X = LayerLength(5.0f, 0.0f, false);
		layer.Y = LayerLength(0.0f, 0.0f, false);
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 15.0f, 10.0f, 50.0f, 25.0f);
		layer.Size = .Auto;
		CheckRect(PlaceImageLayer(layer, area, 40.0f, 20.0f), 15.0f, 10.0f, 40.0f, 20.0f);
	}

	[Test]
	public static void BackgroundSizeAndBackgroundPositionFromASheetACommaListPerLayer()
	{
		let pictures = scope LayerPictures();
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		panel.AddClass("card");
		root.AddChild(panel);
		let styles = scope StyleManager();
		styles.ResourceProvider = pictures;
		WidgetFixtures.UseSheet(styles, ".card { background-image: url(a.png), url(b.png), url(c.png);" +
			" background-size: cover, 50% auto; background-position: right bottom, 10px center; }");
		styles.ApplyTree(root);
		let layers = panel.Box.Layers;
		Test.Assert(layers.Count == 3);
		Test.Assert(layers[0].Size == .Cover);
		Test.Assert(Near(layers[0].X.Percent, 100.0f));
		Test.Assert(Near(layers[0].Y.Percent, 100.0f));
		Test.Assert(layers[1].Size == .Lengths);
		Test.Assert(Near(layers[1].Width.Percent, 50.0f));
		Test.Assert(layers[1].Height.Auto);
		Test.Assert(Near(layers[1].X.Px, 10.0f));
		Test.Assert(Near(layers[1].Y.Percent, 50.0f));
		Test.Assert(layers[2].Size == .Lengths); // past the list: the last again
		Test.Assert(Near(layers[2].X.Px, 10.0f));
	}

	[Test]
	public static void AnSvgLayerIsAskedForAsSvgAndPlacedByItsOwnSize()
	{
		let pictures = scope LayerPictures();
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		let panel = new Panel();
		defer panel.ReleaseRef();
		panel.AddClass("badge");
		root.AddChild(panel);
		let styles = scope StyleManager();
		styles.ResourceProvider = pictures;
		WidgetFixtures.UseSheet(styles, ".badge { background-image: url(icons/star.svg), url(paper.png); background-size: contain; }");
		styles.ApplyTree(root);
		let layers = panel.Box.Layers;
		Test.Assert(layers.Count == 2);
		Test.Assert(layers[0].Svg === pictures.Svg);
		Test.Assert(layers[0].Image == null);
		Test.Assert(layers[1].Image === pictures.Img);
		Test.Assert(pictures.SvgsAsked.Count == 1);
		Test.Assert(pictures.SvgsAsked[0] == "icons/star.svg");
		// Contained in a 100 by 100 box, the 24 by 12 picture is 100 by 50.
		let placed = PlaceImageLayer(layers[0], Rectangle(0.0f, 0.0f, 100.0f, 100.0f), 24.0f, 12.0f);
		CheckRect(placed, 0.0f, 0.0f, 100.0f, 50.0f);
	}
}
