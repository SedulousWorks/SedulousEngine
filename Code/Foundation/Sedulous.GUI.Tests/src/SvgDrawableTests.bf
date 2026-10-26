using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts.TrueType;
using Sedulous.Image;
using Sedulous.VG;
using Sedulous.VG.SVG;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// An SVG and a raster, each counted when asked for.
class SvgPictures : IResourceProvider
{
	public OwnedImageData Img ~ delete _;
	public SVGDocument Doc ~ delete _;
	public int Images = 0;
	public int Svgs = 0;

	public this()
	{
		uint8[40 * 20 * 4] pixels = default;
		Img = new OwnedImageData(40, 20, .RGBA8, Span<uint8>(&pixels[0], pixels.Count));
		if (SVGLoader.Load(SvgDrawableTests.cBar) case .Ok(let document))
			Doc = document;
	}

	public override ImageData LoadImage(StringView path)
	{
		Images++;
		if (path == "missing.png")
			return null;
		return Img;
	}

	public override bool LoadText(StringView path, String outText) => false;

	public override SVGDocument LoadSvg(StringView path)
	{
		Svgs++;
		if (path == "missing.svg")
			return null;
		return Doc;
	}
}

/// The SVG drawable: an SVG picture as image content, from its markup (owning its document) or
/// by a path through the resource provider (borrowing the provider's); its intrinsic size is the
/// document's, it draws paths at the size it lands, and a tint recolours it whole.
/// PictureDrawable picks SVG or raster by the source (an SVG by a .svg ending or written inline
/// as a data: URL, which the provider parses once and keeps).
class SvgDrawableTests
{
	/// A red 24 by 12 rectangle.
	public const String cBar = "<svg width=\"24\" height=\"12\"><rect width=\"24\" height=\"12\" fill=\"#ff0000\"/></svg>";
	private const String cBarBase64 =
		"PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMTIiPjxyZWN0IHdpZHRoPSIyNCIgaGVpZ2h0PSIxMiIgZmlsbD0iI2ZmMDAwMCIvPjwvc3ZnPg==";
	private const String cBarPercent =
		"data:image/svg+xml,%3Csvg%20width%3D%2224%22%20height%3D%2212%22%3E%3Crect%20width%3D%2224%22%20height%3D%2212%22%20fill%3D%22%23ff0000%22%2F%3E%3C%2Fsvg%3E";

	/// doctest's Approx: within a relative epsilon (scaled by 1 plus the larger magnitude).
	private static bool Near(float a, float b, float epsilon = 1.2e-5f) =>
		Math.Abs(a - b) < epsilon * (1.0f + Math.Max(Math.Abs(a), Math.Abs(b)));

	private static bool AllRed(VGContext ctx)
	{
		for (let v in ctx.GetBatch().Vertices)
			if ((v.Color.R < 0.99f) || (v.Color.G > 0.01f))
				return false;
		return true;
	}

	/// Whether `source` decodes to `expected`.
	private static bool Decodes(StringView source, StringView expected)
	{
		let text = scope String();
		return DecodeSvgDataUrl(source, text) && (text == expected);
	}

	[Test]
	public static void FromItsMarkupTheDocumentsSizeAndThePathsItDrawsAsAuthored()
	{
		let d = SvgDrawable.FromText(cBar);
		Test.Assert(d != null);
		defer d.ReleaseRef();
		Test.Assert(d.Document != null);
		Test.Assert(d.IntrinsicSize.HasValue);
		Test.Assert(Near(d.IntrinsicSize.Value.X, 24.0f));
		Test.Assert(Near(d.IntrinsicSize.Value.Y, 12.0f));
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		d.Draw(dc, Rect(0.0f, 0.0f, 48.0f, 24.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count > 0);
		Test.Assert(AllRed(ctx)); // white draws it as authored
		for (let v in ctx.GetBatch().Vertices)
		{
			Test.Assert(v.Position.X >= -1.0f); // scaled into the rectangle it lands in
			Test.Assert(v.Position.X <= 49.0f);
			Test.Assert(v.Position.Y <= 25.0f);
		}
	}

	[Test]
	public static void ATintRecoloursItWholeMarkupThatDoesNotParseMakesNone()
	{
		let d = SvgDrawable.FromText(cBar);
		Test.Assert(d != null);
		defer d.ReleaseRef();
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		d.DrawTinted(dc, Rect(0.0f, 0.0f, 24.0f, 12.0f), Color.Blue);
		Test.Assert(ctx.GetBatch().Vertices.Count > 0);
		for (let v in ctx.GetBatch().Vertices)
		{
			Test.Assert(Near(v.Color.B, 1.0f));
			Test.Assert(Near(v.Color.R, 0.0f));
		}
		Test.Assert(SvgDrawable.FromText("not svg") == null);
	}

	[Test]
	public static void APictureByItsPathIsAnSvgByItsEndingARasterOtherwiseNoneWhenMissing()
	{
		let pictures = scope SvgPictures();
		let svg = PictureDrawable(pictures, "Icons/bar.SVG");
		Test.Assert(svg != null);
		defer svg.ReleaseRef();
		let asSvg = svg as SvgDrawable;
		Test.Assert(asSvg != null);
		Test.Assert(asSvg.Document === pictures.Doc); // borrowed, not copied
		let raster = PictureDrawable(pictures, "Icons/bar.png");
		Test.Assert(raster != null);
		defer raster.ReleaseRef();
		Test.Assert((raster as ImageDrawable) != null);
		Test.Assert(pictures.Svgs == 1);
		Test.Assert(pictures.Images == 1);
		Test.Assert(PictureDrawable(pictures, "missing.svg") == null);
		Test.Assert(PictureDrawable(pictures, "missing.png") == null);
	}

	[Test]
	public static void AnSvgWrittenInlineDecodesFromADataUrlPlainPercentEncodedOrBase64()
	{
		Test.Assert(Decodes(cBarPercent, cBar));
		let base64 = scope String("data:image/svg+xml;charset=utf-8;base64,");
		base64.Append(cBarBase64);
		Test.Assert(Decodes(base64, cBar));
		Test.Assert(Decodes("DATA:image/SVG+xml;utf8,<svg/>", "<svg/>")); // the media type in any case
		Test.Assert(!DecodeSvgDataUrl("data:image/svg+xml;base64,not*base64", scope String()));
		Test.Assert(!DecodeSvgDataUrl("data:image/png;base64,AAAA", scope String()));
		Test.Assert(!DecodeSvgDataUrl("data:image/svg+xmlfoo,<svg/>", scope String()));

		Test.Assert(IsSvgSource(cBarPercent));
		Test.Assert(IsSvgSource("Icons/a.svg"));
		Test.Assert(!IsSvgSource("Icons/a.png"));
		Test.Assert(!IsSvgSource("data:image/png;base64,AAAA"));
	}

	[Test]
	public static void TheProviderParsesAnInlineSvgOnceAndKeepsItAPathStillGoesToLoadSvg()
	{
		let pictures = scope SvgPictures();
		let first = pictures.Svg(cBarPercent);
		Test.Assert(first != null);
		Test.Assert(Near(first.Width, 24.0f));
		Test.Assert(pictures.Svg(cBarPercent) === first); // the same document, not parsed again
		Test.Assert(pictures.Svgs == 0);
		Test.Assert(pictures.Svg("data:image/svg+xml,not svg") == null);
		Test.Assert(pictures.Svg("data:image/svg+xml,not svg") == null); // remembered as none
		Test.Assert(pictures.Svg("bar.svg") === pictures.Doc);
		Test.Assert(pictures.Svgs == 1);
	}

	[Test]
	public static void ARichTextsInlineIconByAnSvgPathIsDrawnAsItsPaths()
	{
		let service = scope TrueTypeFontService();
		TextFixtures.Load(service, "Roboto", TextFixtures.cRoboto);
		let pictures = scope SvgPictures();
		let text = scope Text();
		text.FontService = service;
		text.Font = service.GetFont("Roboto", 16.0f);
		text.SetResourceProvider(pictures);
		text.SetMarkup("[icon=bar.svg]");
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		text.Draw(dc, Float2(0.0f, 0.0f));
		Test.Assert(pictures.Svgs == 1);
		Test.Assert(pictures.Images == 0);
		Test.Assert(ctx.GetBatch().Vertices.Count > 0);
		Test.Assert(AllRed(ctx)); // the icon alone, as authored
	}

	[Test]
	public static void AnImageShowsAnSvgByItsSrcOrFromItsTextSizedAsTheDocument()
	{
		let pictures = scope SvgPictures();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		root.Context.ResourceProvider = pictures;
		let bySource = new Sedulous.GUI.Image();
		defer bySource.ReleaseRef();
		bySource.Source = "bar.svg";
		let fromText = new Sedulous.GUI.Image();
		defer fromText.ReleaseRef();
		let drawable = SvgDrawable.FromText(cBar);
		fromText.SetDrawable(drawable);
		drawable.ReleaseRef(); // the image's reference keeps it
		root.AddChild(bySource);
		root.AddChild(fromText);
		root.UpdateLayout();
		Test.Assert(pictures.Svgs == 1);
		Test.Assert(pictures.Images == 0);
		Test.Assert(NodeFixtures.Near(bySource.Size.X, 24.0f));
		Test.Assert(NodeFixtures.Near(bySource.Size.Y, 12.0f));
		Test.Assert(NodeFixtures.Near(fromText.Size.X, 24.0f));
		Test.Assert(NodeFixtures.Near(fromText.Size.Y, 12.0f));
	}

	[Test]
	public static void AMenuCommandsIconByAnSvgPath()
	{
		let pictures = scope SvgPictures();
		let root = SceneFixtures.NewScene();
		defer root.ReleaseRef();
		root.Context.ResourceProvider = pictures;
		let item = new MenuItem();
		defer item.ReleaseRef();
		root.AddChild(item);
		item.OnBoundCommandText("Bar", "bar.svg", "");
		Test.Assert(pictures.Svgs == 1);
		Test.Assert(item.Icon != null);
		Test.Assert(item.Icon is SvgDrawable);
	}

	[Test]
	public static void AnInlineSvgAsASheetsBackgroundAnImagesSrcAndARichTextsIcon()
	{
		let pictures = scope SvgPictures();
		let root = SceneFixtures.NewScene(200.0f, 200.0f);
		defer root.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		root.Context.ResourceProvider = pictures;
		let panel = new Panel();
		defer panel.ReleaseRef();
		panel.AddClass("card");
		root.AddChild(panel);
		let styles = scope StyleManager();
		styles.ResourceProvider = pictures;
		WidgetFixtures.UseSheet(styles,
			".card { background-image: url(\"data:image/svg+xml,<svg width='24' height='12'><rect width='24' height='12'" +
			" fill='%23ff0000'/></svg>\"); }");
		styles.ApplyTree(root);
		Test.Assert(panel.Box.Layers.Count == 1);
		Test.Assert(panel.Box.Layers[0].Svg != null);
		Test.Assert(NodeFixtures.Near(panel.Box.Layers[0].Svg.Width, 24.0f));

		let markup = scope String("<Image src=\"");
		markup.Append(cBarPercent);
		markup.Append("\"/>");
		let image = MarkupFixtures.Load(markup);
		Test.Assert(image != null);
		defer image.ReleaseRef();
		root.AddChild(image);
		root.UpdateLayout();
		Test.Assert(NodeFixtures.Near(image.Size.X, 24.0f));
		Test.Assert(NodeFixtures.Near(image.Size.Y, 12.0f));
		Test.Assert(pictures.Svgs == 0); // neither asked the provider for a file

		let service = scope TrueTypeFontService();
		TextFixtures.Load(service, "Roboto", TextFixtures.cRoboto);
		let text = scope Text();
		text.FontService = service;
		text.Font = service.GetFont("Roboto", 16.0f);
		text.SetResourceProvider(pictures);
		let rich = scope String("[icon=");
		rich.Append(cBarPercent);
		rich.Append("]");
		text.SetMarkup(rich);
		let ctx = scope VGContext();
		let dc = scope DrawContext(ctx);
		text.Draw(dc, Float2(0.0f, 0.0f));
		Test.Assert(ctx.GetBatch().Vertices.Count > 0);
		Test.Assert(AllRed(ctx));
		Test.Assert(pictures.Svgs == 0);
	}

	/// `icon` drawn 12 by 6 under a scale of two device pixels a unit, through `baker`.
	private static void DrawThroughAtlas(SvgDrawable icon, AtlasBaker baker, VGContext ctx, Color tint)
	{
		let dc = scope DrawContext(ctx);
		dc.PictureBaker = baker;
		ctx.Scale(2.0f, 2.0f); // two device pixels a unit
		icon.DrawTinted(dc, Rect(0.0f, 0.0f, 12.0f, 6.0f), tint);
	}

	/// With a baker an icon is asked for in its atlas at its size in device pixels, drawn as
	/// paths until it is there, then as one quad carrying its tint. A tinted icon is baked white
	/// (a mask), an untinted one as authored.
	[Test]
	public static void WithABakerItIsAskedForInItsAtlasAtItsDeviceSizeDrawnAsPathsUntilItIsThereThenAsOneQuad()
	{
		let icon = SvgDrawable.FromText(cBar);
		Test.Assert(icon != null);
		defer icon.ReleaseRef();
		let baker = scope AtlasBaker();
		let tint = Color(0.2f, 0.4f, 1.0f, 1.0f);
		{
			let ctx = scope VGContext();
			DrawThroughAtlas(icon, baker, ctx, tint);
			Test.Assert(baker.Asked == 1);
			Test.Assert(baker.Width == 24); // its size on the device
			Test.Assert(baker.Height == 12);
			Test.Assert(baker.Mask); // tinted: baked white, to take the tint
			for (let command in ctx.GetBatch().Commands)
				Test.Assert(command.DrawMode != .Layer); // paths meanwhile
		}
		{
			let ctx = scope VGContext();
			DrawThroughAtlas(icon, baker, ctx, tint);
			let batch = ctx.GetBatch();
			Test.Assert(batch.CommandCount == 1);
			Test.Assert(batch.GetCommand(0).DrawMode == .Layer);
			Test.Assert(batch.Textures[batch.GetCommand(0).TextureIndex] === baker.Page);
			Test.Assert(batch.GetCommand(0).IndexCount == 6); // one quad
			Test.Assert(NodeFixtures.Near(batch.Vertices[0].Color.B, 1.0f)); // the tint, on the quad
			Test.Assert(NodeFixtures.Near(batch.Vertices[0].Color.R, 0.2f));
		}
		{
			let ctx = scope VGContext();
			DrawThroughAtlas(icon, baker, ctx, .White);
			Test.Assert(!baker.Mask); // white: as authored
		}
	}
}

/// An atlas that has a picture the second time it is asked for it, and says what it was asked.
class AtlasBaker : IPictureBaker
{
	public ImageDataRef Page = new .(512, 512) ~ delete _;
	public int Asked = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;
	public bool Mask = false;

	public ImageData Baked(SVGDocument document, uint32 width, uint32 height) => null;

	public PictureRegion? AtlasRegion(SVGDocument document, uint32 width, uint32 height, bool mask)
	{
		Asked++;
		Width = width;
		Height = height;
		Mask = mask;
		if (Asked == 1)
			return null;
		return PictureRegion(Page, .(100.0f, 40.0f, (float)width, (float)height));
	}

	public uint64 Generation => 0;
}
