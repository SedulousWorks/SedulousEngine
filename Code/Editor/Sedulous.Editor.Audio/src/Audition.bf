using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Audio;
using Sedulous.Audio.Pipeline;
using Sedulous.Engine.Audio;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Audio;

// What the audio pages audition with: a clip read from its
// asset's source file, as the cook reads it, and one voice played through the RUNTIME context's
// AudioSubsystem (the game's engine, buses and voice pool, so what is heard is what the game plays).
// A clip page plays its clip; a cue page plays the variant the runtime's resolver picks. Either way
// one voice at a time: playing again stops the last.

static class Audition
{
	/// The clip `asset` names, read from its source file under `project` (its options applied:
	/// gain, loop); null when the file is missing or does not decode. `outMetadata` gets what the
	/// probe read. The caller owns the clip.
	public static AudioClip ReadClip(EditorProject project, AudioClipAsset asset, out AudioClipMetadata outMetadata)
	{
		outMetadata = default;
		if ((project == null) || (asset == null) || asset.FileName.IsEmpty)
			return null;
		let path = PathJoin(project.SourcesRoot(.. scope .()), asset.FileName.Value, .. scope .());
		let bytes = scope List<uint8>();
		if (!(ReadFile(path, bytes) case .Ok))
			return null;
		if (!AudioCodec.Probe(bytes, out outMetadata))
			return null;
		let clip = new AudioClip();
		clip.Channels = outMetadata.Channels;
		clip.SampleRate = outMetadata.SampleRate;
		clip.FrameCount = outMetadata.FrameCount;
		clip.DurationSeconds = outMetadata.DurationSeconds;
		clip.Gain = asset.Gain;
		clip.Loop = asset.Loop;
		clip.LoopStartFrame = asset.LoopStartFrame;
		clip.LoopEndFrame = asset.LoopEndFrame;
		clip.EncodedData.AddRange(bytes);
		return clip;
	}

	/// A transport's state beside it (`label`, the kit's transport-state): its class (stopped,
	/// playing, paused, faulted) the only one of them it has, and `text`.
	public static void ShowTransportState(Sedulous.GUI.Label label, StringView state, StringView text)
	{
		if (label == null)
			return;
		for (let name in StringView[?]("stopped", "playing", "paused", "faulted"))
			label.RemoveClass(name);
		label.AddClass(state);
		label.Text = text;
	}
}

/// One audition voice through the runtime's audio engine (none without an engine: a test, a
/// headless host).
class AuditionVoice
{
	/// The runtime context's; null without one.
	private AudioSubsystem mAudio = null;
	/// An engine of its own (a test's); null: the subsystem's.
	private AudioEngine mEngine = null;
	private VoiceHandle mVoice = .();
	private bool mPaused = false;
	private float mVolume = 1.0f;

	/// Through the runtime context's audio (null: none).
	public this(AudioSubsystem audio)
	{
		mAudio = audio;
	}

	/// Through `engine`, borrowed (a test's headless one).
	public this(AudioEngine engine)
	{
		mEngine = engine;
	}

	public ~this()
	{
		Stop();
	}

	/// Whether there is an engine to play through.
	public bool HasEngine => Engine != null;
	public bool IsActive => mVoice.IsValid;
	public bool IsPaused => mVoice.IsValid && mPaused;
	public bool IsPlaying => mVoice.IsValid && !mPaused;
	/// The voice's volume, 0 to 1, this voice only.
	public float Volume => mVolume;

	/// Plays `clip` (borrowed: it outlives the voice) from its start, the last voice stopped first;
	/// false when no voice started.
	public bool Start(AudioClip clip, AudioPlayParams parameters)
	{
		Stop();
		let engine = Engine;
		if ((engine == null) || (clip == null))
			return false;
		var played = parameters;
		played.AllowDedupe = false; // a quick play again starts again, never merges
		mVoice = engine.Play(clip, played);
		if (mVoice.IsValid)
			engine.SetVoiceVolume(mVoice, mVolume);
		mPaused = false;
		return mVoice.IsValid;
	}

	public void SetPaused(bool paused)
	{
		let engine = Engine;
		if (!mVoice.IsValid || (paused == mPaused) || (engine == null))
			return;
		mPaused = paused;
		engine.SetPaused(mVoice, paused);
	}

	public void Stop()
	{
		let engine = Engine;
		if (mVoice.IsValid && (engine != null))
			engine.Stop(mVoice);
		mVoice = .();
		mPaused = false;
	}

	/// The voice's volume, 0 to 1, this voice only; heard at once while it plays.
	public void SetVolume(float volume)
	{
		mVolume = Math.Clamp(volume, 0.0f, 1.0f);
		let engine = Engine;
		if (mVoice.IsValid && (engine != null))
			engine.SetVoiceVolume(mVoice, mVolume);
	}

	/// Once a frame: where the voice is in its clip (seconds, the voice's own cursor: pitch and loop
	/// wraps honoured); false when it finished or was taken (it is let go). A paused voice is still
	/// the audition: the engine keeps it, and Play resumes it (asking whether it plays instead ended
	/// an audition the frame after its pause).
	public bool Poll(out float outCursorSeconds)
	{
		outCursorSeconds = 0.0f;
		let engine = Engine;
		if (!mVoice.IsValid || (engine == null))
			return false;
		if (!engine.GetVoiceStatus(mVoice, var status) || (!status.Paused && !status.Playing))
		{
			mVoice = .();
			mPaused = false;
			return false;
		}
		outCursorSeconds = status.CursorSeconds;
		return true;
	}

	private AudioEngine Engine => (mEngine != null) ? mEngine : ((mAudio != null) ? mAudio.Engine : null);
}
