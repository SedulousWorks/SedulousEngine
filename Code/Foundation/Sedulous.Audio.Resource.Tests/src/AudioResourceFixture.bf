using System;
using System.Collections;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Audio.Resource.Tests;

/// A scratch mount, a database, and the three factories a cooked audio asset reaches
/// through: the clip's, the layout's and the cue's.
///
/// All three, because the point of a factory is partly the EDGES it records mid build, and
/// a fixture missing the clip factory would test a cue in isolation from what it binds.
class AudioResourceFixture
{
	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Serializers ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;

	public AudioClipFactory Clips = new .() ~ delete _;
	public AudioBusLayoutFactory Layouts = new .() ~ delete _;
	public SoundCueFactory Cues = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public const String ClipTypeName = "Sedulous.Audio.Resource.AudioClipSource";
	public const String LayoutTypeName = "Sedulous.Audio.Resource.AudioBusLayoutSource";
	public const String CueTypeName = "Sedulous.Audio.Resource.SoundCueSource";

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		AudioResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
		Manager = new ResourceManager(Database, null);

		AudioResources.AddFactories(Manager, Clips, Layouts, Cues);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// A real wav of a tone, so a clip the factory builds is one the engine can actually
	/// decode and play.
	public static void MakeWav(List<uint8> outBytes, float seconds = 0.1f,
		uint32 sampleRate = 8000, uint32 channels = 1)
	{
		let samples = scope List<int16>();
		let frameCount = (int)(seconds * (float)sampleRate);
		for (int frame = 0; frame < frameCount; frame++)
		{
			let t = (float)frame / (float)sampleRate;
			let sample = (int16)(0.5f * Sin(2.0f * 3.14159265f * 440.0f * t) * 32000.0f);
			for (uint32 channel = 0; channel < channels; channel++)
				samples.Add(sample);
		}
		AudioCodec.EncodeWav(samples, channels, sampleRate, outBytes);
	}

	/// Cooks a clip: the record in the envelope, the container bytes in "data" beside it,
	/// which is the shape the factory reads back.
	public Guid CookClip(StringView name, bool stream = false, bool keepCompressed = false)
	{
		let wav = scope List<uint8>();
		MakeWav(wav);
		AudioCodec.Probe(wav, let metadata);

		let instance = Database.RootGroup.CreateInstance(name, ClipTypeName);
		let record = scope AudioClipSource();
		record.Channels = metadata.Channels;
		record.SampleRate = metadata.SampleRate;
		record.FrameCount = metadata.FrameCount;
		record.DurationSeconds = metadata.DurationSeconds;
		record.Gain = 0.8f;
		record.Loop = true;
		record.LoopStartFrame = 16;
		record.LoopEndFrame = 64;
		record.Stream = stream;
		record.KeepCompressed = keepCompressed;
		record.ContainerExtension.Set("wav");
		instance.WriteObject(record).IgnoreError();
		instance.WriteData("data", wav).IgnoreError();
		return instance.Id;
	}

	public Guid CookLayout(StringView name, AudioBusLayout layout)
	{
		let instance = Database.RootGroup.CreateInstance(name, LayoutTypeName);
		let record = scope AudioBusLayoutSource();
		AudioBusLayoutSource.FromLayout(layout, record);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}

	public Guid CookCue(StringView name, Span<Guid> clipIds, Span<float> weights)
	{
		let instance = Database.RootGroup.CreateInstance(name, CueTypeName);
		let record = scope SoundCueSource();
		for (let id in clipIds)
			record.ClipId.Add(id);
		for (let weight in weights)
			record.Weight.Add(weight);
		record.Mode = (uint8)SoundCueMode.Sequential;
		record.PitchMin = 0.9f;
		record.PitchMax = 1.1f;
		record.VolumeMin = 0.8f;
		record.VolumeMax = 1.0f;
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}
}
