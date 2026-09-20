using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Engine.Audio;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// The audio clip page: the waveform with a playhead, play, pause and stop on the runtime
/// audio engine, and an audition volume. Audition only; the import options edit through
/// the inspector, so there is nothing to save.
class AudioClipEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	/// The runtime context's subsystem; null in a headless host.
	private AudioSubsystem mAudio = null;
	private String mTitle = new .() ~ delete _;
	private bool mLoop = false;
	private bool mPaused = false;
	private float mAuditionVolume = 1.0f;
	/// Owned; the engine decodes it on play.
	private AudioClip mClip = null ~ delete _;
	private VoiceHandle mVoice = .();

	/// Borrowed: the content owns them.
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private Label mInfo = null;
	private Label mStatus = null;
	private Button mPlayButton = null;
	private Button mPauseButton = null;
	private Button mStopButton = null;
	private Slider mVolumeSlider = null;
	private WaveformView mWaveform = null;

	public this(EditorContext context, IApplicationHost host, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		mAudio = (host != null) ? host.Context.GetSubsystem<AudioSubsystem>() : null;
		LoadClip(instance);

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 8.0f;
		mInfo = new Label("");
		mInfo.FontSize.Value = 13.0f;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mInfo, match);
		mWaveform = new WaveformView();
		var strip = LayoutStyle();
		strip.Width = SizeSpec.Match();
		strip.Height = SizeSpec.Fixed(Unit.Dp(160));
		column.AddView(mWaveform, strip);

		let controls = new FlexLayout();
		controls.Direction = .Horizontal;
		controls.Spacing = 8.0f;
		mPlayButton = new Button("Play");
		mPlayButton.OnClick.Add(new [=this](btn) => { Audition(); });
		controls.AddView(mPlayButton);
		mPauseButton = new Button("Pause");
		mPauseButton.OnClick.Add(new [=this](btn) => { TogglePause(); });
		controls.AddView(mPauseButton);
		mStopButton = new Button("Stop");
		mStopButton.OnClick.Add(new [=this](btn) => { StopAudition(); });
		controls.AddView(mStopButton);
		let volLabel = new Label("Vol");
		volLabel.FontSize.Value = 12.0f;
		controls.AddView(volLabel);
		mVolumeSlider = new Slider(0.0f, 1.0f, 1.0f);
		mVolumeSlider.Step.Value = 0.05f;
		mVolumeSlider.OnValueChanged.Add(new [=this](slider, v) => { SetAuditionVolume(v); });
		var sliderStyle = LayoutStyle();
		sliderStyle.Width = SizeSpec.Fixed(Unit.Dp(90));
		sliderStyle.AlignSelf = .Center;
		controls.AddView(mVolumeSlider, sliderStyle);
		mStatus = new Label("");
		mStatus.FontSize.Value = 12.0f;
		controls.AddView(mStatus);
		column.AddView(controls, match);
		column.AddRef();
		mContent = column;
		RefreshInfo();
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public bool HasClip => mClip != null;
	/// Audition only: the options edit through the inspector.
	public override Result<void, ErrorCode> Save() => .Ok;
	public override void OnClose() => StopAudition();

	private AudioEngine Engine => (mAudio != null) ? mAudio.Engine : null;

	/// Tracks the voice: the playhead follows, and a finished voice stops the transport.
	public override void OnUpdate(IApplicationHost host, float dt)
	{
		let engine = Engine;
		if (!mVoice.IsValid || (engine == null))
			return;
		if (!engine.IsPlaying(mVoice))
		{
			StopAudition();
			return;
		}
		VoiceStatus status = ?;
		if (!engine.GetVoiceStatus(mVoice, out status))
			return;
		let duration = (mClip != null) ? mClip.DurationSeconds : 0.0f;
		if (duration <= 0.0f)
			return;
		var fraction = status.CursorSeconds / duration;
		if (mLoop)
			fraction = fraction - (float)(int64)fraction;
		mWaveform.SetPlayheadFraction(Math.Min(fraction, 1.0f));
		mStatus.SetText(scope $"Playing...  {status.CursorSeconds:F1} s");
	}

	private void LoadClip(Instance instance)
	{
		let object = instance.ReadObject();
		defer delete object;
		let asset = object as AudioClipAsset;
		if (asset == null)
			return;
		mLoop = asset.Loop;
		mClip = AudioClipLoader.Load(mContext, asset);
	}

	private void RefreshInfo()
	{
		if (mClip == null)
		{
			mInfo.SetText("Source file missing or undecodable.");
			mPlayButton.IsEnabled = false;
			mStopButton.IsEnabled = false;
			return;
		}
		mInfo.SetText(scope $"{mClip.Channels} ch  |  {mClip.SampleRate} Hz  |  {mClip.DurationSeconds:F2} s{mLoop ? "  |  loops" : ""}");
		let peaks = scope List<float>();
		if (AudioCodec.BuildWaveformPeaks(mClip.EncodedData, 256, peaks))
			mWaveform.SetPeaks(peaks);
	}

	private void Audition()
	{
		let engine = Engine;
		if ((mClip == null) || (engine == null))
			return;
		StopAudition();
		var parameters = AudioPlayParams();
		parameters.Loop = mLoop;
		parameters.AllowDedupe = false; // a rapid re-audition restarts, never merges
		mVoice = engine.Play(mClip, parameters);
		if (mVoice.IsValid)
			engine.SetVoiceVolume(mVoice, mAuditionVolume); // the audition slider applies
		mPaused = false;
		mPauseButton.SetText("Pause");
		mStatus.SetText(mVoice.IsValid ? "Playing..." : "No voice (engine headless?)");
	}

	private void TogglePause()
	{
		let engine = Engine;
		if ((engine == null) || !mVoice.IsValid)
			return;
		mPaused = !mPaused;
		engine.SetPaused(mVoice, mPaused);
		mPauseButton.SetText(mPaused ? "Resume" : "Pause");
		mStatus.SetText(mPaused ? "Paused" : "Playing...");
	}

	private void SetAuditionVolume(float volume)
	{
		mAuditionVolume = Math.Max(volume, 0.0f);
		let engine = Engine;
		if ((engine != null) && mVoice.IsValid)
			engine.SetVoiceVolume(mVoice, mAuditionVolume); // live while auditioning
	}

	private void StopAudition()
	{
		let engine = Engine;
		if ((engine != null) && mVoice.IsValid)
			engine.Stop(mVoice);
		mVoice = .();
		mPaused = false;
		mPauseButton.SetText("Pause");
		mWaveform.SetPlayheadFraction(-1.0f);
		mStatus.SetText("");
	}
}
