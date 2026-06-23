namespace EngineAnimationSandbox;

using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Core.Mathematics;
using Sedulous.Engine;
using Sedulous.Engine.Animation;
using Sedulous.Engine.App;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.Geometry.Resources;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Images.STB;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Models;
using Sedulous.Models.GLTF;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Runtime;
using Sedulous.Shell.Input;
using Sedulous.Textures.Resources;
using Sedulous.UI;

/// Stress-tests skeletal animation by spawning batches of the PlatformerGameKit
/// character into a grid. +/- buttons in the HUD add or remove BatchSize copies.
/// All copies share the same mesh/skeleton/clip/material resources — only the
/// per-entity AnimationPlayer state and transform are unique. Each instance gets
/// a randomized starting time so the herd doesn't move in lockstep.
class AnimationSandboxApp : EngineApplication
{
	// Tweak this single constant to change how many instances each click of
	// +/- adds or removes (and the initial spawn count).
	const int32 BatchSize = 128;

	// Initial spacing between characters in the grid (world units).
	const float CharacterSpacing = 3f;

	// Smoothed frame-time stats for the FPS readout.
	float mFpsSmoothed = 0.0f;
	float mFrameTimeMs = 0.0f;

	// Screen UI elements.
	Label mFpsLabel;
	Label mCountLabel;

	// Camera fly-through state (same controls as EngineSandbox).
	Scene mScene;
	EntityHandle mCameraEntity;
	Vector3 mCameraPosition = .(0, 6, 16);
	float mYaw = Math.PI_f;
	float mPitch = -0.35f;
	bool mMouseCaptured;

	// Shared materials.
	Material mPbrMaterial ~ delete _;
	MaterialInstance mGrayMaterial ~ _?.ReleaseRef();
	ResourceRef mSkyRef = .(.Empty, "builtin://skies/realistic_sky.texture") ~ _.Dispose();

	// Ground plane mesh.
	StaticMeshResource mPlaneRes;

	// Character resources (loaded once, shared by every instance).
	SkinnedMeshResource mCharMeshRes;
	SkeletonResource mCharSkeletonRes;
	// All animation clips from the imported model. Each character picks a
	// random one at spawn so the herd shows a mix of idle/walk/death/etc.
	List<AnimationClipResource> mCharClipResources = new .() ~ delete _;
	List<TextureResource> mCharTextures = new .() ~ delete _;
	List<MaterialResource> mCharMaterialResources = new .() ~ delete _;
	bool mCharLoadOk;

	// Spawned character entities. Tracked so we can pop the most recent batch on demand.
	List<EntityHandle> mCharEntities = new .() ~ delete _;
	Random mRandom = new .(12345) ~ delete _;

	protected override void OnStartup()
	{
		Console.WriteLine("=== EngineAnimationSandbox OnStartup ===");

		STBImageLoader.Initialize();
		GltfModels.Initialize();

		SetupScreenUI();

		let sceneSub = Context.GetSubsystem<SceneSubsystem>();
		let renderSub = Context.GetSubsystem<RenderSubsystem>();
		let renderer = renderSub.RenderContext;
		let matSystem = renderer.MaterialSystem;

		mScene = sceneSub.CreateScene("AnimationScene");

		// ---- Materials ----
		mPbrMaterial = Materials.CreatePBR("PBR", "forward",
			matSystem.WhiteTexture, matSystem.DefaultSampler);

		mGrayMaterial = new MaterialInstance(mPbrMaterial);
		mGrayMaterial.SetColor("BaseColor", .(0.45f, 0.46f, 0.48f, 1));

		// ---- Ground plane ----
		let resources = ResourceSystem;
		mPlaneRes = StaticMeshResource.CreatePlane(60, 60, 1, 1);
		resources.AddResource<StaticMeshResource>(mPlaneRes);

		var planeRef = ResourceRef(mPlaneRes.Id, .());
		defer planeRef.Dispose();

		let planeEntity = mScene.CreateEntity("Ground");
		mScene.SetLocalTransform(planeEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });
		let meshMgr = mScene.GetModule<MeshComponentManager>();
		let planeHandle = meshMgr.CreateComponent(planeEntity);
		if (let comp = meshMgr.Get(planeHandle))
		{
			comp.SetMeshRef(planeRef);
			comp.SetMaterial(0, mGrayMaterial);
		}

		// ---- Load the character (gltf) ----
		mCharLoadOk = LoadCharacter();

		// ---- Spawn the initial batch ----
		if (mCharLoadOk)
			AddBatch();
		else
			Console.WriteLine("WARNING: Character did not load; nothing to spawn.");

		// ---- Lights ----
		let lightMgr = mScene.GetModule<LightComponentManager>();
		let dirLight = mScene.CreateEntity("DirectionalLight");
		mScene.SetLocalTransform(dirLight, Transform.CreateLookAt(.(-4, 8, 4), .Zero));
		let lightHandle = lightMgr.CreateComponent(dirLight);
		if (let light = lightMgr.Get(lightHandle))
		{
			light.Type = .Directional;
			light.Color = .(1.0f, 0.97f, 0.92f);
			light.Intensity = 2.0f;
			light.CastsShadows = true;
			light.ShadowBias = 0.0005f;
			light.ShadowNormalBias = 3.0f;
		}

		// ---- Camera ----
		let cameraEntity = mScene.CreateEntity("Camera");
		mCameraEntity = cameraEntity;
		mScene.SetLocalTransform(cameraEntity, Transform.CreateLookAt(mCameraPosition, .(0, 1, 0)));

		let cameraMgr = mScene.GetModule<CameraComponentManager>();
		let cameraComp = cameraMgr.CreateComponent(cameraEntity);
		if (let camera = cameraMgr.Get(cameraComp))
		{
			camera.FieldOfView = 60.0f;
			camera.NearPlane = 0.1f;
			camera.FarPlane = 200.0f;
		}

		// ---- Sky & render settings ----
		if (let renderSettings = mScene.GetModule<RenderSceneModule>())
		{
			renderSettings.SetSkyTextureRef(mSkyRef);
			renderSettings.SkyIntensity = 1.0f;
			renderSettings.AmbientColor = .(0.18f, 0.18f, 0.22f);
			renderSettings.Exposure = 1.0f;
		}

		UpdateCountLabel();
		Console.WriteLine("Initial spawn complete. {0} characters.", mCharEntities.Count);
	}

	bool LoadCharacter()
	{
		let charPath = scope String();
		GetAssetPath("samples/PlatformerGameKit/Character/glTF/Character.gltf", charPath);

		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(charPath, model) != .Ok)
		{
			Console.WriteLine("WARNING: Could not load Character.gltf at {0}", charPath);
			return false;
		}

		let importOpts = ModelImportOptions.SkinnedWithAnimations();
		let importer = scope ModelImporter(importOpts);
		let importResult = importer.Import(model);
		defer delete importResult;

		if (importResult.SkinnedMeshes.Count == 0 || importResult.Skeletons.Count == 0)
		{
			Console.WriteLine("WARNING: Character has no skinned mesh / skeleton (mesh={0} skel={1})",
				importResult.SkinnedMeshes.Count, importResult.Skeletons.Count);
			return false;
		}

		let resources = ResourceSystem;

		// Skeleton.
		let skeleton = importResult.Skeletons[0];
		importResult.Skeletons[0] = null;
		mCharSkeletonRes = new SkeletonResource(skeleton, true);
		resources.AddResource<SkeletonResource>(mCharSkeletonRes);

		// Register every animation clip; each spawned character picks one
		// at random for visual variety. Character.gltf ships with several
		// (Idle, Death, Duck, HitReact, Idle_Gun, ...).
		for (int32 i = 0; i < importResult.Animations.Count; i++)
		{
			let clip = importResult.Animations[i];
			if (clip == null) continue;
			importResult.Animations[i] = null;
			let clipRes = new AnimationClipResource(clip, true);
			resources.AddResource<AnimationClipResource>(clipRes);
			mCharClipResources.Add(clipRes);
		}
		if (mCharClipResources.Count == 0)
		{
			Console.WriteLine("WARNING: Character.gltf has no animation clips. Characters will pose statically.");
		}

		// Skinned mesh.
		let skinnedMesh = importResult.SkinnedMeshes[0];
		mCharMeshRes = new SkinnedMeshResource(skinnedMesh, true);
		importResult.SkinnedMeshes[0] = null;
		resources.AddResource<SkinnedMeshResource>(mCharMeshRes);

		// Textures.
		for (let tex in importResult.Textures)
		{
			let texRes = TextureResourceConverter.Convert(tex);
			if (texRes != null)
			{
				resources.AddResource<TextureResource>(texRes);
				mCharTextures.Add(texRes);
			}
		}

		// Materials.
		for (let mat in importResult.Materials)
		{
			let matRes = MaterialResourceConverter.Convert(mat, mCharTextures);
			if (matRes != null)
			{
				resources.AddResource<MaterialResource>(matRes);
				mCharMaterialResources.Add(matRes);
			}
		}

		Console.WriteLine("Character loaded: {0} verts, {1} bones, {2} clips, {3} mats, {4} textures",
			skinnedMesh.VertexCount, skeleton.BoneCount,
			importResult.Animations.Count, importResult.Materials.Count, importResult.Textures.Count);

		return true;
	}

	// Adds a batch of BatchSize characters laid out in a square grid centered on origin.
	void AddBatch()
	{
		if (!mCharLoadOk) return;

		// Compute starting index within the global grid so newly added batches
		// extend the existing layout instead of overlapping.
		let startIndex = (int32)mCharEntities.Count;
		let endIndex   = startIndex + BatchSize;

		let skelAnimMgr = mScene.GetModule<SkeletalAnimationComponentManager>();
		let skinnedMgr  = mScene.GetModule<SkinnedMeshComponentManager>();

		for (int32 i = startIndex; i < endIndex; i++)
			SpawnCharacterAt(i, skelAnimMgr, skinnedMgr);

		UpdateCountLabel();
	}

	// Removes the most recently added batch (up to BatchSize entities).
	void RemoveBatch()
	{
		let toRemove = Math.Min(BatchSize, (int32)mCharEntities.Count);
		for (int32 i = 0; i < toRemove; i++)
		{
			let entity = mCharEntities.PopBack();
			mScene.DestroyEntity(entity);
		}
		UpdateCountLabel();
	}

	// Lays out characters in a square grid where side = ceil(sqrt(N)). `index`
	// is the entity's position in that grid.
	void SpawnCharacterAt(int32 index, SkeletalAnimationComponentManager skelAnimMgr,
		SkinnedMeshComponentManager skinnedMgr)
	{
		// Use the *target* count for grid sizing so the grid doesn't keep
		// re-centering as we add batches. Round up to a perfect square.
		let target = Math.Max(BatchSize, (int32)mCharEntities.Count + 1);
		let side = (int32)Math.Ceiling(Math.Sqrt((double)target));
		let half = (side - 1) * 0.5f;

		let col = index % side;
		let row = index / side;
		let x = ((float)col - half) * CharacterSpacing;
		let z = ((float)row - half) * CharacterSpacing;

		let entity = mScene.CreateEntity("Char");
		mScene.SetLocalTransform(entity, .() {
			Position = .(x, 0, z),
			Rotation = .Identity,
			Scale = .One
		});

		// Skeletal animation component.
		let animHandle = skelAnimMgr.CreateComponent(entity);
		if (let animComp = skelAnimMgr.Get(animHandle))
		{
			var skelRef = ResourceRef(mCharSkeletonRes.Id, .());
			defer skelRef.Dispose();
			animComp.SetSkeletonRef(skelRef);

			if (mCharClipResources.Count > 0)
			{
				let clipIdx = mRandom.Next(0, (int32)mCharClipResources.Count);
				var clipRef = ResourceRef(mCharClipResources[clipIdx].Id, .());
				defer clipRef.Dispose();
				animComp.SetClipRef(clipRef);
			}
			animComp.Loop = true;
			animComp.AutoPlay = true;
			// Tiny per-instance speed jitter so the herd never re-syncs.
			animComp.Speed = 0.85f + (float)mRandom.NextDouble() * 0.3f;
		}

		// Skinned mesh component (shares the resources with every other character).
		let meshHandle = skinnedMgr.CreateComponent(entity);
		if (let meshComp = skinnedMgr.Get(meshHandle))
		{
			var meshRef = ResourceRef(mCharMeshRes.Id, .());
			defer meshRef.Dispose();
			meshComp.SetMeshRef(meshRef);

			for (int32 slot = 0; slot < mCharMaterialResources.Count; slot++)
			{
				var matRef = ResourceRef(mCharMaterialResources[slot].Id, .());
				meshComp.SetMaterialRef(slot, matRef);
				matRef.Dispose();
			}
		}

		mCharEntities.Add(entity);
	}

	// After the manager initializes per-entity AnimationPlayers, set a random
	// CurrentTime on each so the herd is desynchronized. Re-runs every frame on
	// newly added entities — it's cheap and avoids racing the manager's resolve.
	void DesyncNewPlayers()
	{
		if (mScene == null) return;
		let skelAnimMgr = mScene.GetModule<SkeletalAnimationComponentManager>();
		if (skelAnimMgr == null) return;

		for (let entity in mCharEntities)
		{
			let comp = skelAnimMgr.GetForEntity(entity);
			if (comp?.Player == null) continue;

			// Mark with a sentinel so we only randomize once per entity. We
			// stash the offset in CurrentTime if it's still exactly 0 (the
			// default AnimationPlayer initializer leaves it at 0).
			if (comp.Player.CurrentTime == 0.0f && comp.CurrentClip != null)
			{
				let duration = comp.CurrentClip.Duration;
				if (duration > 0.0f)
					comp.Player.CurrentTime = (float)mRandom.NextDouble() * duration;
			}
		}
	}

	protected override void OnUpdate(float deltaTime)
	{
		// Smooth FPS readout so it doesn't strobe.
		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
		let fps = mFrameTimeMs > 0.001f ? 1000.0f / mFrameTimeMs : 0.0f;
		mFpsSmoothed = mFpsSmoothed * 0.9f + fps * 0.1f;

		if (mFpsLabel != null)
		{
			let fpsText = scope String();
			fpsText.AppendF("FPS {0:F0}  ({1:F2} ms)", mFpsSmoothed, mFrameTimeMs);
			mFpsLabel.SetText(fpsText);
		}

		// Stagger newly-spawned characters once their players exist.
		DesyncNewPlayers();

		// Camera + exit.
		let uiSub = Context.GetSubsystem<EngineUISubsystem>();
		let uiHovered = uiSub?.IsMouseOverUI ?? false;
		UpdateCamera(deltaTime, uiHovered);
	}

	void UpdateCountLabel()
	{
		if (mCountLabel == null) return;
		let text = scope String();
		text.AppendF("Characters: {0}  (batch={1})", mCharEntities.Count, BatchSize);
		mCountLabel.SetText(text);
	}

	void SetupScreenUI()
	{
		let uiSub = Context.GetSubsystem<EngineUISubsystem>();
		if (uiSub?.ScreenView == null) return;

		let root = uiSub.ScreenView.Root;

		// Top-right HUD panel using FrameLayout gravity.
		let frame = new FrameLayout();
		frame.IsHitTestVisible = false;
		root.AddView(frame, new LayoutParams() { Width = .Match, Height = .Match });

		let panel = new Panel();
		panel.SetStyle(.Background, new ColorDrawable(.(0, 0, 0, 140)));
		panel.Padding = .(10, 8, 10, 8);
		frame.AddView(panel, new FrameLayout.LayoutParams() {
			Width  = .Fixed(.Px(240)),
			Height = .Fixed(.Px(120)),
			Gravity = .TopRight,
			Margin = .(0, 12, 12, 0)
		});

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;
		panel.AddView(column, new LayoutParams() { Width = .Match, Height = .Match });

		// FPS readout.
		mFpsLabel = new Label("FPS --");
		mFpsLabel.FontSize.Value = 14;
		column.AddView(mFpsLabel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(18))
		});

		// Character count readout.
		mCountLabel = new Label("Characters: 0  (batch=64)");
		mCountLabel.FontSize.Value = 12;
		column.AddView(mCountLabel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(16))
		});

		// +64 / -64 buttons on a horizontal row.
		let buttonRow = new FlexLayout();
		buttonRow.Direction = .Horizontal;
		buttonRow.Spacing = 6;
		column.AddView(buttonRow, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(28))
		});

		let addText = scope String();
		addText.AppendF("+{0}", BatchSize);
		let addBtn = new Button(addText);
		addBtn.OnClick.Add(new (b) => { AddBatch(); });
		buttonRow.AddView(addBtn, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Match, Grow = 1
		});

		let subText = scope String();
		subText.AppendF("-{0}", BatchSize);
		let subBtn = new Button(subText);
		subBtn.OnClick.Add(new (b) => { RemoveBatch(); });
		buttonRow.AddView(subBtn, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Match, Grow = 1
		});
	}

	void UpdateCamera(float deltaTime, bool uiHovered = false)
	{
		let keyboard = mShell.InputManager.Keyboard;
		let mouse    = mShell.InputManager.Mouse;

		if (keyboard.IsKeyPressed(.Escape))
		{
			Exit();
			return;
		}

		if (keyboard.IsKeyPressed(.Tab))
		{
			mMouseCaptured = !mMouseCaptured;
			mouse.RelativeMode = mMouseCaptured;
			mouse.Visible = !mMouseCaptured;
		}

		if (mMouseCaptured || (mouse.IsButtonDown(.Right) && !uiHovered))
		{
			mYaw   += mouse.DeltaX * 0.003f;
			mPitch -= mouse.DeltaY * 0.003f;
			mPitch  = Math.Clamp(mPitch, -Math.PI_f * 0.49f, Math.PI_f * 0.49f);
		}

		let cosP = Math.Cos(mPitch);
		let forward = Vector3(cosP * Math.Sin(mYaw), Math.Sin(mPitch), cosP * Math.Cos(mYaw));
		let right   = Vector3.Normalize(Vector3.Cross(forward, .(0, 1, 0)));
		let speed   = (keyboard.IsKeyDown(.LeftShift) ? 30.0f : 8.0f) * deltaTime;

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

	protected override void OnCleanup() { }

	protected override void OnShutdown()
	{
		Console.WriteLine("=== EngineAnimationSandbox OnShutdown ({0} chars) ===", mCharEntities.Count);

		mPlaneRes?.ReleaseRef();
		mCharMeshRes?.ReleaseRef();
		mCharSkeletonRes?.ReleaseRef();
		for (let clipRes in mCharClipResources)
			clipRes?.ReleaseRef();

		for (let texRes in mCharTextures)
			texRes?.ReleaseRef();
		for (let matRes in mCharMaterialResources)
			matRes?.ReleaseRef();
	}
}
