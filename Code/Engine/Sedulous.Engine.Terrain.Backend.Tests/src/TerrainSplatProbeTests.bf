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
	/// The coverage mask patterns the split case renders.
	private enum MaskPattern { Off, SplitLeft, SplitRight, Cut }

	/// MakeFlat's world size, so ONE mask repeat spans the whole footprint and the pattern
	/// lands on screen as itself rather than as a tiling.
	private const float cFlatWorldSize = 130.0f;

	private static TerrainProbe RenderMasked(TerrainProbeFixture fixture, MaskPattern pattern)
	{
		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let owned = scope ProbeTextures();
		let weights = TerrainSplatFixtures.MakeStripeWeights(1); // layer 0 one hot everywhere
		defer delete weights;

		let blue = scope Float3[](.(0.05f, 0.05f, 0.9f));
		let palette = TerrainSplatFixtures.MakePaletteData(blue);
		defer delete palette;

		if (pattern != .Off)
		{
			let side = palette.SliceSize;
			palette.MaskTexels.Resize(TerrainPaletteData.SliceBytes(side, palette.MipCount));
			for (uint32 y = 0; y < side; y++)
			{
				for (uint32 x = 0; x < side; x++)
				{
					uint8 value = 255;
					switch (pattern)
					{
					case .SplitLeft: value = (x < side / 2) ? 255 : 0;
					case .SplitRight: value = (x < side / 2) ? 0 : 255;
					case .Cut: value = 0;
					case .Off:
					}

					let at = (int)(y * side + x) * 4;
					palette.MaskTexels[at + 0] = value;
					palette.MaskTexels[at + 1] = value;
					palette.MaskTexels[at + 2] = value;
					palette.MaskTexels[at + 3] = 255;
				}
			}
		}

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		let scales = scope float[](cFlatWorldSize);
		let views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);
		if (pattern != .Off)
			Test.Assert(gpu.MaskArrayView != null, "a masked palette builds the mask array");

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		config.BaseAlbedoView = TerrainSplatFixtures.MakeSolid(owned, fixture.Device, 230, 30, 30);
		config.PaletteArrayView = gpu.ArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		config.PaletteCount = 1;
		config.MaskArrayView = (pattern != .Off) ? gpu.MaskArrayView : null;

		return TerrainProbeRenderer.Render(fixture, config);
	}

	/// A coverage mask cuts the painted layer away and the BASE shows through the hole.
	[Test]
	public static void ACoverageMaskCutsALayerToRevealTheBase()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let off = RenderMasked(fixture, .Off);
		defer delete off;
		if (!off.Valid)
			return;

		let cut = RenderMasked(fixture, .Cut);
		defer delete cut;
		let splitLeft = RenderMasked(fixture, .SplitLeft);
		defer delete splitLeft;
		let splitRight = RenderMasked(fixture, .SplitRight);
		defer delete splitRight;

		Test.Assert((off.LeftB + off.RightB) > (off.LeftR + off.RightR) * 1.5,
			"with no mask the layer covers everything");
		Test.Assert((cut.LeftR + cut.RightR) > (cut.LeftB + cut.RightB) * 1.5,
			"an all zero mask falls through to the base");

		// A real SPATIAL split: one screen half reads as the layer and the other as the base.
		let leftIsLayer = splitLeft.LeftB > splitLeft.LeftR;
		let rightIsLayer = splitLeft.RightB > splitLeft.RightR;
		Test.Assert(leftIsLayer != rightIsLayer, "the mask splits the footprint on screen");

		// And inverting the mask swaps which half it is.
		Test.Assert((splitRight.LeftB > splitRight.LeftR) != leftIsLayer,
			"flipping the mask flips the halves");
	}
	/// Both halves of the screen summed, which is how the whole footprint's colour reads.
	private static double Red(TerrainProbe probe) => probe.LeftR + probe.RightR;
	private static double Blue(TerrainProbe probe) => probe.LeftB + probe.RightB;

	/// Two layers painted over each other with constant per layer height slices.
	private static TerrainProbe RenderHeightBlend(TerrainProbeFixture fixture, uint8 h0, uint8 h1,
		uint8 w0, uint8 w1, bool bindHeight, float contrast)
	{
		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let weights = TerrainSplatFixtures.MakeTwoLayerWeights(w0, w1);
		defer delete weights;

		let colors = scope Float3[](.(0.9f, 0.05f, 0.05f), .(0.05f, 0.05f, 0.9f));
		let palette = TerrainSplatFixtures.MakePaletteData(colors);
		defer delete palette;

		// One CONSTANT height per layer, so the only thing that can break the tie is the
		// height term itself.
		let heights = scope Float3[](
			.((float)h0 / 255.0f, (float)h0 / 255.0f, (float)h0 / 255.0f),
			.((float)h1 / 255.0f, (float)h1 / 255.0f, (float)h1 / 255.0f));
		TerrainSplatFixtures.FillSliceArray(palette.HeightTexels, heights, palette);

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		let scales = scope float[](1000.0f, 1000.0f);
		let views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);
		if (bindHeight)
			Test.Assert(gpu.HeightArrayView != null, "a palette with heights builds the array");

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		config.PaletteArrayView = gpu.ArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		config.PaletteCount = 2;
		config.HeightArrayView = bindHeight ? gpu.HeightArrayView : null;
		config.HeightBlendContrast = contrast;

		return TerrainProbeRenderer.Render(fixture, config);
	}

	/// Height blending breaks a fifty fifty tie toward the TALLER layer, and the weight still
	/// counts when the heights are equal.
	///
	/// The equal height half is the one that catches a score that dropped its weight term: the
	/// crossover has to sit at the weight tie, not below it.
	[Test]
	public static void HeightBlendBiasesTheTieTowardTheTallerLayer()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let redTall = RenderHeightBlend(fixture, 255, 0, 128, 128, true, 0.15f);
		defer delete redTall;
		if (!redTall.Valid)
			return;

		let blueTall = RenderHeightBlend(fixture, 0, 255, 128, 128, true, 0.15f);
		defer delete blueTall;
		let linear = RenderHeightBlend(fixture, 255, 0, 128, 128, false, 0.15f);
		defer delete linear;
		let weightWins = RenderHeightBlend(fixture, 128, 128, 180, 60, true, 0.15f);
		defer delete weightWins;

		Test.Assert(Red(redTall) > Blue(redTall) * 1.5, "the taller layer takes the tie");
		Test.Assert(Blue(blueTall) > Red(blueTall) * 1.5, "and swapping it flips the winner");

		// The control anchors it: the SAME weights with no height array bound stay an even mix,
		// so binding the array is what tipped the result.
		Test.Assert(Math.Abs(Red(linear) - Blue(linear)) < Red(linear) * 0.15,
			"unbound heights leave the linear fifty fifty");
		Test.Assert(Red(redTall) > Red(linear) * 1.2, "and binding them is what pushed red up");

		Test.Assert(Red(weightWins) > Blue(weightWins) * 1.5,
			"with equal heights the greater weight still wins");
	}
	private static double Green(TerrainProbe probe) => probe.LeftG + probe.RightG;

	/// Two painted layers over a distinct base, with the upper one optionally masked away.
	private static TerrainProbe RenderTwoPainted(TerrainProbeFixture fixture, bool maskUpper)
	{
		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let owned = scope ProbeTextures();
		let weights = TerrainSplatFixtures.MakeTwoLayerWeights(128, 128); // about half each
		defer delete weights;

		let colors = scope Float3[](
			.(0.9f, 0.05f, 0.05f),  // layer 0, the GROUND
			.(0.05f, 0.9f, 0.05f)); // layer 1, the GRASS
		let palette = TerrainSplatFixtures.MakePaletteData(colors);
		defer delete palette;

		if (maskUpper)
		{
			// The ground opaque, the grass cut away entirely.
			let masks = scope Float3[](.(1.0f, 1.0f, 1.0f), .(0.0f, 0.0f, 0.0f));
			TerrainSplatFixtures.FillSliceArray(palette.MaskTexels, masks, palette);
		}

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		let scales = scope float[](1000.0f, 1000.0f);
		let views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		// The base is a colour neither layer uses, so it is obvious if it wins.
		config.BaseAlbedoView = TerrainSplatFixtures.MakeSolid(owned, fixture.Device, 30, 30, 230);
		config.PaletteArrayView = gpu.ArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		config.PaletteCount = 2;
		config.MaskArrayView = maskUpper ? gpu.MaskArrayView : null;

		return TerrainProbeRenderer.Render(fixture, config);
	}

	/// Coverage freed by a mask goes to the layer PAINTED beneath, not down to the base.
	///
	/// Reveal what you painted: dumping the freed share to the base canvas instead is the
	/// behaviour this pins against coming back.
	[Test]
	public static void AMaskedLayerRevealsTheOnePaintedBeneathIt()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let masked = RenderTwoPainted(fixture, true);
		defer delete masked;
		if (!masked.Valid)
			return;

		let unmasked = RenderTwoPainted(fixture, false);
		defer delete unmasked;

		Test.Assert(Red(masked) > Blue(masked) * 1.5,
			"the freed coverage went to the painted ground, not the base");

		// The unmasked run is the baseline that makes the claim a redistribution rather than
		// just the observation that red exists at all.
		Test.Assert(Green(unmasked) > Blue(unmasked), "the grass was visible before masking");
		Test.Assert(Red(masked) > Red(unmasked) * 1.3, "masking the grass grew the ground");
		Test.Assert(Green(masked) < Green(unmasked) * 0.3, "and actually removed the grass");
	}
	/// One hot palette layer carrying its own ARRAY normal and ORM slices.
	private static TerrainProbe RenderArrayPbr(TerrainProbeFixture fixture, Float3 toLight,
		uint8 ao, Float4x4 chunkToWorld)
	{
		let grid = TerrainFixtures.MakeFlat();
		defer delete grid;

		let weights = TerrainSplatFixtures.MakeStripeWeights(1);
		defer delete weights;

		let gray = scope Float3[](.(0.66f, 0.66f, 0.66f));
		let palette = TerrainSplatFixtures.MakePaletteData(gray);
		defer delete palette;

		// Tangent space (0.6, 0, 0.8), which tilts the shading normal toward the map's U axis
		// and so toward LOCAL +X, wherever the chunk frame puts that.
		let normals = scope Float3[](.(204.0f / 255.0f, 128.0f / 255.0f, 229.0f / 255.0f));
		TerrainSplatFixtures.FillSliceArray(palette.NormalTexels, normals, palette);

		// R = ambient occlusion, G = roughness, B = metalness.
		let orm = scope Float3[](.((float)ao / 255.0f, 1.0f, 0.0f));
		TerrainSplatFixtures.FillSliceArray(palette.OrmTexels, orm, palette);

		let splatCache = scope TerrainSplatTextureCache();
		let paletteCache = scope TerrainPaletteTextureCache();
		defer { splatCache.Clear(fixture.Device); paletteCache.Clear(fixture.Device); }

		let scales = scope float[](1000.0f);
		let views = splatCache.GetOrCreate(fixture.Device, weights, weights.Version);
		let gpu = paletteCache.GetOrCreate(fixture.Device, palette, scales);
		Test.Assert(gpu.NormalArrayView != null, "the normal array was built");
		Test.Assert(gpu.OrmArrayView != null, "and the ORM array");

		let config = scope TerrainProbeConfig();
		config.Terrain = grid;
		config.ToLight = toLight;
		config.ChunkToWorld = chunkToWorld;
		config.WeightView = views.WeightView;
		config.IndexView = views.IndexView;
		config.PaletteArrayView = gpu.ArrayView;
		config.NormalArrayView = gpu.NormalArrayView;
		config.OrmArrayView = gpu.OrmArrayView;
		config.TileScaleBuffer = gpu.TileScaleBuffer;
		config.TileScaleGeneration = gpu.Generation;
		config.PaletteCount = 1;

		return TerrainProbeRenderer.Render(fixture, config);
	}

	/// The per LAYER array PBR path, which the base map probes never touch, and the pin that
	/// its perturbation follows the CHUNK frame rather than a world axis.
	///
	/// Rotating the terrain a quarter turn has to move the asymmetry from world X onto world
	/// Z. A frame built on world axes instead would leave it on X and shear the result.
	[Test]
	public static void TheArrayNormalAndOrmBlendThroughTopK()
	{
		let fixture = scope TerrainProbeFixture();
		if (!fixture.Ready)
			return;

		let plusX = Normalized(Float3(0.85f, 0.5f, 0.0f));
		let minusX = Normalized(Float3(-0.85f, 0.5f, 0.0f));
		let plusZ = Normalized(Float3(0.0f, 0.5f, 0.85f));
		let minusZ = Normalized(Float3(0.0f, 0.5f, -0.85f));

		let alignedSun = RenderArrayPbr(fixture, plusX, 255, Float4x4.Identity());
		defer delete alignedSun;
		if (!alignedSun.Valid)
			return;

		let opposedSun = RenderArrayPbr(fixture, minusX, 255, Float4x4.Identity());
		defer delete opposedSun;
		let noAmbient = RenderArrayPbr(fixture, plusX, 0, Float4x4.Identity());
		defer delete noAmbient;

		Test.Assert(alignedSun.Total > opposedSun.Total * 1.10,
			"the array normal makes flat ground directional");
		Test.Assert(noAmbient.Total < alignedSun.Total * 0.95,
			"and an occlusion of nought kills the ambient term");

		// A quarter turn about Y: the tilt rides the chunk frame round with it.
		let rotated = Float4x4.RotationY(Math.PI_f * 0.5f);
		let rotatedPlusX = RenderArrayPbr(fixture, plusX, 255, rotated);
		defer delete rotatedPlusX;
		let rotatedMinusX = RenderArrayPbr(fixture, minusX, 255, rotated);
		defer delete rotatedMinusX;
		let rotatedPlusZ = RenderArrayPbr(fixture, plusZ, 255, rotated);
		defer delete rotatedPlusZ;
		let rotatedMinusZ = RenderArrayPbr(fixture, minusZ, 255, rotated);
		defer delete rotatedMinusZ;

		Test.Assert(Math.Abs(rotatedPlusX.Total - rotatedMinusX.Total) < rotatedPlusX.Total * 0.05,
			"the asymmetry left world X");
		// Magnitude rather than sign, so which way round it landed does not matter.
		Test.Assert(Math.Abs(rotatedPlusZ.Total - rotatedMinusZ.Total) > rotatedPlusZ.Total * 0.10,
			"and moved onto world Z");
	}
}
