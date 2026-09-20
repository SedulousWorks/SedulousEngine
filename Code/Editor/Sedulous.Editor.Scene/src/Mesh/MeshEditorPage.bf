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
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// The mesh page: the cooked product on a preview entity, following reloads by product
/// identity, beside a stats column with a preview material picker and, for a LOD chain, a
/// row of level buttons driving the component's real ForceLod knob. Read only: a mesh is
/// edited by re-importing its source.
class MeshEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private IApplicationHost mHost;
	private UIHost mUiHost;
	private String mTitle = new .() ~ delete _;

	private PreviewViewport mPreview = null;
	/// The preview mesh entity, in the preview scene.
	private EntityHandle mEntity = .Invalid;
	/// Owned: what draws when no material is picked.
	private Material mDefaultMaterial = null;
	/// The picked override, retained; null is the default.
	private Proxy<Material> mPreviewMaterial = default;
	/// Its source guid, for the label.
	private Guid mPreviewMaterialId = .();
	/// The LOD row's choice, -1 auto, pushed to ForceLod.
	private int32 mPreviewForceLod = -1;

	/// The cooked product, retained; follows reloads.
	private Proxy<StaticMesh> mMeshProxy = default;
	/// Product identity, so a hot reload re-points the component.
	private uint64 mLastUid = 0;

	/// Borrowed: the content owns them.
	private FlexLayout mStatsColumn = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mHost = host;
		mUiHost = uiHost;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;

		mDefaultMaterial = MaterialPresets.CreatePbr("MeshPreview");

		mPreview = new PreviewViewport(host, uiHost, "mesh.preview");
		mPreview.Camera.Position = .(4.0f, 3.0f, 6.0f);
		mPreview.Camera.LookAt(.(0.0f, 0.0f, 0.0f));

		BuildPreviewScene();

		mStatsColumn = new FlexLayout();
		mStatsColumn.Direction = .Vertical;
		mStatsColumn.Spacing = 4.0f;

		let scroll = new ScrollView();
		scroll.VScrollBarPolicy.Value = .Auto;
		scroll.HScrollBarPolicy.Value = .Never;
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		scroll.AddView(mStatsColumn, match);

		let outer = new FlexLayout();
		outer.Direction = .Vertical;
		outer.Padding = .(8, 6);
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		outer.AddView(scroll, grow);

		let split = new SplitView();
		split.AddRef();
		split.SplitRatio = 0.66f;
		split.SetPanes(mPreview.View, outer);
		mContent = split;

		LoadPreviewPref();
		BindMesh();
	}

	public ~this()
	{
		ClearPreviewOverrides();
		mPreviewMaterial.Forget();
		mMeshProxy.Forget();
		delete mPreview;
		delete mDefaultMaterial;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public override Result<void, ErrorCode> Save() => .Ok;
	public PreviewViewport Preview => mPreview;
	public Guid PreviewMaterialId => mPreviewMaterialId;
	public int32 PreviewForceLod => mPreviewForceLod;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mPreview != null)
			mPreview.Update(dt);

		let mesh = mMeshProxy.Get;
		let uid = (mesh != null) ? mesh.Uid : 0;
		if (uid != mLastUid)
		{
			PointComponentAtMesh(mesh);
			mLastUid = uid;
			FramePreview(mesh);
			RefreshStats();
		}
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPreview != null)
			mPreview.RenderFrame(ref frame);
	}

	public override void OnClose()
	{
		if (mPreview != null)
			mPreview.Shutdown();
	}

	private void LoadPreviewPref()
	{
		mPreviewMaterialId = MeshPreviewPrefs.Load(mContext.ProjectEditorSettings, InstanceId);
		if (!mPreviewMaterialId.IsNil && (mContext.Resources != null))
		{
			mPreviewMaterial = mContext.Resources.Bind<Material>(mPreviewMaterialId);
			mPreviewMaterial.Retain();
		}
	}

	private void SavePreviewPref()
	{
		if (MeshPreviewPrefs.Save(mContext.ProjectEditorSettings, InstanceId, mPreviewMaterialId))
			mContext.RequestProjectEditorSettingsSave();
	}

	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
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

	private void BindMesh()
	{
		if (mContext.Resources != null)
		{
			mMeshProxy.Forget();
			mMeshProxy = mContext.Resources.Bind<StaticMesh>(InstanceId);
			mMeshProxy.Retain();
		}
		let mesh = mMeshProxy.Get;
		PointComponentAtMesh(mesh);
		mLastUid = (mesh != null) ? mesh.Uid : 0;
		FramePreview(mesh);
		RefreshStats();
	}

	private MeshComponent* PreviewComponent()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		let meshes = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		return ((meshes != null) && mEntity.IsAssigned) ? meshes.Get(mEntity) : null;
	}

	private void PointComponentAtMesh(StaticMesh mesh)
	{
		let mc = PreviewComponent();
		if (mc == null)
			return;
		mc.Mesh.SetId(.());
		mc.Mesh.SetDirect(mesh); // the cooked product, or null while it is not cooked yet
		mc.ForceLod = mPreviewForceLod; // the page's LOD row drives the real knob
		ApplyPreviewMaterial();
	}

	private void ApplyPreviewLod()
	{
		if (let mc = PreviewComponent())
			mc.ForceLod = mPreviewForceLod;
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

	private void PickPreviewMaterial()
	{
		let ctx = (mContent != null) ? mContent.Context : null;
		if ((ctx == null) || (mContext.Project == null))
			return;
		let dialog = new AssetPickerDialog(mContext, scope StringView[]("MaterialAsset"));
		dialog.OnPicked = new [=this](picked) =>
			{
				mPreviewMaterialId = picked;
				mPreviewMaterial.Forget();
				if ((mContext.Resources != null) && !picked.IsNil)
				{
					mPreviewMaterial = mContext.Resources.Bind<Material>(picked);
					mPreviewMaterial.Retain();
				}
				else
					mPreviewMaterial = default;
				ApplyPreviewMaterial();
				RefreshStats();
				SavePreviewPref();
			};
		dialog.Show(ctx);
	}

	private void RefreshStats()
	{
		if (mStatsColumn == null)
			return;
		mStatsColumn.RemoveAllViews();

		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 4.0f;

			let matLabel = scope String("Material: ");
			if (!mPreviewMaterialId.IsNil && (mContext.Project != null))
			{
				if (let inst = mContext.Project.SourceDb.GetInstance(mPreviewMaterialId))
					matLabel.Append(inst.Name);
				else
					matLabel.Append("(missing)");
			}
			else
				matLabel.Append("Default");
			let materialButton = new Button(matLabel);
			materialButton.FontSize.Value = 12.0f;
			materialButton.OnClick.Add(new [=this](btn) => { PickPreviewMaterial(); });
			var grow = LayoutStyle();
			grow.FlexGrow = 1.0f;
			row.AddView(materialButton, grow);

			let reset = new Button("Default");
			reset.FontSize.Value = 12.0f;
			reset.OnClick.Add(new [=this](btn) =>
				{
					mPreviewMaterialId = .();
					mPreviewMaterial.Forget();
					mPreviewMaterial = default;
					ApplyPreviewMaterial();
					RefreshStats();
					SavePreviewPref();
				});
			var fixedWidth = LayoutStyle();
			fixedWidth.Width = SizeSpec.Fixed(Unit.Dp(64.0f));
			row.AddView(reset, fixedWidth);

			AddRow(row);
		}

		let mesh = mMeshProxy.Get;
		if (mesh == null)
		{
			AddStatLine("Not cooked yet - the preview appears once the asset cooks.");
			return;
		}

		if (mesh.LodCount > 1)
		{
			let row = new FlexLayout();
			row.Direction = .Horizontal;
			row.Spacing = 4.0f;
			AddLodButton(row, "Auto", -1);
			for (uint32 l < mesh.LodCount)
				AddLodButton(row, scope $"LOD {l}", (int32)l);
			AddRow(row);
		}

		let lines = scope List<String>();
		defer { ClearAndDeleteItems!(lines); }
		MeshStats.Lines(mesh, lines);
		for (let line in lines)
			AddStatLine(line);
	}

	private void AddLodButton(FlexLayout row, StringView text, int32 value)
	{
		let button = new Button(text);
		button.FontSize.Value = 12.0f;
		if (value == mPreviewForceLod)
			button.IsEnabled = false; // the active choice reads as pressed
		button.OnClick.Add(new [=this, =value](btn) =>
			{
				mPreviewForceLod = value;
				ApplyPreviewLod();
				RefreshStats();
			});
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		row.AddView(button, grow);
	}

	private void AddRow(View row)
	{
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		style.Height = SizeSpec.Fixed(Unit.Dp(24.0f));
		mStatsColumn.AddView(row, style);
	}

	private void AddStatLine(StringView text)
	{
		let label = new Label(text);
		label.FontSize.Value = 12.0f;
		var style = LayoutStyle();
		style.Width = SizeSpec.Match();
		mStatsColumn.AddView(label, style);
	}

	private void FramePreview(StaticMesh mesh)
	{
		var radius = 1.0f;
		var center = Float3(0.0f, 0.0f, 0.0f);
		if ((mesh != null) && (mesh.VertexCount > 0))
		{
			center = mesh.Bounds.Center();
			radius = Math.Max(0.25f, Length(mesh.Bounds.Extents()));
		}
		if (mPreview != null)
			mPreview.Camera.FrameBounds(center, radius);
	}
}
