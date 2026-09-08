using System;
using System.Collections;

namespace Sedulous.Scene;

/// The pure scene state: the composition, the observers, the registered managers, and the
/// sweeps across all of them.
///
/// No subsystem, no context, nothing from the runtime layer. A thin driver owns one of
/// these and fans its frame lanes over it, which is what makes the whole arrangement
/// testable with nothing but scenes.
class SceneRegistry
{
	private SceneComposition mComposition = null ~ delete _;
	/// BORROWED: a page or an instance owns its manager.
	private List<SceneManager> mManagers = new .() ~ delete _;
	/// Sorted by Order within a stage.
	private List<SceneObserverEntry> mObservers = new .() ~ delete _;

	// ---- composition ----

	/// Takes ownership of the composition.
	public void SetComposition(SceneComposition composition)
	{
		if (mComposition === composition)
			return;
		delete mComposition;
		mComposition = composition;
	}

	public SceneComposition Composition => mComposition;

	public void RegisterReflection()
	{
		if (mComposition != null)
			mComposition.RegisterReflection();
	}

	// ---- observers ----

	/// Registers `observer` for one stage. IDEMPOTENT per observer and stage: registering
	/// the same pair twice does not deliver twice.
	public void AddObserver(ISceneObserver observer, SceneLifecycleStage stage)
	{
		if (observer == null)
			return;

		for (let entry in mObservers)
		{
			if ((entry.Observer === observer) && (entry.Stage == stage))
				return;
		}

		mObservers.Add(.(observer, stage));

		// Stable insertion sort by Order, lower first, so peers in a stage run in the order
		// they declared rather than the order they happened to register.
		int i = mObservers.Count - 1;
		while ((i > 0) && (mObservers[i - 1].Observer.Order > observer.Order))
		{
			let previous = mObservers[i - 1];
			mObservers[i - 1] = mObservers[i];
			mObservers[i] = previous;
			i--;
		}
	}

	/// Removes EVERY registration for `observer`, across all stages.
	public void RemoveObserver(ISceneObserver observer)
	{
		for (int i = mObservers.Count - 1; i >= 0; i--)
		{
			if (mObservers[i].Observer === observer)
				mObservers.RemoveAt(i);
		}
	}

	public int ObserverCount => mObservers.Count;

	/// Fires `stage` to every observer registered for it, in Order.
	public void Notify(SceneLifecycleStage stage, Scene scene)
	{
		for (let entry in mObservers)
		{
			if (entry.Stage != stage)
				continue;

			switch (stage)
			{
			case .Composing: entry.Observer.OnComposing(scene);
			case .SystemsReady: entry.Observer.OnSystemsReady(scene);
			case .Destroying: entry.Observer.OnDestroying(scene);
			case .Count:
			}
		}
	}

	// ---- managers ----

	public void RegisterManager(SceneManager manager)
	{
		if (manager == null)
			return;
		if (mManagers.Contains(manager))
			return;
		mManagers.Add(manager);
	}

	public void UnregisterManager(SceneManager manager) => mManagers.Remove(manager);

	public int ManagerCount => mManagers.Count;

	public void ForEachManager(delegate void(SceneManager) fn)
	{
		for (let manager in mManagers)
			fn(manager);
	}

	/// A sweep across every live scene in every manager, for a prefab rebuild or an export.
	public void ForEachScene(delegate void(Scene) fn)
	{
		for (let manager in mManagers)
			manager.ForEachScene(fn);
	}

	// ---- the lane drive ----

	/// The bridge builds ONE FrameTime; each manager folds in its group term and each scene
	/// its own.
	public void BeginFrame(FrameTime time)
	{
		for (let manager in mManagers)
			manager.BeginFrame(time);
	}

	public void Update(FrameTime time)
	{
		for (let manager in mManagers)
			manager.Update(time);
	}
}
