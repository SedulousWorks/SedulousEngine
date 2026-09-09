using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RenderGraph;

/// Works out and emits the barriers between passes.
///
/// State is tracked at TWO levels. Per resource handle, which is what a buffer needs and what
/// a texture's convenience answers come from; and per GPU TEXTURE with subresource
/// granularity, which is the source of truth. The texture level is keyed on the texture
/// itself rather than on the handle, so two handles that ended up backed by the same texture,
/// which pooling and aliasing both produce, agree about its state instead of each barriering
/// it out from under the other.
class BarrierSolver
{
	private const uint32 cAllRemaining = 0xFFFFFFFF;

	private Dictionary<int32, ResourceState> mResourceStates = new .() ~ delete _;
	/// Keyed by the texture's ADDRESS: Beef wants a hashable key and an interface is not one,
	/// and identity is exactly what this needs anyway. Nothing outlives the frame's Reset, so
	/// there is no reuse of a freed address to confuse it.
	private Dictionary<int, SubresourceStateTracker> mTextureStates = new .() ~ delete _;
	private List<TextureBarrier> mTextureBarriers = new .() ~ delete _;
	private List<BufferBarrier> mBufferBarriers = new .() ~ delete _;

	public ~this()
	{
		ClearTrackers();
	}

	/// Starts a frame's tracking from the resource list.
	///
	/// A persistent resource resumes from what it ended the last frame in; an imported one
	/// from whatever its owner says; and a transient one from UNDEFINED, always, so its first
	/// access is a real transition rather than a silent assumption about a pooled texture's
	/// contents.
	public void Reset(Span<RenderGraphResource> resources)
	{
		mResourceStates.Clear();
		ClearTrackers();

		for (int32 i = 0; i < (int32)resources.Length; i++)
		{
			let resource = resources[i];
			if (resource == null)
				continue;

			var initialState = ResourceState.Undefined;
			if ((resource.Lifetime == .Persistent) && (resource.PersistentData != null))
			{
				initialState = resource.PersistentData.FirstFrame
					? ((resource.Texture != null) ? resource.Texture.InitialState : .Undefined)
					: resource.PersistentData.LastKnownState;
			}
			else if (resource.Lifetime == .Imported)
			{
				initialState = resource.LastKnownState;
			}

			mResourceStates[i] = initialState;

			if ((resource.ResourceType != .Texture) || (resource.Texture == null))
				continue;

			if (mTextureStates.TryGetValue(KeyOf(resource.Texture), let existing))
			{
				// The SAME GPU texture through another handle, so the two unify rather than
				// tracking it twice and disagreeing.
				if ((initialState == .Undefined) && existing.IsUniform
					&& (existing.UniformState != .Undefined))
					mResourceStates[i] = existing.UniformState;
				else if (initialState != .Undefined)
					existing.SetAll(initialState);

				continue;
			}

			let tracker = new SubresourceStateTracker(resource.Texture.Desc.MipLevelCount,
				resource.Texture.Desc.ArrayLayerCount, initialState);

			// A persistent resource that ended the last frame with its subresources
			// disagreeing resumes exactly that, rather than being flattened to one state it
			// was never in.
			if ((resource.Lifetime == .Persistent) && (resource.PersistentData != null)
				&& !resource.PersistentData.FirstFrame
				&& !resource.PersistentData.SubresourceStates.IsEmpty)
				tracker.InitFromStates(resource.PersistentData.SubresourceStates, initialState);

			mTextureStates[KeyOf(resource.Texture)] = tracker;
		}
	}

	/// The barriers a pass needs BEFORE it runs.
	public void EmitBarriers(RenderGraphPass pass, Span<RenderGraphResource> resources,
		ICommandEncoder encoder)
	{
		mTextureBarriers.Clear();
		mBufferBarriers.Clear();

		for (let access in pass.Accesses)
		{
			if (!access.Handle.IsValid)
				continue;

			let index = (int32)access.Handle.Index;
			if (index >= (int32)resources.Length)
				continue;

			let resource = resources[index];
			if (resource == null)
				continue;

			let requiredState = access.ToResourceState();
			// A read write access barriers even when the state already matches: the hazard is
			// between the two uses of it, not between two states.
			let isReadWrite = access.IsRead && access.IsWrite;

			if ((resource.ResourceType == .Texture) && (resource.Texture != null))
			{
				if (!mTextureStates.TryGetValue(KeyOf(resource.Texture), let tracker))
					continue;

				EmitTextureBarriers(tracker, resource.Texture, access.Subresource, requiredState,
					isReadWrite);
				tracker.SetState(access.Subresource, requiredState);
				mResourceStates[index] = requiredState;
			}
			else if ((resource.ResourceType == .Buffer) && (resource.Buffer != null))
			{
				var currentState = ResourceState.Undefined;
				if (mResourceStates.TryGetValue(index, let stored))
					currentState = stored;

				if (currentState == requiredState)
					continue;

				var barrier = BufferBarrier();
				barrier.Buffer = resource.Buffer;
				barrier.OldState = currentState;
				barrier.NewState = requiredState;
				mBufferBarriers.Add(barrier);

				mResourceStates[index] = requiredState;
			}
		}

		FlushBarriers(encoder);
	}

	/// After a pass runs, moves whatever it wrote and was marked readable into a shader read,
	/// so a bind group OUTSIDE the graph can sample it without the caller knowing what state
	/// the graph happened to leave it in.
	public void EmitReadableAfterWriteBarriers(RenderGraphPass pass,
		Span<RenderGraphResource> resources, ICommandEncoder encoder)
	{
		mTextureBarriers.Clear();
		mBufferBarriers.Clear();

		for (let access in pass.Accesses)
		{
			if (!access.IsWrite || !access.Handle.IsValid)
				continue;

			let index = (int32)access.Handle.Index;
			if (index >= (int32)resources.Length)
				continue;

			let resource = resources[index];
			if ((resource == null) || !resource.ReadableAfterWrite)
				continue;
			if ((resource.ResourceType != .Texture) || (resource.Texture == null))
				continue;

			if (!mTextureStates.TryGetValue(KeyOf(resource.Texture), let tracker))
				continue;

			EmitTextureBarriers(tracker, resource.Texture, access.Subresource, .ShaderRead, false);
			tracker.SetState(access.Subresource, .ShaderRead);
			mResourceStates[index] = .ShaderRead;
		}

		FlushBarriers(encoder);
	}

	/// Moves whatever asked for a final state into it, which is how an imported resource is
	/// handed back to its owner in the state that owner expects.
	public void EmitFinalTransitions(Span<RenderGraphResource> resources, ICommandEncoder encoder)
	{
		mTextureBarriers.Clear();
		mBufferBarriers.Clear();

		for (int32 i = 0; i < (int32)resources.Length; i++)
		{
			let resource = resources[i];
			if ((resource == null) || (resource.FinalState == null))
				continue;

			let finalState = resource.FinalState.Value;
			if (resource.Texture == null)
				continue;

			if (!mTextureStates.TryGetValue(KeyOf(resource.Texture), let tracker))
				continue;

			EmitTextureBarriers(tracker, resource.Texture, .All, finalState, false);
			tracker.SetAll(finalState);
			mResourceStates[i] = finalState;
		}

		FlushBarriers(encoder);
	}

	/// Writes what was tracked back onto the resources, so the next frame resumes rather than
	/// rediscovering.
	public void UpdatePersistentStates(Span<RenderGraphResource> resources)
	{
		for (int32 i = 0; i < (int32)resources.Length; i++)
		{
			let resource = resources[i];
			if (resource == null)
				continue;

			if ((resource.ResourceType == .Texture) && (resource.Texture != null))
			{
				if (!mTextureStates.TryGetValue(KeyOf(resource.Texture), let tracker))
					continue;

				if (tracker.IsUniform)
				{
					resource.LastKnownState = tracker.UniformState;
					if (resource.PersistentData != null)
					{
						resource.PersistentData.LastKnownState = tracker.UniformState;
						resource.PersistentData.FirstFrame = false;
						resource.PersistentData.SubresourceStates.Clear();
					}
					continue;
				}

				// Diverged, so the single state is only the first subresource's and the whole
				// picture has to be carried over.
				resource.LastKnownState = tracker.GetState(0, 0);
				if (resource.PersistentData != null)
				{
					resource.PersistentData.LastKnownState = tracker.GetState(0, 0);
					resource.PersistentData.FirstFrame = false;
					tracker.CopyStates(resource.PersistentData.SubresourceStates);
				}
			}
			else if (mResourceStates.TryGetValue(i, let state))
			{
				resource.LastKnownState = state;
				if (resource.PersistentData != null)
				{
					resource.PersistentData.LastKnownState = state;
					resource.PersistentData.FirstFrame = false;
				}
			}
		}
	}

	public ResourceState GetState(int32 resourceIndex)
	{
		if (mResourceStates.TryGetValue(resourceIndex, let state))
			return state;
		return .Undefined;
	}

	public ResourceState GetTextureState(ITexture texture)
	{
		if (texture == null)
			return .Undefined;

		if (mTextureStates.TryGetValue(KeyOf(texture), let tracker))
			return tracker.IsUniform ? tracker.UniformState : tracker.GetState(0, 0);
		return .Undefined;
	}

	/// The tracker itself, for a caller that needs the whole subresource picture. BORROWED.
	public SubresourceStateTracker GetTextureTracker(ITexture texture)
	{
		if (texture == null)
			return null;

		if (mTextureStates.TryGetValue(KeyOf(texture), let tracker))
			return tracker;
		return null;
	}

	/// One barrier for the whole range while the tracker is uniform, and one per subresource
	/// once it is not: a uniform texture is the common case, and splitting it would emit
	/// dozens of identical barriers for a mip chain nothing has touched separately.
	private void EmitTextureBarriers(SubresourceStateTracker tracker, ITexture texture,
		RGSubresourceRange subresource, ResourceState requiredState, bool accessIsReadWrite)
	{
		let totalMips = tracker.MipCount;
		let totalLayers = tracker.LayerCount;

		if (tracker.IsUniform)
		{
			let currentState = tracker.UniformState;
			if ((currentState == requiredState) && !accessIsReadWrite)
				return;

			var barrier = TextureBarrier();
			barrier.Texture = texture;
			barrier.OldState = currentState;
			barrier.NewState = requiredState;
			if (!subresource.IsAll)
			{
				barrier.BaseMipLevel = subresource.BaseMipLevel;
				barrier.MipLevelCount = (subresource.MipLevelCount == 0)
					? cAllRemaining : subresource.MipLevelCount;
				barrier.BaseArrayLayer = subresource.BaseArrayLayer;
				barrier.ArrayLayerCount = (subresource.ArrayLayerCount == 0)
					? cAllRemaining : subresource.ArrayLayerCount;
			}
			mTextureBarriers.Add(barrier);
			return;
		}

		let baseMip = subresource.BaseMipLevel;
		let mipEnd = (subresource.MipLevelCount == 0)
			? totalMips : Min(baseMip + subresource.MipLevelCount, totalMips);
		let baseLayer = subresource.BaseArrayLayer;
		let layerEnd = (subresource.ArrayLayerCount == 0)
			? totalLayers : Min(baseLayer + subresource.ArrayLayerCount, totalLayers);

		for (uint32 layer = baseLayer; layer < layerEnd; layer++)
		{
			for (uint32 mip = baseMip; mip < mipEnd; mip++)
			{
				let currentState = tracker.GetState(mip, layer);
				if ((currentState == requiredState) && !accessIsReadWrite)
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

	/// ONE group per emit point, because a barrier is a pipeline stall and several groups
	/// where one would do stalls several times.
	private void FlushBarriers(ICommandEncoder encoder)
	{
		if (mTextureBarriers.IsEmpty && mBufferBarriers.IsEmpty)
			return;

		var group = BarrierGroup();
		if (!mTextureBarriers.IsEmpty)
			group.TextureBarriers = .(mTextureBarriers.Ptr, mTextureBarriers.Count);
		if (!mBufferBarriers.IsEmpty)
			group.BufferBarriers = .(mBufferBarriers.Ptr, mBufferBarriers.Count);

		encoder.Barrier(group);
	}

	private static int KeyOf(ITexture texture) => (int)(void*)Internal.UnsafeCastToPtr(texture);

	private void ClearTrackers()
	{
		for (let tracker in mTextureStates.Values)
			delete tracker;
		mTextureStates.Clear();
	}
}
