using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Geometry;

/// The mesh viewer (Raptor's editor-gui spec, 5.4, layer 3), on the preview pages' markup
/// (Data/Editor/PreviewPage.gml): the cooked product on a preview entity, following reloads by
/// product identity, beside the asset's fields and its stats, read only. The material the preview
/// shows it in (kept for this mesh) and, for a LOD chain, the level it draws are the preview's own
/// choices, on its bar, not among the stats. What every asset page does is AssetObjectPage's.
class MeshEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/PreviewPage.gml";

	private PreviewPane mPane = null ~ delete _;
	/// One reference each, the page's: the preview's bar holds its own.
	private AssetPickerSlot mMaterialSlot = null ~ _?.ReleaseRef();
	private ComboBox mLod = null ~ _?.ReleaseRef();
	/// The preview mesh entity, in the preview scene.
	private EntityHandle mEntity = .Invalid;
	/// Owned: what draws when no material is picked.
	private Material mDefaultMaterial = null;
	/// The picked override, retained; null is the default.
	private Proxy<Material> mPreviewMaterial = default;
	private Guid mPreviewMaterialId = .();
	/// The level the preview draws, -1 the one the game would choose; pushed to ForceLod.
	private int32 mPreviewForceLod = -1;
	/// The cooked product, retained; follows reloads.
	private Proxy<StaticMesh> mMeshProxy = default;
	/// Product identity, so a hot reload re-points the component.
	private uint64 mLastUid = 0;

	/// It takes `services`; `type` is the mesh asset type it opens (static or skinned).
	public this(EditorContext context, AssetPageServices services, Instance instance, Type type)
		: base(context, services, instance, type, cMarkupPath)
	{
		mDefaultMaterial = MaterialPresets.CreatePbr("MeshPreview");
		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "mesh.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			if (let preview = mPane.Viewport)
			{
				preview.Camera.Position = .(4.0f, 3.0f, 6.0f);
				preview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));
			}

			// The material the preview shows the mesh in: a slot on the preview's bar.
			mMaterialSlot = new AssetPickerSlot();
			mMaterialSlot.AddClass("preview-slot");
			mMaterialSlot.Tooltip = "The material the preview shows the mesh in (a neutral one when none); kept for this mesh";
			let refs = Services.Refs;
			mMaterialSlot.AcceptTypesOf(refs, typeof(Material)); // what makes a Material, asked of the builders
			if ((refs != null) && (refs.Pick != null))
				mMaterialSlot.SetOnPick(new [=this, =refs] () =>
					{
						refs.Pick(mMaterialSlot.AcceptedTypes, mPreviewMaterialId, new [=this] (picked) => { SetPreviewMaterial(picked); });
					});
			mMaterialSlot.SetOnClear(new [=this] () => { SetPreviewMaterial(.()); });
			mMaterialSlot.SetOnDropped(new [=this] (dropped) => { SetPreviewMaterial(dropped); });
			mPane.AddControl(mMaterialSlot);

			// A chain's level of detail: the one the game would choose, or one held.
			mLod = new ComboBox();
			mLod.AddClass("preview-lod");
			mLod.Tooltip = "The level of detail the preview draws: Auto is the one the game would choose";
			mLod.SetOnSelectionChanged(new [=this] (index) => { SetPreviewLod(index - 1); });
			mLod.Displayed = false;
			mPane.AddControl(mLod);
		}
		BuildPreviewScene();
		LoadPreviewPref(); // binds the preview material before BindMesh applies it
		ShowMaterial();
		BindMesh();
	}

	public ~this()
	{
		ClearPreviewOverrides();
		mPreviewMaterial.Forget();
		mMeshProxy.Forget();
		DeleteAndNullify!(mPane); // its preview scene before the material it drew with
		delete mDefaultMaterial;
	}

	/// The preview's material, nil for the neutral default; kept with the project per asset.
	public void SetPreviewMaterial(Guid picked)
	{
		mPreviewMaterialId = picked;
		mPreviewMaterial.Forget();
		if ((Context.Resources != null) && !picked.IsNil)
		{
			mPreviewMaterial = Context.Resources.Bind<Material>(picked);
			mPreviewMaterial.Retain();
		}
		else
			mPreviewMaterial = default;
		ApplyPreviewMaterial();
		SavePreviewPref();
		ShowMaterial();
	}

	public Guid PreviewMaterial => mPreviewMaterialId;

	/// The level the preview draws (-1: the one the game would choose).
	public void SetPreviewLod(int32 lod)
	{
		mPreviewForceLod = lod;
		if (let mc = PreviewComponent())
			mc.ForceLod = mPreviewForceLod;
	}

	// === For tests ===

	public PreviewPane Pane => mPane;
	public AssetPickerSlot MaterialSlot => mMaterialSlot;
	public ComboBox LodChoice => mLod;
	public int32 PreviewForceLod => mPreviewForceLod;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mPane != null)
			mPane.Update(dt);
		// The product resolving (a cook) or its identity changing (a re-cook): the component
		// pointed at it again, the preview framed, the stats shown again.
		let mesh = mMeshProxy.Get;
		let uid = (mesh != null) ? mesh.Uid : 0;
		if (uid != mLastUid)
		{
			PointComponentAtMesh(mesh);
			mLastUid = uid;
			FramePreview();
			ShowMesh(mesh);
		}
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

	private void LoadPreviewPref()
	{
		mPreviewMaterialId = MeshPreviewPrefs.Load(Context.ProjectEditorSettings, InstanceId);
		if (!mPreviewMaterialId.IsNil && (Context.Resources != null))
		{
			mPreviewMaterial = Context.Resources.Bind<Material>(mPreviewMaterialId);
			mPreviewMaterial.Retain();
		}
	}

	private void SavePreviewPref()
	{
		if (MeshPreviewPrefs.Save(Context.ProjectEditorSettings, InstanceId, mPreviewMaterialId))
			Context.RequestProjectEditorSettingsSave();
	}

	private Sedulous.Scene.Scene PreviewScene => ((mPane != null) && (mPane.Viewport != null)) ? mPane.Viewport.Scene : null;

	/// The preview world: one entity with a MeshComponent and a sun (the render subsystem gives the
	/// scene its default environment).
	private void BuildPreviewScene()
	{
		let scene = PreviewScene;
		if (scene == null)
			return;
		mEntity = scene.CreateEntity("PreviewMesh");
		if (let meshes = scene.GetSystem<MeshComponentManager>())
			meshes.Add(mEntity); // the mesh lands in BindMesh once the product resolves
		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(sun);
			light.CastsShadows = false;
		}
	}

	/// The cooked product bound by the asset's guid; safe before it is cooked.
	private void BindMesh()
	{
		if (Context.Resources != null)
		{
			mMeshProxy.Forget();
			mMeshProxy = Context.Resources.Bind<StaticMesh>(InstanceId);
			mMeshProxy.Retain();
		}
		let mesh = mMeshProxy.Get;
		PointComponentAtMesh(mesh);
		mLastUid = (mesh != null) ? mesh.Uid : 0;
		FramePreview();
		ShowMesh(mesh);
	}

	/// The stats as facts, the LOD choice as the chain is, and the preview or why there is none.
	private void ShowMesh(StaticMesh mesh)
	{
		if (mesh == null)
		{
			SetFact("Status", "Not cooked yet");
			if (mPane != null)
				mPane.ShowEmpty("Not cooked yet", "The preview and the stats show once the mesh has cooked.");
			if (mLod != null)
				mLod.Displayed = false;
			return;
		}
		SetFact("Status", "Cooked");
		if (mPane != null)
			mPane.Show();
		let lines = scope List<String>();
		defer { ClearAndDeleteItems(lines); }
		MeshStats.Lines(mesh, lines);
		let name = scope String();
		let value = scope String();
		for (let line in lines)
		{
			name.Clear();
			value.Clear();
			MeshStats.Split(line, name, value);
			SetFact(name, value);
		}
		if (mLod != null)
		{
			mLod.Displayed = mesh.LodCount > 1;
			let items = scope String("Auto");
			for (uint32 l < mesh.LodCount)
				items.AppendF("|LOD {}", l);
			mLod.ItemsText = items;
			mLod.SelectedIndex = mPreviewForceLod + 1;
		}
	}

	private MeshComponent* PreviewComponent()
	{
		let scene = PreviewScene;
		let meshes = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		return ((meshes != null) && mEntity.IsAssigned) ? meshes.Get(mEntity) : null;
	}

	/// The preview entity's MeshComponent at `mesh` (null: cleared, not cooked yet).
	private void PointComponentAtMesh(StaticMesh mesh)
	{
		let mc = PreviewComponent();
		if (mc == null)
			return;
		mc.Mesh.SetId(.());
		mc.Mesh.SetDirect(mesh); // the cooked product, or null while it is not cooked yet
		mc.ForceLod = mPreviewForceLod; // the LOD choice drives the real knob
		ApplyPreviewMaterial();
	}

	private void ApplyPreviewMaterial()
	{
		let mc = PreviewComponent();
		if (mc == null)
			return;
		let picked = mPreviewMaterial.Get;
		mc.SetMaterial((picked != null) ? picked : mDefaultMaterial);
	}

	/// Detaches the page's material from the preview entity, ahead of deleting it.
	private void ClearPreviewOverrides()
	{
		if (let mc = PreviewComponent())
		{
			mc.Mesh.SetId(.());
			mc.Mesh.SetDirect(null);
			mc.Materials.Clear();
			mc.MaterialCache.Clear();
		}
	}

	private void ShowMaterial()
	{
		if (mMaterialSlot == null)
			return;
		let refs = Services.Refs;
		if (!mPreviewMaterialId.IsNil && (refs != null) && (refs.Describe != null))
		{
			let shown = scope ResourceRefShown();
			if (refs.Describe(mPreviewMaterialId, shown))
			{
				mMaterialSlot.SetValue(shown.Name);
				mMaterialSlot.SetGlyph(shown.Glyph, shown.GlyphClass);
				return;
			}
		}
		mMaterialSlot.SetValue(""); // the neutral default
	}

	/// The orbit camera framed on the mesh's bounds.
	private void FramePreview()
	{
		let mesh = mMeshProxy.Get;
		var radius = 1.0f;
		var center = Float3(0.0f, 0.0f, 0.0f);
		if ((mesh != null) && (mesh.VertexCount > 0))
		{
			center = mesh.Bounds.Center();
			radius = Math.Max(0.25f, Length(mesh.Bounds.Extents()));
		}
		if ((mPane != null) && (mPane.Viewport != null))
			mPane.Viewport.Frame(center, radius);
	}
}
