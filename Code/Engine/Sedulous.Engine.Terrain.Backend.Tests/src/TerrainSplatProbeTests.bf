using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Terrain;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// The splat material at the pixel level: what the top-K blend actually puts on screen.
///
/// Every case here paints a raster, binds it through the PRODUCTION caches, renders one frame
/// on a real device and reads the colours back. The band readout is the middle half of each
/// vertical sixth, clear of the boundaries where stripes blend.
///
/// Raptor runs each of these against Vulkan and WebGPU and cross-checks the two. There is no
/// WebGPU backend here, so the Vulkan half is the whole of it; the parity case that exists
/// only to compare them is left in the ledger.
class TerrainSplatProbeTests
{
	private const int cBands = TerrainProbe.Bands;

	/// Six distinguishable colours, one per palette layer: R, G, B and their pairs, so a band
	/// can be classified by WHICH channels are lit rather than by an exact value.
	private static Float3[cBands] sBandColors = .(
		.(0.86f, 0.12f, 0.12f), // red
		.(0.12f, 0.86f, 0.12f), // green
		.(0.12f, 0.12f, 0.86f), // blue
		.(0.86f, 0.86f, 0.12f), // yellow
		.(0.12f, 0.86f, 0.86f), // cyan
		.(0.86f, 0.12f, 0.86f)); // magenta

	/// Which channels are lit in a band, as a bit per channel, against that band's own
	/// maximum. Comparing shares rather than absolutes keeps this clear of exposure.
	private static uint32 BandClass(TerrainProbe probe, int band)
	{
		let max = Math.Max(probe.BandR[band], Math.Max(probe.BandG[band], probe.BandB[band]));
		uint32 bits = 0;
		if (probe.BandR[band] > 0.6 * max) bits |= 1;
		if (probe.BandG[band] > 0.6 * max) bits |= 2;
		if (probe.BandB[band] > 0.6 * max) bits |= 4;
		return bits;
	}

	/// SIX distinct palette layers on one terrain, which the retired four layer model could
	/// not represent at all.
	[Test]
	public static void SixPaletteLayersRenderAsDistinctStripes()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let weights = TerrainSplatFixtures.MakeStripeWeights(cBands);
		defer delete weights;
		let palette = TerrainSplatFixtures.MakePaletteData(sBandColors);
		defer delete palette;

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		// A tile scale large enough that one tile covers the stripe, so each band reads as
		// its layer's flat colour rather than as a repeat pattern.
		let scales = scope float[cBands];
		for (int i < cBands)
			scales[i] = 1000.0f;

		let views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);
		Test.Assert(views.WeightView != null, "the splat pair resolved");
		Test.Assert(gpu.ArrayView != null, "and the palette array");

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		config.PaletteArrayView = gpu.ArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		config.PaletteCount = cBands;

		let probe = TerrainProbeRenderer.Render(fixture, config);
		defer delete probe;
		Test.Assert(probe.Valid, "the stripes rendered");

		// FLIP AGNOSTIC: the probe's x may run either way round depending on the projection,
		// so the palette order is accepted forwards or mirrored, never neither.
		let expected = scope uint32[cBands](1, 2, 4, 3, 6, 5); // R, G, B, R+G, G+B, R+B
		var forward = true;
		var mirrored = true;
		for (int b < cBands)
		{
			forward = forward && (BandClass(probe, b) == expected[b]);
			mirrored = mirrored && (BandClass(probe, b) == expected[cBands - 1 - b]);
		}

		Test.Assert(forward || mirrored,
			scope $"all six layers appear in palette order (got {BandClass(probe, 0)}, {BandClass(probe, 1)}, {BandClass(probe, 2)}, {BandClass(probe, 3)}, {BandClass(probe, 4)}, {BandClass(probe, 5)})");
	}
	/// The editor's paint loop end to end: a CPU raster, the version keyed cache, the blend.
	///
	/// All zero weights over a red base render red; painting palette layer nought blue and
	/// bumping the version makes the cache re upload, and the SAME terrain renders blue. That
	/// the colour changed at all is what proves the paint reached the GPU.
	[Test]
	public static void PaintingTheWeightsReUploadsAndChangesThePixel()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let owned = scope ProbeTextures();
		let weights = scope SplatWeights(8, 8); // all zero, so the base owns every texel
		let blue = scope Float3[](.(0.12f, 0.12f, 0.86f));
		let palette = TerrainSplatFixtures.MakePaletteData(blue);
		defer delete palette;

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		let scales = scope float[](1000.0f);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);
		Test.Assert(gpu.ArrayView != null);

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.BaseAlbedoView = TerrainSplatFixtures.MakeSolid(owned, fixture.Device, 220, 30, 30);
		config.BaseTileScale = 1000.0f;
		config.PaletteArrayView = gpu.ArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		config.PaletteCount = 1;

		var views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		let before = TerrainProbeRenderer.Render(fixture, config);
		defer delete before;

		// Several dabs, so the brush converges on one hot rather than leaving a partial blend.
		for (int i < 24)
			SplatBrush.Paint(weights, 0.5f, 0.5f, 2.0f, 2.0f, 0, 1.0f);

		views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		let after = TerrainProbeRenderer.Render(fixture, config);
		defer delete after;

		Test.Assert(before.Valid && after.Valid, "both frames rendered");

		Test.Assert(before.LeftR > before.LeftB * 1.5, "unpainted reads as the red base");
		Test.Assert(before.RightR > before.RightB * 1.5);
		Test.Assert(after.LeftB > after.LeftR * 1.5, "and painted reads as the blue layer");
		Test.Assert(after.RightB > after.RightR * 1.5);
	}

	/// Paint layers bound with NOTHING painted and no base albedo keeps the fresh terrain
	/// look: the height and slope ramp, not the white stand in.
	///
	/// Adding a palette layer must not flip an unpainted terrain to white, which is what
	/// binding the dummy as though it were a base would do.
	[Test]
	public static void WithNoBaseAlbedoTheRampIsTheImplicitBase()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let weights = scope SplatWeights(16, 16); // nothing painted
		let blue = scope Float3[](.(0.12f, 0.12f, 0.86f));
		let palette = TerrainSplatFixtures.MakePaletteData(blue);
		defer delete palette;

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		let scales = scope float[](1000.0f);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);
		let views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		config.PaletteArrayView = gpu.ArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		// Weights present and a base ABSENT, which is the arrangement that used to confuse it.
		config.PaletteCount = 1;

		let probe = TerrainProbeRenderer.Render(fixture, config);
		defer delete probe;
		Test.Assert(probe.Valid);

		let half = (double)TerrainProbeRenderer.Size * TerrainProbeRenderer.Size / 2.0;
		Test.Assert(probe.LeftR / half < 150.0, "not the white stand in, which reads saturated");
		Test.Assert(probe.LeftR > probe.LeftB, "the ramp is warm green at a low height");
		Test.Assert(probe.Filled > 30000, "and the terrain still rendered");
	}
	/// One flat frame with an optional base normal map, for the two orientation cases.
	private static TerrainProbe RenderWithBaseNormal(TerrainProbeFixture fixture, Float3 toLight,
		bool withNormal, uint8 nr, uint8 ng, uint8 nb)
	{
		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let owned = scope ProbeTextures();
		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.ToLight = toLight;
		config.BaseAlbedoView = TerrainSplatFixtures.MakeSolid(owned, fixture.Device, 170, 170, 170);
		config.BaseTileScale = 1000.0f;
		if (withNormal)
			config.BaseNormalView = TerrainSplatFixtures.MakeSolid(owned, fixture.Device, nr, ng, nb);

		return TerrainProbeRenderer.Render(fixture, config);
	}

	/// Flat ground has ONE geometric normal, so a sun from either side shades it the same. A
	/// base normal map leaning toward +X has to make it directional: brighter under a sun from
	/// +X than the flat control, darker under one from -X.
	[Test]
	public static void ABaseNormalMapPerturbsTheFlatGroundShading()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let plusX = Normalized(Float3(0.85f, 0.5f, 0.0f));
		let minusX = Normalized(Float3(-0.85f, 0.5f, 0.0f));

		// Tangent space (0.6, 0, 0.8) encoded as n * 0.5 + 0.5, which leans the world normal
		// toward +X under the flat frame.
		let mappedPlus = RenderWithBaseNormal(fixture, plusX, true, 204, 128, 229);
		defer delete mappedPlus;
		if (!mappedPlus.Valid)
			return;

		let mappedMinus = RenderWithBaseNormal(fixture, minusX, true, 204, 128, 229);
		defer delete mappedMinus;
		let flatPlus = RenderWithBaseNormal(fixture, plusX, false, 0, 0, 0);
		defer delete flatPlus;
		let flatMinus = RenderWithBaseNormal(fixture, minusX, false, 0, 0, 0);
		defer delete flatMinus;

		// The control first: without the map the two suns shade one normal about equally.
		Test.Assert(Math.Abs(flatPlus.Total - flatMinus.Total) < flatPlus.Total * 0.06,
			"the flat control is not directional");

		Test.Assert(mappedPlus.Total > flatPlus.Total * 1.10, "the aligned sun brightens it");
		Test.Assert(mappedMinus.Total < flatMinus.Total * 0.90, "and the opposed sun darkens it");
	}

	/// The tangent frame's bitangent points toward -Z, which under a top left UV origin IS
	/// glTF and GL green up: a `_nor_gl_` map imports as authored.
	///
	/// A normal leaning toward +green must brighten under a sun from -Z. If this ever fails,
	/// the sign belongs in the SHADER: never ask an author to flip their maps.
	[Test]
	public static void APlusGreenBaseNormalLeansTowardMinusZ()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let plusZ = Normalized(Float3(0.0f, 0.5f, 0.85f));
		let minusZ = Normalized(Float3(0.0f, 0.5f, -0.85f));

		// Tangent space (0, +0.6, +0.8).
		let leanMinus = RenderWithBaseNormal(fixture, minusZ, true, 128, 204, 229);
		defer delete leanMinus;
		if (!leanMinus.Valid)
			return;

		let leanPlus = RenderWithBaseNormal(fixture, plusZ, true, 128, 204, 229);
		defer delete leanPlus;
		let flatMinus = RenderWithBaseNormal(fixture, minusZ, false, 0, 0, 0);
		defer delete flatMinus;
		let flatPlus = RenderWithBaseNormal(fixture, plusZ, false, 0, 0, 0);
		defer delete flatPlus;

		Test.Assert(Math.Abs(flatMinus.Total - flatPlus.Total) < flatMinus.Total * 0.06,
			"the flat control is not directional");

		Test.Assert(leanMinus.Total > flatMinus.Total * 1.10, "green leans toward minus Z");
		Test.Assert(leanPlus.Total < flatPlus.Total * 0.90, "and away from plus Z");
	}
}
