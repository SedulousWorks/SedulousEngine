namespace Sedulous.Scene.Tests;

/// A system that only runs while the simulation does, which is what edit mode gates.
class SimulationOnlySystem : SceneSystem
{
	public int Updates = 0;

	public override bool IsSimulationOnly => true;
	public override void OnUpdate(ScenePhase phase, float deltaTime) { Updates++; }
}
