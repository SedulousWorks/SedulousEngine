using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Engine.Render;
using Sedulous.Render.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Scene;

/// Edits a profile asset (an Environment Profile, a Post Process Profile; any
/// SettingsProfileAsset): a preview scene on the left (a ground, spheres of a few materials, a
/// cube and a sun) rendered with the profile applied, and the profile's values on the right in
/// the same rows a scene's settings section shows. Save writes the asset and cooks it, so every
/// scene using the profile picks the change up.
///
/// Edits are snapshot commands like the material page's: the whole asset serialized before and
/// after (it is small), consecutive scrubs of one field merged, each apply re-applying the
/// values to the preview.
class SettingsProfilePage : UIEditorPage, IInspectorOwner
{
	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;

	/// Owned; null when the read failed and the page opened empty.
	private SettingsProfileAsset mAsset = null ~ delete _;

	private PreviewViewport mPreview = null;
	/// The preview's entities that draw the page's own meshes and materials, detached before
	/// those go.
	private List<EntityHandle> mPreviewEntities = new .() ~ delete _;
	/// Owned: runtime built, never assets.
	private List<StaticMesh> mPreviewMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<Material> mPreviewMaterials = new .() ~ DeleteContainerAndItems!(_);

	/// Borrowed: the content owns it.
	private PropertyGrid mGrid = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;
	private List<delegate void()> mRefreshers = new .() ~ DeleteContainerAndItems!(_);
	private List<Object> mOwned = new .() ~ DeleteContainerAndItems!(_);
	private bool mRebuildRequested = false;

	public this(EditorContext context, IApplicationHost host, UIHost uiHost, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);

		let object = instance.ReadObject();
		mAsset = object as SettingsProfileAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: profile '{}' failed to read, page opens empty", mTitle);
		InstanceId = instance.Id;

		mPreview = new PreviewViewport(host, uiHost, "profile.preview");
		mPreview.Camera.Position = .(0.0f, 1.7f, 5.0f);
		mPreview.Camera.LookAt(.(0.0f, 0.5f, 0.0f));
		BuildPreviewScene();
		ApplyPreview();

		mGrid = new PropertyGrid();
		RebuildGrid();

		let gridColumn = new FlexLayout();
		gridColumn.Direction = .Vertical;
		gridColumn.Padding = .(8, 6); // inset like the scene inspector
		var grow = LayoutStyle();
		grow.FlexGrow = 1.0f;
		gridColumn.AddView(mGrid, grow);

		let split = new SplitView();
		split.SplitRatio = 0.62f;
		split.SetPanes(mPreview.View, gridColumn);
		mToolbar = new PageToolbar(this, mContext.Actions);
		mContent = PageToolbar.Frame(mToolbar, split);
	}

	public ~this()
	{
		// The preview's entities draw the page's meshes and materials directly; detach them
		// before they go, then the viewport and its scene.
		ClearPreviewOverrides();
		delete mPreview;
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public SettingsProfileAsset Asset => mAsset;
	public PreviewViewport Preview => mPreview;

	/// The values' layout, and where they are: the rows' target reads both.
	public Type ValuesType => (mAsset != null) ? mAsset.ValuesType : null;
	public void* ValuesAddress => (mAsset != null) ? mAsset.ValuesAddress : null;

	// ---- IInspectorOwner: the rows a scene's settings section shows ----

	public EditorContext Editor => mContext;
	public PropertyGrid Grid => mGrid;
	public UIContext DialogContext => (mGrid != null) ? mGrid.Context : null;

	public void AddEditor(PropertyEditor editor, delegate void() refresher)
	{
		mGrid.AddProperty(editor);
		mRefreshers.Add(new [=editor, =refresher]() =>
			{
				if (!editor.IsEditing)
					refresher();
			} ~ delete refresher);
	}

	public void AddRefresher(delegate void() refresher) => mRefreshers.Add(refresher);
	public void Keep(Object owned) => mOwned.Add(owned);
	public void AssetNameFor(Guid target, String outName) => mContext.AssetNameFor(target, outName);
	public void RequestRebuild() => mRebuildRequested = true;

	// ---- the page ----

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
		if (mPreview != null)
			mPreview.Update(dt);
		if (mRebuildRequested)
		{
			mRebuildRequested = false;
			RebuildGrid();
			return;
		}
		for (let refresher in mRefreshers)
			refresher();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPreview != null)
			mPreview.RenderFrame(ref frame);
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mAsset == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false); // every scene using the profile takes the new values
			GlobalLog(.Information, "Editor: saved profile '{}'", mTitle);
		}
		return saved;
	}

	public override void OnClose()
	{
		if (mPreview != null)
			mPreview.Shutdown();
	}

	/// A scene's save wrote a profile-mode edit to the asset: show what is stored now.
	public override void OnAssetExternallyModified()
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(InstanceId) : null;
		if (instance == null)
			return;
		let object = instance.ReadObject();
		let asset = object as SettingsProfileAsset;
		if (asset == null)
		{
			delete object;
			return;
		}
		delete mAsset;
		mAsset = asset;
		Commands.Clear();
		ClearDirty();
		ApplyPreview();
	}

	/// Restores an asset snapshot, the undo and redo path, and gives the preview its values.
	public void ApplyAssetBlob(List<uint8> blob)
	{
		if (mAsset == null)
			return;
		let stream = scope MemoryStream();
		stream.Write(blob);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		mAsset.Serialize(ar);
		ApplyPreview();
	}

	public void SnapshotAsset(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset == null)
			return;
		let stream = scope MemoryStream();
		{
			let ar = scope BinarySerializer(stream, .Write);
			mAsset.Serialize(ar);
		}
		outBlob.AddRange(stream.Bytes);
	}

	/// One undoable edit of the profile's values: `mutate` runs on them between a snapshot
	/// before and after, recorded as one command merged per `mergeKey`.
	public void ApplyEdit(StringView mergeKey, delegate void(void* values) mutate)
	{
		if (mAsset == null)
			return;
		let before = scope List<uint8>();
		SnapshotAsset(before);
		mutate(mAsset.ValuesAddress);
		let after = scope List<uint8>();
		SnapshotAsset(after);
		Commands.Execute(new EditProfileCommand(this, mergeKey, before, after));
	}

	private void ApplyPreview()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
		if ((scene != null) && (mAsset != null))
			SettingsProfiles.ApplyToScene(mAsset, scene, mContext.Resources);
	}

	/// The profile's values, in the rows a scene's settings section shows; the block's own
	/// fields (its source, its profile) are not a profile's and have none.
	private void RebuildGrid()
	{
		mGrid.Clear();
		ClearAndDeleteItems(mRefreshers);
		ClearAndDeleteItems(mOwned);
		let type = ValuesType;
		let entry = (type != null) ? InspectorRegistry.Find(type) : null;
		if (entry == null)
			return;
		let target = Own(new ProfileValuesTarget(this));
		let section = scope InspectorSection(this, target, entry.DisplayName);
		entry.Build(section);
	}

	private void BuildPreviewScene()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
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

	/// Detaches the page's meshes and materials from the preview's entities, ahead of
	/// deleting them.
	private void ClearPreviewOverrides()
	{
		let scene = (mPreview != null) ? mPreview.Scene : null;
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

	/// Keeps a helper object alive for the grid's contents.
	private T Own<T>(T object) where T : class
	{
		mOwned.Add(object);
		return object;
	}
}
