namespace Sedulous.Renderer.Shadows;

using System;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;

/// A region within the shadow atlas. Coordinates are in pixels.
public struct ShadowAtlasRegion
{
	public uint32 X;
	public uint32 Y;
	public uint32 Width;
	public uint32 Height;

	/// UV rect within the atlas (0..1), used by the fragment shader to sample.
	public Vector4 UVRect;
}

/// Manages a single depth texture used as a packed shadow map atlas.
///
/// Phase 7.1 implementation: fixed-size square cells in a regular grid.
/// 2048×2048 atlas, 512×512 cells, 4×4 = 16 cells.
/// Allocator is a simple bitset — one bit per cell.
///
/// Phase 7.5 will replace this with a hierarchical allocator supporting mixed
/// cell sizes (1024 for nearest cascades, 256 for distant spots, etc.).
public class ShadowAtlas
{
	/// Atlas dimensions (square, power of two).
	public uint32 Size { get; private set; }
	/// Cell side length (square cells).
	public uint32 CellSize { get; private set; }
	/// Number of cells per side.
	public uint32 CellsPerSide { get; private set; }
	/// Total cell count.
	public uint32 CellCount { get; private set; }

	private IDevice mDevice;
	private ITexture mTexture ~ if (mDevice != null) mDevice.DestroyTexture(ref _);
	private ITextureView mTextureView ~ if (mDevice != null) mDevice.DestroyTextureView(ref _);
	private TextureFormat mFormat = .Depth32Float;

	// Per-cell allocation bitset. Bit set = cell is in use this frame.
	private uint64 mCellsUsed;

	public ITexture Texture => mTexture;
	public ITextureView TextureView => mTextureView;
	public TextureFormat Format => mFormat;

	/// Initializes the atlas with the given size and cell size.
	/// Defaults: 2048 atlas, 512 cells (16 cells, 4 directional lights worth of cascades).
	public Result<void> Initialize(IDevice device, uint32 size = 2048, uint32 cellSize = 512)
	{
		mDevice = device;
		Size = size;
		CellSize = cellSize;
		CellsPerSide = size / cellSize;
		CellCount = CellsPerSide * CellsPerSide;

		Runtime.Assert(CellCount <= 64, "ShadowAtlas: cell count exceeds bitset capacity (64)");
		Runtime.Assert(size % cellSize == 0, "ShadowAtlas: size must be a multiple of cellSize");

		TextureDesc desc = .()
		{
			Label = "Shadow Atlas",
			Width = size,
			Height = size,
			Depth = 1,
			Format = mFormat,
			Usage = .DepthStencil | .Sampled,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};

		if (device.CreateTexture(desc) case .Ok(let tex))
			mTexture = tex;
		else
			return .Err;

		TextureViewDesc viewDesc = .()
		{
			Label = "Shadow Atlas View",
			Format = mFormat,
			Dimension = .Texture2D
		};

		if (device.CreateTextureView(mTexture, viewDesc) case .Ok(let view))
			mTextureView = view;
		else
			return .Err;

		return .Ok;
	}

	/// Releases all cell allocations. Called once per frame before allocating shadows.
	public void Reset()
	{
		mCellsUsed = 0;
	}

	/// Allocates a single cell. Returns the region in pixels + UV rect, or .Err if full.
	public Result<ShadowAtlasRegion> AllocateCell()
	{
		// Find first free cell
		for (uint32 i = 0; i < CellCount; i++)
		{
			let mask = (uint64)1 << i;
			if ((mCellsUsed & mask) == 0)
			{
				mCellsUsed |= mask;
				return .Ok(MakeRegion(i));
			}
		}
		return .Err;
	}

	/// Allocates `count` consecutive cells (used for cascaded shadow maps — 4 cells
	/// per directional light). Returns the first region; subsequent cells follow in
	/// linear cell-index order. Caller can compute their regions via GetRegion(idx + N).
	public Result<uint32> AllocateContiguous(uint32 count)
	{
		if (count == 0 || count > CellCount) return .Err;

		// Find a run of `count` free consecutive cells.
		for (uint32 start = 0; start + count <= CellCount; start++)
		{
			bool ok = true;
			for (uint32 i = 0; i < count; i++)
			{
				if ((mCellsUsed & ((uint64)1 << (start + i))) != 0)
				{
					ok = false;
					break;
				}
			}
			if (ok)
			{
				for (uint32 i = 0; i < count; i++)
					mCellsUsed |= (uint64)1 << (start + i);
				return .Ok(start);
			}
		}
		return .Err;
	}

	/// Returns the region for the given cell index (regardless of allocation state).
	public ShadowAtlasRegion GetRegion(uint32 cellIndex)
	{
		return MakeRegion(cellIndex);
	}

	private ShadowAtlasRegion MakeRegion(uint32 cellIndex)
	{
		let cellX = cellIndex % CellsPerSide;
		let cellY = cellIndex / CellsPerSide;
		let pxX = cellX * CellSize;
		let pxY = cellY * CellSize;
		let invSize = 1.0f / (float)Size;

		return .()
		{
			X = pxX,
			Y = pxY,
			Width = CellSize,
			Height = CellSize,
			UVRect = .(
				(float)pxX * invSize,
				(float)pxY * invSize,
				(float)CellSize * invSize,
				(float)CellSize * invSize
			)
		};
	}
}
