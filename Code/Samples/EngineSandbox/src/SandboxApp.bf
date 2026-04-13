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
using Sedulous.Shell.Input;
using Sedulous.Models;
using Sedulous.Models.GLTF;
using Sedulous.Geometry.Tooling;
using Sedulous.Textures.Resources;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Animation;
using System.Collections;
using Sedulous.Materials.Resources;
using Sedulous.Imaging.SDL;
using Sedulous.Particles;

class SandboxApp : EngineApplication
{
	// Smoothed frame-time stats for the FPS counter.
	private float mFpsSmoothed = 0.0f;
	private float mFrameTimeMs = 0.0f;

	// Camera fly-through state.
	private Scene mScene;
	private EntityHandle mCameraEntity;
	private Vector3 mCameraPosition = .(0, 4, 8);
	private float mYaw = Math.PI_f;             // facing -Z initially (toward origin)
	private float mPitch = -0.464f;              // slight downward tilt
	private bool mMouseCaptured = false;

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

	// Particle effects (owned by app, shared by components)
	ParticleEffect mSparksEffect ~ delete _;
	ParticleEffect mSmokeEffect ~ delete _;
	ParticleEffect mMagicEffect ~ delete _;
	ParticleEffect mFireEffect ~ delete _;
	ParticleEffect mTrailEffect ~ delete _;
	ParticleEffect mFireworksEffect ~ delete _;

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
		mScene = scene;

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
		mPlaneRes = StaticMeshResource.CreatePlane(30, 30, 1, 1);
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
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/rabbit.png",
				.(-4.0f, 0.2f, 2.0f), .(1.2f, 1.2f), .CameraFacing);
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/bear.png",
				.( 0.0f, 1.6f, 2.0f), .(1.2f, 1.2f), .CameraFacingY);
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/chicken.png",
				.( 4.0f, 0.2f, 2.0f), .(1.2f, 1.2f), .WorldAligned);
		}

		// ==================== Decal ====================
		// Projects a Kenney animal icon downward onto the ground plane.
		CreateDecal(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/panda.png",
			.(0.0f, -0.5f, 2.5f), .(3.0f, 3.0f, 3.0f));

		// ==================== Particles ====================
		// Four effects spaced across the scene to showcase different particle types.
		{
			let particleMgr = scene.GetModule<ParticleComponentManager>();

			// --- Sparks (additive, rising embers) ---
			mSparksEffect = new ParticleEffect("Sparks");
			{
				let sys = new ParticleSystem(500);
				sys.Emitter.SpawnRate = 40;
				sys.BlendMode = .Additive;
				sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.5f, 1.5f) });
				sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.3f) });
				sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 3, 0), Randomness = .(1.5f, 1, 1.5f) });
				sys.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.08f, 0.08f)) });
				sys.AddInitializer(new ColorInitializer() { Color = .Range(.(1, 0.4f, 0, 1), .(1, 0.9f, 0.2f, 1)) });
				sys.AddInitializer(new RotationInitializer());
				sys.AddBehavior(new GravityBehavior() { Multiplier = 0.3f });
				sys.AddBehavior(new DragBehavior() { Drag = 0.8f });
				sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f) });
				sys.AddBehavior(new RotationOverLifetimeBehavior());
				sys.AddBehavior(new VelocityIntegrationBehavior());
				mSparksEffect.AddSystem(sys);
			}
			CreateParticleEntity(scene, resources, particleMgr, mSparksEffect,
				"textures/kenney_particle-pack/PNG (Transparent)/circle_05.png",
				"Sparks", .(6, -1, -6));

			// --- Smoke (alpha blended, rising plume) ---
			mSmokeEffect = new ParticleEffect("Smoke");
			{
				let sys = new ParticleSystem(300);
				sys.Emitter.SpawnRate = 15;
				sys.BlendMode = .Alpha;
				sys.SortParticles = true;
				sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(2.0f, 4.0f) });
				sys.AddInitializer(new PositionInitializer() { Shape = .Circle(0.4f) });
				sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 1.5f, 0), Randomness = .(0.3f, 0.2f, 0.3f) });
				sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.3f, 0.3f), .(0.5f, 0.5f)) });
				sys.AddInitializer(new ColorInitializer() { Color = .Range(.(0.4f, 0.4f, 0.4f, 0.6f), .(0.6f, 0.6f, 0.6f, 0.4f)) });
				sys.AddInitializer(new RotationInitializer() { RotationSpeed = .(-0.5f, 0.5f) });
				sys.AddBehavior(new GravityBehavior() { Multiplier = -0.05f, Direction = .(0, -1, 0) }); // slight buoyancy
				sys.AddBehavior(new DragBehavior() { Drag = 0.3f });
				sys.AddBehavior(new WindBehavior() { Force = .(0.3f, 0, 0.1f) });
				sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = .Linear(.(0.3f, 0.3f), .(1.2f, 1.2f)) });
				sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.5f) });
				sys.AddBehavior(new RotationOverLifetimeBehavior());
				sys.AddBehavior(new VelocityIntegrationBehavior());
				mSmokeEffect.AddSystem(sys);
			}
			CreateParticleEntity(scene, resources, particleMgr, mSmokeEffect,
				"textures/kenney_particle-pack/PNG (Transparent)/smoke_07.png",
				"Smoke", .(-6, -1, -6));

			// --- Magic sparkles (additive, orbiting vortex) ---
			mMagicEffect = new ParticleEffect("Magic");
			{
				let sys = new ParticleSystem(400);
				sys.Emitter.SpawnRate = 60;
				sys.BlendMode = .Additive;
				sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(1.0f, 2.0f) });
				sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.8f, true) }); // surface only
				sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 0.5f, 0), Randomness = .(0.2f, 0.3f, 0.2f) });
				sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.15f, 0.15f), .(0.3f, 0.3f)) });
				sys.AddInitializer(new ColorInitializer() { Color = .Range(.(0.5f, 0.7f, 1.5f, 1), .(1.2f, 0.5f, 1.5f, 1)) }); // HDR bright
				sys.AddBehavior(new VortexBehavior() { Strength = 3.0f, Axis = .(0, 1, 0) });
				sys.AddBehavior(new DragBehavior() { Drag = 0.5f });
				sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.6f) });
				sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = .Linear(.(0.3f, 0.3f), .(0.05f, 0.05f)) });
				sys.AddBehavior(new VelocityIntegrationBehavior());
				mMagicEffect.AddSystem(sys);
			}
			CreateParticleEntity(scene, resources, particleMgr, mMagicEffect,
				"textures/kenney_particle-pack/PNG (Transparent)/star_04.png",
				"Magic", .(0, 0, -8));

			// --- Fire (additive, upward flames) ---
			mFireEffect = new ParticleEffect("Fire");
			{
				let sys = new ParticleSystem(800);
				sys.Emitter.SpawnRate = 120;
				sys.BlendMode = .Additive;
				sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.3f, 0.8f) });
				sys.AddInitializer(new PositionInitializer() { Shape = .Circle(0.15f) }); // tight base
				sys.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 2.0f, 0), Randomness = .(0.15f, 0.5f, 0.15f) }); // mostly upward
				sys.AddInitializer(new SizeInitializer() { Size = .Range(.(0.2f, 0.2f), .(0.35f, 0.35f)) });
				sys.AddInitializer(new ColorInitializer() { Color = .Constant(.(1, 0.9f, 0.5f, 1)) }); // bright yellow-white core
				sys.AddInitializer(new RotationInitializer());
				sys.AddBehavior(new GravityBehavior() { Multiplier = -0.3f, Direction = .(0, -1, 0) }); // buoyancy
				sys.AddBehavior(new DragBehavior() { Drag = 2.0f });
				sys.AddBehavior(new TurbulenceBehavior() { Strength = 0.8f, Frequency = 3.0f, Speed = 4.0f }); // subtle flicker

				// Color gradient: bright yellow-white core → orange → dark red → transparent
				var fireColor = ParticleCurveColor();
				fireColor.AddKey(0.0f, .(1.5f, 1.2f, 0.5f, 1));    // HDR bright yellow-white
				fireColor.AddKey(0.25f, .(1.2f, 0.5f, 0.05f, 1));   // orange
				fireColor.AddKey(0.6f, .(0.6f, 0.1f, 0.0f, 0.7f));  // dark red, fading
				fireColor.AddKey(1.0f, .(0.2f, 0.02f, 0.0f, 0.0f)); // nearly black, fully transparent
				sys.AddBehavior(new ColorOverLifetimeBehavior() { Curve = fireColor });

				// Grow slightly at base then shrink toward tip
				var fireSize = ParticleCurveVector2();
				fireSize.AddKey(0.0f, .(0.2f, 0.2f));
				fireSize.AddKey(0.15f, .(0.35f, 0.35f));
				fireSize.AddKey(1.0f, .(0.02f, 0.02f));
				sys.AddBehavior(new SizeOverLifetimeBehavior() { Curve = fireSize });

				sys.AddBehavior(new RotationOverLifetimeBehavior());
				sys.AddBehavior(new VelocityIntegrationBehavior());
				mFireEffect.AddSystem(sys);
			}
			CreateParticleEntity(scene, resources, particleMgr, mFireEffect,
				"textures/kenney_particle-pack/PNG (Transparent)/flame_06.png",
				"Fire", .(-6, -1, -12));

			// --- Comet trail (trail render mode demo) ---
			mTrailEffect = new ParticleEffect("Comet");
			{
				let sys = new ParticleSystem(50);
				sys.Emitter.SpawnRate = 8;
				sys.BlendMode = .Additive;
				sys.RenderMode = .Trail;
				sys.Trail = .()
				{
					Enabled = true,
					MaxPoints = 32,
					RecordInterval = 0.016f,
					Lifetime = 1.5f,
					WidthStart = 0.15f,
					WidthEnd = 0.0f,
					MinVertexDistance = 0.01f,
					UseParticleColor = true,
					TrailColor = .(1, 1, 1, 1)
				};
				sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(2.0f, 3.0f) });
				sys.AddInitializer(new PositionInitializer() { Shape = .Point() });
				sys.AddInitializer(new VelocityInitializer()
				{
					BaseVelocity = .Zero,
					ShapeDirectionSpeed = 3.0f,
					Shape = .Sphere(0.1f)
				});
				sys.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.12f, 0.12f)) });
				sys.AddInitializer(new ColorInitializer() { Color = .Range(.(0.5f, 0.8f, 1.5f, 1), .(1.5f, 0.5f, 1.0f, 1)) }); // HDR blue-purple
				sys.AddBehavior(new GravityBehavior() { Multiplier = 0.15f });
				sys.AddBehavior(new DragBehavior() { Drag = 0.3f });
				sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.4f) });
				sys.AddBehavior(new VelocityIntegrationBehavior());
				mTrailEffect.AddSystem(sys);
			}
			CreateParticleEntity(scene, resources, particleMgr, mTrailEffect,
				"textures/kenney_particle-pack/PNG (Transparent)/trace_05.png",
				"Comet", .(0, 1, -14));

			// --- Fireworks (sub-emitter demo: rocket → burst on death) ---
			mFireworksEffect = new ParticleEffect("Fireworks");
			{
				// System 0: Rockets — rise upward, short lifetime, trigger burst on death
				let rockets = new ParticleSystem(10);
				rockets.Emitter.Mode = .Burst;
				rockets.Emitter.BurstCount = 3;
				rockets.Emitter.BurstInterval = 2.0f;
				rockets.Emitter.BurstCycles = 0; // infinite
				rockets.BlendMode = .Additive;
				rockets.RenderMode = .Trail;
				rockets.Trail = .()
				{
					Enabled = true,
					MaxPoints = 24,
					RecordInterval = 0.02f,
					Lifetime = 0.8f,
					WidthStart = 0.06f,
					WidthEnd = 0.0f,
					MinVertexDistance = 0.01f,
					UseParticleColor = true,
					TrailColor = .(1, 1, 1, 1)
				};
				rockets.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.8f, 1.2f) });
				rockets.AddInitializer(new PositionInitializer() { Shape = .Circle(0.5f) });
				rockets.AddInitializer(new VelocityInitializer() { BaseVelocity = .(0, 8, 0), Randomness = .(1.5f, 2, 1.5f) });
				rockets.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.06f, 0.06f)) });
				rockets.AddInitializer(new ColorInitializer() { Color = .Constant(.(1.5f, 1.2f, 0.5f, 1)) }); // bright yellow
				rockets.AddBehavior(new GravityBehavior() { Multiplier = 0.4f });
				rockets.AddBehavior(new VelocityIntegrationBehavior());
				mFireworksEffect.AddSystem(rockets);

				// System 1: Burst sparks — triggered by rocket death
				let burst = new ParticleSystem(500);
				burst.Emitter.IsEmitting = false; // only spawns via sub-emitter
				burst.BlendMode = .Additive;
				burst.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.5f, 1.5f) });
				burst.AddInitializer(new PositionInitializer() { Shape = .Point() });
				burst.AddInitializer(new VelocityInitializer()
				{
					BaseVelocity = .Zero,
					ShapeDirectionSpeed = 5.0f,
					Shape = .Sphere(0.1f)
				});
				burst.AddInitializer(new SizeInitializer() { Size = .Range(.(0.06f, 0.06f), .(0.12f, 0.12f)) });
				burst.AddInitializer(new ColorInitializer() { Color = .Range(.(1.5f, 0.3f, 0.1f, 1), .(0.3f, 1.5f, 0.3f, 1)) }); // red-green mix
				burst.AddBehavior(new GravityBehavior() { Multiplier = 0.5f });
				burst.AddBehavior(new DragBehavior() { Drag = 1.0f });
				burst.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f, 0.3f) });
				burst.AddBehavior(new VelocityIntegrationBehavior());
				let burstIdx = mFireworksEffect.AddSystem(burst);

				// Link: rocket death → burst sparks
				var link = SubEmitterLink.Default();
				link.Trigger = .OnDeath;
				link.ChildSystemIndex = burstIdx;
				link.SpawnCount = 30;
				link.Probability = 1.0f;
				link.InheritPosition = true;
				mFireworksEffect.AddSubEmitterLink(link);
			}
			CreateParticleEntity(scene, resources, particleMgr, mFireworksEffect,
				"textures/kenney_particle-pack/PNG (Transparent)/spark_07.png",
				"Fireworks", .(8, -1, -8));
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
		scene.SetLocalTransform(spotLightEntity, Transform.CreateLookAt(.(2, 8, 2), .(0, -1, 0)));
		let spotLightHandle = lightMgr.CreateComponent(spotLightEntity);
		if (let light = lightMgr.Get(spotLightHandle))
		{
			light.Type = .Spot;
			light.Color = .(1.0f, 0.95f, 0.85f);
			light.Intensity = 20.0f;
			light.Range = 30.0f;
			light.InnerConeAngle = 25.0f;
			light.OuterConeAngle = 40.0f;
			light.CastsShadows = true;
			light.ShadowBias = 0.001f;
			light.ShadowNormalBias = 0.05f;
		}

		// Shadow-casting point light — sits near the scene, casts shadows in every
		// direction (6 cube-map faces). Good test for the point shadow code path.
		let pointLightEntity = scene.CreateEntity("ShadowPoint");
		scene.SetLocalTransform(pointLightEntity, .()
		{
			Position = .(-2.0f, 2.0f, 0.0f),
			Rotation = .Identity,
			Scale = .One
		});
		let pointLightHandle = lightMgr.CreateComponent(pointLightEntity);
		if (let light = lightMgr.Get(pointLightHandle))
		{
			light.Type = .Point;
			light.Color = .(1.0f, 0.7f, 0.4f); // warm orange
			light.Intensity = 15.0f;
			light.Range = 12.0f;
			light.CastsShadows = true;
			light.ShadowBias = 0.0005f;
			light.ShadowNormalBias = 2.0f;
		}

		// ==================== Camera ====================

		let cameraEntity = scene.CreateEntity("Camera");
		mCameraEntity = cameraEntity;
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

	/// Loads a decal texture and creates a decal entity projecting downward
	/// (local -Z axis in identity orientation) at the given world position.
	private void CreateDecal(Scene scene, ResourceSystem resources, StringView relativePath,
		Vector3 position, Vector3 size)
	{
		let fullPath = scope String();
		GetAssetPath(relativePath, fullPath);

		Image image = null;
		if (ImageLoaderFactory.LoadImage(fullPath) case .Ok(var loaded))
			image = loaded;
		else
		{
			Console.WriteLine(scope $"WARNING: Decal texture not found: {relativePath}");
			return;
		}

		let texRes = new TextureResource(image, true);
		resources.AddResource<TextureResource>(texRes);
		mSpriteTextures.Add(texRes); // reuse shutdown list

		let entity = scene.CreateEntity("Decal");
		// Rotate so local +Z (decal forward) points world -Y (downward).
		let rot = Quaternion.CreateFromAxisAngle(.(1, 0, 0), Math.PI_f * 0.5f);
		scene.SetLocalTransform(entity, .() { Position = position, Rotation = rot, Scale = .One });

		let decalMgr = scene.GetModule<DecalComponentManager>();
		let handle = decalMgr.CreateComponent(entity);
		if (let comp = decalMgr.Get(handle))
		{
			var texRef = ResourceRef(texRes.Id, "");
			defer texRef.Dispose();
			comp.SetTextureRef(texRef);
			comp.Size = size;
			comp.Color = .(1, 1, 1, 1);
		}
	}

	/// Creates a particle entity with the given effect and texture.
	private void CreateParticleEntity(Scene scene, ResourceSystem resources,
		ParticleComponentManager particleMgr, ParticleEffect effect,
		StringView texturePath, StringView entityName, Vector3 position)
	{
		let entity = scene.CreateEntity(entityName);
		scene.SetLocalTransform(entity, .() { Position = position, Rotation = .Identity, Scale = .One });

		let handle = particleMgr.CreateComponent(entity);
		if (let comp = particleMgr.Get(handle))
		{
			comp.SetEffect(effect);

			let fullPath = scope String();
			GetAssetPath(texturePath, fullPath);

			if (ImageLoaderFactory.LoadImage(fullPath) case .Ok(var image))
			{
				let texRes = new TextureResource(image, true);
				resources.AddResource<TextureResource>(texRes);
				mSpriteTextures.Add(texRes); // reuse shutdown list

				var texRef = ResourceRef(texRes.Id, "");
				defer texRef.Dispose();
				comp.SetTextureRef(texRef);
			}
		}
	}

	protected override void OnUpdate(float deltaTime)
	{
		// ==================== Camera Controls ====================
		// WASD = move, Q/E = down/up, mouse right-click drag = look,
		// Tab = toggle mouse capture, Shift = fast, Escape = exit.
		UpdateCamera(deltaTime);

		// ==================== Debug HUD ====================
		let rs = Context.GetSubsystem<RenderSubsystem>();
		if (rs == null) return;
		let dbg = rs.DebugDraw;
		if (dbg == null) return;

		// Smooth the FPS readout so it doesn't flicker every frame.
		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
		let fps = mFrameTimeMs > 0.001f ? 1000.0f / mFrameTimeMs : 0.0f;
		mFpsSmoothed = mFpsSmoothed * 0.9f + fps * 0.1f;

		// FPS counter + controls hint.
		dbg.DrawScreenRect(4, 4, 300, 34, .(0, 0, 0, 160));
		let fpsText = scope String();
		fpsText.AppendF("FPS {0:F0}  ({1:F2} ms)", mFpsSmoothed, mFrameTimeMs);
		dbg.DrawScreenText(8, 8, fpsText, .White);
		dbg.DrawScreenText(8, 20, "WASD=Move QE=Up/Down RMB=Look Tab=Capture Shift=Fast", .LightGray);

		// World-space axis indicator at the origin.
		dbg.DrawAxis(Matrix.Identity, 1.5f);

		// Particle system bounding boxes.
		DrawParticleBounds(dbg, mSparksEffect, .Yellow);
		DrawParticleBounds(dbg, mSmokeEffect, .LightGray);
		DrawParticleBounds(dbg, mMagicEffect, .Cyan);
		DrawParticleBounds(dbg, mFireEffect, .Red);
		DrawParticleBounds(dbg, mTrailEffect, .Blue);
		DrawParticleBounds(dbg, mFireworksEffect, .Magenta);
	}

	private void DrawParticleBounds(DebugDraw dbg, ParticleEffect effect, Color color)
	{
		if (effect == null) return;
		for (let system in effect.Systems)
		{
			if (system.AliveCount == 0) continue;
			let positions = system.Streams.Positions;
			if (positions == null) continue;

			var min = positions[0];
			var max = positions[0];
			for (int32 i = 1; i < system.AliveCount; i++)
			{
				let p = positions[i];
				min = Vector3.Min(min, p);
				max = Vector3.Max(max, p);
			}

			// Expand slightly for particle size
			let expand = Vector3(0.15f, 0.15f, 0.15f);
			dbg.DrawWireBox(BoundingBox(min - expand, max + expand), color);
		}
	}

	private void UpdateCamera(float deltaTime)
	{
		let keyboard = mShell.InputManager.Keyboard;
		let mouse = mShell.InputManager.Mouse;

		// Escape exits.
		if (keyboard.IsKeyPressed(.Escape))
		{
			Exit();
			return;
		}

		// Tab toggles mouse capture (continuous look without holding RMB).
		if (keyboard.IsKeyPressed(.Tab))
		{
			mMouseCaptured = !mMouseCaptured;
			mouse.RelativeMode = mMouseCaptured;
			mouse.Visible = !mMouseCaptured;
		}

		// Look: mouse delta → yaw/pitch when captured OR when right-click held.
		if (mMouseCaptured || mouse.IsButtonDown(.Right))
		{
			mYaw += mouse.DeltaX * 0.003f;
			mPitch -= mouse.DeltaY * 0.003f;
			mPitch = Math.Clamp(mPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);
		}

		// Movement: WASD + QE relative to the current yaw/pitch.
		let cosP = Math.Cos(mPitch);
		let forward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
		let right = Vector3.Normalize(Vector3.Cross(forward, .(0, 1, 0)));
		let speed = (keyboard.IsKeyDown(.LeftShift) ? 20.0f : 5.0f) * deltaTime;

		Vector3 move = .Zero;
		if (keyboard.IsKeyDown(.W)) move += forward;
		if (keyboard.IsKeyDown(.S)) move -= forward;
		if (keyboard.IsKeyDown(.D)) move += right;
		if (keyboard.IsKeyDown(.A)) move -= right;
		if (keyboard.IsKeyDown(.E)) move += .(0, 1, 0);
		if (keyboard.IsKeyDown(.Q)) move -= .(0, 1, 0);
		if (move.LengthSquared() > 0)
			mCameraPosition += Vector3.Normalize(move) * speed;

		// Update the camera entity's transform to reflect the fly-cam state.
		if (mScene != null)
		{
			let target = mCameraPosition + forward;
			mScene.SetLocalTransform(mCameraEntity, Transform.CreateLookAt(mCameraPosition, target));
		}
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
