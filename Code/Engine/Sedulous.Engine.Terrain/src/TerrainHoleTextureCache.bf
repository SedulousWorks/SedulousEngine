using System;
using System.Collections;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.RHI;

namespace Sedulous.Engine.Terrain;

/// Owns and caches the per heightfield GPU hole MASK textures.
///
/// One R8 texel per sample, nought solid and one cut, which the HOLES pixel shaders sample
/// BILINEARLY: the drawn rim is that mask's half iso line, one smooth curve through the cut
/// samples instead of a staircase of whole triangles, and it reads the same at every level.
///
/// The height texture cache's twin in every other respect: keyed by the heightfield's UID
/// rather than its address, rebuilt in place on a version change, retired through the frame
/// aged queue. Only a grid that HAS holes gets one, the extract asking first, so a solid
/// terrain pays nothing.
class TerrainHoleTextureCache
{
	private class Entry
	{
		/// The heightfield's UID, never its address.
		public uint64 Key = 0;
		public uint64 Version = 0;
		public ITexture Texture = null;
		public ITextureView View = null;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: the render subsystem owns and ticks it.
	private GpuRetireQueue mRetire = null;

	/// Wires in the frame aged queue, so a rebuild RETIRES the old texture instead of
	/// destroying it at once. Unwired, as a headless test is, it falls back to destroying
	/// directly.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
	}

	public int Size => mEntries.Count;

	/// The hole mask for this heightfield at this version.
	///
	/// Creates, uploads and caches on a miss, and rebuilds in place when the version moved on,
	/// which is the hole brush's path. Answers null for an empty grid or a device failure.
	public ITextureView GetOrCreate(IDevice device, Heightfield heightfield, uint64 version)
	{
		if (heightfield.IsEmpty)
			return null;

		for (let entry in mEntries)
		{
			if (entry.Key != heightfield.Uid)
				continue;

			if ((entry.Version == version) && (entry.View != null))
				return entry.View;

			RetireOrDestroy(device, entry);
			if (!Build(device, heightfield, entry))
				return null;

			entry.Version = version;
			return entry.View;
		}

		let fresh = new Entry();
		fresh.Key = heightfield.Uid;
		fresh.Version = version;

		if (!Build(device, heightfield, fresh))
		{
			delete fresh;
			return null;
		}

		mEntries.Add(fresh);
		return fresh.View;
	}

	/// Drops every entry, on a scene destroy as much as at shutdown.
	public void Clear(IDevice device)
	{
		for (let entry in mEntries)
			RetireOrDestroy(device, entry);

		ClearAndDeleteItems!(mEntries);
	}

	private static bool Build(IDevice device, Heightfield heightfield, Entry outEntry)
	{
		let size = (uint32)heightfield.Size;

		var textureDesc = TextureDesc();
		textureDesc.Format = .R8Unorm;
		textureDesc.Width = size;
		textureDesc.Height = size;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "terrain.holes";
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return false;
		outEntry.Texture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .R8Unorm;
		viewDesc.Dimension = .Texture2D;
		if (!(device.CreateTextureView(texture, viewDesc) case .Ok(let view)))
		{
			var owned = outEntry.Texture;
			device.DestroyTexture(ref owned);
			outEntry.Texture = null;
			return false;
		}
		outEntry.View = view;

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return true;

		if (queue.CreateTransferBatch() case .Ok(var batch))
		{
			let holes = heightfield.Holes;

			var layout = TextureDataLayout();
			layout.BytesPerRow = size;
			layout.RowsPerImage = size;

			batch.WriteTexture(outEntry.Texture, .(holes.Ptr, holes.Length), layout,
				.(size, size, 1));
			batch.Submit().IgnoreError();
			queue.DestroyTransferBatch(ref batch);
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

		// Aged past every frame still in flight, and freed then.
		mRetire.Retire(entry.View);
		mRetire.Retire(entry.Texture);
		entry.View = null;
		entry.Texture = null;
	}

	private static void Destroy(IDevice device, Entry entry)
	{
		if (entry.View != null)
			device.DestroyTextureView(ref entry.View);
		if (entry.Texture != null)
			device.DestroyTexture(ref entry.Texture);
	}
}
