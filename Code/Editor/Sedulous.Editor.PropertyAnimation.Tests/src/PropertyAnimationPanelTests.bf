using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;
using Sedulous.UI;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// The host-agnostic panel logic: the type to kind mapping, the animatable-property collector,
/// the panel as a clip-editor host, the live-preview snapshot and restore with the re-snapshot
/// on a track-set change and the edit-only gate, the transport, the dopesheet drag, the clip
/// duration, the empty state and scene value capture.
static class PropertyAnimationPanelTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	[Test]
	public static void InferTrackKindMapsTheFourAnimatableTypesAndRejectsOthers()
	{
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(float)) == .Float);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(Float3)) == .Float3);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(Color)) == .Color);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(Quaternion)) == .Quat);
		Test.Assert(AnimatableProperties.InferTrackKind(typeof(int32)) == null);
		Test.Assert(AnimatableProperties.InferTrackKind(null) == null);
	}

	[Test]
	public static void CollectSeedsLeavesAndNestedAndSkipsNonAnimatable()
	{
		let infos = scope List<AnimatablePropertyInfo>();
		defer { ClearAndDeleteItems(infos); }
		AnimatableProperties.Collect(typeof(TestComp), infos);
		// Position (Float3), Rotation (Quat), Intensity (float), Light.Tint (Color); not Flags.
		Test.Assert(infos.Count == 4);
		bool sawPosition = false;
		bool sawRotation = false;
		bool sawIntensity = false;
		bool sawTint = false;
		bool sawFlags = false;
		for (let p in infos)
		{
			Test.Assert(p.ComponentType == "TestComp");
			if (p.PropertyPath == "Position")
			{
				sawPosition = true;
				Test.Assert(p.Kind == .Float3);
			}
			else if (p.PropertyPath == "Rotation")
			{
				sawRotation = true;
				Test.Assert(p.Kind == .Quat);
			}
			else if (p.PropertyPath == "Intensity")
			{
				sawIntensity = true;
				Test.Assert(p.Kind == .Float);
			}
			else if (p.PropertyPath == "Light.Tint")
			{
				sawTint = true;
				Test.Assert(p.Kind == .Color);
			}
			else if (p.PropertyPath == "Flags")
			{
				sawFlags = true;
			}
		}
		Test.Assert(sawPosition && sawRotation && sawIntensity && sawTint);
		Test.Assert(!sawFlags, "the int leaf is not animatable");
	}

	[Test]
	public static void ThePanelIsAValidClipEditorHost()
	{
		let f = scope PanelFixture("host-test");
		f.Build();
		Test.Assert(!f.Panel.HasClip);

		f.Panel.View.AddTrack("Transform", "Position", .Float3);
		Test.Assert(f.Panel.Clip.Tracks.Count == 1);
		Test.Assert(f.Stack.CanUndo);
		f.Stack.Undo();
		Test.Assert(f.Panel.Clip.Tracks.Count == 0);

		// No bound entity: add-from-selection is a no-op, never a crash.
		Test.Assert(f.Panel.AddTracksFromSelection(f.Panel.View) == 0);
	}

	[Test]
	public static void PreviewWritesSampledValuesTransientlyRestoresAndNeverDirties()
	{
		let f = scope PanelFixture("preview-test");
		let mgr = f.Scene.AddSystem<ComponentManager<PreviewComp>>();
		let e = f.Scene.CreateEntity("e0");
		mgr.Add(e).Position = .(5.0f, 6.0f, 7.0f); // the original, pre-preview value
		f.Selection.Set(f.Scene.GetEntityId(e));
		f.Build();
		f.Panel.Clip.Tracks.Add(PanelFixture.MakePositionTrack(100.0f, 200.0f, 300.0f));

		// A scrub writes the sampled values onto the live component.
		f.Panel.OnScrubTimeChanged(0.5f);
		Test.Assert(f.Panel.IsPreviewing);
		Test.Assert(Near(mgr.Get(e).Position.X, 100.0f));
		Test.Assert(Near(mgr.Get(e).Position.Y, 200.0f));
		Test.Assert(Near(mgr.Get(e).Position.Z, 300.0f));
		// The preview goes nowhere near the command stack.
		Test.Assert(!f.Stack.CanUndo);

		// Stopping restores the snapshot exactly.
		f.Panel.StopPreview();
		Test.Assert(!f.Panel.IsPreviewing);
		Test.Assert(Near(mgr.Get(e).Position.X, 5.0f));
		Test.Assert(Near(mgr.Get(e).Position.Y, 6.0f));
		Test.Assert(Near(mgr.Get(e).Position.Z, 7.0f));
	}

	[Test]
	public static void PreviewIsDisabledOutsideEdit()
	{
		let f = scope PanelFixture("preview-sim");
		let mgr = f.Scene.AddSystem<ComponentManager<PreviewComp>>();
		let e = f.Scene.CreateEntity("e0");
		mgr.Add(e).Position = .(1.0f, 1.0f, 1.0f);
		f.Selection.Set(f.Scene.GetEntityId(e));
		f.Build();
		f.Panel.Clip.Tracks.Add(PanelFixture.MakePositionTrack(9.0f, 9.0f, 9.0f));

		// Simulate is on: the frame tick stands the preview down.
		f.Panel.Tick(0.0f, true);
		f.Panel.OnScrubTimeChanged(0.5f);
		Test.Assert(!f.Panel.IsPreviewing);
		Test.Assert(Near(mgr.Get(e).Position.X, 1.0f), "untouched");

		// Back to edit: the same scrub now previews.
		f.Panel.Tick(0.0f, false);
		f.Panel.OnScrubTimeChanged(0.5f);
		Test.Assert(f.Panel.IsPreviewing);
		Test.Assert(Near(mgr.Get(e).Position.X, 9.0f));
		f.Panel.StopPreview();
		Test.Assert(Near(mgr.Get(e).Position.X, 1.0f));
	}

	[Test]
	public static void ChangingTheBoundEntityRestoresTheOldOneAndPreviewsTheNew()
	{
		let f = scope PanelFixture("preview-swap");
		let mgr = f.Scene.AddSystem<ComponentManager<PreviewComp>>();
		let a = f.Scene.CreateEntity("a");
		let b = f.Scene.CreateEntity("b");
		mgr.Add(a).Position = .(1.0f, 0.0f, 0.0f);
		mgr.Add(b).Position = .(2.0f, 0.0f, 0.0f);
		f.Selection.Set(f.Scene.GetEntityId(a));
		f.Build();
		f.Panel.Clip.Tracks.Add(PanelFixture.MakePositionTrack(50.0f, 0.0f, 0.0f));

		f.Panel.OnScrubTimeChanged(0.0f); // preview A
		Test.Assert(Near(mgr.Get(a).Position.X, 50.0f));

		// Rebound to B and scrubbed: A restores, B previews. Selection alone no longer
		// retargets; binding is the explicit act.
		f.Selection.Set(f.Scene.GetEntityId(b));
		f.Panel.BindSelectedEntity();
		f.Panel.OnScrubTimeChanged(0.0f);
		Test.Assert(Near(mgr.Get(a).Position.X, 1.0f), "restored");
		Test.Assert(Near(mgr.Get(b).Position.X, 50.0f), "previewed");

		f.Panel.StopPreview();
		Test.Assert(Near(mgr.Get(b).Position.X, 2.0f), "restored");
	}

	[Test]
	public static void ReSnapshotsWhenTheTrackSetChangesMidPreview()
	{
		let f = scope PanelFixture("resnapshot");
		let e = f.Scene.CreateEntity("e0");
		f.Scene.SetLocalPosition(e, .(5.0f, 6.0f, 7.0f)); // the scale defaults to one
		f.Selection.Set(f.Scene.GetEntityId(e));
		f.Build();

		// A preview with one track, Transform.Position.
		f.Panel.Clip.Tracks.Add(PanelFixture.MakePositionTrackOn("Transform", 100.0f, 200.0f, 300.0f));
		f.Panel.OnScrubTimeChanged(0.5f);
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.X, 100.0f));

		// A second track, Transform.Scale, while previewing: the identity changed, so the next
		// scrub re-snapshots, else the scale write would never be restored.
		f.Panel.Clip.Tracks.Add(PanelFixture.MakeFloat3TrackOn("Transform", "Scale", 9.0f, 9.0f, 9.0f));
		f.Panel.OnScrubTimeChanged(0.5f);
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.X, 100.0f), "still previewed");
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Scale.X, 9.0f), "the new track previewed");

		// Stop: both targets restore, proving the re-snapshot.
		f.Panel.StopPreview();
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.X, 5.0f));
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Scale.X, 1.0f));
	}

	[Test]
	public static void AddFromSelectionSeedsTheEntityTransform()
	{
		let f = scope PanelFixture("seed");
		let e = f.Scene.CreateEntity("e0");
		f.Selection.Set(f.Scene.GetEntityId(e));
		f.Build();
		let added = f.Panel.AddTracksFromSelection(f.Panel.View);
		Test.Assert(added >= 3, "an entity with no components still animates its Transform");

		int pos = 0;
		int rot = 0;
		int scl = 0;
		for (let t in f.Panel.Clip.Tracks)
		{
			if (t.ComponentType != "Transform")
				continue;
			if (t.PropertyPath == "Position")
			{
				pos++;
				Test.Assert(t.Kind == .Float3);
			}
			else if (t.PropertyPath == "Rotation")
			{
				rot++;
				Test.Assert(t.Kind == .Quat);
			}
			else if (t.PropertyPath == "Scale")
			{
				scl++;
				Test.Assert(t.Kind == .Float3);
			}
		}
		Test.Assert((pos == 1) && (rot == 1) && (scl == 1));
	}

	[Test]
	public static void PreviewDrivesTheBuiltInTransformAndRestoresIt()
	{
		let f = scope PanelFixture("tprev");
		let e = f.Scene.CreateEntity("e0");
		f.Scene.SetLocalPosition(e, .(5.0f, 6.0f, 7.0f));
		f.Selection.Set(f.Scene.GetEntityId(e));
		f.Build();
		f.Panel.Clip.Tracks.Add(PanelFixture.MakePositionTrackOn("Transform", 100.0f, 200.0f, 300.0f));

		f.Panel.OnScrubTimeChanged(0.5f);
		Test.Assert(f.Panel.IsPreviewing);
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.X, 100.0f));
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.Y, 200.0f));
		Test.Assert(!f.Stack.CanUndo, "the preview never dirties the document");

		f.Panel.StopPreview();
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.X, 5.0f));
		Test.Assert(Near(f.Scene.GetLocalTransform(e).Position.Z, 7.0f));
	}

	[Test]
	public static void TransportAdvancesThePlayheadEachTickAndLoopsByDefault()
	{
		let f = scope RampFixture();
		Test.Assert(!f.Panel.IsPlaying);
		f.Panel.Play();
		Test.Assert(f.Panel.IsPlaying);

		f.Panel.Tick(0.3f, false);
		Test.Assert(Near(f.Panel.PlayheadTime, 0.3f));
		f.Panel.Tick(0.3f, false);
		Test.Assert(Near(f.Panel.PlayheadTime, 0.6f));

		// 0.6 + 0.6 = 1.2 wraps to 0.2 with loop on, still playing.
		f.Panel.Tick(0.6f, false);
		Test.Assert(Near(f.Panel.PlayheadTime, 0.2f));
		Test.Assert(f.Panel.IsPlaying);
	}

	[Test]
	public static void LoopOffClampsAtTheEndAndStops()
	{
		let f = scope RampFixture();
		f.Panel.SetLooping(false);
		Test.Assert(!f.Panel.IsLooping);
		f.Panel.Play();
		f.Panel.Tick(2.0f, false); // past the end
		Test.Assert(Near(f.Panel.PlayheadTime, 1.0f));
		Test.Assert(!f.Panel.IsPlaying);
	}

	[Test]
	public static void StopRewindsThePlayheadToZero()
	{
		let f = scope RampFixture();
		f.Panel.Play();
		f.Panel.Tick(0.5f, false);
		Test.Assert(Near(f.Panel.PlayheadTime, 0.5f));
		f.Panel.Stop();
		Test.Assert(Near(f.Panel.PlayheadTime, 0.0f));
		Test.Assert(!f.Panel.IsPlaying);
	}

	[Test]
	public static void SimulateStopsEditorPlayback()
	{
		let f = scope RampFixture();
		f.Panel.Play();
		f.Panel.Tick(0.1f, false);
		Test.Assert(f.Panel.IsPlaying);
		f.Panel.Tick(0.1f, true); // Simulate begins
		Test.Assert(!f.Panel.IsPlaying);
	}

	[Test]
	public static void PlaybackDrivesTheLivePreviewAndScrubIsIgnoredWhilePlaying()
	{
		let f = scope RampFixture();
		f.Panel.Play();
		f.Panel.Tick(0.5f, false);
		Test.Assert(Near(f.X, 5.0f), "the ramp midpoint previewed by the advance loop");

		// A scrub while actively playing is ignored: the transport owns the playhead.
		f.Panel.OnScrubTimeChanged(0.9f);
		Test.Assert(Near(f.Panel.PlayheadTime, 0.5f), "unchanged");
		Test.Assert(Near(f.X, 5.0f), "not jumped to 9");

		// Stopped: a scrub repositions the clock and the preview.
		f.Panel.Stop();
		f.Panel.OnScrubTimeChanged(0.9f);
		Test.Assert(Near(f.Panel.PlayheadTime, 0.9f));
		Test.Assert(Near(f.X, 9.0f));
	}

	[Test]
	public static void DopesheetLaneFeedAndKeyDragCommitsAMoveAndReselects()
	{
		let f = scope PanelFixture("dope");
		f.Build();

		// A Float3 position track with keys at 0 and 1 on each channel.
		let track = new PropertyTrack();
		track.ComponentType.Set("Transform");
		track.PropertyPath.Set("Position");
		track.Kind = .Float3;
		for (int c < 3)
		{
			track.Channels[c].AddKey(PanelFixture.Kv(0.0f, 0.0f));
			track.Channels[c].AddKey(PanelFixture.Kv(1.0f, 5.0f));
		}
		f.Panel.Clip.Tracks.Add(track);
		f.Panel.OnClipViewRebuilt(); // the dopesheet lanes rebuild from the clip

		let dope = f.Panel.Dopesheet;
		dope.SetPixelsPerSecond(100.0f); // t maps to gutter + t * 100; lane 0 centre y = 24 + 11
		Test.Assert(dope.LaneCount == 1);
		let gutter = dope.LabelColumnWidth;
		Test.Assert(Near(gutter, 140.0f));

		// The t=1 marker drags by +50px, +0.5s.
		let down = scope MouseEventArgs();
		down.Button = .Left;
		down.X = gutter + 100.0f;
		down.Y = 35.0f;
		dope.OnMouseDown(down);
		Test.Assert(dope.IsKeySelected(0, 1));
		let move = scope MouseEventArgs();
		move.Button = .Left;
		move.X = gutter + 150.0f;
		move.Y = 35.0f;
		dope.OnMouseMove(move);
		let up = scope MouseEventArgs();
		up.Button = .Left;
		up.X = gutter + 150.0f;
		up.Y = 35.0f;
		dope.OnMouseUp(up);

		// Every channel's second key moved 1.0 to 1.5 as one undo step, and the marker
		// re-selected by time.
		Test.Assert(f.Panel.Clip.Tracks.Count == 1);
		let ch0 = f.Panel.Clip.Tracks[0].Channels[0].Keys;
		Test.Assert(ch0.Count == 2);
		Test.Assert(Near(ch0[1].Time, 1.5f));
		Test.Assert(Near(f.Panel.Clip.Tracks[0].Channels[2].Keys[1].Time, 1.5f));
		Test.Assert(f.Stack.CanUndo);
		Test.Assert(dope.IsKeySelected(0, 1));

		// Undo restores t=1.
		f.Stack.Undo();
		Test.Assert(Near(f.Panel.Clip.Tracks[0].Channels[0].Keys[1].Time, 1.0f));
	}

	[Test]
	public static void SetClipDurationAuthorsTheLengthClampedToTheLastKeyUndoable()
	{
		let f = scope PanelFixture("dur");
		f.Build();

		// An empty clip, computed 0: a 5s length authors.
		f.Panel.SetClipDuration(5.0f);
		Test.Assert(Near(f.Panel.Clip.Duration, 5.0f));
		Test.Assert(f.Stack.CanUndo);
		f.Stack.Undo();
		Test.Assert(Near(f.Panel.Clip.Duration, 0.0f));

		// A track with a key at 3, computed 3: authoring 1s clamps up to 3.
		let track = new PropertyTrack();
		track.ComponentType.Set("Transform");
		track.PropertyPath.Set("Position");
		track.Kind = .Float3;
		track.Channels[0].AddKey(PanelFixture.Kv(3.0f, 0.0f));
		f.Panel.Clip.Tracks.Add(track);
		f.Panel.SetClipDuration(1.0f);
		Test.Assert(Near(f.Panel.Clip.Duration, 3.0f));
	}

	[Test]
	public static void ExclusiveEmptyStateNoClipMeansNoEditingSurface()
	{
		let f = scope PanelFixture("empty-state");
		f.Build();
		// No clip loaded: the whole editing surface, inside the body the dopesheet lives in, is
		// Gone; only the empty-state message with Create and Open remains.
		Test.Assert(!f.Panel.HasClip);
		let body = f.Panel.Dopesheet.Parent;
		Test.Assert(body != null);
		Test.Assert(body.Visibility == .Gone);
	}

	[Test]
	public static void ReadSceneValueCapturesTheLiveTransformAndComponentValues()
	{
		let f = scope PanelFixture("capture");
		let e = f.Scene.CreateEntity("hero");
		var t = f.Scene.GetLocalTransform(e);
		t.Position = .(4.0f, 5.0f, 6.0f);
		f.Scene.SetLocalTransform(e, t);
		f.Selection.Set(f.Scene.GetEntityId(e));
		f.Build();

		// The key-from-scene source: the bound entity's live transform.
		let v = f.Panel.ReadSceneValue("Transform", "Position");
		Test.Assert(v.HasValue);
		Test.Assert(v.Kind == .Float3);
		Test.Assert(Near(v.Vector.X, 4.0f));
		Test.Assert(Near(v.Vector.Z, 6.0f));

		// Unresolvable paths answer no value, the warn-and-skip contract.
		Test.Assert(!f.Panel.ReadSceneValue("Transform", "nope").HasValue);
		Test.Assert(!f.Panel.ReadSceneValue("NoSuchComponent", "Position").HasValue);

		// Clearing the selection changes nothing: the binding is session state.
		f.Selection.Clear();
		Test.Assert(f.Panel.ReadSceneValue("Transform", "Position").HasValue);

		// No bound entity: no value, the workflow's capture gate.
		f.Panel.BindEntity(.Empty);
		Test.Assert(!f.Panel.ReadSceneValue("Transform", "Position").HasValue);
	}
}
