using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.GUI;

namespace Sedulous.Editor.Play;

/// The Game tab's script debugger beside the game (its markup in Game.gml): Continue, Step Into,
/// Step Over and Break; the state line; the call stack; the locals, an object's members one level
/// under it (closed until opened). It reads only the neutral IScriptDebugger, so the same panel
/// would drive a remote debugger; the page rebuilds it from its update, never mid-script. The
/// debugger is borrowed from the run host and forgotten when the run stops.
class DebuggerPanel
{
	// The pane's: the tree holds them.
	private Sedulous.GUI.Label mStatus = null;
	private TreeView mStack = null;
	private TreeView mLocals = null;
	private TreeModel mStackModel = new .() ~ delete _;
	private TreeModel mLocalsModel = new .() ~ delete _;
	private IScriptDebugger mDebugger = null;

	/// The pane may hold the trees past this panel: they let go of its models first.
	public ~this()
	{
		if (mStack != null)
			mStack.Model = null;
		if (mLocals != null)
			mLocals.Model = null;
	}

	/// Over `pane` (the markup's `game-debugger-continue`, `-step-into`, `-step-over`, `-break`,
	/// `-state`, `-stack` and `-locals`, by id). `pane` is borrowed.
	public void Bind(Node pane)
	{
		mStatus = pane.FindElement("game-debugger-state") as Sedulous.GUI.Label;
		mStack = pane.FindElement("game-debugger-stack") as TreeView;
		mLocals = pane.FindElement("game-debugger-locals") as TreeView;
		if (mStack != null)
			mStack.Model = mStackModel;
		if (mLocals != null)
			mLocals.Model = mLocalsModel;
		Verb(pane, "game-debugger-continue", new (debugger) => { debugger.Continue(); });
		Verb(pane, "game-debugger-step-into", new (debugger) => { debugger.StepInto(); });
		Verb(pane, "game-debugger-step-over", new (debugger) => { debugger.StepOver(); });
		Verb(pane, "game-debugger-break", new (debugger) => { debugger.Break(); });
		SetIdle();
	}

	public IScriptDebugger Debugger => mDebugger;

	/// The active debugger for the run (null when not debugging). Clears the panel.
	public void SetDebugger(IScriptDebugger debugger)
	{
		mDebugger = debugger;
		if (debugger == null)
			Clear();
	}

	/// Shows the paused run's frames and locals.
	public void Refresh()
	{
		if (mDebugger == null)
		{
			Clear();
			return;
		}
		if (mStatus != null)
			mStatus.Text = "Paused";
		mStackModel.Clear();
		let frames = scope List<ScriptStackFrame>();
		defer { ClearAndDeleteItems(frames); }
		mDebugger.CaptureStackFrames(frames);
		for (let frame in frames)
			mStackModel.AddNode(TreeModel.Root, scope $"{frame.Function}  ({frame.File}:{frame.Line})");
		// The locals, an object's members one level under it.
		mLocalsModel.Clear();
		let locals = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(locals); }
		mDebugger.CaptureLocals(0, locals);
		let text = scope String();
		for (let local in locals)
		{
			text.Clear();
			text.AppendF("{} = {}", local.Name, local.Value);
			if (!local.TypeName.IsEmpty)
				text.AppendF("  ({})", local.TypeName);
			let node = mLocalsModel.AddNode(TreeModel.Root, text);
			if (local.ObjectRef == 0)
				continue;
			let members = scope List<ScriptVariable>();
			defer { ClearAndDeleteItems(members); }
			mDebugger.CaptureObject(local.ObjectRef, members);
			for (let member in members)
				mLocalsModel.AddNode(node, scope $"{member.Name} = {member.Value}");
		}
	}

	public void Clear()
	{
		if (mStatus != null)
			mStatus.Text = "Running";
		mStackModel.Clear();
		mLocalsModel.Clear();
	}

	public void SetIdle()
	{
		mDebugger = null;
		if (mStatus != null)
			mStatus.Text = "Not running";
		mStackModel.Clear();
		mLocalsModel.Clear();
	}

	// === What it shows (for tests) ===

	public StringView State => (mStatus != null) ? mStatus.Text : default;
	public int StackCount => mStackModel.RowCount(.());

	/// The button `id` in `pane` runs `run` (taken) on the debugger, while there is one.
	private void Verb(Node pane, StringView id, delegate void(IScriptDebugger debugger) run)
	{
		let button = pane.FindElement(id) as ButtonBase;
		if (button == null)
		{
			delete run;
			return;
		}
		button.SetOnClick(new [=this, =run] () =>
			{
				if (mDebugger != null)
					run(mDebugger);
			} ~ delete run);
	}
}
