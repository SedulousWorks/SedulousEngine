namespace Sedulous.Editor.App;

using System;
using System.Collections;
using System.IO;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.VFS;

/// Editor page for `.propanim` (PropertyAnimationClipResource) files.
///
/// Phase 1 scope: scaffolding only. The page loads the clip, can host a
/// `.scene` or `.prefab` as the preview source, lists the loaded entities,
/// lets the user pick one as the animation target, and exposes a scrub
/// slider that drives `PropertyAnimationPlayer.Evaluate` against the
/// target. The actual dopesheet / keyframe editing UI is Phase 2.
///
/// Preview lifecycle: the page owns a private temp scene via
/// `PreviewSceneHost`. Loading a `.scene` deserializes into it directly;
/// loading a `.prefab` spawns the prefab as a root entity. All edits
/// (component auto-add, evaluated property writes) are scoped to that
/// temp scene and discarded on page close. The on-disk source file is
/// never modified.
class PropAnimEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private bool mDirty;

	private PropertyAnimationClipResource mClipResource;
	private PreviewSceneHost mHost ~ delete _;
	private EditorContext mEditorContext;
	private ComponentTypeRegistry mTypeRegistry;

	// Preview source: path of the .scene or .prefab currently loaded
	// into the temp scene. Empty when nothing is loaded.
	private String mPreviewSourcePath = new .() ~ delete _;

	// Roots created when loading the preview source. Destroyed (and the
	// list cleared) on Unload, on Dispose, and when the preview source
	// is swapped.
	private List<EntityHandle> mPreviewRoots = new .() ~ delete _;

	// Currently-targeted animation entity inside the temp scene. Invalid
	// when nothing is picked. Setting this attaches a
	// `PropertyAnimationComponent` to the entity (auto-creating it if
	// absent) and wires it to the in-progress clip.
	private EntityHandle mTargetEntity = .Invalid;
	private bool mTargetAutoAddedComponent;

	// Phase 1 UI sentinels - referenced by the page-builder layer so
	// scrubbing the time slider, refreshing the entity list, and
	// changing the preview source can mutate the right pieces.
	public Event<delegate void(PropAnimEditorPage)> OnPreviewSourceChanged ~ _.Dispose();
	public Event<delegate void(PropAnimEditorPage)> OnTargetChanged ~ _.Dispose();
	public Event<delegate void(PropAnimEditorPage)> OnCurrentTimeChanged ~ _.Dispose();

	public this(StringView filePath, PropertyAnimationClipResource clip,
		PreviewSceneHost host, EditorContext editorContext,
		ComponentTypeRegistry typeRegistry)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mClipResource = clip;
		mHost = host;
		mEditorContext = editorContext;
		mTypeRegistry = typeRegistry;
		UpdateTitle();
	}

	public ~this()
	{
		// Deliberately minimal. EditorPageManager.Close() runs Dispose()
		// BEFORE deleting the page, which destroys mContentView (and
		// every UI view inside it, including the labels the page's
		// events have closures on). Firing OnPreviewSourceChanged /
		// OnTargetChanged from here would then call those handlers
		// against freed labels.
		//
		// All the cleanup that needs to happen still happens, just
		// through field destructors instead of explicit event-firing
		// calls: `~mHost` calls PreviewSceneHost.Dispose() which calls
		// SceneSubsystem.DestroyScene() (recursive destroy of every
		// entity in the temp scene, including spawned preview roots
		// and the auto-added PropertyAnimationComponent on the
		// target). `~_` on the events disposes their subscriber lists.
		if (mClipResource != null)
			mClipResource.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => ".propanim";

	public void SetContentView(View view) { mContentView = view; }

	// === Accessors used by the page builder ===

	public PropertyAnimationClipResource ClipResource => mClipResource;
	public PropertyAnimationClip Clip => mClipResource?.Clip;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;
	public StringView PreviewSourcePath => mPreviewSourcePath;
	public EntityHandle TargetEntity => mTargetEntity;
	public bool TargetAutoAddedComponent => mTargetAutoAddedComponent;
	public Span<EntityHandle> PreviewRoots => mPreviewRoots;

	public void MarkDirty()
	{
		if (mDirty) return;
		mDirty = true;
		UpdateTitle();
	}

	// === Preview source ===

	/// Loads `uri` (a `scheme://locator` reference to a `.scene` or
	/// `.prefab`) into the temp scene as the new preview source. Any
	/// previously-loaded preview is torn down first. The on-disk file
	/// is never modified.
	///
	/// URIs are what `AssetPickerDialog` hands back through its
	/// callback - the only caller of this method.
	public Result<void> LoadPreviewSource(StringView uri)
	{
		UnloadPreviewSource();

		let scene = mHost?.PreviewScene;
		if (scene == null || mEditorContext == null)
			return .Err;

		let isPrefab = uri.EndsWith(".prefab", .OrdinalIgnoreCase);
		let isScene = uri.EndsWith(".scene", .OrdinalIgnoreCase);
		if (!isPrefab && !isScene)
		{
			mEditorContext.Logger?.LogWarning("[PropAnim] preview source must be .scene or .prefab: {}", uri);
			return .Err;
		}

		// Split scheme://locator and look up the mount.
		let sep = uri.IndexOf("://");
		if (sep <= 0)
		{
			mEditorContext.Logger?.LogWarning("[PropAnim] preview source is not a URI: {}", uri);
			return .Err;
		}
		let scheme = uri.Substring(0, sep);
		let locator = scope String();
		locator.Append(uri.Substring(sep + 3));
		let mount = mEditorContext.ResourceSystem?.GetMount(scheme);
		if (mount == null)
		{
			mEditorContext.Logger?.LogWarning("[PropAnim] no mount registered for scheme '{}' (uri: {})", scheme, uri);
			return .Err;
		}

		// Snapshot existing roots so we know which ones the load added.
		// The temp scene already has the host's default light entity;
		// anything that appears beyond what was here belongs to the
		// loaded preview source.
		let preExisting = scope HashSet<EntityHandle>();
		{
			var cur = scene.FirstRoot;
			while (cur.IsAssigned)
			{
				preExisting.Add(cur);
				cur = scene.GetNextSibling(cur);
			}
		}

		if (isPrefab)
		{
			var prefabRef = ResourceRef(.Empty, uri);
			defer prefabRef.Dispose();
			if (PrefabSpawner.Spawn(scene, prefabRef, .Empty, .Invalid, mTypeRegistry,
				mEditorContext.ResourceSystem?.SerializerProvider,
				mEditorContext.ResourceSystem) case .Ok(let result))
			{
				if (result.GuidMap != null)
					delete result.GuidMap;
			}
			else
			{
				mEditorContext.Logger?.LogWarning("[PropAnim] PrefabSpawner.Spawn failed for {}", uri);
				return .Err;
			}
		}
		else
		{
			// .scene path: load via SceneSerializer into the temp scene.
			let text = scope String();
			if (!ReadTextFromMount(mount, locator, text))
				return .Err;

			let provider = mEditorContext.ResourceSystem?.SerializerProvider;
			let reader = provider?.CreateReader(text);
			if (reader == null) return .Err;
			defer delete reader;

			let sceneSerializer = scope SceneSerializer(mTypeRegistry, provider,
				mEditorContext.ResourceSystem);
			let tempResource = scope SceneResource();
			tempResource.Scene = scene;
			tempResource.SceneSerializer = sceneSerializer;
			tempResource.Serialize(reader);
		}

		// Collect the newly-added roots so we can tear them down later.
		var cur = scene.FirstRoot;
		while (cur.IsAssigned)
		{
			if (!preExisting.Contains(cur))
				mPreviewRoots.Add(cur);
			cur = scene.GetNextSibling(cur);
		}

		mPreviewSourcePath.Set(uri);
		OnPreviewSourceChanged(this);

		// Try to frame the camera on the new content. Best-effort - the
		// host's FitToBounds wants a valid AABB and we don't have one
		// here without walking entities; future Phase 2 work can call
		// FitToBounds explicitly.
		return .Ok;
	}

	/// Tears down the currently-loaded preview source. Safe no-op when
	/// nothing is loaded.
	public void UnloadPreviewSource()
	{
		// Drop the animation target first, since it may live inside the
		// roots we're about to destroy.
		ClearTarget();

		let scene = mHost?.PreviewScene;
		if (scene != null)
		{
			for (let root in mPreviewRoots)
			{
				if (root.IsAssigned && scene.IsValid(root))
					scene.DestroyEntity(root);
			}
		}
		mPreviewRoots.Clear();
		mPreviewSourcePath.Clear();
		OnPreviewSourceChanged(this);
	}

	// === Animation target ===

	/// Picks `entity` (which must live in the temp scene) as the
	/// animation target. Auto-adds a `PropertyAnimationComponent` if
	/// the entity doesn't already have one, wires it to our in-progress
	/// clip, and remembers whether we had to add the component so the
	/// UI can surface that to the user.
	public void SetTarget(EntityHandle entity)
	{
		// Detach the previous target's component reference so the
		// previous entity stops getting animated.
		ClearTarget();

		let scene = mHost?.PreviewScene;
		if (scene == null || !entity.IsAssigned || !scene.IsValid(entity))
			return;

		let animMgr = scene.GetModule<PropertyAnimationComponentManager>();
		if (animMgr == null) return;

		var comp = animMgr.GetForEntity(entity);
		if (comp == null)
		{
			let handle = animMgr.CreateComponent(entity);
			comp = animMgr.Get(handle);
			mTargetAutoAddedComponent = (comp != null);
		}
		else
		{
			mTargetAutoAddedComponent = false;
		}

		if (comp == null) return;

		// Point the component at our editing clip. SetClipRef stores
		// the ref; the manager's ResolveResources phase next tick
		// constructs the PropertyAnimationPlayer.
		if (mClipResource != null)
		{
			var @ref = ResourceRef(mClipResource.Id, mFilePath);
			comp.SetClipRef(@ref);
			@ref.Dispose();
		}

		// Default to paused so the slider drives time directly. Play
		// flips this when the user wants real-time playback.
		comp.Playing = false;
		comp.AutoPlay = false;

		mTargetEntity = entity;
		OnTargetChanged(this);
	}

	private void ClearTarget()
	{
		if (!mTargetEntity.IsAssigned)
		{
			mTargetAutoAddedComponent = false;
			return;
		}

		let scene = mHost?.PreviewScene;
		if (scene != null && scene.IsValid(mTargetEntity))
		{
			let animMgr = scene.GetModule<PropertyAnimationComponentManager>();
			if (animMgr != null)
			{
				if (let comp = animMgr.GetForEntity(mTargetEntity))
				{
					var emptyRef = ResourceRef();
					comp.SetClipRef(emptyRef);
					emptyRef.Dispose();
					comp.Playing = false;
				}
			}
		}

		mTargetEntity = .Invalid;
		mTargetAutoAddedComponent = false;
		OnTargetChanged(this);
	}

	// === Scrub / play ===

	public float CurrentTime
	{
		get
		{
			let player = GetTargetPlayer();
			return (player != null) ? player.CurrentTime : 0.0f;
		}
		set
		{
			let player = GetTargetPlayer();
			if (player == null) return;

			let clip = mClipResource?.Clip;
			let duration = (clip != null) ? clip.Duration : 0.0f;
			let clamped = (duration > 0) ? Math.Clamp(value, 0.0f, duration) : 0.0f;
			if (player.CurrentTime == clamped) return;
			player.CurrentTime = clamped;
			player.Evaluate();
			OnCurrentTimeChanged(this);
		}
	}

	public bool IsPlaying
	{
		get
		{
			let player = GetTargetPlayer();
			return player != null && player.State == .Playing;
		}
	}

	public void Play()
	{
		let scene = mHost?.PreviewScene;
		let player = GetTargetPlayer();
		if (scene == null || player == null) return;

		// Resume from current time rather than restart. If the player
		// hasn't seen a clip yet (just-attached component, before the
		// manager's first tick), Resume() is a no-op - Play(clip)
		// kicks it off explicitly.
		if (player.Clip == null && mClipResource?.Clip != null)
			player.Play(mClipResource.Clip);
		else
			player.Resume();

		let comp = GetTargetComponent();
		if (comp != null) comp.Playing = true;
	}

	public void Stop()
	{
		let player = GetTargetPlayer();
		if (player == null) return;
		player.Pause();

		let comp = GetTargetComponent();
		if (comp != null) comp.Playing = false;
	}

	private PropertyAnimationComponent GetTargetComponent()
	{
		let scene = mHost?.PreviewScene;
		if (scene == null || !mTargetEntity.IsAssigned) return null;
		let mgr = scene.GetModule<PropertyAnimationComponentManager>();
		return mgr?.GetForEntity(mTargetEntity);
	}

	private PropertyAnimationPlayer GetTargetPlayer()
	{
		return GetTargetComponent()?.Player;
	}

	// === Save ===

	public void Save()
	{
		if (mFilePath.Length == 0 || mClipResource == null || mEditorContext == null) return;

		IWritableMount mount = null;
		let locator = scope String();
		if (!MountResolver.TryResolveAbsoluteWritable(mEditorContext.MountEntries, mFilePath, out mount, locator))
		{
			mEditorContext.Logger?.LogError("[PropAnim] save target not inside any writable mount: {}", mFilePath);
			return;
		}

		let provider = mEditorContext.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditorContext.Logger?.LogError("[PropAnim] no serializer provider available");
			return;
		}

		let memStream = scope MemoryStream();
		if (mClipResource.WriteToStream(memStream, provider) case .Err)
		{
			mEditorContext.Logger?.LogError("[PropAnim] serialization failed: {}", mFilePath);
			return;
		}
		memStream.Position = 0;

		if (mount.Save(locator, memStream) case .Err(let err))
		{
			mEditorContext.Logger?.LogError("[PropAnim] mount save failed for {}: {}", mFilePath, err);
			return;
		}

		mDirty = false;
		UpdateTitle();
		mEditorContext.Logger?.LogInformation("[PropAnim] saved: {}", mFilePath);
	}

	public void SaveAs(StringView path)
	{
		mFilePath.Set(path);
		mPageId.Set(path);
		Save();
	}

	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	// === Helpers ===

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
		if (mDirty) mTitle.Append("*");
	}

	private static bool ReadTextFromMount(IMount mount, StringView locator, String outText)
	{
		let openResult = mount.Open(locator);
		if (openResult case .Err) return false;
		let stream = openResult.Value;
		defer delete stream;

		let len = (int)stream.Length;
		if (len <= 0) return true;

		let buf = scope uint8[len];
		switch (stream.TryRead(.(&buf[0], len)))
		{
		case .Ok(let n):
			if (n != len) return false;
			outText.Append((char8*)&buf[0], len);
			return true;
		case .Err:
			return false;
		}
	}
}
