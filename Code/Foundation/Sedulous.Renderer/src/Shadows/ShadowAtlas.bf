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

/// Quality tier for shadow atlas allocation.
/// Higher tiers give more texels per shadow map at the cost of fewer slots.
public enum ShadowTier : uint8
{
	/// 2048×2048 — for near directional cascades (high resolution, 2 slots).
	Large,
	/// 1024×1024 — for far cascades and spot lights (4 slots).
	Medium,
	/// 512×512 — for point light faces and minor lights (16 slots).
	Small
}

/// Hierarchical shadow atlas with three cell-size tiers.
///
/// Atlas layout within a 4096×4096 depth texture:
///
///   +--------+--------+
///   | L0     | L1     |  Top half: 2 cells of 2048×2048
///   | 2048   | 2048   |
///   +----+---+--------+
///   |M0 M1|  S0 .. S15|  Bottom-left: 4 cells of 1024×1024
///   |M2 M3|  512×512  |  Bottom-right: 16 cells of 512×512
///   +----+-+-----------+
///
/// Total: 22 cells across 3 tiers, all packed into 4096×4096.
public class ShadowAtlas
{
	/// Per-tier metadata.
	private struct TierInfo
	{
		public uint32 CellSize;
		public uint32 OriginX, OriginY;   // pixel offset of the tier's region
		public uint32 CellsPerRow;
		public uint32 CellCount;
		public uint64 UsedMask;           // bitset (max 64 cells per tier)
	}

	private const int TierCount = 3;
	private TierInfo[TierCount] mTiers;

	private IDevice mDevice;
	private ITexture mTexture ~ if (mDevice != null) mDevice.DestroyTexture(ref _);
	private ITextureView mTextureView ~ if (mDevice != null) mDevice.DestroyTextureView(ref _);
	private TextureFormat mFormat = .Depth32Float;

	public uint32 Size { get; private set; }
	public ITexture Texture => mTexture;
	public ITextureView TextureView => mTextureView;
	public TextureFormat Format => mFormat;

	/// Gets the cell side length for a tier.
	public uint32 GetCellSize(ShadowTier tier) => mTiers[(int)tier].CellSize;

	public Result<void> Initialize(IDevice device, uint32 atlasSize = 4096)
	{
		mDevice = device;
		Size = atlasSize;

		// --- Tier layout ---
		// Large: top half — 2 cells of 2048
		mTiers[0] = .()
		{
			CellSize = 2048,
			OriginX = 0, OriginY = 0,
			CellsPerRow = 2,
			CellCount = 2,
			UsedMask = 0
		};
		// Medium: bottom-left quarter — 4 cells of 1024
		mTiers[1] = .()
		{
			CellSize = 1024,
			OriginX = 0, OriginY = 2048,
			CellsPerRow = 2,
			CellCount = 4,
			UsedMask = 0
		};
		// Small: bottom-right quarter — 16 cells of 512
		mTiers[2] = .()
		{
			CellSize = 512,
			OriginX = 2048, OriginY = 2048,
			CellsPerRow = 4,
			CellCount = 16,
			UsedMask = 0
		};

		// --- GPU texture ---
		TextureDesc desc = .()
		{
			Label = "Shadow Atlas",
			Width = atlasSize,
			Height = atlasSize,
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

	/// Resets all tier allocations. Called once per frame.
	public void Reset()
	{
		for (int i = 0; i < TierCount; i++)
			mTiers[i].UsedMask = 0;
	}

	/// Allocates a single cell from the given tier.
	public Result<ShadowAtlasRegion> AllocateCell(ShadowTier tier)
	{
		var tierInfo = ref mTiers[(int)tier];
		for (uint32 i = 0; i < tierInfo.CellCount; i++)
		{
			let mask = (uint64)1 << i;
			if ((tierInfo.UsedMask & mask) == 0)
			{
				tierInfo.UsedMask |= mask;
				return .Ok(MakeRegion(ref tierInfo, i));
			}
		}
		return .Err;
	}

	/// Allocates `count` contiguous cells from the given tier.
	/// Returns the first cell index within the tier.
	public Result<uint32> AllocateContiguous(ShadowTier tier, uint32 count)
	{
		if (count == 0) return .Err;
		var tierInfo = ref mTiers[(int)tier];
		if (count > tierInfo.CellCount) return .Err;

		for (uint32 start = 0; start + count <= tierInfo.CellCount; start++)
		{
			bool ok = true;
			for (uint32 i = 0; i < count; i++)
			{
				if ((tierInfo.UsedMask & ((uint64)1 << (start + i))) != 0)
				{
					ok = false;
					break;
				}
			}
			if (ok)
			{
				for (uint32 i = 0; i < count; i++)
					tierInfo.UsedMask |= (uint64)1 << (start + i);
				return .Ok(start);
			}
		}
		return .Err;
	}

	/// Returns the atlas region for a cell index within a tier.
	public ShadowAtlasRegion GetRegion(ShadowTier tier, uint32 cellIndex)
	{
		return MakeRegion(ref mTiers[(int)tier], cellIndex);
	}

	private ShadowAtlasRegion MakeRegion(ref TierInfo tier, uint32 cellIndex)
	{
		let cellX = cellIndex % tier.CellsPerRow;
		let cellY = cellIndex / tier.CellsPerRow;
		let pxX = tier.OriginX + cellX * tier.CellSize;
		let pxY = tier.OriginY + cellY * tier.CellSize;
		let invSize = 1.0f / (float)Size;

		return .()
		{
			X = pxX,
			Y = pxY,
			Width = tier.CellSize,
			Height = tier.CellSize,
			UVRect = .(
				(float)pxX * invSize,
				(float)pxY * invSize,
				(float)tier.CellSize * invSize,
				(float)tier.CellSize * invSize
			)
		};
	}
}
