using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Engine.Audio;
using Sedulous.Runtime.Client;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// The audition page of an AudioClipAsset, on the GUI from its markup (Data/Editor/AudioClipPage.gml;
/// Raptor's editor-gui spec, 5.4, layer 5). The clip's peak waveform (decoded from its source file,
/// the bytes the cook writes through) with the kit's transport over it: Play, Stop and Restart are
/// the playback actions over the page, auditioned through the RUNTIME context's AudioSubsystem (the
/// game's engine, buses and voices, so what is heard is what the game plays), honouring the clip's
/// loop, a playhead following the voice. Beside it the clip's options on the grid, each edit one
/// undo step, the audition following them (a loop turned on loops the next play), and its source's
/// facts read only (channels, rate, length). The old page edited nothing itself; its options were
/// the inspector's.
class AudioClipEditorPage : AssetObjectPage, IPlaybackPage
{
	public const String cMarkupPath = "Editor/AudioClipPage.gml";
	public const uint32 cPeakBuckets = 256;

	/// Through the runtime context's audio (none in a test).
	private AuditionVoice mVoice ~ delete _;
	/// Owned; the engine decodes it on play. Null: no source read.
	private AudioClip mClip = null;
	/// The source the clip was read from (a new one reads it again).
	private String mLoadedFile = new .() ~ delete _;
	/// One reference, the page's: the stage holds its own.
	private WaveformView mWaveform = null ~ _?.ReleaseRef();
	// The markup's: the tree holds them.
	private Node mStage = null;
	private Node mEmpty = null;
	private Sedulous.GUI.Label mEmptyText = null;
	private Sedulous.GUI.Label mState = null;
	private Slider mVolume = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(AudioClipAsset), cMarkupPath)
	{
		let host = Services.Host;
		mVoice = new AuditionVoice((host != null) ? host.Context.GetSubsystem<AudioSubsystem>() : null);
		mStage = Find<Node>("audio-stage");
		mEmpty = Find<Node>("audio-empty");
		mEmptyText = Find<Sedulous.GUI.Label>("audio-empty-text");
		mState = Find<Sedulous.GUI.Label>("audio-state");
		mVolume = Find<Slider>("audio-volume");
		mWaveform = new WaveformView();
		if (mStage != null)
			mStage.AddChild(mWaveform);
		// The kit's transport: the playback actions over this page, as every page's transport is.
		BindAction(Find<ButtonBase>("audio-restart"), "playback.restart");
		BindAction(Find<ButtonBase>("audio-play"), "playback.play");
		BindAction(Find<ButtonBase>("audio-stop"), "playback.stop");
		if (mVolume != null)
			mVolume.SetOnValueChanging(new [=this] (volume) => { SetAuditionVolume((float)volume); });
		LoadClip();
		ShowState("stopped", "Stopped");
	}

	public ~this()
	{
		StopAudition();
		delete mClip; // after the voice that played it has stopped
	}

	public override void OnClose() => StopAudition();

	// === IPlaybackPage ===

	public bool CanPlay => (mClip != null) && mVoice.HasEngine;
	public bool IsPlaying => mVoice.IsPlaying;

	public void Play()
	{
		if (!mVoice.IsActive)
		{
			StartAudition();
			return;
		}
		mVoice.SetPaused(false);
		ShowState("playing", "Playing");
	}

	public void Pause()
	{
		if (!mVoice.IsPlaying)
			return;
		mVoice.SetPaused(true);
		ShowState("paused", "Paused");
	}

	public void Stop() => StopAudition();
	public void Restart() => StartAudition();

	/// The audition's volume (this page's voice only, not saved), 0 to 1.
	public void SetAuditionVolume(float volume)
	{
		mVoice.SetVolume(volume); // heard as it moves
		if ((mVolume != null) && (mVolume.Value != (double)mVoice.Volume))
			mVolume.Value = mVoice.Volume;
	}

	public float AuditionVolume => mVoice.Volume;

	// === For tests ===

	public AudioClip Clip => mClip;
	public WaveformView Waveform => mWaveform;
	public StringView State => (mState != null) ? mState.Text : default;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt); // the bar, the transport with it, each frame
		if (!mVoice.IsActive)
			return;
		if (!mVoice.Poll(let cursor))
		{
			StopAudition(); // finished, or its voice taken
			return;
		}
		let duration = (mClip != null) ? mClip.DurationSeconds : 0.0f;
		if (mVoice.IsPaused || (duration <= 0.0f))
			return; // a paused audition holds its playhead
		var fraction = cursor / duration;
		if (mClip.Loop)
			fraction -= (float)(int64)fraction;
		mWaveform.SetPlayhead(Math.Min(fraction, 1.0f));
		ShowState("playing", scope String()..AppendF("Playing {:F1} s", cursor));
	}

	protected override void OnObjectChanged()
	{
		let asset = ObjectAs<AudioClipAsset>();
		if ((asset != null) && (asset.FileName.Value != mLoadedFile))
			LoadClip(); // another source: read again
		else
			ApplyOptions(); // the next play takes them
	}

	/// Reads the source file named by the asset: the clip to audition, its peaks and its facts; the
	/// waveform's place says why when there is none.
	private void LoadClip()
	{
		StopAudition();
		let asset = ObjectAs<AudioClipAsset>();
		if (asset == null)
			return;
		mLoadedFile.Set(asset.FileName.Value);
		if (asset.FileName.IsEmpty || (Context.Project == null))
		{
			ShowEmpty("This clip names no source file.");
			return;
		}
		DeleteAndNullify!(mClip);
		mClip = Audition.ReadClip(Context.Project, asset, let metadata);
		if (mClip == null)
		{
			GlobalLog(.Warning, "Editor: audio source missing or undecodable: {}", asset.FileName.Value);
			ShowEmpty(scope String()..AppendF("{} is missing or did not decode.", asset.FileName.Value));
			return;
		}
		let peaks = scope List<float>();
		if (AudioCodec.BuildWaveformPeaks(mClip.EncodedData, cPeakBuckets, peaks))
			mWaveform.SetPeaks(peaks);
		if (mStage != null)
			mStage.Displayed = true;
		if (mEmpty != null)
			mEmpty.Displayed = false;
		let channels = scope String();
		switch (metadata.Channels)
		{
		case 1: channels.Append("Mono");
		case 2: channels.Append("Stereo");
		default: channels.AppendF("{}", metadata.Channels);
		}
		SetFact("Channels", channels);
		SetFact("Sample Rate", scope String()..AppendF("{} Hz", metadata.SampleRate));
		SetFact("Length", scope String()..AppendF("{:F2} s ({} frames)", metadata.DurationSeconds, metadata.FrameCount));
	}

	/// The clip's options as the asset has them now (an edit, an undo): the next play takes them.
	private void ApplyOptions()
	{
		let asset = ObjectAs<AudioClipAsset>();
		if ((asset == null) || (mClip == null))
			return;
		mClip.Gain = asset.Gain;
		mClip.Loop = asset.Loop;
		mClip.LoopStartFrame = asset.LoopStartFrame;
		mClip.LoopEndFrame = asset.LoopEndFrame;
	}

	private void StartAudition()
	{
		StopAudition();
		if (!CanPlay)
			return;
		var parameters = AudioPlayParams();
		parameters.Loop = mClip.Loop;
		if (!mVoice.Start(mClip, parameters))
		{
			ShowState("faulted", "No voice: the audio engine did not start one");
			return;
		}
		ShowState("playing", "Playing");
	}

	private void StopAudition()
	{
		if (mVoice != null)
			mVoice.Stop();
		if (mWaveform != null)
			mWaveform.SetPlayhead(-1.0f);
		ShowState("stopped", "Stopped");
	}

	private void ShowState(StringView state, StringView text)
	{
		Audition.ShowTransportState(mState, state, text);
	}

	private void ShowEmpty(StringView why)
	{
		DeleteAndNullify!(mClip);
		if (mWaveform != null)
			mWaveform.SetPeaks(.());
		if (mStage != null)
			mStage.Displayed = false;
		if (mEmpty != null)
			mEmpty.Displayed = true;
		if (mEmptyText != null)
			mEmptyText.Text = why;
	}
}
