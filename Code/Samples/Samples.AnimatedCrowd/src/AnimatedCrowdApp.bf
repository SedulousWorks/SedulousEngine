using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Animation;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Render;
using Sedulous.Extensions.Imgui;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Materials;
using Sedulous.Model.Resource;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Samples.Common;
using cimgui_Beef;

namespace Samples.AnimatedCrowd;

/// A crowd drawn as INSTANCED SETS rather than entities: one instanced mesh per clip group, and
/// one shared pose pool animating all of it.
///
/// That is the whole difference from the per character stress test. The cost is the number of
/// clips times the number of poses, per frame, and does not grow with the crowd. Where
/// AnimStressTest measures what a thousand players cost, this measures what replacing them with
/// thirty two shared palettes buys.
class AnimatedCrowdApp : DefaultApplication
{
	private const int32 cBatchSize = 500;
	private const float cCharacterSpacing = 8.0f;
	private const float cCharacterSize = 6.0f;
	private const float cFloorY = -7.0f;
	private const float cFloorBaseSize = 120.0f;
	/// The phase buckets in one shared pose pool.
	private const uint32 cPoseCount = 32;
	/// The cap on how many distinct clips the crowd mixes across.
	private const int32 cMaxClipGroups = 6;
	private const String cOutputDir = "Output/AnimatedCrowd";
	private const String cModelFile = "Assets/models/QuaterniusCharacter/glTF/Character.gltf";

	/// One colour per clip group, so a glance says which clip a character is playing.
	private static readonly Float3[cMaxClipGroups] cClipColors = .(
		.(1.00f, 0.45f, 0.40f), .(0.45f, 0.90f, 0.50f), .(0.45f, 0.65f, 1.00f),
		.(1.00f, 0.85f, 0.35f), .(0.90f, 0.50f, 1.00f), .(0.45f, 0.95f, 0.95f));

	private static readonly String[5] cPolicyNames = .(
		"Random (hashed)", "Wave (diagonal)", "Columns", "Clusters", "Custom (rings)");

	private Scene mScene = null;
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mFloor = .Invalid;
	private EntityHandle mKeyLight = .Invalid;

	private CookedModel mModel = new .() ~ delete _;
	private StaticMesh mFloorMesh = null ~ delete _;
	private Material mFloorMaterial = null ~ delete _;

	private List<SkinnedPart> mSkinnedParts = new .() ~ delete _;
	private StaticMesh mMergedMesh = null ~ delete _;
	private List<EntityHandle> mCrowdParts = new .() ~ delete _;

	private ImguiSubsystem mOverlay = null ~ delete _;

	private int32 mCrowdCount = 0;
	private int32 mClipGroups = 1;
	private bool mTintEnabled = true;
	private bool mMergeMeshes = false;
	private bool mSingleClip = false;
	private PosePolicy mPosePolicy = .Random;

	private Sedulous.Core.Random mRandom = .(0x9E3779B97F4A7C15UL);
	private FlyCamera mFly = .();
	private float mFrameTimeMs = 16.6f;
	private bool mShowHud = true;

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

		mScene = PrimaryScenes.CreateScene("crowd");
		mFly.Position = .(0.0f, 10.0f, 26.0f);
		mFly.Pitch = -0.25f;

		if (let environment = mScene.GetSystem<EnvironmentSystem>())
		{
			environment.Environment.AmbientColor = .(0.12f, 0.16f, 0.28f, 1.0f);
			environment.Environment.AmbientIntensity = 0.35f;
		}

		mCamera = mScene.CreateEntity("camera");
		mScene.SetLocalPosition(mCamera, .(0.0f, 14.0f, 30.0f));
		{
			var transform = mScene.GetLocalTransform(mCamera);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.48f);
			mScene.SetLocalTransform(mCamera, transform);
		}
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera).ClearColor = .(0.02f, 0.02f, 0.03f, 1.0f);

		if (let meshes = mScene.GetSystem<MeshComponentManager>())
		{
			mFloor = mScene.CreateEntity("floor");
			mScene.SetLocalPosition(mFloor, .(0.0f, cFloorY, 0.0f));

			mFloorMesh = Primitives.Plane(cFloorBaseSize, cFloorBaseSize);
			mFloorMaterial = MaterialPresets.CreatePbr("lit", .(0.5f, 0.5f, 0.53f, 1.0f), 0.0f,
				0.65f);

			let mesh = meshes.Add(mFloor);
			mesh.Mesh.SetDirect(mFloorMesh);
			mesh.SetMaterial(mFloorMaterial);
		}

		if (let lights = mScene.GetSystem<LightComponentManager>())
		{
			mKeyLight = mScene.CreateEntity("keyLight");
			var transform = mScene.GetLocalTransform(mKeyLight);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.9f)
				* Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 0.5f);
			mScene.SetLocalTransform(mKeyLight, transform);

			let light = lights.Add(mKeyLight);
			light.Type = .Directional;
			light.Color = .(1.0f, 0.97f, 0.92f, 1.0f);
			light.Intensity = 2.5f;
			light.CastsShadows = true;
		}

		LoadModel(host);

		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
			render.Exposure = 0.5f;

		Console.WriteLine("AnimatedCrowd: Space adds a batch, Backspace removes one, K toggles");
		Console.WriteLine("shadows, H hides the panel, Esc exits.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (mOverlay != null)
		{
			mOverlay.NewFrame(input, deltaTime);
			BuildHud(host.Context.GetSubsystem<RenderSubsystem>());
		}

		if (input != null)
		{
			mFly.Update(input.Keyboard, input.Mouse, deltaTime);
			if ((input.Keyboard != null) && !HandleKeys(host, input.Keyboard))
				return;
		}

		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);

		mFrameTimeMs = mFrameTimeMs * 0.9f + (deltaTime * 1000.0f) * 0.1f;
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if ((mScene != null) && (frame.Height > 0))
		{
			if (let cameras = mScene.GetSystem<CameraComponentManager>())
			{
				if (let camera = cameras.Get(mCamera))
					camera.Aspect = (float)frame.Width / (float)frame.Height;
			}
		}

		RenderFrame(host, ref frame);

		if (mOverlay != null)
			mOverlay.Render(ref frame);

		// After the overlay, so a screenshot has it.
		FinishFrame(host, ref frame);
	}

	public override void OnShutdown(IApplicationHost host)
	{
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			host.Graphics.Raw.WaitIdle();

		base.OnShutdown(host);
		Console.WriteLine("AnimatedCrowd: shutting down.");
	}

	private bool HandleKeys(IApplicationHost host, IKeyboard keyboard)
	{
		if (keyboard.IsKeyPressed(.Escape))
		{
			host.RequestExit(0);
			return false;
		}

		if (keyboard.IsKeyPressed(.Space))
			RebuildToCount(mCrowdCount + cBatchSize);
		if (keyboard.IsKeyPressed(.Backspace))
			RebuildToCount((mCrowdCount > cBatchSize) ? mCrowdCount - cBatchSize : 0);
		if (keyboard.IsKeyPressed(.H))
			mShowHud = !mShowHud;
		if (keyboard.IsKeyPressed(.K))
			ToggleShadows();

		if (keyboard.IsKeyPressed(.I))
		{
			if (let render = host.Context.GetSubsystem<RenderSubsystem>())
			{
				render.InstanceSharing = !render.InstanceSharing;
				Console.WriteLine(render.InstanceSharing ? "Instance sharing: ON"
					: "Instance sharing: OFF (the forward pass refills)");
			}
		}

		return true;
	}

	private void ToggleShadows()
	{
		if ((mScene == null) || !mKeyLight.IsAssigned)
			return;

		if (let lights = mScene.GetSystem<LightComponentManager>())
		{
			if (let light = lights.Get(mKeyLight))
			{
				light.CastsShadows = !light.CastsShadows;
				Console.WriteLine(light.CastsShadows ? "Directional shadows: ON"
					: "Directional shadows: OFF");
			}
		}
	}

	private void LoadModel(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (!mModel.Open(DataPath(cOutputDir, .. scope String()), device))
			return;

		let path = scope String();
		DataPath(cModelFile, path);
		if (!FileExists(path))
		{
			Console.WriteLine(scope $"AnimatedCrowd: no model at {cModelFile}, showing an empty stage.");
			return;
		}

		if (!mModel.Cook("Char", path, cCharacterSize))
			return;

		CollectSkinnedParts();
		if (mSkinnedParts.IsEmpty)
		{
			Console.Error.WriteLine("AnimatedCrowd: no skinned mesh in the model");
			return;
		}

		RebuildToCount(cBatchSize);
	}

	/// Every SKINNED mesh of the character with its material. A static part is skipped: it has
	/// no pose to share, and drawing it would need a separate path.
	private void CollectSkinnedParts()
	{
		let resource = mModel.Resource;
		for (int i < resource.Meshes.Count)
		{
			let mesh = resource.Mesh(i);
			if ((mesh == null) || !mesh.IsSkinned)
				continue;

			let materialIndex = (i < resource.MeshMaterial.Count) ? resource.MeshMaterial[i] : -1;
			Material material = null;
			if ((materialIndex >= 0) && (materialIndex < mModel.Materials.Count))
				material = mModel.Materials[materialIndex];
			else if (!mModel.Materials.IsEmpty)
				material = mModel.Materials[0];

			mSkinnedParts.Add(.(mesh, material, materialIndex));
		}
	}

	// ---- the crowd ----

	/// Rebuilds the whole crowd: a set per clip group, each with its subset of the transforms,
	/// and one pose pool driving them.
	private void RebuildToCount(int32 count)
	{
		let sets = mScene.GetSystem<InstancedMeshComponentManager>();
		let animations = mScene.GetSystem<InstancedSkinningComponentManager>();
		if ((sets == null) || (animations == null) || mSkinnedParts.IsEmpty)
			return;

		for (let entity in mCrowdParts)
			mScene.DestroyEntity(entity);
		mCrowdParts.Clear();

		let side = (count == 0) ? (int32)1 : (int32)Ceil(Sqrt((float)count));
		let half = ((float)side - 1.0f) * 0.5f;

		// A single clip collapses the herd onto ONE pose pool, which is the only way the
		// spatial pose policies read: across six clips a wave is there but overlaid on six
		// different animations, and looks like noise.
		let resource = mModel.Resource;
		let clipCount = (int32)(mSingleClip ? 1 : Math.Min((int32)mModel.Clips.Count, cMaxClipGroups));
		if ((clipCount == 0) || (resource.Skeleton.Get == null))
		{
			mCrowdCount = count;
			AutoFrame(side);
			return;
		}

		let transforms = scope List<List<Float4x4>>();
		let tints = scope List<List<Color>>();
		let poses = scope List<List<uint32>>();
		defer { ClearAndDeleteItems!(transforms); ClearAndDeleteItems!(tints);
			ClearAndDeleteItems!(poses); }
		for (int32 g < clipCount)
		{
			transforms.Add(new List<Float4x4>());
			tints.Add(new List<Color>());
			poses.Add(new List<uint32>());
		}

		let assignment = AssignmentFor(mPosePolicy);
		for (int32 i < count)
		{
			let column = (uint32)(i % side);
			let row = (uint32)(i / side);

			var transform = Transform();
			transform.Position = .(((float)column - half) * cCharacterSpacing, cFloorY,
				((float)row - half) * cCharacterSpacing);
			transform.Scale = .(mModel.Fit, mModel.Fit, mModel.Fit);

			// Round robin, so the clips spread evenly across the grid rather than in blocks.
			let group = i % clipCount;
			transforms[group].Add(transform.ToMatrix());
			tints[group].Add(mTintEnabled ? ClipTint(group) : .(1.0f, 1.0f, 1.0f, 1.0f));

			if (assignment == .Explicit)
				poses[group].Add(PoseIndexFor(column, row, (uint32)side));
		}

		BuildGroups(sets, animations, transforms, tints, poses, assignment, clipCount);

		mCrowdCount = count;
		mClipGroups = clipCount;
		AutoFrame(side);
		mFrameTimeMs = 16.6f;

		let setsPerCharacter = mMergeMeshes ? 1 : mSkinnedParts.Count;
		Console.WriteLine(scope $"AnimatedCrowd: characters={mCrowdCount}  sets/char={setsPerCharacter}  clips={clipCount}  poses={cPoseCount}");
	}

	private void BuildGroups(InstancedMeshComponentManager sets,
		InstancedSkinningComponentManager animations, List<List<Float4x4>> transforms,
		List<List<Color>> tints, List<List<uint32>> poses, PoseAssignment assignment,
		int32 clipCount)
	{
		let drawMeshes = scope List<StaticMesh>();
		let drawMaterials = scope List<Material>();

		if (mMergeMeshes)
		{
			if (mMergedMesh == null)
				mMergedMesh = SkinnedMeshMerge.Merge(mSkinnedParts);
			drawMeshes.Add(mMergedMesh);
			drawMaterials.Add(mSkinnedParts[0].Material);
		}
		else
		{
			for (let part in mSkinnedParts)
			{
				drawMeshes.Add(part.Mesh);
				drawMaterials.Add(part.Material);
			}
		}

		for (int32 group < clipCount)
		{
			if (transforms[group].IsEmpty)
				continue;

			let targets = scope List<EntityHandle>();
			for (int p < drawMeshes.Count)
			{
				let entity = mScene.CreateEntity("crowd_part");
				let component = sets.Add(entity);
				component.Mesh.SetDirect(drawMeshes[p]);
				component.Material.SetDirect(drawMaterials[p]);

				// COPIED, never assigned. The pool creates and frees each of these lists, and
				// Raptor's component holds them by value, so its assignments copy. Handing the
				// component a list this method owns instead would leave it pointing at freed
				// memory the moment the scope below ran, and leak the pool's own list.
				component.SubmeshMaterials.Clear();
				component.SubmeshMaterials.AddRange(mModel.Materials);

				// BEFORE SetInstances: the version bump it makes is what uploads the tints.
				component.Tints.Clear();
				component.Tints.AddRange(tints[group]);

				component.PoseAssignment = assignment;
				component.PoseIndices.Clear();
				if (assignment == .Explicit)
					component.PoseIndices.AddRange(poses[group]);

				component.SetInstances(transforms[group]);
				mCrowdParts.Add(entity);
				targets.Add(entity);
			}

			let animationEntity = mScene.CreateEntity("crowd_anim");
			let skinning = animations.Add(animationEntity);
			skinning.Skeleton = mModel.Resource.Skeleton.Get;
			skinning.Clip = mModel.Clips[group];
			skinning.PoseCount = cPoseCount;
			skinning.Targets.AddRange(targets);
			mCrowdParts.Add(animationEntity);
		}
	}

	/// A base colour per group plus a per character brightness jitter, so a group reads as one
	/// clip without looking like a flat block of paint.
	private Color ClipTint(int32 group)
	{
		let colour = cClipColors[group % cMaxClipGroups];
		let value = 0.7f + mRandom.NextFloat() * 0.5f;
		return .(colour.X * value, colour.Y * value, colour.Z * value, 1.0f);
	}

	/// Random is a function of the flat index, which the renderer computes itself. Everything
	/// else depends on the grid position the renderer cannot see.
	private static PoseAssignment AssignmentFor(PosePolicy policy) =>
		(policy == .Random) ? PoseAssignment.Hashed : PoseAssignment.Explicit;

	/// Wave is Explicit rather than the renderer's Sequential on purpose: Sequential uses a
	/// set's LOCAL index, and each clip set holds every nth character, so it would scramble
	/// the wave rather than draw one.
	private uint32 PoseIndexFor(uint32 column, uint32 row, uint32 side)
	{
		switch (mPosePolicy)
		{
		case .Wave: return PoseSelection.WavePose(column, row, cPoseCount);
		case .Columns: return PoseSelection.ColumnPose(column, cPoseCount);
		case .Clusters: return PoseSelection.ClusterPose(column, row, 4, cPoseCount);
		case .Custom:
			// Concentric rings, computed here rather than by a render helper: each character's
			// distance from the centre quantised into a bucket, so the phase ripples outward.
			let centre = (float)side * 0.5f;
			let dx = (float)column - centre;
			let dz = (float)row - centre;
			return (uint32)Sqrt(dx * dx + dz * dz) % cPoseCount;
		default: return 0;
		}
	}

	private void AutoFrame(int32 side)
	{
		let extent = ((float)side - 1.0f) * cCharacterSpacing * 0.5f + cCharacterSize;

		let floorScale = Math.Max(1.0f, (extent * 2.0f + 40.0f) / cFloorBaseSize);
		var floor = mScene.GetLocalTransform(mFloor);
		floor.Scale = .(floorScale, 1.0f, floorScale);
		mScene.SetLocalTransform(mFloor, floor);

		let targetY = cFloorY + cCharacterSize * 0.5f;
		let distance = extent / Tan(0.5236f) + cCharacterSize * 2.0f;
		let height = extent * 0.55f + cCharacterSize;

		mFly.Position = .(0.0f, targetY + height, distance);
		mFly.Yaw = 0.0f;
		mFly.Pitch = -Atan2(height, distance);

		if (let cameras = mScene.GetSystem<CameraComponentManager>())
		{
			if (let camera = cameras.Get(mCamera))
			{
				camera.NearZ = 0.5f;
				camera.FarZ = distance + extent * 2.0f + 100.0f;
			}
		}
	}

	private void BuildHud(RenderSubsystem render)
	{
		if (!mShowHud)
			return;

		igBegin("Animated Crowd", null, 0);

		let fps = (mFrameTimeMs > 0.001f) ? 1000.0f / mFrameTimeMs : 0.0f;
		igText(scope $"{fps:0} fps   {mFrameTimeMs:0.00} ms");
		igText(scope $"characters: {mCrowdCount}   clips: {mClipGroups} x {cPoseCount} poses ({mClipGroups * (int32)cPoseCount} palettes/frame)");

		var tint = mTintEnabled;
		if (igCheckbox("Per instance tint (colour code by clip)", &tint))
		{
			mTintEnabled = tint;
			RebuildToCount(mCrowdCount);
		}

		var merge = mMergeMeshes;
		if (igCheckbox("Merge parts into one mesh", &merge))
		{
			mMergeMeshes = merge;
			RebuildToCount(mCrowdCount);
		}
		igSameLine(0.0f, -1.0f);
		igTextDisabled(scope $"({(mMergeMeshes ? 1 : mSkinnedParts.Count)} sets/char)");

		let policyNames = scope char8*[cPolicyNames.Count];
		for (int i < cPolicyNames.Count)
			policyNames[i] = cPolicyNames[i].CStr();

		var policy = (int32)mPosePolicy;
		if (igCombo_Str_arr("Pose assignment", &policy, policyNames.Ptr,
			(int32)cPolicyNames.Count, -1))
		{
			mPosePolicy = (PosePolicy)policy;
			RebuildToCount(mCrowdCount);
		}

		var single = mSingleClip;
		if (igCheckbox("Single clip (isolate the pose modes)", &single))
		{
			mSingleClip = single;
			RebuildToCount(mCrowdCount);
		}

		if (render != null)
			BuildRenderRows(render);

		igSeparator();
		if (igButton("+ batch (Space)", .()))
			RebuildToCount(mCrowdCount + cBatchSize);
		igSameLine(0.0f, -1.0f);
		if (igButton("- batch (Backspace)", .()))
			RebuildToCount((mCrowdCount > cBatchSize) ? mCrowdCount - cBatchSize : 0);

		igTextUnformatted("H hides the panel, Esc exits", null);
		igTextUnformatted("WASD and QE move, the right button looks, Shift is fast", null);
		igEnd();
	}

	private void BuildRenderRows(RenderSubsystem render)
	{
		igSeparator();

		var exposure = render.Exposure;
		if (igSliderFloat("Exposure", &exposure, 0.05f, 4.0f, "%.2f", 0))
			render.Exposure = exposure;

		var bloom = render.BloomEnabled;
		if (igCheckbox("Bloom", &bloom))
			render.BloomEnabled = bloom;

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

		var shadowsOn = false;
		if (mScene != null)
		{
			if (let lights = mScene.GetSystem<LightComponentManager>())
			{
				if (let light = mKeyLight.IsAssigned ? lights.Get(mKeyLight) : null)
				{
					shadowsOn = light.CastsShadows;
					if (igCheckbox("Directional shadows (K)", &shadowsOn))
						light.CastsShadows = shadowsOn;
				}
			}
		}
		if (!shadowsOn)
			igTextDisabled("(shadows off, which isolates the skinning throughput)");

		var shadowDistance = render.ShadowDistance;
		if (igSliderFloat("Distance", &shadowDistance, 50.0f, 1000.0f, "%.0f", 0))
			render.ShadowDistance = shadowDistance;

		var shadowFade = render.ShadowFarFade;
		if (igSliderFloat("Far fade", &shadowFade, 2.0f, 150.0f, "%.0f", 0))
			render.ShadowFarFade = shadowFade;

		igTextDisabled(scope $"shadows fade out over the last {shadowFade:0} units");
	}
}
