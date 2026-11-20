using System;
using Sedulous.Input;
using Sedulous.Script;
using Sedulous.Engine.Behavior;

namespace Sedulous.Editor.Play;

/// Scripted input (pie_run): a timeline source in place of the viewport's, on this tab's game
/// instance and, while this tab holds it, the input subsystem, so the other tabs keep their
/// own. Advanced in OnUpdate by the run's time; the input subsystem, which drives every run's
/// input as the embedded runtime's frame begins, before the pages, reads it on the next frame.
extension GameEditorPage
{
	/// OWNED while a run scripts this tab.
	private ScriptedInputSource mScripted = null ~ delete _;
	/// The run time the script's zero is.
	private double mScriptedStart = 0;
	/// End asked: one frame letting go of everything held, then the viewport source returns.
	private bool mScriptedEnding = false;
	private bool mScriptedReleased = false;

	/// What this tab's game reads: the script while one runs, else the viewport.
	private IInputSourceProvider ActiveSource => (mScripted != null) ? (IInputSourceProvider)mScripted : mViewportSource;

	public bool IsScripted => mScripted != null;

	public void BeginScriptedInput(ScriptedInputSource source)
	{
		DropScriptedInput();
		mScripted = source;
		mScriptedStart = RunTime;
		mScriptedEnding = false;
		mScriptedReleased = false;
		if ((mInput != null) && (mInput.ActiveSource === mViewportSource))
			mInput.SetSourceProvider(mScripted, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		if (mApplicationRun != null)
			mApplicationRun.SetInputSource(mScripted);
	}

	public void EndScriptedInput()
	{
		if (mScripted != null)
			mScriptedEnding = true;
	}

	public bool GetScriptProperty(StringView name, ref ScriptValue value)
	{
		return (mApplicationRun != null) && mApplicationRun.GetScriptProperty(name, ref value);
	}

	public bool GetLevelProperty(StringView name, ref ScriptValue value)
	{
		if (!mRunning || (mScene == null))
			return false;
		let level = mScene.GetSystem<BehaviorSystem>();
		return (level != null) && level.GetLevelProperty(name, ref value);
	}

	/// Once per frame from OnUpdate.
	private void AdvanceScriptedInput()
	{
		if (mScripted == null)
			return;
		if (!mScriptedEnding)
		{
			mScripted.Advance(RunTime - mScriptedStart);
			return;
		}
		if (!mScriptedReleased)
		{
			mScripted.ReleaseAll(); // the game reads the let-go next frame
			mScriptedReleased = true;
			return;
		}
		DropScriptedInput();
	}

	/// The viewport source back, where the script was installed, and the script gone.
	private void DropScriptedInput()
	{
		if (mScripted == null)
			return;
		if ((mInput != null) && (mInput.ActiveSource === mScripted))
			mInput.SetSourceProvider(mViewportSource, (mScene != null) ? Internal.UnsafeCastToPtr(mScene) : null);
		if (mApplicationRun != null)
			mApplicationRun.SetInputSource(mViewportSource);
		DeleteAndNullify!(mScripted);
		mScriptedEnding = false;
		mScriptedReleased = false;
	}
}
