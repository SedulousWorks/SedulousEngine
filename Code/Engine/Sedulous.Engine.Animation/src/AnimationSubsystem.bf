namespace Sedulous.Engine.Animation;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;
using Sedulous.Resources;
using Sedulous.Animation.Resources;

/// Owns animation resource managers (skeleton, animation clip).
/// Per-scene animation state is managed by component managers injected via ISceneAware.
class AnimationSubsystem : Subsystem, ISceneAware
{
	private SkeletonResourceManager mSkeletonManager ~ delete _;
	private AnimationClipResourceManager mAnimClipManager ~ delete _;

	public override int32 UpdateOrder => 100;

	protected override void OnInit()
	{
		mSkeletonManager = new SkeletonResourceManager();
		mAnimClipManager = new AnimationClipResourceManager();

		Context.Resources.AddResourceManager(mSkeletonManager);
		Context.Resources.AddResourceManager(mAnimClipManager);
	}

	protected override void OnShutdown()
	{
		if (mSkeletonManager != null)
			Context.Resources.RemoveResourceManager(mSkeletonManager);
		if (mAnimClipManager != null)
			Context.Resources.RemoveResourceManager(mAnimClipManager);
	}

	public void OnSceneCreated(Scene scene)
	{
		// TODO: inject AnimationManager into scene
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}
}
