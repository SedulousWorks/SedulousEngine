using System;
using Sedulous.PropertyAnimation;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// One undoable step over a whole-clip snapshot. Applying a state replaces the host's clip and
/// rebuilds the view.
class ClipEditCommand : EditorCommand
{
	/// The durable seam, never the recreatable view.
	private IClipEditorHost mHost;
	private PropertyAnimationClip mBefore ~ delete _;
	private PropertyAnimationClip mAfter ~ delete _;
	/// The after state is already applied to the clip and visible, a curve-canvas drag
	/// having mutated live: the first Execute must not rebuild, since a rebuild recreates the
	/// canvas and drops the selected key and its tangent handles. Discrete edits leave it
	/// false so the first Execute rebuilds.
	private bool mLiveApplied;

	/// Takes ownership of both snapshots.
	public this(IClipEditorHost host, PropertyAnimationClip before, PropertyAnimationClip after, bool liveApplied = false)
	{
		mHost = host;
		mBefore = before;
		mAfter = after;
		mLiveApplied = liveApplied;
	}

	public override bool Execute()
	{
		mHost.ApplyClipState(mAfter, !mLiveApplied);
		mLiveApplied = false; // a later redo does rebuild, the canvas being stale by then
		return true;
	}

	public override void Undo() => mHost.ApplyClipState(mBefore, true);
	public override StringView TypeId => "propanim-clip-edit";
}
