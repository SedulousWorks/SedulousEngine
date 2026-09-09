using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Audio.Resource.Tests;

/// Building cooked audio records into the runtime products a game binds.
class AudioFactoryTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// An in memory clip carries its CONTAINER bytes, not decoded samples: that is what
	/// keeps a bank of sounds to a sensible size, and the engine decodes once at
	/// registration.
	[Test]
	public static void AnInMemoryClipCarriesItsContainerBytes()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_clip");
		let id = fixture.CookClip("footstep");

		let clip = fixture.Manager.Bind<AudioClip>(id);
		Test.Assert(clip.Get != null);
		Test.Assert(clip.State == .Ready);

		Test.Assert(clip.Get.Channels == 1);
		Test.Assert(clip.Get.SampleRate == 8000);
		Test.Assert(clip.Get.FrameCount == 800);
		Test.Assert(Near(clip.Get.Gain, 0.8f));
		Test.Assert(clip.Get.Loop);
		Test.Assert(clip.Get.LoopStartFrame == 16);
		Test.Assert(clip.Get.LoopEndFrame == 64);
		Test.Assert(!clip.Get.Stream);
		Test.Assert(clip.Get.StreamSource == null);

		// The payload is the container it was imported as, and it still probes as one.
		Test.Assert(!clip.Get.EncodedData.IsEmpty);
		Test.Assert(AudioCodec.Probe(clip.Get.EncodedBytes, let metadata));
		Test.Assert(metadata.FrameCount == clip.Get.FrameCount);
	}

	/// A streamed clip holds NO bytes at all: it takes a re-openable source over the
	/// instance's own data stream, so the mount pages it as it plays.
	[Test]
	public static void AStreamedClipTakesASourceRatherThanBytes()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_stream");
		let id = fixture.CookClip("music", true);

		let clip = fixture.Manager.Bind<AudioClip>(id);
		Test.Assert(clip.Get != null);
		Test.Assert(clip.Get.Stream);
		Test.Assert(clip.Get.EncodedData.IsEmpty);
		Test.Assert(clip.Get.StreamSource != null);

		// Each open is INDEPENDENT: two voices of one clip must not share a cursor.
		let first = clip.Get.StreamSource.OpenStream();
		let second = clip.Get.StreamSource.OpenStream();
		Test.Assert(first != null);
		Test.Assert(second != null);
		defer { delete first; delete second; }

		Test.Assert(first.Size() > 0);
		Test.Assert(first.Seek(32, .Begin) == 32);
		Test.Assert(second.Tell() == 0);
	}

	/// A streamed clip actually PLAYS through the bridge, which is the whole point of the
	/// seam: the engine asks the mount for bytes and gets them.
	[Test]
	public static void AStreamedClipPlaysThroughTheEngine()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_stream_play");
		let id = fixture.CookClip("music", true);
		let clip = fixture.Manager.Bind<AudioClip>(id);
		Test.Assert(clip.Get != null);

		let settings = scope AudioEngineSettings();
		settings.Headless = true;
		settings.VoiceCount = 4;
		settings.StreamVoiceCount = 2;
		let engine = scope AudioEngine(settings);

		var parameters = AudioPlayParams();
		parameters.Bus = .Music;
		parameters.Loop = true;
		let voice = engine.Play(clip.Get, parameters);
		Test.Assert(voice.IsValid);
		engine.Update(0.1f);
		Test.Assert(engine.IsPlaying(voice));

		engine.Stop(voice);
		engine.Update(0.2f);
		Test.Assert(!engine.IsValidHandle(voice));
	}

	/// A record with no payload beside it is REFUSED rather than answered as a silent clip,
	/// which would put a voice in the pool for every play of it.
	[Test]
	public static void AClipWithNoPayloadIsRefused()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_empty");
		let instance = fixture.Database.RootGroup.CreateInstance("hollow",
			AudioResourceFixture.ClipTypeName);
		let record = scope AudioClipSource();
		record.Channels = 1;
		record.SampleRate = 8000;
		instance.WriteObject(record).IgnoreError();

		let clip = fixture.Manager.Bind<AudioClip>(instance.Id);
		Test.Assert(clip.Get == null);
	}

	[Test]
	public static void ACookedLayoutBuildsIntoTheProductAnEngineApplies()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_layout");

		let layout = scope AudioBusLayout();
		layout.Buses[(int)AudioBus.Music].Volume = 0.4f;
		var lowpass = AudioBusEffectDesc();
		lowpass.Kind = .Lowpass;
		lowpass.FrequencyHz = 900.0f;
		layout.Buses[(int)AudioBus.Effects].Effects.Add(lowpass);
		let drums = new AudioNamedBus();
		drums.Name.Set("drums");
		drums.Parent.Set("Effects");
		layout.CustomBuses.Add(drums);

		let id = fixture.CookLayout("mixer", layout);
		let resource = fixture.Manager.Bind<AudioBusLayoutResource>(id);
		Test.Assert(resource.Get != null);
		Test.Assert(Near(resource.Get.Layout.Buses[(int)AudioBus.Music].Volume, 0.4f));
		Test.Assert(resource.Get.Layout.Buses[(int)AudioBus.Effects].Effects.Count == 1);
		Test.Assert(resource.Get.Layout.CustomBuses.Count == 1);
		Test.Assert(resource.Get.Layout.CustomBuses[0].Name == "drums");

		// It applies to a live engine, which is what the product exists for.
		let engine = scope AudioEngine(scope AudioEngineSettings() { Headless = true });
		engine.ApplyBusLayout(resource.Get.Layout);
		Test.Assert(Near(engine.BusVolume(.Music), 0.4f));
		Test.Assert(engine.BusEffectCount(.Effects) == 1);
		Test.Assert(engine.HasNamedBus("drums"));
	}

	/// A cue points at its clips by ID, and the BIND is what records the cue to clip edge:
	/// this is how a reimported clip reaches every cue playing it.
	[Test]
	public static void ACueBindsItsVariantClips()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_cue");
		let first = fixture.CookClip("step_a");
		let second = fixture.CookClip("step_b");

		let ids = scope Guid[3](first, second, Guid());
		let weights = scope float[3](2.0f, 1.0f, 1.0f);
		let id = fixture.CookCue("steps", ids, weights);

		let cue = fixture.Manager.Bind<SoundCue>(id);
		Test.Assert(cue.Get != null);
		Test.Assert(cue.Get.Mode == .Sequential);
		Test.Assert(Near(cue.Get.PitchMin, 0.9f));
		Test.Assert(Near(cue.Get.VolumeMax, 1.0f));

		Test.Assert(cue.Get.Variants.Count == 3);
		Test.Assert(cue.Get.Variants[0].Clip != null);
		Test.Assert(cue.Get.Variants[1].Clip != null);
		Test.Assert(!(cue.Get.Variants[0].Clip == cue.Get.Variants[1].Clip));
		Test.Assert(Near(cue.Get.Variants[0].Weight, 2.0f));

		// A nil id is an authored GAP rather than an error, and resolving skips it.
		Test.Assert(cue.Get.Variants[2].Clip == null);

		var rng = Sedulous.Core.Random(1234);
		uint32 cursor = 0;
		let pick = SoundCue.Resolve(cue.Get, ref rng, -1, ref cursor);
		Test.Assert(pick.IsValid);
		Test.Assert(cue.Get.Variants[pick.VariantIndex].Clip != null);
	}

	/// The variants stop at the SHORTEST of the parallel arrays, which is the only length
	/// both of them can be read at.
	[Test]
	public static void ACueWithDisagreeingArraysStopsAtTheShortest()
	{
		let fixture = scope AudioResourceFixture("scratch_audio_cue_short");
		let first = fixture.CookClip("step_a");
		let second = fixture.CookClip("step_b");

		let ids = scope Guid[2](first, second);
		let weights = scope float[1](1.0f);
		let id = fixture.CookCue("steps", ids, weights);

		let cue = fixture.Manager.Bind<SoundCue>(id);
		Test.Assert(cue.Get != null);
		Test.Assert(cue.Get.Variants.Count == 1);
	}
}
