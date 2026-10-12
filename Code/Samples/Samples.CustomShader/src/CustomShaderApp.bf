using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Animation;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.Render;
using Sedulous.Geometry;
using Sedulous.Graphics;
using Sedulous.Materials;
using Sedulous.Model.Resource;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Shaders;
using Sedulous.Shell;
using Samples.Common;

namespace Samples.CustomShader;

/// A LOW-LEVEL custom shader end to end: a toon (cel) shader, one file with VSMain and PSMain
/// (Data/Assets/shaders/toon/toon.hlsl), registered with the render subsystem's shader system under
/// the name "toon", and materials built in code whose properties lay out the shader's set-2
/// block. Nothing in the renderer knows about it: a material's property list derives its bind
/// group layout and pipeline, and the shader keeps the frame's contract (sets 0, 1 and 3, the
/// vertex input and the five G-buffer targets).
///
/// What it exercises: distinct draws and an instanced batch of one material (the INSTANCED vertex
/// variant), a masked material (the ALPHA_TEST variant), a sun's cascaded shadows and a point
/// light's cube shadow received by toon surfaces, toon casters in those shadows (the built-in
/// depth shaders), TAA (the motion vectors the toon pixel shader writes) and, beside it, the
/// engine's PBR for comparison, and the glTF Fox, skinned and walking, in toon (the SKINNED
/// variant). WASD and the right button fly; Esc quits.
class CustomShaderApp : DefaultApplication
{
	private const String cShaderFile = "Assets/shaders/toon/toon.hlsl";
	private const String cOutputDir = "Output/CustomShader";
	private const String cModelFile = "Assets/models/Fox/glTF/Fox.gltf";

	private Scene mScene = null;
	private EntityHandle mCamera = .Invalid;
	private EntityHandle mRing = .Invalid;
	private EntityHandle mTorus = .Invalid;
	private float mTime = 0.0f;
	private FlyCamera mFly = .();

	private CookedModel mModel = new .() ~ delete _;
	/// What the scene's mesh components point at, kept alive as long as they are.
	private List<StaticMesh> mMeshes = new .() ~ DeleteContainerAndItems!(_);
	private List<Material> mMaterials = new .() ~ DeleteContainerAndItems!(_);

	public override void OnStartup(IApplicationHost host)
	{
		base.OnStartup(host);

		let render = host.Context.GetSubsystem<RenderSubsystem>();
		if ((render == null) || (render.Shaders == null) || !RegisterToonShader(render.Shaders))
			return;

		mScene = PrimaryScenes.CreateScene("custom-shader");
		if (let environment = mScene.GetSystem<EnvironmentSystem>())
		{
			environment.Environment.AmbientColor = .(0.45f, 0.5f, 0.6f, 1.0f);
			environment.Environment.AmbientIntensity = 0.6f;
		}
		if (let post = mScene.GetSystem<PostProcessSystem>())
			post.Post.AaMode = .TAA; // the toon motion vectors in use

		mCamera = mScene.CreateEntity("camera");
		if (let cameras = mScene.GetSystem<CameraComponentManager>())
			cameras.Add(mCamera);
		mFly.Position = .(0.0f, 4.0f, 13.0f);
		mFly.Pitch = -0.25f;
		mFly.MoveSpeed = 6.0f;
		mFly.FastSpeed = 18.0f;

		BuildScene();
		BuildLights();
		SpawnToonFox(host);

		Console.WriteLine("CustomShader: a toon shader from Data/Assets/shaders/toon.");
		Console.WriteLine("WASD and the right button fly, Esc quits.");
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		let input = (host.Shell != null) ? host.Shell.Input : null;
		if (input != null)
		{
			mFly.Update(input.Keyboard, input.Mouse, deltaTime);
			if ((input.Keyboard != null) && input.Keyboard.IsKeyPressed(.Escape))
			{
				host.RequestExit(0);
				return;
			}
		}
		if (mScene == null)
			return;

		var transform = mScene.GetLocalTransform(mCamera);
		transform.Position = mFly.Position;
		transform.Rotation = mFly.Rotation;
		mScene.SetLocalTransform(mCamera, transform);

		// Motion for TAA to reproject: the ring of cubes turns, the torus spins.
		mTime += deltaTime;
		var ring = mScene.GetLocalTransform(mRing);
		ring.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), mTime * 0.4f);
		mScene.SetLocalTransform(mRing, ring);
		var spin = mScene.GetLocalTransform(mTorus);
		spin.Rotation = Quaternion.FromAxisAngle(.(1, 0, 0), mTime * 1.3f);
		mScene.SetLocalTransform(mTorus, spin);
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
		FinishFrame(host, ref frame); // the --screenshot copy
	}

	public override void OnShutdown(IApplicationHost host)
	{
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			host.Graphics.Raw.WaitIdle();
		base.OnShutdown(host);
	}

	/// The shader, one file with both stages (VSMain and PSMain), read from the data root and
	/// registered by name with each stage's entry point. A registered source wins over the cooked
	/// pack and compiles on first use (DXC, so a development build: a compiler free dist cannot
	/// compile it). Every module made from it records its entry, so the renderer's pipelines run
	/// VSMain and PSMain unbidden.
	private bool RegisterToonShader(ShaderSystem shaders)
	{
		let path = DataPath(cShaderFile, .. scope String());
		let text = scope String();
		if (System.IO.File.ReadAllText(path, text) case .Err)
		{
			Console.Error.WriteLine(scope $"CustomShader: missing the toon shader: {path}");
			return false;
		}
		shaders.RegisterSource("toon", .Vertex, text, "VSMain");
		shaders.RegisterSource("toon", .Fragment, text, "PSMain");
		return true;
	}

	/// The toon material: the properties toon.hlsl's block declares, in its order, so the builder
	/// lays them out where the shader's set-2 block puts them, then the albedo map and its
	/// sampler, t0 and s0.
	private Material CreateToon(StringView name, Float4 baseColor, Float4 shadowColor, float bands = 3.0f)
	{
		let material = scope MaterialBuilder(name)
			.Shader("toon")
			.VertexLayout(.Mesh)
			.Color("BaseColor", baseColor)
			.Color("ShadowColor", shadowColor)
			.Color("RimColor", .(1.0f, 0.95f, 0.85f, 1.0f))
			.Float("Bands", bands)
			.Float("RimPower", 3.0f)
			.Float("RimIntensity", 0.6f)
			.Float("AlphaCutoff", 0.5f)
			.Texture("AlbedoMap")
			.Sampler("MainSampler")
			.Build();
		mMaterials.Add(material);
		return material;
	}

	private StaticMesh Own(StaticMesh mesh)
	{
		mMeshes.Add(mesh);
		return mesh;
	}

	private EntityHandle AddMesh(StringView name, StaticMesh mesh, Material material, Float3 position,
		EntityHandle parent = .Invalid)
	{
		let entity = mScene.CreateEntity(name);
		if (parent.IsAssigned)
			mScene.SetParent(entity, parent);
		mScene.SetLocalPosition(entity, position);
		let component = mScene.GetSystem<MeshComponentManager>().Add(entity);
		component.Mesh.SetDirect(mesh);
		component.SetMaterial(material);
		return entity;
	}

	private void BuildScene()
	{
		let sphere = Own(Primitives.Sphere(0.8f, 48, 24));
		let cube = Own(Primitives.Cube(0.7f));
		let plane = Own(Primitives.Plane(30.0f, 30.0f));

		// The floor: toon, so it RECEIVES the shadows the toon shader samples itself.
		AddMesh("floor", plane, CreateToon("ToonFloor", .(0.75f, 0.75f, 0.72f, 1.0f),
			.(0.35f, 0.38f, 0.5f, 1.0f), 2.0f), .(0.0f, 0.0f, 0.0f));

		// Five toon styles in a row: distinct materials, distinct draws.
		(Float4 color, Float4 shade, float bands)[5] styles = .(
			(.(0.9f, 0.2f, 0.2f, 1.0f), .(0.35f, 0.08f, 0.15f, 1.0f), 2.0f),
			(.(0.2f, 0.45f, 0.95f, 1.0f), .(0.1f, 0.1f, 0.35f, 1.0f), 3.0f),
			(.(0.3f, 0.85f, 0.35f, 1.0f), .(0.1f, 0.3f, 0.2f, 1.0f), 4.0f),
			(.(1.0f, 0.8f, 0.25f, 1.0f), .(0.45f, 0.25f, 0.1f, 1.0f), 3.0f),
			(.(0.7f, 0.35f, 0.9f, 1.0f), .(0.25f, 0.1f, 0.35f, 1.0f), 5.0f));
		for (int i < 5)
		{
			AddMesh("style", sphere, CreateToon("ToonStyle", styles[i].color, styles[i].shade, styles[i].bands),
				.(-5.0f + 2.5f * (float)i, 0.8f, 0.0f));
		}

		// A ring of twelve cubes sharing ONE material and mesh: drawn as an instanced batch, the
		// INSTANCED vertex variant of the toon shader.
		mRing = mScene.CreateEntity("ring");
		mScene.SetLocalPosition(mRing, .(0.0f, 0.5f, -5.0f));
		let ringToon = CreateToon("ToonRing", .(0.95f, 0.6f, 0.2f, 1.0f), .(0.4f, 0.15f, 0.1f, 1.0f), 3.0f);
		for (int i < 12)
		{
			let angle = Math.PI_f * 2.0f * (float)i / 12.0f;
			AddMesh("ringCube", cube, ringToon, .(3.0f * Math.Cos(angle), 0.0f, 3.0f * Math.Sin(angle)), mRing);
		}

		// A spinning torus (motion vectors under TAA) and, beside it, the engine's PBR on the same
		// kind of surface, for comparison.
		let torus = Own(Primitives.Torus(0.8f, 0.3f));
		mTorus = AddMesh("torus", torus, CreateToon("ToonTorus", .(0.25f, 0.85f, 0.85f, 1.0f),
			.(0.05f, 0.2f, 0.3f, 1.0f), 3.0f), .(-3.0f, 1.3f, 3.5f));
		let pbr = MaterialPresets.CreatePbr("Pbr", .(0.25f, 0.85f, 0.85f, 1.0f), 0.0f, 0.4f);
		mMaterials.Add(pbr);
		AddMesh("pbr", sphere, pbr, .(3.0f, 0.8f, 3.5f));

		// A masked toon material: drawn through the shader's ALPHA_TEST variant (with no texture
		// its alpha is 1 throughout, so nothing is cut: the variant compiles and draws).
		let masked = CreateToon("ToonMasked", .(0.9f, 0.9f, 0.95f, 1.0f), .(0.3f, 0.3f, 0.45f, 1.0f), 3.0f);
		masked.Pipeline.BlendMode = .Masked;
		AddMesh("masked", cube, masked, .(0.0f, 2.6f, 2.0f));
	}

	private void BuildLights()
	{
		let lights = mScene.GetSystem<LightComponentManager>();
		if (lights == null)
			return;

		let sun = mScene.CreateEntity("sun");
		var transform = mScene.GetLocalTransform(sun);
		transform.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), -0.7f) * Quaternion.FromAxisAngle(.(1, 0, 0), -0.8f);
		mScene.SetLocalTransform(sun, transform);
		let sunLight = lights.Add(sun);
		sunLight.Type = .Directional;
		sunLight.Intensity = 2.5f;
		sunLight.CastsShadows = true;

		let lamp = mScene.CreateEntity("lamp");
		mScene.SetLocalPosition(lamp, .(2.0f, 2.5f, -3.0f));
		let lampLight = lights.Add(lamp);
		lampLight.Type = .Point;
		lampLight.Color = .(1.0f, 0.5f, 0.2f, 1.0f);
		lampLight.Intensity = 30.0f;
		lampLight.Range = 9.0f;
		lampLight.CastsShadows = true;
	}

	/// The Fox (glTF, skinned and animated), cooked at startup into this sample's own output
	/// database, then drawn with toon materials that keep its texture: the SKINNED variant.
	private void SpawnToonFox(IApplicationHost host)
	{
		let device = (host.Graphics != null) ? host.Graphics.Raw : null;
		if (!mModel.Open(DataPath(cOutputDir, .. scope String()), device))
			return;
		let path = DataPath(cModelFile, .. scope String());
		if (!FileExists(path))
		{
			Console.WriteLine(scope $"CustomShader: no model at {cModelFile}, no Fox.");
			return;
		}
		if (!mModel.Cook("Fox", path, 2.0f))
			return;
		let resource = mModel.Resource;
		if ((resource.Skeleton.Get == null) || mModel.Clips.IsEmpty)
			return;

		// One toon material per Fox material, keeping its albedo texture.
		let toonMaterials = scope List<Material>();
		for (var source in ref resource.Materials)
		{
			let toon = CreateToon("ToonFox", .(1.0f, 1.0f, 1.0f, 1.0f), .(0.45f, 0.2f, 0.12f, 1.0f), 3.0f);
			if (let sourceMaterial = source.Get)
			{
				let albedo = sourceMaterial.GetPropertyIndex("AlbedoMap");
				if (albedo >= 0)
					toon.SetDefaultTexture("AlbedoMap", sourceMaterial.GetDefaultTexture(albedo));
			}
			toonMaterials.Add(toon);
		}

		let root = mScene.CreateEntity("fox");
		var rootTransform = Transform();
		rootTransform.Position = .(5.5f, 0.0f, 3.0f);
		rootTransform.Scale = .(mModel.Fit, mModel.Fit, mModel.Fit);
		mScene.SetLocalTransform(root, rootTransform);

		let meshes = mScene.GetSystem<MeshComponentManager>();
		let entities = scope List<EntityHandle>();
		let skinned = scope List<EntityHandle>();
		let slots = scope List<int32>();
		let meshMaterials = scope List<Material>();
		for (let node in resource.Nodes)
		{
			let entity = mScene.CreateEntity(node.Name);
			mScene.SetLocalTransform(entity, node.LocalTransform);
			entities.Add(entity);
		}
		for (int i < resource.Nodes.Count)
		{
			let node = resource.Nodes[i];
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
			resource.MeshMaterialIndices(node.MeshIndex, slots);
			meshMaterials.Clear();
			for (let slot in slots)
				meshMaterials.Add(((slot >= 0) && (slot < toonMaterials.Count)) ? toonMaterials[slot] : null);
			component.SetMaterials(meshMaterials);
			if (resource.MeshSkinned[node.MeshIndex])
				skinned.Add(entities[i]);
		}

		let animations = mScene.GetSystem<SkeletalAnimationComponentManager>();
		if ((animations == null) || skinned.IsEmpty)
			return;
		let animation = animations.Add(root);
		animation.Skeleton.SetDirect(resource.Skeleton.Get);
		// The Fox's clips are Survey, Walk and Run: Walk if it is there.
		animation.Clip.SetDirect(mModel.Clips[Math.Min(1, mModel.Clips.Count - 1)]);
		for (let entity in skinned)
			animation.MeshEntities.Add(.(mScene.GetEntityId(entity)));
	}
}
