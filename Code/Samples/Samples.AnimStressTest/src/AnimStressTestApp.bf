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
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shell;
using Samples.Common;
using cimgui_Beef;

namespace Samples.AnimStressTest;

/// A skinning benchmark: a square grid of the same character, each with its own animation
/// player over ONE shared skeleton, mesh and clip set.
///
/// Shared resources and per instance players on purpose: that is what isolates the cost being
/// measured. Duplicating the meshes would measure memory bandwidth instead.
class AnimStressTestApp : DefaultApplication
{
	private const int32 cBatchSize = 25;
	private const float cCharacterSpacing = 8.0f;
	/// The auto fit target, which the floor and the framing are both sized against.
	private const float cCharacterSize = 6.0f;
	private const float cFloorY = -7.0f;
	private const float cFloorBaseSize = 120.0f;
	private const String cOutputDir = "Output/AnimStressTest";
	private const String cModelFile = "Assets/models/QuaterniusCharacter/glTF/Character.gltf";

	private Scene mScene = null;
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mFloor = .Invalid;

	private CookedModel mModel = new .() ~ delete _;
	private StaticMesh mFloorMesh = null ~ delete _;
	private Material mFloorMaterial = null ~ delete _;
	private List<EntityHandle> mInstances = new .() ~ delete _;

	private ImguiSubsystem mOverlay = null ~ delete _;

	private Sedulous.Core.Random mRandom = .(0x9E3779B97F4A7C15UL);
	private FlyCamera mFly = .();
	private float mFrameTimeMs = 16.6f;
	private bool mShowHud = true;

	/// Uncapped, so the frame time is the skinning cost rather than the display's refresh.
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

		mScene = PrimaryScenes.CreateScene("animstress");
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
		{
			// Dark, so the lit characters carry the image rather than the backdrop.
			cameras.Add(mCamera).ClearColor = .(0.02f, 0.02f, 0.03f, 1.0f);
		}

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

		// ONE shadow casting key light and nothing else: extra lights would measure shading
		// rather than the skinning this is here to time.
		if (let lights = mScene.GetSystem<LightComponentManager>())
		{
			let key = mScene.CreateEntity("keyLight");
			var transform = mScene.GetLocalTransform(key);
			transform.Rotation = Quaternion.FromAxisAngle(.(1.0f, 0.0f, 0.0f), -0.9f)
				* Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), 0.5f);
			mScene.SetLocalTransform(key, transform);

			let light = lights.Add(key);
			light.Type = .Directional;
			light.Color = .(1.0f, 0.97f, 0.92f, 1.0f);
			light.Intensity = 2.5f;
			light.CastsShadows = true;
		}

		LoadModel(host);

		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
			render.Exposure = 0.5f; // the sky and sun together wash out at one

		Console.WriteLine("AnimStressTest: Space adds a batch, Backspace removes one, H hides the");
		Console.WriteLine("panel, Esc exits.");
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
			if (input.Keyboard != null)
			{
				if (!HandleKeys(host, input.Keyboard))
					return;
			}
		}

		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);

		// The animation subsystem ticks every player itself, in the scene's post update phase,
		// so there is nothing to drive by hand here.
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

		base.OnRenderWindow(host, ref frame);

		if (mOverlay != null)
			mOverlay.Render(ref frame);
	}

	public override void OnShutdown(IApplicationHost host)
	{
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			host.Graphics.Raw.WaitIdle();

		base.OnShutdown(host);
		Console.WriteLine("AnimStressTest: shutting down.");
	}

	/// False when the application asked to exit, so the caller stops touching the scene.
	private bool HandleKeys(IApplicationHost host, IKeyboard keyboard)
	{
		if (keyboard.IsKeyPressed(.Escape))
		{
			host.RequestExit(0);
			return false;
		}

		if (keyboard.IsKeyPressed(.Space))
			AddBatch();
		if (keyboard.IsKeyPressed(.Backspace))
			RemoveBatch();
		if (keyboard.IsKeyPressed(.H))
			mShowHud = !mShowHud;

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

	private void LoadModel(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (!mModel.Open(DataPath(cOutputDir, .. scope String()), device))
			return;

		// The model lives in the repository's data, found by walking up from wherever this was
		// run. A checkout without it simply shows the empty stage.
		let path = scope String();
		DataPath(cModelFile, path);
		if (!FileExists(path))
		{
			Console.WriteLine(scope $"AnimStressTest: no model at {cModelFile}, showing an empty stage.");
			return;
		}

		if (!mModel.Cook("Char", path, cCharacterSize))
			return;

		RebuildToCount(cBatchSize);
	}

	// ---- the grid ----

	private void AddBatch() => RebuildToCount((int32)mInstances.Count + cBatchSize);

	private void RemoveBatch()
	{
		let count = (int32)mInstances.Count;
		RebuildToCount((count > cBatchSize) ? count - cBatchSize : 0);
	}

	/// Rebuilt wholesale rather than grown, because the grid is RE CENTRED every time: adding
	/// to one edge would drift the whole field off the floor.
	private void RebuildToCount(int32 count)
	{
		for (let instance in mInstances)
			mScene.DestroyEntity(instance); // recurses, so the hierarchy goes with it
		mInstances.Clear();

		let side = (count == 0) ? (int32)1 : (int32)Ceil(Sqrt((float)count));
		let half = ((float)side - 1.0f) * 0.5f;
		for (int32 i < count)
		{
			let x = ((float)(i % side) - half) * cCharacterSpacing;
			let z = ((float)(i / side) - half) * cCharacterSpacing;
			SpawnInstance(.(x, cFloorY, z));
		}

		AutoFrame(side);
		mFrameTimeMs = 16.6f; // the rebuild hitch would otherwise skew the next few readings
		Console.WriteLine(scope $"AnimStressTest: characters={mInstances.Count}");
	}

	/// One instance: the model's node hierarchy under a scaled root, mesh nodes pointing at the
	/// SHARED cooked meshes, and its own player over the shared skeleton.
	private void SpawnInstance(Float3 position)
	{
		let meshes = mScene.GetSystem<MeshComponentManager>();
		let resource = mModel.Resource;
		if ((meshes == null) || (resource == null))
			return;

		let root = mScene.CreateEntity("char");
		var rootTransform = Transform();
		rootTransform.Position = position;
		rootTransform.Scale = .(mModel.Fit, mModel.Fit, mModel.Fit);
		mScene.SetLocalTransform(root, rootTransform);

		let entities = scope List<EntityHandle>();
		let skinned = scope List<EntityHandle>();

		for (let node in resource.Nodes)
		{
			let entity = mScene.CreateEntity(node.Name);
			mScene.SetLocalTransform(entity, node.LocalTransform);
			entities.Add(entity);
		}

		for (int i < resource.Nodes.Count)
		{
			let node = resource.Nodes[i];
			// A top level node hangs off the SCALED root, which is what applies the auto fit
			// to the whole hierarchy at once.
			if ((node.ParentIndex >= 0) && (node.ParentIndex < entities.Count))
				mScene.SetParent(entities[i], entities[node.ParentIndex]);
			else
				mScene.SetParent(entities[i], root);

			if ((node.MeshIndex < 0) || (node.MeshIndex >= resource.Meshes.Count))
				continue;

			let mesh = resource.Mesh(node.MeshIndex);
			if (mesh == null)
				continue;

			let component = meshes.Add(entities[i]);
			component.Mesh.SetDirect(mesh);
			component.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
			component.SetMaterials(mModel.Materials); // slot zero covers an out of range index
			if (resource.MeshSkinned[node.MeshIndex])
				skinned.Add(entities[i]);
		}

		AttachAnimation(root, skinned);
		mInstances.Add(root);
	}

	/// A random clip, a jittered speed and a random start time: without all three the crowd
	/// moves in lockstep, which looks like one animation rather than a hundred.
	private void AttachAnimation(EntityHandle root, List<EntityHandle> skinned)
	{
		let resource = mModel.Resource;
		if ((resource.Skeleton.Get == null) || mModel.Clips.IsEmpty || skinned.IsEmpty)
			return;

		let animations = mScene.GetSystem<SkeletalAnimationComponentManager>();
		if (animations == null)
			return;

		let clip = mModel.Clips[mRandom.NextInt(0, (int32)mModel.Clips.Count - 1)];
		let component = animations.Add(root);
		component.Skeleton.SetDirect(resource.Skeleton.Get);
		component.Clip.SetDirect(clip);

		for (let entity in skinned)
			component.MeshEntities.Add(.(mScene.GetEntityId(entity)));

		component.Speed = 0.85f + mRandom.NextFloat() * 0.3f;
		component.StartTime = ((clip != null) && (clip.Duration > 0.0f))
			? mRandom.NextFloat() * clip.Duration
			: 0.0f;
	}

	/// Frames the whole grid and grows the floor under it. The far plane goes with them, or the
	/// back rows would be culled and the measurement would flatter itself.
	private void AutoFrame(int32 side)
	{
		let extent = ((float)side - 1.0f) * cCharacterSpacing * 0.5f + cCharacterSize;

		let floorScale = Math.Max(1.0f, (extent * 2.0f + 40.0f) / cFloorBaseSize);
		var floor = mScene.GetLocalTransform(mFloor);
		floor.Scale = .(floorScale, 1.0f, floorScale);
		mScene.SetLocalTransform(mFloor, floor);

		let targetY = cFloorY + cCharacterSize * 0.5f;
		let distance = extent / Tan(0.5236f) + cCharacterSize * 2.0f; // half of sixty degrees
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

		igBegin("Anim Stress Test", null, 0);

		let fps = (mFrameTimeMs > 0.001f) ? 1000.0f / mFrameTimeMs : 0.0f;
		igText(scope $"{fps:0} fps   {mFrameTimeMs:0.00} ms");
		igText(scope $"characters: {mInstances.Count}");

		if (render != null)
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
			igTextUnformatted("Directional shadows", null);

			var shadowDistance = render.ShadowDistance;
			if (igSliderFloat("Distance", &shadowDistance, 50.0f, 1000.0f, "%.0f", 0))
				render.ShadowDistance = shadowDistance;

			var shadowFade = render.ShadowFarFade;
			if (igSliderFloat("Far fade", &shadowFade, 2.0f, 150.0f, "%.0f", 0))
				render.ShadowFarFade = shadowFade;

			igTextDisabled(scope $"shadows fade out over the last {shadowFade:0} units");
		}

		igSeparator();
		if (igButton("+ batch (Space)", .()))
			AddBatch();
		igSameLine(0.0f, -1.0f);
		if (igButton("- batch (Backspace)", .()))
			RemoveBatch();

		igTextUnformatted("H hides the panel, Esc exits", null);
		igTextUnformatted("WASD and QE move, the right button looks, Shift is fast", null);
		igEnd();
	}
}
