using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Render;
using Sedulous.Extensions.Imgui;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Samples.Common;
using cimgui_Beef;

namespace Samples.RenderStressTest;

/// A deliberate worst case for the renderer: a flat grid of spheres arranged so the camera sees
/// ALL of them at once, which is what takes frustum culling out of the picture.
///
/// Two axes of stress, each defeating one optimisation. Unique materials defeat BATCHING, one
/// draw per sphere. The bob rewrites every transform each frame, so nothing can be cached as
/// static. MultiMesh is the opposite end: the whole grid as one instanced set.
class RenderStressTestApp : DefaultApplication
{
	private const int32 cSpheresPerBatch = 8000;
	private const float cSphereSpacing = 1.5f;
	/// The base height above a floor the spheres have radius 0.5 on.
	private const float cSphereHeight = 2.5f;
	private const float cFloorBaseSize = 500.0f;

	private Scene mScene = null;
	private EntityHandle mCamera = default;
	private EntityHandle mSun = default;
	private EntityHandle mGround = default;

	private StaticMesh mSphere = null ~ delete _;
	private StaticMesh mGroundMesh = null ~ delete _;
	private Material mSharedMaterial = null ~ delete _;
	private Material mGroundMaterial = null ~ delete _;
	private List<Material> mUniqueMaterials = new .() ~ DeleteContainerAndItems!(_);

	private List<EntityHandle> mSpheres = new .() ~ delete _;
	private List<Float4x4> mInstanceTransforms = new .() ~ delete _;
	private EntityHandle mMultiMeshEntity = default;

	private ImguiSubsystem mOverlay = null ~ delete _;

	private int32 mBatchCount = 0;
	private int32 mGridSize = 0;
	private bool mUnique = false;
	private bool mBob = false;
	private bool mMultiMesh = false;
	private bool mShowStats = true;
	private float mTime = 0.0f;
	private float mFrameMs = 0.0f;

	private FlyCamera mFly = .();

	/// Uncapped on purpose: a frame time that tracks the display's refresh measures the
	/// display, not the renderer. It tears, which is fine for a benchmark.
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

		mScene = PrimaryScenes.CreateScene("stress");
		mFly.Position = .(0.0f, 50.0f, 200.0f);
		mFly.Pitch = -0.245f;

		// Enough ambient that the unlit hemispheres are not pure black, and no more: this is
		// a benchmark, not a beauty shot.
		if (let environment = mScene.GetSystem<EnvironmentSystem>())
		{
			environment.Environment.AmbientColor = .(0.10f, 0.12f, 0.16f, 1.0f);
			environment.Environment.AmbientIntensity = 0.30f;
		}

		// ONE material and ONE mesh for every sphere by default, which is exactly what lets
		// the renderer collapse the grid into a single instanced draw.
		mSharedMaterial = MaterialPresets.CreatePbr("stress.shared", .(0.7f, 0.7f, 0.7f, 1.0f),
			0.1f, 0.4f);
		mSphere = Primitives.Sphere(0.5f, 16, 8);

		if (let meshes = mScene.GetSystem<MeshComponentManager>())
		{
			mGround = mScene.CreateEntity("ground");
			mScene.SetLocalPosition(mGround, .(0.0f, 0.0f, 0.0f));

			mGroundMesh = Primitives.Plane(cFloorBaseSize, cFloorBaseSize);
			mGroundMaterial = MaterialPresets.CreatePbr("stress.ground", .(0.3f, 0.3f, 0.3f, 1.0f),
				0.0f, 0.8f);

			let mesh = meshes.Add(mGround);
			mesh.Mesh.SetDirect(mGroundMesh);
			mesh.SetMaterial(mGroundMaterial);
		}

		if (let lights = mScene.GetSystem<LightComponentManager>())
		{
			mSun = mScene.CreateEntity("sun");
			var transform = mScene.GetLocalTransform(mSun);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.9f)
				* Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 0.5f);
			mScene.SetLocalTransform(mSun, transform);

			let light = lights.Add(mSun);
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.9f, 1.0f);
			light.Intensity = 1.5f;
			light.CastsShadows = true;
		}

		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
		{
			let camera = cameras.Add(mCamera);
			camera.FovYRadians = 1.04719755f; // 60 degrees
			camera.NearZ = 0.1f;
			camera.FarZ = 2000.0f;
			camera.ClearColor = .(0.04f, 0.05f, 0.07f, 1.0f);
		}
		PushCameraToEntity();

		AddSphereBatch();

		// The sky and sun together are bright enough that the tone mapper washes out at one.
		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
			render.Exposure = 0.5f;

		Console.WriteLine("=== Render Stress Test ===");
		Console.WriteLine("  Space: +8000 spheres   Backspace: -8000");
		Console.WriteLine("  U: unique materials (defeats batching)");
		Console.WriteLine("  B: sin wave bob (defeats static caching)");
		Console.WriteLine("  M: MultiMesh (the whole grid as ONE instanced set)");
		Console.WriteLine("  H: the panel   K: directional shadows   Esc: exit");
		Console.WriteLine("==========================");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		mFrameMs = mFrameMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (mOverlay != null)
		{
			mOverlay.NewFrame(input, deltaTime);
			BuildHud(host.Context.GetSubsystem<RenderSubsystem>());
		}

		if ((mScene == null) || (input == null) || (input.Keyboard == null))
			return;

		HandleKeys(host, input.Keyboard);

		mFly.Update(input.Keyboard, input.Mouse, deltaTime);
		PushCameraToEntity();

		mTime += deltaTime;
		if (mBob)
			ApplyBob();
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		// The default render path reads the aspect from the component, so it has to track the
		// backbuffer or a resize stretches the scene.
		if ((mScene != null) && (frame.Height > 0))
		{
			if (let cameras = mScene.GetSystem<CameraComponentManager>())
			{
				if (let camera = cameras.Get(mCamera))
					camera.Aspect = (float)frame.Width / (float)frame.Height;
			}
		}

		base.OnRenderWindow(host, ref frame);

		if (mOverlay != null)
			mOverlay.Render(ref frame);
	}

	public override void OnShutdown(IApplicationHost host)
	{
		base.OnShutdown(host);
		Console.WriteLine("=== Stress Test Shutdown ===");
	}

	// ---- the controls ----

	private void HandleKeys(IApplicationHost host, IKeyboard keyboard)
	{
		if (keyboard.IsKeyPressed(.Escape))
		{
			host.RequestExit(0);
			return;
		}

		if (keyboard.IsKeyPressed(.Space))
			AddSphereBatch();
		if (keyboard.IsKeyPressed(.Backspace))
			RemoveLastBatch();

		if (keyboard.IsKeyPressed(.U))
		{
			mUnique = !mUnique;
			RebuildSphereMaterials();
			Console.WriteLine(mUnique ? "Unique materials: ON (a draw per sphere)"
				: "Unique materials: OFF (shared, batched)");
		}

		if (keyboard.IsKeyPressed(.B))
		{
			mBob = !mBob;
			Console.WriteLine(mBob ? "Sin wave bob: ON (transforms rewritten every frame)"
				: "Sin wave bob: OFF");
		}

		if (keyboard.IsKeyPressed(.M))
		{
			mMultiMesh = !mMultiMesh;
			RebuildMultiMesh();
			Console.WriteLine(mMultiMesh ? "MultiMesh: ON (the whole grid as one instanced set)"
				: "MultiMesh: OFF (per entity spheres)");
		}

		if (keyboard.IsKeyPressed(.H))
			mShowStats = !mShowStats;

		let render = host.Context.GetSubsystem<RenderSubsystem>();
		if (render != null)
		{
			if (keyboard.IsKeyPressed(.T))
			{
				render.TaaEnabled = !render.TaaEnabled;
				Console.WriteLine(render.TaaEnabled ? "TAA: ON (motion vectors active)"
					: "TAA: OFF");
			}
			if (keyboard.IsKeyPressed(.I))
			{
				render.InstanceSharing = !render.InstanceSharing;
				Console.WriteLine(render.InstanceSharing
					? "Instance sharing: ON (the prepass builds once, the forward pass reuses)"
					: "Instance sharing: OFF (the forward pass refills)");
			}
		}

		if (keyboard.IsKeyPressed(.K) && mSun.IsAssigned)
		{
			if (let lights = mScene.GetSystem<LightComponentManager>())
			{
				if (let light = lights.Get(mSun))
				{
					light.CastsShadows = !light.CastsShadows;
					Console.WriteLine(light.CastsShadows ? "Directional shadows: ON (cascaded)"
						: "Directional shadows: OFF");
				}
			}
		}
	}

	/// Rewrites every sphere's height each frame, phased from its own position so the grid
	/// ripples rather than pulsing as one block. The phase comes from the position rather
	/// than the index, so it stays put as the grid widens.
	private void ApplyBob()
	{
		const float cAmplitude = 1.0f;
		const float cSpeed = 2.0f;

		for (let entity in mSpheres)
		{
			var transform = mScene.GetLocalTransform(entity);
			let phase = (transform.Position.X + transform.Position.Z) * 0.2f;
			// AROUND the base height rather than from it, so the spheres stay clear of the
			// floor and their shadows stay separate.
			transform.Position.Y = cSphereHeight + Sin(mTime * cSpeed + phase) * cAmplitude;
			mScene.SetLocalTransform(entity, transform);
		}
	}

	// ---- the grid ----

	/// The position depends only on a GLOBAL index, so widening the grid leaves every existing
	/// sphere where it was.
	private Float3 SphereTranslation(int32 index)
	{
		let gx = index % mGridSize;
		let gz = index / mGridSize;
		let x = ((float)gx - (float)mGridSize * 0.5f) * cSphereSpacing;
		let z = ((float)gz - (float)mGridSize * 0.5f) * cSphereSpacing;
		return .(x, cSphereHeight, z);
	}

	private void AddSphereBatch()
	{
		let startIndex = mBatchCount * cSpheresPerBatch;
		let newTotal = (mBatchCount + 1) * cSpheresPerBatch;
		mGridSize = (int32)Ceil(Sqrt((float)newTotal));

		if (mMultiMesh)
		{
			for (int32 i < cSpheresPerBatch)
				mInstanceTransforms.Add(Float4x4.Translation(SphereTranslation(startIndex + i)));
		}
		else if (let meshes = mScene.GetSystem<MeshComponentManager>())
		{
			for (int32 i < cSpheresPerBatch)
			{
				let index = startIndex + i;
				let entity = mScene.CreateEntity("sphere");
				mScene.SetLocalPosition(entity, SphereTranslation(index));

				let mesh = meshes.Add(entity);
				mesh.Mesh.SetDirect(mSphere);
				AssignSphereMaterial(mesh, index);
				mSpheres.Add(entity);
			}
		}
		else
		{
			return;
		}

		mBatchCount++;
		FitFloorAndCamera();
		if (mMultiMesh)
			PushMultiMesh();
		PrintCounts();
	}

	private void RemoveLastBatch()
	{
		if (mBatchCount <= 0)
			return;

		if (mMultiMesh)
		{
			let remove = Math.Min((int)cSpheresPerBatch, mInstanceTransforms.Count);
			mInstanceTransforms.RemoveRange(mInstanceTransforms.Count - remove, remove);
		}
		else
		{
			let remove = Math.Min((int)cSpheresPerBatch, mSpheres.Count);
			for (int i < remove)
			{
				mScene.DestroyEntity(mSpheres.PopBack());
				if (mUnique && !mUniqueMaterials.IsEmpty)
					delete mUniqueMaterials.PopBack();
			}
		}

		mBatchCount--;
		FitFloorAndCamera();
		if (mMultiMesh)
			PushMultiMesh();
		PrintCounts();
	}

	/// The floor grows with the grid and the camera pulls back to frame it, so every sphere
	/// stays visible: the moment one falls outside the frustum the benchmark stops being a
	/// worst case.
	private void FitFloorAndCamera()
	{
		let gridWidth = (float)mGridSize * cSphereSpacing;

		let scale = Math.Max(0.1f, (gridWidth + 40.0f) / cFloorBaseSize);
		var floor = mScene.GetLocalTransform(mGround);
		floor.Scale = .(scale, 1.0f, scale);
		mScene.SetLocalTransform(mGround, floor);

		let extent = gridWidth * 0.5f + 6.0f;
		let distance = extent / Tan(0.5236f) + 10.0f; // half of sixty degrees
		let height = extent * 0.55f + cSphereHeight;

		mFly.Position = .(0.0f, cSphereHeight + height, distance);
		mFly.Yaw = 0.0f;
		mFly.Pitch = -Atan2(height, distance);

		if (let cameras = mScene.GetSystem<CameraComponentManager>())
		{
			if (let camera = cameras.Get(mCamera))
				camera.FarZ = distance + extent * 2.0f + 200.0f; // never far cull a sphere
		}
		PushCameraToEntity();
	}

	private void AssignSphereMaterial(MeshComponent* mesh, int32 index)
	{
		if (mUnique)
		{
			let hue = (float)(index % 360) / 360.0f;
			let colour = HueRamp.HsvToRgb(hue, 0.8f, 0.9f);
			let material = MaterialPresets.CreatePbr("stress.unique",
				.(colour.X, colour.Y, colour.Z, 1.0f), 0.1f, 0.4f);
			mesh.SetMaterial(material);
			mUniqueMaterials.Add(material);
		}
		else
		{
			mesh.SetMaterial(mSharedMaterial);
		}

		mesh.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
	}

	/// Rebuilt from scratch rather than patched, so the material count tracks the mode
	/// exactly: in shared mode every unique material goes.
	private void RebuildSphereMaterials()
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		ClearAndDeleteItems!(mUniqueMaterials);
		for (int i < mSpheres.Count)
		{
			if (let mesh = meshes.Get(mSpheres[i]))
				AssignSphereMaterial(mesh, (int32)i);
		}
	}

	private void PushMultiMesh()
	{
		let sets = mScene.GetSystem<InstancedMeshComponentManager>();
		if (sets == null)
			return;

		if (mInstanceTransforms.IsEmpty)
		{
			if (mMultiMeshEntity.IsAssigned)
			{
				mScene.DestroyEntity(mMultiMeshEntity);
				mMultiMeshEntity = default;
			}
			return;
		}

		if (!mMultiMeshEntity.IsAssigned)
			mMultiMeshEntity = mScene.CreateEntity("multimesh");

		let set = sets.Has(mMultiMeshEntity) ? sets.Get(mMultiMeshEntity)
			: sets.Add(mMultiMeshEntity);
		set.Mesh.SetDirect(mSphere);
		set.Material.SetDirect(mSharedMaterial);
		set.SetInstances(mInstanceTransforms);
	}

	/// Entering MultiMesh mode DESTROYS the per entity spheres rather than hiding them, which
	/// is what makes the extract genuinely constant time: a hidden entity is still walked.
	private void RebuildMultiMesh()
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		if (mMultiMesh)
		{
			mInstanceTransforms.Clear();
			for (let entity in mSpheres)
				mInstanceTransforms.Add(mScene.GetWorldMatrix(entity));
			for (let entity in mSpheres)
				mScene.DestroyEntity(entity);

			mSpheres.Clear();
			// The set draws with one shared material, so the unique ones have nothing left
			// pointing at them.
			ClearAndDeleteItems!(mUniqueMaterials);
			PushMultiMesh();
		}
		else
		{
			if (mMultiMeshEntity.IsAssigned)
			{
				mScene.DestroyEntity(mMultiMeshEntity);
				mMultiMeshEntity = default;
			}

			for (int i < mInstanceTransforms.Count)
			{
				// Translation only, so the position row is the whole transform.
				let matrix = mInstanceTransforms[i];
				let entity = mScene.CreateEntity("sphere");
				mScene.SetLocalPosition(entity, .(matrix.M[3][0], matrix.M[3][1], matrix.M[3][2]));

				let mesh = meshes.Add(entity);
				mesh.Mesh.SetDirect(mSphere);
				AssignSphereMaterial(mesh, (int32)i);
				mSpheres.Add(entity);
			}
			mInstanceTransforms.Clear();
		}

		PrintCounts();
	}

	private void PrintCounts()
	{
		let count = mMultiMesh ? mInstanceTransforms.Count : mSpheres.Count;
		let materials = (mMultiMesh || !mUnique) ? 1 : mUniqueMaterials.Count;
		let tag = mMultiMesh ? "  [multimesh]" : "";
		Console.WriteLine(scope $"  spheres {count}  batches {mBatchCount}  grid {mGridSize}x{mGridSize}  materials {materials}{tag}");
	}

	private void PushCameraToEntity()
	{
		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);
	}

	private void BuildHud(RenderSubsystem render)
	{
		if (!mShowStats)
			return;

		igBegin("Render Stress Test", null, 0);

		let fps = (mFrameMs > 0.001f) ? 1000.0f / mFrameMs : 0.0f;
		igText(scope $"{fps:0} fps   {mFrameMs:0.00} ms");

		let label = mMultiMesh ? "instances" : "spheres";
		let count = mMultiMesh ? mInstanceTransforms.Count : mSpheres.Count;
		igText(scope $"{label} {count}   batches {mBatchCount}   grid {mGridSize}x{mGridSize}");
		igSeparator();

		if (igButton("+ batch (Space)", .()))
			AddSphereBatch();
		igSameLine(0.0f, -1.0f);
		if (igButton("- batch (Backspace)", .()))
			RemoveLastBatch();

		var unique = mUnique;
		if (igCheckbox("Unique materials (U)", &unique))
		{
			mUnique = unique;
			RebuildSphereMaterials();
		}

		igCheckbox("Sin wave bob (B)", &mBob);

		var multiMesh = mMultiMesh;
		if (igCheckbox("MultiMesh: the whole grid as one instanced set (M)", &multiMesh))
		{
			mMultiMesh = multiMesh;
			RebuildMultiMesh();
		}

		if (render != null)
			BuildRenderRows(render);

		if (mSun.IsAssigned)
		{
			if (let lights = mScene.GetSystem<LightComponentManager>())
			{
				if (let light = lights.Get(mSun))
				{
					var shadows = light.CastsShadows;
					if (igCheckbox("Directional shadows (K)", &shadows))
						light.CastsShadows = shadows;
				}
			}
		}

		igSeparator();
		igTextUnformatted("H hides the panel", null);
		igTextUnformatted("WASD and QE move, the right button looks, Shift is fast, Esc exits",
			null);
		igEnd();
	}

	private void BuildRenderRows(RenderSubsystem render)
	{
		var taa = render.TaaEnabled;
		if (igCheckbox("TAA (T)", &taa))
			render.TaaEnabled = taa;

		var sharing = render.InstanceSharing;
		if (igCheckbox("Instance sharing (I)", &sharing))
			render.InstanceSharing = sharing;

		var culling = render.ViewCulling;
		if (igCheckbox("View frustum cull", &culling))
			render.ViewCulling = culling;

		if (culling)
		{
			render.ViewCullStats(let culled, let total);
			igSameLine(0.0f, -1.0f);
			igTextDisabled(scope $"({culled}/{total} culled)");
		}

		igSeparator();

		var exposure = render.Exposure;
		if (igSliderFloat("Exposure", &exposure, 0.05f, 4.0f, "%.2f", 0))
			render.Exposure = exposure;

		var bloom = render.BloomEnabled;
		if (igCheckbox("Bloom", &bloom))
			render.BloomEnabled = bloom;

		var shadowDistance = render.ShadowDistance;
		if (igSliderFloat("Shadow dist", &shadowDistance, 50.0f, 1000.0f, "%.0f", 0))
			render.ShadowDistance = shadowDistance;

		var shadowFade = render.ShadowFarFade;
		if (igSliderFloat("Shadow fade", &shadowFade, 2.0f, 150.0f, "%.0f", 0))
			render.ShadowFarFade = shadowFade;
	}
}
