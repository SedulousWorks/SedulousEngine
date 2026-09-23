using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.RHI;

namespace Sedulous.Engine.Terrain.Backend.Tests;

/// One probe's scene: the grid, the camera, and whichever parts of the splat material the
/// case under test actually binds. Everything left null is absent, which the renderer fills
/// with its stand ins.
class TerrainProbeConfig
{
	public Heightfield Terrain = null;

	public Float3 Eye = .(0, 120, 0.001f);
	public Float3 Target = .(0, 0, 0);
	public Float3 Up = .(0, 0, 1);
	public float Fov = 1.0f;
	public ClearColor Clear = ClearColor.Black;
	public bool Skirts = true;
	/// Binds the R8 hole mask a cut grid carries. False leaves the geometry rule alone, which
	/// is what the rim the pixel shader discards is measured against.
	public bool HoleMask = true;
	/// Stands a cascaded shadow system up for the frame, so the terrain both casts into the
	/// cascade and samples it.
	public bool Shadows = false;

	/// The direction TO the light. Null leaves the renderer's fallback sun.
	public Float3? ToLight = null;

	/// Overrides the level thresholds. Empty keeps the default set.
	public float[] Thresholds = null;

	// ---- the top layer splat material; all absent means the height lit fallback ----

	public ITextureView WeightView = null;
	public ITextureView IndexView = null;
	public ITextureView BaseAlbedoView = null;
	public ITextureView BaseNormalView = null;
	public ITextureView BaseOrmView = null;
	public float BaseTileScale = 1.0f;

	public ITextureView PaletteArrayView = null;
	public ITextureView NormalArrayView = null;
	public ITextureView OrmArrayView = null;
	public ITextureView HeightArrayView = null;
	public ITextureView MaskArrayView = null;
	/// Only sent when a height map is actually bound.
	public float HeightBlendContrast = 0.25f;

	/// The tangent frame follows THIS.
	public Float4x4 ChunkToWorld = Float4x4.Identity();
	public IBuffer TileScaleBuffer = null;
	public uint64 TileScaleGeneration = 0;
	public uint32 PaletteCount = 0;
}
