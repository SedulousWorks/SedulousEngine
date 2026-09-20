using System;
using Sedulous.PropertyAnimation;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation;

/// The seam a ClipEditorView edits against. The host owns the clip storage, the undo stack,
/// the dirty flag and, optionally, live preview; the view owns the widgets and edit logic.
interface IClipEditorHost
{
	/// The editing model the view reads and writes in place: curve-drag write-backs edit it
	/// live, then the view records one undo step spanning the whole gesture.
	PropertyAnimationClip Clip { get; }
	/// The undo stack the view pushes its clip-edit commands onto.
	EditorCommandStack Commands { get; }
	/// Flags the document dirty, a live write-back during a gesture before it commits.
	void MarkClipDirty();
	/// The scrub time moved; the host may drive a live preview of the bound entity.
	void OnScrubTimeChanged(float time) {}
	/// Sets the clip's authored duration, the play and loop bound and the timeline extent.
	/// The host clamps it to at least the last key and commits it as one undo step.
	void SetClipDuration(float seconds) {}
	/// The view finished rebuilding its rows; the host may refresh chrome.
	void OnClipViewRebuilt() {}
	/// The shared dopesheet time transform; a static 100 px/s axis by default.
	ClipTimeAxis ClipTimeTransform => .();
	/// The current scene value of a component property on the bound entity, the key-from-scene
	/// capture source. No value when unresolvable; the caller skips then.
	PropertyValue ReadSceneValue(StringView componentType, StringView propertyPath) => .Empty;
	/// Applies a whole-clip state, an undo or redo step, and refreshes the editing surface.
	/// The command routes through this seam, never a view pointer, so it depends only on the
	/// durable host. The default copies the clip only; a host with a live view rebuilds too.
	void ApplyClipState(PropertyAnimationClip state, bool rebuild) => state.CopyTo(Clip);
}
