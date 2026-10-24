using System;
using System.Collections;

namespace Sedulous.GUI;

// ActionManager: owns and ticks running Actions. Ported from eepp's Scene::ActionManager
// (include/eepp/scene/actionmanager.hpp). Owned by the SceneRoot; Node.RunAction forwards here.
// It holds a reference to each action it runs; a finished action is released after Update.

class ActionManager
{
	private List<Sedulous.GUI.Action> mActions = new .() ~ { ReleaseAll(_); delete _; };

	/// Adds and starts an action. The manager takes a reference of its own: the caller keeps (and
	/// releases) the one it holds.
	public void AddAction(Sedulous.GUI.Action action)
	{
		if (action == null)
			return;
		action.Start();
		action.AddRef();
		mActions.Add(action);
	}

	/// Calls `f(action)` for each running action.
	public void ForEachAction(delegate void(Sedulous.GUI.Action action) f)
	{
		for (let a in mActions)
			f(a);
	}

	public Sedulous.GUI.Action GetActionByTag(uint64 tag)
	{
		for (let a in mActions)
		{
			if (a.Tag == tag)
				return a;
		}
		return null;
	}

	public int Count => mActions.Count;
	public bool IsEmpty => mActions.Count == 0;

	public void Clear()
	{
		ReleaseAll(mActions);
		mActions.Clear();
	}

	private static void ReleaseAll(List<Sedulous.GUI.Action> actions)
	{
		for (let a in actions)
			a.ReleaseRef();
	}
}
