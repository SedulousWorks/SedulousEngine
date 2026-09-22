using System;
using System.Collections;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.RHI;

namespace Sedulous.Engine.Terrain;

/// Owns and caches the per heightfield GPU height textures.
///
/// The renderer's vertex shader fetches a height per vertex, so each grid is uploaded as one
/// texel per sample and read exactly rather than filtered.
///
/// CACHED by the heightfield's own identity and a version. Two terrains referencing one
/// heightfield share ONE texture, and a version bump, which a sculpt produces, rebuilds it.
/// The key is the heightfield's UID rather than its address: a freed grid's address can be
/// handed straight back to a fresh one at an equal version, and an address keyed cache would
/// then serve the dead grid's texture.
///
/// The grid itself stays on the CPU, where navigation and physics read it; only the texture
/// lives here.
class TerrainHeightTextureCache
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
	/// destroying it at once: a submitted frame still samples the old view through the
	/// renderer's bind group. Unwired, as a headless test is, it falls back to destroying
	/// directly.
	public void SetRetireQueue(GpuRetireQueue retire)
	{
		mRetire = retire;
	}

	public int Size => mEntries.Count;

	/// The height texture for this heightfield at this version.
	///
	/// Creates, uploads and caches on a miss, and rebuilds in place when the version moved on,
	/// which is the sculpt path. Answers null for an empty grid or a device failure.
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

	/// Drops every entry. Runs at SCENE DESTROY as well as at shutdown, stopping play in the
	/// editor destroying the run's scenes mid frame loop, so a live entry may still sit in a
	/// submitted frame's descriptor set: with a retire queue wired the GPU objects age past
	/// every in flight frame before they are freed; without one, the Null device tests, they
	/// are destroyed in place.
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
		textureDesc.Format = .R16Uint;
		textureDesc.Width = size;
		textureDesc.Height = size;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "terrain.height";
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return false;
		outEntry.Texture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .R16Uint;
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
			let samples = heightfield.Samples;

			var layout = TextureDataLayout();
			layout.BytesPerRow = size * sizeof(uint16);
			layout.RowsPerImage = size;

			batch.WriteTexture(outEntry.Texture,
				.((uint8*)samples.Ptr, samples.Length * sizeof(uint16)), layout,
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
