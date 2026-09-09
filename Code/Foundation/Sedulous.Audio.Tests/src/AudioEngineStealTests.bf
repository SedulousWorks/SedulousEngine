using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio;
using static Sedulous.Audio.Tests.AudioEngineFixture;

namespace Sedulous.Audio.Tests;

/// What a FULL pool does: who is stolen, how the victim's tail is let down, and when a
/// repeat of one clip folds into the voice already going.
class AudioEngineStealTests
{
	/// Free slot, then the lowest priority strictly below the newcomer, then the farthest of
	/// equal priority; a pool of strictly higher priorities REFUSES the play.
	///
	/// The steal is faded: the victim's handle dies at once and its slot is reused, but its
	/// sound keeps mixing on the dying list, so the two overlap briefly rather than clicking.
	[Test]
	public static void TheLowestPriorityBelowTheNewcomerIsStolen()
	{
		let engine = scope AudioEngine(HeadlessSettings!(2, 0));
		let clipA = MakeToneClip(2.0f);
		let clipB = MakeToneClip(2.0f, 8000, 1);
		let clipC = MakeToneClip(2.0f, 4000, 1);
		let clipD = MakeToneClip(2.0f, 16000, 1);
		defer { delete clipA; delete clipB; delete clipC; delete clipD; }

		var low = AudioPlayParams();
		low.Priority = 10;
		low.Loop = true;
		let voiceA = engine.Play(clipA, low);
		low.Priority = 20;
		let voiceB = engine.Play(clipB, low);
		Test.Assert(voiceA.IsValid);
		Test.Assert(voiceB.IsValid);
		Test.Assert(engine.ActiveVoiceCount == 2);

		var high = AudioPlayParams();
		high.Priority = 30;
		high.Loop = true;
		let voiceC = engine.Play(clipC, high);
		Test.Assert(voiceC.IsValid);
		Test.Assert(!engine.IsValidHandle(voiceA));
		Test.Assert(engine.IsValidHandle(voiceB));
		// Addressable voices only: A's tail is mixing but no longer reachable.
		Test.Assert(engine.ActiveVoiceCount == 2);
		Test.Assert(engine.DyingVoiceCount == 1);

		for (int i < 10)
			engine.Update(0.05f);
		Test.Assert(engine.DyingVoiceCount == 0);

		var lowest = AudioPlayParams();
		lowest.Priority = 5;
		Test.Assert(!engine.Play(clipD, lowest).IsValid);
		Test.Assert(engine.IsValidHandle(voiceB));
		Test.Assert(engine.IsValidHandle(voiceC));
	}

	/// With nothing below it to take, the newcomer takes the FARTHEST voice of its own
	/// priority: the loss of the most distant of several equally important sounds is the
	/// least audible one.
	[Test]
	public static void EqualPriorityStealsTheFarthestVoice()
	{
		let engine = scope AudioEngine(HeadlessSettings!(2, 0));
		engine.SetListenerTransform(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0), .(0, 0, 0));

		let clipNear = MakeToneClip(2.0f);
		let clipFar = MakeToneClip(2.0f, 8000, 1);
		let clipNew = MakeToneClip(2.0f, 4000, 1);
		defer { delete clipNear; delete clipFar; delete clipNew; }

		var spatial = AudioPlayParams();
		spatial.Loop = true;
		spatial.Spatial = true;
		spatial.Priority = 50;
		spatial.Position = .(1.0f, 0.0f, 0.0f);
		let nearVoice = engine.Play(clipNear, spatial);
		spatial.Position = .(60.0f, 0.0f, 0.0f);
		let farVoice = engine.Play(clipFar, spatial);
		Test.Assert(nearVoice.IsValid);
		Test.Assert(farVoice.IsValid);

		spatial.Position = .(2.0f, 0.0f, 0.0f);
		let newVoice = engine.Play(clipNew, spatial);
		Test.Assert(newVoice.IsValid);
		Test.Assert(engine.IsValidHandle(nearVoice));
		Test.Assert(!engine.IsValidHandle(farVoice));
		Test.Assert(engine.DyingVoiceCount == 1);
	}

	/// The dying list is BOUNDED: its oldest tail is hard cut on overflow, a silent victim
	/// never joins it at all, and a capacity of nothing is the plain immediate cut.
	[Test]
	public static void TheDyingListIsBoundedAndSkipsSilentVictims()
	{
		let settings = scope AudioEngineSettings();
		settings.Headless = true;
		settings.VoiceCount = 1;
		settings.StreamVoiceCount = 0;
		settings.DedupeWindowSeconds = 0.0f;
		settings.DyingVoiceCapacity = 2;
		let engine = scope AudioEngine(settings);

		let clips = scope List<AudioClip>();
		clips.Add(MakeToneClip(1.0f));
		clips.Add(MakeToneClip(1.0f, 4000, 1));
		clips.Add(MakeToneClip(1.0f, 16000, 1));
		clips.Add(MakeToneClip(1.0f, 12000, 1));
		defer { ClearAndDeleteItems!(clips); }

		// Four plays through a pool of one: each steals the incumbent, and the list holds
		// at most two tails.
		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.AllowDedupe = false;
		var last = VoiceHandle();
		for (let clip in clips)
		{
			last = engine.Play(clip, parameters);
			Test.Assert(last.IsValid);
		}
		Test.Assert(engine.ActiveVoiceCount == 1);
		Test.Assert(engine.DyingVoiceCount == 2);

		for (int i < 10)
			engine.Update(0.05f);
		Test.Assert(engine.DyingVoiceCount == 0);
		Test.Assert(engine.IsPlaying(last));

		// A paused victim is already silent, so stealing it never busies the list.
		engine.SetPaused(last, true);
		let successor = engine.Play(clips[0], parameters);
		Test.Assert(successor.IsValid);
		Test.Assert(!engine.IsValidHandle(last));
		Test.Assert(engine.DyingVoiceCount == 0);

		let immediate = scope AudioEngineSettings();
		immediate.Headless = true;
		immediate.VoiceCount = 1;
		immediate.StreamVoiceCount = 0;
		immediate.DedupeWindowSeconds = 0.0f;
		immediate.DyingVoiceCapacity = 0;
		let hardEngine = scope AudioEngine(immediate);
		Test.Assert(hardEngine.Play(clips[0], parameters).IsValid);
		Test.Assert(hardEngine.Play(clips[1], parameters).IsValid);
		Test.Assert(hardEngine.DyingVoiceCount == 0);
		Test.Assert(hardEngine.ActiveVoiceCount == 1);
	}

	/// A repeat inside the window answers the voice already going rather than stacking a
	/// second one, which is what keeps a shotgun's pellets from becoming one loud crack.
	[Test]
	public static void ARepeatInsideTheWindowMergesIntoTheVoiceAlreadyGoing()
	{
		let engine = scope AudioEngine(HeadlessSettings!(8, 2, 1.0f / 30.0f));
		let clip = MakeToneClip(1.0f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;

		let first = engine.Play(clip, parameters);
		let merged = engine.Play(clip, parameters);
		Test.Assert(first.IsValid);
		Test.Assert(merged == first);
		Test.Assert(engine.ActiveVoiceCount == 1);

		engine.Update(0.1f);
		let second = engine.Play(clip, parameters);
		Test.Assert(second.IsValid);
		Test.Assert(!(second == first));
		Test.Assert(engine.ActiveVoiceCount == 2);
	}

	/// A persistent source opts OUT of merging, and opting out must not ARM the window
	/// either: several authored emitters sharing one clip are distinct voices at distinct
	/// places, and a later one shot must not fold into any of them.
	[Test]
	public static void OptingOutNeitherMergesNorArmsTheWindow()
	{
		let engine = scope AudioEngine(HeadlessSettings!(8, 2, 1.0f / 30.0f));
		let clip = MakeToneClip(1.0f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.Spatial = true;
		parameters.AllowDedupe = false;

		let voices = scope VoiceHandle[4];
		for (int i < 4)
		{
			parameters.Position = .((float)i * 10.0f, 0.0f, 0.0f);
			voices[i] = engine.Play(clip, parameters);
			Test.Assert(voices[i].IsValid);
		}
		Test.Assert(engine.ActiveVoiceCount == 4);
		for (int i = 1; i < 4; i++)
			Test.Assert(!(voices[i] == voices[0]));

		let shot = engine.Play(clip, AudioPlayParams());
		Test.Assert(shot.IsValid);
		for (int i < 4)
			Test.Assert(!(shot == voices[i]));
		Test.Assert(engine.ActiveVoiceCount == 5);
	}
}
