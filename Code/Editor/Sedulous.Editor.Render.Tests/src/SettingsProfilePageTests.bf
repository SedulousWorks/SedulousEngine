using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Engine.Render;
using Sedulous.Render.Pipeline;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Render.Tests;

/// The settings profile page: its preview takes the profile's values, on its built-in scene or
/// on a project scene that takes a profile, and the scene each profile is previewed on is
/// remembered. Then the page from the preview pages' markup over a profile in a project, with no
/// host (so no preview): its rows the values' (the scene's own fields left out), an edit one undo
/// step, and Discard Changes taking every edit back.
class SettingsProfilePageTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	/// Markup under the data root: a node with one reference, the caller's.
	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A project holding an environment profile ("Dusk") and its editor settings.
	class Bed
	{
		public String Dir = new .("scratch_profile_page_project") ~ delete _;
		public EditorProject Project;
		public Settings Store = new .() ~ delete _;
		/// What the registered factories make pages with: the markup. Declared before the context, so
		/// it outlives the factories the context's registry holds.
		public AssetPageServicesSource Services = new .(new () =>
			{
				let services = new AssetPageServices();
				services.LoadMarkup = new (path) => LoadMarkup(path);
				return services;
			}) ~ delete _;
		public EditorContext Context = new .() ~ delete _;
		public Instance Dusk;

		public this()
		{
			SettingsProfileEditor.Register(Context, Services); // the asset's types and the preferences' section
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			Context.ProjectEditorSettings = Store;
			Dusk = Project.SourceDb.RootGroup.CreateInstance("Dusk", typeof(EnvironmentProfileAsset).GetFullName(.. scope .()));
			Test.Assert(Dusk != null);
			let asset = scope EnvironmentProfileAsset();
			asset.Values.Turbidity = 3.0f;
			Test.Assert(Dusk.WriteObject(asset) case .Ok);
		}

		public ~this()
		{
			Context.ProjectEditorSettings = null;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// The page over the profile; the caller deletes it.
		public SettingsProfilePage Open()
		{
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			return new SettingsProfilePage(Context, services, Dusk);
		}
	}

	static bool HasRow(IPropertySource rows, StringView name)
	{
		let top = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(top); }
		rows.GetProperties(default, top);
		for (let info in top)
		{
			if (info.Name == name)
				return true;
		}
		return false;
	}

	static double FloatOf(IPropertySource rows, StringView path)
	{
		var value = rows.GetValue(path, 0);
		defer value.Dispose();
		return value.AsFloat;
	}

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

	[Test]
	public static void ItsRowsAreTheValuesTheScenesOwnFieldsLeftOut()
	{
		let bed = scope Bed();
		Test.Assert(bed.Context.Pages.FindFactory(typeof(EnvironmentProfileAsset)) != null, "found along the base chain");
		let page = bed.Open();
		defer delete page;
		Test.Assert(!page.LoadFailed);
		let rows = page.Rows;
		Test.Assert(rows != null);
		Test.Assert(rows.ObjectCount == 1);
		Test.Assert(HasRow(rows, "Turbidity"));
		Test.Assert(!HasRow(rows, "Source"), "a scene's, not a profile's");
		Test.Assert(!HasRow(rows, "Profile"));
		Test.Assert(Math.Abs(FloatOf(rows, "Turbidity") - 3.0) < 1e-5);
		Test.Assert(page.PreviewSceneId.IsNil, "the built-in scene");
		Test.Assert(page.Sections.SectionCount == 3, "notices, the values, facts (no field rows)");

		// The bar names the kind by the asset type's display name, each profile declaring its own.
		Test.Assert((typeof(EnvironmentProfileAsset).GetCustomAttribute<DisplayNameAttribute>() case .Ok(let environment)) && (environment.Name == "Environment Profile"));
		Test.Assert((typeof(PostProcessProfileAsset).GetCustomAttribute<DisplayNameAttribute>() case .Ok(let post)) && (post.Name == "Post Process Profile"));
	}

	[Test]
	public static void AnEditIsOneUndoStepDiscardChangesTakesEveryEditBack()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		let rows = page.Rows;
		page.EditValue("Turbidity", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		Test.Assert(page.IsDirty);
		Test.Assert(Math.Abs(FloatOf(rows, "Turbidity") - 5.0) < 1e-5);
		page.Commands.Undo();
		Test.Assert(Math.Abs(FloatOf(rows, "Turbidity") - 3.0) < 1e-5);

		page.EditValue("Turbidity", PropertyWrite(Sedulous.GUI.Variant(6.0)));
		page.EditValue("Turbidity", PropertyWrite(Sedulous.GUI.Variant(7.0)));
		page.DiscardChanges();
		Test.Assert(!page.IsDirty);
		Test.Assert(Math.Abs(FloatOf(rows, "Turbidity") - 3.0) < 1e-5);
	}

	/// A scene's save wrote the profile: the page reads it again, its undo let go.
	[Test]
	public static void AScenesSaveWritingTheProfileHasThePageReadItAgain()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		page.EditValue("Turbidity", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		let written = scope EnvironmentProfileAsset();
		written.Values.Turbidity = 9.0f;
		Test.Assert(bed.Dusk.WriteObject(written) case .Ok);
		page.OnAssetExternallyModified();
		Test.Assert(Math.Abs(FloatOf(page.Rows, "Turbidity") - 9.0) < 1e-5);
		Test.Assert(!page.IsDirty);
		Test.Assert(!page.Commands.CanUndo);
	}

	/// A gesture's previews reach the preview as they go, and so does its cancel.
	[Test]
	public static void AGesturesPreviewsReachThePreviewAsTheyGoAndItsCancel()
	{
		let bed = scope Bed();
		let page = bed.Open();
		defer delete page;
		let rows = page.Rows;
		let before = page.PreviewsApplied;
		// As a slider's drag: written in place as it goes, the preview given each value.
		rows.BeginEdit("Turbidity");
		rows.PreviewEdit("Turbidity", PropertyWrite(Sedulous.GUI.Variant(4.0)));
		Test.Assert(page.PreviewsApplied == before + 1);
		Test.Assert(Math.Abs(FloatOf(rows, "Turbidity") - 4.0) < 1e-5);
		rows.PreviewEdit("Turbidity", PropertyWrite(Sedulous.GUI.Variant(5.0)));
		Test.Assert(page.PreviewsApplied == before + 2);
		Test.Assert(!page.Commands.CanUndo, "no step while it goes");
		rows.CancelEdit("Turbidity");
		Test.Assert(page.PreviewsApplied == before + 3, "the value back, the preview with it");
		Test.Assert(Math.Abs(FloatOf(rows, "Turbidity") - 3.0) < 1e-5);
	}
}
