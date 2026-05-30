using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A persistent resource that survives across frames with tracked state.
/// Externally owned - the render graph does not create or destroy these.
///
/// The ping-pong variant carries SlotCount slots (current + previous frame).
/// Independent of MaxFramesInFlight: that controls CPU/GPU pipelining
/// (fence-driven), this controls how many frames of temporal data are
/// retained. The PreviousTexture / PreviousTextureView accessors specifically
/// model "current + one previous" - deeper history would need a different
/// accessor shape, so bumping SlotCount alone is not enough to support N>2.
public class PersistentResource
{
	/// Number of slots in the ping-pong (current + one previous).
	public const int SlotCount = 2;

	/// Texture handles (index 0 = primary, index 1 = secondary for ping-pong)
	private ITexture[SlotCount] mTextures;
	/// Texture view handles
	private ITextureView[SlotCount] mViews;
	/// Current active index in [0, SlotCount)
	private int32 mCurrentIndex;
	/// Whether this is a ping-pong resource
	private bool mIsPingPong;
	/// Whether this is the first frame this resource is being used
	public bool FirstFrame = true;
	/// Last known resource state (persists across graph.Reset() calls).
	/// When SubresourceStates is non-null, this is the fallback/uniform value.
	public ResourceState LastKnownState = .Undefined;
	/// Per-subresource states when the resource ended the previous frame in non-uniform state.
	/// Null when all subresources share the same state (stored in LastKnownState).
	public ResourceState[] SubresourceStates ~ delete _;

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
	public ITexture PreviousTexture => mIsPingPong ? mTextures[(mCurrentIndex + SlotCount - 1) % SlotCount] : mTextures[mCurrentIndex];

	/// The previous frame's texture view
	public ITextureView PreviousTextureView => mIsPingPong ? mViews[(mCurrentIndex + SlotCount - 1) % SlotCount] : mViews[mCurrentIndex];

	/// Whether this is a ping-pong resource
	public bool IsPingPong => mIsPingPong;

	/// Swap the active texture (for ping-pong resources)
	public void Swap()
	{
		if (mIsPingPong)
			mCurrentIndex = (int32)((mCurrentIndex + 1) % SlotCount);
	}

	/// Update references (e.g., when the external texture is recreated on resize)
	public void UpdateTexture(ITexture texture, ITextureView view)
	{
		mTextures[mCurrentIndex] = texture;
		mViews[mCurrentIndex] = view;
	}
}
