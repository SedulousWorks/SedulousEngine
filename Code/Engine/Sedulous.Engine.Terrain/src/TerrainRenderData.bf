using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Terrain;

namespace Sedulous.Engine.Terrain;

/// One terrain, as the renderer sees it. The WHOLE terrain is a single draw list item; the
/// renderer culls and picks a level for its chunks per view.
///
/// The chunk grid and the flattened tree are a SNAPSHOT copied into the frame's arena at
/// extraction, never pointers into the manager's own storage: the snapshot is read at record
/// time, after arbitrary scene mutation, and a mid frame cache rebuild would otherwise free
/// what the recording is still walking.
class TerrainRenderData : RenderData
{
	/// The largest level threshold table a terrain carries inline.
	public const int cMaxLodThresholds = 8;

	public TerrainChunk* Chunks = null;
	public TerrainQuadtreeNode* Nodes = null;
	public uint32 ChunkCount = 0;
	public uint32 NodeCount = 0;

	/// The HOLED chunks' own index buffers, an arena copy with one record per chunk that has
	/// holes, in chunk order.
	///
	/// The renderer draws these for a chunk whose holes flag is set and skips an entirely cut
	/// chunk outright; every other chunk draws the shared grid.
	public HoledChunkMesh* HoledMeshes = null;
	public uint32 HoledMeshCount = 0;

	/// The R8 hole MASK, null for a grid with no holes: the HOLES pixel shaders sample it
	/// bilinearly to shape a holed chunk's rim.
	public ITextureView HoleView = null;

	/// The height texture, fetched exactly rather than filtered.
	public ITextureView HeightView = null;

	// ---- placement, and how a sample becomes a world height ----

	public Float4x4 ChunkToWorld = Float4x4.Identity();
	/// The heightfield's side, the texture being square at this size.
	public int32 GridSize = 0;
	public Float2 WorldSizeXZ = .(0.0f, 0.0f);
	/// The world height at the lowest sample.
	public float MinY = 0.0f;
	/// And at the highest.
	public float MaxY = 0.0f;

	/// DESCENDING coverage thresholds. The first is one by convention, and level nought is the
	/// fallback.
	public float[cMaxLodThresholds] Thresholds = .(1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
	public uint32 ThresholdCount = 1;
	/// Negative holds detail longer, positive drops it sooner.
	public float LodBias = 0.0f;

	// ---- the splat material ----

	/// The blend weights.
	public ITextureView WeightView = null;
	/// The layer indices, read EXACTLY: filtering these would interpolate one layer id into
	/// another and produce a layer nobody painted.
	public ITextureView IndexView = null;

	/// The BASE layer, which shows wherever the painted weights do not sum to one. A null map
	/// binds a stand in rather than branching in the shader.
	public ITextureView BaseAlbedoView = null;
	public ITextureView BaseNormalView = null;
	public ITextureView BaseOrmView = null;
	public ITextureView BaseHeightView = null;
	public float BaseTileScale = 1.0f;

	/// The paint palette: one array slice per layer, cook resized to a common size, with the
	/// per layer tile scales beside it.
	public ITextureView PaletteArrayView = null;
	public ITextureView NormalArrayView = null;
	public ITextureView OrmArrayView = null;
	public ITextureView HeightArrayView = null;
	public ITextureView MaskArrayView = null;
	public IBuffer TileScaleBuffer = null;
	/// Part of the renderer's bind group key, so a rebuilt palette is noticed. Never an
	/// address.
	public uint64 TileScaleGeneration = 0;
	public uint32 PaletteCount = 0;

	/// The soft skirt a height blend fades over. The renderer only sends it when a height map
	/// is actually present; otherwise the plain linear blend runs.
	public float HeightBlendContrast = 0.25f;
}
