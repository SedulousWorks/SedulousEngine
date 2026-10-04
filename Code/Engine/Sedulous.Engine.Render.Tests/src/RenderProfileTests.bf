using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.Render.Tests;

/// Render profiles: a scene's environment and post settings take their values from the scene
/// or from a shared profile, chosen by the block's source. The values in effect drive
/// extraction and post resolution; a missing profile falls back to the scene's own; the blocks
/// round trip and read their earlier versions as source Scene; a cooked profile loads through
/// its factory.
class RenderProfileTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	[Test]
	public static void TheSourceChoosesTheValuesInEffectForExtractionAndPost()
	{
		let scene = scope Scene("profiles");
		let env = scene.AddSystem<EnvironmentSystem>();
		let post = scene.AddSystem<PostProcessSystem>();
		env.Environment.AmbientIntensity = 0.25f;
		post.Post.ExposureEV = 0.5f;

		let envProfile = scope EnvironmentProfile();
		envProfile.Values.AmbientIntensity = 0.9f;
		envProfile.Values.ShadowDistance = 60.0f;
		let postProfile = scope PostProcessProfile();
		postProfile.Values.ExposureEV = 1.5f;
		env.Environment.Profile.SetDirect(envProfile); // the picker binds by identity
		post.Post.Profile.SetDirect(postProfile);

		// Scene source: the profile is referenced but not used.
		Test.Assert(Near(env.Effective.AmbientIntensity, 0.25f));
		Test.Assert(Near(post.Effective.ExposureEV, 0.5f));

		// Profile source: the profile's values are in effect everywhere.
		env.Environment.Source = .Profile;
		post.Post.Source = .Profile;
		Test.Assert(env.Effective == &envProfile.Values);
		Test.Assert(Near(post.Effective.ExposureEV, 1.5f));
		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractEnvironmentInto(scene, snapshot);
		Test.Assert(Near(snapshot.ShadowSettings.Distance, 60.0f));
		Test.Assert(Near(ScenePost.Resolve(*post.Effective).Exposure, Math.Pow(2.0f, 1.5f)));

		// A profile that is not there: the scene's own values stand in.
		env.Environment.Profile.ClearBinding();
		Test.Assert(Near(env.Effective.AmbientIntensity, 0.25f));
	}

	[Test]
	public static void TheBlocksRoundTripTheirSourceAndOlderBlocksReadSourceScene()
	{
		let envId = TypeIdOf("environment");
		let postId = TypeIdOf("postprocess");
		let profileId = Guid.Create();

		// The current version: the source and the profile's identity survive.
		let written = scope EnvironmentSystem();
		written.Environment.Source = .Profile;
		written.Environment.Profile.SetId(profileId);
		let current = scope MemoryStream();
		{
			let writer = scope BinarySerializer(current, .Write);
			BeginVersionedPayload(writer, envId, written.SettingsDataVersion);
			written.SerializeSettings(writer);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}
		current.Seek(0, .Begin);
		let read = scope EnvironmentSystem();
		{
			let reader = scope BinarySerializer(current, .Read);
			BeginVersionedPayload(reader, envId, read.SettingsDataVersion, read.SettingsMinReadDataVersion);
			read.SerializeSettings(reader);
			EndVersionedPayload(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(read.Environment.Source == .Profile);
		Test.Assert(read.Environment.Profile.Id == profileId);

		// A version 2 environment (no source) reads as the scene's own values.
		var older = EnvironmentSettings();
		older.AmbientIntensity = 0.4f;
		let versionTwo = scope MemoryStream();
		{
			let writer = scope BinarySerializer(versionTwo, .Write);
			BeginVersionedPayload(writer, envId, 2);
			RenderSettingsValues.SerializeEnvironment(writer, ref older, true);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}
		versionTwo.Seek(0, .Begin);
		let fromTwo = scope EnvironmentSystem();
		{
			let reader = scope BinarySerializer(versionTwo, .Read);
			BeginVersionedPayload(reader, envId, fromTwo.SettingsDataVersion, fromTwo.SettingsMinReadDataVersion);
			fromTwo.SerializeSettings(reader);
			EndVersionedPayload(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(fromTwo.Environment.Source == .Scene);
		Test.Assert(Near(fromTwo.Environment.AmbientIntensity, 0.4f));

		// And a version 1 post block.
		var olderPost = PostProcessSettings();
		olderPost.ExposureEV = -1.0f;
		let postOne = scope MemoryStream();
		{
			let writer = scope BinarySerializer(postOne, .Write);
			BeginVersionedPayload(writer, postId, 1);
			RenderSettingsValues.SerializePost(writer, ref olderPost);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}
		postOne.Seek(0, .Begin);
		let fromOne = scope PostProcessSystem();
		{
			let reader = scope BinarySerializer(postOne, .Read);
			BeginVersionedPayload(reader, postId, fromOne.SettingsDataVersion, fromOne.SettingsMinReadDataVersion);
			fromOne.SerializeSettings(reader);
			EndVersionedPayload(reader);
			Test.Assert(reader.IsOk);
		}
		Test.Assert(fromOne.Post.Source == .Scene);
		Test.Assert(Near(fromOne.Post.ExposureEV, -1.0f));
	}

	[Test]
	public static void ACookedProfileLoadsThroughItsFactory()
	{
		let root = "scratch_render_profiles_db";
		RemoveDirectoryRecursive(root);
		CreateDirectory(root);
		defer RemoveDirectoryRecursive(root);

		let serializables = scope SerializableRegistry();
		RenderProfileResources.RegisterAll(serializables);
		let mount = scope NativeFileSystem(root);
		SerializerFactory serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete serializers;
		let database = scope ContentDatabase(mount, serializers, "asset", serializables);
		let envFactory = scope EnvironmentProfileFactory();
		let postFactory = scope PostProcessProfileFactory();
		// Declared after the factories and the database, so it goes first.
		let manager = scope ResourceManager(database, null);
		manager.AddFactory(envFactory);
		manager.AddFactory(postFactory);

		let envSource = scope EnvironmentProfileSource();
		envSource.Values.SkyMode = .Analytic;
		envSource.Values.Turbidity = 7.0f;
		envSource.Values.ShadowFadeDistance = 12.0f;
		let envInstance = database.RootGroup.CreateInstance("dusk", "Sedulous.Engine.Render.EnvironmentProfileSource");
		Test.Assert(envInstance.WriteObject(envSource) case .Ok);
		let postSource = scope PostProcessProfileSource();
		postSource.Values.AaMode = .FXAA;
		postSource.Values.BloomIntensity = 0.2f;
		let postInstance = database.RootGroup.CreateInstance("punchy", "Sedulous.Engine.Render.PostProcessProfileSource");
		Test.Assert(postInstance.WriteObject(postSource) case .Ok);

		let envProfile = manager.Bind<EnvironmentProfile>(envInstance.Id).Get;
		let postProfile = manager.Bind<PostProcessProfile>(postInstance.Id).Get;
		Test.Assert((envProfile != null) && (postProfile != null));
		Test.Assert(envProfile.Values.SkyMode == .Analytic);
		Test.Assert(Near(envProfile.Values.Turbidity, 7.0f));
		Test.Assert(Near(envProfile.Values.ShadowFadeDistance, 12.0f));
		Test.Assert(postProfile.Values.AaMode == .FXAA);
		Test.Assert(Near(postProfile.Values.BloomIntensity, 0.2f));
	}
}
