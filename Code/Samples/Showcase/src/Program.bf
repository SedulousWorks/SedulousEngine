namespace Showcase;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Engine;
using Sedulous.Engine.App;
using Sedulous.Engine.Render;
using Sedulous.Renderer;
using Sedulous.Renderer.Passes;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Textures.Resources;
using Sedulous.Resources;
using Sedulous.Images;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
using Sedulous.Models;
using Sedulous.Models.GLTF;
using Sedulous.Shell;
using Sedulous.Engine.Core;

/// Loaded model asset: mesh resource + per-slot material resource refs.
class LoadedModel
{
	public String Name ~ delete _;
	public StaticMeshResource MeshResource;
	/// Material ResourceRefs per submesh slot. Resolver creates shared instances automatically.
	public List<ResourceRef> MaterialRefs = new .() ~ { for (var r in _) r.Dispose(); delete _; };

	public void ReleaseRefs()
	{
		MeshResource?.ReleaseRef();
	}
}

/// Stylized nature showcase scene.
class ShowcaseApp : EngineApplication
{
	private Scene mScene;
	private EntityHandle mCameraEntity;

	// FPS display
	private float mFpsSmoothed = 0;
	private float mFrameTimeMs = 0;

	// Camera state
	private Vector3 mCameraPosition = .(0, 5, 20);
	private float mYaw = Math.PI_f;
	private float mPitch = -0.15f;
	private bool mMouseCaptured = false;

	// Loaded model assets (owned, cleaned up on shutdown)
	private List<LoadedModel> mLoadedModels = new .() ~ DeleteContainerAndItems!(_);

	// Dedup context for texture/material resource deduplication across model imports
	private ImportDeduplicationContext mDedupContext = new .() ~ delete _;

	// Materials
	private Material mPbrMaterial ~ delete _;

	// Ground plane
	private StaticMeshResource mPlaneRes ~ _.ReleaseRef();
	private MaterialInstance mGroundMaterial ~ _.ReleaseRef();

	// Sky
	private ITexture mSkyTexture;
	private ITextureView mSkyTextureView;

	protected override void OnStartup()
	{
		SDLImageLoader.Initialize();
		STBImageLoader.Initialize();
		GltfModels.Initialize();

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let renderer = renderSub.RenderContext;
		let matSystem = renderer.MaterialSystem;
		let resources = ResourceSystem;

		// Create scene
		let scene = sceneSub.CreateScene("NatureShowcase");
		mScene = scene;

		// Ground material
		mPbrMaterial = Materials.CreatePBR("PBR", "forward",
			matSystem.WhiteTexture, matSystem.DefaultSampler);

		mGroundMaterial = new MaterialInstance(mPbrMaterial);
		mGroundMaterial.SetColor("BaseColor", .(0.35f, 0.55f, 0.25f, 1)); // grass green
		mGroundMaterial.SetFloat("Roughness", 0.9f);

		// Ground plane
		mPlaneRes = StaticMeshResource.CreatePlane(120, 120, 1, 1);
		resources.AddResource<StaticMeshResource>(mPlaneRes);

		var planeRef = ResourceRef(mPlaneRes.Id, .());
		defer planeRef.Dispose();

		let planeEntity = scene.CreateEntity("Ground");
		scene.SetLocalTransform(planeEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, planeEntity, planeRef, mGroundMaterial);

		// Load nature assets
		let assetBase = scope String();
		GetAssetPath("samples/StylizedNatureMegaKit_Standard/glTF", assetBase);

		// ==================== Trees ====================
		// Common trees - dense clusters and scattered singles
		Vector3[8] ct1Pos = .(
			.(-8, 0, -6), .(5, 0, -10), .(-12, 0, 3), .(18, 0, 5),
			.(-25, 0, -18), .(30, 0, -15), .(-8, 0, -25), .(15, 0, 20));
		PlaceModels(scene, resources, assetBase, "CommonTree_1", ct1Pos);
		Vector3[6] ct2Pos = .(
			.(10, 0, -4), .(-5, 0, -12), .(-20, 0, 15), .(25, 0, -8),
			.(-30, 0, -5), .(12, 0, 25));
		PlaceModels(scene, resources, assetBase, "CommonTree_2", ct2Pos);
		Vector3[5] ct3Pos = .(
			.(15, 0, -8), .(-15, 0, -5), .(22, 0, 12), .(-28, 0, 8), .(0, 0, -30));
		PlaceModels(scene, resources, assetBase, "CommonTree_3", ct3Pos);
		Vector3[4] ct4Pos = .(.(3, 0, -15), .(-18, 0, -22), .(28, 0, 18), .(-10, 0, 28));
		PlaceModels(scene, resources, assetBase, "CommonTree_4", ct4Pos);
		Vector3[3] ct5Pos = .(.(20, 0, -20), .(-22, 0, 20), .(35, 0, 0));
		PlaceModels(scene, resources, assetBase, "CommonTree_5", ct5Pos);

		// Pine trees - back and sides
		Vector3[5] p1Pos = .(
			.(-18, 0, -10), .(18, 0, -12), .(-35, 0, -20), .(32, 0, -25), .(0, 0, -35));
		PlaceModels(scene, resources, assetBase, "Pine_1", p1Pos);
		Vector3[4] p2Pos = .(
			.(-14, 0, -14), .(12, 0, -16), .(-28, 0, -28), .(25, 0, -30));
		PlaceModels(scene, resources, assetBase, "Pine_2", p2Pos);
		Vector3[3] p3Pos = .(.(20, 0, -6), .(-32, 0, -12), .(35, 0, -18));
		PlaceModels(scene, resources, assetBase, "Pine_3", p3Pos);
		Vector3[2] p4Pos = .(.(-25, 0, -32), .(30, 0, -32));
		PlaceModels(scene, resources, assetBase, "Pine_4", p4Pos);
		Vector3[2] p5Pos = .(.(15, 0, -35), .(-15, 0, -35));
		PlaceModels(scene, resources, assetBase, "Pine_5", p5Pos);

		// Twisted trees - scattered accents
		Vector3[3] tt1Pos = .(.(-20, 0, -2), .(25, 0, 15), .(-30, 0, 12));
		PlaceModels(scene, resources, assetBase, "TwistedTree_1", tt1Pos);
		Vector3[2] tt2Pos = .(.(22, 0, 2), .(-15, 0, 22));
		PlaceModels(scene, resources, assetBase, "TwistedTree_2", tt2Pos);
		Vector3[2] tt3Pos = .(.(30, 0, 8), .(-25, 0, -8));
		PlaceModels(scene, resources, assetBase, "TwistedTree_3", tt3Pos);

		// Dead trees - sparse
		Vector3[3] dt1Pos = .(.(-22, 0, -15), .(35, 0, -10), .(-35, 0, 5));
		PlaceModels(scene, resources, assetBase, "DeadTree_1", dt1Pos);
		Vector3[2] dt2Pos = .(.(28, 0, -22), .(-18, 0, 30));
		PlaceModels(scene, resources, assetBase, "DeadTree_2", dt2Pos);

		// ==================== Rocks ====================
		Vector3[4] r1Pos = .(.(2, 0, -3), .(-6, 0, 5), .(18, 0, 10), .(-20, 0, -10));
		PlaceModels(scene, resources, assetBase, "Rock_Medium_1", r1Pos);
		Vector3[4] r2Pos = .(.(-3, 0, -8), .(8, 0, 3), .(-15, 0, 12), .(25, 0, -5));
		PlaceModels(scene, resources, assetBase, "Rock_Medium_2", r2Pos);
		Vector3[3] r3Pos = .(.(6, 0, -6), .(-12, 0, -15), .(20, 0, 15));
		PlaceModels(scene, resources, assetBase, "Rock_Medium_3", r3Pos);

		// ==================== Rock path ====================
		// Winding path from front to back
		Vector3[1] rpwPos = .(.(0, 0.01f, 0));
		PlaceModels(scene, resources, assetBase, "RockPath_Round_Wide", rpwPos);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(0, 0.01f, 3), 0);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(-1, 0.01f, 6), 0.3f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(-3, 0.01f, 9), 0.5f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(-4, 0.01f, 12), 0.2f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Wide", .(-3, 0.01f, 15), 0.8f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(-1, 0.01f, 18), 1.2f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(2, 0.01f, 20), 1.5f);
		// Branch path to the right
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(2, 0.01f, 0), 1.57f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Thin", .(5, 0.01f, -1), 1.3f);
		PlaceModelRotated(scene, resources, assetBase, "RockPath_Round_Wide", .(8, 0.01f, -1), 1.57f);

		// ==================== Bushes ====================
		Vector3[6] bPos = .(
			.(-4, 0, -2), .(7, 0, -1), .(-10, 0, -8),
			.(15, 0, 8), .(-18, 0, 6), .(12, 0, -12));
		PlaceModels(scene, resources, assetBase, "Bush_Common", bPos);
		Vector3[6] bfPos = .(
			.(4, 0, -1), .(-7, 0, 1), .(11, 0, -7),
			.(-14, 0, 10), .(20, 0, 3), .(-8, 0, 18));
		PlaceModels(scene, resources, assetBase, "Bush_Common_Flowers", bfPos);

		// ==================== Flowers ====================
		Vector3[5] f3gPos = .(.(1, 0, 2), .(-2, 0, 4), .(5, 0, 5), .(10, 0, 8), .(-8, 0, 12));
		PlaceModels(scene, resources, assetBase, "Flower_3_Group", f3gPos);
		Vector3[4] f4gPos = .(.(-1, 0, 6), .(3, 0, 3), .(14, 0, 5), .(-12, 0, 8));
		PlaceModels(scene, resources, assetBase, "Flower_4_Group", f4gPos);
		Vector3[4] f3sPos = .(.(2, 0, 1), .(-3, 0, 3), .(8, 0, 12), .(-6, 0, 15));
		PlaceModels(scene, resources, assetBase, "Flower_3_Single", f3sPos);
		Vector3[4] f4sPos = .(.(6, 0, 2), .(-5, 0, 7), .(12, 0, 15), .(-10, 0, 20));
		PlaceModels(scene, resources, assetBase, "Flower_4_Single", f4sPos);

		// ==================== Grass ====================
		Vector3[12] gsPos = .(
			.(1, 0, 1), .(-2, 0, 2), .(4, 0, -2), .(-6, 0, 3),
			.(8, 0, 1), .(-1, 0, 5), .(10, 0, 6), .(-8, 0, 10),
			.(15, 0, 3), .(-12, 0, 5), .(6, 0, 14), .(-4, 0, 18));
		PlaceModels(scene, resources, assetBase, "Grass_Common_Short", gsPos);
		Vector3[8] gtPos = .(
			.(3, 0, 4), .(-4, 0, 6), .(7, 0, 5), .(12, 0, 10),
			.(-10, 0, 14), .(18, 0, 7), .(-15, 0, 2), .(5, 0, 18));
		PlaceModels(scene, resources, assetBase, "Grass_Common_Tall", gtPos);
		Vector3[6] gwsPos = .(
			.(0, 0, 3), .(-3, 0, 1), .(5, 0, 7), .(14, 0, 2),
			.(-10, 0, 8), .(8, 0, 16));
		PlaceModels(scene, resources, assetBase, "Grass_Wispy_Short", gwsPos);
		Vector3[4] gwtPos = .(.(-5, 0, 12), .(10, 0, 12), .(-14, 0, 16), .(16, 0, 14));
		PlaceModels(scene, resources, assetBase, "Grass_Wispy_Tall", gwtPos);

		// ==================== Ferns & plants ====================
		Vector3[4] fernPos = .(.(-8, 0, 2), .(9, 0, -3), .(-15, 0, 8), .(18, 0, 12));
		PlaceModels(scene, resources, assetBase, "Fern_1", fernPos);
		Vector3[4] pl1Pos = .(.(-5, 0, 4), .(6, 0, 6), .(-12, 0, 15), .(14, 0, 18));
		PlaceModels(scene, resources, assetBase, "Plant_1", pl1Pos);
		Vector3[3] pl1bPos = .(.(-18, 0, 12), .(20, 0, 8), .(0, 0, 22));
		PlaceModels(scene, resources, assetBase, "Plant_1_Big", pl1bPos);
		Vector3[3] pl7Pos = .(.(2, 0, 7), .(-7, 0, 8), .(15, 0, 15));
		PlaceModels(scene, resources, assetBase, "Plant_7", pl7Pos);
		Vector3[2] pl7bPos = .(.(-20, 0, 18), .(22, 0, 20));
		PlaceModels(scene, resources, assetBase, "Plant_7_Big", pl7bPos);

		// Clovers
		Vector3[4] cl1Pos = .(.(3, 0, 2), .(-4, 0, 5), .(8, 0, 8), .(-6, 0, 10));
		PlaceModels(scene, resources, assetBase, "Clover_1", cl1Pos);
		Vector3[3] cl2Pos = .(.(5, 0, 4), .(-2, 0, 8), .(10, 0, 10));
		PlaceModels(scene, resources, assetBase, "Clover_2", cl2Pos);

		// ==================== Mushrooms ====================
		Vector3[4] musPos = .(.(-9, 0, -5), .(3, 0, -4), .(-12, 0, 6), .(8, 0, 10));
		PlaceModels(scene, resources, assetBase, "Mushroom_Common", musPos);
		Vector3[3] musLPos = .(.(-6, 0, -4), .(10, 0, -8), .(-15, 0, 3));
		PlaceModels(scene, resources, assetBase, "Mushroom_Laetiporus", musLPos);

		// ==================== Pebbles ====================
		Vector3[4] peb1Pos = .(.(1, 0, 1), .(-1, 0, 4), .(4, 0, 10), .(-3, 0, 14));
		PlaceModels(scene, resources, assetBase, "Pebble_Round_1", peb1Pos);
		Vector3[3] peb2Pos = .(.(0, 0, 2), .(-2, 0, 7), .(6, 0, 0));
		PlaceModels(scene, resources, assetBase, "Pebble_Round_2", peb2Pos);
		Vector3[3] peb3Pos = .(.(2, 0, 0), .(-1, 0, 5), .(8, 0, -2));
		PlaceModels(scene, resources, assetBase, "Pebble_Square_1", peb3Pos);
		Vector3[3] peb4Pos = .(.(-2, 0, 9), .(5, 0, 12), .(3, 0, 16));
		PlaceModels(scene, resources, assetBase, "Pebble_Round_3", peb4Pos);
		Vector3[2] peb5Pos = .(.(7, 0, 5), .(-5, 0, 11));
		PlaceModels(scene, resources, assetBase, "Pebble_Square_2", peb5Pos);

		// Lighting
		SetupLighting(scene);

		// Camera
		SetupCamera(scene);

		// Sky
		SetupSky(renderSub);

		Console.WriteLine("Showcase scene loaded: {0} models", mLoadedModels.Count);
	}

	// ==================== Model Loading ====================

	/// Cache of already-loaded models to avoid re-importing the same asset.
	private Dictionary<String, LoadedModel> mModelCache = new .() ~ delete _;

	private LoadedModel LoadModel(ResourceSystem resources, StringView basePath, StringView modelName)
	{
		// Check cache first
		if (mModelCache.TryGetValue(scope String(modelName), let cached))
			return cached;

		let path = scope String();
		path.AppendF("{}/{}.gltf", basePath, modelName);

		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(path, model) != .Ok)
		{
			Console.WriteLine("WARNING: Could not load model: {}", modelName);
			return null;
		}

		let importOpts = ModelImportOptions.StaticMeshOnly();
		importOpts.BasePath.Set(basePath);
		importOpts.ModelPath.Set(path);
		let importer = scope ModelImporter(importOpts);
		let importResult = importer.Import(model);
		defer delete importResult;

		if (importResult.StaticMeshes.Count == 0)
		{
			Console.WriteLine("WARNING: No static meshes in model: {}", modelName);
			return null;
		}

		// Convert to resources with deduplication (shared textures + materials across models)
		let resResult = ResourceImportResult.ConvertFrom(importResult, mDedupContext, path);
		defer delete resResult;

		Console.WriteLine("  Import: {0} textures, {1} materials from model",
			importResult.Textures.Count, importResult.Materials.Count);
		Console.WriteLine("  Dedup:  {0} new textures, {1} new materials (rest reused)",
			resResult.Textures.Count, resResult.Materials.Count);

		// Register newly created resources and take ownership from resResult
		// (deduped ones already registered by earlier imports)
		for (let texRes in resResult.Textures)
			resources.AddResource<TextureResource>(texRes);
		for (let matRes in resResult.Materials)
			resources.AddResource<MaterialResource>(matRes);

		// Prevent resResult from deleting resources we registered
		// (ResourceSystem now owns them via AddResource refs)
		resResult.Textures.Clear();
		resResult.Materials.Clear();

		// Collect material ResourceRefs -- resolver will create shared instances automatically
		let loaded = new LoadedModel();
		loaded.Name = new String(modelName);

		for (let importedMat in importResult.Materials)
		{
			let matRes = mDedupContext.FindMaterial(importedMat.Name);
			if (matRes != null)
			{
				loaded.MaterialRefs.Add(ResourceRef(matRes.Id, matRes.Name));
				Console.WriteLine("  Material '{}': ref -> {}", importedMat.Name, matRes.Id);
			}
		}

		// Take ownership of the static mesh
		let staticMesh = importResult.StaticMeshes[0];
		let meshRes = new StaticMeshResource(staticMesh, true);
		importResult.StaticMeshes[0] = null; // transfer ownership
		meshRes.Name.Set(modelName);
		resources.AddResource<StaticMeshResource>(meshRes);
		loaded.MeshResource = meshRes;

		mModelCache[new String(modelName)] = loaded;
		mLoadedModels.Add(loaded);

		Console.WriteLine("Loaded: {} ({} verts, {} material slots)",
			modelName, staticMesh.VertexCount, loaded.MaterialRefs.Count);

		return loaded;
	}

	private void PlaceModels(Scene scene, ResourceSystem resources,
		StringView basePath, StringView modelName, Span<Vector3> positions)
	{
		let loaded = LoadModel(resources, basePath, modelName);
		if (loaded == null) return;

		var meshRef = ResourceRef(loaded.MeshResource.Id, .());
		defer meshRef.Dispose();

		for (let pos in positions)
		{
			let name = scope String();
			name.AppendF("{}_{}", modelName, @pos.Index);
			let entity = scene.CreateEntity(name);
			scene.SetLocalTransform(entity, .() { Position = pos, Rotation = .Identity, Scale = .One });
			SetupImportedMeshComponent(scene, entity, meshRef, loaded);
		}
	}

	private void PlaceModelRotated(Scene scene, ResourceSystem resources,
		StringView basePath, StringView modelName, Vector3 position, float yaw)
	{
		let loaded = LoadModel(resources, basePath, modelName);
		if (loaded == null) return;

		var meshRef = ResourceRef(loaded.MeshResource.Id, .());
		defer meshRef.Dispose();

		let name = scope String();
		name.AppendF("{}_r", modelName);
		let entity = scene.CreateEntity(name);
		scene.SetLocalTransform(entity, .()
		{
			Position = position,
			Rotation = Quaternion.CreateFromYawPitchRoll(yaw, 0, 0),
			Scale = .One
		});
		SetupImportedMeshComponent(scene, entity, meshRef, loaded);
	}

	// ==================== Components ====================

	private void SetupMeshComponent(Scene scene, EntityHandle entity, ResourceRef meshRef, MaterialInstance material)
	{
		let meshMgr = scene.GetModule<MeshComponentManager>();
		let compHandle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(compHandle))
		{
			comp.SetMeshRef(meshRef);
			if (material != null)
				comp.SetMaterial(0, material);
		}
	}

	private void SetupImportedMeshComponent(Scene scene, EntityHandle entity, ResourceRef meshRef, LoadedModel loaded)
	{
		let meshMgr = scene.GetModule<MeshComponentManager>();
		let compHandle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(compHandle))
		{
			comp.SetMeshRef(meshRef);
			for (int32 slot = 0; slot < loaded.MaterialRefs.Count; slot++)
				comp.SetMaterialRef(slot, loaded.MaterialRefs[slot]);
		}
	}

	// ==================== Lighting ====================

	private void SetupLighting(Scene scene)
	{
		let lightMgr = scene.GetModule<LightComponentManager>();
		// lightMgr.DebugDrawEnabled = true;  // uncomment to visualize light gizmos
		lightMgr.DebugDrawEnabled = false;

		// Warm directional sun - angled for long shadows
		let sunEntity = scene.CreateEntity("Sun");
		scene.SetLocalTransform(sunEntity, Transform.CreateLookAt(.(10, 15, 8), .Zero));
		let sunHandle = lightMgr.CreateComponent(sunEntity);
		if (let light = lightMgr.Get(sunHandle))
		{
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.85f);
			light.Intensity = 1.8f;
			light.CastsShadows = true;
			light.ShadowBias = 0.0005f;
			light.ShadowNormalBias = 3.0f;
		}

		// Warm fill point light near the path
		let fillEntity = scene.CreateEntity("FillLight");
		scene.SetLocalTransform(fillEntity, .() { Position = .(-2, 3, 4), Rotation = .Identity, Scale = .One });
		let fillHandle = lightMgr.CreateComponent(fillEntity);
		if (let light = lightMgr.Get(fillHandle))
		{
			light.Type = .Point;
			light.Color = .(1.0f, 0.85f, 0.6f);
			light.Intensity = 8.0f;
			light.Range = 15.0f;
			light.CastsShadows = false;
		}
	}

	// ==================== Camera ====================

	private void SetupCamera(Scene scene)
	{
		let cameraEntity = scene.CreateEntity("Camera");
		mCameraEntity = cameraEntity;
		scene.SetLocalTransform(cameraEntity, Transform.CreateLookAt(mCameraPosition, .(0, 1, 0)));

		let cameraMgr = scene.GetModule<CameraComponentManager>();
		let cameraCompHandle = cameraMgr.CreateComponent(cameraEntity);
		if (let camera = cameraMgr.Get(cameraCompHandle))
		{
			camera.FieldOfView = 60.0f;
			camera.NearPlane = 0.1f;
			camera.FarPlane = 500.0f;
		}
	}

	// ==================== Sky ====================

	private void SetupSky(RenderSubsystem renderSub)
	{
		let skyPath = scope String();
		GetAssetPath("textures/environment/BlueSky.hdr", skyPath);

		let device = renderSub.Device;
		let queue = device.GetQueue(.Graphics);

		if (ImageLoaderFactory.LoadImage(skyPath) case .Ok(var image))
		{
			TextureDesc skyTexDesc = .()
			{
				Label = "Sky HDR",
				Width = image.Width,
				Height = image.Height,
				Depth = 1,
				Format = .RGBA32Float,
				Usage = .Sampled | .CopyDst,
				Dimension = .Texture2D,
				MipLevelCount = 1,
				ArrayLayerCount = 1,
				SampleCount = 1
			};

			if (device.CreateTexture(skyTexDesc) case .Ok(let tex))
			{
				mSkyTexture = tex;

				var layout = TextureDataLayout() { BytesPerRow = image.Width * 16, RowsPerImage = image.Height };
				var writeSize = Extent3D(image.Width, image.Height, 1);

				if (queue.CreateTransferBatch() case .Ok(let tb))
				{
					tb.WriteTexture(mSkyTexture, Span<uint8>(image.Data.Ptr, image.Data.Length), layout, writeSize);
					tb.Submit();
					device.WaitIdle();
					var tbRef = tb;
					queue.DestroyTransferBatch(ref tbRef);
				}

				TextureViewDesc viewDesc = .() { Label = "Sky HDR View", Format = .RGBA32Float, Dimension = .Texture2D };
				if (device.CreateTextureView(mSkyTexture, viewDesc) case .Ok(let view))
					mSkyTextureView = view;

				if (let skyPass = renderSub.GetPipeline(mScene)?.GetPass<SkyPass>())
				{
					skyPass.SkyTexture = mSkyTextureView;
					skyPass.Intensity = 1.2f;
				}
			}

			delete image;
		}
		else
		{
			Console.WriteLine("WARNING: Could not load sky HDR texture");
		}
	}

	// ==================== Update ====================

	protected override void OnUpdate(float deltaTime)
	{
		// FPS counter
		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
		let fps = mFrameTimeMs > 0.001f ? 1000.0f / mFrameTimeMs : 0.0f;
		mFpsSmoothed = mFpsSmoothed * 0.9f + fps * 0.1f;

		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		if (let dbg = renderSub?.RenderContext?.DebugDraw)
		{
			let text = scope String();
			text.AppendF("FPS {0:F0}  ({1:F2} ms)", mFpsSmoothed, mFrameTimeMs);
			dbg.DrawScreenRect(5, 5, text.Length * 8 + 14, 20, .(0, 0, 0, 180));
			dbg.DrawScreenText(10, 10, text, .(255, 255, 255));
		}

		let keyboard = mShell.InputManager.Keyboard;
		let mouse = mShell.InputManager.Mouse;

		// Escape to exit
		if (keyboard.IsKeyPressed(.Escape))
		{
			Exit();
			return;
		}

		// Tab to toggle mouse capture
		if (keyboard.IsKeyPressed(.Tab))
		{
			mMouseCaptured = !mMouseCaptured;
			mouse.RelativeMode = mMouseCaptured;
			mouse.Visible = !mMouseCaptured;
		}

		// Camera rotation (RMB or captured)
		bool rotating = mMouseCaptured || mouse.IsButtonDown(.Right);
		if (rotating)
		{
			let deltaX = mouse.DeltaX;
			let deltaY = mouse.DeltaY;
			mYaw -= deltaX * 0.003f;
			mPitch -= deltaY * 0.003f;
			mPitch = Math.Clamp(mPitch, -1.5f, 1.5f);
		}

		// Camera movement (WASD + QE)
		let forward = Vector3(
			Math.Cos(mPitch) * Math.Sin(mYaw),
			Math.Sin(mPitch),
			Math.Cos(mPitch) * Math.Cos(mYaw)
		);
		let right = Vector3.Normalize(Vector3.Cross(forward, .(0, 1, 0)));
		let up = Vector3(0, 1, 0);

		float speed = 8.0f * deltaTime;
		if (keyboard.IsKeyDown(.LeftShift)) speed *= 4.0f;

		if (keyboard.IsKeyDown(.W)) mCameraPosition += forward * speed;
		if (keyboard.IsKeyDown(.S)) mCameraPosition -= forward * speed;
		if (keyboard.IsKeyDown(.A)) mCameraPosition -= right * speed;
		if (keyboard.IsKeyDown(.D)) mCameraPosition += right * speed;
		if (keyboard.IsKeyDown(.Q)) mCameraPosition -= up * speed;
		if (keyboard.IsKeyDown(.E)) mCameraPosition += up * speed;

		// Apply camera transform
		if (mScene != null)
		{
			let target = mCameraPosition + forward;
			mScene.SetLocalTransform(mCameraEntity, Transform.CreateLookAt(mCameraPosition, target));
		}
	}

	// ==================== Shutdown ====================

	protected override void OnShutdown()
	{
		let renderSub = Context.GetSubsystem<RenderSubsystem>();

		// Clear sky pass reference before destroying texture
		if (renderSub != null && mScene != null)
		{
			if (let skyPass = renderSub.GetPipeline(mScene)?.GetPass<SkyPass>())
				skyPass.SkyTexture = null;
		}

		let device = mDevice;
		if (device != null)
		{
			if (mSkyTextureView != null)
				device.DestroyTextureView(ref mSkyTextureView);
			if (mSkyTexture != null)
				device.DestroyTexture(ref mSkyTexture);
		}

		// Release resource refs
		for (let loaded in mLoadedModels)
			loaded.ReleaseRefs();

		// Release deduped texture/material resource refs
		mDedupContext.ReleaseAllRefs();

		// Model cache keys
		for (let key in mModelCache.Keys)
			delete key;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope ShowcaseApp();
		return app.Run(.()
		{
			Title = "Sedulous - Nature Showcase",
			Width = 1280, Height = 720,
			EnableShaderCache = true
		});
	}
}
