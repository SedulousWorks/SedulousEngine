using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Computes and emits resource barriers between render graph passes.
/// Tracks state at two levels:
/// - Per-resource-handle (fast lookup for buffers and simple queries)
/// - Per-ITexture with per-subresource granularity (source of truth for textures)
public class BarrierSolver
{
	/// Identity key for ITexture - hashes by object pointer so the same
	/// GPU texture is always the same key regardless of which handle references it.
	private struct TextureKey : IHashable
	{
		public ITexture Texture;

		public this(ITexture texture) { Texture = texture; }

		public int GetHashCode()
		{
			return (int)(void*)Internal.UnsafeCastToPtr(Texture);
		}

		public static bool operator==(Self lhs, Self rhs)
		{
			return lhs.Texture === rhs.Texture;
		}
	}

	/// Per-resource-handle tracked state (buffers: source of truth; textures: last-set convenience)
	private Dictionary<int32, ResourceState> mResourceStates = new .() ~ delete _;
	/// Per-ITexture tracked state with per-subresource granularity - source of truth for textures
	private Dictionary<TextureKey, SubresourceStateTracker> mTextureStates = new .() ~ {
		for (let v in _.Values) delete v;
		delete _;
	};
	/// Temporary barrier lists to avoid per-pass allocation
	private List<TextureBarrier> mTextureBarriers = new .() ~ delete _;
	private List<BufferBarrier> mBufferBarriers = new .() ~ delete _;

	/// Initialize resource states from the resource list.
	/// Persistent resources use their LastKnownState; transient resources start from InitialState.
	/// When multiple handles reference the same ITexture, they share one state entry.
	public void Reset(List<RenderGraphResource> resources)
	{
		mResourceStates.Clear();
		for (let v in mTextureStates.Values) delete v;
		mTextureStates.Clear();

		for (int32 i = 0; i < (int32)resources.Count; i++)
		{
			let res = resources[i];
			if (res == null) continue;

			ResourceState initialState = .Undefined;

			if (res.Lifetime == .Persistent && res.PersistentData != null)
			{
				// Persistent resources carry state from previous frame
				if (res.PersistentData.FirstFrame)
					initialState = res.Texture != null ? res.Texture.InitialState : .Undefined;
				else
					initialState = res.PersistentData.LastKnownState;
			}
			else if (res.Lifetime == .Imported)
			{
				// Imported resources start from their last known state
				initialState = res.LastKnownState;
			}
			else
			{
				// Transient resources always start from Undefined, even if the pooled
				// texture reports an InitialState. The texture may have been reused from
				// the pool in a different state than its creation default. Starting from
				// Undefined forces a barrier on first access; the DX12/Vulkan backends
				// use the texture's actual tracked state (dxTex.State / vkTex.CurrentLayout)
				// for the "before" side, so the transition is always correct.
				initialState = .Undefined;
			}

			mResourceStates[i] = initialState;

			// For textures, register in the ITexture-keyed dictionary with per-subresource tracking.
			if (res.ResourceType == .Texture && res.Texture != null)
			{
				let key = TextureKey(res.Texture);
				if (mTextureStates.TryGetValue(key, let existingTracker))
				{
					// Same GPU texture seen from another handle - unify state.
					// Prefer the existing tracked state if our handle says Undefined.
					if (initialState == .Undefined && existingTracker.IsUniform && existingTracker.UniformState != .Undefined)
						mResourceStates[i] = existingTracker.UniformState;
					else if (initialState != .Undefined)
						existingTracker.SetAll(initialState);
				}
				else
				{
					let mipCount = res.Texture.Desc.MipLevelCount;
					let layerCount = res.Texture.Desc.ArrayLayerCount;
					let tracker = new SubresourceStateTracker(mipCount, layerCount, initialState);

					// Restore per-subresource state from persistent data if available
					if (res.Lifetime == .Persistent && res.PersistentData != null
						&& !res.PersistentData.FirstFrame && res.PersistentData.SubresourceStates != null)
					{
						tracker.InitFromStates(res.PersistentData.SubresourceStates, initialState);
					}

					mTextureStates[key] = tracker;
				}
			}
		}
	}

	/// Emit barriers needed before executing the given pass.
	/// For textures with non-uniform subresource states, emits per-subresource barriers.
	public void EmitBarriers(RenderGraphPass pass, List<RenderGraphResource> resources, ICommandEncoder encoder)
	{
		mTextureBarriers.Clear();
		mBufferBarriers.Clear();

		for (let access in pass.Accesses)
		{
			if (!access.Handle.IsValid) continue;
			let resIdx = (int32)access.Handle.Index;
			if (resIdx >= resources.Count) continue;

			let res = resources[resIdx];
			if (res == null) continue;

			let requiredState = access.ToResourceState();
			let accessIsReadWrite = access.Type.IsRead && access.Type.IsWrite;

			if (res.ResourceType == .Texture && res.Texture != null)
			{
				let key = TextureKey(res.Texture);
				SubresourceStateTracker tracker = null;
				mTextureStates.TryGetValue(key, out tracker);
				if (tracker == null) continue;

				EmitTextureBarriers(tracker, res.Texture, access.Subresource, requiredState, accessIsReadWrite);

				// Update tracker state for the accessed range
				tracker.SetState(access.Subresource, requiredState);

				// Update per-handle state (lossy for non-uniform, but only used for convenience queries)
				mResourceStates[resIdx] = requiredState;
			}
			else if (res.ResourceType == .Buffer && res.Buffer != null)
			{
				ResourceState currentState = .Undefined;
				mResourceStates.TryGetValue(resIdx, out currentState);

				if (currentState == requiredState)
					continue;

				var bufBarrier = BufferBarrier();
				bufBarrier.Buffer = res.Buffer;
				bufBarrier.OldState = currentState;
				bufBarrier.NewState = requiredState;
				mBufferBarriers.Add(bufBarrier);

				mResourceStates[resIdx] = requiredState;
			}
		}

		// Emit the barrier group
		if (mTextureBarriers.Count > 0 || mBufferBarriers.Count > 0)
		{
			var group = BarrierGroup();
			if (mTextureBarriers.Count > 0)
				group.TextureBarriers = Span<TextureBarrier>(mTextureBarriers.Ptr, mTextureBarriers.Count);
			if (mBufferBarriers.Count > 0)
				group.BufferBarriers = Span<BufferBarrier>(mBufferBarriers.Ptr, mBufferBarriers.Count);
			encoder.Barrier(group);
		}
	}

	/// Emit texture barriers for an access, handling uniform and non-uniform state.
	private void EmitTextureBarriers(SubresourceStateTracker tracker, ITexture texture,
		RGSubresourceRange subresource, ResourceState requiredState, bool accessIsReadWrite)
	{
		let totalMips = tracker.MipCount;
		let totalLayers = tracker.LayerCount;

		if (tracker.IsUniform)
		{
			// Fast path: all subresources in same state
			let currentState = tracker.UniformState;
			if (currentState == requiredState && !accessIsReadWrite)
				return;

			var barrier = TextureBarrier();
			barrier.Texture = texture;
			barrier.OldState = currentState;
			barrier.NewState = requiredState;

			// Apply subresource range if specified
			if (!subresource.IsAll)
			{
				barrier.BaseMipLevel = subresource.BaseMipLevel;
				barrier.MipLevelCount = subresource.MipLevelCount == 0 ? uint32.MaxValue : subresource.MipLevelCount;
				barrier.BaseArrayLayer = subresource.BaseArrayLayer;
				barrier.ArrayLayerCount = subresource.ArrayLayerCount == 0 ? uint32.MaxValue : subresource.ArrayLayerCount;
			}

			mTextureBarriers.Add(barrier);
		}
		else
		{
			// Non-uniform: emit per-subresource barriers for subresources that need transitioning
			let baseMip = subresource.BaseMipLevel;
			let mipEnd = (subresource.MipLevelCount == 0) ? totalMips : Math.Min(baseMip + subresource.MipLevelCount, totalMips);
			let baseLayer = subresource.BaseArrayLayer;
			let layerEnd = (subresource.ArrayLayerCount == 0) ? totalLayers : Math.Min(baseLayer + subresource.ArrayLayerCount, totalLayers);

			for (uint32 layer = baseLayer; layer < layerEnd; layer++)
			{
				for (uint32 mip = baseMip; mip < mipEnd; mip++)
				{
					let currentState = tracker.GetState(mip, layer);
					if (currentState == requiredState && !accessIsReadWrite)
						continue;

					var barrier = TextureBarrier();
					barrier.Texture = texture;
					barrier.OldState = currentState;
					barrier.NewState = requiredState;
					barrier.BaseMipLevel = mip;
					barrier.MipLevelCount = 1;
					barrier.BaseArrayLayer = layer;
					barrier.ArrayLayerCount = 1;
					mTextureBarriers.Add(barrier);
				}
			}
		}
	}

	/// Emit ShaderRead transitions for resources marked ReadableAfterWrite
	/// that were written by the given pass. Called after the pass executes.
	public void EmitReadableAfterWriteBarriers(RenderGraphPass pass, List<RenderGraphResource> resources, ICommandEncoder encoder)
	{
		mTextureBarriers.Clear();

		for (let access in pass.Accesses)
		{
			if (!access.IsWrite) continue;
			if (!access.Handle.IsValid) continue;
			let resIdx = (int32)access.Handle.Index;
			if (resIdx >= resources.Count) continue;

			let res = resources[resIdx];
			if (res == null || !res.ReadableAfterWrite) continue;
			if (res.ResourceType != .Texture || res.Texture == null) continue;

			let key = TextureKey(res.Texture);
			SubresourceStateTracker tracker = null;
			mTextureStates.TryGetValue(key, out tracker);
			if (tracker == null) continue;

			// Transition the written subresource range to ShaderRead
			EmitTextureBarriers(tracker, res.Texture, access.Subresource, .ShaderRead, false);
			tracker.SetState(access.Subresource, .ShaderRead);
			mResourceStates[resIdx] = .ShaderRead;
		}

		if (mTextureBarriers.Count > 0)
		{
			var group = BarrierGroup();
			group.TextureBarriers = Span<TextureBarrier>(mTextureBarriers.Ptr, mTextureBarriers.Count);
			encoder.Barrier(group);
		}
	}

	/// Emit final-state transitions for imported resources
	public void EmitFinalTransitions(List<RenderGraphResource> resources, ICommandEncoder encoder)
	{
		mTextureBarriers.Clear();

		for (int32 i = 0; i < (int32)resources.Count; i++)
		{
			let res = resources[i];
			if (res == null) continue;
			if (!res.FinalState.HasValue) continue;

			let finalState = res.FinalState.Value;

			if (res.Texture != null)
			{
				let key = TextureKey(res.Texture);
				SubresourceStateTracker tracker = null;
				mTextureStates.TryGetValue(key, out tracker);
				if (tracker == null) continue;

				// Transition all subresources to final state
				EmitTextureBarriers(tracker, res.Texture, .All, finalState, false);
				tracker.SetAll(finalState);
				mResourceStates[i] = finalState;
			}
		}

		if (mTextureBarriers.Count > 0)
		{
			var group = BarrierGroup();
			group.TextureBarriers = Span<TextureBarrier>(mTextureBarriers.Ptr, mTextureBarriers.Count);
			encoder.Barrier(group);
		}
	}

	/// Update persistent resource states after execution
	public void UpdatePersistentStates(List<RenderGraphResource> resources)
	{
		for (int32 i = 0; i < (int32)resources.Count; i++)
		{
			let res = resources[i];
			if (res == null) continue;

			// For textures, read back from the per-subresource tracker
			if (res.ResourceType == .Texture && res.Texture != null)
			{
				let key = TextureKey(res.Texture);
				if (mTextureStates.TryGetValue(key, let tracker))
				{
					if (tracker.IsUniform)
					{
						res.LastKnownState = tracker.UniformState;
						if (res.PersistentData != null)
						{
							res.PersistentData.LastKnownState = tracker.UniformState;
							res.PersistentData.FirstFrame = false;
							// Clear per-subresource state since we're uniform
							DeleteAndNullify!(res.PersistentData.SubresourceStates);
						}
					}
					else
					{
						// Non-uniform: store per-subresource states for next frame
						res.LastKnownState = tracker.GetState(0, 0);
						if (res.PersistentData != null)
						{
							res.PersistentData.LastKnownState = tracker.GetState(0, 0);
							res.PersistentData.FirstFrame = false;
							// Save per-subresource state array
							delete res.PersistentData.SubresourceStates;
							res.PersistentData.SubresourceStates = tracker.CopyStates();
						}
					}
				}
			}
			else if (mResourceStates.TryGetValue(i, let state))
			{
				res.LastKnownState = state;

				if (res.PersistentData != null)
				{
					res.PersistentData.LastKnownState = state;
					res.PersistentData.FirstFrame = false;
				}
			}
		}
	}

	/// Get the current tracked state for a resource (whole-resource, lossy for non-uniform textures)
	public ResourceState GetState(int32 resourceIndex)
	{
		ResourceState state = .Undefined;
		mResourceStates.TryGetValue(resourceIndex, out state);
		return state;
	}

	/// Get the current tracked state for a texture by its ITexture identity.
	/// Returns the uniform state, or the state of subresource (0,0) if non-uniform.
	public ResourceState GetTextureState(ITexture texture)
	{
		if (texture == null) return .Undefined;
		if (mTextureStates.TryGetValue(TextureKey(texture), let tracker))
			return tracker.IsUniform ? tracker.UniformState : tracker.GetState(0, 0);
		return .Undefined;
	}

	/// Get the per-subresource state tracker for a texture. Returns null if not tracked.
	public SubresourceStateTracker GetTextureTracker(ITexture texture)
	{
		if (texture == null) return null;
		SubresourceStateTracker tracker = null;
		mTextureStates.TryGetValue(TextureKey(texture), out tracker);
		return tracker;
	}
}
