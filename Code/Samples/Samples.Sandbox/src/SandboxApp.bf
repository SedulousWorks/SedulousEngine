using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Animation;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Render;
using Sedulous.Extensions.Imgui;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Materials;
using Sedulous.Model.Resource;
using Sedulous.Particles;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Texture;
using Sedulous.Texture.Resource;
using Sedulous.Texture.Pipeline;
using Samples.Common;
using cimgui_Beef;

namespace Samples.Sandbox;

/// The running dev harness: as much of the renderer as will fit in one scene, drawn SPLIT
/// SCREEN through an offscreen target.
///
/// Split screen and offscreen on purpose. Two views prove the multi view path and the per view
/// debug draw; rendering to a sampleable target rather than straight to the swapchain is the
/// shape an editor viewport has, so a regression there shows up here rather than in the editor.
class SandboxApp : DefaultApplication
{
	private const int32 cGridSide = 16;
	private const float cGridSpacing = 0.8f;
	private const float cFloorY = 0.0f;
	private const float cBoxSize = 2.5f;
	private const float cBallRadius = 1.25f;

	private Scene mScene = null;
	private EntityHandle mCamera = default;
	private EntityHandle mFloorEntity = default;
	private EntityHandle mKeyLight = default;
	private EntityHandle mProbeEntity = default;
	private EntityHandle mGraphCharacter = default;
	private EntityHandle mCampfireEntity = default;

	private List<EntityHandle> mCubes = new .() ~ delete _;
	private List<EntityHandle> mPointLights = new .() ~ delete _;
	private List<Float3> mLightBases = new .() ~ delete _;

	/// Everything the scene borrows and this owns.
	private List<StaticMesh> mMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<Material> mMaterials = new .() ~ DeleteContainerAndItems!(_);
	private List<AnimationGraph> mGraphs = new .() ~ DeleteContainerAndItems!(_);
	private ParticleEffect mCampfire = new .() ~ delete _;

	private ContentStack mContent = new .() ~ delete _;
	private Texture mLogo = null;
	private CutoutTexture mCutout = null ~ delete _;
	private OffscreenTargets mOffscreen = new .() ~ delete _;
	private ImguiSubsystem mOverlay = null ~ delete _;

	private InputRouter mRouter = null ~ delete _;
	private InputSurface mSurfaceLeft = null ~ delete _;
	private InputSurface mSurfaceRight = null ~ delete _;

	private FlyCamera mFlyLeft = .();
	private FlyCamera mFlyRight = .();

	private float mFloorMetallic = 0.0f;
	private float mFloorRoughness = 0.45f;
	private float mKeyPitch = -1.05f;
	private float mKeyYaw = 0.35f;
	private float mAngle = 0.0f;
	private float mFpsSmoothed = 0.0f;
	private bool mShowDebugDraw = true;

	/// Uncapped, so the readout is the real cost rather than the display's refresh.
	public override RenderWindowDesc MainRenderWindow
	{
		get
		{
			RenderWindowDesc desc = .();
			desc.PresentMode = .Immediate;
			return desc;
		}
	}

	public override void Configure(IApplicationHost host)
	{
		base.Configure(host);

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			mOverlay = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight);
			host.Context.RegisterSubsystem<ImguiSubsystem>(mOverlay);
		}
	}

	public override void OnStartup(IApplicationHost host)
	{
		base.OnStartup(host);

		mScene = PrimaryScenes.CreateScene("sandbox");
		mFlyLeft.Position = .(-6.0f, 21.0f, 30.0f);
		mFlyLeft.Pitch = -0.45f;
		mFlyRight.Position = .(6.0f, 21.0f, 30.0f);
		mFlyRight.Pitch = -0.45f;

		ApplyEnvironment();
		LoadSkySources(host);
		BuildCamera();
		BuildProps(host);
		BuildLights();
		BuildProbes();
		LoadContent(host);
		BuildParticleDemo();

		Console.WriteLine("Sandbox: split screen, so click a half to fly its camera. The right");
		Console.WriteLine("button looks in the hovered half. G cycles the character's graph.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		if (mOverlay != null)
		{
			mOverlay.NewFrame((host.Shell != null) ? host.Shell.Input : null, deltaTime);
			BuildDebugUI(host.Context.GetSubsystem<RenderSubsystem>());
		}

		let input = (host.Shell != null) ? host.Shell.Input : null;
		let window = (host.Shell != null) ? host.Shell.MainWindow : null;
		if ((input != null) && (window != null))
			UpdateInputRouting(input, window);

		// Each camera is driven by its SURFACE's gated devices, so it only moves while the
		// pointer is over that half.
		if (mSurfaceLeft != null)
			mFlyLeft.Update(mSurfaceLeft.Keyboard, mSurfaceLeft.Mouse, deltaTime);
		if (mSurfaceRight != null)
			mFlyRight.Update(mSurfaceRight.Keyboard, mSurfaceRight.Mouse, deltaTime);

		// The global keys still read the raw keyboard: they belong to the application rather
		// than to either viewport.
		if ((input != null) && (input.Keyboard != null))
		{
			if (!HandleKeys(host, input.Keyboard))
				return;
		}

		if (mScene == null)
			return;

		AnimateScene(deltaTime);
		DrawDebug(host, deltaTime);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		let render = host.Context.GetSubsystem<RenderSubsystem>();
		let graphics = host.Graphics;
		if ((mScene == null) || (render == null) || !render.IsReady || (graphics == null)
			|| (graphics.Raw == null) || (frame.Encoder == null) || (frame.Backbuffer == null)
			|| (frame.Window == null))
		{
			return;
		}

		let device = graphics.Raw;
		let format = frame.Window.Swap.Format;
		uint32 slot = (frame.FrameIndex < OffscreenTargets.cSlots) ? frame.FrameIndex : 0;
		if (!mOffscreen.Ensure(device, format, frame.Width, frame.Height, slot))
			return;

		let target = mOffscreen.Texture(slot);
		let targetView = mOffscreen.View(slot);

		uint32 halfWidth = frame.Width / 2;
		let aspect = (float)halfWidth / (float)frame.Height;

		CameraOverride left = .();
		left.Camera = MakeCamera(mFlyLeft, aspect);
		left.ClearColor = .(0.02f, 0.02f, 0.03f, 1.0f);

		CameraOverride right = .();
		right.Camera = MakeCamera(mFlyRight, aspect);
		right.ClearColor = .(0.02f, 0.02f, 0.03f, 1.0f);

		// Both views draw into the SAME offscreen texture, each into its own viewport slice.
		// The graph leaves it in CopySrc, which the blit then reads.
		TargetState state = .(target, mOffscreen.State(slot), .CopySrc);
		render.BeginRendering(frame.Encoder, frame.FrameIndex);
		render.RenderScene(mScene, targetView, format, frame.Width, frame.Height,
			.(0, 0, halfWidth, frame.Height), &left, state);
		render.RenderScene(mScene, targetView, format, frame.Width, frame.Height,
			.((int32)halfWidth, 0, (uint32)(frame.Width - halfWidth), frame.Height), &right, state);
		render.EndRendering();
		mOffscreen.SetState(slot, .CopySrc);

		frame.Encoder.TransitionTexture(frame.Backbuffer, .RenderTarget, .CopyDst);
		frame.Encoder.Blit(target, frame.Backbuffer);
		frame.Encoder.TransitionTexture(frame.Backbuffer, .CopyDst, .RenderTarget);

		// The backbuffer is a render target again, so the panel loads and draws over it.
		if (mOverlay != null)
			mOverlay.Render(ref frame);
	}

	public override void OnShutdown(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (device != null)
		{
			device.WaitIdle(); // the GPU has to be done before any of this goes back
			mOffscreen.Release(device);
			if (mCutout != null)
				mCutout.Release();
		}

		base.OnShutdown(host);
		Console.WriteLine("Sandbox: shutting down.");
	}

	private ViewCamera MakeCamera(FlyCamera fly, float aspect)
	{
		ViewCamera camera = .();
		camera.View = Float4x4.LookAtRH(fly.Position, fly.Position + fly.Forward,
			.(0.0f, 1.0f, 0.0f));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, aspect, 0.1f, 1000.0f);
		camera.Position = fly.Position;
		camera.FarZ = 1000.0f;
		return camera;
	}

	private bool HandleKeys(IApplicationHost host, IKeyboard keyboard)
	{
		if (keyboard.IsKeyPressed(.Escape))
		{
			host.RequestExit(0);
			return false;
		}

		if (keyboard.IsKeyPressed(.G))
			FireGraphNext();
		if (keyboard.IsKeyPressed(.F5))
			CycleSkyMode();
		if (keyboard.IsKeyPressed(.F6))
			ToggleProbeParallax();

		return true;
	}

	// ---- the scene ----

	private void ApplyEnvironment()
	{
		let environments = mScene.GetSystem<EnvironmentSystem>();
		if (environments == null)
			return;

		let settings = environments.Environment;
		settings.AmbientColor = .(0.12f, 0.16f, 0.28f, 1.0f); // the flat fallback, with IBL off
		settings.AmbientIntensity = 0.35f;
		settings.SkyMode = .Procedural;
		settings.SkyIntensity = 0.7f; // a dimmer sky, so the IBL ambient is not washed out
		settings.SkyHorizon = .(0.62f, 0.70f, 0.85f, 1.0f);
		settings.SkyZenith = .(0.18f, 0.34f, 0.68f, 1.0f);
		settings.SkyGround = .(0.28f, 0.26f, 0.24f, 1.0f);
		settings.SunIntensity = 1.0f;
	}

	/// Loads the two textured sky sources up front so F5 can cycle onto them. Either one
	/// missing simply leaves that mode showing nothing.
	private void LoadSkySources(IApplicationHost host)
	{
		let render = host.Context.GetSubsystem<RenderSubsystem>();
		if (render == null)
			return;

		// Under one, because the procedural sky and its IBL are bright enough that the tone
		// mapper washes out at the default.
		render.Exposure = 0.5f;

		let hdrPath = scope String();
		if (SampleContent.FindFile(SandboxPaths.cHdrSky, hdrPath))
		{
			let image = scope Image();
			if ((ImageIO.LoadImage(hdrPath, image) case .Ok) && (image.Format == .RGBA32F))
			{
				let pixels = image.PixelData;
				let floats = Span<float>((float*)pixels.Ptr, pixels.Length / sizeof(float));
				render.SetSkyEquirect(image.Width, image.Height, floats);
				Console.WriteLine(scope $"Sandbox: loaded the HDR sky {image.Width}x{image.Height}");
			}
			else
			{
				Console.WriteLine(scope $"Sandbox: could not read the HDR sky at {hdrPath}");
			}
		}

		// One face names the set: the rest are detected from its naming rather than listed.
		let facePath = scope String();
		if (!SampleContent.FindFile(SandboxPaths.cCubemapFace, facePath))
			return;

		let faces = scope List<String>();
		defer { ClearAndDeleteItems!(faces); }
		if (!(CubemapFaces.Detect(facePath, faces) case .Ok) || (faces.Count != 6))
			return;

		let faceViews = scope StringView[6];
		for (int i < 6)
			faceViews[i] = faces[i];

		let cube = scope List<uint8>();
		if (TextureImporter.LoadCubemap(faceViews, cube, let faceSize) case .Ok)
		{
			render.SetSkyCubemap(faceSize, cube);
			Console.WriteLine(scope $"Sandbox: loaded the cubemap sky {faceSize}x{faceSize} x6");
		}
	}

	private void BuildCamera()
	{
		mCamera = mScene.CreateEntity("camera");
		mScene.SetLocalPosition(mCamera, .(0.0f, 21.0f, 30.0f));

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.48f);
		mScene.SetLocalTransform(mCamera, transform);

		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera).ClearColor = .(0.02f, 0.02f, 0.03f, 1.0f);
	}

	private void BuildProps(IApplicationHost host)
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		mFloorEntity = mScene.CreateEntity("floor");
		mScene.SetLocalPosition(mFloorEntity, .(0.0f, 0.0f, 0.0f));
		{
			let mesh = meshes.Add(mFloorEntity);
			mesh.Mesh.SetDirect(Track(Primitives.Plane(120.0f, 120.0f)));
		}
		ApplyFloorMaterial();

		let cube = Track(Primitives.Cube(0.35f));
		BuildGrid(meshes, cube, -8.0f, true);
		BuildGrid(meshes, cube, 8.0f, false);

		// A row resting EXACTLY on the floor: the grids float, so without these there is
		// nothing to judge shadow contact against.
		{
			let boxMesh = Track(Primitives.Cube(cBoxSize));
			let material = Track(MaterialPresets.CreatePbr("lit", .(0.85f, 0.55f, 0.2f, 1.0f),
				0.0f, 0.5f));
			for (int32 k < 4)
			{
				let entity = mScene.CreateEntity("floorBox");
				mScene.SetLocalPosition(entity, .(-7.5f + 5.0f * k, cFloorY + cBoxSize * 0.5f,
					10.0f));
				let mesh = meshes.Add(entity);
				mesh.Mesh.SetDirect(boxMesh);
				mesh.SetMaterial(material);
			}
		}

		let ball = Track(Primitives.Sphere(cBallRadius, 24, 12));

		// Fully metallic with roughness climbing across the row, so the probe reflection goes
		// from mirror sharp to blurry: the GGX prefilter, as a row you can walk along.
		for (int32 k < 4)
		{
			let material = Track(MaterialPresets.CreatePbr("lit", .(0.90f, 0.90f, 0.92f, 1.0f),
				1.0f, 0.05f + 0.18f * k));
			let entity = mScene.CreateEntity("floorBall");
			mScene.SetLocalPosition(entity, .(-7.5f + 5.0f * k, cFloorY + cBallRadius, 16.0f));
			let mesh = meshes.Add(entity);
			mesh.Mesh.SetDirect(ball);
			mesh.SetMaterial(material);
		}

		// Alpha blended: routed to the transparent category, sorted back to front, depth tested
		// without writing. Well off to the left so they do not sit inside the probe box.
		{
			let glass = Track(MaterialPresets.CreatePbr("lit", .(0.35f, 0.6f, 0.95f, 0.4f), 0.0f,
				0.12f));
			glass.Pipeline.BlendMode = .AlphaBlend;
			glass.Pipeline.DepthMode = .ReadOnly;
			for (int32 k < 3)
			{
				let entity = mScene.CreateEntity("glassBall");
				mScene.SetLocalPosition(entity, .(-26.0f, cFloorY + 6.0f + 3.0f * k, 16.0f));
				let mesh = meshes.Add(entity);
				mesh.Mesh.SetDirect(ball);
				mesh.SetMaterial(glass);
			}
		}

		BuildMaskedBalls(host, meshes, ball);
	}

	/// Alpha tested against a cutout texture, so the spheres render with real holes rather than
	/// merely looking see through.
	private void BuildMaskedBalls(IApplicationHost host, MeshComponentManager meshes,
		StaticMesh ball)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (device == null)
			return;

		mCutout = new CutoutTexture(device);
		if (mCutout.View == null)
			return;

		let material = Track(MaterialPresets.CreatePbr("lit", .(0.95f, 0.8f, 0.3f, 1.0f), 0.0f,
			0.45f));
		material.Pipeline.BlendMode = .Masked;
		material.SetDefaultTexture("AlbedoMap", mCutout.View);

		for (int32 k < 3)
		{
			let entity = mScene.CreateEntity("maskedBall");
			mScene.SetLocalPosition(entity, .(-5.0f + 5.0f * k, cFloorY + 3.5f, 24.0f));
			let mesh = meshes.Add(entity);
			mesh.Mesh.SetDirect(ball);
			mesh.SetMaterial(material);
		}
	}

	private void BuildLights()
	{
		let lights = mScene.GetSystem<LightComponentManager>();
		if (lights == null)
			return;

		mKeyLight = mScene.CreateEntity("keyLight");
		ApplyKeyLightDirection();
		{
			let light = lights.Add(mKeyLight);
			light.Type = .Directional;
			light.Color = .(0.4f, 0.5f, 0.7f, 1.0f);
			light.Intensity = 0.5f;
			light.CastsShadows = true;
		}

		// A FIELD of point lights over the floor: the clustered culling demo. A fragment only
		// evaluates the lights in its froxel, which is what makes eighteen of them cheap.
		const int32 cColumns = 6;
		const int32 cRows = 3;
		for (int32 j < cRows)
		{
			for (int32 i < cColumns)
			{
				let fi = (float)i / (cColumns - 1);
				let fj = (float)j / (cRows - 1);
				let position = Float3(-15.0f + 30.0f * fi, 5.5f, -2.0f + 16.0f * fj);

				let entity = mScene.CreateEntity("pointLight");
				mScene.SetLocalPosition(entity, position);

				let light = lights.Add(entity);
				light.Type = .Point;
				light.Color = .(0.4f + 0.6f * fi, 0.4f + 0.6f * fj, 1.0f - 0.6f * fi, 1.0f);
				light.Intensity = 14.0f;
				light.Range = 8.0f;

				mPointLights.Add(entity);
				mLightBases.Add(position);
			}
		}

		// A spot overhead, aimed down between the box and sphere rows: its cone casts sharp
		// shadows into the local atlas, which is a different path from the directional cascades.
		{
			let entity = mScene.CreateEntity("spotLight");
			mScene.SetLocalPosition(entity, .(0.0f, 14.0f, 13.0f));
			var transform = mScene.GetLocalTransform(entity);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -1.5f);
			mScene.SetLocalTransform(entity, transform);

			let light = lights.Add(entity);
			light.Type = .Spot;
			light.Color = .(1.0f, 0.92f, 0.78f, 1.0f); // warm, against the blue key
			light.Intensity = 120.0f;
			light.Range = 30.0f;
			light.InnerAngle = 0.55f;
			light.OuterAngle = 0.75f;
			light.CastsShadows = true;
			light.ShadowUpdate = .Static; // a static scene, so the atlas layer is cached
		}

		// A shadow casting POINT light among the props: six atlas faces casting radially.
		{
			let entity = mScene.CreateEntity("shadowPoint");
			mScene.SetLocalPosition(entity, .(4.0f, 5.0f, 13.0f));

			let light = lights.Add(entity);
			light.Type = .Point;
			light.Color = .(0.5f, 1.0f, 0.6f, 1.0f);
			light.Intensity = 28.0f;
			light.Range = 16.0f;
			light.CastsShadows = true;
		}
	}

	/// TWO probes with an overlap between them. Each captures from its own centre, so their
	/// reflections differ, and a fragment in the overlap blends them by influence.
	private void BuildProbes()
	{
		let probes = mScene.GetSystem<ReflectionProbeComponentManager>();
		if (probes == null)
			return;

		mProbeEntity = mScene.CreateEntity("reflectionProbeL");
		mScene.SetLocalPosition(mProbeEntity, .(-8.0f, 6.0f, 16.0f));
		{
			let probe = probes.Add(mProbeEntity);
			probe.HalfExtents = .(12.0f, 12.0f, 14.0f);
			probe.BlendDistance = 4.0f;
			probe.Update = .Realtime;
		}

		let right = mScene.CreateEntity("reflectionProbeR");
		mScene.SetLocalPosition(right, .(8.0f, 6.0f, 16.0f));
		{
			let probe = probes.Add(right);
			probe.HalfExtents = .(12.0f, 12.0f, 14.0f);
			probe.BlendDistance = 4.0f;
			probe.Update = .Realtime;
		}
	}

	/// Two cube grids that spin every frame. The left shares ONE material, so it collapses into
	/// a single instanced draw with the per instance colour supplying each hue; the right gives
	/// every cube its own, which is what trips the parallel emit path.
	private void BuildGrid(MeshComponentManager meshes, StaticMesh cube, float originX,
		bool instanced)
	{
		Material shared = null;
		if (instanced)
			shared = Track(MaterialPresets.CreatePbr("lit", .(1.0f, 1.0f, 1.0f, 1.0f), 0.0f, 0.4f));

		for (int32 y < cGridSide)
		{
			for (int32 x < cGridSide)
			{
				let entity = mScene.CreateEntity("cube");
				let fx = (float)x - (cGridSide - 1) * 0.5f;
				let fy = (float)y - (cGridSide - 1) * 0.5f;
				mScene.SetLocalPosition(entity, .(originX + fx * cGridSpacing,
					fy * cGridSpacing + 7.0f, 0.0f));

				let baseColor = Float4((float)x / (cGridSide - 1), (float)y / (cGridSide - 1),
					0.6f, 1.0f);

				let mesh = meshes.Add(entity);
				mesh.Mesh.SetDirect(cube);
				if (instanced)
				{
					mesh.SetMaterial(shared);
					mesh.Color = .(baseColor.X, baseColor.Y, baseColor.Z, 1.0f);
				}
				else
				{
					// Roughness sweeps across X and the top half is metallic, so one grid
					// covers the whole PBR matrix.
					let roughness = 0.05f + 0.95f * (float)x / (cGridSide - 1);
					let metallic = (y >= cGridSide / 2) ? 1.0f : 0.0f;
					mesh.SetMaterial(Track(MaterialPresets.CreatePbr("lit", baseColor, metallic,
						roughness)));
					mesh.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
				}

				mCubes.Add(entity);
			}
		}
	}

	/// A campfire with spark trails, sharing the frame with meshes, shadows, occlusion and
	/// probes. The dedicated showcase runs particles alone; this is where a regression that
	/// only appears in the MIX shows up.
	private void BuildParticleDemo()
	{
		let emitters = mScene.GetSystem<ParticleEffectComponentManager>();
		if (emitters == null)
			return;

		{
			let system = mCampfire.AddSystem(5000);
			system.Name.Set("campfire");
			system.BlendMode = .Additive;
			system.RenderMode = .Billboard;
			system.Emitter.Mode = .Continuous;
			system.Emitter.SpawnRate = 700.0f;
			system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.35f);
			system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.9f, 1.8f);
			{
				let velocity = system.AddInitializer<VelocityInitializer>();
				velocity.BaseVelocity = .(0.0f, 3.2f, 0.0f);
				velocity.Randomness = .(0.8f, 0.8f, 0.8f);
			}
			system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.5f, 0.5f));
			system.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.55f, 0.15f, 1.0f),
				.(1.0f, 0.8f, 0.35f, 1.0f));
			system.AddBehavior<ColorOverLifetimeBehavior>().Curve =
				.FadeAlpha(.(1.0f, 0.45f, 0.1f, 1.0f), 0.3f);
			system.AddBehavior<SizeOverLifetimeBehavior>().Curve =
				.Linear(.(0.55f, 0.55f), .(0.08f, 0.08f));
		}

		{
			let system = mCampfire.AddSystem(600);
			system.Name.Set("campfire-sparks");
			system.RenderMode = .Trail;
			system.BlendMode = .Additive;
			system.Emitter.Mode = .Continuous;
			system.Emitter.SpawnRate = 16.0f;
			system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.2f);
			system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.8f);
			{
				let velocity = system.AddInitializer<VelocityInitializer>();
				velocity.BaseVelocity = .(0.0f, 5.0f, 0.0f);
				velocity.Randomness = .(2.5f, 1.5f, 2.5f);
			}
			system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.12f, 0.12f));
			system.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.7f, 0.2f, 1.0f),
				.(1.0f, 0.45f, 0.1f, 1.0f));
			system.AddBehavior<GravityBehavior>().Multiplier = 0.9f;
		}

		mCampfireEntity = mScene.CreateEntity("campfire");
		mScene.SetLocalPosition(mCampfireEntity, .(-10.0f, 0.2f, 8.0f));
		emitters.Add(mCampfireEntity);
		emitters.SetEffect(mCampfireEntity, mCampfire);
	}

	// ---- the cooked content ----

	private void LoadContent(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (!mContent.Open(SandboxPaths.cOutputDir, device))
			return;

		let modelDir = scope String();
		if (SampleContent.FindDirectory(SandboxPaths.cModelDir, modelDir))
		{
			SpawnModel("Duck", scope $"{modelDir}/Duck/glTF/Duck.gltf", .(-5.0f, 3.0f, 6.0f));
			SpawnModel("Fox", scope $"{modelDir}/Fox/glTF/Fox.gltf", .(5.0f, 0.0f, 6.0f));
			// The character runs off a GRAPH rather than one clip, so G cross fades it to the
			// next state instead of merely restarting it.
			SpawnModel("Char", scope $"{modelDir}/QuaterniusCharacter/glTF/Character.gltf",
				.(0.0f, 0.0f, 12.0f), true);
		}
		else
		{
			Console.WriteLine(scope $"Sandbox: no models at {SandboxPaths.cModelDir}");
		}

		let imageDir = scope String();
		if (SampleContent.FindDirectory(SandboxPaths.cImageDir, imageDir))
			mLogo = mContent.CookTexture("logo.tex", imageDir, SandboxPaths.cLogoImage);

		SpawnSpriteDemo();
		SpawnDecalDemo();
	}

	private void SpawnModel(StringView prefix, StringView path, Float3 position,
		bool useGraph = false)
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if ((meshes == null) || !mContent.IsOpen)
			return;

		let model = mContent.CookModel(prefix, path);
		if (model == null)
			return;

		// Models come in wildly different unit scales (the Duck is about a hundred units, the
		// Fox a hundred and fifty), so the root scales the largest extent to a target size.
		const float cTargetSize = 6.0f;
		let extent = model.BoundsMax - model.BoundsMin;
		let largest = Math.Max(extent.X, Math.Max(extent.Y, extent.Z));
		let fit = (largest > 0.0001f) ? (cTargetSize / largest) : 1.0f;

		let root = mScene.CreateEntity(prefix);
		var rootTransform = Transform();
		rootTransform.Position = position;
		rootTransform.Scale = .(fit, fit, fit);
		mScene.SetLocalTransform(root, rootTransform);

		let materials = scope List<Material>();
		for (var material in ref model.Materials)
		{
			if (material.Get != null)
				materials.Add(material.Get);
		}

		let entities = scope List<EntityHandle>();
		let skinned = scope List<EntityHandle>();

		for (let node in model.Nodes)
		{
			let entity = mScene.CreateEntity(node.Name);
			mScene.SetLocalTransform(entity, node.LocalTransform);
			entities.Add(entity);
		}

		for (int i < model.Nodes.Count)
		{
			let node = model.Nodes[i];
			if ((node.ParentIndex >= 0) && (node.ParentIndex < entities.Count))
				mScene.SetParent(entities[i], entities[node.ParentIndex]);
			else
				mScene.SetParent(entities[i], root);

			if ((node.MeshIndex < 0) || (node.MeshIndex >= model.Meshes.Count))
				continue;

			let mesh = model.Mesh(node.MeshIndex);
			if (mesh == null)
				continue;

			let component = meshes.Add(entities[i]);
			component.Mesh.SetDirect(mesh);
			component.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
			// The unified list: a submesh indexes it by its own material index, and slot zero
			// covers anything out of range.
			component.SetMaterials(materials);
			if (model.MeshSkinned[node.MeshIndex])
				skinned.Add(entities[i]);
		}

		AttachAnimation(model, root, skinned, useGraph);
	}

	private void AttachAnimation(ModelResource model, EntityHandle root,
		List<EntityHandle> skinned, bool useGraph)
	{
		if ((model.Skeleton.Get == null) || model.Animations.IsEmpty || skinned.IsEmpty)
			return;
		if (model.Animations[0].Get == null)
			return;

		if (useGraph)
		{
			let graphs = mScene.GetSystem<AnimationGraphComponentManager>();
			if (graphs == null)
				return;

			let graph = ClipCyclerGraph.Build(model);
			if (graph == null)
				return;
			mGraphs.Add(graph);

			let component = graphs.Add(root);
			component.Skeleton.SetDirect(model.Skeleton.Get);
			component.Graph.SetDirect(graph);
			for (let entity in skinned)
				component.MeshEntities.Add(.(mScene.GetEntityId(entity)));

			mGraphCharacter = root;
			return;
		}

		let animations = mScene.GetSystem<SkeletalAnimationComponentManager>();
		if (animations == null)
			return;

		let component = animations.Add(root);
		component.Skeleton.SetDirect(model.Skeleton.Get);
		component.Clip.SetDirect(model.Animations[0].Get);
		for (let entity in skinned)
			component.MeshEntities.Add(.(mScene.GetEntityId(entity)));
	}

	/// One billboard per orientation and blend combination, in a row above the grids, so the
	/// modes are comparable by flying round them.
	private void SpawnSpriteDemo()
	{
		if ((mLogo == null) || (mLogo.View == null))
			return;

		let sprites = mScene.GetSystem<SpriteComponentManager>();
		if (sprites == null)
			return;

		let names = scope String[](
			"spriteFace", "spriteFaceY", "spriteWorld", "spriteAdd", "spriteTint");
		let orientations = scope SpriteOrientation[](
			.CameraFacing, .CameraFacingY, .WorldAligned, .CameraFacing, .CameraFacing);
		let additive = scope bool[](false, false, false, true, false);
		let tints = scope Color[](
			.(1.0f, 1.0f, 1.0f, 1.0f), .(1.0f, 1.0f, 1.0f, 1.0f), .(1.0f, 1.0f, 1.0f, 1.0f),
			.(2.6f, 2.2f, 1.4f, 1.0f), // an HDR tint, so the glow reads over the bright scene
			.(0.4f, 0.9f, 1.0f, 1.0f));

		const float cSpacing = 4.5f;
		let x0 = -0.5f * cSpacing * (float)(names.Count - 1);
		for (int i < names.Count)
		{
			let entity = mScene.CreateEntity(names[i]);
			let sprite = sprites.Add(entity);
			sprite.Texture = mLogo.View;
			sprite.Size = .(3.0f, 3.0f);
			sprite.Tint = tints[i];
			sprite.Orientation = orientations[i];
			sprite.Additive = additive[i];

			// Above the grids, which top out at fourteen, and in front of them, so the row
			// reads as a banner rather than tangling with the cubes.
			mScene.SetLocalPosition(entity, .(x0 + cSpacing * (float)i, 16.0f, -8.0f));
		}
	}

	/// The same logo projected onto the floor: a box straddling it, rotated so its local plus Z
	/// points straight down, which is the direction a decal sprays along.
	private void SpawnDecalDemo()
	{
		if ((mLogo == null) || (mLogo.View == null))
			return;

		let decals = mScene.GetSystem<DecalComponentManager>();
		if (decals == null)
			return;

		let entity = mScene.CreateEntity("floorDecal");
		let decal = decals.Add(entity);
		decal.Texture = mLogo.View;
		decal.Size = .(8.0f, 8.0f, 6.0f); // an eight by eight footprint in a six deep box
		decal.FadeStart = 0.0f;
		decal.FadeEnd = 1.4f; // about eighty degrees, so a near vertical face takes nothing

		// On a clear patch: the props start at z of six.
		var transform = Transform();
		transform.Position = .(0.0f, 0.0f, -3.0f);
		transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), 1.5707963f);
		mScene.SetLocalTransform(entity, transform);
	}

	// ---- per frame ----

	private void AnimateScene(float deltaTime)
	{
		mAngle += deltaTime;

		let spin = Quaternion.FromAxisAngle(.(0.3f, 1.0f, 0.0f), mAngle);
		for (let cube in mCubes)
		{
			var transform = mScene.GetLocalTransform(cube);
			transform.Rotation = spin;
			mScene.SetLocalTransform(cube, transform);
		}

		// The whole field sweeps sideways, so the coloured pools visibly slide as a group, and
		// each light bobs in depth on its own phase, so they cross froxel slices every frame.
		// A static binning would look identical without the second part.
		let sweep = 5.0f * Sin(mAngle * 0.6f);
		for (int k < mPointLights.Count)
		{
			var position = mLightBases[k];
			position.X += sweep;
			position.Z += 0.8f * Sin(mAngle * 1.3f + (float)k * 0.5f);
			mScene.SetLocalPosition(mPointLights[k], position);
		}
	}

	private void DrawDebug(IApplicationHost host, float deltaTime)
	{
		let render = host.Context.GetSubsystem<RenderSubsystem>();
		if (render == null)
			return;

		if (mShowDebugDraw)
		{
			// Keyed to THIS scene, so a second scene's gizmos could never bleed in, and drawn
			// once per view through each view's own camera.
			let draw = render.DebugScene(mScene);
			for (int32 k < 4)
			{
				draw.DrawWireBoxCenter(.(-7.5f + 5.0f * k, 1.25f, 10.0f), .(1.3f, 1.3f, 1.3f),
					.(1.0f, 1.0f, 0.0f, 1.0f));
				draw.DrawWireSphere(Float3(-7.5f + 5.0f * k, 1.25f, 16.0f), 1.4f,
					.(0.2f, 0.9f, 1.0f, 1.0f));
			}

			draw.DrawAxis(Float4x4.Identity(), 3.0f, true);
			draw.DrawGrid(.(0.0f, 0.01f, 0.0f), 60.0f, 30, .(0.25f, 0.25f, 0.30f, 1.0f));
			draw.DrawArrow(.(0.0f, 14.0f, 13.0f), .(0.0f, 0.5f, 13.0f), .(1.0f, 0.5f, 0.0f, 1.0f));
			draw.DrawText3D(.(0.0f, 0.5f, 0.0f), "origin", .(1.0f, 1.0f, 1.0f, 1.0f));

			render.DebugScreen.DrawScreenText(12.0f, 12.0f, "Debug Draw",
				.(0.6f, 1.0f, 0.6f, 1.0f), 2.0f);
		}

		let instant = (deltaTime > 0.0f) ? (1.0f / deltaTime) : 0.0f;
		mFpsSmoothed = (mFpsSmoothed > 0.0f) ? (mFpsSmoothed * 0.9f + instant * 0.1f) : instant;
		let milliseconds = (mFpsSmoothed > 0.0f) ? (1000.0f / mFpsSmoothed) : 0.0f;
		render.DebugScreen.DrawScreenText(12.0f, 34.0f,
			scope $"{mFpsSmoothed:0} FPS  {milliseconds:0.0} ms", .(1.0f, 1.0f, 0.4f, 1.0f), 2.0f);
	}

	/// A surface per split half, re fitted to the live window. Each half's content space equals
	/// its own pixel rect, so a viewport mouse reads local to that view.
	private void UpdateInputRouting(IInputManager input, IWindow window)
	{
		let width = (float)window.Width;
		let height = (float)window.Height;
		let halfWidth = width * 0.5f;

		if (mRouter == null)
		{
			ContentFit left = .(.(0.0f, 0.0f, halfWidth, height), .(halfWidth, height), .Stretch);
			ContentFit right = .(.(halfWidth, 0.0f, width - halfWidth, height),
				.(width - halfWidth, height), .Stretch);

			mSurfaceLeft = new InputSurface(input, window.Id, left);
			mSurfaceRight = new InputSurface(input, window.Id, right);
			mRouter = new InputRouter(input);
			mRouter.AddSurface(mSurfaceLeft);
			mRouter.AddSurface(mSurfaceRight);
		}

		mSurfaceLeft.SetRegion(.(0.0f, 0.0f, halfWidth, height));
		mSurfaceLeft.SetContentSize(.(halfWidth, height));
		mSurfaceRight.SetRegion(.(halfWidth, 0.0f, width - halfWidth, height));
		mSurfaceRight.SetContentSize(.(width - halfWidth, height));

		// What the panel is using this frame must not ALSO drive a camera, or scrolling a
		// slider flies the view.
		if (igGetCurrentContext() != null)
		{
			let io = igGetIO_Nil();
			mRouter.SetExternalCapture(io.WantCaptureMouse, io.WantCaptureKeyboard);
		}

		mRouter.Update();
	}

	// ---- the live controls ----

	private StaticMesh Track(StaticMesh mesh)
	{
		mMeshes.Add(mesh);
		return mesh;
	}

	private Material Track(Material material)
	{
		mMaterials.Add(material);
		return material;
	}

	/// A fresh material rather than a mutated one: the renderer keys instances by identity and
	/// prunes what nothing references, so replacing it is the clean live tweak.
	private void ApplyFloorMaterial()
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		if (let mesh = meshes.Get(mFloorEntity))
		{
			mesh.SetMaterial(Track(MaterialPresets.CreatePbr("lit", .(0.12f, 0.45f, 0.22f, 1.0f),
				mFloorMetallic, mFloorRoughness)));
		}
	}

	/// The light shines along its entity's forward, so yaw about up then pitch down.
	private void ApplyKeyLightDirection()
	{
		if ((mScene == null) || !mKeyLight.IsAssigned)
			return;

		var transform = mScene.GetLocalTransform(mKeyLight);
		transform.Rotation = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), mKeyYaw)
			* Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), mKeyPitch);
		mScene.SetLocalTransform(mKeyLight, transform);
	}

	private void CycleSkyMode()
	{
		let environments = mScene.GetSystem<EnvironmentSystem>();
		if (environments == null)
			return;

		let settings = environments.Environment;
		switch (settings.SkyMode)
		{
		case .Procedural: settings.SkyMode = .Analytic;
		case .Analytic: settings.SkyMode = .HDREquirect;
		case .HDREquirect: settings.SkyMode = .Cubemap;
		default: settings.SkyMode = .Procedural;
		}
	}

	private void ToggleProbeParallax()
	{
		let probes = mScene.GetSystem<ReflectionProbeComponentManager>();
		if (probes == null)
			return;

		if (let probe = probes.Get(mProbeEntity))
			probe.Parallax = !probe.Parallax;
	}

	/// The player is created lazily by the manager, so the trigger has to go through the
	/// component rather than a player the sample holds.
	private void FireGraphNext()
	{
		if ((mScene == null) || !mGraphCharacter.IsAssigned)
			return;

		let graphs = mScene.GetSystem<AnimationGraphComponentManager>();
		if (graphs == null)
			return;

		if (let component = graphs.Get(mGraphCharacter))
		{
			if (component.Player != null)
				component.Player.SetTrigger("Next");
		}
	}

	// ---- the debug panel ----

	/// Wired straight to the live settings: editing one of these re-runs the IBL precompute
	/// next frame, so the ambient updates while the slider is moving.
	private void BuildDebugUI(RenderSubsystem render)
	{
		if (mScene == null)
			return;

		igBegin("Environment", null, 0);

		if (render != null)
		{
			BuildPostRows(render);
			BuildFloorRows();
			BuildAntiAliasRows(render);
		}

		BuildSkyRows();
		BuildLightRows();
		BuildProbeRows();

		if (mGraphCharacter.IsAssigned)
		{
			igSeparatorText("Animation");
			if (igButton("Fire the graph's 'Next' (G)", .()))
				FireGraphNext();
		}

		igSeparatorText("Debug");
		if (render != null)
		{
			var culling = render.ViewCulling;
			if (igCheckbox("View frustum cull", &culling))
				render.ViewCulling = culling;

			if (culling)
			{
				render.ViewCullStats(let culled, let total);
				igSameLine(0.0f, -1.0f);
				igTextDisabled(scope $"({culled}/{total})");
			}
		}

		igCheckbox("Debug draw (gizmos, grid, axes)", &mShowDebugDraw);
		igEnd();
	}

	private void BuildPostRows(RenderSubsystem render)
	{
		var exposure = render.Exposure;
		if (igSliderFloat("Exposure", &exposure, 0.05f, 8.0f, "%.2f", 0))
			render.Exposure = exposure;

		var sharing = render.InstanceSharing;
		if (igCheckbox("Instance sharing", &sharing))
			render.InstanceSharing = sharing;

		let aoNames = scope char8*[]("Off".CStr(), "GTAO".CStr(), "SSAO".CStr());
		var aoMode = (int32)render.AoMode;
		if (igCombo_Str_arr("AO mode", &aoMode, aoNames.Ptr, 3, -1))
			render.AoMode = (AoMode)aoMode;

		if (render.AoMode != .Off)
		{
			var strength = render.AoStrength;
			if (igSliderFloat("AO strength", &strength, 0.0f, 1.0f, "%.2f", 0))
				render.AoStrength = strength;

			var radius = render.AoRadius;
			if (igSliderFloat("AO radius", &radius, 0.1f, 3.0f, "%.2f", 0))
				render.AoRadius = radius;

			var intensity = render.AoIntensity;
			if (igSliderFloat("AO power", &intensity, 0.5f, 4.0f, "%.2f", 0))
				render.AoIntensity = intensity;
		}

		// The debug views force a generator on and show its buffer straight to screen: a good
		// view space normal ramps smoothly with orientation, view Z ramps with distance, and
		// occlusion darkens only in creases.
		let debugNames = scope char8*[]("Off".CStr(), "AO".CStr(), "Normal.x".CStr(),
			"Normal.y".CStr(), "Normal.z".CStr(), "View Z".CStr(), "Raw depth".CStr());
		var aoDebug = render.AoDebug;
		if (igCombo_Str_arr("AO debug", &aoDebug, debugNames.Ptr, 7, -1))
			render.AoDebug = aoDebug;

		igSeparator();

		var ssr = render.SsrEnabled;
		if (igCheckbox("SSR (screen space reflections)", &ssr))
			render.SsrEnabled = ssr;

		if (!render.SsrEnabled)
			return;

		let parameters = render.SsrParams;
		igCheckbox("SSR temporal", &parameters.Temporal);
		igSliderFloat("SSR intensity", &parameters.Intensity, 0.0f, 1.0f, "%.2f", 0);
		igSliderFloat("SSR glossy (0 is sharp)", &parameters.Glossy, 0.0f, 2.0f, "%.2f", 0);
		igSliderFloat("SSR thickness", &parameters.Thickness, 0.05f, 3.0f, "%.2f", 0);
		igSliderFloat("SSR rough cutoff", &parameters.RoughnessCutoff, 0.0f, 1.0f, "%.2f", 0);
		igSliderInt("SSR steps", &parameters.MaxSteps, 16, 256, "%d", 0);

		if (parameters.Temporal)
		{
			igSliderFloat("SSR history", &parameters.HistoryBlend, 0.0f, 0.98f, "%.2f", 0);
			igSliderFloat("SSR ghost reject", &parameters.GhostReject, 0.0f, 20.0f, "%.2f", 0);
		}

		let ssrDebugNames = scope char8*[]("Off".CStr(), "Raw reflection".CStr(), "Hit UV".CStr(),
			"Weight".CStr(), "Reflect dir".CStr());
		igCombo_Str_arr("SSR debug", &parameters.Debug, ssrDebugNames.Ptr, 5, -1);
	}

	/// The reflection eye test wants a TUNABLE reflector: roughness feeds the cutoff and the
	/// cone gather, metallic drives how much there is to reflect.
	private void BuildFloorRows()
	{
		var changed = igSliderFloat("Floor metallic", &mFloorMetallic, 0.0f, 1.0f, "%.2f", 0);
		changed |= igSliderFloat("Floor roughness", &mFloorRoughness, 0.0f, 1.0f, "%.2f", 0);
		if (changed)
			ApplyFloorMaterial();
	}

	private void BuildAntiAliasRows(RenderSubsystem render)
	{
		igSeparator();

		var taa = render.TaaEnabled;
		if (igCheckbox("TAA", &taa))
			render.TaaEnabled = taa;

		if (render.TaaEnabled)
		{
			var blend = render.TaaBlend;
			if (igSliderFloat("TAA history", &blend, 0.80f, 0.995f, "%.3f", 0))
				render.TaaBlend = blend;

			var gamma = render.TaaGamma;
			if (igSliderFloat("TAA variance", &gamma, 0.5f, 2.5f, "%.2f", 0))
				render.TaaGamma = gamma;

			var motion = render.TaaMotionScale;
			if (igSliderFloat("TAA motion", &motion, 0.0f, 128.0f, "%.1f", 0))
				render.TaaMotionScale = motion;
		}
		else
		{
			// The fallback, never stacked with TAA: two temporal passes would fight.
			var fxaa = render.FxaaEnabled;
			if (igCheckbox("FXAA", &fxaa))
				render.FxaaEnabled = fxaa;

			if (render.FxaaEnabled)
			{
				var subpixel = render.FxaaSubpixel;
				if (igSliderFloat("FXAA subpixel", &subpixel, 0.0f, 1.0f, "%.2f", 0))
					render.FxaaSubpixel = subpixel;
			}
		}

		var bloom = render.BloomEnabled;
		if (igCheckbox("Bloom", &bloom))
			render.BloomEnabled = bloom;

		if (render.BloomEnabled)
		{
			var intensity = render.BloomIntensity;
			if (igSliderFloat("Bloom intensity", &intensity, 0.0f, 0.5f, "%.3f", 0))
				render.BloomIntensity = intensity;

			var threshold = render.BloomThreshold;
			if (igSliderFloat("Bloom threshold", &threshold, 0.0f, 4.0f, "%.2f", 0))
				render.BloomThreshold = threshold;
		}
	}

	private void BuildSkyRows()
	{
		let environments = mScene.GetSystem<EnvironmentSystem>();
		if (environments == null)
			return;

		let settings = environments.Environment;

		let modeNames = scope char8*[]("Procedural".CStr(), "Analytic (Preetham)".CStr(),
			"HDR equirect".CStr(), "Cubemap".CStr());
		var mode = (int32)settings.SkyMode;
		if (igCombo_Str_arr("Sky mode", &mode, modeNames.Ptr, 4, -1))
			settings.SkyMode = (SkyMode)mode;

		igSliderFloat("Sky intensity", &settings.SkyIntensity, 0.0f, 4.0f, "%.2f", 0);

		let procedural = settings.SkyMode == .Procedural;
		let analytic = settings.SkyMode == .Analytic;

		// Only the untextured modes have an analytic sun disc to size, so the rest of the rows
		// would be inert.
		if (procedural || analytic)
		{
			igSliderFloat("Sun intensity", &settings.SunIntensity, 0.0f, 8.0f, "%.2f", 0);
			igSliderFloat("Sun size (deg)", &settings.SunAngularSize, 0.1f, 10.0f, "%.2f", 0);
		}
		if (analytic)
			igSliderFloat("Turbidity", &settings.Turbidity, 1.7f, 10.0f, "%.2f", 0);

		if (!procedural)
			return;

		ColorEdit("Horizon", ref settings.SkyHorizon);
		ColorEdit("Zenith", ref settings.SkyZenith);
		ColorEdit("Ground", ref settings.SkyGround);
	}

	private static void ColorEdit(StringView label, ref Color color)
	{
		float[3] rgb = .(color.R, color.G, color.B);
		if (igColorEdit3(label.Ptr, &rgb[0], 0))
			color = .(rgb[0], rgb[1], rgb[2], 1.0f);
	}

	/// The light that actually shades surfaces, as opposed to the sky's sun disc above: two
	/// different things that both say "sun".
	private void BuildLightRows()
	{
		let lights = mScene.GetSystem<LightComponentManager>();
		if ((lights == null) || !mKeyLight.IsAssigned)
			return;

		let light = lights.Get(mKeyLight);
		if (light == null)
			return;

		igSeparatorText("Directional light");
		igSliderFloat("Light intensity", &light.Intensity, 0.0f, 8.0f, "%.2f", 0);
		ColorEdit("Light colour", ref light.Color);

		var changed = igSliderAngle("Pitch", &mKeyPitch, -89.0f, 0.0f, "%.0f deg", 0);
		changed |= igSliderAngle("Yaw", &mKeyYaw, -180.0f, 180.0f, "%.0f deg", 0);
		if (changed)
			ApplyKeyLightDirection();
	}

	private void BuildProbeRows()
	{
		let probes = mScene.GetSystem<ReflectionProbeComponentManager>();
		if ((probes == null) || !mProbeEntity.IsAssigned)
			return;

		let probe = probes.Get(mProbeEntity);
		if (probe == null)
			return;

		igSeparatorText("Reflection probe");
		igCheckbox("Box parallax", &probe.Parallax);
		igSliderFloat("Probe intensity", &probe.Intensity, 0.0f, 4.0f, "%.2f", 0);
	}
}
