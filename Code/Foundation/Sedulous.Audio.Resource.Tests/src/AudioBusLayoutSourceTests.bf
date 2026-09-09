using System;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Resource.Tests;

/// The cooked mixer's wire: flatten, serialize, read back, rebuild.
class AudioBusLayoutSourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	/// A layout worth flattening: a tuned fixed bus, a two link chain on another, and two
	/// named buses, one of them nested under the other.
	private static void MakeLayout(AudioBusLayout outLayout)
	{
		outLayout.Buses[(int)AudioBus.Music].Volume = 0.5f;
		outLayout.Buses[(int)AudioBus.UI].Muted = true;

		var lowpass = AudioBusEffectDesc();
		lowpass.Kind = .Lowpass;
		lowpass.FrequencyHz = 2000.0f;
		var delay = AudioBusEffectDesc();
		delay.Kind = .Delay;
		delay.DelaySeconds = 0.1f;
		delay.DelayDecay = 0.4f;
		outLayout.Buses[(int)AudioBus.Effects].Effects.Add(lowpass);
		outLayout.Buses[(int)AudioBus.Effects].Effects.Add(delay);

		let drums = new AudioNamedBus();
		drums.Name.Set("drums");
		drums.Parent.Set("Effects");
		drums.Settings.Volume = 0.25f;
		var reverb = AudioBusEffectDesc();
		reverb.Kind = .Reverb;
		reverb.RoomSize = 0.7f;
		reverb.Damping = 0.3f;
		reverb.WetLevel = 0.5f;
		drums.Settings.Effects.Add(reverb);
		outLayout.CustomBuses.Add(drums);

		let quiet = new AudioNamedBus();
		quiet.Name.Set("quiet");
		quiet.Parent.Set("drums");
		quiet.Settings.Muted = true;
		outLayout.CustomBuses.Add(quiet);
	}

	/// The flattening's SHAPE: four fixed buses, two named ones, and ONE pool of three
	/// effects that both kinds of bus index runs of.
	[Test]
	public static void FlatteningLaysTheLayoutOutFlat()
	{
		let layout = scope AudioBusLayout();
		MakeLayout(layout);

		let source = scope AudioBusLayoutSource();
		AudioBusLayoutSource.FromLayout(layout, source);

		Test.Assert(source.BusVolume.Count == AudioBus.Count);
		Test.Assert(source.BusEffectStart.Count == AudioBus.Count);
		Test.Assert(source.CustomName.Count == 2);
		Test.Assert(source.EffectKind.Count == 3);

		// The Effects bus's run is the first two of the pool, the named bus's the third.
		Test.Assert(source.BusEffectCount[(int)AudioBus.Effects] == 2);
		Test.Assert(source.CustomEffectStart[0] == 2);
		Test.Assert(source.CustomEffectCount[0] == 1);
		Test.Assert(source.CustomEffectCount[1] == 0);
	}

	[Test]
	public static void TheWireRoundTripsThroughTheSerializer()
	{
		let original = scope AudioBusLayout();
		MakeLayout(original);

		let source = scope AudioBusLayoutSource();
		AudioBusLayoutSource.FromLayout(original, source);

		let stream = scope MemoryStream();
		{
			ISerializable writable = source;
			let writer = scope BinarySerializer(stream, .Write);
			writable.Serialize(writer);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);

		let restored = scope AudioBusLayoutSource();
		{
			ISerializable readable = restored;
			let reader = scope BinarySerializer(stream, .Read);
			readable.Serialize(reader);
			Test.Assert(reader.IsOk);
		}

		let rebuilt = scope AudioBusLayout();
		restored.FillLayout(rebuilt);

		Test.Assert(Near(rebuilt.Buses[(int)AudioBus.Music].Volume, 0.5f));
		Test.Assert(rebuilt.Buses[(int)AudioBus.UI].Muted);
		Test.Assert(rebuilt.Buses[(int)AudioBus.Effects].Effects.Count == 2);
		Test.Assert(rebuilt.Buses[(int)AudioBus.Effects].Effects[0].Kind == .Lowpass);
		Test.Assert(Near(rebuilt.Buses[(int)AudioBus.Effects].Effects[0].FrequencyHz, 2000.0f));
		Test.Assert(rebuilt.Buses[(int)AudioBus.Effects].Effects[1].Kind == .Delay);
		Test.Assert(Near(rebuilt.Buses[(int)AudioBus.Effects].Effects[1].DelayDecay, 0.4f));

		Test.Assert(rebuilt.CustomBuses.Count == 2);
		Test.Assert(rebuilt.CustomBuses[0].Name == "drums");
		Test.Assert(rebuilt.CustomBuses[0].Parent == "Effects");
		Test.Assert(Near(rebuilt.CustomBuses[0].Settings.Volume, 0.25f));
		Test.Assert(rebuilt.CustomBuses[0].Settings.Effects.Count == 1);
		Test.Assert(rebuilt.CustomBuses[0].Settings.Effects[0].Kind == .Reverb);
		Test.Assert(Near(rebuilt.CustomBuses[0].Settings.Effects[0].RoomSize, 0.7f));
		Test.Assert(rebuilt.CustomBuses[1].Name == "quiet");
		Test.Assert(rebuilt.CustomBuses[1].Parent == "drums");
		Test.Assert(rebuilt.CustomBuses[1].Settings.Muted);
		Test.Assert(rebuilt.CustomBuses[1].Settings.Effects.IsEmpty);
	}

	/// A rebuild REPLACES what was there rather than accumulating, since a layout resource
	/// is filled once per load and a reload must not double its buses.
	[Test]
	public static void ARebuildReplacesRatherThanAccumulates()
	{
		let layout = scope AudioBusLayout();
		MakeLayout(layout);

		let source = scope AudioBusLayoutSource();
		AudioBusLayoutSource.FromLayout(layout, source);

		let rebuilt = scope AudioBusLayout();
		source.FillLayout(rebuilt);
		source.FillLayout(rebuilt);

		Test.Assert(rebuilt.CustomBuses.Count == 2);
		Test.Assert(rebuilt.Buses[(int)AudioBus.Effects].Effects.Count == 2);
	}

	/// A run pointing past the pool yields a SHORTER chain rather than a read past the end
	/// of the array: cooked bytes reach the runtime by paths a cook never saw.
	[Test]
	public static void ARunPastThePoolIsClampedRatherThanRead()
	{
		let source = scope AudioBusLayoutSource();
		for (int bus = 0; bus < AudioBus.Count; bus++)
		{
			source.BusVolume.Add(1.0f);
			source.BusMuted.Add(false);
			source.BusEffectStart.Add(0);
			// Four effects claimed, with none in the pool at all.
			source.BusEffectCount.Add(4);
		}

		let rebuilt = scope AudioBusLayout();
		source.FillLayout(rebuilt);
		for (int bus = 0; bus < AudioBus.Count; bus++)
			Test.Assert(rebuilt.Buses[bus].Effects.IsEmpty);
	}

	/// A record whose parallel arrays disagree in length stops at the SHORTEST of them,
	/// which is the only length every one of them can be read at.
	[Test]
	public static void DisagreeingArraysStopAtTheShortest()
	{
		let source = scope AudioBusLayoutSource();
		source.CustomName.Add(new String("drums"));
		source.CustomName.Add(new String("quiet"));
		source.CustomParent.Add(new String(""));
		source.CustomVolume.Add(1.0f);
		source.CustomVolume.Add(1.0f);
		source.CustomMuted.Add(false);
		source.CustomMuted.Add(false);
		source.CustomEffectStart.Add(0);
		source.CustomEffectStart.Add(0);
		source.CustomEffectCount.Add(0);
		source.CustomEffectCount.Add(0);

		let rebuilt = scope AudioBusLayout();
		source.FillLayout(rebuilt);
		Test.Assert(rebuilt.CustomBuses.Count == 1);
		Test.Assert(rebuilt.CustomBuses[0].Name == "drums");
	}
}
