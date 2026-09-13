using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.GameInstance;

/// One async scene load in flight: the scene being built, and how far its resources have
/// got.
///
/// A VALUE, so a caller can hold one in a list beside a ticket. The scene it names is
/// created INACTIVE and never ticks or draws until the load completes and the instance
/// activates it.
///
/// LIMITATION, carried over as found: the progress polls the manager's WHOLE pending count,
/// and the total snapshots that same global number. Two overlapping loads, or any unrelated
/// async bind in flight, conflate: each handle then waits on ALL of the pending work, which
/// is the safe direction, and its progress distorts. Fine for a boot and a level switch;
/// overlapping or background loads need per batch tracking, which the resource layer's own
/// load batch already does.
struct SceneLoadHandle
{
	/// BORROWED: the instance's scene group owns it, and drops any handle naming a scene it
	/// destroys.
	public Scene Scene = null;
	/// BORROWED: the caller's manager, which is what the progress is measured against.
	public ResourceManager Resources = null;
	/// What was pending the moment every bind had been issued, which is the denominator.
	public int Total = 0;
	public bool Failed = false;

	public this() {}

	public bool IsComplete => Failed || (Resources == null) || (Resources.PendingCount == 0);

	/// Nought to one, and one once complete or failed.
	public float Progress
	{
		get
		{
			if (Failed || (Resources == null) || (Total == 0))
				return 1.0f;

			let remaining = Resources.PendingCount;
			if (remaining == 0)
				return 1.0f;

			let done = (remaining >= Total) ? 0 : (Total - remaining);
			return (float)done / (float)Total;
		}
	}
}
