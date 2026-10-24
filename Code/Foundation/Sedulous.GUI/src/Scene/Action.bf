using System;

namespace Sedulous.GUI;

// Action: the base of what runs on a GUI's clock (the tweens, a widget's TickAction). Ported from
// eepp's Scene::Action (include/eepp/scene/action.hpp): an abstract lifecycle (Start/Stop/Update/
// IsDone) driven by the ActionManager, with a tag, an id and an OnDone callback. Reference
// counted: the manager holds a reference to each action it runs, and whoever made one releases
// its own.

enum ActionType
{
	OnStart,
	OnStop,
	OnUpdate,
	OnDone
}

abstract class Action : RefCounted
{
	public typealias Callback = delegate void(Sedulous.GUI.Action action);

	private Callback mOnDone ~ delete _;
	private uint64 mId = 0;
	private uint64 mTag = 0;

	public abstract void Start();
	public abstract void Stop();
	public abstract void Update(TimeSpan elapsed);
	public abstract bool IsDone { get; }
	public abstract float CurrentProgress { get; }
	public abstract TimeSpan TotalTime { get; }

	/// Whether it can change where its target is, how big, or how far its drawing reaches (an
	/// animation that could bring a node out of view into view). One that cannot asks for no
	/// frames while its target is out of view; it still runs, so it is caught up when the target
	/// shows. True unless an action knows better.
	public virtual bool CanMoveTarget => true;

	/// How much of the time its last Update was given ran past its end: a group's next step starts
	/// with it, so a sequence keeps time whatever the frames.
	public virtual TimeSpan Overrun => default;

	public uint64 Id
	{
		get => mId;
		set => mId = value;
	}

	public uint64 Tag
	{
		get => mTag;
		set => mTag = value;
	}

	/// OWNERSHIP of `callback` transfers (one set before is deleted).
	public void SetOnDone(Callback callback)
	{
		delete mOnDone;
		mOnDone = callback;
	}

	protected virtual void OnTargetChange() { }

	protected void FireDone()
	{
		if (mOnDone != null)
			mOnDone(this);
	}
}
