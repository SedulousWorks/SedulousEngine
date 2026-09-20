using System;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// The shared editing view over the host seam: it builds headlessly over a clip, discrete
/// edits route through the host's undo stack, and both render paths build without a window.
static class ClipEditorViewTests
{
	[Test]
	public static void BuildsHeadlesslyAndRebuildsOnAnEmptyClip()
	{
		let host = scope FakeClipHost();
		let view = scope ClipEditorView(host);
		Test.Assert(view.Root != null);
		Test.Assert(host.RebuildCount >= 1, "the constructor's first Rebuild fired OnClipViewRebuilt");
		let before = host.RebuildCount;
		view.Rebuild(); // idempotent
		Test.Assert(host.RebuildCount == before + 1);
	}

	[Test]
	public static void AddTrackRoutesThroughTheHostCommandStack()
	{
		let host = scope FakeClipHost();
		let view = scope ClipEditorView(host);
		Test.Assert(host.ClipData.Tracks.Count == 0);

		view.AddTrack("Transform", "Position", .Float3);
		Test.Assert(host.ClipData.Tracks.Count == 1);
		Test.Assert(host.ClipData.Tracks[0].ComponentType == "Transform");
		Test.Assert(host.ClipData.Tracks[0].PropertyPath == "Position");
		Test.Assert(host.ClipData.Tracks[0].Kind == .Float3);
		Test.Assert(host.Stack.CanUndo);

		host.Stack.Undo();
		Test.Assert(host.ClipData.Tracks.Count == 0);
		Test.Assert(host.Stack.CanRedo);

		host.Stack.Redo();
		Test.Assert(host.ClipData.Tracks.Count == 1);
	}

	[Test]
	public static void BothTrackRenderPathsBuild()
	{
		let host = scope FakeClipHost();
		let view = scope ClipEditorView(host);
		// A scalar track takes the CurveCanvas path, a quaternion track the keys strip; each add
		// is one undo step.
		view.AddTrack("Transform", "Position", .Float3);
		view.AddTrack("Transform", "Rotation", .Quat);
		Test.Assert(host.ClipData.Tracks.Count == 2);
		view.Rebuild();
		Test.Assert(view.Root != null);
		host.Stack.Undo();
		host.Stack.Undo();
		Test.Assert(host.ClipData.Tracks.Count == 0);
	}
}
