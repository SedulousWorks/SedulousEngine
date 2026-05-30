using System;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Tracks ResourceState per subresource (mip level x array layer) with a uniform fast path.
/// When all subresources share the same state, only a single value is stored.
/// A per-subresource array is lazily allocated the first time states diverge.
public class SubresourceStateTracker
{
	private uint32 mMipCount;
	private uint32 mLayerCount;
	/// State used when all subresources are uniform (mStates == null)
	private ResourceState mUniformState;
	/// Per-subresource states, indexed as [mip + layer * mMipCount]. Null when uniform.
	private ResourceState[] mStates ~ delete _;

	public uint32 MipCount => mMipCount;
	public uint32 LayerCount => mLayerCount;

	public this(uint32 mipCount, uint32 layerCount, ResourceState initialState)
	{
		mMipCount = Math.Max(mipCount, 1);
		mLayerCount = Math.Max(layerCount, 1);
		mUniformState = initialState;
	}

	/// Whether all subresources are in the same state
	public bool IsUniform => mStates == null;

	/// The uniform state. Only meaningful when IsUniform is true.
	public ResourceState UniformState => mUniformState;

	/// Get the state for a single subresource
	public ResourceState GetState(uint32 mip, uint32 layer)
	{
		if (mStates == null)
			return mUniformState;
		let idx = mip + layer * mMipCount;
		if (idx >= (uint32)mStates.Count)
			return mUniformState;
		return mStates[idx];
	}

	/// Set state for a subresource range.
	/// mipCount/layerCount of 0 or uint32.MaxValue means "all remaining from base".
	public void SetState(uint32 baseMip, uint32 mipCount, uint32 baseLayer, uint32 layerCount, ResourceState state)
	{
		let resolvedMipEnd = ResolveEnd(baseMip, mipCount, mMipCount);
		let resolvedLayerEnd = ResolveEnd(baseLayer, layerCount, mLayerCount);

		// All subresources? Collapse to uniform.
		if (baseMip == 0 && resolvedMipEnd >= mMipCount && baseLayer == 0 && resolvedLayerEnd >= mLayerCount)
		{
			mUniformState = state;
			DeleteAndNullify!(mStates);
			return;
		}

		// Promote to per-subresource if needed
		if (mStates == null)
		{
			if (state == mUniformState)
				return; // No change
			mStates = new ResourceState[mMipCount * mLayerCount];
			for (int i = 0; i < mStates.Count; i++)
				mStates[i] = mUniformState;
		}

		// Update the range
		for (uint32 layer = baseLayer; layer < resolvedLayerEnd; layer++)
			for (uint32 mip = baseMip; mip < resolvedMipEnd; mip++)
				mStates[mip + layer * mMipCount] = state;

		// Try to collapse back to uniform
		TryCollapseToUniform();
	}

	/// Set state for a range described by RGSubresourceRange.
	/// RGSubresourceRange uses 0 for "all remaining"; this resolves that.
	public void SetState(RGSubresourceRange range, ResourceState state)
	{
		let mipCount = range.MipLevelCount == 0 ? uint32.MaxValue : range.MipLevelCount;
		let layerCount = range.ArrayLayerCount == 0 ? uint32.MaxValue : range.ArrayLayerCount;
		SetState(range.BaseMipLevel, mipCount, range.BaseArrayLayer, layerCount, state);
	}

	/// Set all subresources to the given state (always collapses to uniform)
	public void SetAll(ResourceState state)
	{
		mUniformState = state;
		DeleteAndNullify!(mStates);
	}

	/// Copy per-subresource states into a flat array. Returns null if uniform.
	/// Caller owns the returned array.
	public ResourceState[] CopyStates()
	{
		if (mStates == null)
			return null;
		let copy = new ResourceState[mStates.Count];
		mStates.CopyTo(copy);
		return copy;
	}

	/// Initialize from a per-subresource array (takes ownership of null, copies non-null).
	/// Used to restore persistent per-subresource state across frames.
	public void InitFromStates(ResourceState[] states, ResourceState uniformFallback)
	{
		if (states == null || states.Count != mMipCount * mLayerCount)
		{
			mUniformState = uniformFallback;
			DeleteAndNullify!(mStates);
			return;
		}

		delete mStates;
		mStates = new ResourceState[states.Count];
		states.CopyTo(mStates);

		TryCollapseToUniform();
	}

	private void TryCollapseToUniform()
	{
		if (mStates == null)
			return;
		let first = mStates[0];
		for (int i = 1; i < mStates.Count; i++)
		{
			if (mStates[i] != first)
				return;
		}
		mUniformState = first;
		DeleteAndNullify!(mStates);
	}

	/// Resolve "0 or MaxValue means all remaining" into an end index
	private static uint32 ResolveEnd(uint32 @base, uint32 count, uint32 total)
	{
		if (count == 0 || count == uint32.MaxValue)
			return total;
		return Math.Min(@base + count, total);
	}
}
