using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Terrain.Resource;

/// Resolves a cooked terrain into the runtime one, binding each referenced resource through
/// the manager so the dependency edges are recorded and a reload of a heightfield or a
/// texture cascades.
///
/// A sub resource that is MISSING, meaning not cooked, or with no factory for it in a
/// headless tool, leaves that reference unbound rather than failing the terrain: a terrain
/// with no albedo still has its shape, and the renderer has stand ins for the rest.
class TerrainFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<TerrainResource>();

	/// The bind of each sub resource goes through the manager, which is the main thread's.
	public bool SupportsAsync => false;

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as TerrainSource;
		if (source == null)
		{
			// Something else was stored under this type name.
			delete stored;
			return null;
		}
		defer delete source;

		let terrain = new TerrainResource();
		terrain.CastShadows = source.CastShadows;
		terrain.HeightBlendContrast = source.HeightBlendContrast;

		// Each reference is STAMPED with its identity as well as bound. A factory built
		// product has to round trip its sub reference identities, or serializing it writes
		// nothing back, and the editor resolves the heightfield asset from this identity.
		if (source.HeightfieldId != Guid.Empty)
		{
			terrain.Heightfield.SetId(source.HeightfieldId);
			terrain.Heightfield.Bind(manager);
		}
		if (source.WeightsId != Guid.Empty)
		{
			terrain.Weights.SetId(source.WeightsId);
			terrain.Weights.Bind(manager);
		}

		terrain.Base.TileScale = source.BaseTileScale;
		BindTexture(manager, ref terrain.Base.Albedo, source.BaseAlbedoId);
		BindTexture(manager, ref terrain.Base.Normal, source.BaseNormalId);
		BindTexture(manager, ref terrain.Base.Orm, source.BaseOrmId);
		BindTexture(manager, ref terrain.Base.Height, source.BaseHeightId);

		for (int i < source.PaletteAlbedoIds.Count)
		{
			var layer = TerrainLayer();
			layer.TileScale = (i < source.PaletteTileScales.Count) ? source.PaletteTileScales[i] : 1.0f;

			BindTexture(manager, ref layer.Albedo, source.PaletteAlbedoIds[i]);
			if (i < source.PaletteNormalIds.Count)
				BindTexture(manager, ref layer.Normal, source.PaletteNormalIds[i]);
			if (i < source.PaletteOrmIds.Count)
				BindTexture(manager, ref layer.Orm, source.PaletteOrmIds[i]);
			if (i < source.PaletteHeightIds.Count)
				BindTexture(manager, ref layer.Height, source.PaletteHeightIds[i]);
			if (i < source.PaletteMaskIds.Count)
				BindTexture(manager, ref layer.Mask, source.PaletteMaskIds[i]);

			terrain.Palette.Add(layer);
		}

		terrain.PaletteData = ReadPalette(instance);
		return terrain;
	}

	public Object DecodeStage(Instance instance) => null;
	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	/// Binds and stamps a texture reference. An unset identity leaves it unbound, which is
	/// the renderer's stand in.
	private static void BindTexture(ResourceManager manager, ref Ref<Texture> reference, Guid id)
	{
		if (id == Guid.Empty)
			return;

		reference.SetId(id);
		reference.Bind(manager);
	}

	/// The cook built palette arrays: the albedo, plus whichever of the other maps were built.
	///
	/// A secondary array is taken ONLY when its geometry matches the albedo's exactly. One
	/// that does not is a stale or truncated cook, and binding it beside the albedo would
	/// sample a different slice for the same layer.
	///
	/// THE CALLER OWNS what comes back, and null means there is no palette.
	private static TerrainPaletteData ReadPalette(Instance instance)
	{
		let texels = scope List<uint8>();
		if (!ReadArrayStream(instance, TerrainPaletteData.AlbedoStream, let sliceSize,
			let mipCount, let sliceCount, texels))
			return null;

		let palette = new TerrainPaletteData();
		palette.SliceSize = sliceSize;
		palette.MipCount = mipCount;
		palette.SliceCount = sliceCount;
		palette.Texels.AddRange(texels);

		if (!palette.IsValid)
			return palette;

		ReadMatchingStream(instance, TerrainPaletteData.NormalStream, palette, palette.NormalTexels);
		ReadMatchingStream(instance, TerrainPaletteData.OrmStream, palette, palette.OrmTexels);
		ReadMatchingStream(instance, TerrainPaletteData.HeightStream, palette, palette.HeightTexels);
		ReadMatchingStream(instance, TerrainPaletteData.MaskStream, palette, palette.MaskTexels);
		return palette;
	}

	private static void ReadMatchingStream(Instance instance, StringView stream,
		TerrainPaletteData palette, List<uint8> outTexels)
	{
		let texels = scope List<uint8>();
		if (!ReadArrayStream(instance, stream, let sliceSize, let mipCount, let sliceCount, texels))
			return;

		if ((sliceSize != palette.SliceSize) || (mipCount != palette.MipCount)
			|| (sliceCount != palette.SliceCount) || (texels.Count != palette.ArrayBytes))
			return;

		outTexels.AddRange(texels);
	}

	/// One palette stream: a slice size, mip count and slice count, then the texels. False
	/// when the stream is absent or truncated.
	private static bool ReadArrayStream(Instance instance, StringView name, out uint32 outSliceSize,
		out uint32 outMipCount, out uint32 outSliceCount, List<uint8> outTexels)
	{
		outSliceSize = 0;
		outMipCount = 0;
		outSliceCount = 0;

		let stream = instance.ReadData(name);
		if (stream == null)
			return false;
		defer delete stream;

		let headerBytes = sizeof(uint32) * 3;
		let size = stream.Size();
		if (size <= (int64)headerBytes)
			return false;

		var header = uint32[3]();
		if (stream.Read(.((uint8*)&header[0], headerBytes)) != headerBytes)
			return false;

		outSliceSize = header[0];
		outMipCount = header[1];
		outSliceCount = header[2];

		let texelBytes = (int)size - headerBytes;
		outTexels.Resize(texelBytes);
		return stream.Read(.(outTexels.Ptr, texelBytes)) == texelBytes;
	}
}
