using System;
using System.Collections;

namespace Sedulous.GUI;

// ActionManager: owns and ticks running Actions. Ported from eepp's Scene::ActionManager
// (include/eepp/scene/actionmanager.hpp). Owned by the SceneRoot; Node.RunAction forwards here.
// It holds a reference to each action it runs; a finished action is released after Update.

class ActionManager
{
	/// How fast an action's time runs (its target's root may be paused, 0, or slowed).
	public typealias TimeScale = delegate float(Node target);

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

	/// Ticks all actions, each by `elapsed` times its target's time scale (1 without one); drops
	/// finished ones and those whose target is gone. An action that cannot bring its target into
	/// view, on a target out of view at the last frame, writes quietly: its target's invalidations
	/// mark it alone, asking for no frame.
	public void Update(TimeSpan elapsed, TimeScale scaleOf = null)
	{
		for (int i = 0; i < mActions.Count;)
		{
			let action = mActions[i];
			let target = action.ResolveTarget();
			if ((target == null) && (action.Target != null))
			{
				mActions.RemoveAt(i); // its target was destroyed
				action.ReleaseRef();
				continue;
			}
			let scale = ((scaleOf != null) && (target != null)) ? scaleOf(target) : 1.0f;
			// Out of view, an action that cannot bring its target into view changes nothing
			// that shows: what it writes marks the target alone, asking for no frame.
			let quiet = (target != null) && target.WasOutOfView && !action.CanMoveTarget;
			if (quiet)
				target.BeginQuietInvalidation();
			if (scale == 1.0f)
				action.Update(elapsed);
			else if (scale > 0.0f)
			{
				// By ticks: TimeSpan.FromSeconds would round to whole milliseconds.
				let seconds = (double)(float)elapsed.TotalSeconds * (double)scale;
				action.Update(TimeSpan((int64)(seconds * (double)TimeSpan.TicksPerSecond)));
			}
			if (quiet)
				target.EndQuietInvalidation();
			if (i >= mActions.Count)
				break; // an action cleared the manager
			let ran = mActions[i];
			if (ran.IsDone)
			{
				mActions.RemoveAt(i);
				ran.ReleaseRef();
			}
			else
				i++;
		}
	}

	/// Whether an action is running that `matches(action, target)` takes (a root asks for its
	/// frames).
	public bool AnyAction(delegate bool(Sedulous.GUI.Action action, Node target) matches)
	{
		for (let a in mActions)
		{
			let target = a.ResolveTarget();
			if ((target != null) && matches(a, target))
				return true;
		}
		return false;
	}

	public bool RemoveAllActionsFromTarget(Node target)
	{
		bool removed = false;
		for (int i = 0; i < mActions.Count;)
		{
			let a = mActions[i];
			if (a.Target == target)
			{
				mActions.RemoveAt(i);
				a.ReleaseRef();
				removed = true;
			}
			else
				i++;
		}
		return removed;
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
