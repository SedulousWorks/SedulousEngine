using Sedulous.PropertyAnimation;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// A minimal host: a clip, a real command stack, and counters. No page, no viewport.
class FakeClipHost : IClipEditorHost
{
	public PropertyAnimationClip ClipData = new .() ~ delete _;
	public EditorCommandStack Stack = new .() ~ delete _;
	public int DirtyCount = 0;
	public int RebuildCount = 0;
	public float LastScrub = -1.0f;

	public PropertyAnimationClip Clip => ClipData;
	public EditorCommandStack Commands => Stack;
	public void MarkClipDirty() { DirtyCount++; }
	public void OnScrubTimeChanged(float t) { LastScrub = t; }
	public void OnClipViewRebuilt() { RebuildCount++; }
}
