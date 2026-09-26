using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Editor.Core;
using Sedulous.Engine.Render;
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
		public bool MarkersShown => true;
		public void SetMarkersShown(bool shown) {}
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
		Refused("mesh", "Materials", "[]", "field 'Materials' of 'mesh' is a list or object");
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
}
