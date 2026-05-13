namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Geometry.Resources;
using Sedulous.Resources;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;

/// Editor page for previewing .mesh files in a 3D viewport.
///
/// Owns a PreviewSceneHost which manages the scene/viewport/camera triple.
/// Spawns one entity with a MeshComponent pointing at this resource and a
/// builtin default material so the mesh has visible shading. Info panel on
/// the right shows vertex/triangle/submesh counts and bounds.
class MeshEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private StaticMeshResource mMesh;
	private String mMeshUri = new .() ~ delete _;
	private PreviewSceneHost mHost ~ delete _;

	public this(StringView filePath, StringView uri, StaticMeshResource mesh, PreviewSceneHost host)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mMeshUri.Set(uri);
		mMesh = mesh;
		mHost = host;
		UpdateTitle();

		SpawnMeshEntity();

		if (mMesh?.Mesh != null)
			mHost.FitToBounds(mMesh.Mesh.Bounds);
	}

	public ~this()
	{
		if (mMesh != null)
			mMesh.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;

	public StaticMeshResource Mesh => mMesh;
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

	private void SpawnMeshEntity()
	{
		if (mMesh == null) return;

		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null) return;

		let entity = scene.CreateEntity("PreviewMesh");
		scene.SetLocalTransform(entity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		let handle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(handle))
		{
			// ResourceRef ctor allocates its Path string; the setter deep-copies
			// internally, so the local must be Disposed to free the temporary.
			var meshRef = ResourceRef(mMesh.Id, mMeshUri);
			defer meshRef.Dispose();
			comp.SetMeshRef(meshRef);
			// Materials default through MeshComponentManager when slots are unassigned.
		}
	}
}
