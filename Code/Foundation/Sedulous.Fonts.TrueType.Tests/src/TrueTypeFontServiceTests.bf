using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Fonts.TrueType;
using Sedulous.Image;

namespace Sedulous.Fonts.TrueType.Tests;

/// Resolving a family and a size against loaded faces.
class TrueTypeFontServiceTests
{
	/// The asset, or an empty view when this checkout has no data: the tests then skip
	/// rather than report the font code broken.
	private static bool FontPath(String outPath) => TestFont.FindPath(outPath);

	private static FontLoadOptions Options(float pixelHeight, AtlasMode mode = .Coverage)
	{
		// The default 512 square atlas: the small preset's 256 cannot hold ASCII at 24px
		// with oversampling, and a packing failure would look like a service defect.
		var options = FontLoadOptions.Default();
		options.PixelHeight = pixelHeight;
		options.AtlasMode = mode;
		return options;
	}

	[Test]
	public static void TheFirstFamilyLoadedBecomesTheDefault()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);
		Test.Assert(service.LoadFont("Second", path, Options(16.0f)) == .Success);

		let family = scope String();
		service.GetDefaultFontFamily(family);
		Test.Assert(family == "Roboto", "the first one, not the last");
		Test.Assert(service.GetFont(16.0f) == service.GetFont("Roboto", 16.0f));
	}

	/// Before anything is loaded there is nothing to hand back, and asking is not a crash.
	[Test]
	public static void AnEmptyServiceAnswersWithNothing()
	{
		let service = scope TrueTypeFontService();

		Test.Assert(service.GetFont(16.0f) == null);
		Test.Assert(service.GetFont("Roboto", 16.0f) == null);
		Test.Assert(service.GetAtlasTexture("Roboto", 16.0f) == null);

		let family = scope String();
		service.GetDefaultFontFamily(family);
		Test.Assert(family == "Default");
	}

	[Test]
	public static void AMissingFileIsRefused()
	{
		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Nothing", "no-such-font.ttf", Options(16.0f)) != .Success);
		Test.Assert(service.FontCount == 0);
	}

	/// A family is written however the caller felt like writing it.
	[Test]
	public static void TheFamilyMatchIsCaseInsensitive()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);
		Test.Assert(service.GetFont("ROBOTO", 16.0f) != null);
		Test.Assert(service.GetFont("roboto", 16.0f) == service.GetFont("Roboto", 16.0f));
	}

	/// A coverage family answers each size with its own bake, cached: drawn from one bake,
	/// every label in a game without a UI font came out at the bake's size whatever its font
	/// size. A fraction rounds to the whole pixel, and a size past the first atlas grows it.
	[Test]
	public static void ACoverageFamilyAnswersEachSizeWithItsOwnBake()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);

		let small = service.GetFont("Roboto", 16.0f);
		let large = service.GetFont("Roboto", 40.0f);
		let huge = service.GetFont("Roboto", 72.0f);
		Test.Assert((small != null) && (large != null) && (huge != null));
		Test.Assert(Math.Abs(small.Font.PixelHeight - 16.0f) < 0.01f);
		Test.Assert(Math.Abs(large.Font.PixelHeight - 40.0f) < 0.01f);
		Test.Assert(Math.Abs(huge.Font.PixelHeight - 72.0f) < 0.01f);
		Test.Assert(huge.Font.Metrics.Ascent > large.Font.Metrics.Ascent);
		Test.Assert(large.Font.Metrics.Ascent > small.Font.Metrics.Ascent);

		// Cached: the same size again is the same font, a fraction rounds to the whole pixel.
		Test.Assert(service.GetFont("Roboto", 40.0f) == large);
		Test.Assert(service.GetFont("Roboto", 40.3f) == large);
		Test.Assert(service.FontCount == 3);
		Test.Assert(service.GetAtlasTexture("Roboto", 40.0f) == service.GetAtlasTexture(large));
		// An unknown family falls back to the default family's first bake, as before.
		let fallback = service.GetFont("Nope", 24.0f);
		Test.Assert((fallback != null) && (Math.Abs(fallback.Font.PixelHeight - 16.0f) < 0.01f));
	}

	/// A family loaded from memory bakes its other sizes from the bytes the service kept.
	[Test]
	public static void AFamilyLoadedFromMemoryBakesItsOtherSizesFromTheKeptBytes()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let bytes = scope List<uint8>();
		Test.Assert(System.IO.File.ReadAll(path, bytes) case .Ok);
		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFontFromMemory("Roboto", bytes) == .Success);
		bytes.Clear(); // the service keeps its own copy
		let big = service.GetFont("Roboto", 30.0f);
		Test.Assert((big != null) && (Math.Abs(big.Font.PixelHeight - 30.0f) < 0.01f));
	}

	/// An unknown family falls to the DEFAULT face, so text still draws.
	[Test]
	public static void AnUnknownFamilyFallsToTheDefault()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);
		Test.Assert(service.GetFont("Nothing At All", 16.0f) == service.GetFont("Roboto", 16.0f));
	}

	/// The atlas comes back as an image a renderer can upload, found either by the font it
	/// belongs to or by family and size.
	[Test]
	public static void TheAtlasTextureIsReachableBothWays()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);

		let font = service.GetFont("Roboto", 16.0f);
		let texture = service.GetAtlasTexture(font);
		Test.Assert(texture != null);
		Test.Assert(texture.Width > 0 && texture.Height > 0);
		Test.Assert(texture.Format == .RGBA8, "a coverage atlas expands to four channels");
		Test.Assert(service.GetAtlasTexture("Roboto", 16.0f) == texture);
	}

	/// A font the service never handed out has no texture here.
	[Test]
	public static void AnUnknownFontHasNoTexture()
	{
		let service = scope TrueTypeFontService();
		let stranger = scope CachedFont(null, null);
		Test.Assert(service.GetAtlasTexture(stranger) == null);
	}

	/// A distance field family serves EVERY size from one bake: a size it was not baked at
	/// gets a scaled view, cached so the next request finds it exactly, and sharing the
	/// base's texture rather than baking a second one.
	[Test]
	public static void ADistanceFieldFamilySynthesizesEverySize()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let baker = new FakeDistanceFieldBaker();
		FontAtlasBakerFactory.RegisterBaker(baker);
		defer
		{
			if (FontAtlasBakerFactory.UnregisterBaker(baker))
				delete baker;
		}

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("RobotoDF", path, Options(48.0f, .DistanceField)) == .Success);

		let baked = service.GetFont("RobotoDF", 48.0f);
		Test.Assert(baked != null);
		Test.Assert(baked.Atlas.Mode == .DistanceField);

		let scaled = service.GetFont("RobotoDF", 12.0f);
		Test.Assert(scaled != null);
		Test.Assert(scaled != baked, "a view, not the bake's own tables");
		Test.Assert(scaled.Font.PixelHeight == 12.0f);
		Test.Assert(service.FontCount == 2, "the view was cached");

		Test.Assert(service.GetFont("RobotoDF", 12.0f) == scaled, "and found again exactly");
		Test.Assert(service.FontCount == 2, "without synthesizing a second one");

		// The view shares the base's texture, which is the point of one bake per family.
		Test.Assert(service.GetAtlasTexture(scaled) == service.GetAtlasTexture(baked));
	}

	/// A coverage family does NOT synthesize: its glyphs were rasterised at one size, and
	/// scaling those is exactly the blur a distance field exists to avoid. Another size is a
	/// bake of its own, with its own texture.
	[Test]
	public static void ACoverageFamilyDoesNotSynthesize()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);

		let twelve = service.GetFont("Roboto", 12.0f);
		let sixteen = service.GetFont("Roboto", 16.0f);
		Test.Assert((twelve != null) && (twelve != sixteen));
		Test.Assert(!(twelve.Font is ScaledFontView), "a bake, not a scaled view");
		Test.Assert(twelve.Font.PixelHeight == 12.0f);
		Test.Assert(service.GetAtlasTexture(twelve) != service.GetAtlasTexture(sixteen));
		Test.Assert(service.FontCount == 2);
	}

	/// The default family can be pointed at another loaded face.
	[Test]
	public static void TheDefaultFamilyCanBeMoved()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);
		Test.Assert(service.LoadFont("Second", path, Options(20.0f)) == .Success);

		service.SetDefaultFamily("Second");
		Test.Assert(service.GetFont(20.0f) == service.GetFont("Second", 20.0f));
	}

	/// Bytes already in memory load the same way a file does: the embedded fallback a
	/// relocated build falls back on.
	[Test]
	public static void AFaceLoadsFromMemory()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let bytes = scope System.Collections.List<uint8>();
		if (System.IO.File.ReadAll(path, bytes) case .Err)
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFontFromMemory("Embedded", .(bytes.Ptr, bytes.Count),
			Options(16.0f)) == .Success);
		Test.Assert(service.GetFont("Embedded", 16.0f) != null);
	}

	/// Releasing is a no op: the service owns its faces, and the next frame will ask again.
	[Test]
	public static void ReleasingKeepsTheFont()
	{
		let path = scope String();
		if (!FontPath(path))
			return;

		let service = scope TrueTypeFontService();
		Test.Assert(service.LoadFont("Roboto", path, Options(16.0f)) == .Success);

		let font = service.GetFont("Roboto", 16.0f);
		service.ReleaseFont(font);
		Test.Assert(service.GetFont("Roboto", 16.0f) == font);
	}
}
