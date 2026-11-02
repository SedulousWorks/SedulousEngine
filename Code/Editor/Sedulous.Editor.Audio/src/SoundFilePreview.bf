using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

// The import window's preview of a sound file (Raptor's import-window spec, W3): its waveform, with
// Play and Stop over it and a playhead while it plays, and the facts the decoder gives: its length,
// its channels and rate, and its peak. The file is read, probed and reduced to its peaks on the
// ImportPreviewReader's worker; it plays through the runtime context's audio, as the clip page
// auditions (nothing plays without an engine, as in a test). The audio domain registers it for
// audio clips.

class SoundFilePreview : IImportPreview
{
	/// The waveform's buckets: the pane is a few hundred pixels wide.
	private const uint32 cPreviewPeakBuckets = 400;

	/// What the worker reads, for the main thread to show: nothing else touches it until it is back.
	private class Decoded : RefCounted
	{
		public List<uint8> Bytes = new .() ~ delete _;
		public AudioClipMetadata Metadata = .();
		public List<float> Peaks = new .() ~ delete _;
		public bool Ok = false;
	}

	/// One reference each, this one's.
	private Node mRoot ~ _.ReleaseRef();
	private WaveformView mWaveform ~ _.ReleaseRef();
	// The tree's.
	private Sedulous.GUI.Label mState = null;
	private Sedulous.GUI.Label mMessage = null;
	private List<String> mFacts = new .() ~ DeleteContainerAndItems!(_);
	/// The sound, once read: what Play plays (the voice borrows it).
	private AudioClip mClip = null ~ delete _;
	private AuditionVoice mVoice ~ delete _;
	/// Following the voice on the GUI's clock while it plays: a reference of ours.
	private TickAction mFollow = null;
	/// The read it started, cancelled as it goes: a reference of ours.
	private ImportPreviewRead mRead = null;
	private delegate void() mOnChanged ~ delete _;

	/// Shows that it is reading `path` and starts the read on `reader` (borrowed: it outlives this);
	/// `audio` is what Play plays through (null: nothing plays).
	public this(StringView path, ImportPreviewReader reader, AudioSubsystem audio)
	{
		mVoice = new AuditionVoice(audio);
		let root = new Sedulous.GUI.Panel();
		root.AddClass("import-sound");
		let bar = new Sedulous.GUI.Panel();
		bar.AddClasses("panel-toolbar audio-bar");
		let play = Tool("Editor/Icons/play.svg", "Play it from the start");
		play.SetOnClick(new [=this] () => { Play(); });
		let stop = Tool("Editor/Icons/stop.svg", "Stop");
		stop.SetOnClick(new [=this] () => { Stop(); });
		let state = new Sedulous.GUI.Label();
		state.AddClass("transport-state");
		mState = state;
		Add(bar, play);
		Add(bar, stop);
		Add(bar, state);
		let stage = new Sedulous.GUI.Panel();
		stage.AddClass("audio-stage");
		mWaveform = new WaveformView();
		stage.AddChild(mWaveform);
		let message = new Sedulous.GUI.Label();
		message.AddClasses("state-text import-sound-message");
		mMessage = message;
		Add(root, bar);
		Add(root, stage);
		Add(root, message);
		mRoot = root;
		Audition.ShowTransportState(mState, "stopped", "Stopped");
		mMessage.Text = scope $"Reading {PathFilename(path, .. scope .())}...";

		let decoded = new Decoded(); // the done's reference
		decoded.AddRef(); // the read's
		let file = new String(path);
		mRead = reader.Read(
			// On the worker: only the file and `decoded`.
			new [=file, =decoded] () => { Decode(file, decoded); } ~ { delete file; decoded.ReleaseRef(); },
			// On the main thread, and only while this preview lives (it cancels the read as it goes).
			new [=this, =decoded] () => { Show(decoded); } ~ { decoded.ReleaseRef(); });
	}

	public ~this()
	{
		if (mRead != null)
		{
			mRead.Cancel();
			mRead.ReleaseRef();
		}
		StopFollowing();
		mVoice.Stop(); // before the clip it plays goes
	}

	public Node View => mRoot;
	public Span<String> Facts => mFacts;

	public void SetOnChanged(delegate void() onChanged)
	{
		delete mOnChanged;
		mOnChanged = onChanged;
	}

	/// Plays the sound from its start, the playhead following it; false when nothing plays.
	public bool Play()
	{
		Stop();
		if (mClip == null)
			return false;
		if (!mVoice.Start(mClip, AudioPlayParams()))
		{
			Audition.ShowTransportState(mState, "faulted", mVoice.HasEngine ? "No voice: the audio engine did not start one" : "No audio engine");
			return false;
		}
		Audition.ShowTransportState(mState, "playing", "Playing");
		mFollow = new TickAction(new [=this] (elapsed) => Follow());
		mRoot.RunAction(mFollow);
		return true;
	}

	public void Stop()
	{
		StopFollowing();
		mVoice.Stop();
		mWaveform.SetPlayhead(-1.0f);
		Audition.ShowTransportState(mState, "stopped", "Stopped");
	}

	// For tests.
	public WaveformView Waveform => mWaveform;
	public bool HasSound => mClip != null;
	public StringView State => (mState != null) ? mState.Text : default;

	/// A sound's peak (0 to 1) as the facts say it, appended: "Peak -3.1 dB"; "Silent" for none.
	public static void PeakText(float peak, String outText)
	{
		if (peak <= 0.0f)
		{
			outText.Append("Silent");
			return;
		}
		outText.AppendF("Peak {:F1} dB", 20.0f * Math.Log10(peak));
	}

	/// "Mono, 44100 Hz", appended.
	private static void ChannelsText(AudioClipMetadata metadata, String outText)
	{
		if (metadata.Channels == 1)
			outText.Append("Mono");
		else if (metadata.Channels == 2)
			outText.Append("Stereo");
		else
			outText.AppendF("{} channels", metadata.Channels);
		outText.AppendF(", {} Hz", metadata.SampleRate);
	}

	/// On the worker: the file at `file` read, probed and reduced to its peaks, into `decoded`.
	private static void Decode(StringView file, Decoded decoded)
	{
		if (!(ReadFile(file, decoded.Bytes) case .Ok))
			return;
		if (!AudioCodec.Probe(decoded.Bytes, out decoded.Metadata))
			return;
		AudioCodec.BuildWaveformPeaks(decoded.Bytes, cPreviewPeakBuckets, decoded.Peaks);
		decoded.Ok = true;
	}

	/// On the main thread: the read's result shown, or why there is none; the window told.
	private void Show(Decoded decoded)
	{
		if (!decoded.Ok)
			mMessage.Text = "This file did not decode as a sound.";
		else
		{
			let metadata = decoded.Metadata;
			var peak = 0.0f;
			for (let bucket in decoded.Peaks)
				peak = Math.Max(peak, bucket);
			mFacts.Add(new String()..AppendF("{:F2} s", metadata.DurationSeconds));
			mFacts.Add(ChannelsText(metadata, .. new .()));
			if (!decoded.Peaks.IsEmpty)
				mFacts.Add(PeakText(peak, .. new .()));
			mWaveform.SetPeaks(decoded.Peaks);
			mClip = new AudioClip();
			mClip.Channels = metadata.Channels;
			mClip.SampleRate = metadata.SampleRate;
			mClip.FrameCount = metadata.FrameCount;
			mClip.DurationSeconds = metadata.DurationSeconds;
			mClip.EncodedData.AddRange(decoded.Bytes);
			mMessage.Text = "";
			mMessage.Displayed = false;
		}
		if (mOnChanged != null)
			mOnChanged();
	}

	/// On the GUI's clock while it plays: the playhead and the state follow the voice; false once it
	/// ends, which ends the following.
	private bool Follow()
	{
		if (!mVoice.Poll(let cursor) || (mClip == null) || (mClip.DurationSeconds <= 0.0f))
		{
			mWaveform.SetPlayhead(-1.0f);
			Audition.ShowTransportState(mState, "stopped", "Stopped");
			return false;
		}
		mWaveform.SetPlayhead(Math.Min(cursor / mClip.DurationSeconds, 1.0f));
		Audition.ShowTransportState(mState, "playing", scope String()..AppendF("Playing {:F1} s", cursor));
		return true;
	}

	private void StopFollowing()
	{
		if (mFollow == null)
			return;
		mFollow.Stop();
		mFollow.ReleaseRef();
		mFollow = null;
	}

	/// A tool button of `icon`, said by `tooltip`: a node with one reference, the caller's.
	private static ToolButton Tool(StringView icon, StringView tooltip)
	{
		let button = new ToolButton();
		button.Icon = icon;
		button.Tooltip = tooltip;
		return button;
	}

	/// `child` into `into`, whose reference keeps it: the caller's one goes.
	private static void Add(Node into, Node child)
	{
		into.AddChild(child);
		child.ReleaseRef();
	}
}

/// Previews the sound files an importer lists by one asset type; it plays through the audio of the
/// host its page services name when it makes a preview.
class SoundFilePreviewFactory : IImportPreviewFactory
{
	private Type mType;
	/// Borrowed: the editor's (or a test's), which outlives it; null: nothing plays.
	private AssetPageServicesSource mServices;

	public this(Type type, AssetPageServicesSource services)
	{
		mType = type;
		mServices = services;
	}

	public Type AssetType => mType;

	public IImportPreview Create(StringView path, ImportPreviewReader reader)
	{
		AudioSubsystem audio = null;
		if (mServices != null)
		{
			let services = mServices.Make();
			defer delete services;
			if (services.Host != null)
				audio = services.Host.Subsystems.GetSubsystem<AudioSubsystem>();
		}
		return new SoundFilePreview(path, reader, audio);
	}
}
