namespace Sedulous.Engine.Animation;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;
using Sedulous.Resources;
using Sedulous.Animation.Resources;

/// Owns animation resource managers (skeleton, clip, graph, property animation)
/// and the shared PropertyBinderRegistry.
/// Per-scene animation state is managed by component managers injected via ISceneAware.
class AnimationSubsystem : Subsystem, ISceneAware
{
	private SkeletonResourceManager mSkeletonManager ~ delete _;
	private AnimationClipResourceManager mAnimClipManager ~ delete _;
	private AnimationGraphResourceManager mAnimGraphManager ~ delete _;
	private PropertyAnimationClipResourceManager mPropertyAnimManager ~ delete _;

	/// Shared property binder registry (maps property paths to setter delegates).
	/// Game code can register custom bindings via this registry.
	private PropertyBinderRegistry mPropertyBinderRegistry ~ delete _;

	/// Gets the property binder registry for registering custom property bindings.
	public PropertyBinderRegistry PropertyBinderRegistry => mPropertyBinderRegistry;

	public override int32 UpdateOrder => 100;

	protected override void OnInit()
	{
		mSkeletonManager = new SkeletonResourceManager();
		mAnimClipManager = new AnimationClipResourceManager();
		mAnimGraphManager = new AnimationGraphResourceManager();
		mPropertyAnimManager = new PropertyAnimationClipResourceManager();
		mPropertyBinderRegistry = new PropertyBinderRegistry();

		Context.Resources.AddResourceManager(mSkeletonManager);
		Context.Resources.AddResourceManager(mAnimClipManager);
		Context.Resources.AddResourceManager(mAnimGraphManager);
		Context.Resources.AddResourceManager(mPropertyAnimManager);
	}

	protected override void OnShutdown()
	{
		if (mSkeletonManager != null)
			Context.Resources.RemoveResourceManager(mSkeletonManager);
		if (mAnimClipManager != null)
			Context.Resources.RemoveResourceManager(mAnimClipManager);
		if (mAnimGraphManager != null)
			Context.Resources.RemoveResourceManager(mAnimGraphManager);
		if (mPropertyAnimManager != null)
			Context.Resources.RemoveResourceManager(mPropertyAnimManager);
	}

	public void OnSceneCreated(Scene scene)
	{
		// Inject skeletal animation component manager
		let skelAnimMgr = new SkeletalAnimationComponentManager();
		skelAnimMgr.ResourceSystem = Context.Resources;
		scene.AddModule(skelAnimMgr);

		// Inject animation graph component manager
		let graphAnimMgr = new AnimationGraphComponentManager();
		graphAnimMgr.ResourceSystem = Context.Resources;
		scene.AddModule(graphAnimMgr);

		// Inject property animation component manager
		let propAnimMgr = new PropertyAnimationComponentManager();
		propAnimMgr.ResourceSystem = Context.Resources;
		propAnimMgr.BinderRegistry = mPropertyBinderRegistry;
		scene.AddModule(propAnimMgr);
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}
}
