namespace Sedulous.Editor.App;

using System;
using System.IO;
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
using Sedulous.VFS;

/// Editor page for previewing + editing `.material` files.
///
/// Spawns a unit sphere with the material applied so all surface
/// properties (base color, normal, roughness, metallic, ...) become
/// visible. The right panel exposes editors for the material's
/// per-shader uniform properties, texture refs, sampler settings, and
/// pipeline config; any change marks the page dirty and bumps the
/// resource generation so the preview viewport updates live (the
/// render resource resolver re-uploads the MaterialInstance on the
/// next frame). Save writes through the originating writable mount;
/// hot-reload then re-applies the same data path so any other open
/// view referencing the same material picks up the change.
class MaterialEditorPage : IEditorPage, IEditableAssetPage
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
	private EditorContext mEditorContext;
	private bool mDirty;

	// Cached ref handed out by AssetRef (IEditableAssetPage). Allocated
	// once at construction so callers don't have to Dispose a fresh
	// String per access. Disposed with the page.
	private ResourceRef mAssetRef ~ _.Dispose();

	// Strings the per-property editor closures capture by value. The
	// closures live on heap-allocated event delegates and outlive the
	// factory's build methods - `scope` / `scope::` allocations would
	// dangle once BuildMaterialView returns. The page owns them; they
	// stay valid for the page's lifetime.
	private List<String> mOwnedStrings = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView filePath, StringView materialUri, MaterialResource material,
		StaticMeshResource sphereMesh, StringView sphereUri, PreviewSceneHost host,
		EditorContext editorContext)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mMaterialUri.Set(materialUri);
		mMaterial = material;
		mSphereMesh = sphereMesh;
		mHost = host;
		mEditorContext = editorContext;
		mAssetRef = ResourceRef((material != null) ? material.Id : .Empty, materialUri);
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
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => ".material";

	public MaterialResource Material => mMaterial;
	public PreviewSceneHost Host => mHost;
	public EditorContext EditorContext => mEditorContext;

	// === IEditableAssetPage ===
	public readonly ref ResourceRef AssetRef => ref mAssetRef;

	public void SetContentView(View view) { mContentView = view; }

	/// Called by editor controls when the user mutates a property,
	/// texture ref, sampler, or pipeline field. Marks the page dirty
	/// and bumps `Resource.Generation` so `RenderResourceResolver`
	/// rebuilds the `MaterialInstance` on the preview entity next
	/// render - that's the live-feedback path.
	/// Hands the page a string to keep alive for the lifetime of the
	/// page - the editor factory uses this when a closure on a heap-
	/// allocated event needs to capture a string (property name,
	/// texture slot name, etc.). Returns the owned String so the
	/// closure captures by value through a stable pointer.
	public String AddOwnedString(StringView value)
	{
		let s = new String(value);
		mOwnedStrings.Add(s);
		return s;
	}

	public void OnMaterialMutated()
	{
		if (mMaterial == null) return;
		mMaterial.IncrementGeneration();
		MarkDirty();
	}

	public void MarkDirty()
	{
		if (mDirty) return;
		mDirty = true;
		UpdateTitle();
	}

	public void Save()
	{
		if (mFilePath.Length == 0 || mMaterial == null || mEditorContext == null) return;

		IWritableMount mount = null;
		let locator = scope String();
		if (!MountResolver.TryResolveAbsoluteWritable(mEditorContext.MountEntries, mFilePath, out mount, locator))
		{
			mEditorContext.Logger?.LogError("[Material] save target not inside any writable mount: {}", mFilePath);
			return;
		}

		let provider = mEditorContext.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			mEditorContext.Logger?.LogError("[Material] no serializer provider available");
			return;
		}

		let memStream = scope MemoryStream();
		if (mMaterial.WriteToStream(memStream, provider) case .Err)
		{
			mEditorContext.Logger?.LogError("[Material] serialization failed: {}", mFilePath);
			return;
		}
		memStream.Position = 0;

		if (mount.Save(locator, memStream) case .Err(let err))
		{
			mEditorContext.Logger?.LogError("[Material] mount save failed for {}: {}", mFilePath, err);
			return;
		}

		mDirty = false;
		UpdateTitle();
		mEditorContext.Logger?.LogInformation("[Material] saved: {}", mFilePath);
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
		// Discard-on-close (revert in-memory edits to the cached
		// resource via ResourceSystem.ReloadResource) is centralized
		// in EditorPageManager.Close; this page only needs to expose
		// AssetRef via IEditableAssetPage.
		delete mContentView;
		mContentView = null;
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
		if (mDirty) mTitle.Append("*");
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
