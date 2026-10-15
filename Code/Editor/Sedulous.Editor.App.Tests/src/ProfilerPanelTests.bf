using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.Profiler;
using Sedulous.Profiler.UI;
using Sedulous.Profiler.Capture;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The editor's Profiler tab over a test's own store: it records into its own recording and
/// follows the newest frame, saves and opens captures, lets the store go when it stops or
/// closes, and keeps its parts' sizes in a small pane.
class ProfilerPanelTests
{
	private static void RunFrames(Sedulous.Profiler.Profiler p, uint32 count)
	{
		for (uint32 f < count)
		{
			p.BeginFrame();
			if (p.BeginScope("Editor.Frame"))
				p.EndScope();
			p.EndFrame();
		}
	}

	private static ProfilerPanel MakePanel(Sedulous.Profiler.Profiler store, CaptureRecorder recorder, StringView folder)
	{
		let seams = new ProfilerPanelSeams();
		seams.Store = store;
		seams.Recorder = recorder;
		seams.Folder.Set(folder);
		return new ProfilerPanel(seams);
	}

	[Test]
	public static void RecordCopiesSettledFramesAndFollowsTheNewestStopKeepsThem()
	{
		let store = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		let panel = MakePanel(store, recorder, "scratch_profiler_panel");
		defer panel.ReleaseRef();
		Test.Assert(!panel.IsRecording);
		Test.Assert(!store.Armed);
		Test.Assert(panel.StatusText.Contains("Play-in-editor", true), "it says what it shows: the whole process");

		store.Arm(); // another viewer (a PIE game's overlay) already watching
		RunFrames(store, 3);
		panel.Start();
		Test.Assert(panel.IsRecording);
		RunFrames(store, 10); // frames 3..12
		panel.Update();
		Test.Assert(panel.Recording.OldestFrame == 3);
		Test.Assert(panel.Recording.NewestFrame == 12 - ProfileRecording.SettleFrames);
		// Following: the newest settled frame is the selection, in every view.
		Test.Assert(panel.Selection.First == panel.Recording.NewestFrame);
		Test.Assert(panel.Table.Rows.Length == 1);
		Test.Assert(panel.StatusText.Contains("Recording", true));

		// A chosen frame stops the following.
		var chosen = FrameRange();
		chosen.First = 4;
		chosen.Last = 5;
		chosen.Empty = false;
		panel.Select(chosen);
		RunFrames(store, 3);
		panel.Update();
		Test.Assert((panel.Selection.First == 4) && (panel.Selection.Last == 5));

		panel.Stop();
		Test.Assert(!panel.IsRecording);
		Test.Assert(panel.Recording.NewestFrame == 15, "the rest taken as they were");
		Test.Assert(store.Armed, "the other viewer's arm is still held");
		store.Disarm();
		Test.Assert(!store.Armed);
		Test.Assert(store.OldestKeptFrame == 0, "the store's history untouched");
		RunFrames(store, 2);
		panel.Update(); // stopped: nothing more
		Test.Assert(panel.Recording.NewestFrame == 15);
	}

	[Test]
	public static void SaveWritesACaptureOpenShowsItLiveGoesBack()
	{
		let store = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		recorder.SetBuild("Linux64", "test-build");
		let panel = MakePanel(store, recorder, "scratch_profiler_panel");
		defer panel.ReleaseRef();
		Test.Assert(panel.SaveRecording(.. scope .()).IsEmpty, "nothing recorded yet");

		panel.Start();
		RunFrames(store, 8);
		panel.Stop();
		let path = panel.SaveRecording(.. scope .());
		Test.Assert(!path.IsEmpty);
		Test.Assert(path.EndsWith(".aeprofile"));
		Test.Assert(path.Contains("scratch_profiler_panel/Editor-"), path);
		Test.Assert(panel.StatusText.Contains("Saved 8 frames", true), scope String(panel.StatusText));

		Test.Assert(panel.OpenCapture(path));
		Test.Assert(panel.ViewingCapture);
		Test.Assert(panel.Source != null);
		Test.Assert(panel.Source !== panel.Recording);
		Test.Assert(panel.Source.NewestFrame == panel.Recording.NewestFrame);
		Test.Assert(panel.Selection.First == panel.Source.NewestFrame, "the newest frame shown");
		Test.Assert(panel.StatusText.Contains("test-build", true), scope String(panel.StatusText));
		Test.Assert(panel.SaveRecording(.. scope .()).IsEmpty, "a capture is already a file");

		panel.ShowLive();
		Test.Assert(!panel.ViewingCapture);
		Test.Assert(panel.Source === panel.Recording);

		Test.Assert(!panel.OpenCapture("scratch_profiler_panel/not-there.aeprofile"));
		Test.Assert(panel.StatusText.Contains("Could not read", true));
		Test.Assert(!panel.ViewingCapture);
	}

	[Test]
	public static void RecordingWhileClosingLetsTheStoreGo()
	{
		let store = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		{
			let panel = MakePanel(store, recorder, "scratch_profiler_panel");
			panel.Start();
			Test.Assert(store.Armed);
			panel.ReleaseRef();
		}
		Test.Assert(!store.Armed);
	}

	[Test]
	public static void ItsPartsKeepTheirSizesASmallerPaneScrollsALargerOneFills()
	{
		let store = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		let panel = MakePanel(store, recorder, "scratch_profiler_panel");
		let context = scope UIContext();
		let root = new RootView();
		context.AddRootView(root);
		defer { context.RemoveRootView(root); root.ReleaseRef(); }
		root.AddView(panel); // consumes the panel's reference
		void LayOut(float w, float h)
		{
			root.ViewportSize = .(w, h);
			context.UpdateRootView(root);
		}

		// The Console's pane in the default layout, about 560 by 180: the body keeps its
		// minimum and the pane scrolls it.
		LayOut(560, 180);
		Test.Assert(Math.Abs(panel.Body.Width - ProfilerPanelBody.MinWidth) < 0.5f, scope $"{panel.Body.Width}");
		Test.Assert(Math.Abs(panel.Body.Height - ProfilerPanelBody.MinHeight) < 0.5f, scope $"{panel.Body.Height}");
		Test.Assert(Math.Abs(panel.Strip.Height - FrameTimeGraph.GraphHeight) < 0.5f);
		Test.Assert(Math.Abs(panel.Scroller.Width - 560.0f) < 0.5f);
		Test.Assert(Math.Abs(panel.Scroller.Height - 180.0f) < 0.5f);
		let tableTop = panel.Table.Bounds.Y;
		Test.Assert(panel.Counters.Bounds.Y >= tableTop + panel.Table.Height);
		Test.Assert(panel.Counters.Bounds.Y + panel.Counters.Height <= ProfilerPanelBody.MinHeight + 0.5f);

		// A pane larger than the minimum: the body fills it, the timeline and the table taking
		// the room.
		LayOut(1600, 600);
		Test.Assert(Math.Abs(panel.Body.Width - 1600.0f) < 0.5f, scope $"{panel.Body.Width}");
		Test.Assert(Math.Abs(panel.Body.Height - 600.0f) < 0.5f);
		Test.Assert(Math.Abs(panel.Table.Width - ProfilerPanelBody.SideMax) < 0.5f);
		Test.Assert(Math.Abs(panel.TimelineView.Width - (1600.0f - ProfilerPanelBody.SideMax - ProfilerPanelBody.Gap)) < 0.5f);
		Test.Assert(Math.Abs(ProfilerPanelBody.SideWidth(640.0f) - ProfilerPanelBody.SideMin) < 0.001f);
	}
}
