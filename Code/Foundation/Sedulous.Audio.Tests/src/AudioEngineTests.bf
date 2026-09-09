using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio;
using static Sedulous.Audio.Tests.AudioEngineFixture;

namespace Sedulous.Audio.Tests;

/// The engine's core state machine, pumped headlessly: handles across slot generations,
/// fade then reap, pause and resume, the voice setters, the buses, and the cursor.
class AudioEngineTests
{
	/// A fresh engine has no voices, and every degenerate play is refused rather than
	/// faulting: a null clip, an empty one, and one whose bytes decode to nothing.
	///
	/// Every call on a bogus handle is a no-op too, since a handle outliving its voice is
	/// the NORMAL case rather than a caller's mistake.
	[Test]
	public static void AnEmptyOrInvalidPlayIsRefusedSafely()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		Test.Assert(engine.IsHeadless);
		Test.Assert(engine.ActiveVoiceCount == 0);

		Test.Assert(!engine.Play(null).IsValid);

		let empty = scope AudioClip();
		Test.Assert(!engine.Play(empty).IsValid);

		let garbage = scope AudioClip();
		for (int i < 64)
			garbage.EncodedData.Add((uint8)i);
		Test.Assert(!engine.Play(garbage).IsValid);

		let bogus = VoiceHandle(3, 7);
		Test.Assert(!engine.IsValidHandle(bogus));
		Test.Assert(!engine.IsPlaying(bogus));
		engine.Stop(bogus);
		engine.SetPaused(bogus, true);
		engine.SetVoiceVolume(bogus, 0.5f);
		engine.SetVoicePosition(bogus, .(1, 2, 3), .(0, 0, 0));
		engine.Update(0.1f);
	}

	/// A one shot runs out and reaps, and the NEXT play lands in the same slot with a new
	/// generation: the old handle stays dead, which is the whole point of the generation.
	[Test]
	public static void AOneShotReapsAndItsHandleNeverComesBack()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(0.1f);
		defer delete clip;

		let first = engine.Play(clip);
		Test.Assert(first.IsValid);
		Test.Assert(engine.IsPlaying(first));
		Test.Assert(engine.ActiveVoiceCount == 1);

		for (int i = 0; (i < 6) && engine.IsValidHandle(first); i++)
			engine.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(first));
		Test.Assert(engine.ActiveVoiceCount == 0);

		let second = engine.Play(clip);
		Test.Assert(second.IsValid);
		Test.Assert(second.Slot == first.Slot);
		Test.Assert(second.Generation != first.Generation);
		Test.Assert(!engine.IsValidHandle(first));
		Test.Assert(engine.IsPlaying(second));
	}

	/// Stopping ALWAYS fades, and the voice stays addressable while it does: an instant cut
	/// is a click, and a click is the most audible thing an engine can do.
	[Test]
	public static void StopFadesFirstAndReapsAfterwards()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(0.5f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);
		engine.Update(0.05f);
		Test.Assert(engine.IsPlaying(voice));

		engine.Stop(voice);
		Test.Assert(engine.GetVoiceStatus(voice, let status));
		Test.Assert(status.Stopping);
		Test.Assert(!engine.IsPlaying(voice));
		// Still addressable: the fade is in flight, not finished.
		Test.Assert(engine.IsValidHandle(voice));

		// A hundred milliseconds is far past the ten the fade takes.
		engine.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(voice));
		Test.Assert(engine.ActiveVoiceCount == 0);
	}

	/// Pausing fades out but KEEPS the voice and its cursor; resuming fades back in.
	[Test]
	public static void PauseKeepsTheVoiceAndResumeFadesItBack()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(0.3f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);

		engine.SetPaused(voice, true);
		Test.Assert(!engine.IsPlaying(voice));
		Test.Assert(engine.IsValidHandle(voice));

		// A paused voice is never reaped by the passage of time, however long it is left.
		for (int i < 10)
			engine.Update(0.1f);
		Test.Assert(engine.GetVoiceStatus(voice, let status));
		Test.Assert(status.Paused);

		engine.SetPaused(voice, false);
		Test.Assert(engine.IsPlaying(voice));
	}

	/// The setters land on the slot AND on the backend, and un-looping a voice lets it run
	/// out: a live change has to reach the mixer, not just the bookkeeping.
	[Test]
	public static void TheVoiceSettersLand()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(0.5f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Spatial = true;
		parameters.Loop = true;
		parameters.Pitch = 1.5f;
		parameters.Volume = 0.75f;

		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);
		Test.Assert(engine.GetVoiceStatus(voice, var status));
		Test.Assert(Near(status.Pitch, 1.5f));
		Test.Assert(Near(status.Volume, 0.75f));
		Test.Assert(status.Spatial);

		engine.SetVoicePitch(voice, 0.5f);
		engine.SetVoiceVolume(voice, 0.25f);
		engine.SetVoicePan(voice, -0.5f);
		engine.SetVoicePosition(voice, .(3, 4, 5), .(1, 0, 0));
		Test.Assert(engine.GetVoiceStatus(voice, out status));
		Test.Assert(Near(status.Pitch, 0.5f));
		Test.Assert(Near(status.Volume, 0.25f));
		Test.Assert(Near(status.Position.X, 3.0f));
		Test.Assert(Near(status.Position.Z, 5.0f));

		engine.SetVoiceLooping(voice, false);
		for (int i = 0; (i < 20) && engine.IsValidHandle(voice); i++)
			engine.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(voice));
	}

	/// A spatial play of a stereo clip is downmixed and still plays: the mono guard warns
	/// once and fixes the imaging rather than refusing the play.
	[Test]
	public static void ASpatialStereoClipIsDownmixedAndStillPlays()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let stereo = MakeToneClip(0.2f, 8000, 2);
		defer delete stereo;

		var parameters = AudioPlayParams();
		parameters.Spatial = true;
		let voice = engine.Play(stereo, parameters);
		Test.Assert(voice.IsValid);
		Test.Assert(engine.IsPlaying(voice));

		engine.Update(0.05f);
		engine.Stop(voice);
		engine.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(voice));
	}

	[Test]
	public static void StopAllFadesEveryVoiceOut()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clipA = MakeToneClip(1.0f);
		let clipB = MakeToneClip(1.0f, 4000, 1);
		defer { delete clipA; delete clipB; }

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		let voiceA = engine.Play(clipA, parameters);
		let voiceB = engine.Play(clipB, parameters);
		Test.Assert(voiceA.IsValid);
		Test.Assert(voiceB.IsValid);

		engine.StopAll();
		engine.Update(0.2f);
		Test.Assert(engine.ActiveVoiceCount == 0);
		Test.Assert(!engine.IsValidHandle(voiceA));
		Test.Assert(!engine.IsValidHandle(voiceB));
	}

	/// The bus knobs are independent, and a mute REMEMBERS the level it will come back to
	/// rather than overwriting it with silence.
	[Test]
	public static void TheBusVolumesAndMutesAreIndependent()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		Test.Assert(Near(engine.BusVolume(.Master), 1.0f));

		engine.SetBusVolume(.Music, 0.3f);
		Test.Assert(Near(engine.BusVolume(.Music), 0.3f));
		Test.Assert(Near(engine.BusVolume(.Effects), 1.0f));

		engine.SetBusMuted(.Music, true);
		Test.Assert(engine.BusMuted(.Music));
		Test.Assert(Near(engine.BusVolume(.Music), 0.3f));

		engine.SetBusMuted(.Music, false);
		Test.Assert(!engine.BusMuted(.Music));
		Test.Assert(Near(engine.BusVolume(.Music), 0.3f));
	}

	/// The master gain clamps at silence but is NOT clamped above one: a boost is a
	/// legitimate ask, whereas a negative gain would invert the phase.
	[Test]
	public static void TheMasterVolumeClampsAtSilenceAndAllowsABoost()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		Test.Assert(Near(engine.MasterVolume, 1.0f));

		engine.SetMasterVolume(0.25f);
		Test.Assert(Near(engine.MasterVolume, 0.25f));

		engine.SetMasterVolume(-3.0f);
		Test.Assert(Near(engine.MasterVolume, 0.0f));

		engine.SetMasterVolume(2.0f);
		Test.Assert(Near(engine.MasterVolume, 2.0f));
	}

	/// The reported cursor is the voice's TRUE one: it advances with the data the mixer
	/// consumed rather than with wall time, holds still while paused, and wraps on a loop.
	[Test]
	public static void TheCursorFollowsTheMixerAndWrapsOnALoop()
	{
		let engine = scope AudioEngine(HeadlessSettings!());
		let clip = MakeToneClip(1.0f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.AllowDedupe = false;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);

		Test.Assert(engine.GetVoiceStatus(voice, var status));
		let start = status.CursorSeconds;
		Test.Assert(start >= 0.0f);
		Test.Assert(start < 0.05f);

		// About three hundred milliseconds of mixing.
		for (int i < 18)
			engine.Update(1.0f / 60.0f);
		Test.Assert(engine.GetVoiceStatus(voice, out status));
		Test.Assert(status.CursorSeconds > (start + 0.2f));
		Test.Assert(status.CursorSeconds < 0.6f);
		let mid = status.CursorSeconds;

		engine.SetPaused(voice, true);
		for (int i < 12)
			engine.Update(1.0f / 60.0f);
		Test.Assert(engine.GetVoiceStatus(voice, out status));
		Test.Assert(Near(status.CursorSeconds, mid, 0.02f));
		engine.SetPaused(voice, false);

		// A quarter second loop pumped for six tenths reads back INSIDE the clip.
		let shortClip = MakeToneClip(0.25f, 8000, 1);
		defer delete shortClip;

		var loopParams = AudioPlayParams();
		loopParams.Loop = true;
		loopParams.AllowDedupe = false;
		let looping = engine.Play(shortClip, loopParams);
		Test.Assert(looping.IsValid);
		for (int i < 36)
			engine.Update(1.0f / 60.0f);
		Test.Assert(engine.GetVoiceStatus(looping, out status));
		Test.Assert(engine.IsPlaying(looping));
		Test.Assert(status.CursorSeconds >= 0.0f);
		Test.Assert(status.CursorSeconds < 0.26f);
	}
}
