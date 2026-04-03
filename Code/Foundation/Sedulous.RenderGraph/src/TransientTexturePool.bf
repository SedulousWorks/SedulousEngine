using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Pools GPU textures for reuse across frames by transient resources.
/// Avoids per-frame GPU allocation thrashing.
public class TransientTexturePool
{
	struct PooledTexture
	{
		public TextureDesc Desc;
		public ITexture Texture;
		public ITextureView View;
		public int32 UnusedFrames;
	}

	private List<PooledTexture> mPool = new .() ~ delete _;
	private IDevice mDevice;

	/// Max frames a pooled texture can go unused before being destroyed
	public int32 MaxUnusedFrames = 4;

	public this(IDevice device)
	{
		mDevice = device;
	}

	/// Try to acquire a matching texture from the pool.
	/// Returns true and sets texture/view if a match is found.
	public bool TryAcquire(TextureDesc desc, out ITexture texture, out ITextureView view)
	{
		for (int i = 0; i < mPool.Count; i++)
		{
			var entry = ref mPool[i];
			if (DescriptorsMatch(entry.Desc, desc))
			{
				texture = entry.Texture;
				view = entry.View;
				mPool.RemoveAt(i);
				return true;
			}
		}

		texture = null;
		view = null;
		return false;
	}

	/// Return a texture to the pool for future reuse
	public void ReturnToPool(TextureDesc desc, ITexture texture, ITextureView view)
	{
		mPool.Add(.()
		{
			Desc = desc,
			Texture = texture,
			View = view,
			UnusedFrames = 0
		});
	}

	/// Call at end of frame to age out unused textures
	public void EndFrame()
	{
		for (int i = mPool.Count - 1; i >= 0; i--)
		{
			var entry = ref mPool[i];
			entry.UnusedFrames++;

			if (entry.UnusedFrames > MaxUnusedFrames)
			{
				var tex = entry.Texture;
				var view = entry.View;
				mDevice.DestroyTextureView(ref view);
				mDevice.DestroyTexture(ref tex);
				mPool.RemoveAt(i);
			}
		}
	}

	/// Destroy all pooled textures
	public void DestroyAll()
	{
		for (var entry in ref mPool)
		{
			var tex = entry.Texture;
			var view = entry.View;
			if (view != null)
				mDevice.DestroyTextureView(ref view);
			if (tex != null)
				mDevice.DestroyTexture(ref tex);
		}
		mPool.Clear();
	}

	public ~this()
	{
		DestroyAll();
	}

	private static bool DescriptorsMatch(TextureDesc a, TextureDesc b)
	{
		return a.Format == b.Format &&
			   a.Width == b.Width &&
			   a.Height == b.Height &&
			   a.Depth == b.Depth &&
			   a.ArrayLayerCount == b.ArrayLayerCount &&
			   a.MipLevelCount == b.MipLevelCount &&
			   a.SampleCount == b.SampleCount &&
			   a.Usage == b.Usage;
	}
}
