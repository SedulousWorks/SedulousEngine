using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Engine.Render;
using Sedulous.Render.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

using Sedulous.Editor.Scene;

namespace Sedulous.Editor.Render;

/// A profile's values as the grid shows them: its settings type's fields, the block's own left out
/// (those marked [SceneOnly]: its source, its profile reference), which are a scene's and not a
/// profile's.
class ProfileValuesSource : IPropertySource
{
	// What the field source tells reaches this one's client.
	private class Forwarder : IPropertySourceClient
	{
		private ProfileValuesSource mOwner;

		public this(ProfileValuesSource owner)
		{
			mOwner = owner;
		}

		public void OnPropertiesChanged() => mOwner.NotifyPropertiesChanged();
		public void OnValuesChanged() => mOwner.ValuesWritten();
	}

	/// Told whenever the values change under it: a gesture's previews (written in place as they
	/// go) and its cancel, which the field source writes without a word, or a values change it
	/// tells; the page's preview follows them. Owned.
	public delegate void() OnValuesWritten ~ delete _;

	private Forwarder mForwarder ~ delete _;
	private FieldPropertySource mInner ~ delete _;
	/// The top-level fields left out, by name.
	private List<String> mSkipped = new .() ~ DeleteContainerAndItems!(_);

	/// Over the values of `type` that `resolve` finds; `commit` writes an edit (both taken, as a
	/// FieldPropertySource takes them).
	public this(Type type, FieldPropertySource.Resolver resolve, FieldPropertySource.Committer commit, Sedulous.Resource.ResourceManager resources)
	{
		mForwarder = new .(this);
		mInner = new FieldPropertySource(type, 1, resolve, commit, resources);
		mInner.Client = mForwarder;
		for (let field in type.GetFields())
		{
			if (field.GetCustomAttribute<SceneOnlyAttribute>() case .Ok)
				mSkipped.Add(new String(field.Name));
		}
	}

	public ~this()
	{
		mInner.Client = null;
	}

	/// The values found again, the grid told (an undo wrote them behind the source).
	public void Refresh() => mInner.Refresh();

	public override int ObjectCount => mInner.ObjectCount;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		if (!parent.IsEmpty)
		{
			mInner.GetProperties(parent, outInfos);
			return;
		}
		let all = scope List<PropertyInfo>();
		mInner.GetProperties(parent, all);
		for (let info in all)
		{
			if (Skipped(info.Name))
				delete info;
			else
				outInfos.Add(info);
		}
	}

	private void ValuesWritten()
	{
		NotifyValuesChanged();
		if (OnValuesWritten != null)
			OnValuesWritten();
	}

	private bool Skipped(StringView name)
	{
		for (let skipped in mSkipped)
		{
			if (skipped == name)
				return true;
		}
		return false;
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object) => mInner.GetValue(path, object);
	public override void BeginEdit(StringView path) => mInner.BeginEdit(path);
	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		mInner.PreviewEdit(path, write);
		ValuesWritten();
	}

	public override void CommitEdit(StringView path, PropertyWrite write) => mInner.CommitEdit(path, write);

	public override void CancelEdit(StringView path)
	{
		let editing = mInner.Editing;
		mInner.CancelEdit(path);
		if (editing)
			ValuesWritten(); // the values back, the preview with them
	}
	public override bool EditList(StringView path, ListEdit edit) => mInner.EditList(path, edit);
	public override Sedulous.GUI.Variant GetDefault(StringView path, int object) => mInner.GetDefault(path, object);
	public override bool Revert(StringView path) => mInner.Revert(path);
	public override void GetRevertText(StringView path, String outText) => mInner.GetRevertText(path, outText);
	public override void CopyValue(StringView path, String outText) => mInner.CopyValue(path, outText);
	public override bool PasteValue(StringView path, StringView text, String reason) => mInner.PasteValue(path, text, reason);
}

/// Edits a profile asset (an Environment Profile, a Post Process Profile; any
/// SettingsProfileAsset), on the preview pages' markup (Data/Editor/PreviewPage.gml; Raptor's
/// editor-gui spec, 5.4, layer 4): a preview rendered with the profile applied, beside the
/// profile's values, the rows a scene's settings show (the block's own fields, its source and its
/// profile, left out, as they are a scene's). The preview is a built-in scene (a ground, spheres of
/// a few materials, a cube and a sun) or one of the project's scenes, picked on the preview's bar,
/// since a shared profile is tuned by how it looks in the levels: it loads as the scene page opens
/// it, seen from where that page's camera was left, the profile's values over the scene's own. The
/// choice is remembered per profile (ProfilePreviewSettings). Each edit is one undo step; Save
/// writes the asset and cooks it, so every scene using the profile picks the change up.
class SettingsProfilePage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/PreviewPage.gml";

	private PreviewPane mPane = null ~ delete _;
	/// One reference, the page's: the preview's bar holds its own.
	private AssetPickerSlot mSceneSlot = null ~ _?.ReleaseRef();
	/// The values' rows; the base's sections let go of them first (ClearSections).
	private ProfileValuesSource mValues = null;
	/// The project scene the profile is previewed on; nil is the built-in one.
	private Guid mPreviewSceneId = .();
	private int mPreviewsApplied = 0;
	/// The preview's entities that draw the page's own meshes and materials, detached before
	/// those go.
	private List<EntityHandle> mPreviewEntities = new .() ~ delete _;
	/// Owned: runtime built, never assets.
	private List<StaticMesh> mPreviewMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<Material> mPreviewMaterials = new .() ~ DeleteContainerAndItems!(_);

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(SettingsProfileAsset), cMarkupPath)
	{
		// The asset holds its values in a wrapper; the rows are the values', as a scene's show them.
		HideAssetRows();
		if (let profile = Profile)
		{
			mValues = new ProfileValuesSource(profile.ValuesType,
				new [=this] (object) => (Profile != null) ? Profile.ValuesAddress : null,
				new [=this] (apply) =>
				{
					// The whole asset before and after, one undo step; its apply tells the page.
					EditWhole("edit_settings_profile", scope [&] (object) =>
						{
							if (let edited = object as SettingsProfileAsset)
								apply(0, edited.ValuesAddress);
						});
				}, context.Resources);
			// The preview scene follows the values as they change, a slider's drag included (the old
			// page's did; the commit alone left the scene still until the release).
			mValues.OnValuesWritten = new [=this] () => { ApplyPreview(); };
			let title = scope String("Values");
			if (profile.ValuesType.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let named))
				title.Set(named.Name);
			AddSection("values", title, mValues);
		}
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "profile.preview");
			mPane.OnFrame = new [=this] () =>
				{
					let preview = (mPane != null) ? mPane.Viewport : null;
					if ((preview != null) && (preview.Scene != null) && SceneLoading.SceneWorldBounds(preview.Scene, let bounds))
						preview.Frame(bounds.Center(), Length(bounds.Extents()));
				};
			// The scene the profile is previewed on: the built-in one, or one of the project's.
			mSceneSlot = new AssetPickerSlot();
			mSceneSlot.AddClass("preview-slot");
			mSceneSlot.Tooltip = "A scene of the project to preview the profile in (the built-in one when none); kept for this profile";
			let refs = Services.Refs;
			mSceneSlot.AcceptTypesOf(refs, typeof(SceneDocument));
			if ((refs != null) && (refs.Pick != null))
				mSceneSlot.SetOnPick(new [=this, =refs] () =>
					{
						refs.Pick(mSceneSlot.AcceptedTypes, mPreviewSceneId, new [=this] (picked) => { SetPreviewScene(picked); });
					});
			mSceneSlot.SetOnClear(new [=this] () => { SetPreviewScene(.()); });
			mSceneSlot.SetOnDropped(new [=this] (dropped) => { SetPreviewScene(dropped); });
			mPane.AddControl(mSceneSlot);
		}
		LoadPreviewPref();
		LoadPreviewContent();
		ShowScene();
		if ((mPane != null) && !LoadFailed)
			mPane.Show();
	}

	public ~this()
	{
		// The grid's sections let go of the values' rows before they go (the base's outlive these).
		ClearSections();
		DeleteAndNullify!(mValues);
		// The preview's entities draw the page's meshes and materials directly; detach them before
		// they go, then the pane and its scene.
		ClearPreviewOverrides();
		DeleteAndNullify!(mPane);
	}

	/// The scene the profile is previewed on (nil: the built-in one).
	public Guid PreviewSceneId => mPreviewSceneId;

	/// Previews on another scene (nil: the built-in one): the preview reloads, and the choice is
	/// remembered for this profile.
	public void SetPreviewScene(Guid scene)
	{
		if (scene == mPreviewSceneId)
			return;
		mPreviewSceneId = scene;
		LoadPreviewContent();
		SavePreviewPref();
		ShowScene();
	}

	// === For tests ===

	/// The profile's rows (its values, the scene's own fields left out); null when it did not read.
	public IPropertySource Rows => mValues;
	public PreviewPane Pane => mPane;
	/// How often the values were given to the preview scene (a test has no scene to look at).
	public int PreviewsApplied => mPreviewsApplied;

	/// An edit of the values' property `path` to `write`, as the grid commits one.
	public void EditValue(StringView path, PropertyWrite write)
	{
		if (mValues == null)
			return;
		mValues.BeginEdit(path);
		mValues.CommitEdit(path, write);
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane != null)
			mPane.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	/// A scene's save wrote a profile-mode edit to the asset: show what is stored now.
	public override void OnAssetExternallyModified()
	{
		ReadAgain();
	}

	protected override void OnObjectChanged()
	{
		if (mValues != null)
			mValues.Refresh(); // an undo, or a read again, wrote them behind the source
		ApplyPreview();
	}

	private SettingsProfileAsset Profile => ObjectAs<SettingsProfileAsset>();

	private PreviewViewport Preview => (mPane != null) ? mPane.Viewport : null;

	private void ApplyPreview()
	{
		mPreviewsApplied++;
		let scene = (Preview != null) ? Preview.Scene : null;
		if ((scene != null) && (Profile != null))
			ProfilePreview.PreviewInScene(Profile, scene, Context.Resources);
	}

	private void ShowScene()
	{
		if (mSceneSlot == null)
			return;
		let refs = Services.Refs;
		if (!mPreviewSceneId.IsNil && (refs != null) && (refs.Describe != null))
		{
			let shown = scope ResourceRefShown();
			if (refs.Describe(mPreviewSceneId, shown))
			{
				mSceneSlot.SetValue(shown.Name);
				mSceneSlot.SetGlyph(shown.Glyph, shown.GlyphClass);
				return;
			}
		}
		mSceneSlot.SetValue(""); // the built-in scene
	}

	/// The preview's content: the picked scene, loaded and seen from where its page's camera was
	/// left (else framed whole), or the built-in scene when none is picked or it is gone.
	private void LoadPreviewContent()
	{
		let preview = Preview;
		if (preview == null)
			return;
		// The built-in content draws the page's own meshes and materials: detached and freed
		// before the scene that holds it goes.
		ClearPreviewOverrides();
		mPreviewEntities.Clear();
		ClearAndDeleteItems(mPreviewMeshes);
		ClearAndDeleteItems(mPreviewMaterials);
		var scene = preview.ResetScene();
		if (scene == null)
			return;

		let document = (!mPreviewSceneId.IsNil && (Context.Project != null)) ? Context.Project.SourceDb.GetInstance(mPreviewSceneId) : null;
		var loaded = false;
		if (document != null)
		{
			loaded = SceneLoading.LoadEditorScene(Context, document, scene) case .Ok;
			if (!loaded)
			{
				GlobalLog(.Warning, "Editor: profile '{}': preview scene '{}' did not load, showing the built-in one", Title, document.Name);
				scene = preview.ResetScene();
			}
		}
		let camera = preview.Camera;
		if (loaded)
		{
			// From where that scene's page left its camera, else the whole scene in view.
			let view = SceneViewPrefs.Find(Context.ProjectEditorSettings, mPreviewSceneId);
			if ((view != null) && view.HasCamera)
			{
				camera.Position = view.Camera.Position;
				camera.Yaw = view.Camera.Yaw;
				camera.Pitch = view.Camera.Pitch;
				camera.FocusDistance = view.Camera.FocusDistance;
			}
			else if (SceneLoading.SceneWorldBounds(scene, let bounds))
			{
				camera.FrameSphere(bounds.Center(), Length(bounds.Extents()), camera.FovY, false);
			}
		}
		else
		{
			camera.Position = .(0.0f, 1.7f, 5.0f);
			camera.LookAt(.(0.0f, 0.5f, 0.0f));
			BuildPreviewScene();
		}
		ApplyPreview();
	}

	private void LoadPreviewPref()
	{
		let store = Context.ProjectEditorSettings;
		if (store == null)
			return;
		if (let section = store.Find<ProfilePreviewSettings>())
			mPreviewSceneId = section.SceneFor(InstanceId);
	}

	private void SavePreviewPref()
	{
		let store = Context.ProjectEditorSettings;
		if (store == null)
			return;
		store.Section<ProfilePreviewSettings>().Set(InstanceId, mPreviewSceneId);
		store.MarkChanged<ProfilePreviewSettings>();
		Context.RequestProjectEditorSettingsSave();
	}

	private void BuildPreviewScene()
	{
		let scene = (Preview != null) ? Preview.Scene : null;
		let meshes = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		if (meshes == null)
			return;
		// Runtime built content, owned by the page: the components draw it directly.
		// Colours are sRGB, as entered everywhere.
		void Place(StringView name, StaticMesh mesh, Material material, Float3 position)
		{
			let entity = scene.CreateEntity(name);
			var t = Transform();
			t.Position = position;
			scene.SetLocalTransform(entity, t);
			let mc = meshes.Add(entity);
			mc.Mesh.SetDirect(mesh);
			mc.SetMaterial(material);
			mPreviewEntities.Add(entity);
			mPreviewMaterials.Add(material);
		}
		let ground = mPreviewMeshes.Add(.. Primitives.Plane(14.0f, 14.0f));
		let sphere = mPreviewMeshes.Add(.. Primitives.Sphere(0.5f, 48, 24));
		let cube = mPreviewMeshes.Add(.. Primitives.Cube(0.8f));
		Place("Ground", ground, MaterialPresets.CreatePbr("preview.ground", .(0.55f, 0.55f, 0.55f, 1), 0.0f, 0.9f), .(0.0f, 0.0f, 0.0f));
		Place("Matte", sphere, MaterialPresets.CreatePbr("preview.matte", .(0.9f, 0.9f, 0.9f, 1), 0.0f, 0.6f), .(-1.2f, 0.5f, 0.0f));
		Place("Metal", sphere, MaterialPresets.CreatePbr("preview.metal", .(0.95f, 0.8f, 0.45f, 1), 1.0f, 0.3f), .(0.0f, 0.5f, 0.0f));
		Place("Gloss", sphere, MaterialPresets.CreatePbr("preview.gloss", .(0.8f, 0.15f, 0.12f, 1), 0.0f, 0.1f), .(1.2f, 0.5f, 0.0f));
		Place("Cube", cube, MaterialPresets.CreatePbr("preview.cube", .(0.3f, 0.45f, 0.75f, 1), 0.0f, 0.7f), .(2.6f, 0.4f, -0.8f));

		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.6f) * Quaternion.FromAxisAngle(.(1, 0, 0), -0.9f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.CastsShadows = true; // the profile's shadow reach and fade show on the ground
		}
	}

	/// Detaches the page's meshes and materials from the preview's entities, ahead of deleting
	/// them.
	private void ClearPreviewOverrides()
	{
		let scene = (Preview != null) ? Preview.Scene : null;
		let meshes = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		if (meshes == null)
			return;
		for (let entity in mPreviewEntities)
		{
			if (let mc = meshes.Get(entity))
			{
				mc.Mesh.SetDirect(null);
				mc.Materials.Clear();
				mc.MaterialCache.Clear();
			}
		}
	}
}
