using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The debugger wiring: the run's debugger takes the editor's breakpoints and the listener,
/// a break freezes the simulation and shows the execution point, and the editor's hover
/// probe reads a paused local.
extension GameEditorPage
{
	private void EnableDebugging()
	{
		if (mGameInstance == null)
			return;
		mGameInstance.RunHost.RequestDebugger(new [=this](debugger) =>
		{
			debugger.SetListener(mDebugListener);
			for (let breakpoint in mContext.Breakpoints)
			{
				debugger.SetBreakpoint(breakpoint.File, breakpoint.Line);
				mAppliedBreakpoints.Add(new ScriptBreakpoint(breakpoint.File, breakpoint.Line));
			}
			mDebuggerPanel.SetDebugger(debugger);
		});

		delete mContext.OnBreakpointsChanged;
		mContext.OnBreakpointsChanged = new [=this]() => { SyncBreakpointsToDebugger(); };

		delete mContext.ScriptValueProbe;
		mContext.ScriptValueProbe = new [=this](identifier, outText) =>
		{
			outText.Clear();
			if ((mGameInstance == null) || !mRunning || !mGameInstance.RunHost.IsDebugPaused)
				return;
			let debugger = mDebuggerPanel.Debugger;
			if (debugger == null)
				return;
			let locals = scope List<ScriptVariable>();
			defer { ClearAndDeleteItems(locals); }
			debugger.CaptureLocals(0, locals);
			for (let local in locals)
			{
				if (local.Name != identifier)
					continue;
				outText.Set(local.Value);
				if (!local.TypeName.IsEmpty)
					outText.AppendF(" : {}", local.TypeName);
				return;
			}
		};
	}

	private void DrainDebuggerState()
	{
		if (!mRunning)
			return;
		if (mDebugListener.Changed)
		{
			mDebugListener.Changed = false;
			let paused = (mDebugListener.State == .Breakpoint) || (mDebugListener.State == .Stepped);
			if (paused)
			{
				if ((mScene != null) && !mSimPausedByDebugger)
				{
					mScene.SetSimulationEnabled(false);
					mSimPausedByDebugger = true;
				}
				mDebuggerPanel.Refresh();
				if (let debugger = mDebuggerPanel.Debugger)
				{
					let frames = scope List<ScriptStackFrame>();
					defer { ClearAndDeleteItems(frames); }
					debugger.CaptureStackFrames(frames);
					if (!frames.IsEmpty)
						mContext.SetScriptExecutionPoint(frames[0].File, frames[0].Line);
				}
			}
			else
			{
				if ((mScene != null) && mSimPausedByDebugger)
				{
					mScene.SetSimulationEnabled(true);
					mSimPausedByDebugger = false;
				}
				mDebuggerPanel.Clear();
				mContext.ClearScriptExecutionPoint();
			}
		}
		if (mDebuggerPanel.ConsumeDirty())
			mDebuggerPanel.Refresh();
	}

	/// Mirrors the editor's breakpoint store onto the debugger: removed ones cleared, new
	/// ones set.
	private void SyncBreakpointsToDebugger()
	{
		let debugger = mDebuggerPanel.Debugger;
		if ((debugger == null) || !mRunning)
			return;
		let store = mContext.Breakpoints;
		for (let applied in mAppliedBreakpoints)
		{
			if (!Contains(store, applied))
				debugger.RemoveBreakpoint(applied.File, applied.Line);
		}
		for (let breakpoint in store)
		{
			if (!Contains(mAppliedBreakpoints, breakpoint))
				debugger.SetBreakpoint(breakpoint.File, breakpoint.Line);
		}
		ClearAndDeleteItems(mAppliedBreakpoints);
		for (let breakpoint in store)
			mAppliedBreakpoints.Add(new ScriptBreakpoint(breakpoint.File, breakpoint.Line));
	}

	private static bool Contains(List<ScriptBreakpoint> set, ScriptBreakpoint breakpoint)
	{
		for (let entry in set)
		{
			if ((entry.Line == breakpoint.Line) && (entry.File == breakpoint.File))
				return true;
		}
		return false;
	}
}
