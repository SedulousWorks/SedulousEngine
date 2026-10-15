using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Profiler;
using Sedulous.Profiler.UI;
using Sedulous.Profiler.Capture;

namespace Sedulous.Editor.App;

/// What the panel records and where its captures go: the process's store and recorder (a
/// test's own), and the folder (made when missing).
class ProfilerPanelSeams
{
	/// BORROWED, both.
	public Sedulous.Profiler.Profiler Store;
	/// The platform and build a saved capture names; null leaves them empty.
	public CaptureRecorder Recorder;
	public String Folder = new .() ~ delete _;
}

/// The panel's parts at their natural sizes: the toolbar, the frame strip, then the timeline
/// beside a column of the scope table over the counters. It takes the pane's size, or its
/// minimum when the pane is smaller, and the panel scrolls it then: resize the split for more.
class ProfilerPanelBody : ViewGroup
{
	public const float MinWidth = 640.0f;
	public const float MinHeight = 360.0f;
	/// The table and counters' column, at most and at least.
	public const float SideMax = 380.0f;
	public const float SideMin = 260.0f;
	public const float Gap = 4.0f;

	/// The table and counters' column in a body `width` wide: 40%, within its bounds.
	public static float SideWidth(float width) => Math.Clamp(width * 0.4f, SideMin, SideMax);

	/// The parts it places, BORROWED: it holds them as children.
	public View Toolbar;
	public View Strip;
	public View TimelineView;
	public View Table;
	public View Counters;
	/// The pane it shows in (the panel sets it before each measure).
	public Float2 Viewport = .(MinWidth, MinHeight);

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// Unbounded along a scrolled axis: the pane's size decides instead.
		let width = Math.Max(Viewport.X, MinWidth);
		let height = Math.Max(Viewport.Y, MinHeight);
		let unbounded = BoxConstraints.Expand().MaxHeight;
		Toolbar.Measure(.(width, width, 0.0f, unbounded));
		Counters.Measure(.(0.0f, SideWidth(width), 0.0f, unbounded));
		let loose = BoxConstraints(0.0f, width, 0.0f, height);
		Strip.Measure(loose);
		TimelineView.Measure(loose);
		Table.Measure(loose);
		MeasuredSize = .(width, height);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let bar = Toolbar.MeasuredSize.Y;
		Toolbar.Layout(0, 0, width, bar);
		Strip.Layout(0, bar, width, FrameTimeGraph.GraphHeight);
		let y = bar + FrameTimeGraph.GraphHeight + Gap;
		let rest = Math.Max(height - y, 0.0f);
		let side = SideWidth(width);
		TimelineView.Layout(0, y, width - side - Gap, rest);
		let countersHeight = Counters.MeasuredSize.Y;
		let tableHeight = Math.Max(rest - countersHeight - Gap, 0.0f);
		Table.Layout(width - side, y, side, tableHeight);
		Counters.Layout(width - side, y + tableHeight + Gap, side, countersHeight);
	}
}

/// The editor's Profiler tab, docked with the Console. It records the editor process, every
/// page, viewport preview and Play-in-editor run in one frame, and says so: a game's own
/// numbers come from its player (the overlay, or a capture from it opened here). Record starts
/// copying the store's frames into the panel's own recording and Stop ends it, so stopping,
/// the selection and a longer history than the store keeps never touch the store another
/// viewer reads (a PIE game's overlay). The frame strip shows every recorded frame (a click
/// selects one, a drag a range; while recording it follows the newest until you choose), the
/// timeline and the scope table show the selection, the counters their means over it. Save
/// writes the recording as a capture (.aeprofile and its Chrome trace JSON) to
/// <user-data>/profiles; Open shows a capture from there, a player's from a Deck or a phone
/// copied in, and Live goes back to the editor's own.
class ProfilerPanel : ViewGroup
{
	private ProfilerPanelSeams mSeams ~ delete _;
	private LiveProfileSource mLive ~ delete _;
	private ProfileRecording mRecording = new .() ~ delete _;
	/// Shown instead of the recording, when open.
	private ProfileCapture mCapture ~ delete _;
	private String mCapturePath = new .() ~ delete _;
	private IProfileSource mSource;
	private bool mRecordingNow;
	/// While recording, the newest frame shows until the user selects.
	private bool mFollow = true;

	// BORROWED: the tree holds them.
	private ScrollView mScroll;
	private ProfilerPanelBody mBody;
	private Toolbar mToolbar;
	private ToolbarToggle mRecord;
	private ToolbarButton mSave;
	private ToolbarButton mLiveButton;
	private Label mStatus;
	private String mStatusText = new .() ~ delete _;
	private FrameTimeGraph mStrip;
	private Sedulous.Profiler.UI.Timeline mTimeline;
	private ScopeTable mTable;
	private CounterStrip mCounters;

	/// TAKES OWNERSHIP of the seams.
	public this(ProfilerPanelSeams seams)
	{
		mSeams = seams;
		mLive = new .(seams.Store);

		mToolbar = new Toolbar();
		mRecord = mToolbar.AddToggle("Record");
		mRecord.TooltipText.Set("Record the editor process (every page, preview and Play-in-editor run)");
		mRecord.OnCheckedChanged.Add(new [=this](toggle, on) => { if (on) Start(); else Stop(); });
		let clear = mToolbar.AddButton("Clear");
		clear.TooltipText.Set("Drop the recorded frames");
		clear.OnClick.Add(new [=this](button) => Clear());
		mToolbar.AddSeparator();
		let open = mToolbar.AddButton("Open...");
		open.TooltipText.Set("Show a capture from <user-data>/profiles (a player's F9 or --profile-capture)");
		open.OnClick.Add(new [=this](button) => PickCapture());
		mSave = mToolbar.AddButton("Save");
		mSave.TooltipText.Set("Write the recording to <user-data>/profiles (.aeprofile, and .json for Perfetto)");
		mSave.OnClick.Add(new [=this](button) => { SaveRecording(.. scope .()); });
		mLiveButton = mToolbar.AddButton("Live");
		mLiveButton.TooltipText.Set("Back to the editor's own recording");
		mLiveButton.OnClick.Add(new [=this](button) => ShowLive());
		mToolbar.AddSeparator();
		mStatus = mToolbar.AddLabel("");
		mStatus.TooltipText.Set("The editor process: every page, viewport preview and Play-in-editor run in one frame. A game's own numbers come from its player: the overlay (F3), or a capture (F9, --profile-capture) opened here.");
		mBody = new ProfilerPanelBody();
		mBody.AddView(mToolbar);

		mStrip = new FrameTimeGraph();
		mStrip.FitToSource = true;
		mStrip.Interactive = true;
		mStrip.OnSelectionChanged.Add(new [=this](range) =>
			{
				mFollow = false; // the user chose: stop following the newest
				ShowFrames(range);
			});
		mBody.AddView(mStrip);

		mTimeline = new Sedulous.Profiler.UI.Timeline();
		mTable = new ScopeTable();
		mTable.OnSelect.Add(new [=this](row) =>
			{
				if (row != null)
					mTimeline.SetHighlight(row.Name, row.Gpu);
				else
					mTimeline.ClearHighlight();
			});
		mCounters = new CounterStrip();
		mBody.AddView(mTimeline);
		mBody.AddView(mTable);
		mBody.AddView(mCounters);
		mBody.Toolbar = mToolbar;
		mBody.Strip = mStrip;
		mBody.TimelineView = mTimeline;
		mBody.Table = mTable;
		mBody.Counters = mCounters;
		// A pane smaller than the body's minimum scrolls it; the user resizes the split for more.
		mScroll = new ScrollView();
		mScroll.VScrollBarPolicy.Value = .Auto;
		mScroll.HScrollBarPolicy.Value = .Auto;
		mScroll.AddView(mBody);
		AddView(mScroll);
		ShowLive();
	}

	public ~this()
	{
		if (mRecordingNow)
			mSeams.Store.Disarm();
	}

	/// Starts recording the editor process afresh (arming the store, counted).
	public void Start()
	{
		if (mRecordingNow)
			return;
		ShowLive();
		mRecording.Begin(mLive);
		mSeams.Store.Arm();
		mRecordingNow = true;
		mFollow = true;
		SyncRecordToggle();
		RefreshViews();
	}

	/// Stops: the frames recorded stay to read and save; the store is let go.
	public void Stop()
	{
		if (!mRecordingNow)
			return;
		mRecording.Pull(mLive, 0); // the rest, as they are
		mSeams.Store.Disarm();
		mRecordingNow = false;
		SyncRecordToggle();
		RefreshViews();
	}

	public bool IsRecording => mRecordingNow;

	/// Drops the recorded frames (recording carries on from now if it is on).
	public void Clear()
	{
		mRecording.Begin(mLive);
		mFollow = true;
		ShowFrames(.());
		RefreshViews();
	}

	/// Each frame: takes the store's newly settled frames while recording, and redraws.
	public void Update()
	{
		if (!mRecordingNow)
			return;
		let before = mRecording.FrameCount;
		let newest = mRecording.NewestFrame;
		mRecording.Pull(mLive);
		if ((mRecording.FrameCount != before) || (mRecording.NewestFrame != newest))
			RefreshViews();
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

	/// Shows the capture file at `path` (recording stops). False when it cannot be read.
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
		delete mCapture;
		mCapture = capture;
		mCapturePath.Set(path);
		SetSource(mCapture);
		mFollow = false;
		// The newest frame selected, as a recording shows it.
		var newest = FrameRange();
		if (mCapture.HasFrames)
		{
			newest.First = mCapture.NewestFrame;
			newest.Last = newest.First;
			newest.Empty = false;
		}
		ShowFrames(newest);
		return true;
	}

	/// Back to the editor's own recording.
	public void ShowLive()
	{
		DeleteAndNullify!(mCapture);
		mCapturePath.Clear();
		SetSource(mRecording);
	}

	public bool ViewingCapture => mCapture != null;
	public IProfileSource Source => mSource;
	public ProfileRecording Recording => mRecording;
	public FrameRange Selection => mStrip.Selection;

	/// Selects frames as a click or drag on the strip does.
	public void Select(FrameRange range)
	{
		mFollow = false;
		ShowFrames(range);
	}

	public FrameTimeGraph Strip => mStrip;
	public Sedulous.Profiler.UI.Timeline TimelineView => mTimeline;
	public ScopeTable Table => mTable;
	public CounterStrip Counters => mCounters;
	public StringView StatusText => mStatusText;
	public ProfilerPanelBody Body => mBody;
	public ScrollView Scroller => mScroll;

	protected override void OnMeasure(BoxConstraints constraints)
	{
		mBody.Viewport = .(constraints.MaxWidth, constraints.MaxHeight);
		mScroll.Measure(constraints);
		MeasuredSize = .(constraints.MaxWidth, constraints.MaxHeight);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		mScroll.Layout(0, 0, width, height);
	}

	private void SetSource(IProfileSource source)
	{
		mSource = source;
		mStrip.Source = source;
		mTimeline.Source = source;
		mTable.Source = source;
		mCounters.Source = source;
		mLiveButton.Visibility = (mCapture != null) ? .Visible : .Gone;
		mSave.IsEnabled = mCapture == null;
		ShowFrames(.());
		UpdateStatus();
	}

	/// The selection, to every view that shows it.
	private void ShowFrames(FrameRange range)
	{
		mStrip.Selection = range;
		mTimeline.Frames = range;
		mTable.Frames = range;
		mCounters.SetRange(range);
	}

	/// New frames: the strip grows, and while following, the newest is shown.
	private void RefreshViews()
	{
		mStrip.Refresh();
		if (mFollow && mRecording.HasFrames)
		{
			var newest = FrameRange();
			newest.First = mRecording.NewestFrame;
			newest.Last = newest.First;
			newest.Empty = false;
			ShowFrames(newest);
		}
		UpdateStatus();
	}

	private void SyncRecordToggle()
	{
		if (mRecord.IsChecked != mRecordingNow)
			mRecord.IsChecked = mRecordingNow; // fires Start or Stop, which return at once
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
		{
			text.AppendF("Recording the editor process: {} frames", mRecording.FrameCount);
		}
		else if (mRecording.HasFrames)
		{
			text.AppendF("Editor process: {} frames", mRecording.FrameCount);
		}
		else
		{
			text.Append("Editor process (every page, preview and Play-in-editor run): Record to start");
		}
		SetStatus(text);
	}

	private void SetStatus(StringView text)
	{
		mStatusText.Set(text);
		mStatus.SetText(mStatusText);
	}

	private void PickCapture()
	{
		if (Context == null)
			return;
		CreateDirectory(mSeams.Folder);
		let dialog = new PathPickerDialog("Open a capture", mSeams.Folder, scope StringView[](".aeprofile"));
		dialog.OnPicked = new [=this](picked) => { OpenCapture(PathJoin(mSeams.Folder, picked, .. scope .())); };
		dialog.Show(Context);
	}
}
