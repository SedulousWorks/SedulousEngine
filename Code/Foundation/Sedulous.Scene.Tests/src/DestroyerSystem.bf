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

/// Destroys its target from inside the fixed step, and records whether the target was still
/// valid right after the call and when the step's later systems ran.
class FixedDestroyerSystem : SceneSystem
{
	private Scene mScene = null;

	public EntityHandle Target = .Invalid;
	public bool TargetValidAfterDestroy = false;
	/// Whether the target was valid when the frame's Update phase reached this system.
	public bool TargetValidInUpdate = false;

	public override void OnSceneCreate(Scene scene) => mScene = scene;

	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		mScene.DestroyEntity(Target);
		TargetValidAfterDestroy = mScene.IsValid(Target);
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if (phase == .Update)
			TargetValidInUpdate = mScene.IsValid(Target);
	}
}
