using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Pipeline.Core;
using Sedulous.Terrain.Resource;
using Sedulous.Texture.Pipeline;

namespace Sedulous.Terrain.Pipeline;

/// Packing the paint palette's layers into the slice major arrays the renderer samples.
static class TerrainPaletteCook
{
	/// The neutral slice each map falls back to when a layer supplies none.
	public static readonly uint8[4] cWhite = .(255, 255, 255, 255);
	/// Tangent space straight up.
	public static readonly uint8[4] cFlatNormal = .(128, 128, 255, 255);
	/// Full occlusion, full roughness, no metal.
	public static readonly uint8[4] cDefaultOrm = .(255, 255, 0, 255);
	/// A half height, which is neutral in the competition between layers.
	public static readonly uint8[4] cMidHeight = .(128, 128, 128, 255);
	/// Fully covering.
	public static readonly uint8[4] cOpaqueMask = .(255, 255, 255, 255);

	/// Decodes one layer texture's SOURCE pixels as RGBA8, leaving the list EMPTY when there is
	/// nothing to decode.
	///
	/// Through the SOURCE database. At cook time the other one holds cooked texture PRODUCTS,
	/// which may be block compressed and are not authoring assets at all, so resolving there
	/// decodes nothing. That mistake cooked every slice white once.
	public static void DecodeTextureRgba8(AssetBuildContext context, Guid id,
		List<uint8> outPixels, out uint32 outWidth, out uint32 outHeight)
	{
		outPixels.Clear();
		outWidth = 1;
		outHeight = 1;

		// A single database tool sets only the one, so either answers.
		let database = (context.SourceDatabase != null) ? context.SourceDatabase : context.Database;
		if ((database == null) || (id == Guid.Empty))
			return;

		let instance = database.GetInstance(id);
		if (instance == null)
			return;

		let object = instance.ReadObject();
		if (object == null)
			return;
		defer delete object;

		let texture = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
		if (texture == null)
			return;

		if (!texture.FileName.IsEmpty)
		{
			let bytes = scope List<uint8>();
			if (AssetSource.ReadBytes(context, texture.FileName.Value, bytes) case .Err)
				return;

			let image = scope Image();
			if (ImageIO.LoadImageFromMemory(bytes, image) case .Err)
				return;
			if (image.Format != .RGBA8)
				return;

			outWidth = image.Width;
			outHeight = image.Height;
			outPixels.AddRange(image.PixelData);
			return;
		}

		if ((texture.EmbeddedWidth > 0) && (texture.EmbeddedHeight > 0))
		{
			let stream = instance.ReadData(TextureAssetBuilder.cEmbeddedStreamName);
			if (stream == null)
				return;
			defer delete stream;

			let expected = (int)texture.EmbeddedWidth * (int)texture.EmbeddedHeight * 4;
			if ((int)stream.Size() != expected)
				return;

			outPixels.Count = expected;
			if (stream.Read(.(outPixels.Ptr, expected)) != expected)
			{
				outPixels.Clear();
				return;
			}
			outWidth = texture.EmbeddedWidth;
			outHeight = texture.EmbeddedHeight;
		}
	}

	/// Whether any layer supplies this map at all. A map array is built ON DEMAND, so a terrain
	/// whose layers all lack normals carries no normal array.
	public static bool AnySet(List<Guid> ids)
	{
		for (let id in ids)
		{
			if (id != Guid.Empty)
				return true;
		}
		return false;
	}

	/// Builds one slice major, mip chained array: a small header, then every slice's whole
	/// chain. A layer with no texture, or one that will not decode, gets a slice of the
	/// default.
	public static void CookArray(AssetBuildContext context, List<Guid> ids, uint32 sliceCount,
		uint32 sliceSize, uint32 mipCount, int sliceBytes, uint8[4] defaultTexel, bool srgb,
		List<uint8> outBlob)
	{
		var header = uint32[3](sliceSize, mipCount, sliceCount);
		let headerBytes = sizeof(uint32) * 3;

		outBlob.Clear();
		outBlob.Count = headerBytes + sliceBytes * (int)sliceCount;
		Internal.MemCpy(outBlob.Ptr, &header, headerBytes);

		let decoded = scope List<uint8>();
		let level = scope List<uint8>();
		let next = scope List<uint8>();

		for (uint32 slice < sliceCount)
		{
			let id = (slice < (uint32)ids.Count) ? ids[(int)slice] : Guid.Empty;
			DecodeTextureRgba8(context, id, decoded, var width, var height);
			if (decoded.IsEmpty)
			{
				width = 1;
				height = 1;
				var fallback = defaultTexel;
				decoded.Count = 4;
				Internal.MemCpy(decoded.Ptr, &fallback, 4);
			}

			level.Count = (int)sliceSize * (int)sliceSize * 4;
			TerrainImageOps.ResizeRgba8Bilinear(decoded, width, height, level, sliceSize, sliceSize);

			let destination = outBlob.Ptr + headerBytes + sliceBytes * (int)slice;
			var dimension = sliceSize;
			var written = 0;
			for (uint32 m < mipCount)
			{
				let bytes = (int)dimension * (int)dimension * 4;
				Internal.MemCpy(destination + written, level.Ptr, bytes);
				written += bytes;

				if ((m + 1) < mipCount)
				{
					let half = (dimension > 1) ? dimension / 2 : 1;
					next.Count = (int)half * (int)half * 4;
					if (srgb)
						TerrainImageOps.BoxHalveRgba8SrgbAware(.(level.Ptr, bytes), dimension, next);
					else
						TerrainImageOps.BoxHalveRgba8(.(level.Ptr, bytes), dimension, next);

					level.Clear();
					level.AddRange(next);
					dimension = half;
				}
			}
		}
	}
}
