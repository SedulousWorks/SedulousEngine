using System;
using System.Collections;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain;

/// Owns and caches the palette texture ARRAYS and the tile scale buffer for one terrain.
///
/// Keyed by the palette's own identity and a hash of the tile scales, never by an address.
/// Editing a palette re-cooks the terrain into a NEW palette with a new identity, so the old
/// arrays are RETIRED: a frame still in flight is sampling them.
class TerrainPaletteTextureCache
{
	private class Entry
	{
		/// The palette's UID, never its address.
		public uint64 Key = 0;
		public uint64 ScaleHash = 0;
		public uint64 Generation = 0;

		/// The albedo, which is the only array always present.
		public ITexture ArrayTexture = null;
		public ITextureView ArrayView = null;

		public ITexture NormalTexture = null;
		public ITextureView NormalArrayView = null;
		public ITexture OrmTexture = null;
		public ITextureView OrmArrayView = null;
		public ITexture HeightTexture = null;
		public ITextureView HeightArrayView = null;
		public ITexture MaskTexture = null;
		public ITextureView MaskArrayView = null;

		public IBuffer TileScaleBuffer = null;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: the render subsystem owns and ticks it.
	private GpuRetireQueue mRetire = null;

	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
	}

	public int Size => mEntries.Count;

	public PaletteGpu GetOrCreate(IDevice device, TerrainPaletteData data,
		Span<float> paletteTileScales)
	{
		if (!data.IsValid)
			return .();

		let scaleHash = HashScales(paletteTileScales);

		for (let entry in mEntries)
		{
			if (entry.Key != data.Uid)
				continue;

			if ((entry.ScaleHash == scaleHash) && (entry.ArrayView != null))
				return MakeGpu(entry);

			RetireOrDestroy(device, entry);
			if (!Build(device, data, paletteTileScales, entry))
				return .();

			entry.ScaleHash = scaleHash;
			entry.Generation++;
			return MakeGpu(entry);
		}

		let fresh = new Entry();
		fresh.Key = data.Uid;
		fresh.ScaleHash = scaleHash;
		fresh.Generation = 1;

		if (!Build(device, data, paletteTileScales, fresh))
		{
			delete fresh;
			return .();
		}

		mEntries.Add(fresh);
		return MakeGpu(fresh);
	}

	public void Clear(IDevice device)
	{
		for (let entry in mEntries)
			Destroy(device, entry);

		ClearAndDeleteItems!(mEntries);
	}

	private static PaletteGpu MakeGpu(Entry entry)
	{
		var gpu = PaletteGpu();
		gpu.ArrayView = entry.ArrayView;
		gpu.NormalArrayView = entry.NormalArrayView;
		gpu.OrmArrayView = entry.OrmArrayView;
		gpu.HeightArrayView = entry.HeightArrayView;
		gpu.MaskArrayView = entry.MaskArrayView;
		gpu.TileScaleBuffer = entry.TileScaleBuffer;
		gpu.Generation = entry.Generation;
		return gpu;
	}

	/// The scales hashed by their BITS rather than their values, so the comparison is exact
	/// and a rebuild follows any edit at all.
	private static uint64 HashScales(Span<float> scales)
	{
		var hash = 1469598103934665603UL;
		for (int i < scales.Length)
		{
			var value = scales[i];
			let bits = *(uint32*)&value;
			hash = (hash ^ bits) &* 1099511628211UL;
		}
		return hash;
	}

	/// One array texture, uploaded slice by slice and mip by mip.
	private static bool BuildArray(IDevice device, TextureFormat format, Span<uint8> texels,
		uint32 sliceSize, uint32 mipCount, uint32 sliceCount, StringView label,
		out ITexture outTexture, out ITextureView outView)
	{
		outTexture = null;
		outView = null;

		var textureDesc = TextureDesc();
		textureDesc.Format = format;
		textureDesc.Width = sliceSize;
		textureDesc.Height = sliceSize;
		textureDesc.ArrayLayerCount = sliceCount;
		textureDesc.MipLevelCount = mipCount;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = label;
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return false;
		outTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = format;
		viewDesc.Dimension = .Texture2DArray;
		viewDesc.ArrayLayerCount = sliceCount;
		viewDesc.MipLevelCount = mipCount;
		if (!(device.CreateTextureView(texture, viewDesc) case .Ok(let view)))
		{
			var owned = texture;
			device.DestroyTexture(ref owned);
			outTexture = null;
			return false;
		}
		outView = view;

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return true;

		if (queue.CreateTransferBatch() case .Ok(var batch))
		{
			let sliceBytes = TerrainPaletteData.SliceBytes(sliceSize, mipCount);

			for (uint32 slice < sliceCount)
			{
				let sliceBase = texels.Ptr + sliceBytes * (int)slice;
				var offset = 0;
				var dimension = sliceSize;

				for (uint32 mip < mipCount)
				{
					let bytes = (int)dimension * (int)dimension * 4;

					var layout = TextureDataLayout();
					layout.BytesPerRow = dimension * 4;
					layout.RowsPerImage = dimension;

					batch.WriteTexture(outTexture, .(sliceBase + offset, bytes), layout,
						.(dimension, dimension, 1), mip, slice);

					offset += bytes;
					dimension = (dimension > 1) ? (dimension / 2) : 1;
				}
			}

			batch.Submit().IgnoreError();
			queue.DestroyTransferBatch(ref batch);
		}

		return true;
	}

	private static bool Build(IDevice device, TerrainPaletteData data, Span<float> paletteTileScales,
		Entry outEntry)
	{
		// The albedo is sRGB, which is what closes the brightness gap against the base layer.
		// Everything else is LINEAR data and is only built when a layer actually supplied it;
		// otherwise the renderer binds a stand in.
		if (!BuildArray(device, .RGBA8UnormSrgb, data.Texels, data.SliceSize, data.MipCount,
			data.SliceCount, "terrain.palette", out outEntry.ArrayTexture,
			out outEntry.ArrayView))
			return false;

		if (data.HasNormal && !BuildArray(device, .RGBA8Unorm, data.NormalTexels, data.SliceSize,
			data.MipCount, data.SliceCount, "terrain.palette.normal", out outEntry.NormalTexture,
			out outEntry.NormalArrayView))
		{
			Destroy(device, outEntry);
			return false;
		}

		if (data.HasOrm && !BuildArray(device, .RGBA8Unorm, data.OrmTexels, data.SliceSize,
			data.MipCount, data.SliceCount, "terrain.palette.orm", out outEntry.OrmTexture,
			out outEntry.OrmArrayView))
		{
			Destroy(device, outEntry);
			return false;
		}

		if (data.HasHeight && !BuildArray(device, .RGBA8Unorm, data.HeightTexels, data.SliceSize,
			data.MipCount, data.SliceCount, "terrain.palette.height", out outEntry.HeightTexture,
			out outEntry.HeightArrayView))
		{
			Destroy(device, outEntry);
			return false;
		}

		if (data.HasMask && !BuildArray(device, .RGBA8Unorm, data.MaskTexels, data.SliceSize,
			data.MipCount, data.SliceCount, "terrain.palette.mask", out outEntry.MaskTexture,
			out outEntry.MaskArrayView))
		{
			Destroy(device, outEntry);
			return false;
		}

		return BuildTileScales(device, data, paletteTileScales, outEntry);
	}

	/// One scale per palette layer. The BASE tile rides the view's constants, so editing that
	/// never rebuilds this.
	private static bool BuildTileScales(IDevice device, TerrainPaletteData data,
		Span<float> paletteTileScales, Entry outEntry)
	{
		let scales = scope List<float>();
		for (uint32 i < data.SliceCount)
			scales.Add((i < paletteTileScales.Length) ? paletteTileScales[i] : 1.0f);

		var desc = BufferDesc();
		desc.Size = (uint64)scales.Count * sizeof(float);
		// READ ONLY storage rather than plain storage: the shader only reads it, and upload
		// heap memory cannot carry a writable storage usage at all.
		desc.Usage = .StorageRead | .CopyDst;
		desc.Memory = .CpuToGpu;
		desc.Label = "terrain.tileScales";
		if (!(device.CreateBuffer(desc) case .Ok(let buffer)))
		{
			Destroy(device, outEntry);
			return false;
		}
		outEntry.TileScaleBuffer = buffer;

		let mapped = buffer.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, scales.Ptr, scales.Count * sizeof(float));
			buffer.Unmap();
		}

		return true;
	}

	private void RetireOrDestroy(IDevice device, Entry entry)
	{
		if (mRetire == null)
		{
			Destroy(device, entry);
			return;
		}

		mRetire.Retire(entry.ArrayView);
		mRetire.Retire(entry.ArrayTexture);
		mRetire.Retire(entry.NormalArrayView);
		mRetire.Retire(entry.NormalTexture);
		mRetire.Retire(entry.OrmArrayView);
		mRetire.Retire(entry.OrmTexture);
		mRetire.Retire(entry.HeightArrayView);
		mRetire.Retire(entry.HeightTexture);
		mRetire.Retire(entry.MaskArrayView);
		mRetire.Retire(entry.MaskTexture);
		mRetire.Retire(entry.TileScaleBuffer);

		entry.ArrayView = null;
		entry.ArrayTexture = null;
		entry.NormalArrayView = null;
		entry.NormalTexture = null;
		entry.OrmArrayView = null;
		entry.OrmTexture = null;
		entry.HeightArrayView = null;
		entry.HeightTexture = null;
		entry.MaskArrayView = null;
		entry.MaskTexture = null;
		entry.TileScaleBuffer = null;
	}

	private static void Destroy(IDevice device, Entry entry)
	{
		if (entry.ArrayView != null)
			device.DestroyTextureView(ref entry.ArrayView);
		if (entry.ArrayTexture != null)
			device.DestroyTexture(ref entry.ArrayTexture);
		if (entry.NormalArrayView != null)
			device.DestroyTextureView(ref entry.NormalArrayView);
		if (entry.NormalTexture != null)
			device.DestroyTexture(ref entry.NormalTexture);
		if (entry.OrmArrayView != null)
			device.DestroyTextureView(ref entry.OrmArrayView);
		if (entry.OrmTexture != null)
			device.DestroyTexture(ref entry.OrmTexture);
		if (entry.HeightArrayView != null)
			device.DestroyTextureView(ref entry.HeightArrayView);
		if (entry.HeightTexture != null)
			device.DestroyTexture(ref entry.HeightTexture);
		if (entry.MaskArrayView != null)
			device.DestroyTextureView(ref entry.MaskArrayView);
		if (entry.MaskTexture != null)
			device.DestroyTexture(ref entry.MaskTexture);
		if (entry.TileScaleBuffer != null)
			device.DestroyBuffer(ref entry.TileScaleBuffer);
	}
}
