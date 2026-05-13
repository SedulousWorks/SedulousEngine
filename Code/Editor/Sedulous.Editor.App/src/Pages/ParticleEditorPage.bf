namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Particles;
using Sedulous.Particles.Resources;
using Sedulous.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;

/// Editor page for previewing .particlefx files.
///
/// Spawns one entity with a ParticleComponent referencing this effect. AutoPlay
/// starts the simulation. Play/Pause/Restart/Stop controls reach into the
/// component's runtime instance.
class ParticleEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private ParticleEffectResource mEffectRes;
	private String mEffectUri = new .() ~ delete _;
	private PreviewSceneHost mHost ~ delete _;
	private EntityHandle mEntity;

	public this(StringView filePath, StringView uri, ParticleEffectResource effectRes, PreviewSceneHost host)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mEffectUri.Set(uri);
		mEffectRes = effectRes;
		mHost = host;
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
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public ParticleEffectResource EffectResource => mEffectRes;
	public PreviewSceneHost Host => mHost;

	public void SetContentView(View view) { mContentView = view; }

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
		let instance = ResolveInstance();
		if (instance?.Effect == null) return;
		instance.Reset();
		for (let system in instance.Effect.Systems)
			system.Emitter.IsEmitting = true;
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

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
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
