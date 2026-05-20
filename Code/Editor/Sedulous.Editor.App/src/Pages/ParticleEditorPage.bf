namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Particles;
using Sedulous.Particles.Resources;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.VFS;

/// Editor page for authoring and previewing .particlefx files.
///
/// Spawns one entity with a ParticleComponent referencing this effect. The page
/// owns selection of a node within the effect (system / emitter / initializer /
/// behavior) and fires OnSelectionChanged so the property grid can rebuild.
/// Edits run through MarkDirty + RestartIfSpawnTime to keep the preview honest.
class ParticleEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;
	private bool mDirty;

	private ParticleEffectResource mEffectRes;
	private String mEffectUri = new .() ~ delete _;
	private PreviewSceneHost mHost ~ delete _;
	private EntityHandle mEntity;

	private EditorContext mEditorContext;

	/// Auxiliary objects (adapters, controllers) whose lifetime tracks the page.
	private List<Object> mOwnedObjects = new .() ~ { for (let obj in _) delete obj; delete _; };

	/// Tree adapter (non-owning - lives in mOwnedObjects). Set by the factory
	/// so RestartIfSpawnTime can refresh the tree when a system's display
	/// name changes.
	private ParticleEffectTreeAdapter mTreeAdapter;

	/// Currently inspected node. Owned by mEffectRes.Effect - do not delete.
	private Object mSelectedObject;

	/// Fires when the inspected node changes. Payload is the new selection
	/// (may be null when clearing the inspector e.g. before a destructive
	/// mutation).
	public Event<delegate void(Object)> OnSelectionChanged ~ _.Dispose();

	public this(StringView filePath, StringView uri, ParticleEffectResource effectRes,
		PreviewSceneHost host, EditorContext editorContext = null)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mEffectUri.Set(uri);
		mEffectRes = effectRes;
		mHost = host;
		mEditorContext = editorContext;
		UpdateTitle();

		SpawnEffectEntity();

		// Particle bounds change at runtime - use a fixed roomy box so the
		// camera doesn't snap as particles spawn/die.
		mHost.FitToBounds(.(Vector3(-5, -5, -5), Vector3(5, 5, 5)));
	}

	public ~this()
	{
		if (mEffectRes != null)
			mEffectRes.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => ".particlefx";

	public ParticleEffectResource EffectResource => mEffectRes;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;
	public Object SelectedObject => mSelectedObject;

	public void SetContentView(View view) { mContentView = view; }

	/// Register an auxiliary object for deletion when the page is disposed.
	/// Used by the factory to keep tree adapters etc. alive for the page's
	/// lifetime without leaking when the content view is torn down.
	public void AddOwnedObject(Object obj)
	{
		if (obj != null) mOwnedObjects.Add(obj);
	}

	/// Wires the factory-built tree adapter so the page can refresh its
	/// labels after inspector edits that change the visible name.
	public void SetTreeAdapter(ParticleEffectTreeAdapter adapter)
	{
		mTreeAdapter = adapter;
	}

	public void Play()
	{
		let instance = ResolveInstance();
		if (instance?.Effect == null) return;
		for (let system in instance.Effect.Systems)
			system.Emitter.IsEmitting = true;
	}

	public void Stop()
	{
		let instance = ResolveInstance();
		instance?.Stop();
	}

	public void Restart()
	{
		// Clear alive particles and reset emission accumulators, but do not
		// touch each system's IsEmitting flag - that's authored state and a
		// system the user disabled should stay disabled across restarts.
		// Use Play() if you want to force-resume emission on all systems.
		let instance = ResolveInstance();
		instance?.Reset();
	}

	public void Save()
	{
		if (mFilePath.Length == 0 || mEffectRes == null || mEditorContext == null) return;

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
			mEditorContext.Logger?.LogError("No serializer provider available for particle effect save");
			return;
		}

		// Serialize into a memory stream, then hand the bytes to the mount.
		let memStream = scope MemoryStream();
		if (mEffectRes.WriteToStream(memStream, provider) case .Err)
		{
			mEditorContext.Logger?.LogError("Particle effect serialization failed: {}", mFilePath);
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
		mEditorContext.Logger?.LogInformation("Particle effect saved: {}", mFilePath);
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

	public void Dispose()
	{
		delete mContentView;
		mContentView = null;
	}

	// === Selection ===

	/// Set the currently inspected node. Pass null to clear (used before
	/// destructive mutations so property editors don't dangle).
	public void SelectObject(Object obj)
	{
		mSelectedObject = obj;
		OnSelectionChanged(obj);
	}

	// === Dirty / restart ===

	/// Mark the effect as dirty and update the title. Editors call this from
	/// their OnEditEnd callbacks.
	public void MarkDirty()
	{
		if (!mDirty)
		{
			mDirty = true;
			UpdateTitle();
		}
	}

	/// Restart the live preview if `owner` represents a spawn-time property
	/// (emitter shape, initializers, anything that only takes effect at
	/// spawn). Behaviors and curves pick up changes on the next sim tick,
	/// so they no-op here. v1: always restart to keep the preview honest;
	/// the spawn-time/runtime distinction will be re-introduced once it
	/// matters perceptually.
	public void RestartIfSpawnTime(Object owner)
	{
		Restart();

		// Editing a ParticleSystem may change its visible label (Name field),
		// so rebuild the tree to refresh it. Rebuild invalidates node IDs;
		// re-select by target identity so the inspector stays on the same
		// object. Other owner kinds don't drive a tree label.
		//
		// This runs from inside a PropertyEditor's change callback (e.g. a
		// ComboBox selection on the RenderMode enum). Rebuilding the tree
		// re-fires selection -> the property grid tears down and recreates
		// every editor, including the one whose event we're still unwinding
		// from -> use-after-free. Defer via the UI mutation queue so it runs
		// at the next safe sync point, after input dispatch completes.
		if (mTreeAdapter != null && (owner is ParticleSystem || owner is ParticleEffect))
		{
			let adapter = mTreeAdapter;
			let target = owner;
			let ctx = mContentView?.Context;
			if (ctx != null)
			{
				ctx.MutationQueue.QueueAction(new () => {
					adapter.Rebuild();
					let id = adapter.FindNodeForTarget(target);
					if (id >= 0)
						adapter.SelectNode(id);
				});
			}
		}
	}

	/// Whether the given owner represents a spawn-time-only property.
	/// Reserved for the v2 restart-discrimination logic - currently unused
	/// because RestartIfSpawnTime always restarts.
	public static bool IsSpawnTimeOwner(Object o) =>
		o is ParticleSystem || o is ParticleEmitter || o is ParticleInitializer;

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
		if (mDirty)
			mTitle.Append("*");
	}

	private ParticleEffectInstance ResolveInstance()
	{
		if (mEntity == .Invalid) return null;
		let scene = mHost.PreviewScene;
		let mgr = scene.GetModule<ParticleComponentManager>();
		if (mgr == null) return null;

		let comp = mgr.GetComponent(mEntity) as ParticleComponent;
		return comp?.Instance;
	}

	private void SpawnEffectEntity()
	{
		if (mEffectRes == null) return;

		let scene = mHost.PreviewScene;
		let mgr = scene.GetModule<ParticleComponentManager>();
		if (mgr == null) return;

		mEntity = scene.CreateEntity("ParticlePreview");
		scene.SetLocalTransform(mEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });

		let handle = mgr.CreateComponent(mEntity);
		if (let comp = mgr.Get(handle))
		{
			// ResourceRef ctor allocates its Path string; SetEffectRef deep-copies
			// internally, so the local must be Disposed to free the temporary.
			var effectRef = ResourceRef(mEffectRes.Id, mEffectUri);
			defer effectRef.Dispose();
			comp.SetEffectRef(effectRef);
			comp.AutoPlay = true;
		}
	}
}
