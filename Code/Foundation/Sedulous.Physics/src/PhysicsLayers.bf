using joltc_Beef;

namespace Sedulous.Physics;

/// How a semantic layer and a designer group are folded into ONE backend layer.
///
/// The encoding is DENSE, semantic times the group count plus the group, because the
/// backend's pair filter is a table indexed by layer rather than a function: a sparse
/// encoding would be a table of mostly nothing.
///
/// The rules are the semantic ones first and the group matrix second, and a pair has to
/// pass both.
static class PhysicsLayers
{
	public const uint32 GroupCount = 32;
	/// A character's inner body: not a layer a body is authored on. Queries and moving bodies meet
	/// it; statics, triggers and other characters do not (the character itself stands on statics,
	/// senses triggers and meets other characters directly).
	public const PhysicsLayer Character = (PhysicsLayer)PhysicsLayer.Count;
	/// The four authored semantics and the character's, times thirty two groups.
	public const uint32 Count = (uint32)(PhysicsLayer.Count + 1) * GroupCount;

	public const uint32 BroadPhaseStatic = 0;
	public const uint32 BroadPhaseMoving = 1;
	public const uint32 BroadPhaseCount = 2;

	public static JPH_ObjectLayer From(PhysicsLayer layer, uint8 group) =>
		(JPH_ObjectLayer)(((uint32)layer * GroupCount) + ((uint32)group & (GroupCount - 1)));

	public static PhysicsLayer Semantic(JPH_ObjectLayer layer) =>
		(PhysicsLayer)((uint32)layer / GroupCount);

	public static uint32 Group(JPH_ObjectLayer layer) => (uint32)layer % GroupCount;

	/// The semantic rules: two statics never pair, since neither can move into the other; a
	/// trigger senses only what MOVES, so neither another trigger nor a static; everything
	/// else collides.
	public static bool SemanticCollides(PhysicsLayer a, PhysicsLayer b)
	{
		if ((a == Character) || (b == Character))
		{
			let other = (a == Character) ? b : a;
			return (other != .Static) && (other != .Trigger) && (other != Character);
		}
		if ((a == .Static) && (b == .Static))
			return false;
		if ((a == .Trigger) && (b == .Trigger))
			return false;
		if (((a == .Trigger) && (b == .Static)) || ((a == .Static) && (b == .Trigger)))
			return false;
		return true;
	}
}
