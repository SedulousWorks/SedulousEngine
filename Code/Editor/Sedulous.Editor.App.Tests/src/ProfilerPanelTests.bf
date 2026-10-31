using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Capture;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The editor's Profiler page (X7 of Raptor's editor-gui spec) over its markup
/// (Data/Editor/Profiler.xml), on a test's own store: Record arms it and copies settled frames into
/// the page's recording, following the newest until a frame is chosen, Live following again; Stop
/// lets the store go and keeps the frames; another viewer's arm and the store's history are left
/// alone; Stop on spike ends the recording at the first frame over its time; a plot per counter;
/// Longest and Median; Save writes a capture that Open shows, and Live goes back; Clear drops the
/// frames, a recording going on.
class ProfilerPanelTests
{
	private static Node LoadPage()
	{
		RegisterToolkitElements();
		RegisterProfilerElements();
		return PagesBed.LoadMarkup(ProfilerPanel.cMarkupPath);
	}

	/// `count` frames of `ms` each (a busy wait, so a spike is a real one).
	private static void RunFrames(Sedulous.Profiler.Profiler p, uint32 count, double ms = 0.0)
	{
		for (uint32 f < count)
		{
			p.BeginFrame();
			if (p.BeginScope("Editor.Frame"))
			{
				if (ms > 0.0)
				{
					let until = ProfileClock.Now() + (int64)(ms / 1000.0 * (double)ProfileClock.TicksPerSecond);
					while (ProfileClock.Now() < until)
					{
					}
				}
				p.EndScope();
			}
			p.EndFrame();
		}
	}

	private class Bed
	{
		public Sedulous.Profiler.Profiler Store = new .() ~ delete _;
		public CaptureRecorder Recorder = new .() ~ delete _;
		public ProfilerPanel Panel ~ delete _;

		public this()
		{
			let seams = new ProfilerPanelSeams();
			seams.Store = Store;
			seams.Recorder = Recorder;
			seams.Folder.Set("scratch_profiler_panel");
			Panel = new ProfilerPanel(seams, LoadPage());
			Test.Assert(Panel.Content != null);
		}

		public T Find<T>(StringView id) where T : Node => Panel.Content.FindElement(id) as T;
	}

	[Test]
	public static void ItsViewsOnOneFocusFromItsMarkup()
	{
		let bed = scope Bed();
		let strip = bed.Find<FrameStrip>("profiler-strip");
		let timeline = bed.Find<ProfileTimeline>("profiler-timeline");
		let table = bed.Find<ScopeTable>("profiler-table");
		let detail = bed.Find<ScopeDetail>("profiler-detail");
		Test.Assert((strip != null) && (timeline != null) && (table != null) && (detail != null));
		Test.Assert(strip.Focus == bed.Panel.Focus);
		Test.Assert(timeline.Focus == bed.Panel.Focus);
		Test.Assert(table.Focus == bed.Panel.Focus);
		Test.Assert(detail.Focus == bed.Panel.Focus);
		Test.Assert(strip.Axis == bed.Panel.Axis);
		Test.Assert(Math.Abs(strip.BudgetMs - 1000.0f / 60.0f) < 0.001f); // the markup's 60 fps
		bed.Panel.SetBudgetChoice(3);
		Test.Assert(strip.BudgetMs == 0.0f);
		Test.Assert(bed.Panel.StatusText.Contains("Play-in-editor", true)); // it says what it shows: the whole process
	}

	[Test]
	public static void RecordCopiesSettledFramesAndFollowsTheNewestStopKeepsThem()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Panel.IsRecording);
		Test.Assert(!bed.Store.Armed);

		bed.Store.Arm(); // another viewer (a PIE game's overlay) already watching
		RunFrames(bed.Store, 3);
		bed.Panel.Start();
		Test.Assert(bed.Panel.IsRecording);
		Test.Assert(bed.Find<ToolButton>("profiler-record").Checked);
		RunFrames(bed.Store, 10); // frames 3..12
		bed.Panel.Update();
		Test.Assert(bed.Panel.Recording.OldestFrame == 3);
		Test.Assert(bed.Panel.Recording.NewestFrame == 12 - ProfileRecording.SettleFrames);
		// Following: the newest settled frame is the one chosen, in every view.
		Test.Assert(bed.Panel.IsFollowing);
		Test.Assert(bed.Find<ToolButton>("profiler-live").Checked);
		Test.Assert(bed.Panel.Focus.Frames.First == bed.Panel.Recording.NewestFrame);
		Test.Assert(bed.Find<ScopeTable>("profiler-table").Rows.Length == 2); // Main, Editor.Frame
		Test.Assert(bed.Panel.StatusText.Contains("Recording", true));

		// A chosen frame stops the following; Live brings it back.
		bed.Panel.SetFollowing(false);
		bed.Panel.Focus.SetFrame(4);
		RunFrames(bed.Store, 3);
		bed.Panel.Update();
		Test.Assert(bed.Panel.Focus.Frames.First == 4);
		Test.Assert(!bed.Find<ToolButton>("profiler-live").Checked);
		bed.Panel.ShowLive();
		Test.Assert(bed.Panel.Focus.Frames.First == bed.Panel.Recording.NewestFrame);

		bed.Panel.Stop();
		Test.Assert(!bed.Panel.IsRecording);
		Test.Assert(!bed.Find<ToolButton>("profiler-record").Checked);
		Test.Assert(bed.Panel.Recording.NewestFrame == 15); // the rest taken as they were
		Test.Assert(bed.Store.Armed); // the other viewer's arm is still held
		bed.Store.Disarm();
		Test.Assert(!bed.Store.Armed);
		Test.Assert(bed.Store.OldestKeptFrame == 0); // the store's history untouched
		RunFrames(bed.Store, 2);
		bed.Panel.Update(); // stopped: nothing more
		Test.Assert(bed.Panel.Recording.NewestFrame == 15);
	}

	[Test]
	public static void StopOnSpikeEndsTheRecordingAtTheFirstFrameOverItsTime()
	{
		let bed = scope Bed();
		bed.Panel.SetSpikeChoice(0); // 25 ms
		bed.Panel.SetStopOnSpike(true);
		Test.Assert(bed.Find<ToolButton>("profiler-spike").Checked);
		bed.Panel.Start();
		RunFrames(bed.Store, 2);
		RunFrames(bed.Store, 1, 40.0); // frame 2: the spike
		RunFrames(bed.Store, 4);
		bed.Panel.Update();
		Test.Assert(!bed.Panel.IsRecording);
		Test.Assert(!bed.Panel.IsFollowing);
		Test.Assert(bed.Panel.Focus.Frames.First == 2);
		Test.Assert(bed.Panel.StatusText.Contains("Stopped on frame 2", true));
	}

	[Test]
	public static void APlotPerCounterLongestAndMedianChooseFrames()
	{
		let bed = scope Bed();
		let draws = bed.Store.RegisterCounter("Draw calls", .Count);
		bed.Panel.Start();
		for (uint32 f < 6)
		{
			bed.Store.SetCounter(draws, (double)f);
			RunFrames(bed.Store, 1, (f == 3) ? 12.0 : 0.0);
		}
		bed.Panel.Stop();
		Test.Assert(bed.Panel.CounterPlotCount == 1);
		Test.Assert(bed.Find<Sedulous.GUI.Panel>("profiler-counters").ChildCount == 1);
		bed.Panel.ChooseLongest();
		Test.Assert(bed.Panel.Focus.Frames.First == 3);
		Test.Assert(!bed.Panel.IsFollowing);
		bed.Panel.ChooseMedian();
		Test.Assert(bed.Panel.Focus.Frames.First != 3);
	}

	[Test]
	public static void SaveWritesACaptureOpenShowsItLiveGoesBack()
	{
		let bed = scope Bed();
		bed.Recorder.SetBuild("Linux64", "test-build");
		Test.Assert(bed.Panel.SaveRecording(.. scope .()).IsEmpty); // nothing recorded yet

		bed.Panel.Start();
		RunFrames(bed.Store, 8);
		bed.Panel.Stop();
		let path = bed.Panel.SaveRecording(.. scope .());
		Test.Assert(!path.IsEmpty);
		Test.Assert(path.EndsWith(".aeprofile"));
		Test.Assert(path.Contains("scratch_profiler_panel/Editor-"), path);
		Test.Assert(bed.Panel.StatusText.Contains("Saved 8 frames", true), scope String(bed.Panel.StatusText));

		Test.Assert(bed.Panel.OpenCapture(path));
		Test.Assert(bed.Panel.ViewingCapture);
		let shown = bed.Panel.Focus.Source;
		Test.Assert(shown != null);
		Test.Assert(shown !== bed.Panel.Recording);
		Test.Assert(shown.NewestFrame == bed.Panel.Recording.NewestFrame);
		Test.Assert(bed.Panel.Focus.Frames.First == shown.NewestFrame); // the newest frame shown
		Test.Assert(bed.Panel.StatusText.Contains("test-build", true), scope String(bed.Panel.StatusText));
		Test.Assert(bed.Panel.SaveRecording(.. scope .()).IsEmpty); // a capture is already a file

		bed.Panel.ShowLive();
		Test.Assert(!bed.Panel.ViewingCapture);
		Test.Assert(bed.Panel.Focus.Source === bed.Panel.Recording);

		Test.Assert(!bed.Panel.OpenCapture("scratch_profiler_panel/not-there.aeprofile"));
		Test.Assert(bed.Panel.StatusText.Contains("Could not read", true));
		Test.Assert(!bed.Panel.ViewingCapture);
	}

	[Test]
	public static void RecordingWhileClosingLetsTheStoreGo()
	{
		let store = scope Sedulous.Profiler.Profiler();
		let recorder = scope CaptureRecorder();
		{
			let seams = new ProfilerPanelSeams();
			seams.Store = store;
			seams.Recorder = recorder;
			seams.Folder.Set("scratch_profiler_panel");
			let panel = new ProfilerPanel(seams, LoadPage());
			panel.Start();
			Test.Assert(store.Armed);
			delete panel;
		}
		Test.Assert(!store.Armed);
	}

	[Test]
	public static void ClearDropsTheFramesRecordedARecordingGoesOnFromTheNext()
	{
		let bed = scope Bed();
		bed.Panel.Start();
		RunFrames(bed.Store, 10);
		bed.Panel.Update();
		Test.Assert(bed.Panel.Recording.HasFrames);
		Test.Assert(bed.Find<ToolButton>("profiler-clear").HandleActivate());
		Test.Assert(!bed.Panel.Recording.HasFrames);
		Test.Assert(bed.Panel.IsRecording);
		Test.Assert(bed.Panel.Focus.Frames.Empty);
		RunFrames(bed.Store, 8);
		bed.Panel.Update();
		Test.Assert(bed.Panel.Recording.HasFrames);
		Test.Assert(bed.Panel.Recording.OldestFrame == 6); // none it had: the next to settle on
		Test.Assert(bed.Panel.IsFollowing);
		bed.Panel.Stop();
		bed.Panel.Clear();
		Test.Assert(!bed.Panel.Recording.HasFrames);
		Test.Assert(!bed.Panel.IsRecording);
	}
}
