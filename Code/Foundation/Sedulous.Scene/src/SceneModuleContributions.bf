using System;
using System.Collections;

namespace Sedulous.Scene;

/// The modules a game's native plugin contributes at RUNTIME.
///
/// Every instantiation appends the contributed modules after its own order, so the runtime
/// path and a headless tool see the same set, and scenes ALREADY ALIVE get them through
/// the live scene sink a driver installs.
///
/// Process wide, like the logger and the job system: a plugin loading has to reach the one
/// list every scene consults, and threading it through would mean threading it through
/// everything.
class SceneModuleContributions
{
	private static SceneModuleContributions sGlobal = new .() ~ delete _;

	private List<SceneModuleContribution> mContributions = new .() ~ delete _;

	/// Visits every live scene. A driver installs one over its registry; null means there
	/// are none, as in a headless tool.
	private delegate void(delegate void(Scene)) mLiveSceneSink = null;
	/// After a contribution installs into a LIVE scene: the owner's chance to resolve
	/// records that were preserved for it. A hook, because this layer knows nothing of
	/// resources.
	private delegate void(Scene) mLiveInstallHook = null;
	/// The recording hook a plugin host uses to reverse a load. Fires only on a real insert.
	private delegate void(uint64) mRegistrationObserver = null;

	public static SceneModuleContributions Global => sGlobal;

	public int Count => mContributions.Count;

	public bool Contains(uint64 systemType)
	{
		for (let contribution in mContributions)
		{
			if (contribution.SystemType == systemType)
				return true;
		}
		return false;
	}

	/// Adds a contribution, IDEMPOTENT by system type.
	///
	/// Applies to live scenes when a sink is installed, and fires the observer only when
	/// something was actually inserted.
	public void Add(SceneModuleContribution contribution)
	{
		if ((contribution.SystemType == 0) || (contribution.Install == null)
			|| Contains(contribution.SystemType))
			return;

		mContributions.Add(contribution);
		contribution.RegisterReflection?.Invoke();

		// A scene already alive gets the manager NOW, which is what makes opening a project
		// and hot reloading behave the same, and the owner then resolves any preserved
		// records of its type into it.
		if (mLiveSceneSink != null)
		{
			mLiveSceneSink(scope [&](scene) =>
			{
				contribution.Install(scene);
				if (mLiveInstallHook != null)
					mLiveInstallHook(scene);
			});
		}

		if (mRegistrationObserver != null)
			mRegistrationObserver(contribution.SystemType);
	}

	/// Removes from live scenes FIRST, so the manager dies while the code that built it is
	/// still mapped, and only then forgets the contribution.
	public void Remove(uint64 systemType)
	{
		for (int i = 0; i < mContributions.Count; i++)
		{
			if (mContributions[i].SystemType != systemType)
				continue;

			if (mLiveSceneSink != null)
				mLiveSceneSink(scope (scene) => { scene.RemoveSystem(systemType); });

			mContributions.RemoveAt(i);
			return;
		}
	}

	/// Appends every contribution's systems to `scene`: the tail of an instantiation.
	public void InstallAll(Scene scene)
	{
		for (let contribution in mContributions)
			contribution.Install(scene);
	}

	public void RegisterAllReflection()
	{
		for (let contribution in mContributions)
			contribution.RegisterReflection?.Invoke();
	}

	public void SetLiveSceneSink(delegate void(delegate void(Scene)) sink) => mLiveSceneSink = sink;
	public void SetLiveInstallHook(delegate void(Scene) hook) => mLiveInstallHook = hook;
	public void SetRegistrationObserver(delegate void(uint64) observer)
		=> mRegistrationObserver = observer;
}
