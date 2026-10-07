using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Render;

/// What a bind group was built from: each view it binds that can change between frames, with
/// the view's unique id and its texture's generation, and the one buffer it binds that can (a
/// scene's sky lighting, with its context's generation; none by default).
///
/// A group is only still right while EVERY view it binds is the same view of the same texture:
/// the render graph's pool hands transients out per frame, a pooled view can come back over
/// another texture (its generation tells), and a destroyed view's address can be handed to the
/// next one (its unique id tells). A cache that checked only some of its inputs kept another
/// frame's bound: TAA kept frame 0's motion vectors behind one of its two history textures,
/// and the player's edges flickered every other frame.
struct BindGroupInputs<TCount> where TCount : const int
{
	public ITextureView[TCount] Views = default;
	public uint64[TCount] Ids = default;
	public uint64[TCount] Generations = default;
	public IBuffer Buffer = null;
	public uint64 BufferGeneration = 0;

	public this()
	{
	}

	public void Set(int slot, ITextureView view, uint64 generation) mut
	{
		Views[slot] = view;
		Ids[slot] = (view != null) ? view.UniqueId : 0;
		Generations[slot] = generation;
	}

	/// The buffer a group binds that can change between frames. Two views of different scenes
	/// take turns on one history texture, so a group built with another scene's sky must miss.
	public void SetBuffer(IBuffer buffer, uint64 generation) mut
	{
		Buffer = buffer;
		BufferGeneration = generation;
	}

	/// No group can be built while an input is missing.
	public bool Complete
	{
		get
		{
			for (int i < TCount)
			{
				if (Views[i] == null)
					return false;
			}
			return true;
		}
	}

	public bool Matches(Self other)
	{
		if ((Buffer != other.Buffer) || (BufferGeneration != other.BufferGeneration))
			return false;
		for (int i < TCount)
		{
			if ((Views[i] != other.Views[i]) || (Ids[i] != other.Ids[i])
				|| (Generations[i] != other.Generations[i]))
				return false;
		}
		return true;
	}
}

/// Bind groups keyed by the view that selects one (a history texture, an input stable per
/// size), each remembering the inputs it was built from. A hit needs the key to be the same
/// view (its unique id) and every input to match.
class BindGroupCache<TCount> where TCount : const int
{
	private struct Entry
	{
		public IBindGroup BindGroup;
		public uint64 KeyId;
		public BindGroupInputs<TCount> Inputs;
	}

	private Dictionary<int, Entry> mEntries = new .() ~ delete _;

	private static int KeyOf(ITextureView key) => (int)(void*)Internal.UnsafeCastToPtr(key);

	/// The group built for `key` from exactly `inputs`, or null. A group built for `key` from
	/// anything else is forgotten and handed back in `stale` for the caller to destroy.
	public IBindGroup Find(ITextureView key, BindGroupInputs<TCount> inputs, out IBindGroup stale)
	{
		stale = null;
		if (key == null)
			return null;
		let slot = KeyOf(key);
		if (!mEntries.TryGetValue(slot, let entry))
			return null;
		if ((entry.BindGroup != null) && (entry.KeyId == key.UniqueId) && entry.Inputs.Matches(inputs))
			return entry.BindGroup;
		stale = entry.BindGroup;
		mEntries.Remove(slot);
		return null;
	}

	public void Store(ITextureView key, BindGroupInputs<TCount> inputs, IBindGroup bindGroup)
	{
		var entry = Entry();
		entry.BindGroup = bindGroup;
		entry.KeyId = key.UniqueId;
		entry.Inputs = inputs;
		mEntries[KeyOf(key)] = entry;
	}

	/// Every group still held, handed to `destroy`, and the cache emptied.
	public void Release(delegate void(IBindGroup) destroy)
	{
		for (let entry in mEntries.Values)
		{
			if (entry.BindGroup != null)
				destroy(entry.BindGroup);
		}
		mEntries.Clear();
	}

	public int Count => mEntries.Count;
}
