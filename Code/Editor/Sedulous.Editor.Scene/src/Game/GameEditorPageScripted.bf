using System;
using Sedulous.Input;
using Sedulous.Script;

namespace Sedulous.Editor.Scene;

/// Scripted input (pie_run): a timeline source in place of the viewport's, on this tab's game
/// instance and, while this tab holds it, the input subsystem, so the other tabs keep their
/// own. Advanced in OnUpdate by the run's time; the embedded app's DriveInput, which runs
/// before the pages each frame, reads it on the next frame.
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
		if (mGameInstance != null)
			mGameInstance.SetInputSource(mScripted);
	}

	public void EndScriptedInput()
	{
		if (mScripted != null)
			mScriptedEnding = true;
	}

	public bool GetScriptProperty(StringView name, ref ScriptValue value)
	{
		return (mGameInstance != null) && mGameInstance.GetScriptProperty(name, ref value);
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
		if (mGameInstance != null)
			mGameInstance.SetInputSource(mViewportSource);
		DeleteAndNullify!(mScripted);
		mScriptedEnding = false;
		mScriptedReleased = false;
	}
}
