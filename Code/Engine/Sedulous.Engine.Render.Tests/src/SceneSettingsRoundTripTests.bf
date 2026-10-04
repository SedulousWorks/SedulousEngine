using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Render.Tests;

/// The authored look and the authored environment ride the SCENE: what an artist sets in the
/// editor is what the runtime reads back.
class SceneSettingsRoundTripTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	/// The defaults MUST match what the renderer used before the settings existed, so
	/// authoring nothing changes nothing visually.
	[Test]
	public static void ThePostProcessDefaultsMatchTheRenderersOwn()
	{
		let system = scope PostProcessSystem();
		let defaults = system.Post;

		// Two to the nought is the old fixed multiplier.
		Test.Assert(defaults.ExposureEV == 0.0f);
		Test.Assert(defaults.TonemapOperator == .AgX);
		Test.Assert(defaults.BloomEnabled);
		Test.Assert(Near(defaults.BloomIntensity, 0.05f));
		Test.Assert(Near(defaults.BloomThreshold, 1.0f));
		Test.Assert(Near(defaults.BloomKnee, 0.6f));
		Test.Assert(defaults.AoMode == .Off);
		Test.Assert(Near(defaults.AoStrength, 0.6f));
		Test.Assert(!defaults.SsrEnabled);
		Test.Assert(defaults.AaMode == .Off);
		Test.Assert(Near(defaults.TaaBlendFactor, 0.97f));
		Test.Assert(Near(defaults.TaaVarianceGamma, 1.25f));
	}

	/// Edit a field of each kind, a float, a boolean and all three enums, write the whole
	/// scene and read it back: the authored look survives.
	[Test]
	public static void TheAuthoredLookSurvivesASceneRoundTrip()
	{
		let source = scope Scene("look");
		let post = source.AddSystem<PostProcessSystem>();
		post.Post.ExposureEV = 1.5f;
		post.Post.TonemapOperator = .Clamp;
		post.Post.BloomIntensity = 0.2f;
		post.Post.AoMode = .GTAO;
		post.Post.SsrEnabled = true;
		post.Post.SsgiEnabled = true;
		post.Post.SsgiIntensity = 1.5f;
		post.Post.AaMode = .TAA;
		post.Post.TaaBlendFactor = 0.9f;
		source.CreateEntity("e");

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);

		let loaded = scope Scene();
		let reloaded = loaded.AddSystem<PostProcessSystem>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let settings = reloaded.Post;
		Test.Assert(Near(settings.ExposureEV, 1.5f));
		Test.Assert(settings.TonemapOperator == .Clamp);
		Test.Assert(Near(settings.BloomIntensity, 0.2f));
		Test.Assert(settings.AoMode == .GTAO);
		Test.Assert(settings.SsrEnabled);
		Test.Assert(settings.SsgiEnabled);
		Test.Assert(Near(settings.SsgiIntensity, 1.5f));
		Test.Assert(settings.AaMode == .TAA);
		Test.Assert(Near(settings.TaaBlendFactor, 0.9f));
	}

	/// The image based lighting dimmers default to full physical strength and ride the scene
	/// the same way the look does.
	[Test]
	public static void TheIblDimmersSurviveASceneRoundTrip()
	{
		let defaults = EnvironmentSettings();
		Test.Assert(Near(defaults.IblDiffuseIntensity, 1.0f));
		Test.Assert(Near(defaults.IblSpecularIntensity, 1.0f));

		let source = scope Scene("env");
		let environment = source.AddSystem<EnvironmentSystem>();
		environment.Environment.IblDiffuseIntensity = 0.35f;
		environment.Environment.IblSpecularIntensity = 0.8f;
		source.CreateEntity("e");

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);

		let loaded = scope Scene();
		let reloaded = loaded.AddSystem<EnvironmentSystem>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		Test.Assert(Near(reloaded.Environment.IblDiffuseIntensity, 0.35f));
		Test.Assert(Near(reloaded.Environment.IblSpecularIntensity, 0.8f));
	}

	/// The sun's shadow reach rides the scene (environment version 2), and a version 1 block,
	/// as the stored scenes hold it, reads the reach's defaults and its own fields.
	[Test]
	public static void TheShadowReachRoundTripsAndAVersionOneBlockReadsItsDefaults()
	{
		let written = scope EnvironmentSystem();
		written.Environment.ShadowDistance = 70.0f;
		written.Environment.ShadowCascadeSplit = 0.8f;
		written.Environment.ShadowFadeDistance = 12.0f;
		written.Environment.IblSpecularIntensity = 0.6f;
		let typeId = TypeIdOf("environment");

		let current = scope MemoryStream();
		{
			let writer = scope BinarySerializer(current, .Write);
			BeginVersionedPayload(writer, typeId, written.SettingsDataVersion);
			written.SerializeSettings(writer);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}
		current.Seek(0, .Begin);
		let read = scope EnvironmentSystem();
		{
			let reader = scope BinarySerializer(current, .Read);
			BeginVersionedPayload(reader, typeId, read.SettingsDataVersion, read.SettingsMinReadDataVersion);
			read.SerializeSettings(reader);
			EndVersionedPayload(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(Near(read.Environment.ShadowDistance, 70.0f));
		Test.Assert(Near(read.Environment.ShadowCascadeSplit, 0.8f));
		Test.Assert(Near(read.Environment.ShadowFadeDistance, 12.0f));

		// A version 1 block: the chain stamped 1 and no reach (the version 2 layout appends three
		// floats, so a version 1 payload is the version 2 one without its last twelve bytes).
		let stamped = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stamped, .Write);
			BeginVersionedPayload(writer, typeId, 1);
			written.SerializeSettings(writer);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}
		let bytes = stamped.Bytes;
		let versionOne = scope MemoryStream();
		versionOne.Write(Span<uint8>(bytes.Ptr, bytes.Length - 3 * sizeof(float)));
		versionOne.Seek(0, .Begin);
		let legacy = scope EnvironmentSystem();
		legacy.Environment.ShadowDistance = 1.0f; // overwritten only if the reader reads the field
		{
			let reader = scope BinarySerializer(versionOne, .Read);
			BeginVersionedPayload(reader, typeId, legacy.SettingsDataVersion, legacy.SettingsMinReadDataVersion);
			legacy.SerializeSettings(reader);
			EndVersionedPayload(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(Near(legacy.Environment.ShadowDistance, 1.0f), "not read: version 1 has none");
		Test.Assert(Near(legacy.Environment.IblSpecularIntensity, 0.6f), "the version 1 fields read");
	}
}
