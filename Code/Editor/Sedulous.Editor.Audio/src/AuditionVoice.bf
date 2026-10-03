using System;
using Sedulous.Audio;

namespace Sedulous.Editor.Audio;

/// What an audition page's voice is this frame.
enum AuditionVoiceState
{
	/// Finished, stopping or never started: the audition is over.
	Gone,
	Playing,
	/// Still the audition: the engine keeps a paused voice, and Play resumes it.
	Paused
}

/// The per-frame check the audio pages share. Asking `IsPlaying` instead (true only while
/// playing) ended an audition the frame after it was paused: the clip page stopped the voice,
/// and the cue page forgot a voice the engine still held paused, so Play could not resume it.
static class AuditionVoice
{
	public static AuditionVoiceState Track(AudioEngine engine, VoiceHandle voice, out VoiceStatus status)
	{
		status = .();
		if ((engine == null) || !voice.IsValid || !engine.GetVoiceStatus(voice, out status))
			return .Gone;
		if (status.Paused)
			return .Paused;
		return status.Playing ? .Playing : .Gone;
	}
}
