using System.Collections;

namespace Sedulous.Scene.Tests;

/// Records which phases and notifications it received, in order.
class RecordingSystem : SceneSystem
{
	public List<ScenePhase> Phases = new .() ~ delete _;
	public int Started = 0;
	public int Stopped = 0;
	public int EntitiesDestroyed = 0;
	public int ActiveChanges = 0;
	public int FixedUpdates = 0;

	public override void OnUpdate(ScenePhase phase, float deltaTime) => Phases.Add(phase);
	public override void OnFixedUpdate(float fixedDeltaTime) { FixedUpdates++; }
	public override void OnSceneStarted() { Started++; }
	public override void OnSceneStopped() { Stopped++; }
	public override void OnEntityDestroyed(EntityHandle entity) { EntitiesDestroyed++; }
	public override void OnEntityActiveChanged(EntityHandle entity, bool active) { ActiveChanges++; }
}
