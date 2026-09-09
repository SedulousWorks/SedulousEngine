using System;
using System.Collections;
using Sedulous.Heightfield;
using Sedulous.Resource;

namespace Sedulous.Terrain.Resource;

/// The runtime terrain: the resolved references the renderer draws with.
///
/// The heightfield drives the geometry, through the chunk model, and the shared collision:
/// the physics and the navigation bake resolve the SAME grid rather than a copy of it.
class TerrainResource
{
	public Ref<Heightfield> Heightfield = default;
	/// The paint rasters. Unset means pure base.
	public Ref<SplatWeights> Weights = default;

	/// What shows wherever the paint does not sum to one. Never painted.
	public TerrainLayer Base = .();
	/// The paint layers, unbounded, though an eight bit index reaches 256 of them.
	public List<TerrainLayer> Palette = new .() ~ delete _;

	/// The cook built palette array, which the renderer uploads as a texture array. Null for
	/// a terrain with no palette, or one built in memory that assigns it directly.
	public TerrainPaletteData PaletteData = null ~ delete _;

	/// Copied from the source; the renderer feeds it to the shader only where height maps are
	/// present.
	public float HeightBlendContrast = 0.25f;
	public bool CastShadows = true;

	public uint32 PaletteCount => (uint32)Palette.Count;
}
