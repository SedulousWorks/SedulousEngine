using System;
using System.Collections;

namespace Sedulous.Terrain.Resource;

/// The cook built paint palette texels: every palette albedo resized to ONE common slice size
/// and mip chained, concatenated slice major.
///
/// CPU side, the way the heightfield and the weights are: the renderer derives and caches the
/// GPU texture array from it, keyed by identity. It rides the terrain's own cooked instance
/// as a sidecar rather than being a resource of its own.
class TerrainPaletteData
{
	/// The sidecar streams. The normal, occlusion, height and mask streams are ABSENT when no
	/// palette layer uses that map.
	public const String AlbedoStream = "palette";
	public const String NormalStream = "palette.normal";
	public const String OrmStream = "palette.orm";
	public const String HeightStream = "palette.height";
	public const String MaskStream = "palette.mask";

	/// Shares the splat weights' identity domain, and is a cache key rather than a reference.
	public readonly uint64 Uid = SplatWeights.NextUid();

	/// The square slice's side, which is a power of two.
	public uint32 SliceSize = 0;
	/// Mips per slice, down to one by one.
	public uint32 MipCount = 0;
	/// The palette's layer count at cook time.
	public uint32 SliceCount = 0;

	/// The ALBEDO array: each slice its own full mip chain, one after another.
	public List<uint8> Texels = new .() ~ delete _;

	/// The other arrays are built ON DEMAND, and empty means absent: no palette layer used
	/// that map, so the renderer binds a one by one stand in instead. A present array shares
	/// the albedo's geometry.
	public List<uint8> NormalTexels = new .() ~ delete _;
	public List<uint8> OrmTexels = new .() ~ delete _;
	public List<uint8> HeightTexels = new .() ~ delete _;
	public List<uint8> MaskTexels = new .() ~ delete _;

	/// The bytes of one slice's full mip chain at a geometry.
	public static int SliceBytes(uint32 sliceSize, uint32 mipCount)
	{
		var total = 0;
		var dimension = sliceSize;
		for (uint32 m = 0; m < mipCount; m++)
		{
			total += (int)dimension * (int)dimension * 4;
			dimension = (dimension > 1) ? (dimension / 2) : 1;
		}
		return total;
	}

	/// What one array must weigh at this geometry.
	public int ArrayBytes => SliceBytes(SliceSize, MipCount) * (int)SliceCount;

	public bool IsValid =>
		(SliceSize > 0) && (MipCount > 0) && (SliceCount > 0) && (Texels.Count == ArrayBytes);

	public bool HasNormal => IsValid && (NormalTexels.Count == ArrayBytes);
	public bool HasOrm => IsValid && (OrmTexels.Count == ArrayBytes);
	public bool HasHeight => IsValid && (HeightTexels.Count == ArrayBytes);
	public bool HasMask => IsValid && (MaskTexels.Count == ArrayBytes);
}
