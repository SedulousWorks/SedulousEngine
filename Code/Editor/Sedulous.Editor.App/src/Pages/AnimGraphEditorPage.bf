using System;
using System.Collections;
using System.IO;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;
using Sedulous.VFS;

using internal Sedulous.Editor.App.Pages;

namespace Sedulous.Editor.App.Pages;

/// Editor page for animation graph (.animgraph) files.
/// Displays states as nodes, transitions as connections in a NodeGraphCanvas.
/// Side panel shows parameters and selected state/transition properties.
/// Bottom preview viewport shows a skinned mesh driven by the graph.
class AnimGraphEditorPage : IEditorPage, IResourceChangeListener
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private String mUri = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private bool mDirty;

	// Resource (ref-counted)
	private AnimationGraphResource mResource;

	// Editor context
	private EditorContext mEditorContext;

	// Graph reference (owned by resource)
	public AnimationGraph Graph => mResource?.Graph;

	// Active layer index (default = 0)
	private int32 mActiveLayerIndex;

	// Canvas reference (for rebuilding)
	private NodeGraphCanvas mCanvas;

	// Inspector property grid
	private PropertyGrid mPropertyGrid;

	// Selection state
	private Object mSelectedObject ~ { }; // Not owned - points into graph data

	// Owned objects for cleanup
	private List<Object> mOwnedObjects = new .() ~ { for (let obj in _) delete obj; delete _; };

	// Preview
	private PreviewSceneHost mHost ~ delete _;
	private EntityHandle mPreviewEntity;
	private bool mIsPlaying;

	public Event<delegate void(Object)> OnSelectionChanged ~ _.Dispose();

	public this(StringView filePath, StringView uri, AnimationGraphResource resource,
		PreviewSceneHost host, EditorContext context)
	{
		mFilePath.Set(filePath);
		mUri.Set(uri);
		mPageId.Set(filePath);
		mResource = resource;
		mHost = host;
		mEditorContext = context;
		UpdateTitle();

		mHost.FitToBounds(.(Vector3(-2, -1, -2), Vector3(2, 3, 2)));

		// Listen for hot-reload so we can rebuild UI after graph is reloaded in-place
		mEditorContext?.ResourceSystem?.AddChangeListener(this);
	}

	public ~this()
	{
		mEditorContext?.ResourceSystem?.RemoveChangeListener(this);

		if (mResource != null)
			mResource.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => ".animgraph";

	public AnimationGraphResource Resource => mResource;
	public int32 ActiveLayerIndex => mActiveLayerIndex;
	public NodeGraphCanvas Canvas => mCanvas;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;
	public bool IsPlaying => mIsPlaying;

	public void SetContentView(View view) { mContentView = view; }
	public void SetCanvas(NodeGraphCanvas canvas) { mCanvas = canvas; }
	public void SetPropertyGrid(PropertyGrid grid) { mPropertyGrid = grid; }

	public void AddOwnedObject(Object obj) { mOwnedObjects.Add(obj); }

	/// Switches to a different layer by index. Rebuilds the canvas.
	public void SetActiveLayer(int32 layerIndex)
	{
		if (Graph == null || layerIndex < 0 || layerIndex >= Graph.Layers.Count)
			return;
		if (mActiveLayerIndex == layerIndex)
			return;
		mActiveLayerIndex = layerIndex;
		SelectObject(null);
		RebuildGraph();
		OnLayerChanged();
	}

	/// Fires when the active layer changes or layer list changes.
	public Event<delegate void()> OnLayerChanged ~ _.Dispose();

	public void MarkDirty()
	{
		if (!mDirty)
		{
			mDirty = true;
			UpdateTitle();
		}
	}

	public void SelectObject(Object obj)
	{
		mSelectedObject = obj;
		OnSelectionChanged(obj);
	}

	// === Transport ===

	public void Play()
	{
		let comp = GetPreviewGraphComponent();
		if (comp != null)
			comp.Active = true;
		mIsPlaying = true;
	}

	public void Pause()
	{
		let comp = GetPreviewGraphComponent();
		if (comp != null)
			comp.Active = false;
		mIsPlaying = false;
	}

	public void Reset()
	{
		let graphComp = GetPreviewGraphComponent();
		if (graphComp?.GraphPlayer != null)
		{
			let layer = GetActiveLayer();
			let defaultIdx = layer != null ? layer.DefaultStateIndex : (int32)0;
			graphComp.GraphPlayer.ForceState(defaultIdx, mActiveLayerIndex);
		}
	}

	// === Preview entity ===

	/// Spawns the preview entity with SkinnedMesh + AnimationGraph components.
	/// Call after setting preview mesh ref if you want it visible immediately.
	public void SpawnPreviewEntity()
	{
		if (mHost == null) return;
		let scene = mHost.PreviewScene;
		if (scene == null) return;

		// Clean up existing if re-spawning
		if (mPreviewEntity != .Invalid)
		{
			scene.DestroyEntity(mPreviewEntity);
			mPreviewEntity = .Invalid;
		}

		mPreviewEntity = scene.CreateEntity("AnimGraphPreview");
		scene.SetLocalTransform(mPreviewEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		// Resolve clip refs so state nodes have actual AnimationClip pointers
		if (mResource != null && mEditorContext?.ResourceSystem != null)
			mResource.ResolveClips(mEditorContext.ResourceSystem);

		// AnimationGraphComponent - set the graph directly (it's in memory)
		let graphMgr = scene.GetModule<AnimationGraphComponentManager>();
		if (graphMgr != null)
		{
			let handle = graphMgr.CreateComponent(mPreviewEntity);
			if (let comp = graphMgr.Get(handle))
			{
				comp.Graph = mResource?.Graph;
				comp.Active = false; // Starts paused - Play activates
			}
		}

		// SkinnedMeshComponent - initially empty, user assigns preview mesh
		let meshMgr = scene.GetModule<SkinnedMeshComponentManager>();
		if (meshMgr != null)
			meshMgr.CreateComponent(mPreviewEntity);

		// Graph starts inactive - user presses Play to animate
		mIsPlaying = false;

		// Reapply the user's last preview rig picks for this asset.
		// Must run after the SkinnedMesh + AnimationGraph components
		// have been created since Apply* writes ref fields on them.
		RestoreFromCache();
	}

	// Cache keys used to persist preview rig assignments per-asset
	// (keyed by the .animgraph's URI) so closing + reopening restores
	// the user's mesh + skeleton picks. Same convention as the
	// SkinnedMeshEditorPage rig.
	private const String CacheKey_PreviewSkeleton = "preview.skeleton";
	private const String CacheKey_PreviewMesh = "preview.mesh";

	/// Sets the preview skeleton on the AnimationGraphComponent.
	/// Persists the pick through EditorContext.AssetCache so reopening
	/// the page restores it.
	public void SetPreviewSkeleton(ResourceRef skeletonRef)
	{
		ApplyPreviewSkeleton(skeletonRef);
		WriteCache(CacheKey_PreviewSkeleton, skeletonRef.HasPath ? skeletonRef.Path : "");
	}

	/// Sets the preview skinned mesh on the SkinnedMeshComponent.
	/// Persists the pick through EditorContext.AssetCache so reopening
	/// the page restores it.
	public void SetPreviewMesh(ResourceRef meshRef)
	{
		ApplyPreviewMesh(meshRef);
		WriteCache(CacheKey_PreviewMesh, meshRef.HasPath ? meshRef.Path : "");
	}

	private void ApplyPreviewSkeleton(ResourceRef skeletonRef)
	{
		let comp = GetPreviewGraphComponent();
		if (comp != null)
			comp.SetSkeletonRef(skeletonRef);
	}

	private void ApplyPreviewMesh(ResourceRef meshRef)
	{
		let comp = GetPreviewMeshComponent();
		if (comp != null)
			comp.SetMeshRef(meshRef);
	}

	/// Reads cached preview-rig picks for this .animgraph URI and
	/// applies them through the Apply* helpers (bypassing the cache
	/// write that the public Set* methods would re-issue). Called at
	/// the end of SpawnPreviewEntity so the preview components exist
	/// by the time we set refs on them.
	private void RestoreFromCache()
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null || mUri.Length == 0) return;

		let cachedSkel = cache.Get(mUri, CacheKey_PreviewSkeleton);
		if (cachedSkel.Length > 0)
		{
			var skelRef = ResourceRef(.Empty, cachedSkel);
			defer skelRef.Dispose();
			ApplyPreviewSkeleton(skelRef);
		}

		let cachedMesh = cache.Get(mUri, CacheKey_PreviewMesh);
		if (cachedMesh.Length > 0)
		{
			var meshRef = ResourceRef(.Empty, cachedMesh);
			defer meshRef.Dispose();
			ApplyPreviewMesh(meshRef);
		}
	}

	private void WriteCache(StringView key, StringView value)
	{
		let cache = mEditorContext?.AssetCache;
		if (cache == null || mUri.Length == 0) return;
		if (value.Length == 0)
			cache.Clear(mUri, key);
		else
			cache.Set(mUri, key, value);
	}

	internal AnimationGraphComponent GetPreviewGraphComponent()
	{
		if (mPreviewEntity == .Invalid || mHost?.PreviewScene == null) return null;
		let mgr = mHost.PreviewScene.GetModule<AnimationGraphComponentManager>();
		if (mgr == null) return null;
		return mgr.GetComponent(mPreviewEntity) as AnimationGraphComponent;
	}

	internal SkinnedMeshComponent GetPreviewMeshComponent()
	{
		if (mPreviewEntity == .Invalid || mHost?.PreviewScene == null) return null;
		let mgr = mHost.PreviewScene.GetModule<SkinnedMeshComponentManager>();
		if (mgr == null) return null;
		return mgr.GetComponent(mPreviewEntity) as SkinnedMeshComponent;
	}

	// === Save ===

	public void Save()
	{
		if (mFilePath.Length == 0 || mResource == null || mEditorContext == null) return;

		IWritableMount mount = null;
		let locator = scope String();
		if (!MountResolver.TryResolveAbsoluteWritable(mEditorContext.MountEntries, mFilePath, out mount, locator))
		{
			mEditorContext.Logger?.LogError("Save target is not inside any writable mount: {}", mFilePath);
			return;
		}

		let provider = mEditorContext.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditorContext.Logger?.LogError("No serializer provider available for anim graph save");
			return;
		}

		let memStream = scope MemoryStream();
		if (mResource.WriteToStream(memStream, provider) case .Err)
		{
			mEditorContext.Logger?.LogError("Animation graph serialization failed: {}", mFilePath);
			return;
		}
		memStream.Position = 0;

		if (mount.Save(locator, memStream) case .Err(let err))
		{
			mEditorContext.Logger?.LogError("Mount save failed for {}: {}", mFilePath, err);
			return;
		}

		mDirty = false;
		UpdateTitle();
		mEditorContext.Logger?.LogInformation("Animation graph saved: {}", mFilePath);
	}

	public void SaveAs(StringView path)
	{
		mFilePath.Set(path);
		mPageId.Set(path);
		Save();
		UpdateTitle();
	}

	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	// === IResourceChangeListener ===

	public void OnResourceReloaded(StringView uri, Type resourceType, IResource resource)
	{
		// Only care about our own graph resource being reloaded
		if (resource !== mResource)
			return;

		// Re-resolve clips (graph was cleared and repopulated in-place)
		if (mEditorContext?.ResourceSystem != null)
			mResource.ResolveClips(mEditorContext.ResourceSystem);

		// Clear selection (old state/transition pointers are dead)
		SelectObject(null);

		// Rebuild the node graph canvas
		RebuildGraph();

		// Rebuild param grid (old parameter objects were deleted)
		for (let obj in mOwnedObjects)
		{
			if (let pgRef = obj as AnimGraphEditorPageFactory.ParamGridRef)
			{
				AnimGraphEditorPageFactory.RebuildParameterGrid(pgRef.Grid, this);
				break;
			}
		}
	}

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	/// Rebuilds the node graph canvas from the current layer's states and transitions.
	public void RebuildGraph()
	{
		if (mCanvas == null || Graph == null) return;

		// Ensure at least one layer exists
		if (Graph.Layers.Count == 0)
			Graph.AddLayer(new AnimationLayer("Base Layer"));

		let layer = GetActiveLayer();
		if (layer == null) return;

		mCanvas.Clear();

		// Add "Any State" virtual node
		let anyNode = new NodeGraphNode();
		anyNode.Title.Set("Any State");
		anyNode.HeaderColor = .(100, 100, 110, 255);
		anyNode.IsDeletable = false;
		anyNode.UserHandle = -1;
		anyNode.Position = .(20, 20);
		let anyOut = new NodeGraphPort();
		anyOut.Direction = .Output;
		anyOut.Label.Set("");
		anyNode.OutputPorts.Add(anyOut);
		let anyIn = new NodeGraphPort();
		anyIn.Direction = .Input;
		anyIn.Label.Set("");
		anyNode.InputPorts.Add(anyIn);
		mCanvas.AddNode(anyNode);

		// Add state nodes (offset by 1 because Any State is index 0)
		for (int32 i = 0; i < layer.States.Count; i++)
		{
			let state = layer.States[i];
			let node = new NodeGraphNode();
			node.Title.Set(state.Name);
			node.UserHandle = i;
			node.HeaderColor = GetStateColor(state);
			node.Position = .(200 + (i % 3) * 220, 20 + (i / 3) * 140);

			// Subtitle based on node type
			if (state.Node != null)
			{
				if (state.Node is BlendTree1D)
					node.Subtitle.Set("BlendTree 1D");
				else if (state.Node is BlendTree2D)
					node.Subtitle.Set("BlendTree 2D");
				else if (state.Node is ClipStateNode)
					node.Subtitle.Set("Clip");
			}

			// All states get one input and one output (for transitions)
			let stateIn = new NodeGraphPort();
			stateIn.Direction = .Input;
			stateIn.Label.Set("In");
			node.InputPorts.Add(stateIn);

			let stateOut = new NodeGraphPort();
			stateOut.Direction = .Output;
			stateOut.Label.Set("Out");
			node.OutputPorts.Add(stateOut);

			// Mark default state
			if (i == layer.DefaultStateIndex)
				node.HeaderColor = .(100, 180, 80, 255); // Green for default

			mCanvas.AddNode(node);
		}

		// Add transitions as connections
		for (let trans in layer.Transitions)
		{
			// Source: -1 = Any State (canvas index 0), otherwise state index + 1
			let srcCanvasIdx = (trans.SourceStateIndex == -1) ? 0 : trans.SourceStateIndex + 1;
			let dstCanvasIdx = trans.DestStateIndex + 1;

			mCanvas.AddConnection(.() {
				SourceNodeIndex = (int32)srcCanvasIdx,
				SourcePortIndex = 0,
				DestNodeIndex = (int32)dstCanvasIdx,
				DestPortIndex = 0
			});
		}

		mCanvas.FrameAll();
	}

	public AnimationLayer GetActiveLayer()
	{
		if (Graph == null || mActiveLayerIndex >= Graph.Layers.Count) return null;
		return Graph.Layers[mActiveLayerIndex];
	}

	private Color32 GetStateColor(AnimationGraphState state)
	{
		if (state.Node is BlendTree1D)
			return .(180, 120, 60, 255);
		if (state.Node is BlendTree2D)
			return .(160, 80, 160, 255);
		return .(70, 130, 200, 255); // Clip or default
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
		if (mDirty)
			mTitle.Append("*");
	}
}
