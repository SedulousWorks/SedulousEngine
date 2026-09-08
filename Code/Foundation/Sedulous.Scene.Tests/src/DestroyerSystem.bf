namespace Sedulous.Scene.Tests;

/// Destroys its target from inside the Update phase, which is the case deferred
/// destruction exists for.
class DestroyerSystem : SceneSystem
{
	private Scene mScene = null;

	public EntityHandle Target = .Invalid;
	public bool TargetWasValidDuringUpdate = false;

	public override void OnSceneCreate(Scene scene) => mScene = scene;

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase != .Update)
			return;
		TargetWasValidDuringUpdate = mScene.IsValid(Target);
		mScene.DestroyEntity(Target);
	}
}
