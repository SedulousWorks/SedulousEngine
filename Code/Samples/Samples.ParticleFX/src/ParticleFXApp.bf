using System;
using System.Collections;
using System.IO;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Render;
using Sedulous.Extensions.Imgui;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Materials;
using Sedulous.Particles;
using Sedulous.Particles.Pipeline;
using Sedulous.Particles.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Resource;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.VFS;
using Samples.Common;
using cimgui_Beef;

namespace Samples.ParticleFX;

/// The particle showcase: sixteen systems on a 4x4 grid, one per cell, plus the authoring
/// pipeline running live in front of it.
///
/// A grid rather than one effect at a time, because what most of these demonstrate only reads
/// against its neighbours: two mesh cells that differ only in their material, a soft particle
/// A/B, local against world space.
class ParticleFXApp : DefaultApplication
{
	private const float cCellSpacing = 15.0f;
	private const int32 cGridColumns = 4;
	private const String cCookedOutputDir = "Output/ParticleFX";

	private static readonly String[16] cCellNames = .(
		"fountain", "mesh solid", "mesh glow", "embers",
		"haze", "trail", "collision", "orbit (local)",
		"smoke", "fire", "campfire", "fireworks",
		"tornado", "explosion", "magic circle", "fireflies");

	private Scene mScene = null;
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mLocalEmitter = .Invalid;
	private EntityHandle mCookedEmitter = .Invalid;

	/// Every effect is OWNED here and borrowed by its component, which is the code path the
	/// component documents.
	private List<ParticleEffect> mEffects = new .() ~ DeleteContainerAndItems!(_);
	private ParticleEffect mFountain = null;
	private ParticleEffect mEmbers = null;
	private ParticleEffect mHaze = null;

	private List<StaticMesh> mMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<Material> mMaterials = new .() ~ DeleteContainerAndItems!(_);

	private BlastAtlas mBlastAtlas = null ~ delete _;
	private ImguiSubsystem mOverlay = null ~ delete _;

	// The cooked demo's own stack, kept alive for as long as the bound effect is.
	private NativeFileSystem mCookedMount = null ~ delete _;
	private ContentDatabase mCookedDatabase = null ~ delete _;
	private ResourceManager mCookedResources = null ~ delete _;
	private ParticleEffectFactory mCookedFactory = null ~ delete _;
	private SerializerFactory mCookedSerializers = null ~ delete _;
	private bool mHaveCooked = false;

	private FlyCamera mFly = .();
	private float mFrameSmooth = 0.016f;
	private float mOrbitTime = 0.0f;
	private bool mSoftOn = true;
	private float mSoftDistance = 2.0f;

	/// Uncapped, so the frame time reflects the sim and draw cost rather than the display.
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
			mOverlay = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight, DataFileSystem);
			host.Context.RegisterSubsystem<ImguiSubsystem>(mOverlay);
		}
	}

	public override void OnStartup(IApplicationHost host)
	{
		base.OnStartup(host);

		mScene = PrimaryScenes.CreateScene("particlefx");

		// Dim and cool, so the additive particles pop against the lit floor rather than
		// washing into it.
		if (let environment = mScene.GetSystem<EnvironmentSystem>())
		{
			environment.Environment.AmbientColor = .(0.10f, 0.12f, 0.18f, 1.0f);
			environment.Environment.AmbientIntensity = 0.4f;
		}

		mCamera = mScene.CreateEntity("camera");
		mScene.SetLocalPosition(mCamera, .(0.0f, 34.0f, 52.0f));
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera).ClearColor = .(0.02f, 0.02f, 0.04f, 1.0f);

		mFly.Position = .(0.0f, 34.0f, 52.0f);
		mFly.Pitch = -0.55f;

		BuildStage();
		BuildShowcase(host);
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);
		mFrameSmooth = mFrameSmooth * 0.9f + deltaTime * 0.1f;

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (mOverlay != null)
		{
			mOverlay.NewFrame(input, deltaTime);
			BuildHud();
		}

		if (input != null)
			mFly.Update(input.Keyboard, input.Mouse, deltaTime);

		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);

		// Orbiting the local space emitter is the whole demonstration of cell seven: the cloud
		// rides along rigidly instead of streaming out behind.
		mOrbitTime += deltaTime;
		let centre = CellPosition(7);
		mScene.SetLocalPosition(mLocalEmitter, .(centre.X + 2.5f * Cos(mOrbitTime * 1.5f),
			centre.Y + 1.5f, centre.Z + 2.5f * Sin(mOrbitTime * 1.5f)));

		LabelCells(host);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		base.OnRenderWindow(host, ref frame);

		if (mOverlay != null)
			mOverlay.Render(ref frame);
	}

	/// The atlas goes back while the device is still up. A destructor would run too late, and
	/// in no defined order against the graphics device.
	public override void OnShutdown(IApplicationHost host)
	{
		if (mBlastAtlas != null)
			mBlastAtlas.Release();

		base.OnShutdown(host);
	}

	// ---- the stage ----

	/// A cell's floor level centre. The grid is row major and centred on the origin, so a
	/// caller adds only its own height offset.
	private static Float3 CellPosition(int32 index)
	{
		let half = (cGridColumns - 1) * 0.5f;
		let column = (float)(index % cGridColumns);
		let row = (float)(index / cGridColumns);
		return .((column - half) * cCellSpacing, 0.2f, (row - half) * cCellSpacing);
	}

	private void BuildStage()
	{
		if (let meshes = mScene.GetSystem<MeshComponentManager>())
		{
			let floor = mScene.CreateEntity("floor");
			mScene.SetLocalPosition(floor, .(0.0f, 0.0f, 0.0f));

			let mesh = meshes.Add(floor);
			mesh.Mesh.SetDirect(TrackMesh(Primitives.Plane(80.0f, 80.0f)));
			mesh.SetMaterial(TrackMaterial(MaterialPresets.CreatePbr("floor",
				.(0.20f, 0.22f, 0.26f, 1.0f), 0.0f, 0.8f)));
		}

		if (let lights = mScene.GetSystem<LightComponentManager>())
		{
			let key = mScene.CreateEntity("key");
			var transform = mScene.GetLocalTransform(key);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.9f);
			mScene.SetLocalTransform(key, transform);

			let light = lights.Add(key);
			light.Type = .Directional;
			// Cool and dim, so the warm ember point lights still read against it.
			light.Color = .(0.6f, 0.7f, 0.95f, 1.0f);
			light.Intensity = 1.0f;
		}
	}

	private void BuildShowcase(IApplicationHost host)
	{
		let emitters = mScene.GetSystem<ParticleEffectComponentManager>();
		if (emitters == null)
			return;

		let obstacle = CellPosition(6) + Float3(0.0f, 1.4f, 0.0f);
		const float cObstacleRadius = 1.4f;

		mFountain = Place(emitters, 0, "fountain", => ShowcaseEffects.Fountain);
		BuildMeshCells(emitters);
		mEmbers = Place(emitters, 3, "embers", => ShowcaseEffects.Embers, (component) =>
			{
				component.LightIntensity = 14.0f;
				// A smaller range keeps the pools from overlapping into a visible cluster grid.
				component.LightRange = 6.0f;
			});

		mHaze = Place(emitters, 4, "haze", => ShowcaseEffects.Haze, null, .(0.0f, 0.4f, 0.0f));
		Place(emitters, 5, "trail-sparks", => ShowcaseEffects.Trail);
		BuildCollisionCell(emitters, obstacle, cObstacleRadius);

		mLocalEmitter = PlaceEntity(emitters, 7, "orbit", => ShowcaseEffects.Local);

		Place(emitters, 8, "smoke", => ShowcaseEffects.Smoke);
		Place(emitters, 9, "fire", => ShowcaseEffects.Fire);
		Place(emitters, 10, "campfire", => ShowcaseEffects.Campfire);
		Place(emitters, 11, "fireworks", => ShowcaseEffects.Fireworks);
		Place(emitters, 12, "tornado", => ShowcaseEffects.Tornado);

		BuildExplosionCell(emitters, host);

		Place(emitters, 14, "magic", => ShowcaseEffects.MagicCircle);
		Place(emitters, 15, "fireflies", => ShowcaseEffects.Fireflies);

		SetupCookedDemo(emitters);

		// Only the three A/B systems follow the slider. Smoke keeps soft off, for the reason
		// its builder records.
		ApplySoft(mFountain);
		ApplySoft(mEmbers);
		ApplySoft(mHaze);
	}

	/// Two mesh systems side by side with an IDENTICAL simulation: the only difference is the
	/// material, and additive is what routes one of them to the transparent pass.
	private void BuildMeshCells(ParticleEffectComponentManager emitters)
	{
		let solid = PlaceEntity(emitters, 1, "shards-solid", => ShowcaseEffects.MeshShards);
		if (let component = emitters.Get(solid))
		{
			component.Mesh.SetDirect(TrackMesh(Primitives.Cube(1.0f)));
			component.Material.SetDirect(TrackMaterial(MaterialPresets.CreatePbr("shards-solid",
				.(0.35f, 0.6f, 0.9f, 1.0f), 0.1f, 0.5f)));
			component.MeshScale = 0.5f;
		}

		let glow = PlaceEntity(emitters, 2, "shards-glow", => ShowcaseEffects.MeshShards);
		if (let component = emitters.Get(glow))
		{
			component.Mesh.SetDirect(TrackMesh(Primitives.Cube(1.0f)));

			let material = TrackMaterial(MaterialPresets.CreatePbr("shards-glow",
				.(0.4f, 0.8f, 1.0f, 1.0f), 0.0f, 0.4f));
			material.Pipeline.BlendMode = .Additive;
			material.Pipeline.DepthMode = .ReadOnly;
			component.Material.SetDirect(material);
			component.MeshScale = 0.5f;
		}
	}

	private void BuildCollisionCell(ParticleEffectComponentManager emitters, Float3 obstacle,
		float radius)
	{
		let effect = new ParticleEffect();
		mEffects.Add(effect);
		ShowcaseEffects.Collision(effect, obstacle, radius);

		let entity = mScene.CreateEntity("rain");
		mScene.SetLocalPosition(entity, CellPosition(6) + Float3(0.0f, 6.0f, 0.0f));
		emitters.Add(entity);
		emitters.SetEffect(entity, effect);

		// The DRAWN sphere the collider mirrors. Two numbers that have to agree, and a
		// mismatch shows up as rain bouncing off nothing.
		if (let meshes = mScene.GetSystem<MeshComponentManager>())
		{
			let drawn = mScene.CreateEntity("obstacle");
			mScene.SetLocalPosition(drawn, obstacle);

			let mesh = meshes.Add(drawn);
			mesh.Mesh.SetDirect(TrackMesh(Primitives.Sphere(radius)));
			mesh.SetMaterial(TrackMaterial(MaterialPresets.CreatePbr("obstacle",
				.(0.7f, 0.7f, 0.72f, 1.0f), 0.1f, 0.4f)));
		}
	}

	/// Two emitters in ONE cell: the textured blast and the untextured debris and shockwave,
	/// burst synced so they read as a single event.
	private void BuildExplosionCell(ParticleEffectComponentManager emitters, IApplicationHost host)
	{
		let blast = PlaceEntity(emitters, 13, "explosion", => ShowcaseEffects.ExplosionBlast);

		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (device != null)
		{
			mBlastAtlas = new BlastAtlas(device);
			if (let component = emitters.Get(blast))
				component.Texture = mBlastAtlas.View;
		}

		PlaceEntity(emitters, 13, "explosion-fx", => ShowcaseEffects.ExplosionFx);
	}

	private function void BuildEffect(ParticleEffect effect);
	private function void TuneComponent(ParticleEffectComponent* component);

	private ParticleEffect Place(ParticleEffectComponentManager emitters, int32 cell,
		StringView name, BuildEffect build, TuneComponent tune = null,
		Float3 offset = .(0, 0, 0))
	{
		let effect = new ParticleEffect();
		mEffects.Add(effect);
		build(effect);

		let entity = mScene.CreateEntity(name);
		mScene.SetLocalPosition(entity, CellPosition(cell) + offset);
		emitters.Add(entity);
		emitters.SetEffect(entity, effect);

		if (tune != null)
		{
			if (let component = emitters.Get(entity))
				tune(component);
		}

		return effect;
	}

	private EntityHandle PlaceEntity(ParticleEffectComponentManager emitters, int32 cell,
		StringView name, BuildEffect build)
	{
		let effect = new ParticleEffect();
		mEffects.Add(effect);
		build(effect);

		let entity = mScene.CreateEntity(name);
		mScene.SetLocalPosition(entity, CellPosition(cell));
		emitters.Add(entity);
		emitters.SetEffect(entity, effect);
		return entity;
	}

	private StaticMesh TrackMesh(StaticMesh mesh)
	{
		mMeshes.Add(mesh);
		return mesh;
	}

	private Material TrackMaterial(Material material)
	{
		mMaterials.Add(material);
		return material;
	}

	/// The authoring pipeline end to end, at startup: author an asset in code, bake it into a
	/// content database, bind the cooked resource back through a manager, and drive a
	/// component from it. An editor would bake offline; doing it here proves the same path.
	private void SetupCookedDemo(ParticleEffectComponentManager emitters)
	{
		ParticlesPipeline.RegisterAll();
		ParticleResources.RegisterAll();
		ParticleModules.RegisterModules();

		let cookedDir = DataPath(cCookedOutputDir, .. scope String());
		if (Directory.CreateDirectory(cookedDir) case .Err)
		{
			if (!Directory.Exists(cookedDir))
				return;
		}

		mCookedSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mCookedMount = new NativeFileSystem(cookedDir);
		mCookedDatabase = new ContentDatabase(mCookedMount, mCookedSerializers, "rasset");

		let instance = mCookedDatabase.RootGroup.CreateInstance("cooked_demo",
			"Sedulous.Particles.Resource.ParticleEffectResource");
		if (instance == null)
			return;

		let asset = scope ParticleEffectAsset();
		ShowcaseEffects.Cooked(asset.Effect);

		let builder = scope ParticleEffectAssetBuilder();
		let context = scope AssetBuildContext();
		context.Output = instance;
		context.Database = mCookedDatabase;
		context.Serializers = mCookedSerializers;
		if (!(builder.Build(asset, context) case .Ok))
			return;

		mCookedResources = new ResourceManager(mCookedDatabase, null);
		mCookedFactory = new ParticleEffectFactory();
		mCookedResources.AddFactory(mCookedFactory);

		let bound = mCookedResources.Bind<ParticleEffectResource>(instance.Id);
		let resource = bound.Get;
		if (resource == null)
			return;

		mCookedEmitter = mScene.CreateEntity("cooked");
		mScene.SetLocalPosition(mCookedEmitter, .(0.0f, 0.2f, 34.0f));
		let component = emitters.Add(mCookedEmitter);
		emitters.AttachResource(component, resource);
		mHaveCooked = true;
	}

	/// Pushes the current soft particle settings onto every system of an effect. A distance of
	/// nought is what disables it.
	private void ApplySoft(ParticleEffect effect)
	{
		if (effect == null)
			return;

		for (int32 i < effect.SystemCount)
		{
			if (let system = effect.GetSystem(i))
			{
				system.SoftParticles = mSoftOn;
				system.SoftDistance = mSoftDistance;
			}
		}
	}

	/// A floor label under each cell, so every system says what it is without a legend to
	/// cross reference.
	private void LabelCells(IApplicationHost host)
	{
		let render = host.Context.GetSubsystem<RenderSubsystem>();
		if (render == null)
			return;

		let draw = render.DebugScene(mScene);
		for (int32 i < 16)
		{
			draw.DrawText3D(CellPosition(i) + Float3(0.0f, 0.15f, cCellSpacing * 0.42f),
				cCellNames[i], .(0.85f, 0.9f, 1.0f, 1.0f));
		}

		if (mHaveCooked)
		{
			draw.DrawText3D(.(0.0f, 0.3f, 37.0f), "COOKED: asset -> bake -> load",
				.(0.4f, 1.0f, 0.9f, 1.0f));
		}
	}

	private void BuildHud()
	{
		igSetNextWindowPos(.() { x = 12, y = 12 }, (int32)ImGuiCond.ImGuiCond_FirstUseEver, .());
		if (igBegin("ParticleFX", null, 0))
		{
			let system = (mFountain != null) ? mFountain.GetSystem(0) : null;
			igText(scope $"alive: {(system != null) ? system.AliveCount : 0}");
			igText(scope $"fps: {1.0f / Math.Max(mFrameSmooth, 0.0001f):0}");

			if (system != null)
			{
				var emitting = system.Emitter.IsEmitting;
				if (igCheckbox("emit", &emitting))
					system.Emitter.IsEmitting = emitting;

				igSliderFloat("rate", &system.Emitter.SpawnRate, 0.0f, 12000.0f, "%.0f/s", 0);

				// Read at extract, so changing it here is live and all four blend variants
				// are eyeballable without a restart.
				let blends = scope char8*[]("Alpha".CStr(), "Additive".CStr(),
					"Premultiplied".CStr(), "Multiply".CStr());
				var blend = (int32)system.BlendMode;
				if (igCombo_Str_arr("blend", &blend, blends.Ptr, 4, -1))
					system.BlendMode = (ParticleBlendMode)blend;
			}

			// The slider keeps its value while the checkbox is off, so toggling restores the
			// band rather than resetting it.
			var changed = igCheckbox("soft particles", &mSoftOn);
			changed |= igSliderFloat("soft dist", &mSoftDistance, 0.0f, 4.0f, "%.2f", 0);
			if (changed)
			{
				ApplySoft(mFountain);
				ApplySoft(mEmbers);
				ApplySoft(mHaze);
			}

			igTextDisabled("WASD and the right button to fly. The grid, row by row:");
			igTextDisabled("fountain / mesh solid / mesh glow / embers");
			igTextDisabled("haze / trail / collision / orbit");
			igTextDisabled("smoke / fire / campfire / fireworks");
			igTextDisabled("tornado / explosion / magic circle / fireflies");
		}
		igEnd();
	}
}
