namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;

/// Editor page for previewing .material files.
///
/// Spawns a unit sphere with the material applied so all surface properties
/// (base color, normal, roughness, metallic) become visible. The info panel
/// shows material properties; full editing arrives in a follow-up.
class MaterialEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private MaterialResource mMaterial;
	private String mMaterialUri = new .() ~ delete _;
	private StaticMeshResource mSphereMesh;
	private PreviewSceneHost mHost ~ delete _;

	public this(StringView filePath, StringView materialUri, MaterialResource material,
		StaticMeshResource sphereMesh, StringView sphereUri, PreviewSceneHost host)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mMaterialUri.Set(materialUri);
		mMaterial = material;
		mSphereMesh = sphereMesh;
		mHost = host;
		UpdateTitle();

		SpawnPreviewSphere(sphereUri);

		// Sphere is unit-radius; fit a 2x2x2 box.
		mHost.FitToBounds(.(Vector3(-1, -1, -1), Vector3(1, 1, 1)));
	}

	public ~this()
	{
		// Both resources are AddRef'd by LoadResource; release them on close.
		if (mMaterial != null)
			mMaterial.ReleaseRef();
		if (mSphereMesh != null)
			mSphereMesh.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview (property editing coming later)

	public MaterialResource Material => mMaterial;
	public PreviewSceneHost Host => mHost;

	public void SetContentView(View view) { mContentView = view; }

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}

	private void SpawnPreviewSphere(StringView sphereUri)
	{
		if (mMaterial == null || mSphereMesh == null) return;

		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null) return;

		let entity = scene.CreateEntity("MaterialPreviewSphere");
		scene.SetLocalTransform(entity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		let handle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(handle))
		{
			// ResourceRef ctor allocates its Path string; setters deep-copy
			// internally, so locals must be Disposed to free the temporaries.
			var meshRef = ResourceRef(mSphereMesh.Id, sphereUri);
			defer meshRef.Dispose();
			comp.SetMeshRef(meshRef);

			var matRef = ResourceRef(mMaterial.Id, mMaterialUri);
			defer matRef.Dispose();
			comp.SetMaterialRef(0, matRef);
		}
	}
}
