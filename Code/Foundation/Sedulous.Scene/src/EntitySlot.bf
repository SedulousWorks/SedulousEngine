using System;

namespace Sedulous.Scene;

/// One slot in the entity table.
///
/// A slot OUTLIVES the entity in it: destroying an entity clears the slot and puts its
/// index on the free list, and the generation counter is what tells a handle to the old
/// occupant from one to the new.
class EntitySlot
{
	public uint32 Generation = 0;
	public bool Active = false;
	/// CACHED: this entity's own flag and every ancestor's. Recomputed at the choke points
	/// that can change it, so reading it is O(1).
	public bool EffectiveActive = false;
	public bool Alive = false;
	public Guid PersistentId = .();
	public String Name = new .() ~ delete _;

	/// Back to the state a fresh slot is in, keeping the generation, which must only ever
	/// go forward.
	public void Reset()
	{
		Active = false;
		EffectiveActive = false;
		Alive = false;
		PersistentId = .();
		Name.Clear();
	}
}
