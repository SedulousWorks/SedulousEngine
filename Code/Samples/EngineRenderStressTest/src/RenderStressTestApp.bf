namespace EngineRenderStressTest;

using System;
using System.Collections;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine;
using Sedulous.Engine.Render;
using Sedulous.Engine.Core;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Renderer.Debug;
using Sedulous.Renderer.Passes;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Resources;
using Sedulous.Shell.Input;
using Sedulous.Images.STB;
using Sedulous.Images.SDL;
using Sedulous.Textures.Resources;
using Sedulous.Profiler;
using Sedulous.Images;

class RenderStressTestApp : DefaultApplication
{
	public override ApplicationSettings Settings() => .()
	{
		Title = "Render Stress Test",
		EnableShaderCache = true,
		EnableValidation = false
	};

	private const int32 SpheresPerBatch = 8000;
	private const float SphereSpacing = 1.5f;

	// Scene
	private Scene mScene;
	private EntityHandle mCameraEntity;

	// Camera
	private Vector3 mCameraPosition = .(0, 50, 200);
	private float mYaw = Math.PI_f;
	private float mPitch = -0.3f;
	private bool mMouseCaptured = false;

	// Resources
	Material mPbrMaterial ~ delete _;
	StaticMeshResource mSphereRes;
	MaterialInstance mSharedMaterial ~ _?.ReleaseRef();

	// Sphere tracking
	private List<EntityHandle> mSphereEntities = new .() ~ delete _;
	private int32 mBatchCount = 0;
	private int32 mGridSize = 0;
	private bool mUseUniqueMaterials = false;
	private List<MaterialInstance> mUniqueMaterials = new .() ~
		{
			for (let m in _) m?.ReleaseRef();
			delete _;
		};

	// FPS tracking
	private float mFpsSmoothed = 0.0f;
	private float mFrameTimeMs = 0.0f;

	private bool mSinWaveBob = false;

	// Sky
	ITexture mSkyTexture;
	ITextureView mSkyTextureView;

	public override void OnStartup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		base.OnStartup(host);

		Console.WriteLine("=== Render Stress Test ===");
		Console.WriteLine("Controls:");
		Console.WriteLine("  Space: Add 8000 spheres");
		Console.WriteLine("  Backspace: Remove last batch");
		Console.WriteLine("  U: Toggle unique materials (more draw calls)");
		Console.WriteLine("  WASD/QE: Move camera");
		Console.WriteLine("  RMB: Look, Tab: Capture, Shift: Fast");
		Console.WriteLine("  Escape: Exit");

		SDLImageLoader.Initialize();
		STBImageLoader.Initialize();

		let sceneSub = host.Ctx.GetSubsystem<SceneSubsystem>();
		let renderSub = host.Ctx.GetSubsystem<RenderSubsystem>();
		let renderer = renderSub.RenderContext;
		let matSystem = renderer.MaterialSystem;
		let resources = mResourceSystem;

		mScene = sceneSub.CreateScene("StressTest");
		RuntimeScene = mScene;

		// PBR material template
		mPbrMaterial = Materials.CreatePBR("PBR", "forward",
			matSystem.WhiteTexture, matSystem.DefaultSampler);

		// Shared sphere material (gray)
		mSharedMaterial = new MaterialInstance(mPbrMaterial);
		mSharedMaterial.SetColor("BaseColor", .(0.7f, 0.7f, 0.7f, 1));
		mSharedMaterial.SetFloat("Roughness", 0.4f);
		mSharedMaterial.SetFloat("Metallic", 0.1f);

		// Sphere mesh
		mSphereRes = StaticMeshResource.CreateSphere(0.5f, 16, 8);
		resources.AddResource<StaticMeshResource>(mSphereRes);

		// Ground plane
		let planeRes = StaticMeshResource.CreatePlane(500, 500, 1, 1);
		resources.AddResource<StaticMeshResource>(planeRes);

		let planeMat = new MaterialInstance(mPbrMaterial);
		planeMat.SetColor("BaseColor", .(0.3f, 0.3f, 0.3f, 1));

		let planeEntity = mScene.CreateEntity("Ground");
		let meshMgr = mScene.GetModule<MeshComponentManager>();
		let planeHandle = meshMgr.CreateComponent(planeEntity);
		if (let comp = meshMgr.Get(planeHandle))
		{
			var planeRef = ResourceRef(planeRes.Id, .());
			defer planeRef.Dispose();
			comp.SetMeshRef(planeRef);
			comp.SetMaterial(0, planeMat);
		}
		planeMat.ReleaseRef();
		planeRes.ReleaseRef();

		// Directional light
		let lightMgr = mScene.GetModule<LightComponentManager>();
		let lightEntity = mScene.CreateEntity("Sun");
		mScene.SetLocalTransform(lightEntity, Transform.CreateLookAt(.(-3, 5, 2), .Zero));
		let lightHandle = lightMgr.CreateComponent(lightEntity);
		if (let light = lightMgr.Get(lightHandle))
		{
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.9f);
			light.Intensity = 1.5f;
			light.CastsShadows = false;
		}

		// Camera
		mCameraEntity = mScene.CreateEntity("Camera");
		mScene.SetLocalTransform(mCameraEntity, Transform.CreateLookAt(mCameraPosition, .Zero));
		let cameraMgr = mScene.GetModule<CameraComponentManager>();
		let cameraHandle = cameraMgr.CreateComponent(mCameraEntity);
		if (let camera = cameraMgr.Get(cameraHandle))
		{
			camera.FieldOfView = 60.0f;
			camera.NearPlane = 0.1f;
			camera.FarPlane = 2000.0f;
		}

		// Sky
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

				if (let skyPass = renderSub.GetPipeline(mScene).GetPass<SkyPass>())
				{
					skyPass.SkyTexture = mSkyTextureView;
					skyPass.Intensity = 1.0f;
				}
			}
			delete image;
		}

		// Add first batch
		AddSphereBatch();

		Console.WriteLine("=== Ready ===\n");
	}

	private void AddSphereBatch()
	{
		using (Profiler.Begin("AddSphereBatch"))
		{
		let meshMgr = mScene.GetModule<MeshComponentManager>();
		if (meshMgr == null) return;

		var sphereRef = ResourceRef(mSphereRes.Id, .());
		defer sphereRef.Dispose();

		// Calculate grid dimensions
		int32 newTotal = (mBatchCount + 1) * SpheresPerBatch;
		mGridSize = (int32)Math.Ceiling(Math.Sqrt((float)newTotal));

		int32 startIndex = mBatchCount * SpheresPerBatch;

		Console.WriteLine("Adding batch {} ({} spheres, total {}, grid {}x{})...",
			mBatchCount + 1, SpheresPerBatch, newTotal, mGridSize, mGridSize);

		// Each phase wraps the entire batch loop so the profiler captures
		// one aggregate sample per phase instead of 8000 individual ones.
		// Original per-iteration scoping flooded the profile with 40k+
		// samples, all small and noisy. Phase-batched: 6 samples, each
		// summing the work for all spheres.
		let entities = scope EntityHandle[SpheresPerBatch];
		let handles = scope ComponentHandle<MeshComponent>[SpheresPerBatch];

		using (Profiler.Begin("Spawn.CreateEntity"))
		{
			for (int32 i = 0; i < SpheresPerBatch; i++)
				entities[i] = mScene.CreateEntity();
		}

		using (Profiler.Begin("Spawn.SetLocalTransform"))
		{
			for (int32 i = 0; i < SpheresPerBatch; i++)
			{
				int32 index = startIndex + i;
				int32 gridX = index % mGridSize;
				int32 gridZ = index / mGridSize;
				float x = ((float)gridX - (float)mGridSize * 0.5f) * SphereSpacing;
				float z = ((float)gridZ - (float)mGridSize * 0.5f) * SphereSpacing;
				mScene.SetLocalTransform(entities[i], .() { Position = .(x, 0.5f, z), Rotation = .Identity, Scale = .One });
			}
		}

		using (Profiler.Begin("Spawn.CreateComponent"))
		{
			for (int32 i = 0; i < SpheresPerBatch; i++)
				handles[i] = meshMgr.CreateComponent(entities[i]);
		}

		using (Profiler.Begin("Spawn.SetMeshRef"))
		{
			for (int32 i = 0; i < SpheresPerBatch; i++)
			{
				if (let comp = meshMgr.Get(handles[i]))
					comp.SetMeshRef(sphereRef);
			}
		}

		if (mUseUniqueMaterials)
		{
			using (Profiler.Begin("Spawn.UniqueMaterial"))
			{
				for (int32 i = 0; i < SpheresPerBatch; i++)
				{
					int32 index = startIndex + i;
					if (let comp = meshMgr.Get(handles[i]))
					{
						let uniqueMat = new MaterialInstance(mPbrMaterial);
						let hue = (float)(index % 360) / 360.0f;
						let color = HSVtoRGB(hue, 0.8f, 0.9f);
						uniqueMat.SetColor("BaseColor", .(color.X, color.Y, color.Z, 1.0f));
						comp.SetMaterial(0, uniqueMat);
						mUniqueMaterials.Add(uniqueMat);
					}
				}
			}
		}
		else
		{
			using (Profiler.Begin("Spawn.SetMaterial"))
			{
				for (int32 i = 0; i < SpheresPerBatch; i++)
				{
					if (let comp = meshMgr.Get(handles[i]))
						comp.SetMaterial(0, mSharedMaterial);
				}
			}
		}

		using (Profiler.Begin("Spawn.TrackEntities"))
		{
			for (int32 i = 0; i < SpheresPerBatch; i++)
				mSphereEntities.Add(entities[i]);
		}

		mBatchCount++;
		Console.WriteLine("  Done. Total spheres: {}", mSphereEntities.Count);

		// Capture the spawn frame's profile breakdown without having to
		// time the P hotkey. Prints right after SProfiler.EndFrame() of
		// the current frame so AddSphereBatch and its sub-scopes are
		// fully accounted for.
		RequestProfilePrint();
		}

	}

	private void RemoveLastBatch()
	{
		if (mBatchCount <= 0) return;

		int32 removeCount = Math.Min(SpheresPerBatch, (int32)mSphereEntities.Count);
		for (int32 i = 0; i < removeCount; i++)
		{
			if (mSphereEntities.Count > 0)
			{
				let entity = mSphereEntities.PopBack();
				mScene.DestroyEntity(entity);
			}
		}

		// Remove unique materials for this batch
		if (mUseUniqueMaterials)
		{
			for (int32 i = 0; i < removeCount && mUniqueMaterials.Count > 0; i++)
			{
				let mat = mUniqueMaterials.PopBack();
				mat?.ReleaseRef();
			}
		}

		mBatchCount--;
		Console.WriteLine("Removed batch. Remaining: {} spheres ({} batches)",
			mSphereEntities.Count, mBatchCount);
	}

	float m_Time = 0.0f;

	public override void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime)
	{
		UpdateCamera(host, deltaTime);

		let keyboard = host.Shell.InputManager.Keyboard;

		// Space: add batch
		if (keyboard.IsKeyPressed(.Space))
			AddSphereBatch();

		// Backspace: remove batch
		if (keyboard.IsKeyPressed(.Backspace))
			RemoveLastBatch();

		m_Time += deltaTime;

		const float planeY = 0.0f;

		if (mSinWaveBob)
		{
			float amplitude = 1.0f;
			float speed = 2.0f;
			for (var entity in ref mSphereEntities)
			{
				var transform = mScene.GetLocalTransform(entity);

				// Phase from world position, not list index + grid size.
				// AddSphereBatch grows mGridSize every batch, but already-
				// placed spheres keep their original world positions. Using
				// the list index + current mGridSize would shift their
				// phases non-uniformly every time a new batch spawns
				// (sphere at row-1-start of the old grid suddenly thinks
				// it's at row 0 of the new wider grid). World-position-based
				// phase stays continuous regardless of batch count.
				let worldX = transform.Position.X;
				let worldZ = transform.Position.Z;
				float phaseOffset = (worldX + worldZ) * 0.2f;

				// Shift wave up by amplitude so min = planeY
				float y = Math.Sin(m_Time * speed + phaseOffset) * amplitude + amplitude;

				transform.Position.Y = planeY + y;

				mScene.SetLocalTransform(entity, transform);
			}
		}

		// U: toggle unique materials
		if (keyboard.IsKeyPressed(.U))
		{
			mUseUniqueMaterials = !mUseUniqueMaterials;
			Console.WriteLine("Unique materials: {}", mUseUniqueMaterials ? "ON (more draw calls)" : "OFF (shared material)");
		}

		if(keyboard.IsKeyPressed(.B))
		{
			mSinWaveBob = !mSinWaveBob;
		}

		// HUD
		let rs = host.Ctx.GetSubsystem<RenderSubsystem>();
		if (rs == null) return;
		let dbg = rs.DebugDraw;
		if (dbg == null) return;

		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
		let fps = mFrameTimeMs > 0.001f ? 1000.0f / mFrameTimeMs : 0.0f;
		mFpsSmoothed = mFpsSmoothed * 0.9f + fps * 0.1f;

		dbg.DrawScreenRect(4, 4, 400, 58, .(0, 0, 0, 180));

		let fpsText = scope String();
		fpsText.AppendF("FPS {0:F0}  ({1:F2} ms)  Spheres: {2}  Batches: {3}",
			mFpsSmoothed, mFrameTimeMs, mSphereEntities.Count, mBatchCount);
		dbg.DrawScreenText(8, 8, fpsText, .White);

		let controlText = scope String();
		controlText.AppendF("Space=+8K  Backspace=-8K B=Sin Wave Bob  U=UniqueMats({0})  Esc=Exit",
			mUseUniqueMaterials ? "ON" : "OFF");
		dbg.DrawScreenText(8, 20, controlText, .LightGray);

		let drawCallText = scope String();
		drawCallText.AppendF("Materials: {0}  Grid: {1}x{1}",
			mUseUniqueMaterials ? mUniqueMaterials.Count : 1, mGridSize);
		dbg.DrawScreenText(8, 32, drawCallText, .LightGray);
	}

	private void UpdateCamera(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime)
	{
		let keyboard = host.Shell.InputManager.Keyboard;
		let mouse = host.Shell.InputManager.Mouse;

		if (keyboard.IsKeyPressed(.Escape))
		{
			host.RequestExit();
			return;
		}

		if (keyboard.IsKeyPressed(.Tab))
		{
			mMouseCaptured = !mMouseCaptured;
			mouse.RelativeMode = mMouseCaptured;
			mouse.Visible = !mMouseCaptured;
		}

		if (mMouseCaptured || mouse.IsButtonDown(.Right))
		{
			mYaw += mouse.DeltaX * 0.003f;
			mPitch -= mouse.DeltaY * 0.003f;
			mPitch = Math.Clamp(mPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);
		}

		let cosP = Math.Cos(mPitch);
		let forward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
		let right = Vector3.Normalize(Vector3.Cross(forward, .(0, 1, 0)));
		let speed = (keyboard.IsKeyDown(.LeftShift) ? 200.0f : 50.0f) * deltaTime;

		Vector3 move = .Zero;
		if (keyboard.IsKeyDown(.W)) move += forward;
		if (keyboard.IsKeyDown(.S)) move -= forward;
		if (keyboard.IsKeyDown(.D)) move += right;
		if (keyboard.IsKeyDown(.A)) move -= right;
		if (keyboard.IsKeyDown(.E)) move += .(0, 1, 0);
		if (keyboard.IsKeyDown(.Q)) move -= .(0, 1, 0);
		if (move.LengthSquared() > 0)
			mCameraPosition += Vector3.Normalize(move) * speed;

		if (mScene != null)
		{
			let target = mCameraPosition + forward;
			mScene.SetLocalTransform(mCameraEntity, Transform.CreateLookAt(mCameraPosition, target));
		}
	}

	/// Converts HSV (0-1 range) to RGB.
	private static Vector3 HSVtoRGB(float h, float s, float v)
	{
		let i = (int32)(h * 6.0f);
		let f = h * 6.0f - (float)i;
		let p = v * (1.0f - s);
		let q = v * (1.0f - f * s);
		let t = v * (1.0f - (1.0f - f) * s);

		switch (i % 6)
		{
		case 0: return .(v, t, p);
		case 1: return .(q, v, p);
		case 2: return .(p, v, t);
		case 3: return .(p, q, v);
		case 4: return .(t, p, v);
		default: return .(v, p, q);
		}
	}

	public override void OnShutdown(Sedulous.Runtime.Client.IApplicationHost host)
	{
		let renderSub = host.Ctx.GetSubsystem<RenderSubsystem>();
		let device = renderSub.RenderContext.Device;

		if (let skyPass = renderSub.GetPipeline(mScene).GetPass<SkyPass>())
			skyPass.SkyTexture = null;

		if (mSkyTextureView != null)
			device.DestroyTextureView(ref mSkyTextureView);
		if (mSkyTexture != null)
			device.DestroyTexture(ref mSkyTexture);

		mSphereRes?.ReleaseRef();

		Console.WriteLine("=== Stress Test Shutdown ===");

		base.OnShutdown(host);
	}
}
