using System;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Sequence;

/// One play in one scene, as a script holds it: the scene, weakly, and the play's id. Harmless
/// once its play has ended or its scene is gone: its calls do nothing and IsPlaying() is false.
[Scriptable]
struct SequencePlay
{
	/// The scene's place in the process's weak table; generation 0 names none.
	private uint32 mSceneSlot = 0;
	private uint32 mSceneGeneration = 0;
	/// 0: no play.
	private uint32 mPlay = 0;

	public this() {}

	public this(Scene scene, uint32 play)
	{
		if ((scene != null) && (play != 0))
		{
			let weak = scene.TakeScriptWeak();
			mSceneSlot = weak.Slot;
			mSceneGeneration = weak.Generation;
			mPlay = play;
		}
	}

	/// The play's number, as a SequenceNotice carries it.
	[Scriptable]
	public int32 Id() => (int32)mPlay;

	/// Fills the sequence's name `name` with `entity` (an actor spawned for the scene). False when
	/// the sequence has no such name or the play has ended.
	[Scriptable]
	public bool Bind(StringView name, EntityHandle entity)
	{
		let play = Find();
		return (play != null) && play.Bind(name, entity);
	}

	/// Ends the play (its finish decides what it puts back).
	[Scriptable]
	public void Stop()
	{
		let system = System();
		if (system != null)
			system.Stop(mPlay);
	}

	[Scriptable]
	public void Pause() => Find()?.Pause();

	/// Continues after a pause, or from a hold (a line of dialogue answered).
	[Scriptable]
	public void Resume() => Find()?.Resume();

	[Scriptable]
	public void Seek(float time) => Find()?.Seek(time);

	[Scriptable]
	public void SetSpeed(float speed)
	{
		let play = Find();
		if (play != null)
			play.Speed = Math.Max(0.0f, speed);
	}

	[Scriptable]
	public float Time() => Find()?.Time ?? 0.0f;

	[Scriptable]
	public float Duration() => Find()?.Duration ?? 0.0f;

	[Scriptable]
	public bool IsPlaying() => Find()?.IsPlaying ?? false;

	[Scriptable]
	public bool IsHeld() => Find()?.IsHeld ?? false;

	private SequenceSystem System()
	{
		if (mPlay == 0)
			return null;
		let scene = ScriptWeakTable.Shared.ResolveWeak(mSceneSlot, mSceneGeneration) as Scene;
		return (scene != null) ? scene.GetSystem<SequenceSystem>() : null;
	}

	private Sedulous.Sequence.SequencePlay Find() => System()?.Find(mPlay);
}
