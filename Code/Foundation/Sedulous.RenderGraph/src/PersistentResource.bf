using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A persistent resource that survives across frames with tracked state.
/// Externally owned - the render graph does not create or destroy these.
public class PersistentResource
{
	/// Texture handles (index 0 = primary, index 1 = secondary for ping-pong)
	private ITexture[2] mTextures;
	/// Texture view handles
	private ITextureView[2] mViews;
	/// Current active index (0 or 1)
	private int32 mCurrentIndex;
	/// Whether this is a ping-pong resource
	private bool mIsPingPong;
	/// Whether this is the first frame this resource is being used
	public bool FirstFrame = true;
	/// Last known resource state (persists across graph.Reset() calls)
	public ResourceState LastKnownState = .Undefined;

	/// Create a single persistent resource
	public this(ITexture texture, ITextureView view)
	{
		mTextures[0] = texture;
		mViews[0] = view;
		mCurrentIndex = 0;
		mIsPingPong = false;
	}

	/// Create a ping-pong persistent resource (double-buffered)
	public this(ITexture tex0, ITexture tex1, ITextureView view0, ITextureView view1)
	{
		mTextures[0] = tex0;
		mTextures[1] = tex1;
		mViews[0] = view0;
		mViews[1] = view1;
		mCurrentIndex = 0;
		mIsPingPong = true;
	}

	/// The current active texture
	public ITexture Texture => mTextures[mCurrentIndex];

	/// The current active texture view
	public ITextureView TextureView => mViews[mCurrentIndex];

	/// The previous frame's texture (for ping-pong; same as current for non-ping-pong)
	public ITexture PreviousTexture => mIsPingPong ? mTextures[1 - mCurrentIndex] : mTextures[mCurrentIndex];

	/// The previous frame's texture view
	public ITextureView PreviousTextureView => mIsPingPong ? mViews[1 - mCurrentIndex] : mViews[mCurrentIndex];

	/// Whether this is a ping-pong resource
	public bool IsPingPong => mIsPingPong;

	/// Swap the active texture (for ping-pong resources)
	public void Swap()
	{
		if (mIsPingPong)
			mCurrentIndex = 1 - mCurrentIndex;
	}

	/// Update references (e.g., when the external texture is recreated on resize)
	public void UpdateTexture(ITexture texture, ITextureView view)
	{
		mTextures[mCurrentIndex] = texture;
		mViews[mCurrentIndex] = view;
	}
}
