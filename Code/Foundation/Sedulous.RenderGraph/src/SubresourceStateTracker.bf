using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Tracks the resource state of every subresource of a texture, with a UNIFORM FAST PATH.
///
/// While every subresource agrees, one value is stored and nothing is allocated, which is the
/// overwhelmingly common case. The per subresource array is materialised only when the states
/// diverge, and collapsed back the moment they agree again: a shadow atlas whose cascades are
/// written one at a time diverges for the length of that pass and no longer.
class SubresourceStateTracker
{
	/// A count meaning everything remaining from the base.
	private const uint32 cAllRemaining = 0xFFFFFFFF;

	private uint32 mMipCount;
	private uint32 mLayerCount;
	private ResourceState mUniformState;
	/// Empty means uniform.
	private List<ResourceState> mStates = new .() ~ delete _;

	public this(uint32 mipCount, uint32 layerCount, ResourceState initialState)
	{
		mMipCount = Max(mipCount, (uint32)1);
		mLayerCount = Max(layerCount, (uint32)1);
		mUniformState = initialState;
	}

	public uint32 MipCount => mMipCount;
	public uint32 LayerCount => mLayerCount;
	public bool IsUniform => mStates.IsEmpty;
	public ResourceState UniformState => mUniformState;

	public ResourceState GetState(uint32 mip, uint32 layer)
	{
		if (mStates.IsEmpty)
			return mUniformState;

		let index = (int)(mip + layer * mMipCount);
		if (index >= mStates.Count)
			return mUniformState;

		return mStates[index];
	}

	/// A count of zero, or of everything, means the rest from the base.
	public void SetState(uint32 baseMip, uint32 mipCount, uint32 baseLayer, uint32 layerCount,
		ResourceState state)
	{
		let mipEnd = ResolveEnd(baseMip, mipCount, mMipCount);
		let layerEnd = ResolveEnd(baseLayer, layerCount, mLayerCount);

		// The whole resource, so it collapses to uniform whatever it was before.
		if ((baseMip == 0) && (mipEnd >= mMipCount) && (baseLayer == 0) && (layerEnd >= mLayerCount))
		{
			mUniformState = state;
			mStates.Clear();
			return;
		}

		// The per subresource storage appears on the FIRST divergence, and a write of the
		// state everything already has is not one.
		if (mStates.IsEmpty)
		{
			if (state == mUniformState)
				return;

			mStates.Resize((int)(mMipCount * mLayerCount));
			for (int i < mStates.Count)
				mStates[i] = mUniformState;
		}

		for (uint32 layer = baseLayer; layer < layerEnd; layer++)
		{
			for (uint32 mip = baseMip; mip < mipEnd; mip++)
				mStates[(int)(mip + layer * mMipCount)] = state;
		}

		TryCollapseToUniform();
	}

	public void SetState(RGSubresourceRange range, ResourceState state)
	{
		let mipCount = (range.MipLevelCount == 0) ? cAllRemaining : range.MipLevelCount;
		let layerCount = (range.ArrayLayerCount == 0) ? cAllRemaining : range.ArrayLayerCount;
		SetState(range.BaseMipLevel, mipCount, range.BaseArrayLayer, layerCount, state);
	}

	public void SetAll(ResourceState state)
	{
		mUniformState = state;
		mStates.Clear();
	}

	/// Copies the per subresource states out, leaving the list EMPTY when they are uniform:
	/// that is what a persistent resource stores between frames.
	public void CopyStates(List<ResourceState> outStates)
	{
		outStates.Clear();
		if (mStates.IsEmpty)
			return;

		outStates.AddRange(mStates);
	}

	/// Restores from a snapshot. One that does not match this geometry falls back to the
	/// uniform state, because a mismatch means the resource was reallocated at a different
	/// size and the old states describe something that no longer exists.
	public void InitFromStates(List<ResourceState> states, ResourceState uniformFallback)
	{
		if (states.Count != (int)mMipCount * (int)mLayerCount)
		{
			mUniformState = uniformFallback;
			mStates.Clear();
			return;
		}

		mStates.Clear();
		mStates.AddRange(states);
		TryCollapseToUniform();
	}

	/// Back to the one value the moment every subresource agrees again, so the divergence
	/// costs only as long as it lasts.
	private void TryCollapseToUniform()
	{
		if (mStates.IsEmpty)
			return;

		let first = mStates[0];
		for (int i = 1; i < mStates.Count; i++)
		{
			if (mStates[i] != first)
				return;
		}

		mUniformState = first;
		mStates.Clear();
	}

	private static uint32 ResolveEnd(uint32 @base, uint32 count, uint32 total)
	{
		if ((count == 0) || (count == cAllRemaining))
			return total;
		return Min(@base + count, total);
	}
}
