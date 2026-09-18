using Sedulous.Core;
using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Terrain.Pipeline;

/// A terrain: the heightfield and splat weights it uses, the BASE layer, the paint palette, and
/// how it all tiles.
///
/// Everything is referenced by IDENTITY, and an asset's identity equals its cooked product's,
/// so the same reference works on both sides. Terrain has no source file of its own, which is
/// why the file name a plain asset carries goes unused.
[Category("Terrain")]
[DisplayName("Terrain")]
[Serializable]
class TerrainAsset : Asset
{
	/// Shared with physics and navigation, which read the same grid.
	public Guid HeightfieldId = .Empty;
	/// The top weights. Empty means a pure base terrain.
	public Guid WeightsId = .Empty;

	/// The base layer's maps. Each empty one falls back to a neutral default rather than
	/// failing: a terrain with only an albedo is a perfectly ordinary terrain.
	public Guid BaseAlbedoId = .Empty;
	public Guid BaseNormalId = .Empty;
	public Guid BaseOrmId = .Empty;
	public Guid BaseHeightId = .Empty;
	public float BaseTileScale = 1.0f;

	/// The paint layers, unbounded, and parallel to one another and to the tile scales.
	public List<Guid> PaletteAlbedoIds = new .() ~ delete _;
	public List<Guid> PaletteNormalIds = new .() ~ delete _;
	public List<Guid> PaletteOrmIds = new .() ~ delete _;
	public List<Guid> PaletteHeightIds = new .() ~ delete _;
	public List<Guid> PaletteMaskIds = new .() ~ delete _;
	public List<float> PaletteTileScales = new .() ~ delete _;

	/// The common slice size every palette layer is resized onto.
	public int32 PaletteTextureSize = 1024;

	/// How soft the skirt is where two layers compete by height.
	public float HeightBlendContrast = 0.25f;

	[DisplayName("Cast Shadows")]
	public bool CastShadows = true;
}
