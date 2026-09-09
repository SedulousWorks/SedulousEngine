using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// A resource that survives from one frame to the next, with its state tracked across them.
///
/// EXTERNALLY OWNED: the graph never creates or destroys these, only reads and writes them.
/// The ping pong variant carries two slots, this frame's and last frame's, which is what a
/// temporal effect reads its history out of.
class PersistentResource
{
	/// The current slot and one previous.
	public const int SlotCount = 2;

	private ITexture[SlotCount] mTextures = .(null, null);
	private ITextureView[SlotCount] mViews = .(null, null);
	private int mCurrentIndex = 0;
	private bool mIsPingPong = false;

	/// Cross frame tracking the graph reads and writes. It survives a reset, which is the
	/// point of the resource.
	public bool FirstFrame = true;
	public ResourceState LastKnownState = .Undefined;
	/// Non empty when the resource ended a frame in a NON UNIFORM state, meaning its
	/// subresources disagree. Otherwise the single state above is the whole answer.
	public List<ResourceState> SubresourceStates = new .() ~ delete _;

	public this(ITexture texture, ITextureView view)
	{
		mTextures[0] = texture;
		mViews[0] = view;
	}

	/// The ping pong, or double buffered, variant.
	public this(ITexture first, ITexture second, ITextureView firstView, ITextureView secondView)
	{
		mIsPingPong = true;
		mTextures[0] = first;
		mTextures[1] = second;
		mViews[0] = firstView;
		mViews[1] = secondView;
	}

	public ITexture CurrentTexture => mTextures[mCurrentIndex];
	public ITextureView CurrentView => mViews[mCurrentIndex];

	/// Last frame's slot, or this frame's when there is only one: a single buffered history
	/// reads what it is about to overwrite, which is the caller's business rather than a
	/// reason to answer null.
	public ITexture PreviousTexture =>
		mIsPingPong ? mTextures[(mCurrentIndex + SlotCount - 1) % SlotCount] : mTextures[mCurrentIndex];
	public ITextureView PreviousView =>
		mIsPingPong ? mViews[(mCurrentIndex + SlotCount - 1) % SlotCount] : mViews[mCurrentIndex];

	public bool IsPingPong => mIsPingPong;

	public void Swap()
	{
		if (mIsPingPong)
			mCurrentIndex = (mCurrentIndex + 1) % SlotCount;
	}

	/// Re-points the active slot, which is what a resize does after the external texture is
	/// recreated.
	public void UpdateTexture(ITexture texture, ITextureView view)
	{
		mTextures[mCurrentIndex] = texture;
		mViews[mCurrentIndex] = view;
	}
}
