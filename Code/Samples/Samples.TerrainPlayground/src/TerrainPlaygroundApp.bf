using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Terrain;
using Sedulous.Extensions.Imgui;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Heightfield;
using Sedulous.Materials;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Terrain.Resource;
using Samples.Common;
using cimgui_Beef;

namespace Samples.TerrainPlayground;

/// The terrain showcase: a heightfield built IN CODE, wrapped in a resource with no cook behind
/// it, and drawn by the engine's chunked terrain renderer.
///
/// In code rather than cooked on purpose: a reference takes a direct product as readily as an
/// identity, so a sample can show the renderer without a content database anywhere near it.
class TerrainPlaygroundApp : DefaultApplication
{
	/// Four by four chunks, which is the smallest grid that shows the level of detail seams.
	private const int32 cGridSize = 257;
	private const float cWorldSize = 256.0f;
	private const float cMaxHeight = 60.0f;
	private const float cCasterRadius = 8.0f;

	private Scene mScene = null;
	private EntityHandle mCamera = default;
	private EntityHandle mSun = default;
	private EntityHandle mTerrain = default;
	private EntityHandle mCaster = default;

	private Heightfield mHeightfield = null ~ delete _;
	private TerrainResource mTerrainResource = null ~ delete _;
	private StaticMesh mCasterMesh = null ~ delete _;
	private Material mCasterMaterial = null ~ delete _;

	/// OWNED here, because the context drives a registered subsystem but never frees it.
	private ImguiSubsystem mOverlay = null ~ delete _;

	private FlyCamera mFly = .();
	private float mFrameSmooth = 0.016f;

	// What the panel drives.
	private float mSunAzimuth = 0.7f;
	private float mSunElevation = 0.9f;
	private float mLodBias = 0.0f;
	private TerrainType mType = .Hills;
	private float mAmplitude = 0.7f;
	private float mFrequency = 0.06f;
	private bool mOrbit = true;
	private float mOrbitTime = 0.0f;
	private float mOrbitSpeed = 0.6f;
	private float mCasterHeight = 70.0f;
	private float mOrbitRadius = 75.0f;

	public override void Configure(IApplicationHost host)
	{
		base.Configure(host);

		let graphics = host.Graphics;
		if ((graphics != null) && (graphics.Raw != null))
		{
			// REGISTERED rather than created by the context: the overlay needs the device and
			// the frame count, which a default construction has no way to supply.
			mOverlay = new ImguiSubsystem(graphics.Raw, graphics.FramesInFlight, DataFileSystem);
			host.Context.RegisterSubsystem<ImguiSubsystem>(mOverlay);
		}
	}

	public override void OnStartup(IApplicationHost host)
	{
		base.OnStartup(host);

		mScene = PrimaryScenes.CreateScene("terrain");

		if (let environment = mScene.GetSystem<EnvironmentSystem>())
		{
			environment.Environment.AmbientColor = .(0.45f, 0.52f, 0.62f, 1.0f);
			environment.Environment.AmbientIntensity = 0.5f;
		}

		// High and pulled back, angled down: the level of detail rings are only visible from
		// above them.
		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
		{
			let camera = cameras.Add(mCamera);
			camera.ClearColor = .(0.55f, 0.70f, 0.90f, 1.0f); // sky
		}
		mFly.Position = .(0.0f, 110.0f, 175.0f);
		mFly.Pitch = -0.45f;

		mSun = mScene.CreateEntity("sun");
		if (let lights = mScene.GetSystem<LightComponentManager>())
		{
			let light = lights.Add(mSun);
			light.Type = .Directional;
			light.Color = .(1.0f, 0.96f, 0.88f, 1.0f);
			light.Intensity = 1.0f;
			light.CastsShadows = true; // the terrain both casts and receives
		}
		ApplySun();

		mHeightfield = new Heightfield(cGridSize, .(cWorldSize, cWorldSize), 0.0f, cMaxHeight);
		HeightfieldShapes.Generate(mHeightfield, mType, mAmplitude, mFrequency);

		mTerrainResource = new TerrainResource();
		mTerrainResource.Heightfield.SetDirect(mHeightfield); // the product itself, not an id

		mTerrain = mScene.CreateEntity("terrain");
		if (let terrains = mScene.GetSystem<TerrainComponentManager>())
		{
			let component = terrains.Add(mTerrain);
			component.Terrain.SetDirect(mTerrainResource);
			component.LodBias = mLodBias;
		}

		// A sphere that orbits overhead, so the cascaded shadow is something that MOVES: a
		// static shadow is hard to tell from baked shading.
		mCaster = mScene.CreateEntity("caster");
		if (let meshes = mScene.GetSystem<MeshComponentManager>())
		{
			mCasterMesh = Primitives.Sphere(cCasterRadius);
			mCasterMaterial = MaterialPresets.CreatePbr("caster", .(0.9f, 0.3f, 0.2f, 1.0f), 0.0f,
				0.5f);

			let mesh = meshes.Add(mCaster);
			mesh.Mesh.SetDirect(mCasterMesh);
			mesh.SetMaterial(mCasterMaterial);
		}
		ApplyCaster();
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);
		mFrameSmooth = mFrameSmooth * 0.9f + deltaTime * 0.1f;

		if (let overlay = host.Context.GetSubsystem<ImguiSubsystem>())
		{
			overlay.NewFrame((host.Shell != null) ? host.Shell.Input : null, deltaTime);
			BuildPanel();
		}

		if (host.Shell != null)
			mFly.Update(host.Shell.Input.Keyboard, host.Shell.Input.Mouse, deltaTime);

		if (mScene == null)
			return;

		var cameraTransform = mScene.GetLocalTransform(mCamera);
		cameraTransform.Position = mFly.Position;
		cameraTransform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, cameraTransform);

		if (mOrbit)
			mOrbitTime += deltaTime * mOrbitSpeed;
		ApplyCaster(); // re-applied every frame so the sliders track live
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		base.OnRenderWindow(host, ref frame);

		// AFTER the scene, so the panel is drawn over it rather than under.
		if (let overlay = host.Context.GetSubsystem<ImguiSubsystem>())
			overlay.Render(ref frame);
	}

	/// The light's forward is its travel direction: yaw about up, then pitch DOWN by the
	/// elevation, so a higher elevation is a higher sun.
	private void ApplySun()
	{
		if (mScene == null)
			return;

		let rotation = Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), mSunAzimuth)
			* Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -mSunElevation);

		var transform = mScene.GetLocalTransform(mSun);
		transform.Rotation = rotation;
		mScene.SetLocalTransform(mSun, transform);
	}

	private void ApplyCaster()
	{
		if (mScene == null)
			return;

		mScene.SetLocalPosition(mCaster, .(mOrbitRadius * Math.Cos(mOrbitTime), mCasterHeight,
			mOrbitRadius * Math.Sin(mOrbitTime)));
	}

	private void BuildPanel()
	{
		igSetNextWindowPos(.() { x = 12, y = 12 }, (int32)ImGuiCond.ImGuiCond_FirstUseEver, .());
		igSetNextWindowSize(.() { x = 320, y = 0 }, (int32)ImGuiCond.ImGuiCond_FirstUseEver);

		if (igBegin("TerrainPlayground", null, 0))
		{
			igText(scope $"fps: {1.0f / Math.Max(mFrameSmooth, 0.0001f):0}");
			igText(scope $"grid: {cGridSize} x {cGridSize}  ({cWorldSize:0} x {cWorldSize:0} m)");
			igSeparator();

			igTextDisabled("Sun");
			var sunChanged = igSliderAngle("azimuth", &mSunAzimuth, 0.0f, 360.0f, "%.0f deg", 0);
			sunChanged |= igSliderAngle("elevation", &mSunElevation, 5.0f, 90.0f, "%.0f deg", 0);
			if (sunChanged)
				ApplySun();

			igSeparator();
			igTextDisabled("Level of detail");
			if (igSliderFloat("LOD bias", &mLodBias, -2.0f, 4.0f, "%.2f", 0))
			{
				if (let terrains = mScene.GetSystem<TerrainComponentManager>())
				{
					if (let component = terrains.Get(mTerrain))
						component.LodBias = mLodBias;
				}
			}
			igTextDisabled("plus is coarser sooner, minus holds detail out");

			igSeparator();
			igTextDisabled("Heightfield");

			let typeNames = scope char8*[]("Hills".CStr(), "Dome".CStr(), "Ripple".CStr(),
				"Plateau".CStr());
			var typeIndex = (int32)mType;
			var regenerate = igCombo_Str_arr("type", &typeIndex, typeNames.Ptr, 4, -1);
			mType = (TerrainType)typeIndex;

			regenerate |= igSliderFloat("amplitude", &mAmplitude, 0.05f, 1.0f, "%.2f", 0);
			regenerate |= igSliderFloat("frequency", &mFrequency, 0.01f, 0.3f, "%.3f", 0);
			if (igButton("Regenerate", .()) || regenerate)
			{
				if (mHeightfield != null)
					HeightfieldShapes.Generate(mHeightfield, mType, mAmplitude, mFrequency);
			}

			igSeparator();
			igTextDisabled("Shadow caster - watch its shadow sweep the terrain");
			igCheckbox("orbit", &mOrbit);
			igSliderFloat("caster height", &mCasterHeight, 12.0f, 130.0f, "%.0f", 0);
			igSliderFloat("orbit radius", &mOrbitRadius, 0.0f, 115.0f, "%.0f", 0);

			igSeparator();
			igTextDisabled("WASD and QE to fly, hold the right button to look, Shift is fast.");
		}
		igEnd();
	}
}
