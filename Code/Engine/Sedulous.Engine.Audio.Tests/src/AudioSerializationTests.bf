using System;
using Sedulous.Audio;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Audio;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Settings;

namespace Sedulous.Engine.Audio.Tests;

/// What of an audio component reaches disk, and what stays behind.
class AudioSerializationTests
{
	private static bool Near(float a, float b) => AudioPlayScene.Near(a, b);

	/// The AUTHORED fields round trip; the runtime voice handle does not.
	[Test]
	public static void ComponentsRoundTripThroughTheScene()
	{
		let clipId = Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
		let cueId = Guid(11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);

		let source = scope Scene("level");
		source.AddSystem<AudioSourceComponentManager>();
		source.AddSystem<AudioListenerComponentManager>();

		let emitter = source.CreateEntity("emitter");
		let authored = source.GetSystem<AudioSourceComponentManager>().Add(emitter);
		authored.Clip.SetId(clipId);
		authored.Cue.SetId(cueId);
		// The discriminant has to survive as well.
		authored.SourceType = .Cue;
		authored.Bus = .Music;
		authored.BusName.Set("drums");
		authored.ReverbSend = 0.35f;
		authored.Volume = 0.7f;
		authored.Pitch = 1.25f;
		authored.Loop = true;
		authored.Spatial = true;
		authored.AutoPlay = true;
		authored.Priority = 200;
		authored.MinDistance = 2.5f;
		authored.MaxDistance = 80.0f;
		authored.AttenuationModel = .Linear;
		authored.Rolloff = 1.5f;
		authored.DopplerFactor = 0.5f;
		authored.ConeInnerAngleDegrees = 45.0f;
		authored.ConeOuterAngleDegrees = 90.0f;
		authored.ConeOuterGain = 0.25f;
		// Runtime state that must NOT travel.
		authored.Voice = .(7, 3);

		let ears = source.CreateEntity("ears");
		source.GetSystem<AudioListenerComponentManager>().Add(ears).IsActive = false;

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);

		let loaded = scope Scene();
		loaded.AddSystem<AudioSourceComponentManager>();
		loaded.AddSystem<AudioListenerComponentManager>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let loadedEmitter = loaded.FindEntity(source.GetEntityId(emitter));
		Test.Assert(loadedEmitter.IsAssigned);
		let reloaded = loaded.GetSystem<AudioSourceComponentManager>().Get(loadedEmitter);
		Test.Assert(reloaded != null);

		Test.Assert(reloaded.Clip.Id == clipId);
		Test.Assert(reloaded.Cue.Id == cueId);
		Test.Assert(reloaded.SourceType == .Cue);
		Test.Assert(reloaded.Bus == .Music);
		Test.Assert(reloaded.BusName == "drums");
		Test.Assert(Near(reloaded.ReverbSend, 0.35f));
		Test.Assert(Near(reloaded.Volume, 0.7f));
		Test.Assert(Near(reloaded.Pitch, 1.25f));
		Test.Assert(reloaded.Loop);
		Test.Assert(reloaded.Spatial);
		Test.Assert(reloaded.AutoPlay);
		Test.Assert(reloaded.Priority == 200);
		Test.Assert(Near(reloaded.MinDistance, 2.5f));
		Test.Assert(Near(reloaded.MaxDistance, 80.0f));
		Test.Assert(reloaded.AttenuationModel == .Linear);
		Test.Assert(Near(reloaded.Rolloff, 1.5f));
		Test.Assert(Near(reloaded.DopplerFactor, 0.5f));
		Test.Assert(Near(reloaded.ConeInnerAngleDegrees, 45.0f));
		Test.Assert(Near(reloaded.ConeOuterAngleDegrees, 90.0f));
		Test.Assert(Near(reloaded.ConeOuterGain, 0.25f));
		// The runtime handle did not travel.
		Test.Assert(!reloaded.Voice.IsValid);

		let loadedEars = loaded.FindEntity(source.GetEntityId(ears));
		Test.Assert(loadedEars.IsAssigned);
		let reloadedEars = loaded.GetSystem<AudioListenerComponentManager>().Get(loadedEars);
		Test.Assert(reloadedEars != null);
		Test.Assert(!reloadedEars.IsActive);
	}

	/// The user's mixer state captures off one engine, survives a store round trip, and
	/// reproduces the mixer on a fresh one.
	[Test]
	public static void UserVolumesCaptureStoreAndApply()
	{
		// The store loads THROUGH the registry, so the section has to be in it or the reload
		// finds bytes it cannot name.
		AudioSettings.RegisterAll();

		let settings = scope AudioEngineSettings();
		settings.Headless = true;

		let engine = scope AudioEngine(settings);
		engine.SetBusVolume(.Music, 0.25f);
		engine.SetBusMuted(.Effects, true);

		let store = scope Settings();
		store.Section<AudioUserSettings>().CaptureFrom(engine);

		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, scope (stream, mode) =>
			new BinarySerializerContext(stream, mode)) case .Ok);
		buffer.Seek(0, .Begin);

		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, scope (stream, mode) =>
			new BinarySerializerContext(stream, mode)) case .Ok);

		let user = loaded.Find<AudioUserSettings>();
		Test.Assert(user != null);
		Test.Assert(Near(user.Volumes[(int)AudioBus.Music], 0.25f));
		Test.Assert(user.Muted[(int)AudioBus.Effects]);

		let fresh = scope AudioEngine(settings);
		user.ApplyTo(fresh);
		Test.Assert(Near(fresh.BusVolume(.Music), 0.25f));
		Test.Assert(fresh.BusMuted(.Effects));
		Test.Assert(Near(fresh.BusVolume(.Master), 1.0f));
	}

	/// The engine honours its configured slot count and ignores an index past it.
	[Test]
	public static void ListenerSlotsHonourTheConfiguredCount()
	{
		let settings = scope AudioEngineSettings();
		settings.Headless = true;
		settings.ListenerCount = 3;

		let engine = scope AudioEngine(settings);
		Test.Assert(engine.ListenerCount == 3);

		engine.SetListenerTransformIndexed(2, .(1, 2, 3), .(0, 0, -1), .(0, 1, 0), .(0, 0, 0));
		// Out of bounds: it does nothing rather than writing past the slots.
		engine.SetListenerTransformIndexed(7, .(0, 0, 0), .(0, 0, -1), .(0, 1, 0), .(0, 0, 0));
		engine.SetListenerEnabled(1, false);
		// The pump survives a partial configuration.
		engine.Update(1.0f / 60.0f);
	}
}
