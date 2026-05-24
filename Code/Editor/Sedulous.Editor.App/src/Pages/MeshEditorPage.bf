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
/// Spawns one entity with a MeshComponent pointing at this resource.
/// The right panel exposes one preview-material picker per submesh
/// material slot - picks persist per-asset via `EditorContext.AssetCache`
/// so reopening restores the rig. Picks set the component's
/// `SetMaterialRef(slot, ref)`; empty slots fall back to the
/// component manager's default material.
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
	private EditorContext mEditorContext;

	private EntityHandle mPreviewEntity = .Invalid;
	// One slot per distinct material index referenced by submeshes;
	// see ComputeMaterialSlotCount for why this isn't `submeshes.Count`.
	private List<String> mMaterialUris = new .() ~ DeleteContainerAndItems!(_);
	private List<Label> mMaterialPathLabels = new .() ~ delete _;

	public this(StringView filePath, StringView uri, StaticMeshResource mesh,
		PreviewSceneHost host, EditorContext editorContext)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mMeshUri.Set(uri);
		mMesh = mesh;
		mHost = host;
		mEditorContext = editorContext;
		UpdateTitle();

		let slotCount = ComputeMaterialSlotCount(mMesh);
		for (int i = 0; i < slotCount; i++)
			mMaterialUris.Add(new String());

		SpawnMeshEntity();

		if (mMesh?.Mesh != null)
			mHost.FitToBounds(mMesh.Mesh.Bounds);

		RestoreFromCache();
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

	public StaticMeshResource Mesh => mMesh;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;
	public StringView MeshUri => mMeshUri;
	public EntityHandle PreviewEntity => mPreviewEntity;
	public int32 MaterialSlotCount => (int32)mMaterialUris.Count;

	public StringView GetMaterialUri(int32 slot)
	{
		if (slot < 0 || slot >= mMaterialUris.Count) return "";
		return mMaterialUris[slot];
	}

	public void RegisterMaterialLabel(int32 slot, Label pathLabel)
	{
		while (mMaterialPathLabels.Count <= slot)
			mMaterialPathLabels.Add(null);
		mMaterialPathLabels[slot] = pathLabel;
		RefreshMaterialLabel(slot);
	}

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

	// === Preview material pickers ===

	public void SetMaterialUri(int32 slot, StringView uri)
	{
		if (slot < 0 || slot >= mMaterialUris.Count) return;
		mMaterialUris[slot].Set(uri);
		ApplyMaterialsToPreviewEntity();
		RefreshMaterialLabel(slot);
		WriteCache(MaterialCacheKey(slot, .. scope String()), uri);
	}

	/// Counts distinct material slots a static mesh actually
	/// references via `SubMesh.materialIndex`. Slot indices are not
	/// guaranteed dense (the model importer may skip values) - so
	/// returning `max + 1` keeps the picker UI 1:1 with
	/// `MeshComponent.MaterialRefs[slot]`. Negative or absent data
	/// returns 0.
	public static int32 ComputeMaterialSlotCount(StaticMeshResource mesh)
	{
		if (mesh?.Mesh?.SubMeshes == null) return 0;
		int32 maxIdx = -1;
		for (let sm in mesh.Mesh.SubMeshes)
		{
			if (sm.materialIndex > maxIdx)
				maxIdx = sm.materialIndex;
		}
		return (maxIdx >= 0) ? maxIdx + 1 : 0;
	}

	// === Internals ===

	private void SpawnMeshEntity()
	{
		if (mMesh == null) return;

		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null) return;

		mPreviewEntity = scene.CreateEntity("PreviewMesh");
		scene.SetLocalTransform(mPreviewEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		let handle = meshMgr.CreateComponent(mPreviewEntity);
		if (let comp = meshMgr.Get(handle))
		{
			// ResourceRef ctor allocates its Path string; the setter
			// deep-copies internally, so the local must be Disposed to
			// free the temporary.
			var meshRef = ResourceRef(mMesh.Id, mMeshUri);
			defer meshRef.Dispose();
			comp.SetMeshRef(meshRef);
		}
	}

	/// Pushes the per-slot material URIs to the preview entity's
	/// MeshComponent. Empty URIs clear the slot (the component manager
	/// falls back to its default material).
	private void ApplyMaterialsToPreviewEntity()
	{
		if (!mPreviewEntity.IsAssigned) return;
		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null) return;
		let comp = meshMgr.GetForEntity(mPreviewEntity);
		if (comp == null) return;

		for (int32 i = 0; i < (int32)mMaterialUris.Count; i++)
		{
			let uri = StringView(mMaterialUris[i]);
			var matRef = ResourceRef(.Empty, uri);
			defer matRef.Dispose();
			comp.SetMaterialRef(i, matRef);
		}
	}

	private void RestoreFromCache()
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null) return;

		for (int32 i = 0; i < (int32)mMaterialUris.Count; i++)
		{
			let key = MaterialCacheKey(i, .. scope String());
			let cached = cache.Get(mMeshUri, key);
			if (cached.Length > 0)
				mMaterialUris[i].Set(cached);
		}

		ApplyMaterialsToPreviewEntity();
		for (int32 i = 0; i < (int32)mMaterialUris.Count; i++)
			RefreshMaterialLabel(i);
	}

	private void WriteCache(StringView key, StringView value)
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null) return;
		if (value.Length == 0)
			cache.Clear(mMeshUri, key);
		else
			cache.Set(mMeshUri, key, value);
	}

	private void RefreshMaterialLabel(int32 slot)
	{
		if (slot < 0 || slot >= mMaterialPathLabels.Count) return;
		let label = mMaterialPathLabels[slot];
		if (label == null) return;
		let uri = (slot < mMaterialUris.Count) ? StringView(mMaterialUris[slot]) : "";
		label.SetText(LabelText(uri));
	}

	private static StringView LabelText(StringView uri)
	{
		if (uri.Length == 0) return "(none)";
		let lastSlash = uri.LastIndexOf('/');
		return (lastSlash >= 0) ? uri.Substring(lastSlash + 1) : uri;
	}

	private static void MaterialCacheKey(int32 slot, String outKey)
	{
		outKey.AppendF("preview.material.{}", slot);
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}
}
