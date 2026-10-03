using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Editor.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Spline;
using Sedulous.Net.Replication;
using Sedulous.Materials;
using Sedulous.Resource;
using System.Collections;

namespace Sedulous.Editor.Scene.Tests;

/// The scene editor's MCP tools over a real EditorContext holding pages that implement
/// ISceneEditorPage (a headless scene and edit context behind each) beside one that does not:
/// page addressing (the active page, an explicit page, a page that is not a scene), the
/// selection round trip with names and the primary, the refusals for unknown entities and
/// pages, and the simulate control reflecting the page's state.
class SceneMcpToolsTests
{
	/// A page that IS a scene page to the rest of the editor: a headless scene and its edit
	/// context, the simulate state as a flag. No UI, no viewport.
	class HeadlessScenePage : EditorPage, ISceneEditorPage
	{
		private String mTitle = new .() ~ delete _;
		private Sedulous.Scene.Scene mScene = new .("headless") ~ delete _;
		private SceneEditContext mEdit ~ delete _;
		private bool mSimulating = false;

		public this(StringView title, Guid asset)
		{
			mTitle.Set(title);
			InstanceId = asset;
			mEdit = new .(mScene, Commands);
		}

		public override StringView Title => mTitle;
		public override Result<void, ErrorCode> Save() => .Ok;
		public SceneEditContext EditContext => mEdit;
		public void StartSimulation() { mSimulating = true; }
		public void StopSimulation() { mSimulating = false; }
		public void PauseSimulation(bool paused) {}
		public bool IsSimulating => mSimulating;
		public bool IsPaused => false;
		public GizmoController Gizmos => null;
		public bool CameraOwnsInput => false;
		// A viewport is pretended when HasViewport: the camera is real, the capture advances
		// when the test says the frame rendered (CompleteCapture, FailCapture).
		public bool HasViewport = false;
		public Sedulous.Editor.Camera.EditorCamera Camera = new .() ~ delete _;
		public ViewportCapture Capture = new .() ~ delete _;
		public int CaptureRequests = 0;
		public Sedulous.Editor.Camera.EditorCamera ViewportCamera => HasViewport ? Camera : null;
		public Result<void, ErrorCode> RequestViewportCapture(StringView path)
		{
			if (!HasViewport)
				return .Err(.NotSupported);
			Capture.State = .Pending;
			Capture.Path.Set(path);
			CaptureRequests++;
			return .Ok;
		}
		public ViewportCapture LastViewportCapture => Capture;
		public void CompleteCapture(uint32 width, uint32 height)
		{
			Capture.State = .Written;
			Capture.Width = width;
			Capture.Height = height;
		}
		public void FailCapture() { Capture.State = .Failed; }
		public bool MarkersShown => true;
		public void SetMarkersShown(bool shown) {}
		public bool AnimationPanelShown => false;
		public void SetAnimationPanelShown(bool shown) {}
		public void CreatePrefabFromEntity(Guid entity) {}
		public void PickAndSpawnPrefab(Guid parent) {}
		public void ApplyInstanceToPrefab(Guid root) {}
		public void RevertInstance(Guid root) {}
	}

	class PlainPage : EditorPage
	{
		public this(Guid asset)
		{
			InstanceId = asset;
		}

		public override StringView Title => "a material";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static Answer Call(McpServer server, StringView tool, StringView argumentsJson)
	{
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		Test.Assert(server.HandleLine(line, reply) == .Answered);
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		let answer = new Answer();
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	[Test]
	public static void PageAddressingTheSelectionRoundTripItsRefusalsAndTheSimulateControl()
	{
		var rng = Sedulous.Core.Random(7);
		let sceneA = Guid.Generate(ref rng);
		let sceneB = Guid.Generate(ref rng);
		let material = Guid.Generate(ref rng);

		let context = scope EditorContext();
		let pageA = new HeadlessScenePage("Bistro", sceneA);
		let pageB = new HeadlessScenePage("Menu", sceneB);
		let plain = new PlainPage(material);
		context.AdoptPage(pageA);
		context.AdoptPage(pageB);
		context.AdoptPage(plain);
		Test.Assert(context.OpenPages.Count == 3);
		let lamp = pageA.EditContext.CreateEntity("Lamp");
		let table = pageA.EditContext.CreateEntity("Table");
		// The other page's entity is minted straight on its scene with its own guid (a page's
		// CreateEntity also selects, and two fresh scenes may mint the same first guid).
		let otherSceneEntity = Guid.Generate(ref rng);
		pageB.EditContext.Scene.CreateEntity(otherSceneEntity, "Elsewhere");
		pageA.EditContext.EntitySelection.Clear();

		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		Test.Assert(server.ToolCount == SceneMcpTools.cSceneLiveToolCount);
		Test.Assert(SceneMcpTools.cSceneLiveToolCount == 18, "a tripwire: bump deliberately when a live tool comes or goes");
		let onA = scope $"{{\"page\":\"{sceneA}\"}}";

		// Default addressing: the active page, a scene page, then a page that is not one.
		context.SetActivePage(pageA);
		{
			let got = Call(server, "selection_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("page").Get("title").AsString() == "Bistro");
			Test.Assert(got.Payload.Get("entities").Count == 0);
			Test.Assert(got.Payload.Get("primary").IsNull);
		}
		context.SetActivePage(plain);
		{
			let got = Call(server, "selection_get", "{}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("page 'a material' is not a scene or prefab page"), got.Error);
		}
		// Explicit addressing reaches a scene page whatever is active; unknown pages refuse.
		{
			let got = Call(server, "selection_get", onA);
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("page").Get("title").AsString() == "Bistro");
			let unknown = Call(server, "selection_get", "{\"page\":\"00000000-0000-0000-0000-000000000000\"}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no open page for guid"), unknown.Error);
		}

		// The selection round trip: order kept, the first is the primary, names resolved.
		{
			let set = Call(server, "selection_set", scope $"{{\"page\":\"{sceneA}\",\"entities\":[\"{table}\",\"{lamp}\"]}}");
			defer delete set;
			Test.Assert(set.Ok, set.Error);
			let entities = set.Payload.Get("entities");
			Test.Assert(entities.Count == 2);
			Test.Assert(entities.At(0).Get("name").AsString() == "Table");
			Test.Assert(entities.At(1).Get("name").AsString() == "Lamp");
			Test.Assert(set.Payload.Get("primary").AsString() == table.ToString(.. scope .()));
			Test.Assert(pageA.EditContext.EntitySelection.Count == 2);
			Test.Assert(pageA.EditContext.EntitySelection.Primary == table);
			Test.Assert(pageB.EditContext.EntitySelection.IsEmpty); // the other page is untouched
		}
		// An entity of ANOTHER page's scene is refused for this page; nothing changes.
		{
			let wrong = Call(server, "selection_set", scope $"{{\"page\":\"{sceneA}\",\"entities\":[\"{otherSceneEntity}\"]}}");
			defer delete wrong;
			Test.Assert(!wrong.Ok);
			Test.Assert(wrong.Error.StartsWith("no entity with guid"), wrong.Error);
			Test.Assert(pageA.EditContext.EntitySelection.Count == 2);
		}
		// An empty list clears.
		{
			let set = Call(server, "selection_set", scope $"{{\"page\":\"{sceneA}\",\"entities\":[]}}");
			defer delete set;
			Test.Assert(set.Ok, set.Error);
			Test.Assert(pageA.EditContext.EntitySelection.IsEmpty);
		}

		// Simulate reflects the page's state and addresses the same way.
		{
			let sim = Call(server, "simulate_start", onA);
			defer delete sim;
			Test.Assert(sim.Ok, sim.Error);
			Test.Assert(sim.Payload.Get("simulating").AsBool());
			Test.Assert(pageA.IsSimulating);
			Test.Assert(!pageB.IsSimulating);
		}
		{
			let sim = Call(server, "simulate_stop", onA);
			defer delete sim;
			Test.Assert(sim.Ok, sim.Error);
			Test.Assert(!sim.Payload.Get("simulating").AsBool());
			Test.Assert(!pageA.IsSimulating);
		}
		context.SetActivePage(plain);
		{
			let sim = Call(server, "simulate_start", "{}");
			defer delete sim;
			Test.Assert(!sim.Ok);
		}
	}

	/// navigation_bake: the inspector's Bake Navigation for an agent. It bakes a page's zone
	/// into its asset and says why not: no project, no asset assigned, an entity that is no
	/// zone, a page that simulates.
	[Test]
	public static void NavigationBakeBakesAPagesZoneIntoItsAssetAndSaysWhyNot()
	{
		Sedulous.Navigation.Pipeline.NavigationPipeline.RegisterAll();
		let dir = "scratch_navigation_bake_project";
		Sedulous.Core.IO.RemoveDirectoryRecursive(dir);
		defer Sedulous.Core.IO.RemoveDirectoryRecursive(dir);
		Test.Assert(Sedulous.Editor.Project.EditorProject.Create(dir, "P") case .Ok);
		let project = Sedulous.Editor.Project.EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		let context = scope EditorContext();
		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		var rng = Random(77);
		let page = new HeadlessScenePage("Block", Guid.Generate(ref rng));
		context.AdoptPage(page);
		context.SetActivePage(page);
		let edit = page.EditContext;
		let scene = edit.Scene;
		Sedulous.Engine.Navigation.NavigationScene.AddNavigationSceneManagers(scene);
		scene.AddSystem<Sedulous.Engine.Physics.RigidBodyComponentManager>();

		// A static ground slab and a zone over it.
		let groundId = edit.CreateEntity("Ground");
		let ground = edit.Resolve(groundId);
		scene.SetLocalPosition(ground, .(0, -0.5f, 0));
		let body = scene.GetSystem<Sedulous.Engine.Physics.RigidBodyComponentManager>().Add(ground);
		body.Motion = .Static;
		body.HalfExtents = .(10, 0.5f, 10);
		let zoneId = edit.CreateEntity("Zone");
		let zone = scene.GetSystem<Sedulous.Engine.Navigation.NavMeshZoneComponentManager>().Add(edit.Resolve(zoneId));
		zone.Extents = .(15, 10, 15);

		// No project: refused.
		{
			let bake = Call(server, "navigation_bake", "{}");
			defer delete bake;
			Test.Assert(!bake.Ok);
		}
		context.SetProject(project);
		defer context.SetProject(null);

		// A zone with no asset: refused, saying what to do.
		{
			let bake = Call(server, "navigation_bake", "{}");
			defer delete bake;
			Test.Assert(!bake.Ok);
			Test.Assert(bake.Error.Contains("Navigation Zone asset"), bake.Error);
		}
		// An entity that is not a zone: refused.
		{
			let bake = Call(server, "navigation_bake", "{\"entity\":\"Ground\"}");
			defer delete bake;
			Test.Assert(!bake.Ok);
			Test.Assert(bake.Error.Contains("has no navigation zone component"), bake.Error);
		}

		// With the asset: baked, the scene's only zone found without naming it.
		let asset = project.SourceDb.RootGroup.CreateInstance("BlockZone", "Sedulous.Navigation.Pipeline.NavigationZoneAsset");
		Test.Assert(asset != null);
		zone.Zone.SetId(asset.Id);
		{
			let bake = Call(server, "navigation_bake", "{}");
			defer delete bake;
			Test.Assert(bake.Ok, bake.Error);
			Test.Assert(bake.Payload.Get("baked").AsBool(), scope String(bake.Payload.Get("message").AsString()));
			Test.Assert(bake.Payload.Get("triangles").AsInt() == 12); // the slab's box
			Test.Assert(bake.Payload.Get("asset").AsString() == asset.Id.ToString(.. scope .()));
			Test.Assert(bake.Payload.Get("entity").AsString() == zoneId.ToString(.. scope .()));
		}
		{
			let object = asset.ReadObject();
			defer delete object;
			let stored = object as Sedulous.Navigation.Pipeline.NavigationZoneAsset;
			Test.Assert(stored != null);
			Test.Assert(Sedulous.Navigation.Pipeline.NavigationZoneStorage.EnsureNavMeshLoaded(asset, stored) case .Ok);
			Test.Assert(!stored.NavMeshBlob.IsEmpty);
		}

		// Not while the page simulates.
		page.StartSimulation();
		{
			let bake = Call(server, "navigation_bake", "{\"entity\":\"Zone\"}");
			defer delete bake;
			Test.Assert(!bake.Ok);
			Test.Assert(bake.Error.Contains("is simulating"), bake.Error);
		}
		page.StopSimulation();
	}

	private static String GuidText(Guid id, String outText)
	{
		id.ToString(outText);
		return outText;
	}

	/// entity_inspect reads an entity and its components through run time reflection:
	/// identity, hierarchy, transform, enums by name, references as guids, lists expanded, the
	/// primary selection as the default, and the refusals.
	[Test]
	public static void EntityInspectReadsAnEntityAndItsComponentsThroughReflection()
	{
		let context = scope EditorContext();
		let sceneId = Guid.Create();
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage("Bistro", sceneId));
		let edit = page.EditContext;
		let scene = edit.Scene;
		let lights = scene.AddSystem<LightComponentManager>();
		let meshes = scene.AddSystem<MeshComponentManager>();

		let lampId = edit.CreateEntity("Lamp");
		let bulbId = edit.CreateEntity("Bulb", lampId);
		let lamp = edit.Resolve(lampId);
		let bulb = edit.Resolve(bulbId);
		let light = lights.Add(bulb);
		light.Type = .Spot;
		light.Intensity = 2.5f;
		light.Color = .(1.0f, 0.5f, 0.25f, 1.0f);
		let mesh = meshes.Add(lamp);
		let meshAsset = Guid.Create();
		let materialAsset = Guid.Create();
		mesh.Mesh.SetId(meshAsset);
		mesh.Materials.Add(Ref<Material>(materialAsset));
		mesh.Visible = false;
		var placed = Transform();
		placed.Position = .(1.0f, 2.0f, 3.0f);
		scene.SetLocalTransform(lamp, placed);

		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		let pageGuid = GuidText(sceneId, .. scope .());

		// By guid: the lamp with its child, its transform, and the mesh's references and list.
		{
			let got = Call(server, "entity_inspect", scope $"{{\"page\":\"{pageGuid}\",\"entity\":\"{lampId}\"}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let entity = got.Payload.Get("entity");
			Test.Assert(entity.Get("name").AsString() == "Lamp");
			Test.Assert(entity.Get("active").AsBool());
			Test.Assert(entity.Get("parent").IsNull);
			Test.Assert(entity.Get("children").Count == 1);
			Test.Assert(entity.Get("children").At(0).AsString() == GuidText(bulbId, .. scope .()));
			Test.Assert(entity.Get("transform").Get("position").At(2).AsNumber() == 3.0);
			Test.Assert(entity.Get("components").Count == 1);
			let meshJson = entity.Get("components").At(0);
			Test.Assert(meshJson.Get("type").AsString() == "mesh");
			Test.Assert(meshJson.Get("typeName").AsString() == "MeshComponent");
			let props = meshJson.Get("properties");
			Test.Assert(props.Get("Mesh").AsString() == GuidText(meshAsset, .. scope .()));
			Test.Assert(!props.Get("Visible").AsBool());
			Test.Assert(props.Get("Materials").Count == 1);
			Test.Assert(props.Get("Materials").At(0).AsString() == GuidText(materialAsset, .. scope .()));
			Test.Assert(!props.Has("MaterialCache"), "[Hidden] stays out, as in the inspector");
		}

		// The primary selection as the default: the bulb, a child, its light's enum by name.
		edit.EntitySelection.Set(bulbId);
		{
			let got = Call(server, "entity_inspect", scope $"{{\"page\":\"{pageGuid}\"}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			let bulbJson = got.Payload.Get("entity");
			Test.Assert(bulbJson.Get("parent").AsString() == GuidText(lampId, .. scope .()));
			Test.Assert(bulbJson.Get("components").Count == 1);
			let lightProps = bulbJson.Get("components").At(0).Get("properties");
			Test.Assert(lightProps.Get("Type").AsString() == "Spot");
			Test.Assert(Math.Abs(lightProps.Get("Intensity").AsNumber() - 2.5) < 1e-6);
			Test.Assert(lightProps.Get("Color").Count == 4);
			Test.Assert(Math.Abs(lightProps.Get("Color").At(1).AsNumber() - 0.5) < 1e-6);
		}

		// Refusals: no selection and no entity; an unknown entity.
		edit.EntitySelection.Clear();
		{
			let got = Call(server, "entity_inspect", scope $"{{\"page\":\"{pageGuid}\"}}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("page 'Bistro' has no selection"), got.Error);
			let unknown = Call(server, "entity_inspect", scope $"{{\"page\":\"{pageGuid}\",\"entity\":\"00000000-0000-0000-0000-000000000001\"}}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no entity with guid"), unknown.Error);
		}
	}

	/// component_set writes one field through the undo path - leaves, an enum by name, a
	/// reference by guid - one locked step per call that Undo takes back, and the refusals
	/// leave nothing behind.
	[Test]
	public static void ComponentSetWritesOneFieldThroughTheUndoPath()
	{
		let context = scope EditorContext();
		let sceneId = Guid.Create();
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage("Bistro", sceneId));
		let edit = page.EditContext;
		let scene = edit.Scene;
		let lights = scene.AddSystem<LightComponentManager>();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let lampId = edit.CreateEntity("Lamp");
		let lamp = edit.Resolve(lampId);
		lights.Add(lamp).Intensity = 1.0f;
		meshes.Add(lamp);
		page.ClearDirty();
		edit.Commands.Clear();

		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		let pageGuid = GuidText(sceneId, .. scope .());
		let lampGuid = GuidText(lampId, .. scope .());
		Answer Set(StringView component, StringView property, StringView valueJson)
		{
			return Call(server, "component_set", scope $"{{\"page\":\"{pageGuid}\",\"entity\":\"{lampGuid}\",\"component\":\"{component}\",\"property\":\"{property}\",\"value\":{valueJson}}}");
		}

		void SetOk(StringView component, StringView property, StringView valueJson)
		{
			let got = Set(component, property, valueJson);
			defer delete got;
			Test.Assert(got.Ok, got.Error);
		}

		// A float, by the component's serialization id; the page is dirty after, the value read
		// back as entity_inspect shows it.
		{
			let got = Set("light", "Intensity", "2.5");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Math.Abs(lights.Get(lamp).Intensity - 2.5f) < 1e-6f);
			Test.Assert(got.Payload.Get("value").AsNumber() == 2.5);
			Test.Assert(got.Payload.Get("component").AsString() == "light");
			Test.Assert(page.IsDirty);
		}
		// An enum by name, by the type's name; a colour as four numbers; a bool.
		SetOk("LightComponent", "Type", "\"Spot\"");
		Test.Assert(lights.Get(lamp).Type == .Spot);
		SetOk("light", "Color", "[0.1,0.2,0.3,1]");
		Test.Assert(Math.Abs(lights.Get(lamp).Color.G - 0.2f) < 1e-6f);
		SetOk("mesh", "Visible", "false");
		Test.Assert(!meshes.Get(lamp).Visible);
		// A reference by guid (no resource manager in a headless page: the id is the write).
		let meshAsset = Guid.Create();
		{
			let got = Set("mesh", "Mesh", scope $"\"{meshAsset}\"");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(meshes.Get(lamp).Mesh.Id == meshAsset);
			Test.Assert(got.Payload.Get("value").AsString() == GuidText(meshAsset, .. scope .()));
		}

		// Five writes, five undo steps: each Undo takes exactly one back, the reference first.
		let commands = edit.Commands;
		Test.Assert(commands.CanUndo);
		commands.Undo();
		Test.Assert(meshes.Get(lamp).Mesh.Id == Guid());
		Test.Assert(!meshes.Get(lamp).Visible, "the previous step still stands");
		commands.Undo();
		Test.Assert(meshes.Get(lamp).Visible);
		commands.Undo();
		Test.Assert(Math.Abs(lights.Get(lamp).Color.G - 1.0f) < 1e-6f);
		commands.Undo();
		Test.Assert(lights.Get(lamp).Type == .Directional);
		commands.Undo();
		Test.Assert(Math.Abs(lights.Get(lamp).Intensity - 1.0f) < 1e-6f);
		Test.Assert(!commands.CanUndo);
		// Two writes of the SAME field are still two steps (the user's scrubs merge; an
		// agent's calls do not).
		SetOk("light", "Intensity", "3");
		SetOk("light", "Intensity", "4");
		commands.Undo();
		Test.Assert(Math.Abs(lights.Get(lamp).Intensity - 3.0f) < 1e-6f);
		commands.Undo();
		Test.Assert(Math.Abs(lights.Get(lamp).Intensity - 1.0f) < 1e-6f);

		// Refusals, each leaving the value and the stack as they were.
		let stackBefore = commands.UndoIndex;
		void Refused(StringView component, StringView property, StringView valueJson, StringView expected)
		{
			let got = Set(component, property, valueJson);
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith(expected), got.Error);
		}
		Refused("light", "Intensity", "\"bright\"", "field 'Intensity' of 'light' takes a number");
		Refused("light", "Type", "\"Laser\"", "field 'Type' takes one of: Directional, Point, Spot");
		Refused("light", "Brightness", "1", "component 'light' has no field 'Brightness'");
		Refused("physics.RigidBody", "Mass", "1", "entity 'Lamp' has no reflected component");
		Refused("mesh", "Materials", "[]", "field 'Materials' of 'mesh' is a list - not writable through component_set yet");
		Refused("mesh", "MaterialCache", "[]", "component 'mesh' has no field 'MaterialCache'");
		Refused("mesh", "Mesh", "\"not-a-guid\"", "field 'Mesh' is a reference");
		Test.Assert(commands.UndoIndex == stackBefore);
		Test.Assert(Math.Abs(lights.Get(lamp).Intensity - 1.0f) < 1e-6f);
		// Simulating locks the edits.
		page.StartSimulation();
		Refused("light", "Intensity", "9", "page 'Bistro' is simulating");
		page.StopSimulation();
		Test.Assert(Math.Abs(lights.Get(lamp).Intensity - 1.0f) < 1e-6f);
	}

	/// component_set over every value shape: a string set in place and undone, a vector, a
	/// quaternion, an entity reference and its clearing, a reference cleared to null, an enum by
	/// number; and a [ReadOnly] field refused.
	[Test]
	public static void ComponentSetWritesEveryValueShapeAndRefusesAReadOnlyField()
	{
		let context = scope EditorContext();
		let sceneId = Guid.Create();
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage("Bistro", sceneId));
		let edit = page.EditContext;
		let scene = edit.Scene;
		let sources = scene.AddSystem<AudioSourceComponentManager>();
		let transforms = scene.AddSystem<NetworkedTransformComponentManager>();
		let networks = scene.AddSystem<NetworkComponentManager>();
		let followers = scene.AddSystem<PathFollowComponentManager>();
		let lights = scene.AddSystem<LightComponentManager>();
		let meshes = scene.AddSystem<MeshComponentManager>();
		let thingId = edit.CreateEntity("Thing");
		let trackId = edit.CreateEntity("Track");
		let thing = edit.Resolve(thingId);
		sources.Add(thing).BusName.Set("Music");
		transforms.Add(thing);
		networks.Add(thing).Authority = .Server;
		followers.Add(thing);
		lights.Add(thing);
		meshes.Add(thing).Mesh.SetId(Guid.Create());
		edit.Commands.Clear();

		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		let pageGuid = GuidText(sceneId, .. scope .());
		let thingGuid = GuidText(thingId, .. scope .());
		Answer Set(StringView component, StringView property, StringView valueJson)
		{
			return Call(server, "component_set", scope $"{{\"page\":\"{pageGuid}\",\"entity\":\"{thingGuid}\",\"component\":\"{component}\",\"property\":\"{property}\",\"value\":{valueJson}}}");
		}
		void SetOk(StringView component, StringView property, StringView valueJson)
		{
			let got = Set(component, property, valueJson);
			defer delete got;
			Test.Assert(got.Ok, got.Error);
		}
		let commands = edit.Commands;

		// A string, in place: the component keeps its own string object; undo restores the text.
		let busName = sources.Get(thing).BusName;
		{
			let got = Set("AudioSourceComponent", "BusName", "\"Ambience\"");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("value").AsString() == "Ambience");
		}
		Test.Assert((sources.Get(thing).BusName == busName) && (busName == "Ambience"), "the same string object, new text");
		commands.Undo();
		Test.Assert(sources.Get(thing).BusName == "Music");
		{
			let wrong = Set("AudioSourceComponent", "BusName", "7");
			defer delete wrong;
			Test.Assert(!wrong.Ok);
			Test.Assert(wrong.Error.StartsWith("field 'BusName' of 'AudioSourceComponent' takes a string"), wrong.Error);
		}

		// A vector and a quaternion, as entity_inspect shows them.
		SetOk("NetworkedTransform", "Position", "[1,2,3]");
		Test.Assert(transforms.Get(thing).Position == Float3(1, 2, 3));
		SetOk("NetworkedTransform", "Rotation", "[0,0.7071068,0,0.7071068]");
		Test.Assert(Math.Abs(transforms.Get(thing).Rotation.Y - 0.7071068f) < 1e-6f);

		// An entity reference by guid, then cleared with null.
		SetOk("PathFollowComponent", "Spline", scope $"\"{trackId}\"");
		Test.Assert(followers.Get(thing).Spline.Id == trackId);
		SetOk("PathFollowComponent", "Spline", "null");
		Test.Assert(followers.Get(thing).Spline.IsNil);

		// A resource reference cleared with null.
		SetOk("mesh", "Mesh", "null");
		Test.Assert(meshes.Get(thing).Mesh.Id == Guid());

		// An enum by number.
		SetOk("light", "Type", "1");
		Test.Assert(lights.Get(thing).Type == .Point);

		// Read only: replication owns the identity; refused, nothing changes.
		let before = commands.UndoIndex;
		{
			let got = Set("NetworkComponent", "Authority", "\"Client\"");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("field 'Authority' of 'NetworkComponent' is read-only"), got.Error);
		}
		Test.Assert(networks.Get(thing).Authority == .Server);
		Test.Assert(commands.UndoIndex == before);
	}

	/// One pump of a tool that may ask to be re-entered: the line state, and the answer when
	/// there is one (OWNED, null while not finished).
	private static LineState Pump(McpServer server, StringView tool, StringView argumentsJson, out Answer outAnswer)
	{
		outAnswer = null;
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		let state = server.HandleLine(line, reply);
		if (state != .Answered)
			return state;
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		let answer = new Answer();
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		outAnswer = answer;
		return state;
	}

	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-4;

	/// The viewport camera reads and moves in degrees (position, yaw, pitch, lookAt wins), and
	/// viewport_screenshot waits for the page's capture frame by frame.
	[Test]
	public static void TheViewportCameraAndScreenshotTools()
	{
		let context = scope EditorContext();
		let sceneId = Guid.Create();
		let page = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage("Bistro", sceneId));
		let headless = (HeadlessScenePage)context.AdoptPage(new HeadlessScenePage("Menu", Guid.Create()));
		page.HasViewport = true;
		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		let pageGuid = GuidText(sceneId, .. scope .());

		// No viewport: every viewport tool refuses by name.
		context.SetActivePage(headless);
		{
			let got = Call(server, "viewport_camera_get", "{}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("page 'Menu' has no viewport"), got.Error);
			let set = Call(server, "viewport_camera_set", "{\"yawDegrees\":90}");
			defer delete set;
			Test.Assert(!set.Ok);
			Answer shot;
			Test.Assert(Pump(server, "viewport_screenshot", "{}", out shot) == .Answered);
			defer delete shot;
			Test.Assert(!shot.Ok);
			Test.Assert(shot.Error.StartsWith("page 'Menu' has no viewport"), shot.Error);
		}

		// The pose reads in degrees from the camera's radians.
		page.Camera.Position = .(1.0f, 2.0f, 3.0f);
		page.Camera.Yaw = 0.0f;
		page.Camera.Pitch = 0.0f;
		{
			let got = Call(server, "viewport_camera_get", scope $"{{\"page\":\"{pageGuid}\"}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Near(got.Payload.Get("position").At(2).AsNumber(), 3.0));
			Test.Assert(Near(got.Payload.Get("yawDegrees").AsNumber(), 0.0));
			Test.Assert(Near(got.Payload.Get("forward").At(2).AsNumber(), -1.0), "yaw 0 looks down -Z");
		}

		// Set: position, then yaw and pitch in degrees; the pitch clamps short of the pole, at
		// the mouse look's own limit.
		{
			let got = Call(server, "viewport_camera_set", scope $"{{\"page\":\"{pageGuid}\",\"position\":[10,5,0],\"yawDegrees\":90,\"pitchDegrees\":-30}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Near(page.Camera.Position.X, 10.0));
			Test.Assert(Near(page.Camera.Yaw, Math.PI_f / 2));
			Test.Assert(Near(page.Camera.Pitch, -30.0 * Math.PI_d / 180.0));
			Test.Assert(Near(got.Payload.Get("yawDegrees").AsNumber(), 90.0));
			let clamped = Call(server, "viewport_camera_set", scope $"{{\"page\":\"{pageGuid}\",\"pitchDegrees\":-120}}");
			defer delete clamped;
			Test.Assert(clamped.Ok, clamped.Error);
			Test.Assert(Near(page.Camera.Pitch, -Sedulous.Editor.Camera.EditorCamera.cPitchLimit));
		}
		// lookAt aims from the position and wins over yaw and pitch given beside it.
		{
			let got = Call(server, "viewport_camera_set", scope $"{{\"page\":\"{pageGuid}\",\"position\":[0,0,10],\"yawDegrees\":45,\"lookAt\":[0,0,0]}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(Near(page.Camera.Yaw, 0.0));
			Test.Assert(Near(page.Camera.Pitch, 0.0));
			Test.Assert(Near(page.Camera.FocusDistance, 10.0));
			Test.Assert(Near(got.Payload.Get("focusDistance").AsNumber(), 10.0));
		}
		// Wrong shapes change nothing.
		{
			let got = Call(server, "viewport_camera_set", scope $"{{\"page\":\"{pageGuid}\",\"position\":[1,2],\"yawDegrees\":10}}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("`position` takes [x, y, z]"), got.Error);
			Test.Assert(Near(page.Camera.Yaw, 0.0));
		}

		// The screenshot: the first pump brings the page to front and asks for the capture,
		// then the call is re-entered each pump until the page reports the frame written.
		context.SetActivePage(headless);
		let shotArgs = scope $"{{\"page\":\"{pageGuid}\",\"path\":\"/tmp/bistro.png\"}}";
		Answer answer;
		Test.Assert(Pump(server, "viewport_screenshot", shotArgs, out answer) == .NotFinished);
		Test.Assert(context.ActivePage == page);
		Test.Assert(page.CaptureRequests == 1);
		Test.Assert(page.Capture.State == .Pending);
		Test.Assert(page.Capture.Path == "/tmp/bistro.png");
		Test.Assert(Pump(server, "viewport_screenshot", shotArgs, out answer) == .NotFinished, "not yet rendered");
		Test.Assert(page.CaptureRequests == 1, "the same request, not a new one");
		page.CompleteCapture(1280, 720);
		Test.Assert(Pump(server, "viewport_screenshot", shotArgs, out answer) == .Answered);
		{
			defer delete answer;
			Test.Assert(answer.Ok, answer.Error);
			Test.Assert(answer.Payload.Get("path").AsString() == "/tmp/bistro.png");
			Test.Assert(answer.Payload.Get("width").AsNumber() == 1280);
			Test.Assert(answer.Payload.Get("height").AsNumber() == 720);
		}
		// A failed capture is an error naming the log; a new call starts a new request.
		let againArgs = scope $"{{\"page\":\"{pageGuid}\",\"path\":\"/tmp/again.png\"}}";
		Test.Assert(Pump(server, "viewport_screenshot", againArgs, out answer) == .NotFinished);
		Test.Assert(page.CaptureRequests == 2);
		page.FailCapture();
		Test.Assert(Pump(server, "viewport_screenshot", againArgs, out answer) == .Answered);
		defer delete answer;
		Test.Assert(!answer.Ok);
		Test.Assert(answer.Error.StartsWith("the capture of page 'Bistro' failed"), answer.Error);
	}
}
