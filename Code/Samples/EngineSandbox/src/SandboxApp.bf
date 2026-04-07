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
using Sedulous.Core.Mathematics;
using Sedulous.Materials;
using Sedulous.Imaging;
using Sedulous.Imaging.STB;
using Sedulous.Renderer.Passes;

class SandboxApp : EngineApplication
{
	Material mPbrMaterial ~ delete _;
	ITexture mSkyTexture;
	ITextureView mSkyTextureView;
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
		STBImageLoader.Initialize();

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let renderer = renderSub.Renderer;
		let gpuResources = renderer.GPUResources;
		let matSystem = renderer.MaterialSystem;

		// Create scene
		let scene = sceneSub.CreateScene("TestScene");

		// ==================== Materials ====================

		mPbrMaterial = Materials.CreatePBR("PBR", "forward",
			matSystem.WhiteTexture, matSystem.DefaultSampler);

		// Red cube material
		mRedMaterial = new MaterialInstance(mPbrMaterial);
		mRedMaterial.SetColor("BaseColor", .(1, 0, 0, 1));
		matSystem.PrepareInstance(mRedMaterial);

		// Blue sphere material
		mBlueMaterial = new MaterialInstance(mPbrMaterial);
		mBlueMaterial.SetColor("BaseColor", .(0, 0, 1, 1));
		matSystem.PrepareInstance(mBlueMaterial);

		// Green material
		mGreenMaterial = new MaterialInstance(mPbrMaterial);
		mGreenMaterial.SetColor("BaseColor", .(0.2f, 0.8f, 0.2f, 1));
		matSystem.PrepareInstance(mGreenMaterial);

		// White material (shiny)
		mWhiteMaterial = new MaterialInstance(mPbrMaterial);
		mWhiteMaterial.SetColor("BaseColor", .(0.9f, 0.9f, 0.9f, 1));
		mWhiteMaterial.SetFloat("Roughness", 0.1f);
		mWhiteMaterial.SetFloat("Metallic", 0.8f);
		matSystem.PrepareInstance(mWhiteMaterial);

		// Yellow material
		mYellowMaterial = new MaterialInstance(mPbrMaterial);
		mYellowMaterial.SetColor("BaseColor", .(1.0f, 0.85f, 0.1f, 1));
		matSystem.PrepareInstance(mYellowMaterial);

		// Gray plane material
		mGrayMaterial = new MaterialInstance(mPbrMaterial);
		mGrayMaterial.SetColor("BaseColor", .(0.5f, 0.5f, 0.5f, 1));
		matSystem.PrepareInstance(mGrayMaterial);

		// Transparent material (semi-transparent blue)
		mTransparentMaterial = new MaterialInstance(mPbrMaterial);
		mTransparentMaterial.SetColor("BaseColor", .(0.2f, 0.4f, 0.9f, 0.4f));
		mTransparentMaterial.BlendMode = .AlphaBlend;
		matSystem.PrepareInstance(mTransparentMaterial);

		// Masked material (alpha cutoff test)
		mMaskedMaterial = new MaterialInstance(mPbrMaterial);
		mMaskedMaterial.SetColor("BaseColor", .(0.8f, 0.2f, 0.1f, 1));
		mMaskedMaterial.SetFloat("AlphaCutoff", 0.5f);
		mMaskedMaterial.BlendMode = .Masked;
		matSystem.PrepareInstance(mMaskedMaterial);

		// ==================== Geometry ====================

		// Ground plane
		let planeMesh = MeshBuilder.CreatePlane(10, 10, 1, 1);
		defer delete planeMesh;
		let planeHandle = UploadStaticMesh(gpuResources, planeMesh);

		let planeEntity = scene.CreateEntity("Ground");
		scene.SetLocalTransform(planeEntity, .()
		{
			Position = .(0, -1, 0),
			Rotation = .Identity,
			Scale = .One
		});
		SetupMeshComponent(scene, planeEntity, planeHandle, planeMesh.GetBounds(), mGrayMaterial);

		// Cube
		let cubeMesh = MeshBuilder.CreateCube(1.0f);
		defer delete cubeMesh;
		let cubeHandle = UploadStaticMesh(gpuResources, cubeMesh);

		let cubeEntity = scene.CreateEntity("Cube");
		scene.SetLocalTransform(cubeEntity, .()
		{
			Position = .(-1.5f, -0.5f, 0),
			Rotation = .Identity,
			Scale = .One
		});
		SetupMeshComponent(scene, cubeEntity, cubeHandle, cubeMesh.GetBounds(), mRedMaterial);

		// Sphere
		let sphereMesh = MeshBuilder.CreateSphere(0.5f, 32, 16);
		defer delete sphereMesh;
		let sphereHandle = UploadStaticMesh(gpuResources, sphereMesh);

		let sphereEntity = scene.CreateEntity("Sphere");
		scene.SetLocalTransform(sphereEntity, .()
		{
			Position = .(1.5f, -0.5f, 0),
			Rotation = .Identity,
			Scale = .One
		});
		SetupMeshComponent(scene, sphereEntity, sphereHandle, sphereMesh.GetBounds(), mBlueMaterial);

		// Green cube (back left)
		let cube2Entity = scene.CreateEntity("GreenCube");
		scene.SetLocalTransform(cube2Entity, .()
		{
			Position = .(-3.0f, -0.5f, -2.0f),
			Rotation = .Identity,
			Scale = .One
		});
		SetupMeshComponent(scene, cube2Entity, cubeHandle, cubeMesh.GetBounds(), mGreenMaterial);

		// Yellow cube (back right)
		let cube3Entity = scene.CreateEntity("YellowCube");
		scene.SetLocalTransform(cube3Entity, .()
		{
			Position = .(3.0f, -0.5f, -2.0f),
			Rotation = .Identity,
			Scale = .One
		});
		SetupMeshComponent(scene, cube3Entity, cubeHandle, cubeMesh.GetBounds(), mYellowMaterial);

		// White metallic sphere (center back)
		let sphere2Entity = scene.CreateEntity("MetalSphere");
		scene.SetLocalTransform(sphere2Entity, .()
		{
			Position = .(0, -0.25f, -2.0f),
			Rotation = .Identity,
			Scale = .(1.5f, 1.5f, 1.5f)
		});
		SetupMeshComponent(scene, sphere2Entity, sphereHandle, sphereMesh.GetBounds(), mWhiteMaterial);

		// Small green sphere (front left)
		let sphere3Entity = scene.CreateEntity("GreenSphere");
		scene.SetLocalTransform(sphere3Entity, .()
		{
			Position = .(-0.5f, -0.7f, 1.5f),
			Rotation = .Identity,
			Scale = .(0.6f, 0.6f, 0.6f)
		});
		SetupMeshComponent(scene, sphere3Entity, sphereHandle, sphereMesh.GetBounds(), mGreenMaterial);

		// Small yellow sphere (front right)
		let sphere4Entity = scene.CreateEntity("YellowSphere");
		scene.SetLocalTransform(sphere4Entity, .()
		{
			Position = .(0.5f, -0.7f, 1.5f),
			Rotation = .Identity,
			Scale = .(0.6f, 0.6f, 0.6f)
		});
		SetupMeshComponent(scene, sphere4Entity, sphereHandle, sphereMesh.GetBounds(), mYellowMaterial);

		// Transparent sphere (overlapping the red cube to test alpha blending)
		let transparentEntity = scene.CreateEntity("TransparentSphere");
		scene.SetLocalTransform(transparentEntity, .()
		{
			Position = .(-1.0f, -0.25f, 0.8f),
			Rotation = .Identity,
			Scale = .(1.2f, 1.2f, 1.2f)
		});
		SetupMeshComponent(scene, transparentEntity, sphereHandle, sphereMesh.GetBounds(), mTransparentMaterial);

		// Masked cube (tests alpha cutoff — should render fully since no albedo texture with alpha)
		let maskedEntity = scene.CreateEntity("MaskedCube");
		scene.SetLocalTransform(maskedEntity, .()
		{
			Position = .(3.0f, -0.5f, 1.0f),
			Rotation = .Identity,
			Scale = .One
		});
		SetupMeshComponent(scene, maskedEntity, cubeHandle, cubeMesh.GetBounds(), mMaskedMaterial);

		// ==================== Light ====================

		let lightEntity = scene.CreateEntity("DirectionalLight");
		scene.SetLocalTransform(lightEntity, Transform.CreateLookAt(.(-3, 5, 2), .Zero));

		let lightMgr = scene.GetModule<LightComponentManager>();
		let lightHandle = lightMgr.CreateComponent(lightEntity);
		if (let light = lightMgr.Get(lightHandle))
		{
			light.Type = .Directional;
			light.Color = .(1.0f, 0.95f, 0.9f);
			light.Intensity = 2.0f;
		}

		// ==================== Camera ====================

		let cameraEntity = scene.CreateEntity("Camera");
		scene.SetLocalTransform(cameraEntity, Transform.CreateLookAt(.(0, 3, 5), .(0, 0, 0)));

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

	/// Uploads a StaticMesh to the GPU resource manager.
	private GPUMeshHandle UploadStaticMesh(GPUResourceManager gpuResources, StaticMesh mesh)
	{
		let vertexDataSize = (uint64)(mesh.VertexCount * mesh.VertexSize);
		let indices = mesh.Indices;
		let hasIndices = indices != null && indices.IndexCount > 0;

		let indexSize = hasIndices ? (indices.Format == .UInt16 ? 2 : 4) : 0;
		let indexDataSize = hasIndices ? (uint64)(indices.IndexCount * indexSize) : 0;

		// Build submesh array
		GPUSubMesh[] subMeshes = null;
		if (mesh.SubMeshes != null && mesh.SubMeshes.Count > 0)
		{
			subMeshes = scope :: GPUSubMesh[mesh.SubMeshes.Count];
			for (int i = 0; i < mesh.SubMeshes.Count; i++)
			{
				let sub = mesh.SubMeshes[i];
				subMeshes[i] = .()
				{
					IndexStart = (uint32)sub.startIndex,
					IndexCount = (uint32)sub.indexCount,
					BaseVertex = 0,
					MaterialSlot = (uint32)sub.materialIndex
				};
			}
		}

		MeshUploadDesc desc = .()
		{
			VertexData = mesh.GetVertexData(),
			VertexDataSize = vertexDataSize,
			VertexCount = (uint32)mesh.VertexCount,
			VertexStride = (uint32)mesh.VertexSize,
			IndexData = hasIndices ? mesh.GetIndexData() : null,
			IndexDataSize = indexDataSize,
			IndexCount = hasIndices ? (uint32)indices.IndexCount : 0,
			IndexFormat = hasIndices && indices.Format == .UInt16 ? .UInt16 : .UInt32,
			SubMeshes = (subMeshes != null) ? &subMeshes[0] : null,
			SubMeshCount = (subMeshes != null) ? (uint32)subMeshes.Count : 0,
			Bounds = mesh.GetBounds()
		};

		if (gpuResources.UploadMesh(desc) case .Ok(let handle))
			return handle;

		Console.WriteLine("ERROR: Failed to upload mesh");
		return .Invalid;
	}

	/// Creates a MeshComponent on an entity with the given GPU mesh handle and optional material.
	private void SetupMeshComponent(Scene scene, EntityHandle entity, GPUMeshHandle meshHandle, BoundingBox bounds, MaterialInstance material = null)
	{
		let meshMgr = scene.GetModule<MeshComponentManager>();
		let compHandle = meshMgr.CreateComponent(entity);
		if (let comp = meshMgr.Get(compHandle))
		{
			comp.MeshHandle = meshHandle;
			comp.LocalBounds = bounds;
			if (material != null)
				comp.SetMaterial(0, material);
		}
	}

	protected override void OnCleanup()
	{
	}

	protected override void OnShutdown()
	{
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let device = renderSub.Renderer.Device;

		// Clear sky texture reference before destroying
		if (let skyPass = renderSub.Pipeline.GetPass<SkyPass>())
			skyPass.SkyTexture = null;

		if (mSkyTextureView != null)
			device.DestroyTextureView(ref mSkyTextureView);
		if (mSkyTexture != null)
			device.DestroyTexture(ref mSkyTexture);

		let matSystem = renderSub.Renderer.MaterialSystem;

		if (mRedMaterial != null)
			matSystem.ReleaseInstance(mRedMaterial);
		if (mBlueMaterial != null)
			matSystem.ReleaseInstance(mBlueMaterial);
		if (mGreenMaterial != null)
			matSystem.ReleaseInstance(mGreenMaterial);
		if (mWhiteMaterial != null)
			matSystem.ReleaseInstance(mWhiteMaterial);
		if (mYellowMaterial != null)
			matSystem.ReleaseInstance(mYellowMaterial);
		if (mTransparentMaterial != null)
			matSystem.ReleaseInstance(mTransparentMaterial);
		if (mMaskedMaterial != null)
			matSystem.ReleaseInstance(mMaskedMaterial);
		if (mGrayMaterial != null)
			matSystem.ReleaseInstance(mGrayMaterial);

		Console.WriteLine("=== EngineSandbox OnShutdown ===");
	}
}
