using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Audio;
using static Sedulous.Audio.Tests.AudioEngineFixture;

namespace Sedulous.Audio.Tests;

/// The bus layout as DATA: the fixed four's tuning and effect chains, and the named buses
/// that sit on top of them.
class AudioEngineBusLayoutTests
{
	private static AudioNamedBus NamedBus(AudioBusLayout layout, StringView name,
		StringView parent = "")
	{
		let bus = new AudioNamedBus();
		bus.Name.Set(name);
		bus.Parent.Set(parent);
		layout.CustomBuses.Add(bus);
		return bus;
	}

	/// A layout's volumes, mutes and chains all land, voices keep playing through a spliced
	/// chain, and re-applying an empty layout tears the chains down without taking the
	/// voices with them.
	[Test]
	public static void ALayoutAppliesVolumesMutesAndEffectChains()
	{
		let engine = scope AudioEngine(HeadlessSettings!());

		let layout = scope AudioBusLayout();
		layout.Buses[(int)AudioBus.Music].Volume = 0.5f;
		layout.Buses[(int)AudioBus.UI].Muted = true;

		var lowpass = AudioBusEffectDesc();
		lowpass.Kind = .Lowpass;
		lowpass.FrequencyHz = 2000.0f;
		var delay = AudioBusEffectDesc();
		delay.Kind = .Delay;
		delay.DelaySeconds = 0.1f;
		delay.DelayDecay = 0.4f;
		layout.Buses[(int)AudioBus.Effects].Effects.Add(lowpass);
		layout.Buses[(int)AudioBus.Effects].Effects.Add(delay);

		engine.ApplyBusLayout(layout);
		Test.Assert(Near(engine.BusVolume(.Music), 0.5f));
		Test.Assert(engine.BusMuted(.UI));
		Test.Assert(engine.BusEffectCount(.Effects) == 2);
		Test.Assert(engine.BusEffectCount(.Master) == 0);

		let clip = MakeToneClip(0.5f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(voice));

		engine.ApplyBusLayout(scope AudioBusLayout());
		Test.Assert(engine.BusEffectCount(.Effects) == 0);
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(voice));
	}

	/// A named bus behaves exactly like a fixed one: it takes a volume, a mute and a chain,
	/// nests under another custom bus, and a voice addresses it BY NAME. An unknown name
	/// falls back to the fixed bus rather than silencing the play.
	[Test]
	public static void ANamedBusRoutesVoicesAndTunesLikeAFixedOne()
	{
		let engine = scope AudioEngine(HeadlessSettings!());

		let layout = scope AudioBusLayout();
		let drums = NamedBus(layout, "drums", "Effects");
		drums.Settings.Volume = 0.5f;
		var lowpass = AudioBusEffectDesc();
		lowpass.Kind = .Lowpass;
		lowpass.FrequencyHz = 1500.0f;
		drums.Settings.Effects.Add(lowpass);
		// A custom bus under another custom bus.
		let quiet = NamedBus(layout, "quiet", "drums");
		quiet.Settings.Muted = true;

		engine.ApplyBusLayout(layout);
		Test.Assert(engine.NamedBusCount == 2);
		Test.Assert(engine.HasNamedBus("drums"));
		Test.Assert(engine.HasNamedBus("quiet"));
		Test.Assert(!engine.HasNamedBus("nope"));
		Test.Assert(Near(engine.NamedBusVolume("drums"), 0.5f));
		Test.Assert(engine.NamedBusMuted("quiet"));
		Test.Assert(engine.NamedBusEffectCount("drums") == 1);
		// The fixed buses are untouched by a named one's chain.
		Test.Assert(engine.BusEffectCount(.Effects) == 0);

		let clip = MakeToneClip(1.0f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.BusName = "drums";
		let onDrums = engine.Play(clip, parameters);
		Test.Assert(onDrums.IsValid);
		Test.Assert(engine.GetVoiceStatus(onDrums, var status));
		Test.Assert(status.BusName == "drums");

		var unknown = AudioPlayParams();
		unknown.Loop = true;
		unknown.BusName = "missing";
		unknown.AllowDedupe = false;
		let fallback = engine.Play(clip, unknown);
		Test.Assert(fallback.IsValid);
		Test.Assert(engine.GetVoiceStatus(fallback, out status));
		Test.Assert(status.BusName.IsEmpty);
		Test.Assert(status.Bus == .Effects);

		engine.SetNamedBusVolume("drums", 0.25f);
		Test.Assert(Near(engine.NamedBusVolume("drums"), 0.25f));
		engine.SetNamedBusMuted("drums", true);
		Test.Assert(engine.NamedBusMuted("drums"));
		engine.SetNamedBusMuted("drums", false);
		// The mute REMEMBERED the level it came back to.
		Test.Assert(Near(engine.NamedBusVolume("drums"), 0.25f));

		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(onDrums));
	}

	/// A rebuild reconciles BY NAME and keeps every voice ALIVE: a kept bus updates in place
	/// and its voices keep their name, a removed one hands its voices back to their fixed
	/// fallback rather than taking them down with it.
	[Test]
	public static void ARebuildKeepsVoicesAliveAndReHomesTheOrphans()
	{
		let engine = scope AudioEngine(HeadlessSettings!());

		let layout = scope AudioBusLayout();
		NamedBus(layout, "drums", "Effects");
		NamedBus(layout, "voices");
		engine.ApplyBusLayout(layout);

		let clipA = MakeToneClip(1.0f);
		let clipB = MakeToneClip(1.0f, 4000, 1);
		defer { delete clipA; delete clipB; }

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.BusName = "drums";
		let onDrums = engine.Play(clipA, parameters);
		parameters.BusName = "voices";
		parameters.AllowDedupe = false;
		let onVoices = engine.Play(clipB, parameters);
		Test.Assert(onDrums.IsValid);
		Test.Assert(onVoices.IsValid);

		// The rebuild drops "voices" and re-parents "drums" while both are live.
		let rebuilt = scope AudioBusLayout();
		let drumsKept = NamedBus(rebuilt, "drums", "Music");
		drumsKept.Settings.Volume = 0.8f;
		engine.ApplyBusLayout(rebuilt);

		Test.Assert(engine.NamedBusCount == 1);
		Test.Assert(Near(engine.NamedBusVolume("drums"), 0.8f));
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(onDrums));
		Test.Assert(engine.IsPlaying(onVoices));

		Test.Assert(engine.GetVoiceStatus(onDrums, var status));
		Test.Assert(status.BusName == "drums");
		Test.Assert(engine.GetVoiceStatus(onVoices, out status));
		Test.Assert(status.BusName.IsEmpty);

		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(onVoices));
	}

	/// The degenerate layouts all defuse rather than fault: a cycle lands on Master, an
	/// unknown parent lands on Master, and a repeat or a fixed bus's name is skipped.
	///
	/// Authored data reaches the engine by paths a cook never saw, so the runtime cannot
	/// assume the cook rejected any of these.
	[Test]
	public static void TheDegenerateLayoutsDefuseAndStillMix()
	{
		let engine = scope AudioEngine(HeadlessSettings!());

		let layout = scope AudioBusLayout();
		NamedBus(layout, "a", "b");
		NamedBus(layout, "b", "a");
		NamedBus(layout, "orphan", "ghost");
		NamedBus(layout, "a");
		NamedBus(layout, "Effects");
		engine.ApplyBusLayout(layout);

		Test.Assert(engine.NamedBusCount == 3);
		Test.Assert(engine.HasNamedBus("a"));
		Test.Assert(engine.HasNamedBus("b"));
		Test.Assert(engine.HasNamedBus("orphan"));
		Test.Assert(!engine.HasNamedBus("Effects"));

		let clip = MakeToneClip(0.5f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		parameters.AllowDedupe = false;
		for (let name in StringView[3]("a", "b", "orphan"))
		{
			parameters.BusName = name;
			Test.Assert(engine.Play(clip, parameters).IsValid);
		}
		engine.Update(0.1f);
		Test.Assert(engine.ActiveVoiceCount == 3);
	}

	/// A reverb on a bus is our own maths inside the backend's graph, so the headless mixer
	/// has to survive both the splice and the teardown mid play.
	[Test]
	public static void AReverbBusEffectSplicesAndTheMixerSurvivesIt()
	{
		let engine = scope AudioEngine(HeadlessSettings!());

		let layout = scope AudioBusLayout();
		var reverb = AudioBusEffectDesc();
		reverb.Kind = .Reverb;
		reverb.RoomSize = 0.7f;
		reverb.Damping = 0.3f;
		reverb.WetLevel = 0.5f;
		layout.Buses[(int)AudioBus.Effects].Effects.Add(reverb);
		engine.ApplyBusLayout(layout);
		Test.Assert(engine.BusEffectCount(.Effects) == 1);

		let clip = MakeToneClip(0.3f);
		defer delete clip;

		var parameters = AudioPlayParams();
		parameters.Loop = true;
		let voice = engine.Play(clip, parameters);
		Test.Assert(voice.IsValid);

		// Pumped past the clip's own length, so the tail is what is being mixed.
		for (int i < 30)
			engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(voice));

		engine.ApplyBusLayout(scope AudioBusLayout());
		engine.Update(1.0f / 60.0f);
		Test.Assert(engine.IsPlaying(voice));
	}
}
