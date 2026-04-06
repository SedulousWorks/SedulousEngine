using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Computes and emits resource barriers between render graph passes.
/// Tracks state at two levels:
/// - Per-resource-handle (fast lookup for the common case)
/// - Per-ITexture (source of truth when multiple handles reference the same GPU texture)
public class BarrierSolver
{
	/// Identity key for ITexture — hashes by object pointer so the same
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

	/// Per-resource-handle tracked state (kept in sync with texture-level state)
	private Dictionary<int32, ResourceState> mResourceStates = new .() ~ delete _;
	/// Per-ITexture tracked state — source of truth for actual GPU layout
	private Dictionary<TextureKey, ResourceState> mTextureStates = new .() ~ delete _;
	/// Temporary barrier lists to avoid per-pass allocation
	private List<TextureBarrier> mTextureBarriers = new .() ~ delete _;
	private List<BufferBarrier> mBufferBarriers = new .() ~ delete _;

	/// Initialize resource states from the resource list.
	/// Persistent resources use their LastKnownState; transient resources start from InitialState.
	/// When multiple handles reference the same ITexture, they share one state entry.
	public void Reset(List<RenderGraphResource> resources)
	{
		mResourceStates.Clear();
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
				// Transient resources start from their initial state after allocation
				if (res.Texture != null)
					initialState = res.Texture.InitialState;
			}

			mResourceStates[i] = initialState;

			// For textures, also register in the ITexture-keyed dictionary.
			// If the same ITexture was already registered by another handle,
			// use whichever state is more recent (non-Undefined preferred).
			if (res.ResourceType == .Texture && res.Texture != null)
			{
				let key = TextureKey(res.Texture);
				if (mTextureStates.TryGetValue(key, let existingState))
				{
					// Same GPU texture seen from another handle — unify state.
					// Prefer the existing tracked state if our handle says Undefined.
					if (initialState == .Undefined && existingState != .Undefined)
						mResourceStates[i] = existingState;
					else
						mTextureStates[key] = initialState;
				}
				else
				{
					mTextureStates[key] = initialState;
				}
			}
		}
	}

	/// Emit barriers needed before executing the given pass.
	/// State lookups use the ITexture-keyed dictionary so that when two handles
	/// reference the same GPU texture, a state change through one is visible to the other.
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
				// Look up current state by ITexture (source of truth)
				let key = TextureKey(res.Texture);
				ResourceState currentState = .Undefined;
				mTextureStates.TryGetValue(key, out currentState);

				// Skip if same state, UNLESS this is a read+write access that needs
				// previous writes to be visible (e.g., depth Load+Store after depth Clear+Store)
				if (currentState == requiredState && !accessIsReadWrite)
					continue;

				var barrier = TextureBarrier();
				barrier.Texture = res.Texture;
				barrier.OldState = currentState;
				barrier.NewState = requiredState;

				// Apply subresource range if specified
				if (!access.Subresource.IsAll)
				{
					barrier.BaseMipLevel = access.Subresource.BaseMipLevel;
					barrier.MipLevelCount = access.Subresource.MipLevelCount == 0 ? uint32.MaxValue : access.Subresource.MipLevelCount;
					barrier.BaseArrayLayer = access.Subresource.BaseArrayLayer;
					barrier.ArrayLayerCount = access.Subresource.ArrayLayerCount == 0 ? uint32.MaxValue : access.Subresource.ArrayLayerCount;
				}

				mTextureBarriers.Add(barrier);

				// Update both tracking levels
				mTextureStates[key] = requiredState;
				mResourceStates[resIdx] = requiredState;
			}
			else if (res.ResourceType == .Buffer && res.Buffer != null)
			{
				ResourceState currentState = .Undefined;
				mResourceStates.TryGetValue(resIdx, out currentState);

				if (currentState == requiredState)
					continue;

				var barrier = BufferBarrier();
				barrier.Buffer = res.Buffer;
				barrier.OldState = currentState;
				barrier.NewState = requiredState;
				mBufferBarriers.Add(barrier);

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
			ResourceState currentState = .Undefined;
			mTextureStates.TryGetValue(key, out currentState);

			if (currentState == .ShaderRead)
				continue;

			var barrier = TextureBarrier();
			barrier.Texture = res.Texture;
			barrier.OldState = currentState;
			barrier.NewState = .ShaderRead;
			mTextureBarriers.Add(barrier);

			mTextureStates[key] = .ShaderRead;
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
				// Use ITexture-keyed state for current state
				let key = TextureKey(res.Texture);
				ResourceState currentState = .Undefined;
				mTextureStates.TryGetValue(key, out currentState);

				if (currentState == finalState)
					continue;

				var barrier = TextureBarrier();
				barrier.Texture = res.Texture;
				barrier.OldState = currentState;
				barrier.NewState = finalState;
				mTextureBarriers.Add(barrier);

				mTextureStates[key] = finalState;
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

			// For textures, read back from the ITexture-keyed state
			if (res.ResourceType == .Texture && res.Texture != null)
			{
				let key = TextureKey(res.Texture);
				if (mTextureStates.TryGetValue(key, let state))
				{
					res.LastKnownState = state;

					if (res.PersistentData != null)
					{
						res.PersistentData.LastKnownState = state;
						res.PersistentData.FirstFrame = false;
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

	/// Get the current tracked state for a resource
	public ResourceState GetState(int32 resourceIndex)
	{
		ResourceState state = .Undefined;
		mResourceStates.TryGetValue(resourceIndex, out state);
		return state;
	}

	/// Get the current tracked state for a texture by its ITexture identity
	public ResourceState GetTextureState(ITexture texture)
	{
		if (texture == null) return .Undefined;
		ResourceState state = .Undefined;
		mTextureStates.TryGetValue(TextureKey(texture), out state);
		return state;
	}
}
