namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;

/// Editor page for previewing `.animation` files.
///
/// Mirrors the SkinnedMeshEditorPage preview-rig pattern in reverse:
/// the page is keyed on the clip, and the user picks a Mesh + Skeleton
/// to render it against. Picks are persisted per-asset through
/// `EditorContext.AssetCache`. When both picks are present, a preview
/// entity is spawned with `SkinnedMeshComponent + SkeletalAnimationComponent`
/// referencing this clip. Scrub/Play drive the component's player time
/// directly so the page owns the timeline (the runtime component's
/// `Playing` stays false).
class AnimationEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private AnimationClipResource mClipRes;
	private String mClipUri = new .() ~ delete _;
	private PreviewSceneHost mHost ~ delete _;
	private EditorContext mEditorContext;

	private EntityHandle mPreviewEntity = .Invalid;
	private String mMeshUri = new .() ~ delete _;
	private String mSkeletonUri = new .() ~ delete _;

	private float mScrubTime;
	private bool mIsPlaying;

	// Labels registered by the page builder. Refreshed in place when
	// picks change so the panel doesn't rebuild on every Pick.
	private Label mMeshPathLabel;
	private Label mSkeletonPathLabel;

	private const String CacheKey_Mesh = "preview.mesh";
	private const String CacheKey_Skeleton = "preview.skeleton";

	public this(StringView filePath, StringView uri, AnimationClipResource clipRes,
		PreviewSceneHost host, EditorContext editorContext)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mClipUri.Set(uri);
		mClipRes = clipRes;
		mHost = host;
		mEditorContext = editorContext;
		UpdateTitle();

		// Frame an arbitrary unit volume so the viewport isn't undefined
		// before a mesh is picked. Once a mesh is restored from cache
		// the viewport refits to its bounds.
		mHost.FitToBounds(.(Sedulous.Core.Mathematics.Vector3(-1, -1, -1),
			Sedulous.Core.Mathematics.Vector3(1, 1, 1)));

		// Spawn the entity skeleton up front (without a mesh ref) so
		// SetMeshUri / SetSkeletonUri only need to update components,
		// not branch on "do we have an entity yet".
		let scene = mHost.PreviewScene;
		mPreviewEntity = scene.CreateEntity("PreviewAnimation");
		scene.SetLocalTransform(mPreviewEntity,
			.() { Position = .Zero, Rotation = .Identity, Scale = .One });

		RestoreFromCache();
	}

	public ~this()
	{
		if (mClipRes != null)
			mClipRes.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public AnimationClipResource Clip => mClipRes;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;
	public StringView ClipUri => mClipUri;
	public StringView MeshUri => mMeshUri;
	public StringView SkeletonUri => mSkeletonUri;
	public EntityHandle PreviewEntity => mPreviewEntity;

	public float ScrubTime
	{
		get => mScrubTime;
		set
		{
			let dur = mClipRes?.Clip?.Duration ?? 0;
			mScrubTime = (dur > 0) ? Math.Clamp(value, 0, dur) : 0;
			DrivePlayerTime();
		}
	}
	public bool IsPlaying => mIsPlaying;

	public void SetContentView(View view) { mContentView = view; }

	public void RegisterStateLabels(Label meshPathLabel, Label skeletonPathLabel)
	{
		mMeshPathLabel = meshPathLabel;
		mSkeletonPathLabel = skeletonPathLabel;
		RefreshLabels();
	}

	public void Play()
	{
		// If we're sitting at (or past) the end of a non-looping clip,
		// rewind to 0 before resuming. Otherwise Update increments
		// mScrubTime past Duration on the next tick, clamps it back,
		// and immediately flips mIsPlaying to false - looks like Play
		// did nothing. DCC convention is "Play from end replays".
		let clip = mClipRes?.Clip;
		let dur = clip?.Duration ?? 0;
		if (dur > 0 && mScrubTime >= dur && !(clip?.IsLooping ?? false))
		{
			mScrubTime = 0;
			DrivePlayerTime();
		}
		mIsPlaying = true;
	}
	public void Pause() { mIsPlaying = false; }
	public void Stop()
	{
		mIsPlaying = false;
		mScrubTime = 0;
		DrivePlayerTime();
	}

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }

	public void Update(float deltaTime)
	{
		if (!mIsPlaying) return;
		let dur = mClipRes?.Clip?.Duration ?? 0;
		if (dur <= 0) return;

		mScrubTime += deltaTime;
		if (mClipRes.Clip.IsLooping)
			mScrubTime = mScrubTime - Math.Floor(mScrubTime / dur) * dur;
		else if (mScrubTime >= dur)
		{
			mScrubTime = dur;
			mIsPlaying = false;
		}

		DrivePlayerTime();
	}

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	// === Preview rig pickers ===

	public void SetMeshUri(StringView uri)
	{
		mMeshUri.Set(uri);
		ApplyToPreviewEntity();
		RefreshLabels();
		WriteCache(CacheKey_Mesh, uri);

		// Re-fit the camera to the new mesh's bounds when we can.
		// SkinnedMeshComponentManager resolves the mesh asynchronously,
		// so this is best-effort - if the resource isn't ready yet the
		// next render will still show it with the default framing.
		if (uri.Length > 0)
			TryRefitToMesh(uri);
	}

	public void SetSkeletonUri(StringView uri)
	{
		mSkeletonUri.Set(uri);
		ApplyToPreviewEntity();
		RefreshLabels();
		WriteCache(CacheKey_Skeleton, uri);
	}

	// === Internals ===

	/// Adds or updates SkinnedMeshComponent + SkeletalAnimationComponent
	/// on the preview entity. Both must be present (mesh URI + a
	/// resolvable skeleton, either the explicit pick or the mesh's
	/// SkeletonRef) for the animation to render. Removes the
	/// components when picks are cleared so the viewport blanks out
	/// rather than showing a stale rig.
	private void ApplyToPreviewEntity()
	{
		if (!mPreviewEntity.IsAssigned) return;
		let scene = mHost.PreviewScene;
		let meshMgr = scene.GetModule<SkinnedMeshComponentManager>();
		let animMgr = scene.GetModule<SkeletalAnimationComponentManager>();
		if (meshMgr == null || animMgr == null) return;

		let haveMesh = mMeshUri.Length > 0;
		if (!haveMesh)
		{
			// Tear down everything when the mesh pick is cleared. The
			// scene rig component will be re-added on the next pick.
			if (meshMgr.GetForEntity(mPreviewEntity) != null)
				meshMgr.DestroyComponentOnEntity(mPreviewEntity);
			if (animMgr.GetForEntity(mPreviewEntity) != null)
				animMgr.DestroyComponentOnEntity(mPreviewEntity);
			return;
		}

		// Mesh component: create or update.
		var meshComp = meshMgr.GetForEntity(mPreviewEntity);
		if (meshComp == null)
		{
			let handle = meshMgr.CreateComponent(mPreviewEntity);
			meshComp = meshMgr.Get(handle);
		}
		if (meshComp != null)
		{
			var meshRef = ResourceRef(.Empty, mMeshUri);
			defer meshRef.Dispose();
			meshComp.SetMeshRef(meshRef);
		}

		// Animation component: needs a skeleton URI (explicit pick or
		// nothing - the page can't read the picked mesh's SkeletonRef
		// without resolving the mesh resource, which is async).
		let skelUri = StringView(mSkeletonUri);
		if (skelUri.Length == 0)
		{
			// No skeleton picked yet. Leave the mesh in bind pose
			// (no SkeletalAnimationComponent) until the user picks one.
			if (animMgr.GetForEntity(mPreviewEntity) != null)
				animMgr.DestroyComponentOnEntity(mPreviewEntity);
			return;
		}

		var animComp = animMgr.GetForEntity(mPreviewEntity);
		if (animComp == null)
		{
			let handle = animMgr.CreateComponent(mPreviewEntity);
			animComp = animMgr.Get(handle);
		}
		if (animComp == null) return;

		var clipRef = ResourceRef(.Empty, mClipUri);
		defer clipRef.Dispose();
		animComp.SetClipRef(clipRef);

		var skelRef = ResourceRef(.Empty, skelUri);
		defer skelRef.Dispose();
		animComp.SetSkeletonRef(skelRef);

		// Page owns the timeline - keep the runtime player paused so
		// it doesn't advance time on its own. Scrub / Play push
		// through DrivePlayerTime.
		animComp.AutoPlay = true;
		animComp.Loop = mClipRes?.Clip?.IsLooping ?? false;
		animComp.Playing = false;
	}

	private void DrivePlayerTime()
	{
		if (!mPreviewEntity.IsAssigned) return;
		let scene = mHost.PreviewScene;
		let animMgr = scene.GetModule<SkeletalAnimationComponentManager>();
		let comp = animMgr?.GetForEntity(mPreviewEntity);
		if (comp == null) return;

		// Player is created lazily by the manager once the clip +
		// skeleton resources resolve. Until then the page just tracks
		// mScrubTime; the player picks up the current time on first
		// tick after creation through the same DrivePlayerTime path.
		if (comp.Player == null) return;
		comp.Player.CurrentTime = mScrubTime;
	}

	private void TryRefitToMesh(StringView meshUri)
	{
		let res = mEditorContext?.ResourceSystem;
		if (res == null) return;
		if (res.LoadResource<Sedulous.Geometry.Resources.SkinnedMeshResource>(meshUri) case .Ok(var handle))
		{
			// LoadResource returns a handle with +1 refcount. Release
			// it here - the SkinnedMeshComponent on the preview entity
			// holds its own reference through the ResourceRef path, so
			// the mesh stays alive after this returns.
			defer handle.Release();
			if (handle.Resource?.Mesh != null)
				mHost.FitToBounds(handle.Resource.Mesh.Bounds);
		}
	}

	private void RestoreFromCache()
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null) return;

		let cachedMesh = cache.Get(mClipUri, CacheKey_Mesh);
		if (cachedMesh.Length > 0) mMeshUri.Set(cachedMesh);

		let cachedSkel = cache.Get(mClipUri, CacheKey_Skeleton);
		if (cachedSkel.Length > 0) mSkeletonUri.Set(cachedSkel);

		ApplyToPreviewEntity();
		RefreshLabels();

		if (mMeshUri.Length > 0)
			TryRefitToMesh(mMeshUri);
	}

	private void WriteCache(StringView key, StringView value)
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null) return;
		if (value.Length == 0)
			cache.Clear(mClipUri, key);
		else
			cache.Set(mClipUri, key, value);
	}

	private void RefreshLabels()
	{
		if (mMeshPathLabel != null)
			mMeshPathLabel.SetText(LabelText(mMeshUri));
		if (mSkeletonPathLabel != null)
			mSkeletonPathLabel.SetText(LabelText(mSkeletonUri));
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
