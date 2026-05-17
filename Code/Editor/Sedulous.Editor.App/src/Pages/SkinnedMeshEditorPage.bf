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

/// Editor page for previewing .skinnedmesh files in a 3D viewport.
///
/// Mirrors MeshEditorPage but for SkinnedMeshResource: spawns one entity
/// with a SkinnedMeshComponent pointing at this resource (bind pose, since
/// no animation is bound in the preview). Info panel on the right shows
/// vertex/triangle/submesh counts, bounds, and the skeleton ref.
class SkinnedMeshEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private SkinnedMeshResource mMesh;
	private String mMeshUri = new .() ~ delete _;
	private PreviewSceneHost mHost ~ delete _;

	public this(StringView filePath, StringView uri, SkinnedMeshResource mesh, PreviewSceneHost host)
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
	public StringView SaveFileExtension => "";  // read-only preview

	public SkinnedMeshResource Mesh => mMesh;
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
		let meshMgr = scene.GetModule<SkinnedMeshComponentManager>();
		if (meshMgr == null) return;

		let entity = scene.CreateEntity("PreviewSkinnedMesh");
		scene.SetLocalTransform(entity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		let handle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(handle))
		{
			// ResourceRef ctor allocates its Path string; the setter deep-copies
			// internally, so the local must be Disposed to free the temporary.
			var meshRef = ResourceRef(mMesh.Id, mMeshUri);
			defer meshRef.Dispose();
			comp.SetMeshRef(meshRef);
			// Materials default through SkinnedMeshComponentManager when slots
			// are unassigned. No animation bound -> renders the bind pose.
		}
	}
}
