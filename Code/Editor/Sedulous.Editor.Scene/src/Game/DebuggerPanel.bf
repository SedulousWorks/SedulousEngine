using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// The Game tab's script debugger strip: continue, step and break, the state line, the call
/// stack, and the locals with expandable objects. The debugger is borrowed from the run
/// host and forgotten when the run stops.
class DebuggerPanel
{
	private View mRoot;
	private Label mStatus;
	private FlexLayout mStackList;
	private FlexLayout mLocalsList;
	private IScriptDebugger mDebugger = null;
	/// The object refs expanded in the locals, per break.
	private List<uint64> mExpanded = new .() ~ delete _;
	private bool mDirty = false;

	public this()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4.0f;
		column.Padding = .(6, 6);

		let bar = new FlexLayout();
		bar.Direction = .Horizontal;
		bar.Spacing = 4.0f;
		AddToolButton(bar, "Continue", new [=this]() => { if (mDebugger != null) mDebugger.Continue(); });
		AddToolButton(bar, "Step Into", new [=this]() => { if (mDebugger != null) mDebugger.StepInto(); });
		AddToolButton(bar, "Step Over", new [=this]() => { if (mDebugger != null) mDebugger.StepOver(); });
		AddToolButton(bar, "Break", new [=this]() => { if (mDebugger != null) mDebugger.Break(); });
		column.AddView(bar, MatchWidth());

		mStatus = new Label("Debugger: not running");
		mStatus.FontSize.Value = 12.0f;
		column.AddView(mStatus, MatchWidth());

		column.AddView(new Label("Call Stack"), MatchWidth());
		mStackList = new FlexLayout();
		mStackList.Direction = .Vertical;
		column.AddView(mStackList, MatchWidth());

		column.AddView(new Label("Locals"), MatchWidth());
		mLocalsList = new FlexLayout();
		mLocalsList.Direction = .Vertical;
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		grow.Width = SizeSpec.Match();
		column.AddView(mLocalsList, grow);
		mRoot = column;
	}

	/// BORROWED by the page's layout, which takes its own reference.
	public View RootView => mRoot;

	public IScriptDebugger Debugger => mDebugger;

	public void SetDebugger(IScriptDebugger debugger)
	{
		mDebugger = debugger;
		mExpanded.Clear();
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
		mStatus.SetText("Debugger: paused");
		mStackList.RemoveAllViews();
		let frames = scope List<ScriptStackFrame>();
		defer { ClearAndDeleteItems(frames); }
		mDebugger.CaptureStackFrames(frames);
		for (let frame in frames)
			AddRow(mStackList, scope $"{frame.Function}  ({frame.File}:{frame.Line})", 0.0f);
		mLocalsList.RemoveAllViews();
		let locals = scope List<ScriptVariable>();
		defer { ClearAndDeleteItems(locals); }
		mDebugger.CaptureLocals(0, locals);
		for (let local in locals)
			AddLocalRow(local, 0.0f);
	}

	public void Clear()
	{
		mStatus.SetText("Debugger: running");
		mStackList.RemoveAllViews();
		mLocalsList.RemoveAllViews();
	}

	public void SetIdle()
	{
		mDebugger = null;
		mExpanded.Clear();
		mStatus.SetText("Debugger: not running");
		mStackList.RemoveAllViews();
		mLocalsList.RemoveAllViews();
	}

	/// Whether an expand toggle asked for a refresh; answering clears it.
	public bool ConsumeDirty()
	{
		let was = mDirty;
		mDirty = false;
		return was;
	}

	private static LayoutStyle MatchWidth()
	{
		var lp = LayoutStyle();
		lp.Width = SizeSpec.Match();
		return lp;
	}

	/// CONSUMES `onClick`, which the button's handler owns.
	private static void AddToolButton(FlexLayout bar, StringView label, delegate void() onClick)
	{
		let button = new Button(label);
		button.FontSize.Value = 12.0f;
		button.OnClick.Add(new [=onClick](b) => { onClick(); } ~ delete onClick);
		bar.AddView(button);
	}

	private static void AddRow(FlexLayout list, StringView text, float indent)
	{
		let label = new Label(text);
		label.FontSize.Value = 12.0f;
		var lp = LayoutStyle();
		lp.Width = SizeSpec.Match();
		lp.Margin = Thickness(indent, 0, 0, 0);
		list.AddView(label, lp);
	}

	private void AddLocalRow(ScriptVariable variable, float indent)
	{
		let text = scope String();
		text.AppendF("{} = {}", variable.Name, variable.Value);
		if (!variable.TypeName.IsEmpty)
			text.AppendF("  ({})", variable.TypeName);
		let expandable = variable.ObjectRef != 0;
		let expanded = expandable && IsExpanded(variable.ObjectRef);
		if (!expandable)
		{
			AddRow(mLocalsList, text, indent);
			return;
		}
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4.0f;
		let toggle = new Button(expanded ? "-" : "+");
		toggle.FontSize.Value = 12.0f;
		let reference = variable.ObjectRef;
		toggle.OnClick.Add(new [=this, =reference](b) => { ToggleExpand(reference); });
		row.AddView(toggle);
		let label = new Label(text);
		label.FontSize.Value = 12.0f;
		row.AddView(label);
		var lp = LayoutStyle();
		lp.Width = SizeSpec.Match();
		lp.Margin = Thickness(indent, 0, 0, 0);
		mLocalsList.AddView(row, lp);
		if (expanded && (mDebugger != null))
		{
			let members = scope List<ScriptVariable>();
			defer { ClearAndDeleteItems(members); }
			mDebugger.CaptureObject(reference, members);
			for (let member in members)
				AddRow(mLocalsList, scope $"{member.Name} = {member.Value}", indent + 18.0f);
		}
	}

	private bool IsExpanded(uint64 reference) => mExpanded.Contains(reference);

	private void ToggleExpand(uint64 reference)
	{
		if (!mExpanded.Remove(reference))
			mExpanded.Add(reference);
		mDirty = true;
	}
}
