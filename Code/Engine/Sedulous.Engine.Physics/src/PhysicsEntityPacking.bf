using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// Packing an entity handle into a body's user word, and back.
///
/// The whole handle rides, index and generation both, so the reverse map is LOSSLESS. An
/// identity's low bits would not be: two entities can share them, and a contact would then
/// name the wrong one.
static class PhysicsEntityPacking
{
	public static uint64 PackEntity(EntityHandle entity)
		=> ((uint64)entity.Index << 32) | (uint64)entity.Generation;

	public static EntityHandle UnpackEntity(uint64 value)
		=> .((uint32)(value >> 32), (uint32)(value & 0xFFFFFFFF));
}
