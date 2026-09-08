namespace Sedulous.Scene.Tests;

/// Records the delta its variable lane saw and how many fixed steps ran, which is how the
/// composed time chain is checked at the far end rather than at the near one.
class DeltaProbeSystem : SceneSystem
{
	public float LastUpdate = 0.0f;
	public uint32 FixedSteps = 0;

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase == .Update)
			LastUpdate = deltaTime;
	}

	public override void OnFixedUpdate(float fixedDeltaTime) { FixedSteps++; }
}
