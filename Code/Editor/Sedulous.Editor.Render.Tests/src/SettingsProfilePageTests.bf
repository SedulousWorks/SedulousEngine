using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Render;
using Sedulous.Render.Pipeline;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Render.Tests;

/// The settings profile page: its preview takes the profile's values, on its built-in scene or
/// on a project scene that takes a profile, and the scene each profile is previewed on is
/// remembered.
class SettingsProfilePageTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	[Test]
	public static void TheProfilePagesPreviewTakesTheProfilesValues()
	{
		let scene = scope Sedulous.Scene.Scene("profile.preview");
		let env = scene.AddSystem<EnvironmentSystem>();
		let post = scene.AddSystem<PostProcessSystem>();
		let kept = Guid.Create();
		env.Environment.Profile.SetId(kept);

		let environment = scope EnvironmentProfileAsset();
		environment.Values.Turbidity = 7.0f;
		environment.Values.ShadowDistance = 45.0f;
		Test.Assert(ProfilePreview.ApplyToScene(environment, scene, null));
		Test.Assert(Near(env.Environment.Turbidity, 7.0f));
		Test.Assert(Near(env.Environment.ShadowDistance, 45.0f));
		Test.Assert(env.Environment.Source == .Scene, "the block's own fields kept");
		Test.Assert(env.Environment.Profile.Id == kept);

		let look = scope PostProcessProfileAsset();
		look.Values.ExposureEV = 1.25f;
		Test.Assert(ProfilePreview.ApplyToScene(look, scene, null));
		Test.Assert(Near(post.Post.ExposureEV, 1.25f));

		let empty = scope Sedulous.Scene.Scene("empty");
		Test.Assert(!ProfilePreview.ApplyToScene(look, empty, null), "no block to take them");
	}

	/// A preview scene's block sourced from a profile shows the edited profile's values: the
	/// preview switches it to its own fields first, so the values written there are in effect.
	[Test]
	public static void APreviewSceneWhoseBlockUsesAProfileShowsTheEditedValues()
	{
		let scene = scope Sedulous.Scene.Scene("profile.preview.sourced");
		let env = scene.AddSystem<EnvironmentSystem>();
		env.UseSettingsProfile(Guid.Create());
		Test.Assert(env.Environment.Source == .Profile);

		let environment = scope EnvironmentProfileAsset();
		environment.Values.Turbidity = 6.5f;
		Test.Assert(ProfilePreview.PreviewInScene(environment, scene, null));
		Test.Assert(env.Environment.Source == .Scene, "the block reads its own fields");
		Test.Assert(Near(env.Effective.Turbidity, 6.5f));
	}

	/// The scene each profile is previewed on is remembered per profile, and survives the
	/// store's file.
	[Test]
	public static void TheProfilesPreviewSceneIsRememberedPerProfile()
	{
		RenderEditorSerializables.Register();
		let first = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let second = Guid(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		let level = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);

		let store = scope Settings();
		Test.Assert(store.Find<ProfilePreviewSettings>() == null);
		let section = store.Section<ProfilePreviewSettings>();
		section.Set(first, level);
		section.Set(second, level);
		section.Set(second, .()); // back to the built-in scene, updated in place
		Test.Assert(section.Prefs.Count == 2);
		Test.Assert(section.SceneFor(first) == level);
		Test.Assert(section.SceneFor(second) == Guid());
		Test.Assert(section.SceneFor(Guid.Create()) == Guid(), "none saved: the built-in scene");

		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope Sedulous.Core.IO.MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		let read = loaded.Find<ProfilePreviewSettings>();
		Test.Assert((read != null) && (read.Prefs.Count == 2));
		Test.Assert(read.SceneFor(first) == level);
		Test.Assert(read.SceneFor(second) == Guid());
	}

	/// The preview preferences moved from Editor.Scene with the page: a file saved before the
	/// move, every name and type id the old one, still loads.
	[Test]
	public static void APreviewSceneSavedBeforeThePagesMoveStillLoads()
	{
		RenderEditorSerializables.Register();
		let profile = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let level = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);
		let store = scope Settings();
		store.Section<ProfilePreviewSettings>().Set(profile, level);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);

		// The file as the build before the move wrote it.
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		for (let name in StringView[?]("ProfilePreviewSettings", "ProfilePreviewPref"))
		{
			let current = scope $"Sedulous.Editor.Render.{name}";
			let former = scope $"Sedulous.Editor.Scene.{name}";
			let currentId = scope $"{Sedulous.Core.Serialization.TypeIdOf(current)}";
			Test.Assert(text.Contains(currentId), scope $"{name}'s id is written as {currentId}: {text}");
			text.Replace(currentId, scope $"{Sedulous.Core.Serialization.TypeIdOf(former)}");
			text.Replace(current, former);
		}
		let old = scope MemoryStream();
		old.Write(.((uint8*)text.Ptr, text.Length));
		old.Seek(0, .Begin);

		let loaded = scope Settings();
		Test.Assert(loaded.Load(old, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0);
		let read = loaded.Find<ProfilePreviewSettings>();
		Test.Assert((read != null) && (read.SceneFor(profile) == level));
	}
}
