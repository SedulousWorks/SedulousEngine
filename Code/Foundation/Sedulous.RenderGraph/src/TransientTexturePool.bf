using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Keeps GPU textures alive between frames so the transient resources can reuse them.
///
/// A graph rebuilt every frame would otherwise create and destroy the same handful of targets
/// forever, which thrashes the allocator for no reason. Matching is by the EXACT descriptor,
/// since a target that differs in any of it is a different target, and an entry nothing has
/// asked for in a few frames is let go.
class TransientTexturePool
{
	private IDevice mDevice;
	private List<PooledTexture> mPool = new .() ~ delete _;

	/// How long an unwanted entry is kept. A few frames, because a resolution or a quality
	/// change makes several targets briefly unwanted and then wanted again.
	public int32 MaxUnusedFrames = 4;

	public this(IDevice device)
	{
		mDevice = device;
	}

	public ~this()
	{
		DestroyAll();
	}

	public int Count => mPool.Count;

	/// Takes a matching texture out of the pool.
	///
	/// The GENERATION comes back with it, which is the physical texture's identity: a
	/// consumer caching anything over the view keys on that rather than on the view's
	/// address, since a freed address comes back attached to something else.
	public bool TryAcquire(TextureDesc desc, out ITexture outTexture, out ITextureView outView,
		out uint64 outGeneration)
	{
		for (int i < mPool.Count)
		{
			if (!DescriptorsMatch(mPool[i].Desc, desc))
				continue;

			outTexture = mPool[i].Texture;
			outView = mPool[i].View;
			outGeneration = mPool[i].Generation;
			mPool.RemoveAt(i);
			return true;
		}

		outTexture = null;
		outView = null;
		outGeneration = 0;
		return false;
	}

	public void ReturnToPool(TextureDesc desc, ITexture texture, ITextureView view, uint64 generation)
	{
		mPool.Add(.(desc, texture, view, generation));
	}

	/// Ages the pool, freeing whatever has gone unwanted for too long.
	public void EndFrame()
	{
		for (int i = mPool.Count - 1; i >= 0; i--)
		{
			var entry = mPool[i];
			entry.UnusedFrames++;
			mPool[i] = entry;

			if (entry.UnusedFrames <= MaxUnusedFrames)
				continue;

			Destroy(entry);
			mPool.RemoveAt(i);
		}
	}

	public void DestroyAll()
	{
		for (let entry in mPool)
			Destroy(entry);
		mPool.Clear();
	}

	private void Destroy(PooledTexture entry)
	{
		var view = entry.View;
		var texture = entry.Texture;
		if (view != null)
			mDevice.DestroyTextureView(ref view);
		if (texture != null)
			mDevice.DestroyTexture(ref texture);
	}

	/// EXACT: anything that differs is a different target, and handing back a near miss
	/// silently gives a pass a target of the wrong shape.
	private static bool DescriptorsMatch(TextureDesc a, TextureDesc b) =>
		(a.Dimension == b.Dimension) && (a.Format == b.Format) && (a.Width == b.Width)
		&& (a.Height == b.Height) && (a.Depth == b.Depth)
		&& (a.ArrayLayerCount == b.ArrayLayerCount) && (a.MipLevelCount == b.MipLevelCount)
		&& (a.SampleCount == b.SampleCount) && (a.Usage == b.Usage);
}
