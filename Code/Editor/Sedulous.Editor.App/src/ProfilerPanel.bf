using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Profiler;
using Sedulous.Profiler.GUI;
using Sedulous.Profiler.Capture;

namespace Sedulous.Editor.App;

// ProfilerPanel: the editor's Profiler (X7 of Raptor's editor-gui spec), a tab in the page area that
// floats as any page does. It records the editor process, every page, viewport preview and
// Play-in-editor run in one frame, and says so: a game's own numbers come from its player (the
// overlay, or a capture from it opened here). Its frame is markup (Data/Editor/Profiler.xml); its
// views are Profiler.GUI's, all on one focus.
//
// Record starts copying the store's frames into the panel's own recording and Stop ends it, so
// stopping, the choices and a longer history than the store keeps never touch the store another
// viewer reads (a PIE game's overlay). While Live, the newest frame is chosen as it comes; a choice
// on the strip stops that, and Live brings it back (from a capture, the editor's own recording
// again). Stop on spike ends the recording at the first frame over its time, that frame chosen.
// Save writes the recording as a capture (.aeprofile and its Chrome trace JSON) to
// <user-data>/profiles; Open shows a capture from there, a player's from a Deck or a phone copied in.

/// What the panel records and where its captures go: the process's store and recorder (a test's
/// own), the folder (made when missing) and the picker it opens a capture through.
class ProfilerPanelSeams
{
	/// BORROWED, both.
	public Sedulous.Profiler.Profiler Store;
	/// The platform and build a saved capture names; null leaves them empty.
	public CaptureRecorder Recorder;
	public String Folder = new .() ~ delete _;
	/// Opens a picker's request (OWNERSHIP of it transfers); null: Open does nothing. Owned.
	public delegate void(PickerRequest request) Pick ~ delete _;
}

class ProfilerPanel : IProfileFocusClient
{
	/// Its frame, under the data root.
	public const String cMarkupPath = "Editor/Profiler.xml";
	/// The budget's choices, the combo's order: 30, 60 and 120 fps, then none.
	public static readonly float[4] cBudgets = .(1000.0f / 30.0f, 1000.0f / 60.0f, 1000.0f / 120.0f, 0.0f);
	/// Stop on spike's times, the combo's order.
	public static readonly float[4] cSpikes = .(25.0f, 33.3f, 50.0f, 100.0f);

	/// A reference of ours; the panel showing it takes its own. Declared first: it goes last.
	private Node mContent ~ _?.ReleaseRef();
	private ProfilerPanelSeams mSeams ~ delete _;
	private LiveProfileSource mLive ~ delete _;
	private ProfileRecording mRecording = new .() ~ delete _;
	/// Shown instead of the recording, when open.
	private ProfileCapture mCapture = null ~ delete _;
	private String mCapturePath = new .() ~ delete _;
	private ProfileFocus mFocus = new .() ~ _.ReleaseRef();
	private FrameAxis mAxis = new .() ~ _.ReleaseRef();
	private bool mRecordingNow = false;
	private bool mFollowing = true;
	private bool mStopOnSpike = false;
	private float mSpikeMs = 50.0f;
	private String mStatusText = new .() ~ delete _;

	// Borrowed from the content.
	private FrameStrip mStrip = null;
	private ProfileTimeline mTimeline = null;
	private ScopeTable mTable = null;
	private ScopeDetail mDetail = null;
	private Sedulous.GUI.Panel mCounters = null;
	private ToolButton mRecord = null;
	private ToolButton mLiveButton = null;
	private ToolButton mSave = null;
	private ToolButton mSpike = null;
	/// A reference each, the counters' panel another.
	private List<CounterPlot> mCounterPlots = new .() ~ { for (let plot in _) plot.ReleaseRef(); delete _; };

	/// Over its frame `content` (the markup's: its parts by id). TAKES OWNERSHIP of the seams and
	/// of a reference to `content`; null shows nothing.
	public this(ProfilerPanelSeams seams, Node content)
	{
		mSeams = seams;
		mContent = content;
		mLive = new .(seams.Store);
		mFocus.Join(this);
		if (mContent == null)
			return;
		mStrip = Find<FrameStrip>("profiler-strip");
		mTimeline = Find<ProfileTimeline>("profiler-timeline");
		mTable = Find<ScopeTable>("profiler-table");
		mDetail = Find<ScopeDetail>("profiler-detail");
		mCounters = Find<Sedulous.GUI.Panel>("profiler-counters");
		if (mStrip != null)
		{
			mStrip.Focus = mFocus;
			mStrip.Axis = mAxis;
			mStrip.SetOnFramesPicked(new [=this] () => { SetFollowing(false); });
		}
		if (mTimeline != null)
			mTimeline.Focus = mFocus;
		if (mTable != null)
			mTable.Focus = mFocus;
		if (mDetail != null)
			mDetail.Focus = mFocus;

		mRecord = Find<ToolButton>("profiler-record");
		if (mRecord != null)
			mRecord.SetOnToggled(new [=this] (on) => { if (on) Start(); else Stop(); });
		mLiveButton = Find<ToolButton>("profiler-live");
		if (mLiveButton != null)
			mLiveButton.SetOnToggled(new [=this] (on) => { if (on) ShowLive(); else SetFollowing(false); });
		if (let open = Find<ToolButton>("profiler-open"))
			open.SetOnClick(new [=this] () => { PickCapture(); });
		if (let clear = Find<ToolButton>("profiler-clear"))
			clear.SetOnClick(new [=this] () => { Clear(); });
		mSave = Find<ToolButton>("profiler-save");
		if (mSave != null)
			mSave.SetOnClick(new [=this] () => { SaveRecording(.. scope .()); });
		if (let budget = Find<Sedulous.GUI.ComboBox>("profiler-budget"))
		{
			budget.SetOnSelectionChanged(new [=this] (index) => { SetBudgetChoice(index); });
			SetBudgetChoice(budget.SelectedIndex);
		}
		mSpike = Find<ToolButton>("profiler-spike");
		if (mSpike != null)
			mSpike.SetOnToggled(new [=this] (on) => { SetStopOnSpike(on); });
		if (let spike = Find<Sedulous.GUI.ComboBox>("profiler-spike-ms"))
		{
			spike.SetOnSelectionChanged(new [=this] (index) => { SetSpikeChoice(index); });
			SetSpikeChoice(spike.SelectedIndex);
		}
		if (let longest = Find<Sedulous.GUI.Button>("profiler-longest"))
			longest.SetOnClick(new [=this] () => { ChooseLongest(); });
		if (let median = Find<Sedulous.GUI.Button>("profiler-median"))
			median.SetOnClick(new [=this] () => { ChooseMedian(); });
		if (let zoom = Find<Sedulous.GUI.Button>("profiler-zoom-longest"))
			zoom.SetOnClick(new [=this] () => { ZoomToLongest(); });
		if (let filter = Find<Sedulous.GUI.TextField>("profiler-filter"))
			filter.SetOnTextChanging(new [=this] (text) => { if (mTable != null) mTable.SetFilter(text); });
		ShowLive();
	}

	public ~this()
	{
		if (mRecordingNow)
			mSeams.Store.Disarm();
		mFocus.Leave(this);
		mFocus.SetSource(null);
	}

	/// Its frame (ours; the panel showing it takes its own reference).
	public Node Content => mContent;
	public ProfileFocus Focus => mFocus;
	public FrameAxis Axis => mAxis;

	/// Starts recording the editor process afresh (arming the store, counted).
	public void Start()
	{
		if (mRecordingNow)
			return;
		ShowLive();
		mRecording.Begin(mLive);
		mSeams.Store.Arm();
		mRecordingNow = true;
		mAxis.Fit(0, 0); // fitting again: it follows the recording from here
		SyncToggles();
		Refresh();
	}

	/// Stops: the frames recorded stay to read and save; the store is let go.
	public void Stop()
	{
		if (!mRecordingNow)
			return;
		mRecording.Pull(mLive, 0); // the rest, as they are
		mSeams.Store.Disarm();
		mRecordingNow = false;
		SyncToggles();
		Refresh();
	}

	public bool IsRecording => mRecordingNow;
	public bool IsFollowing => mFollowing;

	/// Drops the frames recorded; a recording goes on from the next frame (the old panel's Clear).
	/// The page shows the recording again, nothing chosen.
	public void Clear()
	{
		mRecording.Clear();
		if (mCapture != null)
		{
			let old = mCapture;
			mCapture = null;
			mCapturePath.Clear();
			SetSource(mRecording);
			delete old;
		}
		mFocus.SetFrames(FrameRange());
		mAxis.Fit(0, 0);
		SetFollowing(mRecordingNow);
		Refresh();
	}

	/// Each frame: the store's newly settled frames taken while recording; Stop on spike stops at
	/// the first frame over its time.
	public void Update()
	{
		if (!mRecordingNow)
			return;
		let before = mRecording.FrameCount;
		let newest = mRecording.NewestFrame;
		let next = mRecording.HasFrames ? (newest + 1) : 0;
		mRecording.Pull(mLive);
		if ((mRecording.FrameCount == before) && (mRecording.NewestFrame == newest))
			return;
		if (mStopOnSpike && mRecording.HasFrames)
		{
			for (var n = Math.Max(next, mRecording.OldestFrame); n <= mRecording.NewestFrame; n++)
			{
				let frame = mRecording.Frame(n);
				if (frame == null)
					continue;
				let ms = ProfileWindow.TicksToMs(frame.EndTick - frame.BeginTick, mRecording.TickFrequency);
				if (ms <= mSpikeMs)
					continue;
				Stop();
				SetFollowing(false);
				mFocus.SetFrame(n);
				SetStatus(scope $"Stopped on frame {n}: {ms:F2} ms, over {mSpikeMs:F0} ms");
				return;
			}
		}
		Refresh();
	}

	/// Writes the recording as a capture; appends the .aeprofile's path to `outPath` (nothing:
	/// nothing to save, or it could not be written, which the log says).
	public void SaveRecording(String outPath)
	{
		if ((mCapture != null) || !mRecording.HasFrames)
		{
			SetStatus("Nothing to save: record first");
			return;
		}
		CreateDirectory(mSeams.Folder); // its parents too
		let basePath = scope $"{mSeams.Folder}/Editor-{DateTime.Now.Ticks}";
		let header = scope StreamHeader();
		header.TickFrequency = mRecording.TickFrequency;
		header.Application.Set("Editor");
		if (mSeams.Recorder != null)
		{
			header.Platform.Set(mSeams.Recorder.Platform);
			header.Build.Set(mSeams.Recorder.Build);
		}
		let path = CaptureRecorder.WriteCaptureFiles(mRecording, mRecording.OldestFrame, mRecording.NewestFrame, basePath, header, .. scope .());
		if (path.IsEmpty)
		{
			SetStatus(scope $"Could not save to {mSeams.Folder} (see the Console)");
			return;
		}
		SetStatus(scope $"Saved {mRecording.FrameCount} frames to {path}");
		GlobalLog(.Information, "Profiler: saved the editor's recording to {}", path);
		outPath.Append(path);
	}

	/// Shows the capture file at `path` (recording stops), its newest frame chosen. False when it
	/// cannot be read.
	public bool OpenCapture(StringView path)
	{
		let capture = new ProfileCapture();
		{
			let file = scope FileStream(path, .Read);
			if (!file.IsValid || !capture.Read(file))
			{
				delete capture;
				SetStatus(scope $"Could not read {path}");
				return false;
			}
		}
		Stop();
		// The views let the old capture go before it is deleted.
		let old = mCapture;
		mCapture = capture;
		mCapturePath.Set(path);
		SetFollowing(false);
		SetSource(mCapture);
		delete old;
		if (mCapture.HasFrames)
			mFocus.SetFrame(mCapture.NewestFrame);
		return true;
	}

	/// The editor's own recording, following its newest frame.
	public void ShowLive()
	{
		if ((mCapture != null) || (mFocus.Source == null))
		{
			let old = mCapture;
			mCapture = null;
			mCapturePath.Clear();
			SetSource(mRecording);
			delete old;
		}
		SetFollowing(true);
		Refresh();
	}

	public bool ViewingCapture => mCapture != null;
	public ProfileRecording Recording => mRecording;
	public StringView StatusText => mStatusText;

	/// Follows the newest frame as it comes, or not (a choice on the strip stops it).
	public void SetFollowing(bool following)
	{
		mFollowing = following;
		SyncToggles();
		if (following)
			Refresh();
	}

	/// The budget in ms (0: none).
	public void SetBudgetChoice(int32 index)
	{
		let at = ((index >= 0) && (index < cBudgets.Count)) ? index : 1;
		if (mStrip != null)
			mStrip.BudgetMs = cBudgets[at];
	}

	/// Stop on spike's time.
	public void SetSpikeChoice(int32 index)
	{
		let at = ((index >= 0) && (index < cSpikes.Count)) ? index : 2;
		mSpikeMs = cSpikes[at];
	}

	public void SetStopOnSpike(bool on)
	{
		mStopOnSpike = on;
		if ((mSpike != null) && (mSpike.Checked != on))
			mSpike.Checked = on;
	}

	public bool StopsOnSpike => mStopOnSpike;

	/// The longest and the median frame held, chosen.
	public void ChooseLongest()
	{
		if (mFocus.Source != null)
			ChooseFrame(ProfileFrames.LongestFrame(mFocus.Source, ProfileFrames.AllFrames(mFocus.Source)));
	}

	public void ChooseMedian()
	{
		if (mFocus.Source != null)
			ChooseFrame(ProfileFrames.MedianFrame(mFocus.Source, ProfileFrames.AllFrames(mFocus.Source)));
	}

	/// The chosen scope's longest call in the frames chosen, on the timeline.
	public void ZoomToLongest()
	{
		if ((mDetail != null) && (mTimeline != null) && mDetail.LongestCall(let begin, let end))
			mTimeline.ZoomTo((double)begin, (double)end);
	}

	/// The plots made for the source's counters (one each, in their order).
	public int CounterPlotCount => mCounterPlots.Count;

	public void OnProfileSourceChanged() { }
	public void OnProfileFramesChanged() => UpdateFrameText();
	public void OnProfileChoiceChanged() => UpdateScopeNote();

	/// The frame's part with this id, as a T; null when it has none.
	private T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	private void SetSource(IProfileSource source)
	{
		mAxis.Fit(0, 0); // every frame of the new source, following it as it grows
		mFocus.SetSource(source);
		SyncCounters();
		if (mSave != null)
			mSave.Enabled = mCapture == null;
		UpdateStatus();
	}

	// New frames: every view reads them again; while following, the newest is chosen.
	private void Refresh()
	{
		mFocus.SourceGrew();
		SyncCounters();
		let source = mFocus.Source;
		if (mFollowing && (source != null) && source.HasFrames)
			mFocus.SetFrame(source.NewestFrame);
		UpdateStatus();
		UpdateFrameText();
	}

	private void ChooseFrame(FrameRange frame)
	{
		if (frame.Empty)
			return;
		SetFollowing(false);
		mFocus.SetFrames(frame);
	}

	// A plot per counter the source has, under the strip.
	private void SyncCounters()
	{
		let source = mFocus.Source;
		let wanted = (source != null) ? source.Counters.Length : 0;
		if ((mCounters == null) || (wanted == mCounterPlots.Count))
			return;
		while (mCounterPlots.Count > wanted)
		{
			let plot = mCounterPlots.PopBack();
			plot.RemoveFromParent();
			plot.ReleaseRef();
		}
		while (mCounterPlots.Count < wanted)
		{
			let plot = new CounterPlot();
			plot.Focus = mFocus;
			plot.Axis = mAxis;
			plot.Counter = (uint32)mCounterPlots.Count;
			plot.SetOnFramesPicked(new [=this] () => { SetFollowing(false); });
			mCounters.AddChild(plot);
			mCounterPlots.Add(plot);
		}
	}

	private void SyncToggles()
	{
		if ((mRecord != null) && (mRecord.Checked != mRecordingNow))
			mRecord.Checked = mRecordingNow; // fires Start or Stop, which return at once
		let live = mFollowing && (mCapture == null);
		if ((mLiveButton != null) && (mLiveButton.Checked != live))
			mLiveButton.Checked = live;
	}

	private void UpdateStatus()
	{
		let text = scope String();
		if (mCapture != null)
		{
			let header = mCapture.Header;
			text.AppendF("{}: {} frames of {} ({} {})", mCapturePath, mCapture.FrameCount, header.Application, header.Platform, header.Build);
		}
		else if (mRecordingNow)
			text.AppendF("Recording the editor process: {} frames", mRecording.FrameCount);
		else if (mRecording.HasFrames)
			text.AppendF("The editor process: {} frames", mRecording.FrameCount);
		else
			text.Append("The editor process (every page, preview and Play-in-editor run): Record to start");
		SetStatus(text);
	}

	private void SetStatus(StringView text)
	{
		mStatusText.Set(text);
		if (let label = Find<Sedulous.GUI.Label>("profiler-source"))
			label.Text = mStatusText;
	}

	// The strip's bar: the frames chosen and their times.
	private void UpdateFrameText()
	{
		let source = mFocus.Source;
		let frames = mFocus.Frames;
		let frame = scope String();
		let times = scope String();
		if ((source != null) && !frames.Empty)
		{
			if (frames.First == frames.Last)
				frame.AppendF("Frame {}", frames.First);
			else
				frame.AppendF("Frames {} to {}", frames.First, frames.Last);
			let collected = scope List<FrameTime>();
			ProfileWindow.CollectFrameTimes(source, frames, collected);
			if (collected.Count == 1)
			{
				if (collected[0].HasGpu)
					times.AppendF("CPU {:F2} ms   GPU {:F2} ms", collected[0].CpuMs, collected[0].GpuMs);
				else
					times.AppendF("CPU {:F2} ms", collected[0].CpuMs);
			}
			else if (!collected.IsEmpty)
			{
				let stats = ProfileWindow.StatsOf(collected);
				times.AppendF("CPU mean {:F2}   median {:F2}   max {:F2} ms", stats.Cpu.Mean, stats.Cpu.Median, stats.Cpu.Max);
			}
		}
		if (let label = Find<Sedulous.GUI.Label>("profiler-frame"))
			label.Text = frame;
		if (let label = Find<Sedulous.GUI.Label>("profiler-frame-times"))
			label.Text = times;
		UpdateScopeNote();
	}

	// The table's bar: what it covers.
	private void UpdateScopeNote()
	{
		let note = Find<Sedulous.GUI.Label>("profiler-scope-note");
		if (note == null)
			return;
		let source = mFocus.Source;
		let frames = mFocus.Frames;
		let text = scope String();
		if ((source != null) && !frames.Empty)
		{
			if (frames.First == frames.Last)
				text.AppendF("Frame {}", frames.First);
			else
				text.AppendF("Frames {} to {}", frames.First, frames.Last);
			let span = mFocus.Span;
			if (span.Any)
				text.AppendF(", a span of {:F2} ms", ProfileWindow.TicksToMs(span.EndTick - span.BeginTick, source.TickFrequency));
		}
		note.Text = text;
	}

	private void PickCapture()
	{
		if (mSeams.Pick == null)
			return;
		CreateDirectory(mSeams.Folder);
		let request = PathPicker.Request(mSeams.Folder, scope StringView[](".aeprofile"));
		let folder = new String(mSeams.Folder);
		delete request.OnPicked;
		request.OnPicked = new [=this, =folder] (picked) => { OpenCapture(PathJoin(folder, picked, .. scope .())); } ~ delete folder;
		mSeams.Pick(request);
	}
}
