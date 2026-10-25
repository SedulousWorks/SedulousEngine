using System;

namespace Sedulous.GUI;

// Action: the base of what runs on a GUI's clock (the tweens, a widget's TickAction). Ported from
// eepp's Scene::Action (include/eepp/scene/action.hpp): an abstract lifecycle (Start/Stop/Update/
// IsDone) driven by the ActionManager, with a target, a tag, an id and an OnDone callback.
// Reference counted: the manager holds a reference to each action it runs, and whoever made one
// releases its own. The target is not owned: a node destroyed mid-animation takes its actions
// with it through the weak hold Node.RunAction gives them. The action keeps a reference on that
// hold's table, so one kept past its GUI (by a script, or native code) reads its target as gone
// rather than reading a freed table.

enum ActionType
{
	OnStart,
	OnStop,
	OnUpdate,
	OnDone
}

abstract class Action : RefCounted, Sedulous.Core.IScriptCounted
{
	public typealias Callback = delegate void(Sedulous.GUI.Action action);

	/// A weak hold on the target, resolved through its GUI's element table (Node.RunAction sets
	/// it): an action whose target is gone is dropped rather than run on freed memory.
	public struct WeakTarget
	{
		public ElementTable Table = null;
		public uint32 Slot = 0;
		public uint32 Generation = 0;
		public function Node(WeakTarget weak) Resolve = null;

		public this() { }

		public this(ElementTable table, uint32 slot, uint32 generation, function Node(WeakTarget weak) resolve)
		{
			Table = table;
			Slot = slot;
			Generation = generation;
			Resolve = resolve;
		}
	}

	private Callback mOnDone ~ delete _;
	private uint64 mId = 0;
	private uint64 mTag = 0;
	private Node mTarget = null; // not owned; read through ResolveTarget when held weakly
	private WeakTarget mWeak = .() ~ { if (_.Table != null) _.Table.ReleaseRef(); };

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

	/// The node it acts on (not owned).
	public Node Target
	{
		get => mTarget;
		set
		{
			mTarget = value;
			OnTargetChange();
		}
	}

	/// Holds `weak` instead of the hold it had, with a reference on its table.
	public void SetWeakTarget(WeakTarget weak)
	{
		if (weak.Table != null)
			weak.Table.AddRef();
		if (mWeak.Table != null)
			mWeak.Table.ReleaseRef();
		mWeak = weak;
	}

	/// The target when it is alive (or when none was held weakly), null once it is gone.
	public Node ResolveTarget() => (mWeak.Resolve != null) ? mWeak.Resolve(mWeak) : mTarget;

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
