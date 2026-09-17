using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Materials;
using Sedulous.Navigation;
using Sedulous.Navigation.Resource;
using Sedulous.Particles;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Render;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Scene;
using Sedulous.Engine.UI;
using Sedulous.UI;
using Sedulous.UI.Resource;
using Samples.Common;

namespace Samples.WebScene;

/// The FULL RENDERER exercise scene, shared by the desktop and the browser entry.
///
/// ONE procedurally built scene that touches every renderer feature, so `--vulkan`,
/// `--webgpu` and the browser can be compared side by side:
///
///   - an analytic Preetham sky baked to IBL: env cube, SH diffuse, prefiltered specular
///   - a directional sun with cascades, TOGGLEABLE, because local shadows have to survive
///     the sun going off, plus a static spot and an orbiting point, both shadowed
///   - a roughness by metallic sphere grid, a glossy floor for SSR, a spinning cube for TAA
///   - a chrome sphere inside a box reflection probe, which is the parallax probe path
///   - an instanced ring, the per instance addressing path
///   - a projected decal and three sprites, alpha, additive and post tonemap, off one
///     procedural texture
///   - a particle fountain of additive billboards, and spark trails, the ribbon path
///   - debug draw: grid, axes, wire volumes and 3D text, plus an FPS readout on the screen pass
///   - game UI in all three tiers: a scene HUD canvas whose button counts its own clicks and
///     so proves pointer routing is CONSUMED there, a billboard nameplate riding the cube,
///     and a screen tier badge
///   - navigation: an inline baked navmesh with six crowd agents crossing and avoiding
///
/// Not exercised: skinning, which needs a skinned asset, and split screen, which Sandbox
/// covers. This scene stays single view on purpose so the browser has the lighter load.
class WebSceneApp : DefaultApplication
{
	private Scene mScene = null;

	private EntityHandle mCube = .Invalid;
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mSun = .Invalid;
	private EntityHandle mPointLight = .Invalid;
	private EntityHandle mFloor = .Invalid;
	private EntityHandle mDecal = .Invalid;
	private EntityHandle mProbe = .Invalid;
	private EntityHandle mHudEntity = .Invalid;
	private EntityHandle mFountainEntity = .Invalid;
	private EntityHandle mSparksEntity = .Invalid;
	private EntityHandle[3] mSprites = .(.Invalid, .Invalid, .Invalid);

	/// Everything the scene borrows and this owns.
	private List<StaticMesh> mMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<Material> mMaterials = new .() ~ DeleteContainerAndItems!(_);
	private ParticleEffect mFountain = new .() ~ delete _;
	private ParticleEffect mSparks = new .() ~ delete _;

	/// The shared procedural texture behind the decal and the sprites. Freed in OnShutdown,
	/// which is what keeps the validation layer quiet at teardown.
	private ITexture mTexture = null;
	private ITextureView mTextureView = null;

	private List<NavAgent> mNavAgents = new .() ~ delete _;
	private NavigationZoneResource mNavZone = null ~ delete _;

	private FlyCamera mFly = .();
	private float mTime = 0.0f;
	private float mFpsSmoothed = 0.0f;
	private bool mShowDebugDraw = true;
	private float mFloorMetallic = 0.0f;
	private float mFloorRoughness = 0.12f;

	private UIDocument mHudDocument = null;
	private UIDocument mPlateDocument = null;
	private UIDocument mBadgeDocument = null;
	private uint32 mHudClicks = 0;
	private bool mHudBound = false;

	/// One agent's round trip. The crowd re-targets on arrival, so they ping pong across the
	/// field and have to route around the obstacle and past each other.
	private struct NavAgent
	{
		public EntityHandle Entity;
		public Float3 Home;
		public Float3 Away;
		public bool GoingHome;
	}

	public override void OnStartup(IApplicationHost host)
	{
		// The base wires resource type registration AND the game UI render bring up. Skip it
		// and the UI silently never draws.
		base.OnStartup(host);

		Console.WriteLine("WebScene: building the full renderer scene...");
		if (host.Context.GetSubsystem<SceneSubsystem>() == null)
		{
			Console.WriteLine("WebScene: no scene subsystem.");
			return;
		}
		mScene = PrimaryScenes.CreateScene("web");

		// The exercise scene turns the optional passes ON: it exists to exercise them, and the
		// panel can put any of them back.
		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
		{
			render.SsrEnabled = true;
			render.Exposure = 0.9f;
		}

		BuildEnvironment();
		BuildTexture(host); // before the decal and sprites, which bind its view
		BuildGeometry();
		BuildLights();
		BuildProbe();
		BuildInstancedRing();
		BuildDecalAndSprites();
		BuildParticles();
		BuildCamera();
		BuildGameUI(host);
		BuildNavigation();

		// Simulation ON so the crowd ticks. The manual animations, the cube spin and the
		// orbiting light, are driven in OnUpdate and are unaffected; there is no physics here.
		mScene.Start();
		mScene.SetSimulationEnabled(true);

		Console.WriteLine("WebScene: started. WASD and QE move, hold the right mouse to look.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);
		if (mScene == null)
			return;

		mTime += deltaTime;

		BindHudButton();

		// The spinning cube: constant motion, so TAA and the velocity buffer are always under
		// load rather than only when the camera moves.
		var cubeTransform = mScene.GetLocalTransform(mCube);
		cubeTransform.Rotation =
			Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), mTime)
			* Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), mTime * 0.35f);
		mScene.SetLocalTransform(mCube, cubeTransform);

		// The orbiting point light, so the local shadow atlas has something MOVING in it; the
		// spot stays put, which is the cached half of the same path.
		let orbit = mTime * 0.6f;
		mScene.SetLocalPosition(mPointLight,
			.(Math.Cos(orbit) * 4.5f, 2.2f, Math.Sin(orbit) * 4.5f));

		UpdateCamera(host, deltaTime);
		UpdateNavigation();
		UpdateDebugDraw(host, deltaTime);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		// The aspect follows the window, which on the web is a canvas CSS can resize at any
		// moment, so it is taken from the frame rather than cached at startup.
		if ((mScene != null) && (frame.Height > 0))
		{
			if (let cameras = mScene.GetSystem<CameraComponentManager>())
			{
				if (let camera = cameras.Get(mCamera))
					camera.Aspect = (float)frame.Width / (float)frame.Height;
			}
		}
		base.OnRenderWindow(host, ref frame);
	}

	public override void OnShutdown(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (device != null)
		{
			device.WaitIdle(); // the GPU has to finish before the shared texture goes
			if (mTextureView != null)
				device.DestroyTextureView(ref mTextureView);
			if (mTexture != null)
				device.DestroyTexture(ref mTexture);
		}

		DeleteAndNullify!(mHudDocument);
		DeleteAndNullify!(mPlateDocument);
		DeleteAndNullify!(mBadgeDocument);

		base.OnShutdown(host);
	}

	// ---- per frame ----

	/// Binds the HUD button once the UI subsystem has instantiated the canvas tree, which is
	/// not until a frame or two in. The click counter is the point: it proves the browser's
	/// pointer path reaches game UI and is consumed there rather than falling through.
	private void BindHudButton()
	{
		if (mHudBound)
			return;

		let canvases = mScene.GetSystem<UICanvasComponentManager>();
		if (canvases == null)
			return;

		let canvas = canvases.Get(mHudEntity);
		if ((canvas == null) || (canvas.Root == null))
			return;

		let group = canvas.Root as ViewGroup;
		if (group == null)
			return;

		let button = group.FindByName<Button>("ws-btn");
		if (button == null)
			return;

		button.OnClick.Add(new (sender) =>
			{
				mHudClicks++;
				button.SetText(scope $"Clicks: {mHudClicks}");
				Console.WriteLine("WebScene: HUD button clicked");
			});
		mHudBound = true;
	}

	private void UpdateCamera(IApplicationHost host, float deltaTime)
	{
		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (input != null)
			mFly.Update(input.Keyboard, input.Mouse, deltaTime);

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);
	}

	/// Re-targets each agent as it arrives, so they cross the field forever rather than
	/// arriving once and stopping.
	private void UpdateNavigation()
	{
		let agents = mScene.GetSystem<NavAgentComponentManager>();
		if (agents == null)
			return;

		for (int i < mNavAgents.Count)
		{
			let agent = mNavAgents[i];
			let component = agents.Get(agent.Entity);
			if ((component == null) || !component.Finished)
				continue;

			var updated = agent;
			updated.GoingHome = !agent.GoingHome;
			mNavAgents[i] = updated;

			let target = updated.GoingHome ? updated.Home : updated.Away;
			component.Navigate(target);
		}
	}

	/// Immediate mode, so everything here is re-issued every frame.
	///
	/// The gizmos go through the 3D pass, in the scene's camera; the FPS readout goes through
	/// the SCREEN pass and stays on regardless, so one of each is always exercised.
	private void UpdateDebugDraw(IApplicationHost host, float deltaTime)
	{
		let render = host.Context.GetSubsystem<RenderSubsystem>();
		if (render == null)
			return;

		if (mShowDebugDraw)
		{
			let debug = render.DebugScene(mScene);
			debug.DrawGrid(.(0.0f, 0.01f, 0.0f), 40.0f, 20, .(0.25f, 0.25f, 0.30f, 1.0f));
			debug.DrawAxis(Float4x4.Identity(), 2.0f, true);

			// The probe's box and a label, matching BuildProbe exactly, so its coverage and the
			// chrome sphere inside it read at a glance.
			debug.DrawWireBoxCenter(.(4.0f, 1.0f, 2.0f), .(5.0f, 3.5f, 5.0f),
				.(0.2f, 0.9f, 1.0f, 1.0f));
			debug.DrawText3D(.(4.0f, 4.7f, 2.0f), "probe", .(0.2f, 0.9f, 1.0f, 1.0f));

			// The orbiting light's CURRENT position, so the gizmo moves with it.
			debug.DrawWireSphere(mScene.GetLocalTransform(mPointLight).Position, 0.25f,
				.(1.0f, 0.8f, 0.2f, 1.0f));
		}

		let instant = (deltaTime > 0.0f) ? (1.0f / deltaTime) : 0.0f;
		mFpsSmoothed = (mFpsSmoothed > 0.0f) ? (mFpsSmoothed * 0.9f + instant * 0.1f) : instant;
		let milliseconds = (mFpsSmoothed > 0.0f) ? (1000.0f / mFpsSmoothed) : 0.0f;
		render.DebugScreen.DrawScreenText(12.0f, 12.0f,
			scope $"{(int)(mFpsSmoothed + 0.5f)} FPS  {milliseconds:0.0} ms",
			.(1.0f, 1.0f, 0.4f, 1.0f), 2.0f);
	}

	// ---- scene building ----

	private void BuildEnvironment()
	{
		let environment = mScene.GetSystem<EnvironmentSystem>();
		if (environment == null)
			return;

		// Preetham, so the IBL bake has a real sky behind it rather than a constant.
		environment.Environment.SkyMode = .Analytic;
		environment.Environment.Turbidity = 3.0f;
		environment.Environment.AmbientColor = .(0.10f, 0.12f, 0.16f, 1.0f);
		environment.Environment.AmbientIntensity = 0.15f; // mostly IBL, a little flat fill
	}

	private void BuildGeometry()
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		// A GLOSSY floor, so SSR has something to reflect into. Metallic and roughness are
		// live from the panel, which is the SSR eye test.
		mFloor = mScene.CreateEntity("floor");
		mScene.SetLocalPosition(mFloor, .(0.0f, -0.75f, 0.0f));
		{
			let mesh = meshes.Add(mFloor);
			mesh.Mesh.SetDirect(Track(Primitives.Plane(30.0f, 30.0f)));
		}
		ApplyFloorMaterial();

		// The roughness by metallic grid: the PBR response as a matrix you can walk along.
		const int32 cColumns = 5; // roughness across
		const int32 cRows = 2;    // dielectric, then metal
		let sphere = Track(Primitives.Sphere(0.6f));
		for (int32 row < cRows)
		{
			for (int32 column < cColumns)
			{
				let entity = mScene.CreateEntity("web.sphere");
				mScene.SetLocalPosition(entity,
					.(-6.0f + (float)column * 1.5f, 0.0f, -4.0f - (float)row * 1.5f));

				let roughness = 0.05f + 0.9f * (float)column / (cColumns - 1);
				let mesh = meshes.Add(entity);
				mesh.Mesh.SetDirect(sphere);
				mesh.SetMaterial(Track(MaterialPresets.CreatePbr("lit",
					.(0.9f, 0.6f, 0.25f, 1.0f), (row == 1) ? 1.0f : 0.0f, roughness)));
			}
		}

		// The spinning cube, for TAA motion.
		mCube = mScene.CreateEntity("cube");
		mScene.SetLocalPosition(mCube, .(0.0f, 0.6f, 0.0f));
		{
			let mesh = meshes.Add(mCube);
			mesh.Mesh.SetDirect(Track(Primitives.Cube(1.0f)));
			mesh.SetMaterial(Track(MaterialPresets.CreatePbr("lit",
				.(0.85f, 0.35f, 0.28f, 1.0f), 0.1f, 0.4f)));
		}

		// A chrome sphere for the probe to reflect, sitting inside its box.
		{
			let entity = mScene.CreateEntity("chrome");
			mScene.SetLocalPosition(entity, .(4.0f, 0.4f, 2.0f));
			let mesh = meshes.Add(entity);
			mesh.Mesh.SetDirect(Track(Primitives.Sphere(1.1f)));
			mesh.SetMaterial(Track(MaterialPresets.CreatePbr("lit",
				.(0.95f, 0.95f, 0.97f, 1.0f), 1.0f, 0.05f)));
		}
	}

	private void BuildLights()
	{
		let lights = mScene.GetSystem<LightComponentManager>();
		if (lights == null)
			return;

		// The sun, with cascades. Toggleable from the panel, because the thing worth catching
		// is local shadows breaking when the sun and its cascades go away.
		mSun = mScene.CreateEntity("sun");
		{
			var transform = mScene.GetLocalTransform(mSun);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.9f)
				* Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 0.5f);
			mScene.SetLocalTransform(mSun, transform);

			let light = lights.Add(mSun);
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.9f, 1.0f);
			light.Intensity = 2.0f;
			light.CastsShadows = true;
		}

		// A static spot over the sphere grid: one cached atlas tile.
		{
			let entity = mScene.CreateEntity("spot");
			var transform = mScene.GetLocalTransform(entity);
			transform.Position = .(-3.0f, 5.0f, -2.0f);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -1.2f);
			mScene.SetLocalTransform(entity, transform);

			let light = lights.Add(entity);
			light.Type = .Spot;
			light.Color = .(0.4f, 0.75f, 1.0f, 1.0f);
			light.Intensity = 14.0f;
			light.Range = 14.0f;
			light.InnerAngle = 0.45f;
			light.OuterAngle = 0.62f;
			light.CastsShadows = true;
		}

		// The orbiting point: six atlas faces, re-rendered every frame because it moves.
		mPointLight = mScene.CreateEntity("pointlight");
		mScene.SetLocalPosition(mPointLight, .(4.5f, 2.2f, 0.0f));
		{
			let light = lights.Add(mPointLight);
			light.Type = .Point;
			light.Color = .(1.0f, 0.55f, 0.3f, 1.0f);
			light.Intensity = 10.0f;
			light.Range = 9.0f;
			light.CastsShadows = true;
		}
	}

	private void BuildProbe()
	{
		let probes = mScene.GetSystem<ReflectionProbeComponentManager>();
		if (probes == null)
			return;

		mProbe = mScene.CreateEntity("probe");
		mScene.SetLocalPosition(mProbe, .(4.0f, 1.0f, 2.0f));

		let probe = probes.Add(mProbe);
		probe.HalfExtents = .(5.0f, 3.5f, 5.0f);
		probe.Resolution = 128;
		probe.Parallax = true;
	}

	/// One entity, 256 instances: the per instance addressing path, which is a different
	/// resolve from 256 separate mesh components.
	private void BuildInstancedRing()
	{
		let instanced = mScene.GetSystem<InstancedMeshComponentManager>();
		if (instanced == null)
			return;

		let ring = mScene.CreateEntity("ring");
		let component = instanced.Add(ring);
		component.Mesh.SetDirect(Track(Primitives.Cube(0.3f)));
		component.Material.SetDirect(Track(MaterialPresets.CreatePbr("lit",
			.(0.3f, 0.8f, 0.5f, 1.0f), 0.2f, 0.5f)));

		const int32 cCount = 256;
		let transforms = scope Float4x4[cCount];
		for (int32 i < cCount)
		{
			let angle = (float)i / cCount * 6.2831853f;
			let radius = 10.0f + 0.8f * Math.Sin(angle * 9.0f);

			transforms[i] = Float4x4.Identity();
			transforms[i].M[3][0] = Math.Cos(angle) * radius;
			transforms[i].M[3][1] = -0.4f + 0.5f * Math.Sin(angle * 5.0f);
			transforms[i].M[3][2] = Math.Sin(angle) * radius;
		}
		component.SetInstances(.(&transforms[0], cCount));
	}

	private void BuildDecalAndSprites()
	{
		if (mTextureView == null)
			return; // the texture failed, so these stay absent rather than bind nothing

		if (let decals = mScene.GetSystem<DecalComponentManager>())
		{
			mDecal = mScene.CreateEntity("decal");
			var transform = mScene.GetLocalTransform(mDecal);
			transform.Position = .(-2.5f, -0.2f, 2.5f);
			// A decal projects along its local +Z, so this turns that axis DOWN at the floor.
			// Unrotated it projects horizontally and the angle fade erases it entirely.
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), 1.5707963f);
			mScene.SetLocalTransform(mDecal, transform);

			let decal = decals.Add(mDecal);
			decal.Texture = mTextureView;
			decal.Size = .(3.0f, 2.0f, 3.0f);
			decal.Color = .(1.0f, 0.9f, 0.4f, 0.9f);
		}

		if (let sprites = mScene.GetSystem<SpriteComponentManager>())
		{
			// One of each blend path, side by side: alpha, additive, and post tonemap.
			let origin = Float3(-6.5f, 1.4f, 3.5f);
			for (int32 i < 3)
			{
				mSprites[i] = mScene.CreateEntity("sprite");
				mScene.SetLocalPosition(mSprites[i], origin + Float3((float)i * 1.6f, 0.0f, 0.0f));

				let sprite = sprites.Add(mSprites[i]);
				sprite.Texture = mTextureView;
				sprite.Size = .(1.2f, 1.2f);
				switch (i)
				{
				case 0:
					sprite.Tint = .(1.0f, 1.0f, 1.0f, 0.9f);
				case 1:
					sprite.Tint = .(0.4f, 0.8f, 1.0f, 1.0f);
					sprite.Additive = true;
				default:
					sprite.Tint = .(1.0f, 0.5f, 0.8f, 1.0f);
					sprite.PostTonemap = true;
				}
			}
		}
	}

	private void BuildParticles()
	{
		let emitters = mScene.GetSystem<ParticleEffectComponentManager>();
		if (emitters == null)
			return;

		// A modest additive fountain: the billboard path.
		{
			let system = mFountain.AddSystem(6000);
			system.Name.Set("fountain");
			system.BlendMode = .Additive;
			system.RenderMode = .Billboard;
			system.Emitter.Mode = .Continuous;
			system.Emitter.SpawnRate = 900.0f;
			system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.15f);
			system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.2f, 2.2f);
			{
				let velocity = system.AddInitializer<VelocityInitializer>();
				velocity.BaseVelocity = .(0.0f, 7.5f, 0.0f);
				velocity.Randomness = .(1.6f, 1.0f, 1.6f);
			}
			system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.16f, 0.16f));
			system.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.6f, 0.2f, 1.0f),
				.(1.0f, 0.85f, 0.4f, 1.0f));
			system.AddBehavior<GravityBehavior>().Multiplier = 1.2f;
			system.AddBehavior<ColorOverLifetimeBehavior>().Curve =
				.FadeAlpha(.(1.0f, 0.55f, 0.15f, 1.0f), 0.35f);
		}
		mFountainEntity = mScene.CreateEntity("fountain");
		mScene.SetLocalPosition(mFountainEntity, .(6.5f, -0.6f, -3.5f));
		emitters.Add(mFountainEntity);
		emitters.SetEffect(mFountainEntity, mFountain);

		// Spark trails: the ribbon path, which is a different renderer from the billboards.
		{
			let system = mSparks.AddSystem(800);
			system.Name.Set("sparks");
			system.RenderMode = .Trail;
			system.BlendMode = .Additive;
			system.Emitter.Mode = .Continuous;
			system.Emitter.SpawnRate = 24.0f;
			system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.1f);
			system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.2f, 2.0f);
			{
				let velocity = system.AddInitializer<VelocityInitializer>();
				velocity.BaseVelocity = .(0.0f, 6.0f, 0.0f);
				velocity.Randomness = .(4.0f, 2.0f, 4.0f);
			}
			system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.15f, 0.15f));
			system.AddInitializer<ColorInitializer>().Color = .(.(0.2f, 0.7f, 1.0f, 1.0f),
				.(0.9f, 0.4f, 1.0f, 1.0f));
			system.AddBehavior<GravityBehavior>().Multiplier = 1.4f;
		}
		mSparksEntity = mScene.CreateEntity("sparks");
		mScene.SetLocalPosition(mSparksEntity, .(-6.5f, -0.5f, -3.5f));
		emitters.Add(mSparksEntity);
		emitters.SetEffect(mSparksEntity, mSparks);
	}

	private void BuildCamera()
	{
		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
		{
			let camera = cameras.Add(mCamera);
			camera.FovYRadians = 1.04719755f; // 60 degrees
			camera.NearZ = 0.1f;
			camera.FarZ = 200.0f;
			camera.ClearColor = .(0.05f, 0.06f, 0.09f, 1.0f);
		}

		mFly.Position = .(0.0f, 2.4f, 9.5f);
		mFly.Yaw = 0.0f;
		mFly.Pitch = -0.22f;
		mFly.MoveSpeed = 5.0f;
		mFly.FastSpeed = 14.0f;
		mFly.FocusDistance = 9.0f;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);
	}

	/// All three tiers of game UI, which is three separate overlay paths:
	///   scene      a HUD canvas whose button counts clicks, so consumption is visible
	///   billboard  a nameplate riding the spinning cube, distance scaled
	///   screen     a badge on the scene-less overlay layer
	private void BuildGameUI(IApplicationHost host)
	{
		mHudDocument = new UIDocument();
		mHudDocument.Markup.Set("""
			<Flex direction="vertical" align="start" padding="12" spacing="8">
			  <Panel padding="12" width="240"
			         style="background: rounded-rect(rgb(28, 32, 40), radius=8);">
			    <Flex direction="vertical" spacing="8">
			      <Label text="WebScene" font-size="18"/>
			      <Label text="WASD/QE move - RMB look" font-size="12"/>
			      <Button id="ws-btn" text="Clicks: 0" width="200" height="36"/>
			    </Flex>
			  </Panel>
			</Flex>
			""");

		mHudEntity = mScene.CreateEntity("hud");
		if (let canvases = mScene.GetSystem<UICanvasComponentManager>())
			canvases.Add(mHudEntity).Document.SetDirect(mHudDocument);

		// The nameplate rides the CUBE, which is the thing that moves, so world tracking is
		// obvious rather than something you have to take on trust.
		mPlateDocument = new UIDocument();
		mPlateDocument.Markup.Set("""
			<Panel padding="4" style="background: rounded-rect(rgb(20, 24, 30), radius=4);">
			  <Label text="cube" font-size="13"/>
			</Panel>
			""");

		if (let billboards = mScene.GetSystem<UIBillboardComponentManager>())
		{
			let plate = billboards.Add(mCube);
			plate.Document.SetDirect(mPlateDocument);
			plate.Offset = .(0.0f, 1.2f, 0.0f);
			plate.ScaleMode = .Distance;
			plate.ReferenceDistance = 12.0f;
		}

		// The screen tier badge sits OUTSIDE any scene, so it survives a scene swap.
		if (let gameUi = host.Context.GetSubsystem<UISubsystem>())
		{
			mBadgeDocument = new UIDocument();
			mBadgeDocument.Markup.Set("""
				<Panel padding="6" style="background: rounded-rect(rgb(20, 24, 30), radius=6);">
				  <Label text="screen tier" font-size="11"/>
				</Panel>
				""");

			let badge = gameUi.PushScreenOverlay(mBadgeDocument);
			if (badge != null)
			{
				LayoutStyle layout = .();
				layout.Gravity = .Right | .Bottom;
				badge.SetLayout(layout);
				// A PASSIVE watermark. A hit testable screen overlay makes the global layer
				// modal, which is right for a menu and would shield the HUD from every click.
				badge.IsHitTestVisible = false;
			}
		}
	}

	/// A FRESH material rather than a mutated one: the renderer keys instances by identity and
	/// prunes what nothing references, so replacing it is the clean live tweak.
	private void ApplyFloorMaterial()
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		if (let floor = meshes.Get(mFloor))
		{
			floor.SetMaterial(Track(MaterialPresets.CreatePbr("lit",
				.(0.28f, 0.29f, 0.33f, 1.0f), mFloorMetallic, mFloorRoughness)));
		}
	}

	/// One shared procedural texture, a soft ring over a checker, for the decal and the
	/// sprites. Uploaded through a transfer batch rather than a mapped buffer, which is the
	/// path that works identically on every backend.
	private void BuildTexture(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (device == null)
			return;

		const uint32 cSize = 64;
		let pixels = scope uint8[cSize * cSize * 4];
		for (uint32 y < cSize)
		{
			for (uint32 x < cSize)
			{
				let fx = ((float)x + 0.5f) / cSize - 0.5f;
				let fy = ((float)y + 0.5f) / cSize - 0.5f;
				let distance = Math.Sqrt(fx * fx + fy * fy);
				let check = (((x / 8) + (y / 8)) & 1) != 0;
				let ring = Math.Clamp(1.0f - Math.Abs(distance - 0.32f) * 12.0f, 0.0f, 1.0f);
				let level = check ? 200.0f : 90.0f;

				let at = (int)(y * cSize + x) * 4;
				pixels[at + 0] = (uint8)Math.Min(255.0f, level + ring * 255.0f);
				pixels[at + 1] = (uint8)Math.Min(255.0f, level * 0.8f + ring * 200.0f);
				pixels[at + 2] = (uint8)(level / 2.0f);
				pixels[at + 3] = (uint8)(Math.Clamp(ring + (check ? 0.55f : 0.25f), 0.0f, 1.0f)
					* 255.0f);
			}
		}

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cSize;
		textureDesc.Height = cSize;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "webscene.tex";
		if (!(device.CreateTexture(textureDesc) case .Ok(let texture)))
			return;
		mTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		if (!(device.CreateTextureView(mTexture, viewDesc) case .Ok(let view)))
			return;
		mTextureView = view;

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
			return;

		if (!(queue.CreateTransferBatch() case .Ok(var batch)))
			return;

		TextureDataLayout layout = .();
		layout.BytesPerRow = cSize * 4;
		layout.RowsPerImage = cSize;
		batch.WriteTexture(mTexture, .(&pixels[0], pixels.Count), layout, .(cSize, cSize, 1));
		batch.Submit().IgnoreError();
		queue.DestroyTransferBatch(ref batch);
	}

	// ---- navigation ----

	/// Bakes the navmesh INLINE, from the floor minus a central obstacle.
	///
	/// The obstacle sits under the spinning cube at the origin, so the detour the agents take
	/// reads against something visible rather than against empty floor.
	private void BuildNavigation()
	{
		const float cFloorY = -0.75f;

		let vertices = scope List<Float3>();
		let indices = scope List<uint32>();
		AddGroundSoup(vertices, indices, cFloorY, -13.0f, 13.0f, -13.0f, 13.0f);
		AddBoxSoup(vertices, indices, 0.0f, cFloorY, 0.0f, 1.6f, 2.5f);

		let blob = scope List<uint8>();
		let baked = NavigationMeshBuilder.Build(.(vertices.Ptr, vertices.Count),
			.(indices.Ptr, indices.Count), .(), blob) case .Ok;

		mNavZone = new NavigationZoneResource();
		if (baked && !blob.IsEmpty)
			mNavZone.Mesh.Load(.(blob.Ptr, blob.Count)).IgnoreError();

		// The navmesh surface and the agent target lines, so the routing is visible.
		if (let navigation = mScene.GetSystem<NavigationSceneSystem>())
		{
			navigation.Settings.DebugDraw = true;
			navigation.Settings.DebugDrawPaths = true;
		}

		// The zone entity sits at the origin with an identity transform, so zone local and
		// world are the same thing and the baked blob needs no fixing up.
		if (let zones = mScene.GetSystem<NavMeshZoneComponentManager>())
		{
			let zoneEntity = mScene.CreateEntity("nav-zone");
			let zone = zones.Add(zoneEntity);
			zone.Extents = .(14.0f, 4.0f, 14.0f);
			zone.Zone.SetDirect(mNavZone);
		}

		// Six agents in three lanes, running both ways, so they have to avoid each other in
		// the middle as well as route around the obstacle.
		let meshes = mScene.GetSystem<MeshComponentManager>();
		let agents = mScene.GetSystem<NavAgentComponentManager>();
		if ((meshes == null) || (agents == null))
			return;

		let agentMesh = Track(Primitives.Sphere(0.5f));
		let lanes = float[3](-6.0f, 0.0f, 6.0f);
		for (let lane in lanes)
		{
			SpawnNavAgent(meshes, agents, agentMesh, .(-11.0f, cFloorY, lane),
				.(11.0f, cFloorY, lane));
			SpawnNavAgent(meshes, agents, agentMesh, .(11.0f, cFloorY, -lane),
				.(-11.0f, cFloorY, -lane));
		}
	}

	private void SpawnNavAgent(MeshComponentManager meshes, NavAgentComponentManager agents,
		StaticMesh mesh, Float3 home, Float3 away)
	{
		let entity = mScene.CreateEntity("nav-agent");
		mScene.SetLocalPosition(entity, home);
		meshes.Add(entity).Mesh.SetDirect(mesh);
		agents.Add(entity); // the defaults are what this wants: radius, speed and MoveEntity

		mNavAgents.Add(.() { Entity = entity, Home = home, Away = away, GoingHome = false });
	}

	/// One quad of ground as two triangles, wound so the bake sees it as walkable.
	private static void AddGroundSoup(List<Float3> vertices, List<uint32> indices, float y,
		float minX, float maxX, float minZ, float maxZ)
	{
		let first = (uint32)vertices.Count;
		vertices.Add(.(minX, y, minZ));
		vertices.Add(.(maxX, y, minZ));
		vertices.Add(.(maxX, y, maxZ));
		vertices.Add(.(minX, y, maxZ));

		indices.Add(first + 0); indices.Add(first + 2); indices.Add(first + 1);
		indices.Add(first + 0); indices.Add(first + 3); indices.Add(first + 2);
	}

	/// A box as twelve triangles. The bake carves it out of the ground, which is what makes
	/// the agents route around rather than through.
	private static void AddBoxSoup(List<Float3> vertices, List<uint32> indices, float centerX,
		float baseY, float centerZ, float halfWidth, float height)
	{
		let first = (uint32)vertices.Count;
		let minX = centerX - halfWidth;
		let maxX = centerX + halfWidth;
		let minZ = centerZ - halfWidth;
		let maxZ = centerZ + halfWidth;
		let topY = baseY + height;

		vertices.Add(.(minX, baseY, minZ)); vertices.Add(.(maxX, baseY, minZ));
		vertices.Add(.(maxX, baseY, maxZ)); vertices.Add(.(minX, baseY, maxZ));
		vertices.Add(.(minX, topY, minZ));  vertices.Add(.(maxX, topY, minZ));
		vertices.Add(.(maxX, topY, maxZ));  vertices.Add(.(minX, topY, maxZ));

		let faces = uint32[36](
			4, 5, 6, 4, 6, 7, // top
			0, 1, 5, 0, 5, 4, // sides
			1, 2, 6, 1, 6, 5,
			2, 3, 7, 2, 7, 6,
			3, 0, 4, 3, 4, 7,
			0, 3, 2, 0, 2, 1); // bottom
		for (let index in faces)
			indices.Add(first + index);
	}

	// ---- ownership ----

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
}
