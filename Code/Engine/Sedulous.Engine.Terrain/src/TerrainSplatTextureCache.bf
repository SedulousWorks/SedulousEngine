using System;
using System.Collections;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain;

/// Owns and caches the per raster GPU texture PAIRS: the blend weights and the layer indices.
///
/// Keyed by the raster's own identity and a version, for the same reason the height cache is:
/// a freed raster's address can be handed back to a fresh one at an equal version, so keying
/// on an address would serve the dead raster's textures. A paint bumps the version and the
/// pair rebuilds in place.
class TerrainSplatTextureCache
{
	private class Entry
	{
		/// The raster's UID, never its address.
		public uint64 Key = 0;
		public uint64 Version = 0;
		public ITexture WeightTexture = null;
		public ITextureView WeightView = null;
		public ITexture IndexTexture = null;
		public ITextureView IndexView = null;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: the render subsystem owns and ticks it.
	private GpuRetireQueue mRetire = null;

	/// A paint's rebuild RETIRES the old pair rather than destroying it at once: a submitted
	/// frame still samples the old views. Unwired, it destroys directly.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
	}

	public int Size => mEntries.Count;

	public SplatTextureViews GetOrCreate(IDevice device, SplatWeights weights, uint64 version)
	{
		if (weights.IsEmpty)
			return .();

		for (let entry in mEntries)
		{
			if (entry.Key != weights.Uid)
				continue;

			if ((entry.Version == version) && (entry.WeightView != null))
				return .(entry.WeightView, entry.IndexView);

			RetireOrDestroy(device, entry);
			if (!Build(device, weights, entry))
				return .();

			entry.Version = version;
			return .(entry.WeightView, entry.IndexView);
		}

		let fresh = new Entry();
		fresh.Key = weights.Uid;
		fresh.Version = version;

		if (!Build(device, weights, fresh))
		{
			delete fresh;
			return .();
		}

		mEntries.Add(fresh);
		return .(fresh.WeightView, fresh.IndexView);
	}

	/// Destroys everything cached. Call it while the device is still alive.
	public void Clear(IDevice device)
	{
		for (let entry in mEntries)
			Destroy(device, entry);

		ClearAndDeleteItems!(mEntries);
	}

	private static bool BuildOne(IDevice device, uint32 width, uint32 height, TextureFormat format,
		Span<uint8> pixels, StringView label, out ITexture outTexture, out ITextureView outView)
	{
		outTexture = null;
		outView = null;

		var textureDesc = TextureDesc();
		textureDesc.Format = format;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = label;
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return false;
		outTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = format;
		viewDesc.Dimension = .Texture2D;
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
			var layout = TextureDataLayout();
			// Four channels, one byte each.
			layout.BytesPerRow = width * 4;
			layout.RowsPerImage = height;

			batch.WriteTexture(outTexture, pixels, layout, .(width, height, 1));
			batch.Submit().IgnoreError();
			queue.DestroyTransferBatch(ref batch);
		}

		return true;
	}

	private static bool Build(IDevice device, SplatWeights weights, Entry outEntry)
	{
		let width = (uint32)weights.Width;
		let height = (uint32)weights.Height;

		if (!BuildOne(device, width, height, .RGBA8Unorm, weights.Weights,
			"terrain.splat.weights", out outEntry.WeightTexture, out outEntry.WeightView))
			return false;

		// The INDICES are read as data rather than filtered, so they are an integer format.
		if (!BuildOne(device, width, height, .RGBA8Uint, weights.Indices,
			"terrain.splat.indices", out outEntry.IndexTexture, out outEntry.IndexView))
		{
			device.DestroyTextureView(ref outEntry.WeightView);
			device.DestroyTexture(ref outEntry.WeightTexture);
			return false;
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

		mRetire.Retire(entry.WeightView);
		mRetire.Retire(entry.WeightTexture);
		mRetire.Retire(entry.IndexView);
		mRetire.Retire(entry.IndexTexture);

		entry.WeightView = null;
		entry.WeightTexture = null;
		entry.IndexView = null;
		entry.IndexTexture = null;
	}

	private static void Destroy(IDevice device, Entry entry)
	{
		if (entry.WeightView != null)
			device.DestroyTextureView(ref entry.WeightView);
		if (entry.WeightTexture != null)
			device.DestroyTexture(ref entry.WeightTexture);
		if (entry.IndexView != null)
			device.DestroyTextureView(ref entry.IndexView);
		if (entry.IndexTexture != null)
			device.DestroyTexture(ref entry.IndexTexture);
	}
}
