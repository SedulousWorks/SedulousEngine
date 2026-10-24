using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// A 64 by 32 atlas, whatever path is asked for (each asking remembered).
class BorderAtlas : IResourceProvider
{
	public OwnedImageData Img ~ delete _;
	public List<String> Asked = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		let pixels = new uint8[64 * 32 * 4];
		defer delete pixels;
		Img = new OwnedImageData(64, 32, .RGBA8, Span<uint8>(pixels));
	}

	public override ImageData LoadImage(StringView path)
	{
		Asked.Add(new String(path));
		return Img;
	}

	public override bool LoadText(StringView path, String outText) => false;

	public override SVGDocument LoadSvg(StringView path) => null;
}

/// border-image from a sheet: slices, widths, fill and repeats from the shorthand; a percentage
/// slice; a spritesheet's sprite as an image; border-style's dashes and dots; an SVG sliced in its
/// own units and drawn as paths, then from its bake; a root redrawing when a bake lands.
class BorderImageTests
{
	private static bool Near(float a, float b) => NodeFixtures.Near(a, b);

	/// A panel of class `skin` in a GUI, styled by `css` with the atlas as its resources. The root
	/// (and the tree) go with the bed.
	private class Bed
	{
		public BorderAtlas Atlas = new .() ~ delete _;
		public SceneRoot Root = SceneFixtures.NewScene() ~ _.ReleaseRef();
		public Sedulous.GUI.Panel Panel = new .() ~ _.ReleaseRef();
		public StyleManager Styles = new .() ~ delete _;

		public this(StringView css)
		{
			Panel.AddClass("skin");
			Root.AddChild(Panel);
			Styles.ResourceProvider = Atlas;
			WidgetFixtures.UseSheet(Styles, css);
			Styles.ApplyTree(Root);
		}
	}

	[Test]
	public static void SlicesWidthsFillAndRepeatsFromTheShorthand()
	{
		let bed = scope Bed(".skin { border-width: 4px; border-style: solid; border-image: url(frame.png) 8 12 fill / 2 6px round repeat; }");
		let skin = bed.Panel.Box.Skin;
		Test.Assert(skin.Image === bed.Atlas.Img);
		Test.Assert(Near(skin.Slice[0], 8.0f)); // top
		Test.Assert(Near(skin.Slice[1], 12.0f)); // right
		Test.Assert(Near(skin.Slice[2], 8.0f)); // bottom, as top
		Test.Assert(Near(skin.Slice[3], 12.0f)); // left, as right
		Test.Assert(skin.Fill);
		Test.Assert(Near(skin.Width[0], 8.0f)); // 2 times the 4px border
		Test.Assert(Near(skin.Width[1], 6.0f));
		Test.Assert(skin.RepeatX == .Round);
		Test.Assert(skin.RepeatY == .Repeat);
		Test.Assert(!bed.Panel.Box.IsEmpty);
	}

	[Test]
	public static void APercentageSliceIsOfTheImageAndNoSliceIsAllOfIt()
	{
		let bed = scope Bed(".skin { border-image: url(frame.png) 25% stretch; }");
		let skin = bed.Panel.Box.Skin;
		Test.Assert(Near(skin.Slice[0], 8.0f)); // 25% of 32
		Test.Assert(Near(skin.Slice[1], 16.0f)); // 25% of 64
		Test.Assert(skin.Width[0] < 0.0f); // no width: the border's
		Test.Assert(skin.RepeatX == .Stretch);
	}

	[Test]
	public static void ASpriteNamedAsAnImageIsItsAtlasAndRegionInABorderImageAndABackground()
	{
		let bed = scope Bed("@spritesheet ui { src: url(theme/atlas.png); button: 0px 0px 32px 16px; star: 32 16 16 16; }" +
			".skin { border-image: url(button) 4 fill; background-image: url(\"star\"); background-size: auto; }");
		let area = bed.Panel.Box;
		Test.Assert(area.Skin.Image != null);
		Test.Assert(Near(area.Skin.Source.Width, 32.0f));
		Test.Assert(Near(area.Skin.Source.Height, 16.0f));
		Test.Assert(area.Layers.Count == 1);
		Test.Assert(Near(area.Layers[0].Source.X, 32.0f));
		Test.Assert(Near(area.Layers[0].Source.Y, 16.0f));
		for (let path in bed.Atlas.Asked)
			Test.Assert(path == "theme/atlas.png"); // the atlas, not the sprite's name
		// Its own size is the region's.
		let placed = PlaceImageLayer(area.Layers[0], Rectangle(0.0f, 0.0f, 100.0f, 100.0f), 16.0f, 16.0f);
		Test.Assert(Near(placed.Width, 16.0f));
	}

	[Test]
	public static void DashedAndDottedSidesAreRecordedTheRestAreSolid()
	{
		let bed = scope Bed(".skin { border-width: 2px; border-color: red; border-style: dashed dotted solid double; }");
		let area = bed.Panel.Box;
		Test.Assert(area.BorderLines[0] == .Dashed);
		Test.Assert(area.BorderLines[1] == .Dotted);
		Test.Assert(area.BorderLines[2] == .Solid);
		Test.Assert(area.BorderLines[3] == .Solid); // double: drawn solid
		Test.Assert(Near(area.BorderWidths.Top, 2.0f));
	}

	[Test]
	public static void AnSvgIsSlicedInItsOwnUnitsEachPieceDrawnAsPathsClippedToItsPlace()
	{
		// 30 by 30: a red, a green and a blue band, 10 wide each, sliced 10 from every side.
		let bed = scope Bed(".skin { border-width: 10px; border-style: solid; border-image: url(\"data:image/svg+xml,<svg width='30' height='30'>" +
			"<rect width='10' height='30' fill='red'/><rect x='10' width='10' height='30' fill='lime'/>" +
			"<rect x='20' width='10' height='30' fill='blue'/></svg>\") 10 fill; }");
		let area = bed.Panel.Box;
		Test.Assert(area.Skin.Svg != null);
		Test.Assert(area.Skin.Image == null);
		Test.Assert(Near(area.Skin.Slice[1], 10.0f)); // in its units
		Test.Assert(!area.IsEmpty);

		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 40.0f));
		let batch = ctx.GetBatch();
		int clipped = 0;
		int red = 0;
		int green = 0;
		int blue = 0;
		for (let command in batch.Commands)
		{
			if (!command.Scissored && (command.ClipMode == .None))
				continue;
			++clipped;
			let clip = command.ClipRect;
			for (int32 k = 0; k < command.IndexCount; ++k)
			{
				let v = batch.Vertices[(int)batch.Indices[command.StartIndex + k]];
				if ((v.Position.X < clip.X - 0.01f) || (v.Position.X > clip.X + clip.Width + 0.01f))
					continue; // cut off by its piece's clip
				if (v.Coverage < 0.99f)
					continue; // an edge's anti-aliasing fringe, half a pixel out
				if (v.Color.R > 0.5f)
				{
					++red;
					Test.Assert(v.Position.X <= 10.1f); // the left column alone
				}
				else if (v.Color.G > 0.5f)
				{
					++green;
					Test.Assert(v.Position.X >= 9.9f); // the middle, stretched across
					Test.Assert(v.Position.X <= 90.1f);
				}
				else if (v.Color.B > 0.5f)
				{
					++blue;
					Test.Assert(v.Position.X >= 89.9f); // the right column alone
				}
			}
		}
		Test.Assert(clipped >= 9); // a clip per piece
		Test.Assert(red > 0);
		Test.Assert(green > 0);
		Test.Assert(blue > 0);
	}

	[Test]
	public static void AnSvgSkinDrawsFromItsBakeOnceThereIsOneSizedAtItsCornersScaleInDevicePixels()
	{
		// 30 units sliced 10, drawn 20 wide: twice its size; at a device scale of 1.5, three times.
		let bed = scope Bed(".skin { border-image: url(\"data:image/svg+xml,<svg width='30' height='30'><rect width='30' height='30' fill='red'/></svg>\") 10 fill / 20px stretch; }");
		let area = bed.Panel.Box;
		Test.Assert(area.Skin.Svg != null);
		let baker = scope FakeBaker();
		{
			let ctx = scope VGContext();
			let dc = scope DrawContext(ctx);
			dc.PictureBaker = baker;
			ctx.Scale(1.5f, 1.5f);
			area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 60.0f)); // not baked yet: queued, drawn as paths
			Test.Assert(baker.Asked == 1);
			Test.Assert(baker.Width == 90); // 30 units, twice, at 1.5
			Test.Assert(baker.Height == 90);
			bool layered = false;
			for (let command in ctx.GetBatch().Commands)
				layered = layered || (command.DrawMode == .Layer);
			Test.Assert(!layered);
			Test.Assert(ctx.GetBatch().Vertices.Count > 36); // paths, not nine quads
		}
		baker.Ready = true;
		{
			let ctx = scope VGContext();
			let dc = scope DrawContext(ctx);
			dc.PictureBaker = baker;
			ctx.Scale(1.5f, 1.5f);
			area.DrawUnder(dc, Rect(0.0f, 0.0f, 100.0f, 60.0f));
			int pieces = 0;
			for (let command in ctx.GetBatch().Commands)
			{
				if (command.DrawMode != .Layer)
					continue;
				pieces++;
				Test.Assert(command.CompositeLayer == -1);
				Test.Assert(ctx.GetBatch().Textures[command.TextureIndex] === baker.Key);
			}
			Test.Assert(pieces == 9); // a premultiplied quad a piece, the middle filled
			Test.Assert(ctx.GetBatch().Vertices.Count == 36);
		}
	}

	[Test]
	public static void ARootRedrawsWhenABakeLands()
	{
		let bed = scope Bed(".skin { width: 40px; height: 40px; }");
		let baker = scope FakeBaker();
		bed.Root.Context.PictureBaker = baker;
		bed.Root.Size = .(100.0f, 100.0f);
		bed.Root.UpdateLayout();
		bed.Root.NeedsFrame();
		let ctx = scope VGContext();
		{
			let dc = scope DrawContext(ctx);
			bed.Root.DrawFrame(dc);
		}
		Test.Assert(!bed.Root.NeedsFrame()); // drawn: nothing new
		baker.Gen = 1; // a bake landed
		Test.Assert(bed.Root.NeedsFrame());
		Test.Assert(bed.Root.LastFrameStats.Reasons.Redraw);
		{
			let dc = scope DrawContext(ctx);
			bed.Root.DrawFrame(dc);
		}
		Test.Assert(!bed.Root.NeedsFrame());
	}
}
