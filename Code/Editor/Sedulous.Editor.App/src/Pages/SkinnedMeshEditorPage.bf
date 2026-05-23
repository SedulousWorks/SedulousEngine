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
using Sedulous.Engine.Animation;

/// Editor page for previewing .skinnedmesh files in a 3D viewport.
///
/// Spawns one entity with a SkinnedMeshComponent pointing at this
/// resource. When the user picks a preview Clip + Skeleton from the
/// info panel, a SkeletalAnimationComponent is added to the same
/// entity so the mesh animates in the preview. Picks are persisted
/// per-asset through `EditorContext.AssetCache`, so reopening the page
/// restores the last preview rig.
///
/// The mesh's own `SkeletonRef` is used as the default skeleton pick
/// (most cases - the user only overrides for retargeting or to debug a
/// mesh whose embedded ref is wrong). Bind pose renders when no clip
/// is picked.
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
	private EditorContext mEditorContext;

	private EntityHandle mPreviewEntity = .Invalid;
	private String mClipUri = new .() ~ delete _;
	private String mSkeletonUri = new .() ~ delete _;
	// One slot per submesh; empty string means "use the
	// SkinnedMeshComponentManager's default". Sized to the mesh's
	// submesh count at construction so picker rows have a stable
	// 1:1 index mapping.
	private List<String> mMaterialUris = new .() ~ DeleteContainerAndItems!(_);

	// Labels surfaced by the info panel; the page updates them when the
	// user picks new assets so the readout reflects the current state
	// without rebuilding the whole info panel.
	private Label mClipPathLabel;
	private Label mSkeletonPathLabel;
	private List<Label> mMaterialPathLabels = new .() ~ delete _;

	// Cache keys are namespaced under "preview." so per-asset state can
	// coexist with future preview / layout / inspector entries on the
	// same asset URI without colliding.
	private const String CacheKey_Clip = "preview.clip";
	private const String CacheKey_Skeleton = "preview.skeleton";
	// Material slot keys are "preview.material.<slot>" - one per
	// submesh. See MaterialCacheKey() for the formatter.

	public this(StringView filePath, StringView uri, SkinnedMeshResource mesh,
		PreviewSceneHost host, EditorContext editorContext)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mMeshUri.Set(uri);
		mMesh = mesh;
		mHost = host;
		mEditorContext = editorContext;
		UpdateTitle();

		// Pre-allocate one material slot per submesh - the picker UI
		// indexes into this list and ApplyToPreviewEntity walks all
		// slots when pushing refs to the component.
		let submeshCount = (mMesh?.Mesh?.SubMeshes?.Count) ?? 0;
		for (int i = 0; i < submeshCount; i++)
			mMaterialUris.Add(new String());

		SpawnMeshEntity();

		if (mMesh?.Mesh != null)
			mHost.FitToBounds(mMesh.Mesh.Bounds);

		// Restore previous preview picks. The skeleton default falls
		// back to the mesh's embedded ref if the cache has nothing.
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

	public SkinnedMeshResource Mesh => mMesh;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;
	public StringView MeshUri => mMeshUri;
	public EntityHandle PreviewEntity => mPreviewEntity;
	public StringView ClipUri => mClipUri;
	public StringView SkeletonUri => mSkeletonUri;

	public void SetContentView(View view) { mContentView = view; }

	/// Used by the page builder to register the path labels so the page
	/// can update them when picks change without rebuilding the panel.
	public void RegisterStateLabels(Label clipPathLabel, Label skeletonPathLabel)
	{
		mClipPathLabel = clipPathLabel;
		mSkeletonPathLabel = skeletonPathLabel;
		RefreshLabels();
	}

	public int32 MaterialSlotCount => (int32)mMaterialUris.Count;
	public StringView GetMaterialUri(int32 slot)
	{
		if (slot < 0 || slot >= mMaterialUris.Count) return "";
		return mMaterialUris[slot];
	}

	/// Registers the material path label for slot `slot` (called per
	/// row by the page builder, matching the order rows are emitted).
	public void RegisterMaterialLabel(int32 slot, Label pathLabel)
	{
		while (mMaterialPathLabels.Count <= slot)
			mMaterialPathLabels.Add(null);
		mMaterialPathLabels[slot] = pathLabel;
		RefreshMaterialLabel(slot);
	}

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

	// === Preview rig pickers ===

	/// Sets the preview animation clip by URI. Empty string clears the
	/// pick. Persists through EditorContext.AssetCache so it's restored
	/// next session.
	public void SetClipUri(StringView uri)
	{
		mClipUri.Set(uri);
		ApplyToPreviewEntity();
		RefreshLabels();
		WriteCache(CacheKey_Clip, uri);
	}

	/// Sets the preview skeleton by URI. Empty string falls back to the
	/// mesh's own SkeletonRef when applying.
	public void SetSkeletonUri(StringView uri)
	{
		mSkeletonUri.Set(uri);
		ApplyToPreviewEntity();
		RefreshLabels();
		WriteCache(CacheKey_Skeleton, uri);
	}

	/// Sets the material URI for submesh `slot`. Empty string clears
	/// the pick (component falls back to the manager's default
	/// material).
	public void SetMaterialUri(int32 slot, StringView uri)
	{
		if (slot < 0 || slot >= mMaterialUris.Count) return;
		mMaterialUris[slot].Set(uri);
		ApplyMaterialsToPreviewEntity();
		RefreshMaterialLabel(slot);
		WriteCache(MaterialCacheKey(slot, .. scope String()), uri);
	}

	// === Internals ===

	private void SpawnMeshEntity()
	{
		if (mMesh == null) return;

		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<SkinnedMeshComponentManager>();
		if (meshMgr == null) return;

		mPreviewEntity = scene.CreateEntity("PreviewSkinnedMesh");
		scene.SetLocalTransform(mPreviewEntity,
			.() { Position = .Zero, Rotation = .Identity, Scale = .One });

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
	/// SkinnedMeshComponent. Empty URIs clear the slot (component
	/// resolver falls back to its default material).
	private void ApplyMaterialsToPreviewEntity()
	{
		if (!mPreviewEntity.IsAssigned) return;
		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<SkinnedMeshComponentManager>();
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

	/// Adds or updates a `SkeletalAnimationComponent` on the preview
	/// entity to drive the mesh. Resolves the effective skeleton URI
	/// (explicit pick, else mesh's `SkeletonRef`); leaves the existing
	/// component alone if no clip or skeleton is available so the mesh
	/// stays in bind pose.
	private void ApplyToPreviewEntity()
	{
		if (!mPreviewEntity.IsAssigned) return;
		let scene = mHost.PreviewScene;
		let animMgr = scene.GetModule<SkeletalAnimationComponentManager>();
		if (animMgr == null) return;

		let effectiveSkeleton = GetEffectiveSkeletonUri(.. scope String());
		let haveClip = mClipUri.Length > 0;
		let haveSkeleton = effectiveSkeleton.Length > 0;

		if (!haveClip || !haveSkeleton)
		{
			// Tear down any prior component so the mesh resets to bind
			// pose when the user clears a pick.
			if (animMgr.GetForEntity(mPreviewEntity) != null)
				animMgr.DestroyComponentOnEntity(mPreviewEntity);
			return;
		}

		var comp = animMgr.GetForEntity(mPreviewEntity);
		if (comp == null)
		{
			let handle = animMgr.CreateComponent(mPreviewEntity);
			comp = animMgr.Get(handle);
		}
		if (comp == null) return;

		var clipRef = ResourceRef(.Empty, mClipUri);
		defer clipRef.Dispose();
		comp.SetClipRef(clipRef);

		var skelRef = ResourceRef(.Empty, effectiveSkeleton);
		defer skelRef.Dispose();
		comp.SetSkeletonRef(skelRef);

		comp.AutoPlay = true;
		comp.Loop = true;
	}

	private void GetEffectiveSkeletonUri(String outUri)
	{
		if (mSkeletonUri.Length > 0)
		{
			outUri.Set(mSkeletonUri);
			return;
		}
		// Fall back to the mesh's embedded ref so picking a mesh
		// "just works" without forcing a skeleton pick when the mesh
		// already knows its rig.
		if (mMesh != null && mMesh.SkeletonRef.HasPath)
			outUri.Set(mMesh.SkeletonRef.Path);
	}

	private void RestoreFromCache()
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null) return;

		let cachedClip = cache.Get(mMeshUri, CacheKey_Clip);
		if (cachedClip.Length > 0)
			mClipUri.Set(cachedClip);

		let cachedSkel = cache.Get(mMeshUri, CacheKey_Skeleton);
		if (cachedSkel.Length > 0)
			mSkeletonUri.Set(cachedSkel);

		for (int32 i = 0; i < (int32)mMaterialUris.Count; i++)
		{
			let key = MaterialCacheKey(i, .. scope String());
			let cached = cache.Get(mMeshUri, key);
			if (cached.Length > 0)
				mMaterialUris[i].Set(cached);
		}

		ApplyToPreviewEntity();
		ApplyMaterialsToPreviewEntity();
		RefreshLabels();
	}

	private static void MaterialCacheKey(int32 slot, String outKey)
	{
		outKey.AppendF("preview.material.{}", slot);
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

	private void RefreshLabels()
	{
		if (mClipPathLabel != null)
			mClipPathLabel.SetText(LabelText(mClipUri));
		if (mSkeletonPathLabel != null)
		{
			let displayUri = (mSkeletonUri.Length > 0)
				? StringView(mSkeletonUri)
				: ((mMesh?.SkeletonRef.HasPath ?? false) ? mMesh.SkeletonRef.Path : "");
			mSkeletonPathLabel.SetText(LabelText(displayUri));
		}
		for (int32 i = 0; i < (int32)mMaterialPathLabels.Count; i++)
			RefreshMaterialLabel(i);
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

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}
}
