namespace EngineSandbox;

using System;
using Sedulous.Engine.App;
using Sedulous.Engine;
using Sedulous.Engine.Render;
using Sedulous.Scenes;
using Sedulous.Runtime;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Imaging;
using Sedulous.Imaging.STB;
using Sedulous.Renderer.Passes;
using Sedulous.Renderer.Debug;
using Sedulous.Models;
using Sedulous.Models.GLTF;
using Sedulous.Geometry.Tooling;
using Sedulous.Textures.Resources;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Animation;
using System.Collections;
using Sedulous.Materials.Resources;
using Sedulous.Imaging.SDL;

class SandboxApp : EngineApplication
{
	// Smoothed frame-time stats for the FPS counter.
	private float mFpsSmoothed = 0.0f;
	private float mFrameTimeMs = 0.0f;

	Material mPbrMaterial ~ delete _;
	ITexture mSkyTexture;
	ITextureView mSkyTextureView;

	// Mesh resources (we hold one ref, resource system holds another)
	StaticMeshResource mPlaneRes;
	StaticMeshResource mCubeRes;
	StaticMeshResource mSphereRes;
	SkinnedMeshResource mFoxMeshRes;

	// Fox model data (persists for animation)
	Skeleton mFoxSkeleton ~ delete _;
	AnimationClip mFoxWalkClip ~ delete _;
	List<TextureResource> mFoxTextures = new .() ~ delete _;

	// Sprite textures — held by the app so we release refs on shutdown.
	List<TextureResource> mSpriteTextures = new .() ~ delete _;
	List<MaterialResource> mFoxMaterialResources = new .() ~ delete _;
	MaterialInstance mRedMaterial ~ _?.ReleaseRef();
	MaterialInstance mBlueMaterial ~ _?.ReleaseRef();
	MaterialInstance mGreenMaterial ~ _?.ReleaseRef();
	MaterialInstance mWhiteMaterial ~ _?.ReleaseRef();
	MaterialInstance mYellowMaterial ~ _?.ReleaseRef();
	MaterialInstance mGrayMaterial ~ _?.ReleaseRef();
	MaterialInstance mTransparentMaterial ~ _?.ReleaseRef();
	MaterialInstance mMaskedMaterial ~ _?.ReleaseRef();

	protected override void OnStartup()
	{
		Console.WriteLine("=== EngineSandbox OnStartup ===");

		// Initialize image loader
		SDLImageLoader.Initialize();
		STBImageLoader.Initialize();

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let renderer = renderSub.RenderContext;
		let matSystem = renderer.MaterialSystem;

		// Create scene
		let scene = sceneSub.CreateScene("TestScene");

		// ==================== Materials ====================

		mPbrMaterial = Materials.CreatePBR("PBR", "forward",
			matSystem.WhiteTexture, matSystem.DefaultSampler);

		// Red cube material
		mRedMaterial = new MaterialInstance(mPbrMaterial);
		mRedMaterial.SetColor("BaseColor", .(1, 0, 0, 1));

		// Blue sphere material
		mBlueMaterial = new MaterialInstance(mPbrMaterial);
		mBlueMaterial.SetColor("BaseColor", .(0, 0, 1, 1));

		// Green material
		mGreenMaterial = new MaterialInstance(mPbrMaterial);
		mGreenMaterial.SetColor("BaseColor", .(0.2f, 0.8f, 0.2f, 1));

		// White material (shiny)
		mWhiteMaterial = new MaterialInstance(mPbrMaterial);
		mWhiteMaterial.SetColor("BaseColor", .(0.9f, 0.9f, 0.9f, 1));
		mWhiteMaterial.SetFloat("Roughness", 0.1f);
		mWhiteMaterial.SetFloat("Metallic", 0.8f);

		// Yellow material
		mYellowMaterial = new MaterialInstance(mPbrMaterial);
		mYellowMaterial.SetColor("BaseColor", .(1.0f, 0.85f, 0.1f, 1));

		// Gray plane material
		mGrayMaterial = new MaterialInstance(mPbrMaterial);
		mGrayMaterial.SetColor("BaseColor", .(0.5f, 0.5f, 0.5f, 1));

		// Transparent material (semi-transparent blue)
		mTransparentMaterial = new MaterialInstance(mPbrMaterial);
		mTransparentMaterial.SetColor("BaseColor", .(0.2f, 0.4f, 0.9f, 0.4f));
		mTransparentMaterial.BlendMode = .AlphaBlend;

		// Masked material (alpha cutoff test)
		mMaskedMaterial = new MaterialInstance(mPbrMaterial);
		mMaskedMaterial.SetColor("BaseColor", .(0.8f, 0.2f, 0.1f, 1));
		mMaskedMaterial.SetFloat("AlphaCutoff", 0.5f);
		mMaskedMaterial.BlendMode = .Masked;

		// ==================== Geometry (registered as resources) ====================

		let resources = Context.Resources;

		// Create mesh resources and register with resource system
		mPlaneRes = StaticMeshResource.CreatePlane(10, 10, 1, 1);
		mCubeRes = StaticMeshResource.CreateCube(1.0f);
		mSphereRes = StaticMeshResource.CreateSphere(0.5f, 32, 16);
		resources.AddResource<StaticMeshResource>(mPlaneRes);
		resources.AddResource<StaticMeshResource>(mCubeRes);
		resources.AddResource<StaticMeshResource>(mSphereRes);

		var planeRef = ResourceRef(mPlaneRes.Id, .());
		defer planeRef.Dispose();

		var cubeRef = ResourceRef(mCubeRes.Id, .());
		defer cubeRef.Dispose();

		var sphereRef = ResourceRef(mSphereRes.Id, .());
		defer sphereRef.Dispose();

		// Ground plane
		let planeEntity = scene.CreateEntity("Ground");
		scene.SetLocalTransform(planeEntity, .() { Position = .(0, -1, 0), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, planeEntity, planeRef, mGrayMaterial);

		// Cube
		let cubeEntity = scene.CreateEntity("Cube");
		scene.SetLocalTransform(cubeEntity, .() { Position = .(-1.5f, -0.5f, 0), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, cubeEntity, cubeRef, mRedMaterial);

		// Sphere
		let sphereEntity = scene.CreateEntity("Sphere");
		scene.SetLocalTransform(sphereEntity, .() { Position = .(1.5f, -0.5f, 0), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, sphereEntity, sphereRef, mBlueMaterial);

		// Green cube (back left)
		let cube2Entity = scene.CreateEntity("GreenCube");
		scene.SetLocalTransform(cube2Entity, .() { Position = .(-3.0f, -0.5f, -2.0f), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, cube2Entity, cubeRef, mGreenMaterial);

		// Yellow cube (back right)
		let cube3Entity = scene.CreateEntity("YellowCube");
		scene.SetLocalTransform(cube3Entity, .() { Position = .(3.0f, -0.5f, -2.0f), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, cube3Entity, cubeRef, mYellowMaterial);

		// White metallic sphere (center back)
		let sphere2Entity = scene.CreateEntity("MetalSphere");
		scene.SetLocalTransform(sphere2Entity, .() { Position = .(0, -0.25f, -2.0f), Rotation = .Identity, Scale = .(1.5f, 1.5f, 1.5f) });
		SetupMeshComponent(scene, sphere2Entity, sphereRef, mWhiteMaterial);

		// Small green sphere (front left)
		let sphere3Entity = scene.CreateEntity("GreenSphere");
		scene.SetLocalTransform(sphere3Entity, .() { Position = .(-0.5f, -0.7f, 1.5f), Rotation = .Identity, Scale = .(0.6f, 0.6f, 0.6f) });
		SetupMeshComponent(scene, sphere3Entity, sphereRef, mGreenMaterial);

		// Small yellow sphere (front right)
		let sphere4Entity = scene.CreateEntity("YellowSphere");
		scene.SetLocalTransform(sphere4Entity, .() { Position = .(0.5f, -0.7f, 1.5f), Rotation = .Identity, Scale = .(0.6f, 0.6f, 0.6f) });
		SetupMeshComponent(scene, sphere4Entity, sphereRef, mYellowMaterial);

		// Transparent sphere
		let transparentEntity = scene.CreateEntity("TransparentSphere");
		scene.SetLocalTransform(transparentEntity, .() { Position = .(-1.0f, -0.25f, 0.8f), Rotation = .Identity, Scale = .(1.2f, 1.2f, 1.2f) });
		SetupMeshComponent(scene, transparentEntity, sphereRef, mTransparentMaterial);

		// Masked cube
		let maskedEntity = scene.CreateEntity("MaskedCube");
		scene.SetLocalTransform(maskedEntity, .() { Position = .(3.0f, -0.5f, 1.0f), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, maskedEntity, cubeRef, mMaskedMaterial);

		// ==================== Sprites ====================
		// Load a few animal icons from the Kenney pack and spawn sprites exercising
		// all three billboard orientation modes.
		{
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/fox.png",
				.(-4.0f, 0.2f, 2.0f), .(1.2f, 1.2f), .CameraFacing);
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/bear.png",
				.( 0.0f, 1.6f, 2.0f), .(1.2f, 1.2f), .CameraFacingY);
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/chicken.png",
				.( 4.0f, 0.2f, 2.0f), .(1.2f, 1.2f), .WorldAligned);
		}

		// ==================== Animated Fox ====================

		GltfModels.Initialize();

		let foxPath = scope String();
		GetAssetPath("samples/models/Fox/glTF-Binary/Fox.glb", foxPath);

		let foxModel = scope Model();
		if (ModelLoaderFactory.LoadModel(foxPath, foxModel) case .Ok)
		{
			let importOpts = ModelImportOptions.SkinnedWithAnimations();
			let importer = scope ModelImporter(importOpts);
			let importResult = importer.Import(foxModel);
			defer delete importResult;

			if (importResult.SkinnedMeshes.Count > 0 && importResult.Skeletons.Count > 0)
			{
				// Take ownership of skeleton and first animation clip
				mFoxSkeleton = importResult.Skeletons[0];
				importResult.Skeletons[0] = null; // prevent double-delete

				if (importResult.Animations.Count > 0)
				{
					mFoxWalkClip = importResult.Animations[0];
					importResult.Animations[0] = null;
				}

				// Register skinned mesh as a resource (resolver handles GPU upload)
				let skinnedMesh = importResult.SkinnedMeshes[0];
				mFoxMeshRes = new SkinnedMeshResource(skinnedMesh, true);
				importResult.SkinnedMeshes[0] = null; // resource took ownership
				resources.AddResource<SkinnedMeshResource>(mFoxMeshRes);
				var foxMeshRef = ResourceRef(mFoxMeshRes.Id, .());
				defer foxMeshRef.Dispose();

				// Convert imported textures to resources and register
				for (let importedTex in importResult.Textures)
				{
					let texRes = TextureResourceConverter.Convert(importedTex);
					if (texRes != null)
					{
						resources.AddResource<TextureResource>(texRes);
						mFoxTextures.Add(texRes);
					}
				}

				// Convert imported materials to resources and register
				for (let importedMat in importResult.Materials)
				{
					let matRes = MaterialResourceConverter.Convert(importedMat, mFoxTextures);
					if (matRes != null)
					{
						resources.AddResource<MaterialResource>(matRes);
						mFoxMaterialResources.Add(matRes);
					}
				}

				// Create animation player
				let player = new AnimationPlayer(mFoxSkeleton);
				if (mFoxWalkClip != null)
				{
					mFoxWalkClip.IsLooping = true;
					player.Play(mFoxWalkClip);
				}

				// Create fox entity
				let foxEntity = scene.CreateEntity("Fox");
				scene.SetLocalTransform(foxEntity, .()
				{
					Position = .(-3, -1, 2),
					Rotation = .Identity,
					Scale = .(0.02f, 0.02f, 0.02f)
				});

				// Set up skinned mesh component — manager resolves mesh, materials, and bone buffer
				let skinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
				let compHandle = skinnedMgr.CreateComponent(foxEntity);
				if (let comp = skinnedMgr.Get(compHandle))
				{
					comp.SetMeshRef(foxMeshRef);
					comp.AnimationPlayer = player;

					// Set material refs by slot — resolver creates instances and prepares bind groups
					for (int32 slot = 0; slot < mFoxMaterialResources.Count; slot++)
					{
						var matRef = ResourceRef(mFoxMaterialResources[slot].Id, .());
						comp.SetMaterialRef(slot, matRef);
						matRef.Dispose();
					}
				}

				Console.WriteLine("Fox loaded: {0} vertices, {1} bones, {2} anims, {3} materials, {4} textures",
					skinnedMesh.VertexCount, mFoxSkeleton.BoneCount,
					importResult.Animations.Count, importResult.Materials.Count, importResult.Textures.Count);
			}
		}
		else
		{
			Console.WriteLine("WARNING: Could not load Fox model");
		}

		// ==================== Lights ====================

		let lightMgr = scene.GetModule<LightComponentManager>();

		// Directional shadow-casting light (4 cascades)
		let dirLightEntity = scene.CreateEntity("DirectionalLight");
		scene.SetLocalTransform(dirLightEntity, Transform.CreateLookAt(.(-3, 5, 2), .Zero));
		let dirLightHandle = lightMgr.CreateComponent(dirLightEntity);
		if (let light = lightMgr.Get(dirLightHandle))
		{
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.9f);
			light.Intensity = 1.5f;
			light.CastsShadows = true;
			light.ShadowBias = 0.0005f;       // shader-side depth bias (hardware slope bias handles acne)
			light.ShadowNormalBias = 3.0f;    // normal-offset bias IN TEXELS (scaled by world texel size in shader)
		}

		// Shadow-casting spot light — high above and angled toward the scene.
		let spotLightEntity = scene.CreateEntity("ShadowSpot");
		scene.SetLocalTransform(spotLightEntity, Transform.CreateLookAt(.(4, 6, 4), .(0, 0, 0)));
		let spotLightHandle = lightMgr.CreateComponent(spotLightEntity);
		if (let light = lightMgr.Get(spotLightHandle))
		{
			light.Type = .Spot;
			light.Color = .(1.0f, 0.95f, 0.85f);
			light.Intensity = 8.0f;
			light.Range = 30.0f;
			light.InnerConeAngle = 25.0f;
			light.OuterConeAngle = 40.0f;
			light.CastsShadows = false;
			light.ShadowBias = 0.001f;
			light.ShadowNormalBias = 0.05f;
		}

		// ==================== Camera ====================

		let cameraEntity = scene.CreateEntity("Camera");
		scene.SetLocalTransform(cameraEntity, Transform.CreateLookAt(.(0, 4, 8), .(0, 0, 0)));

		let cameraMgr = scene.GetModule<CameraComponentManager>();
		let cameraCompHandle = cameraMgr.CreateComponent(cameraEntity);
		if (let camera = cameraMgr.Get(cameraCompHandle))
		{
			camera.FieldOfView = 60.0f;
			camera.NearPlane = 0.1f;
			camera.FarPlane = 100.0f;
		}

		// ==================== Sky ====================

		let skyPath = scope String();
		GetAssetPath("textures/environment/BlueSky.hdr", skyPath);

		if (ImageLoaderFactory.LoadImage(skyPath) case .Ok(var image))
		{
			let device = renderer.Device;
			let queue = renderer.Queue;

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

				// Upload pixel data
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

				// Set on sky pass
				if (let skyPass = renderSub.Pipeline.GetPass<SkyPass>())
				{
					skyPass.SkyTexture = mSkyTextureView;
					skyPass.Intensity = 1.0f;
				}

				Console.WriteLine("Sky texture loaded: {0}x{1}", image.Width, image.Height);
			}

			delete image;
		}
		else
		{
			Console.WriteLine("WARNING: Could not load sky texture");
		}

		Console.WriteLine("Entities: {0}", scene.EntityCount);
		Console.WriteLine("=== Engine running (close window to exit) ===");
	}

	/// Creates a MeshComponent on an entity with a mesh resource ref and optional material.
	private void SetupMeshComponent(Scene scene, EntityHandle entity, ResourceRef meshRef, MaterialInstance material = null)
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

	/// Loads a sprite texture from the assets directory, registers it as a
	/// TextureResource, and creates a sprite entity at the given position.
	private void CreateSprite(Scene scene, ResourceSystem resources, StringView relativePath,
		Vector3 position, Vector2 size, SpriteOrientation orientation)
	{
		let fullPath = scope String();
		GetAssetPath(relativePath, fullPath);

		Image image = null;
		if (ImageLoaderFactory.LoadImage(fullPath) case .Ok(var loaded))
			image = loaded;
		else
		{
			Console.WriteLine(scope $"WARNING: Sprite texture not found: {relativePath}");
			return;
		}

		let texRes = new TextureResource(image, true); // takes ownership of Image
		resources.AddResource<TextureResource>(texRes);
		mSpriteTextures.Add(texRes);

		let entity = scene.CreateEntity("Sprite");
		scene.SetLocalTransform(entity, .() { Position = position, Rotation = .Identity, Scale = .One });

		let spriteMgr = scene.GetModule<SpriteComponentManager>();
		let handle = spriteMgr.CreateComponent(entity);
		if (let comp = spriteMgr.Get(handle))
		{
			var texRef = ResourceRef(texRes.Id, "");
			defer texRef.Dispose();
			comp.SetTextureRef(texRef);
			comp.Size = size;
			comp.Orientation = orientation;
		}
	}

	protected override void OnUpdate(float deltaTime)
	{
		let rs = Context.GetSubsystem<RenderSubsystem>();
		if (rs == null) return;
		let dbg = rs.DebugDraw;
		if (dbg == null) return;

		// Smooth the FPS readout so it doesn't flicker every frame.
		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
		let fps = mFrameTimeMs > 0.001f ? 1000.0f / mFrameTimeMs : 0.0f;
		mFpsSmoothed = mFpsSmoothed * 0.9f + fps * 0.1f;

		// FPS counter — top-left corner with a dark background rect for readability.
		dbg.DrawScreenRect(4, 4, 180, 22, .(0, 0, 0, 160));
		let fpsText = scope String();
		fpsText.AppendF("FPS {0:F0}  ({1:F2} ms)", mFpsSmoothed, mFrameTimeMs);
		dbg.DrawScreenText(8, 8, fpsText, .White);

		// World-space axis indicator at the origin.
		dbg.DrawAxis(Matrix.Identity, 1.5f);

		// Wire box around the rough scene extent so the frustum/cascade math can
		// be visually sanity-checked later.
		BoundingBox sceneBounds = .(.(-6, 0, -6), .(6, 4, 6));
		dbg.DrawWireBox(sceneBounds, .Yellow);
	}

	protected override void OnCleanup()
	{
	}

	protected override void OnShutdown()
	{
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let device = renderSub.RenderContext.Device;

		// Clear sky texture reference before destroying
		if (let skyPass = renderSub.Pipeline.GetPass<SkyPass>())
			skyPass.SkyTexture = null;

		if (mSkyTextureView != null)
			device.DestroyTextureView(ref mSkyTextureView);
		if (mSkyTexture != null)
			device.DestroyTexture(ref mSkyTexture);

		// Release fox resources
		for (let foxMatRes in mFoxMaterialResources)
			foxMatRes?.ReleaseRef();
		for (let foxTex in mFoxTextures)
			foxTex?.ReleaseRef();

		// Release sprite texture refs
		for (let spriteTex in mSpriteTextures)
			spriteTex?.ReleaseRef();

		// Release our refs on mesh resources (resource system holds its own)
		mPlaneRes?.ReleaseRef();
		mCubeRes?.ReleaseRef();
		mSphereRes?.ReleaseRef();
		mFoxMeshRes?.ReleaseRef();

		Console.WriteLine("=== EngineSandbox OnShutdown ===");
	}
}
