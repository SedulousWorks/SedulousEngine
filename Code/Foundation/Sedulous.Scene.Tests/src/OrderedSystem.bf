using System.Collections;

namespace Sedulous.Scene.Tests;

/// Logs its own order when the Update phase runs, so the run order is observable.
class OrderedSystem : SceneSystem
{
	public int32 Order = 0;
	/// BORROWED: the test owns the log.
	public List<int32> Log = null;

	public override int32 UpdateOrder => Order;

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase == .Update)
			Log.Add(Order);
	}
}
