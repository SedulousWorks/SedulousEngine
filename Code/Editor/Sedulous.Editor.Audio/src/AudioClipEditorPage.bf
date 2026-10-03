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

/// The audio clip page: the waveform with a playhead, the page toolbar's playback on the
/// runtime audio engine, and an audition volume. Audition only; the import options edit
/// through the inspector, so there is nothing to save.
class AudioClipEditorPage : UIEditorPage, IPlaybackPage
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
	private PageToolbar mToolbar = null;
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
		mToolbar = new PageToolbar(this, mContext.Actions, .None);
		mToolbar.AddPlayback();
		mToolbar.AddSeparator();
		mToolbar.AddLabel("Vol");
		mVolumeSlider = new Slider(0.0f, 1.0f, 1.0f);
		mVolumeSlider.Step.Value = 0.05f;
		mVolumeSlider.OnValueChanged.Add(new [=this](slider, v) => { SetAuditionVolume(v); });
		var sliderStyle = LayoutStyle();
		sliderStyle.Width = SizeSpec.Fixed(Unit.Dp(90));
		sliderStyle.AlignSelf = .Center;
		mToolbar.AddItem(mVolumeSlider, sliderStyle);
		mStatus = mToolbar.AddLabel("");
		var bar = LayoutStyle();
		bar.Width = SizeSpec.Match();
		column.AddView(mToolbar, bar);
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
		if (mToolbar != null)
			mToolbar.Refresh();
		let engine = Engine;
		if (!mVoice.IsValid || (engine == null))
			return;
		let state = AuditionVoice.Track(engine, mVoice, let status);
		if (state == .Gone)
		{
			StopAudition();
			return;
		}
		// Paused: the playhead and the status hold where they are.
		if (state == .Paused)
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
		mStatus.SetText(mVoice.IsValid ? "Playing..." : "No voice (engine headless?)");
	}

	private void TogglePause()
	{
		let engine = Engine;
		if ((engine == null) || !mVoice.IsValid)
			return;
		mPaused = !mPaused;
		engine.SetPaused(mVoice, mPaused);
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
		mWaveform.SetPlayheadFraction(-1.0f);
		mStatus.SetText("");
	}

	// ---- IPlaybackPage ----

	public bool CanPlay => mClip != null;
	public bool IsPlaying => mVoice.IsValid && !mPaused;

	public void Play()
	{
		if (!mVoice.IsValid)
			Audition();
		else if (mPaused)
			TogglePause();
	}

	public void Pause()
	{
		if (mVoice.IsValid && !mPaused)
			TogglePause();
	}

	public void Stop() => StopAudition();
	public void Restart() => Audition();
}
