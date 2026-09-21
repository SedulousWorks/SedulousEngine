using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Terrain.Resource;

/// The cooked terrain: the resources it REFERENCES, by identity, plus the per layer tiling.
/// Nothing here is bulk.
///
/// The top four model is a BASE layer, an unbounded paint palette, and the weights that blend
/// them. The base is what shows wherever the painted weights do not sum to one; it is not
/// part of the palette and is never painted directly. An unset map identity is that feature's
/// off path rather than an error.
/// Version five: the base and palette maps, the height blend and the coverage masks each
/// added fields, and a payload from before any of them is refused rather than read as
/// though those fields were there.
[Serializable(5)]
class TerrainSource
{
	/// The shared grid, which the physics collider and the navigation bake resolve too.
	public Guid HeightfieldId = .Empty;
	/// The splat weights. Unset means pure base.
	public Guid WeightsId = .Empty;

	public Guid BaseAlbedoId = .Empty;
	public Guid BaseNormalId = .Empty;
	public Guid BaseOrmId = .Empty;
	public Guid BaseHeightId = .Empty;
	public float BaseTileScale = 1.0f;

	/// The paint layers, unbounded, parallel with the tile scales below.
	public List<Guid> PaletteAlbedoIds = new .() ~ delete _;
	public List<Guid> PaletteNormalIds = new .() ~ delete _;
	public List<Guid> PaletteOrmIds = new .() ~ delete _;
	public List<Guid> PaletteHeightIds = new .() ~ delete _;
	public List<Guid> PaletteMaskIds = new .() ~ delete _;
	public List<float> PaletteTileScales = new .() ~ delete _;

	/// The height blend's soft skirt width, consulted only where height maps are present.
	/// Small interlocks sharply, large washes toward an equal mix.
	public float HeightBlendContrast = 0.25f;

	public bool CastShadows = true;
}
