using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;
using Sedulous.Render;
using Sedulous.Render.Pipeline;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// Scene settings from a profile: while a block's source is a profile, an edit of a value field
/// lands in the profile (the block's own fields stay the scene's) and undoes; Copy Into Scene
/// and a source switch are one undo step each; Make Profile writes a profile asset from the
/// block's values and switches to it; a profile-mode edit is queued for the save flow and
/// written to the asset.
class SettingsProfileTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	/// A scene whose environment uses `Profile`, a loaded product under `Id`.
	private class ProfiledScene
	{
		public Sedulous.Scene.Scene Scene = new .("Level") ~ delete _;
		public EnvironmentSystem Env;
		public EnvironmentProfile Profile = new .() ~ delete _;
		public EditorCommandStack Commands = new .() ~ delete _;
		public SceneEditContext Edit ~ delete _;
		public Guid Id = Guid.Create();

		public this()
		{
			Env = Scene.AddSystem<EnvironmentSystem>();
			Env.Environment.AmbientIntensity = 0.25f;
			Profile.Values.AmbientIntensity = 0.9f;
			Env.Environment.Source = .Profile;
			Env.Environment.Profile.SetId(Id);
			Env.Environment.Profile.SetDirect(Profile);
			Edit = new .(Scene, Commands);
		}
	}

	[Test]
	public static void AValueEditLandsInTheProfileAndTheBlocksOwnFieldsInTheScene()
	{
		let s = scope ProfiledScene();
		let edited = scope List<Guid>();
		s.Edit.OnSettingsProfileEdited = new [=edited](type, profile) => { edited.Add(profile); };
		let env = typeof(EnvironmentSettings);

		s.Edit.SetSceneSettingProperty<float>(env, "AmbientIntensity", 0.7f);
		Test.Assert(Near(s.Profile.Values.AmbientIntensity, 0.7f));
		Test.Assert(Near(s.Env.Environment.AmbientIntensity, 0.25f));
		Test.Assert((edited.Count == 1) && (edited[0] == s.Id));

		// An enum, written raw, goes the same way.
		s.Edit.SetSceneSettingPropertyRaw(env, "SkyMode", (int64)SkyMode.Analytic);
		Test.Assert(s.Profile.Values.SkyMode == .Analytic);

		s.Commands.Undo();
		s.Commands.Undo();
		Test.Assert(Near(s.Profile.Values.AmbientIntensity, 0.9f));
		Test.Assert(s.Profile.Values.SkyMode != .Analytic);
		Test.Assert(edited.Count == 4, "every write to the profile is persisted, the undos too");

		// The source is the scene's ([SceneOnly]): switching it edits the block, and after it an
		// edit lands in the scene's own values.
		s.Edit.SetSceneSettingPropertyRaw(env, "Source", (int64)SettingsSource.Scene);
		Test.Assert(s.Env.Environment.Source == .Scene);
		s.Edit.SetSceneSettingProperty<float>(env, "AmbientIntensity", 0.4f);
		Test.Assert(Near(s.Env.Environment.AmbientIntensity, 0.4f));
		Test.Assert(Near(s.Profile.Values.AmbientIntensity, 0.9f));
		Test.Assert(edited.Count == 4);
		s.Commands.Undo();
		s.Commands.Undo();
		Test.Assert(s.Env.Environment.Source == .Profile);
		Test.Assert(Near(s.Env.Environment.AmbientIntensity, 0.25f));
	}

	[Test]
	public static void CopyIntoSceneAndASourceSwitchAreOneUndoStepEach()
	{
		let s = scope ProfiledScene();
		s.Profile.Values.Turbidity = 6.0f;
		let env = typeof(EnvironmentSettings);

		Test.Assert(s.Edit.MutateSceneSettings(env, scope (system) => { system.CopySettingsProfileIntoScene(); }));
		Test.Assert(s.Env.Environment.Source == .Scene);
		Test.Assert(Near(s.Env.Environment.AmbientIntensity, 0.9f));
		Test.Assert(Near(s.Env.Environment.Turbidity, 6.0f));
		Test.Assert(s.Env.Environment.Profile.Id == s.Id, "kept: the profile is a pick away");
		s.Commands.Undo();
		Test.Assert(s.Env.Environment.Source == .Profile);
		Test.Assert(Near(s.Env.Environment.AmbientIntensity, 0.25f));

		let other = Guid.Create();
		Test.Assert(s.Edit.MutateSceneSettings(env, scope [=other](system) => { system.UseSettingsProfile(other); }));
		Test.Assert(s.Env.Environment.Profile.Id == other);
		s.Commands.Undo();
		Test.Assert(s.Env.Environment.Profile.Id == s.Id);
	}

	[Test]
	public static void MakeProfileWritesTheValuesAndSwitchesAndAnEditReachesTheAsset()
	{
		RenderPipeline.RegisterAll();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_settings_profiles", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		context.SetProject(project);
		defer context.SetProject(null);
		RenderCreators.Register(context.Creators);
		// The join the app wires from its builders: the environment profile's asset.
		context.SourceAssetTypesOf = new (product, outAssets) =>
			{
				if (product == typeof(EnvironmentProfile))
					outAssets.Add(typeof(EnvironmentProfileAsset));
			};

		let scene = scope Sedulous.Scene.Scene("Level");
		let env = scene.AddSystem<EnvironmentSystem>();
		env.Environment.AmbientIntensity = 0.3f;
		env.Environment.Turbidity = 5.0f;
		let commands = scope EditorCommandStack();
		let edit = scope SceneEditContext(scene, commands);

		let made = SettingsProfiles.Make(context, edit, typeof(EnvironmentSettings), "Level Environment");
		Test.Assert(made != null);
		Test.Assert(made.GetPath(.. scope .()) == "Profiles/Level Environment");
		let id = made.Id;
		{
			let object = made.ReadObject();
			defer delete object;
			let asset = object as EnvironmentProfileAsset;
			Test.Assert(asset != null);
			Test.Assert(Near(asset.Values.AmbientIntensity, 0.3f));
			Test.Assert(Near(asset.Values.Turbidity, 5.0f));
			Test.Assert(asset.Values.Source == .Scene, "a profile has no source");
		}
		Test.Assert(env.Environment.Source == .Profile);
		Test.Assert(env.Environment.Profile.Id == id);
		commands.Undo();
		Test.Assert(env.Environment.Source == .Scene);
		commands.Redo();

		// The profile loaded (here by hand; the editor binds the cooked product): an edit in
		// profile mode is queued and the save flow writes it to the asset.
		let product = scope EnvironmentProfile();
		product.Values = *env.Environment;
		env.Environment.Profile.SetDirect(product);
		edit.OnSettingsProfileEdited = new [=context, =edit](type, profile) =>
			{
				if (let system = edit.FindSystemBySettingsType(type))
					SettingsProfiles.QueueEdit(context, system, profile);
			};
		edit.SetSceneSettingProperty<float>(typeof(EnvironmentSettings), "Turbidity", 8.0f);
		Test.Assert(Near(product.Values.Turbidity, 8.0f));
		Test.Assert(context.HasPendingAssetEdits);
		Test.Assert(context.DrainAssetEdits(project.SourceDb) case .Ok);
		{
			let object = project.SourceDb.GetInstance(id).ReadObject();
			defer delete object;
			let asset = object as EnvironmentProfileAsset;
			Test.Assert(asset != null);
			Test.Assert(Near(asset.Values.Turbidity, 8.0f));
			Test.Assert(Near(asset.Values.AmbientIntensity, 0.3f));
		}
	}
}
