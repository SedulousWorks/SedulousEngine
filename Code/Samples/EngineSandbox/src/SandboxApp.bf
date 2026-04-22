namespace EngineSandbox;

using System;
using Sedulous.Engine.App;
using Sedulous.Engine;
using Sedulous.Engine.Render;
using Sedulous.Engine.Core;
using Sedulous.Runtime;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Images.STB;
using Sedulous.Renderer.Passes;
using Sedulous.Renderer.Debug;
using Sedulous.Shell.Input;
using Sedulous.Models;
using Sedulous.Models.GLTF;
using Sedulous.Geometry.Tooling;
using Sedulous.Textures.Resources;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using System.Collections;
using Sedulous.Materials.Resources;
using Sedulous.Images.SDL;
using Sedulous.Particles;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Navigation;
using Sedulous.Audio;
using Sedulous.Audio.Decoders;
using Sedulous.Physics;

using Sedulous.Engine.UI;
using Sedulous.UI;
using Sedulous.Shell;
using Sedulous.Images;

class SandboxApp : EngineApplication
{
	// Smoothed frame-time stats for the FPS counter.
	private float mFpsSmoothed = 0.0f;
	private float mFrameTimeMs = 0.0f;

	// Screen UI elements.
	private Label mFpsLabel;
	private Label mControlsLabel;

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
	// Fox animation resources (registered with resource system, we hold refs)
	SkeletonResource mFoxSkeletonRes;
	AnimationClipResource mFoxWalkClipRes;

	PropertyAnimationClipResource mOrbitAnimRes;

	// Audio clips (decoded via AudioDecoderFactory)
	List<AudioClip> mOneShotClips = new .() ~ DeleteContainerAndItems!(_);
	int32 mOneShotIndex = 0;
	AudioClip mBgMusicClip ~ delete _;
	IAudioSource mBgMusicSource;

	// Navigation demo
	List<EntityHandle> mNavAgentEntities = new .() ~ delete _;
	Random mNavRandom = new .() ~ delete _;
	Vector3 mNavTarget;
	bool mHasNavTarget = false;
	List<float> mNavPathWaypoints = new .() ~ delete _;

	// Agent colors for nav mesh agents
	static Color[8] sNavAgentColors = .(
		Color(50, 200, 50, 255),
		Color(50, 100, 255, 255),
		Color(255, 200, 50, 255),
		Color(200, 50, 200, 255),
		Color(255, 100, 50, 255),
		Color(50, 200, 200, 255),
		Color(200, 50, 50, 255),
		Color(200, 200, 200, 255)
	);
	List<TextureResource> mFoxTextures = new .() ~ delete _;

	// Kenney character (animation graph demo)
	float mCharAnimTime = 0;
	AnimationGraph mCharGraph ~ delete _;
	SkinnedMeshResource mCharMeshRes;
	SkeletonResource mCharSkeletonRes;
	List<AnimationClipResource> mCharClipResources = new .() ~ delete _;
	List<TextureResource> mCharTextures = new .() ~ delete _;
	List<MaterialResource> mCharMaterialResources = new .() ~ delete _;

	// Sprite textures - held by the app so we release refs on shutdown.
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

		// Set up screen UI overlay.
		SetupScreenUI();

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let renderer = renderSub.RenderContext;
		let matSystem = renderer.MaterialSystem;

		// Create scene
		let scene = sceneSub.CreateScene("TestScene");
		mScene = scene;

		// Set up world-space UI panel demo.
		SetupWorldUI();

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

		let resources = ResourceSystem;

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

		let physicsMgr = scene.GetModule<PhysicsComponentManager>();

		// Ground plane - static physics body at Y=0 (plane shape passes through body origin)
		let planeEntity = scene.CreateEntity("Ground");
		scene.SetLocalTransform(planeEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, planeEntity, planeRef, mGrayMaterial);
		SetupRigidBody(scene, physicsMgr, planeEntity, .Plane(), .Static, 0);

		// Cube - dynamic, falls from height
		let cubeEntity = scene.CreateEntity("Cube");
		scene.SetLocalTransform(cubeEntity, .() { Position = .(-1.5f, 5, 0), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, cubeEntity, cubeRef, mRedMaterial);
		SetupRigidBody(scene, physicsMgr, cubeEntity, .Box(0.5f), .Dynamic);

		// Sphere - dynamic, falls from height
		let sphereEntity = scene.CreateEntity("Sphere");
		scene.SetLocalTransform(sphereEntity, .() { Position = .(1.5f, 6, 0), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, sphereEntity, sphereRef, mBlueMaterial);
		SetupRigidBody(scene, physicsMgr, sphereEntity, .Sphere(0.5f), .Dynamic);

		// Green cube (back left) - dynamic
		let cube2Entity = scene.CreateEntity("GreenCube");
		scene.SetLocalTransform(cube2Entity, .() { Position = .(-3.0f, 7, -2.0f), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, cube2Entity, cubeRef, mGreenMaterial);
		SetupRigidBody(scene, physicsMgr, cube2Entity, .Box(0.5f), .Dynamic);

		// Yellow cube (back right) - dynamic
		let cube3Entity = scene.CreateEntity("YellowCube");
		scene.SetLocalTransform(cube3Entity, .() { Position = .(3.0f, 4.5f, -2.0f), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, cube3Entity, cubeRef, mYellowMaterial);
		SetupRigidBody(scene, physicsMgr, cube3Entity, .Box(0.5f), .Dynamic);

		// White metallic sphere (center back) - dynamic, larger
		let sphere2Entity = scene.CreateEntity("MetalSphere");
		scene.SetLocalTransform(sphere2Entity, .() { Position = .(0, 8, -2.0f), Rotation = .Identity, Scale = .(1.5f, 1.5f, 1.5f) });
		SetupMeshComponent(scene, sphere2Entity, sphereRef, mWhiteMaterial);
		SetupRigidBody(scene, physicsMgr, sphere2Entity, .Sphere(0.75f), .Dynamic);

		// Small green sphere (front left) - dynamic
		let sphere3Entity = scene.CreateEntity("GreenSphere");
		scene.SetLocalTransform(sphere3Entity, .() { Position = .(-0.5f, 6.5f, 1.5f), Rotation = .Identity, Scale = .(0.6f, 0.6f, 0.6f) });
		SetupMeshComponent(scene, sphere3Entity, sphereRef, mGreenMaterial);
		SetupRigidBody(scene, physicsMgr, sphere3Entity, .Sphere(0.3f), .Dynamic);

		// Small yellow sphere (front right) - dynamic
		let sphere4Entity = scene.CreateEntity("YellowSphere");
		scene.SetLocalTransform(sphere4Entity, .() { Position = .(0.5f, 5.5f, 1.5f), Rotation = .Identity, Scale = .(0.6f, 0.6f, 0.6f) });
		SetupMeshComponent(scene, sphere4Entity, sphereRef, mYellowMaterial);
		SetupRigidBody(scene, physicsMgr, sphere4Entity, .Sphere(0.3f), .Dynamic);

		// Transparent sphere - dynamic
		let transparentEntity = scene.CreateEntity("TransparentSphere");
		scene.SetLocalTransform(transparentEntity, .() { Position = .(-1.0f, 9, 0.8f), Rotation = .Identity, Scale = .(1.2f, 1.2f, 1.2f) });
		SetupMeshComponent(scene, transparentEntity, sphereRef, mTransparentMaterial);
		SetupRigidBody(scene, physicsMgr, transparentEntity, .Sphere(0.6f), .Dynamic);

		// Masked cube - dynamic
		let maskedEntity = scene.CreateEntity("MaskedCube");
		scene.SetLocalTransform(maskedEntity, .() { Position = .(3.0f, 4, 1.0f), Rotation = .Identity, Scale = .One });
		SetupMeshComponent(scene, maskedEntity, cubeRef, mMaskedMaterial);
		SetupRigidBody(scene, physicsMgr, maskedEntity, .Box(0.5f), .Dynamic);

		// ==================== Sprites ====================
		// Load a few animal icons from the Kenney pack and spawn sprites exercising
		// all three billboard orientation modes.
		{
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/rabbit.png",
				.(-4.0f, 1.2f, 2.0f), .(1.2f, 1.2f), .CameraFacing);
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/bear.png",
				.( 0.0f, 2.6f, 2.0f), .(1.2f, 1.2f), .CameraFacingY);
			CreateSprite(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/chicken.png",
				.( 4.0f, 1.2f, 2.0f), .(1.2f, 1.2f), .WorldAligned);
		}

		// ==================== Decal ====================
		// Projects a Kenney animal icon downward onto the ground plane.
		CreateDecal(scene, resources, "textures/kenney_animal-pack-remastered/PNG/Round/panda.png",
			.(0.0f, 0.5f, 2.5f), .(3.0f, 3.0f, 3.0f));

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
				"Sparks", .(6, 0, -6));

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
				"Smoke", .(-6, 0, -6));

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

				// Color gradient: bright yellow-white core -> orange -> dark red -> transparent
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
				"Fire", .(-6, 0, -12));

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

			// --- Fireworks (sub-emitter demo: rocket -> burst on death) ---
			mFireworksEffect = new ParticleEffect("Fireworks");
			{
				// System 0: Rockets - rise upward, short lifetime, trigger burst on death
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

				// System 1: Burst sparks - triggered by rocket death
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

				// Link: rocket death -> burst sparks
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
				"Fireworks", .(8, 0, -8));
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
				// Register skeleton as a resource
				let skeleton = importResult.Skeletons[0];
				importResult.Skeletons[0] = null;
				mFoxSkeletonRes = new SkeletonResource(skeleton, true);
				resources.AddResource<SkeletonResource>(mFoxSkeletonRes);

				// Register first animation clip as a resource
				if (importResult.Animations.Count > 0)
				{
					let clip = importResult.Animations[0];
					importResult.Animations[0] = null;
					mFoxWalkClipRes = new AnimationClipResource(clip, true);
					resources.AddResource<AnimationClipResource>(mFoxWalkClipRes);
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

				// Create fox entity
				let foxEntity = scene.CreateEntity("Fox");
				scene.SetLocalTransform(foxEntity, .()
				{
					Position = .(-3, 0, 2),
					Rotation = .Identity,
					Scale = .(0.02f, 0.02f, 0.02f)
				});

				// Skeletal animation component - drives bone matrices via resource refs
				let skelAnimMgr = scene.GetModule<SkeletalAnimationComponentManager>();
				let animHandle = skelAnimMgr.CreateComponent(foxEntity);
				if (let animComp = skelAnimMgr.Get(animHandle))
				{
					var skelRef = ResourceRef(mFoxSkeletonRes.Id, .());
					defer skelRef.Dispose();
					animComp.SetSkeletonRef(skelRef);

					if (mFoxWalkClipRes != null)
					{
						var clipRef = ResourceRef(mFoxWalkClipRes.Id, .());
						defer clipRef.Dispose();
						animComp.SetClipRef(clipRef);
					}
					animComp.Loop = true;
					animComp.AutoPlay = true;
				}

				// Skinned mesh component - renders the mesh, reads bone matrices from animation component
				let skinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
				let compHandle = skinnedMgr.CreateComponent(foxEntity);
				if (let comp = skinnedMgr.Get(compHandle))
				{
					comp.SetMeshRef(foxMeshRef);

					// Set material refs by slot - resolver creates instances and prepares bind groups
					for (int32 slot = 0; slot < mFoxMaterialResources.Count; slot++)
					{
						var matRef = ResourceRef(mFoxMaterialResources[slot].Id, .());
						comp.SetMaterialRef(slot, matRef);
						matRef.Dispose();
					}
				}

				Console.WriteLine("Fox loaded: {0} vertices, {1} bones, {2} anims, {3} materials, {4} textures",
					skinnedMesh.VertexCount, skeleton.BoneCount,
					importResult.Animations.Count, importResult.Materials.Count, importResult.Textures.Count);
			}
		}
		else
		{
			Console.WriteLine("WARNING: Could not load Fox model");
		}

		// ==================== Property Animation ====================
		// A sphere that floats around the edge of the ground plane,
		// demonstrating PropertyAnimationComponent with Transform.Position tracks.
		{
			let propAnimClip = new PropertyAnimationClip("OrbitPath", 12.0f, true);

			// Trace a rectangular path around the plane at Y=1.5
			let posTrack = propAnimClip.AddVector3Track("Transform.Position");
			let edge = 12.0f; // near edge of 30x30 plane (half = 15)
			let height = 1.5f;
			posTrack.AddKeyframe(0.0f, .( edge, height, edge));      // front-right
			posTrack.AddKeyframe(3.0f, .(-edge, height, edge));      // front-left
			posTrack.AddKeyframe(6.0f, .(-edge, height, -edge));     // back-left
			posTrack.AddKeyframe(9.0f, .( edge, height, -edge));     // back-right
			posTrack.AddKeyframe(12.0f, .( edge, height, edge));     // back to start

			mOrbitAnimRes = new PropertyAnimationClipResource(propAnimClip, true);
			resources.AddResource<PropertyAnimationClipResource>(mOrbitAnimRes);

			let orbitEntity = scene.CreateEntity("OrbitSphere");
			scene.SetLocalTransform(orbitEntity, .() { Position = .(edge, height, edge), Rotation = .Identity, Scale = .(0.8f, 0.8f, 0.8f) });
			SetupMeshComponent(scene, orbitEntity, sphereRef, mYellowMaterial);

			let propAnimMgr = scene.GetModule<PropertyAnimationComponentManager>();
			let propHandle = propAnimMgr.CreateComponent(orbitEntity);
			if (let propComp = propAnimMgr.Get(propHandle))
			{
				var clipRef = ResourceRef(mOrbitAnimRes.Id, .());
				defer clipRef.Dispose();
				propComp.SetClipRef(clipRef);
				propComp.Loop = true;
				propComp.AutoPlay = true;
			}
		}

		// ==================== Animation Graph Demo ====================
		// Kenney character with idle/walk state machine driven by Speed parameter.
		{
			let charPath = scope String();
			GetAssetPath("samples/models/kenney_platformer-kit/Models/GLB format/character-oopi.glb", charPath);

			let charModel = scope Model();
			if (ModelLoaderFactory.LoadModel(charPath, charModel) case .Ok)
			{
				let importOpts = ModelImportOptions.SkinnedWithAnimations();
				let importer = scope ModelImporter(importOpts);
				let importResult = importer.Import(charModel);
				defer delete importResult;

				if (importResult.SkinnedMeshes.Count > 0 && importResult.Skeletons.Count > 0)
				{
					// Register skeleton
					let charSkeleton = importResult.Skeletons[0];
					importResult.Skeletons[0] = null;
					mCharSkeletonRes = new SkeletonResource(charSkeleton, true);
					resources.AddResource<SkeletonResource>(mCharSkeletonRes);

					// Register skinned mesh
					let charMesh = importResult.SkinnedMeshes[0];
					mCharMeshRes = new SkinnedMeshResource(charMesh, true);
					importResult.SkinnedMeshes[0] = null;
					resources.AddResource<SkinnedMeshResource>(mCharMeshRes);
					var charMeshRef = ResourceRef(mCharMeshRes.Id, .());
					defer charMeshRef.Dispose();

					// Register all animation clips (resource takes ownership)
					Dictionary<StringView, AnimationClip> clipsByName = scope .();
					for (int32 clipIdx = 0; clipIdx < importResult.Animations.Count; clipIdx++)
					{
						let clip = importResult.Animations[clipIdx];
						if (clip != null)
						{
							clipsByName[clip.Name] = clip;
							let clipRes = new AnimationClipResource(clip, true);
							importResult.Animations[clipIdx] = null; // resource owns it now
							resources.AddResource<AnimationClipResource>(clipRes);
							mCharClipResources.Add(clipRes);
						}
					}

					// Register textures and materials
					for (let importedTex in importResult.Textures)
					{
						let texRes = TextureResourceConverter.Convert(importedTex);
						if (texRes != null)
						{
							resources.AddResource<TextureResource>(texRes);
							mCharTextures.Add(texRes);
						}
					}
					for (let importedMat in importResult.Materials)
					{
						let matRes = MaterialResourceConverter.Convert(importedMat, mCharTextures);
						if (matRes != null)
						{
							resources.AddResource<MaterialResource>(matRes);
							mCharMaterialResources.Add(matRes);
						}
					}

					// Build animation graph: Idle <-> Walk (Speed parameter)
					let idleClip = clipsByName.GetValueOrDefault("idle");
					let walkClip = clipsByName.GetValueOrDefault("walk");

					if (idleClip != null && walkClip != null)
					{
						mCharGraph = new AnimationGraph();
						let speedIdx = mCharGraph.AddParameter("Speed", .Float);

						let baseLayer = new AnimationLayer("Base");
						let idleState = baseLayer.AddState(new AnimationGraphState("Idle",
							new ClipStateNode(idleClip), ownsNode: true));
						let walkState = baseLayer.AddState(new AnimationGraphState("Walk",
							new ClipStateNode(walkClip), ownsNode: true));
						baseLayer.DefaultStateIndex = idleState;

						// Idle -> Walk (Speed > 0.1)
						let toWalk = new AnimationGraphTransition();
						toWalk.SourceStateIndex = idleState;
						toWalk.DestStateIndex = walkState;
						toWalk.Duration = 0.2f;
						toWalk.AddFloatCondition(speedIdx, .Greater, 0.1f);
						baseLayer.AddTransition(toWalk);

						// Walk -> Idle (Speed <= 0.1)
						let toIdle = new AnimationGraphTransition();
						toIdle.SourceStateIndex = walkState;
						toIdle.DestStateIndex = idleState;
						toIdle.Duration = 0.2f;
						toIdle.AddFloatCondition(speedIdx, .LessEqual, 0.1f);
						baseLayer.AddTransition(toIdle);

						mCharGraph.AddLayer(baseLayer);

						// Create character entity
						let charEntity = scene.CreateEntity("KenneyCharacter");
						scene.SetLocalTransform(charEntity, .()
						{
							Position = .(5, 0, 4),
							Rotation = .Identity,
							Scale = .One
						});

						// Animation graph component
						let graphAnimMgr = scene.GetModule<AnimationGraphComponentManager>();
						let graphHandle = graphAnimMgr.CreateComponent(charEntity);
						if (let graphComp = graphAnimMgr.Get(graphHandle))
						{
							// Set skeleton + graph directly (not via resource ref - graph is built programmatically)
							graphComp.Skeleton = charSkeleton;
							graphComp.Graph = mCharGraph;
						}

						// Skinned mesh component
						let charSkinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
						let charMeshHandle = charSkinnedMgr.CreateComponent(charEntity);
						if (let charComp = charSkinnedMgr.Get(charMeshHandle))
						{
							charComp.SetMeshRef(charMeshRef);
							for (int32 slot = 0; slot < mCharMaterialResources.Count; slot++)
							{
								var matRef = ResourceRef(mCharMaterialResources[slot].Id, .());
								charComp.SetMaterialRef(slot, matRef);
								matRef.Dispose();
							}
						}

						// Cycle Speed parameter so the character alternates idle/walk
						// (done in OnUpdate via graph player parameter)

						Console.WriteLine("Kenney character loaded: {0} anims, idle/walk graph",
							importResult.Animations.Count);
					}
				}
			}
			else
			{
				Console.WriteLine("WARNING: Could not load Kenney character model");
			}
		}

		// ==================== Navigation ====================
		// Build a navmesh from the ground plane and spawn crowd agents.
		// 1=add agent, 2=remove agent, left-click=move target
		{
			let navSub = Context.GetSubsystem<NavigationSubsystem>();
			let navWorld = navSub?.GetNavWorld(scene);
			if (navWorld != null)
			{
				// Build navmesh from ground plane geometry
				let navVerts = scope List<float>();
				let navTris = scope List<int32>();

				// Ground plane (thin box at Y=0, matching the 30×30 visual mesh)
				AddNavBoxGeometry(navVerts, navTris, .(0, -0.05f, 0), .(15, 0.05f, 15));

				let geometry = scope InputGeometry(
					Span<float>(navVerts.Ptr, navVerts.Count),
					Span<int32>(navTris.Ptr, navTris.Count));

				var config = NavMeshBuildConfig.Default;
				config.CellSize = 0.3f;
				config.CellHeight = 0.2f;
				config.AgentRadius = 0.5f;
				config.AgentHeight = 1.8f;
				config.AgentMaxClimb = 0.9f;
				config.AgentMaxSlope = 45.0f;

				// Build single-tile navmesh and set on the NavWorld
				let buildResult = NavMeshBuilder.BuildSingle(geometry, config);
				let buildOk = (buildResult != null && buildResult.Success && buildResult.NavMesh != null);
				if (buildOk)
				{
					let mesh = buildResult.NavMesh;
					buildResult.NavMesh = null; // transfer ownership to NavWorld
					navWorld.SetNavMesh(mesh);
				}
				defer { if (buildResult != null) delete buildResult; }

				if (buildOk)
				{
					// Spawn initial nav agents with visible sphere meshes
					let navMgr = scene.GetModule<NavigationComponentManager>();
					if (navMgr != null)
					{
						Vector3[3] startPositions = .(.(-5, 0, -5), .(5, 0, 5), .(0, 0, -8));
						for (int32 i = 0; i < 3; i++)
							SpawnNavAgent(scene, navMgr, startPositions[i], sphereRef);
					}

					Console.WriteLine("Navigation ready: 1=add agent, 2=remove, left-click=move");
				}
				else
				{
					Console.WriteLine("WARNING: NavMesh build failed");
				}
			}
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

		// Shadow-casting spot light - high above and angled toward the scene.
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

		// Shadow-casting point light - sits near the scene, casts shadows in every
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

		// Audio listener on camera
		let listenerMgr = scene.GetModule<AudioListenerComponentManager>();
		if (listenerMgr != null)
			listenerMgr.CreateComponent(cameraEntity);

		// ==================== Audio ====================
		{
			let audioSub = Context.GetSubsystem<AudioSubsystem>();
			if (audioSub != null)
			{
				let decoder = scope AudioDecoderFactory();
				decoder.RegisterDefaultDecoders();

				// Background music - decode via AudioDecoderFactory (handles 24-bit WAV)
				// and play as a looping source
				let musicPath = scope String();
				GetAssetPath("samples/audio/background/eyeless.wav", musicPath);
				if (decoder.DecodeFile(musicPath) case .Ok(let clip))
				{
					mBgMusicClip = clip;
					mBgMusicSource = audioSub.AudioSystem.CreateSource();
					mBgMusicSource.Loop = true;
					mBgMusicSource.Volume = 0.15f;
					mBgMusicSource.Play(clip);
					Console.WriteLine("Background music started");
				}
				else
				{
					Console.WriteLine("WARNING: Failed to decode background music");
				}

				// Decode RPG clips from OGG for one-shot demo (M key cycles through them)
				StringView[6] rpgClipNames = .(
					"chop.ogg", "bookOpen.ogg", "cloth1.ogg",
					"doorOpen_1.ogg", "metalClick.ogg", "handleCoins.ogg"
				);

				for (let clipName in rpgClipNames)
				{
					let clipPath = scope String();
					GetAssetPath(scope $"samples/audio/kenney_rpg-audio/Audio/{clipName}", clipPath);
					if (decoder.DecodeFile(clipPath) case .Ok(let rpgClip))
						mOneShotClips.Add(rpgClip);
				}

				Console.WriteLine(scope $"Audio initialized: {mOneShotClips.Count} SFX clips (M = play next)");
			}
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
				if (let skyPass = renderSub.GetPipeline(mScene).GetPass<SkyPass>())
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

	/// Adds a RigidBodyComponent to an entity.
	private void SetupRigidBody(Scene scene, PhysicsComponentManager physicsMgr,
		EntityHandle entity, ShapeConfig shape, BodyType bodyType, uint16 layer = 1)
	{
		let handle = physicsMgr.CreateComponent(entity);
		if (let comp = physicsMgr.Get(handle))
		{
			comp.Shape = shape;
			comp.BodyType = bodyType;
			comp.CollisionLayer = layer;
			comp.Restitution = 0.3f;
			// Body is created automatically in OnComponentInitialized
			// (called by Scene.InitializePendingComponents before FixedUpdate)
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
		// Add world UI content once component is initialized.
		TryAddWorldUIContent();

		// ==================== UI Debug ====================
		let uiSub = Context.GetSubsystem<EngineUISubsystem>();

		// F1 toggles UI debug bounds overlay.
		if (mShell.InputManager.Keyboard.IsKeyPressed(.F1) && uiSub?.UIContext != null)
			uiSub.UIContext.DebugSettings.ShowBounds = !uiSub.UIContext.DebugSettings.ShowBounds;

		// ==================== Camera Controls ====================
		// Block camera mouse input when UI has the mouse.
		let uiHovered = uiSub?.IsMouseOverUI ?? false;
		UpdateCamera(deltaTime, uiHovered);

		// ==================== Debug HUD ====================
		let rs = Context.GetSubsystem<RenderSubsystem>();
		if (rs == null) return;
		let dbg = rs.DebugDraw;
		if (dbg == null) return;

		// Smooth the FPS readout so it doesn't flicker every frame.
		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
		let fps = mFrameTimeMs > 0.001f ? 1000.0f / mFrameTimeMs : 0.0f;
		mFpsSmoothed = mFpsSmoothed * 0.9f + fps * 0.1f;

		// Update screen UI FPS label.
		if (mFpsLabel != null)
		{
			let fpsText = scope String();
			fpsText.AppendF("FPS {0:F0}  ({1:F2} ms)", mFpsSmoothed, mFrameTimeMs);
			mFpsLabel.SetText(fpsText);
		}

		// World-space axis indicator at the origin.
		dbg.DrawAxis(Matrix.Identity, 1.5f);

		// M key: play next RPG sound effect
		if (mShell.InputManager.Keyboard.IsKeyPressed(.M) && mOneShotClips.Count > 0)
		{
			let audioSub = Context.GetSubsystem<AudioSubsystem>();
			if (audioSub != null)
			{
				audioSub.PlayOneShot(mOneShotClips[mOneShotIndex], 0.8f);
				mOneShotIndex = (mOneShotIndex + 1) % (int32)mOneShotClips.Count;
			}
		}

		// Navigation: 1=add agent, 2=remove, left-click=move target
		if (mScene != null)
		{
			let keyboard = mShell.InputManager.Keyboard;
			let mouse = mShell.InputManager.Mouse;
			let navMgr = mScene.GetModule<NavigationComponentManager>();

			if (navMgr != null)
			{
				// Add agent at random position with mesh
				if (keyboard.IsKeyPressed(.Num1))
				{
					let x = ((float)mNavRandom.NextDouble() - 0.5f) * 20.0f;
					let z = ((float)mNavRandom.NextDouble() - 0.5f) * 20.0f;
					var agentMeshRef = ResourceRef(mSphereRes.Id, .());
					defer agentMeshRef.Dispose();
					SpawnNavAgent(mScene, navMgr, .(x, 0, z), agentMeshRef);
				}

				// Remove last agent
				if (keyboard.IsKeyPressed(.Num2) && mNavAgentEntities.Count > 0)
				{
					let entity = mNavAgentEntities.PopBack();
					mScene.DestroyEntity(entity);
				}

				// Left-click: move all agents to mouse cursor ground hit
				if (mouse.IsButtonPressed(.Left) && !mMouseCaptured && !uiHovered)
				{
					// Build view-projection matrix from camera state
					let cosP = Math.Cos(mPitch);
					let camForward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
					let camTarget = mCameraPosition + camForward;
					let viewMatrix = Matrix.CreateLookAt(mCameraPosition, camTarget, .(0, 1, 0));
					let aspect = (float)rs.GetPipeline(mScene).OutputWidth / (float)rs.GetPipeline(mScene).OutputHeight;
					let projMatrix = Matrix.CreatePerspectiveFieldOfView(60.0f * (Math.PI_f / 180.0f), aspect, 0.1f, 100.0f);
					let viewProj = viewMatrix * projMatrix;

					// Unproject mouse position to ray
					let ndcX = (2.0f * mouse.X / (float)rs.GetPipeline(mScene).OutputWidth) - 1.0f;
					let ndcY = 1.0f - (2.0f * mouse.Y / (float)rs.GetPipeline(mScene).OutputHeight);

					Matrix invVP = .Identity;
					if (Matrix.TryInvert(viewProj, out invVP))
					{
						var nearWorld = Vector4.Transform(Vector4(ndcX, ndcY, 0, 1), invVP);
						var farWorld = Vector4.Transform(Vector4(ndcX, ndcY, 1, 1), invVP);

						if (Math.Abs(nearWorld.W) > 0.0001f && Math.Abs(farWorld.W) > 0.0001f)
						{
							let nearPos = Vector3(nearWorld.X, nearWorld.Y, nearWorld.Z) / nearWorld.W;
							let farPos = Vector3(farWorld.X, farWorld.Y, farWorld.Z) / farWorld.W;
							let rayDir = farPos - nearPos;

					if (Math.Abs(rayDir.Y) > 0.001f)
					{
						let t = -nearPos.Y / rayDir.Y;
						if (t > 0)
						{
							let hitPos = nearPos + rayDir * t;
							mNavTarget = Vector3(Math.Clamp(hitPos.X, -14, 14), 0, Math.Clamp(hitPos.Z, -14, 14));
							mHasNavTarget = true;

							for (let agentEntity in mNavAgentEntities)
							{
								let agentComp = navMgr.GetForEntity(agentEntity);
								if (agentComp != null)
									agentComp.MoveTarget = mNavTarget;
							}

							// Update path from first agent to target
							let navSub = Context.GetSubsystem<NavigationSubsystem>();
							let navWorld = navSub?.GetNavWorld(mScene);
							if (navWorld != null && mNavAgentEntities.Count > 0)
							{
								float[3] agentPos = ?;
								let firstAgent = navMgr.GetForEntity(mNavAgentEntities[0]);
								if (firstAgent != null && firstAgent.IsOnCrowd)
								{
									navWorld.Crowd.GetAgentPosition(firstAgent.CrowdAgentIndex, out agentPos);
									float[3] targetArr = .(mNavTarget.X, mNavTarget.Y, mNavTarget.Z);
									navWorld.FindPath(agentPos, targetArr, mNavPathWaypoints);
								}
							}
						}
					}
						} // nearWorld.W check
					} // invVP
				} // mouse left click

				// Draw target marker (cross + circle on ground)
				if (mHasNavTarget)
				{
					let targetColor = Color(255, 255, 255, 200);
					let p = mNavTarget + .(0, 0.05f, 0);
					// Cross
					dbg.DrawLine(p + .(-0.3f, 0, 0), p + .(0.3f, 0, 0), targetColor);
					dbg.DrawLine(p + .(0, 0, -0.3f), p + .(0, 0, 0.3f), targetColor);
					dbg.DrawWireSphere(p, 0.15f, targetColor);
				}

				// Draw path on the ground
				if (mNavPathWaypoints.Count >= 6)
				{
					let pathColor = Color(0, 255, 100, 200);
					for (int32 i = 0; i + 5 < (int32)mNavPathWaypoints.Count; i += 3)
					{
						let from = Vector3(mNavPathWaypoints[i], mNavPathWaypoints[i + 1] + 0.1f, mNavPathWaypoints[i + 2]);
						let to = Vector3(mNavPathWaypoints[i + 3], mNavPathWaypoints[i + 4] + 0.1f, mNavPathWaypoints[i + 5]);
						dbg.DrawLine(from, to, pathColor);
					}
				}

				// Draw agents as colored wireframe capsules (cylinder body + sphere top)
				for (int32 i = 0; i < (int32)mNavAgentEntities.Count; i++)
				{
					let agentPos = mScene.GetWorldMatrix(mNavAgentEntities[i]).Translation;
					let color = sNavAgentColors[i % 8];
					let halfH = 0.9f; // half agent height
					let r = 0.5f;     // agent radius

					// Vertical body lines
					dbg.DrawLine(agentPos + .(r, 0, 0), agentPos + .(r, halfH * 2, 0), color);
					dbg.DrawLine(agentPos + .(-r, 0, 0), agentPos + .(-r, halfH * 2, 0), color);
					dbg.DrawLine(agentPos + .(0, 0, r), agentPos + .(0, halfH * 2, r), color);
					dbg.DrawLine(agentPos + .(0, 0, -r), agentPos + .(0, halfH * 2, -r), color);

					// Bottom and top circles
					dbg.DrawWireSphere(agentPos + .(0, 0.05f, 0), r, color, 12);
					dbg.DrawWireSphere(agentPos + .(0, halfH * 2, 0), r, color, 12);

					// Velocity direction arrow
					let agentComp = navMgr.GetForEntity(mNavAgentEntities[i]);
					if (agentComp != null && agentComp.IsOnCrowd && navMgr.NavWorld?.Crowd != null)
					{
						float[3] vel = ?;
						navMgr.NavWorld.Crowd.GetAgentVelocity(agentComp.CrowdAgentIndex, out vel);
						let speed = Math.Sqrt(vel[0] * vel[0] + vel[2] * vel[2]);
						if (speed > 0.1f)
						{
							let arrowStart = agentPos + .(0, halfH, 0);
							let arrowEnd = arrowStart + Vector3(vel[0], 0, vel[2]) * 0.4f;
							dbg.DrawLine(arrowStart, arrowEnd, Color(255, 255, 0, 255));
						}
					}
				}
			}
		}

		// Cycle the Kenney character's Speed parameter on the graph PLAYER
		// (idle <-> walk every ~3 seconds via sin wave)
		if (mScene != null && mCharGraph != null)
		{
			let graphMgr = mScene.GetModule<AnimationGraphComponentManager>();
			if (graphMgr != null)
			{
				for (let comp in graphMgr.ActiveComponents)
				{
					if (comp.GraphPlayer != null)
					{
						mCharAnimTime += deltaTime;
						let cycle = Math.Sin(mCharAnimTime * 1.0f);
						comp.GraphPlayer.SetFloat("Speed", (cycle > 0) ? 1.0f : 0.0f);
					}
				}
			}
		}

		// Particle system bounding boxes.
		DrawParticleBounds(dbg, mSparksEffect, .Yellow);
		DrawParticleBounds(dbg, mSmokeEffect, .LightGray);
		DrawParticleBounds(dbg, mMagicEffect, .Cyan);
		DrawParticleBounds(dbg, mFireEffect, .Red);
		DrawParticleBounds(dbg, mTrailEffect, .Blue);
		DrawParticleBounds(dbg, mFireworksEffect, .Magenta);

		// Physics debug shapes.
		DrawPhysicsDebug(dbg);
	}

	private void DrawPhysicsDebug(DebugDraw dbg)
	{
		if (mScene == null) return;
		let physicsMgr = mScene.GetModule<PhysicsComponentManager>();
		if (physicsMgr == null || physicsMgr.PhysicsWorld == null) return;

		let world = physicsMgr.PhysicsWorld;
		let debugColor = Color(0, 255, 0, 180);

		for (let comp in physicsMgr.ActiveComponents)
		{
			if (!comp.IsActive || !comp.PhysicsBody.IsValid) continue;

			let pos = world.GetBodyPosition(comp.PhysicsBody);
			let rot = world.GetBodyRotation(comp.PhysicsBody);

			switch (comp.Shape.Type)
			{
			case .Box:
				DrawWireBoxOriented(dbg, pos, rot, comp.Shape.HalfExtents, debugColor);
			case .Sphere:
				dbg.DrawWireSphere(pos, comp.Shape.Radius, debugColor);
			case .Capsule:
				dbg.DrawWireSphere(pos, comp.Shape.Radius, debugColor);
			case .Cylinder:
				DrawWireBoxOriented(dbg, pos, rot, .(comp.Shape.Radius, comp.Shape.HalfHeight, comp.Shape.Radius), debugColor);
			case .Plane:
				dbg.DrawWireBox(BoundingBox(pos - .(5, 0.01f, 5), pos + .(5, 0.01f, 5)), debugColor);
			}
		}
	}

	/// Draws a wireframe box with position and rotation applied.
	private void DrawWireBoxOriented(DebugDraw dbg, Vector3 center, Quaternion rotation, Vector3 halfExtents, Color color)
	{
		// 8 local-space corners of the box
		Vector3[8] locals = .(
			.(-halfExtents.X, -halfExtents.Y, -halfExtents.Z),
			.( halfExtents.X, -halfExtents.Y, -halfExtents.Z),
			.( halfExtents.X,  halfExtents.Y, -halfExtents.Z),
			.(-halfExtents.X,  halfExtents.Y, -halfExtents.Z),
			.(-halfExtents.X, -halfExtents.Y,  halfExtents.Z),
			.( halfExtents.X, -halfExtents.Y,  halfExtents.Z),
			.( halfExtents.X,  halfExtents.Y,  halfExtents.Z),
			.(-halfExtents.X,  halfExtents.Y,  halfExtents.Z)
		);

		// Transform to world space
		Vector3[8] corners = .();
		for (int i = 0; i < 8; i++)
			corners[i] = center + Vector3.Transform(locals[i], rotation);

		// Draw 12 edges
		// Bottom face
		dbg.DrawLine(corners[0], corners[1], color);
		dbg.DrawLine(corners[1], corners[2], color);
		dbg.DrawLine(corners[2], corners[3], color);
		dbg.DrawLine(corners[3], corners[0], color);
		// Top face
		dbg.DrawLine(corners[4], corners[5], color);
		dbg.DrawLine(corners[5], corners[6], color);
		dbg.DrawLine(corners[6], corners[7], color);
		dbg.DrawLine(corners[7], corners[4], color);
		// Vertical edges
		dbg.DrawLine(corners[0], corners[4], color);
		dbg.DrawLine(corners[1], corners[5], color);
		dbg.DrawLine(corners[2], corners[6], color);
		dbg.DrawLine(corners[3], corners[7], color);
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

	private void UpdateCamera(float deltaTime, bool uiHovered = false)
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

		// Look: mouse delta -> yaw/pitch when captured OR when right-click held.
		// Skip when UI has the mouse (unless captured).
		if (mMouseCaptured || (mouse.IsButtonDown(.Right) && !uiHovered))
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

	private void SetupWorldUI()
	{
		if (mScene == null) return;

		let uiMgr = mScene.GetModule<UIComponentManager>();
		if (uiMgr == null) return;

		// Create an entity with a world-space UI panel.
		let entity = mScene.CreateEntity("WorldUI");
		mScene.SetLocalTransform(entity, .() {
			Position = .(2, 2.5f, 0),
			Rotation = .Identity,
			Scale = .One
		});

		// Create UIComponent.
		let handle = uiMgr.CreateComponent(entity);
		if (let comp = uiMgr.Get(handle))
		{
			comp.PixelWidth = 256;
			comp.PixelHeight = 256;
			comp.WorldWidth = 2.0f;
			comp.WorldHeight = 2.0f;
		}

		// Second world UI - camera-facing billboard (like a nameplate).
		let billboard = mScene.CreateEntity("WorldUI_Billboard");
		mScene.SetLocalTransform(billboard, .() {
			Position = .(-2, 3, 0),
			Rotation = .Identity,
			Scale = .One
		});

		let billboardHandle = uiMgr.CreateComponent(billboard);
		if (let comp2 = uiMgr.Get(billboardHandle))
		{
			comp2.PixelWidth = 200;
			comp2.PixelHeight = 64;
			comp2.WorldWidth = 1.5f;
			comp2.WorldHeight = 0.5f;
			comp2.Orientation = .CameraFacing;
		}

		// UIComponent is now pending init. On next frame, UIComponentManager
		// will create the RootView, VGContext, VGRenderer, and texture.
		// We add UI content after init - defer to OnUpdate or use a callback.
		// For demo: we'll add content on first update when Root becomes available.
	}

	/// Add UI content to world panels once they're initialized.
	private int mWorldUIContentCount;

	private void TryAddWorldUIContent()
	{
		if (mScene == null) return;

		let uiMgr = mScene.GetModule<UIComponentManager>();
		if (uiMgr == null) return;

		for (let comp in uiMgr.ActiveComponents)
		{
			if (comp.Root == null) continue; // Not initialized yet.
			if (comp.Root.ChildCount > 1) continue; // Already has content (1 = PopupLayer only).

			if (comp.Orientation == .WorldAligned)
				AddWorldPanelContent(comp);
			else
				AddBillboardContent(comp);

			mWorldUIContentCount++;
		}
	}

	private void AddWorldPanelContent(UIComponent comp)
	{
		let panel = new Panel();
		panel.Background = new ColorDrawable(.(30, 35, 50, 220));
		panel.Padding = .(8, 8, 8, 8);
		panel.ClipsContent = true;
		comp.Root.AddView(panel, new LayoutParams() {
			Width = LayoutParams.MatchParent,
			Height = LayoutParams.MatchParent
		});

		let layout = new LinearLayout();
		layout.Orientation = .Vertical;
		layout.Spacing = 4;
		panel.AddView(layout, new LayoutParams() {
			Width = LayoutParams.MatchParent,
			Height = LayoutParams.MatchParent
		});

		let title = new Label();
		title.SetText("World UI Panel");
		title.FontSize = 16;
		title.HAlign = .Center;
		layout.AddView(title, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 24
		});

		let info = new Label();
		info.SetText("Rendered to texture");
		info.FontSize = 12;
		info.HAlign = .Center;
		layout.AddView(info, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 16
		});

		let info2 = new Label();
		info2.SetText("Displayed as sprite");
		info2.FontSize = 12;
		info2.HAlign = .Center;
		layout.AddView(info2, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 16
		});

		let btn = new Button();
		btn.SetText("World Button");
		btn.OnClick.Add(new (b) => {
			info.SetText("Clicked!");
			comp.MarkDirty();
		});
		layout.AddView(btn, new LinearLayout.LayoutParams() {
			Width = LayoutParams.MatchParent, Height = 28
		});

		comp.MarkDirty();
	}

	private void AddBillboardContent(UIComponent comp)
	{
		let panel = new Panel();
		panel.Background = new ColorDrawable(.(20, 20, 20, 180));
		panel.Padding = .(6, 4, 6, 4);
		comp.Root.AddView(panel, new LayoutParams() {
			Width = LayoutParams.MatchParent,
			Height = LayoutParams.MatchParent
		});

		let label = new Label();
		label.SetText("NPC Nameplate");
		label.FontSize = 14;
		label.HAlign = .Center;
		label.VAlign = .Middle;
		label.TextColor = .(255, 220, 100, 255);
		panel.AddView(label, new LayoutParams() {
			Width = LayoutParams.MatchParent,
			Height = LayoutParams.MatchParent
		});

		comp.MarkDirty();
	}

	private void SetupScreenUI()
	{
		let uiSub = Context.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView == null) return;

		let root = uiSub.ScreenView.Root;

		// Absolute layout for HUD overlay - doesn't interfere with 3D.
		let hud = new AbsoluteLayout();
		hud.IsHitTestVisible = false; // Layout is not a hit target - children (panel, button) are.
		root.AddView(hud, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		// Translucent background panel for the HUD info.
		let hudPanel = new Panel();
		hudPanel.Background = new ColorDrawable(.(0, 0, 0, 140));
		hudPanel.Padding = .(8, 6, 8, 6);
		hud.AddView(hudPanel, new AbsoluteLayout.LayoutParams() { X = 4, Y = 4, Width = 420, Height = 70 });

		let hudLayout = new LinearLayout();
		hudLayout.Orientation = .Vertical;
		hudLayout.Spacing = 2;
		hudPanel.AddView(hudLayout, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		// FPS label.
		mFpsLabel = new Label();
		mFpsLabel.SetText("FPS --");
		mFpsLabel.FontSize = 14;
		hudLayout.AddView(mFpsLabel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 18 });

		// Controls hint.
		mControlsLabel = new Label();
		mControlsLabel.SetText("WASD=Move QE=Up/Down RMB=Look Tab=Capture Shift=Fast M=SFX");
		mControlsLabel.FontSize = 11;
		hudLayout.AddView(mControlsLabel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 14 });

		// Test button to confirm input works.
		let btn = new Button();
		btn.SetText("Click Me");
		btn.OnClick.Add(new (b) =>
		{
			mControlsLabel.SetText("Button clicked!");
		});
		hudLayout.AddView(btn, new LinearLayout.LayoutParams() { Width = 100, Height = 24 });
	}

	protected override void OnCleanup()
	{
	}

	protected override void OnShutdown()
	{
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let device = renderSub.RenderContext.Device;

		// Clear sky texture reference before destroying
		if (let skyPass = renderSub.GetPipeline(mScene).GetPass<SkyPass>())
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

		// Release our refs on mesh/animation resources (resource system holds its own)
		mPlaneRes?.ReleaseRef();
		mCubeRes?.ReleaseRef();
		mSphereRes?.ReleaseRef();
		mFoxMeshRes?.ReleaseRef();
		mFoxSkeletonRes?.ReleaseRef();
		mFoxWalkClipRes?.ReleaseRef();
		mOrbitAnimRes?.ReleaseRef();

		// Kenney character cleanup
		mCharMeshRes?.ReleaseRef();
		mCharSkeletonRes?.ReleaseRef();
		for (let clipRes in mCharClipResources)
			clipRes?.ReleaseRef();
		for (let charTex in mCharTextures)
			charTex?.ReleaseRef();
		for (let charMat in mCharMaterialResources)
			charMat?.ReleaseRef();

		Console.WriteLine("=== EngineSandbox OnShutdown ===");
	}

	// ==================== Navigation Helpers ====================

	/// Spawns a nav agent entity with a visible sphere mesh and nav component.
	private void SpawnNavAgent(Scene scene, NavigationComponentManager navMgr, Vector3 position, ResourceRef meshRef)
	{
		let agentEntity = scene.CreateEntity("NavAgent");
		scene.SetLocalTransform(agentEntity, .() { Position = position, Rotation = .Identity, Scale = .One });

		// Visible sphere mesh
		SetupMeshComponent(scene, agentEntity, meshRef, mGreenMaterial);

		// Nav agent component
		let agentHandle = navMgr.CreateComponent(agentEntity);
		if (let agentComp = navMgr.Get(agentHandle))
		{
			agentComp.Radius = 0.5f;
			agentComp.Height = 1.8f;
			agentComp.MaxSpeed = 3.0f;
			agentComp.MaxAcceleration = 8.0f;
		}

		mNavAgentEntities.Add(agentEntity);
	}

	private static void AddNavBoxGeometry(List<float> vertices, List<int32> triangles, Vector3 center, Vector3 halfExtents)
	{
		let baseIndex = (int32)(vertices.Count / 3);
		let min = center - halfExtents;
		let max = center + halfExtents;

		// 8 vertices
		void AddV(float x, float y, float z) { vertices.Add(x); vertices.Add(y); vertices.Add(z); }
		AddV(min.X, min.Y, min.Z);
		AddV(max.X, min.Y, min.Z);
		AddV(max.X, max.Y, min.Z);
		AddV(min.X, max.Y, min.Z);
		AddV(min.X, min.Y, max.Z);
		AddV(max.X, min.Y, max.Z);
		AddV(max.X, max.Y, max.Z);
		AddV(min.X, max.Y, max.Z);

		// 12 triangles (2 per face)
		void AddT(int32 a, int32 b, int32 c) { triangles.Add(a); triangles.Add(b); triangles.Add(c); }
		AddT(baseIndex + 0, baseIndex + 1, baseIndex + 2);
		AddT(baseIndex + 0, baseIndex + 2, baseIndex + 3);
		AddT(baseIndex + 5, baseIndex + 4, baseIndex + 7);
		AddT(baseIndex + 5, baseIndex + 7, baseIndex + 6);
		AddT(baseIndex + 3, baseIndex + 6, baseIndex + 2);
		AddT(baseIndex + 3, baseIndex + 7, baseIndex + 6);
		AddT(baseIndex + 4, baseIndex + 1, baseIndex + 5);
		AddT(baseIndex + 4, baseIndex + 0, baseIndex + 1);
		AddT(baseIndex + 1, baseIndex + 5, baseIndex + 6);
		AddT(baseIndex + 1, baseIndex + 6, baseIndex + 2);
		AddT(baseIndex + 4, baseIndex + 0, baseIndex + 3);
		AddT(baseIndex + 4, baseIndex + 3, baseIndex + 7);
	}
}
