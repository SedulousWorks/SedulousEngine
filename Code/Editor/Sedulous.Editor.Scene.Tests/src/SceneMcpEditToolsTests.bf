using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The live editing tools over a real EditorContext holding a headless scene page whose scene
/// carries the engine's managers: building a level entity by entity, each call one undo step;
/// components added and removed; a prefab placed and linked; and the refusals.
class SceneMcpEditToolsTests
{
	/// A scene page to the editor: a real edit context over a scene with the engine's managers,
	/// and a prefab resolver answering one prefab.
	class EditablePage : EditorPage, ISceneEditorPage
	{
		private Sedulous.Scene.Scene mScene = new .("level") ~ delete _;
		private SceneEditContext mEdit ~ delete _;
		public bool Simulating = false;
		public Guid PrefabId = Guid.Create();

		public this(Guid asset)
		{
			InstanceId = asset;
			EngineSceneComposition.AddAllSceneManagers(mScene);
			mScene.AddSystem<HealthManager>();
			mEdit = new .(mScene, Commands);
			mEdit.SetPrefabResolver(new [=this](id) =>
				{
					if (id != PrefabId)
						return null;
					let bytes = PrefabPayloads.Capture("Crate", 7);
					defer delete bytes;
					let stream = new MemoryStream();
					stream.Write(bytes);
					stream.Seek(0, .Begin);
					return stream;
				});
		}

		public override StringView Title => "Level";
		public override Result<void, ErrorCode> Save() => .Ok;
		public SceneEditContext EditContext => mEdit;
		public void StartSimulation() { Simulating = true; }
		public void StopSimulation() { Simulating = false; }
		public void PauseSimulation(bool paused) {}
		public bool IsSimulating => Simulating;
		public bool IsPaused => false;
		public Sedulous.Editor.ViewportTools.ViewportToolManager ViewportTools => null;
		public GizmoController Gizmos => null;
		public bool CameraOwnsInput => false;
		public Sedulous.Editor.Camera.EditorCamera ViewportCamera => null;
		public bool FrameEntities(Span<Guid> entities, bool ease) => false;
		public Result<void, ErrorCode> RequestViewportCapture(StringView path) => .Err(.NotSupported);
		public Result<void, ErrorCode> RequestProjectThumbnail() => .Err(.NotSupported);
		public ViewportCapture LastViewportCapture => null;
		public bool BeginScriptedInput(Sedulous.Input.ScriptedInputSource source) { delete source; return false; }
		public void EndScriptedInput() {}
		public double ScriptedInputTime => -1.0;
		public Float2 ViewportPixels => .Zero;
		public bool MarkersShown => true;
		public void SetMarkersShown(bool shown) {}
		public bool AnimationPanelShown => false;
		public void SetAnimationPanelShown(bool shown) {}
		public void EditAnimationClip(Guid clip, Guid entity) {}
		public void CreatePrefabFromEntity(Guid entity) {}
		public void PickAndSpawnPrefab(Guid parent) {}
		public void ApplyInstanceToPrefab(Guid root) {}
		public void RevertInstance(Guid root) {}
	}

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
		Test.Assert(result != null, reply);
		let answer = new Answer();
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	/// `entity`'s component of wire name `wire` as entity_inspect shows it; null without one.
	private static JsonValue ComponentOf(JsonValue entity, StringView wire)
	{
		let components = entity.Get("components");
		for (int i < components.Count)
		{
			if (components.At(i).Get("type").AsString() == wire)
				return components.At(i);
		}
		return null;
	}

	private static bool HasComponent(JsonValue entity, StringView wire)
	{
		let components = entity.Get("components");
		for (int i < components.Count)
		{
			if (components.At(i).Get("type").AsString() == wire)
				return true;
		}
		return false;
	}

	[Test]
	public static void AnAgentBuildsALevelOneUndoStepAtATime()
	{
		let context = scope EditorContext();
		let page = (EditablePage)context.AdoptPage(new EditablePage(Guid.Create()));
		context.SetActivePage(page);
		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		let commands = page.Commands;
		let scene = page.EditContext.Scene;

		// An entity, placed: one undo step for the create and its transform together.
		let platformId = scope String();
		{
			let made = Call(server, "entity_create", "{\"name\":\"Platform\",\"position\":[1,2,3],\"yawDegrees\":90,\"scale\":[2,1,2]}");
			defer delete made;
			Test.Assert(made.Ok, made.Error);
			platformId.Set(made.Payload.Get("entity").Get("guid").AsString());
			let transform = made.Payload.Get("entity").Get("transform");
			Test.Assert(transform.Get("position").At(1).AsNumber() == 2);
			Test.Assert(transform.Get("scale").At(0).AsNumber() == 2);
			Test.Assert(Math.Abs(transform.Get("rotation").At(1).AsNumber() - Math.Sin(Math.PI_d / 4)) < 1e-5, "a quarter turn about +Y");
			commands.Undo();
			Test.Assert(!scene.FindEntityByName("Platform").IsAssigned, "one undo takes the create and its placement back");
			commands.Redo();
			let redone = scene.FindEntityByName("Platform");
			Test.Assert(redone.IsAssigned && (scene.GetLocalTransform(redone).Position.Y == 2));
		}

		// Components by wire name, added once; removed by name.
		{
			let added = Call(server, "component_add", "{\"entity\":\"Platform\",\"component\":\"physics.RigidBody\"}");
			defer delete added;
			Test.Assert(added.Ok, added.Error);
			Test.Assert(HasComponent(added.Payload.Get("entity"), "physics.RigidBody"));
			let again = Call(server, "component_add", "{\"entity\":\"Platform\",\"component\":\"physics.RigidBody\"}");
			defer delete again;
			Test.Assert(again.Error.StartsWith("'Platform' already has a physics.RigidBody"), again.Error);
			let unknown = Call(server, "component_add", "{\"entity\":\"Platform\",\"component\":\"physics.Warp\"}");
			defer delete unknown;
			Test.Assert(unknown.Error.StartsWith("no component 'physics.Warp'"), unknown.Error);
			let removed = Call(server, "component_remove", "{\"entity\":\"Platform\",\"component\":\"physics.RigidBody\"}");
			defer delete removed;
			Test.Assert(removed.Ok, removed.Error);
			Test.Assert(!HasComponent(removed.Payload.Get("entity"), "physics.RigidBody"));
		}

		// A child made under the platform, then renamed, switched off and moved to the root in
		// one step; a parent loop is refused.
		{
			let child = Call(server, "entity_create", "{\"name\":\"Lamp\",\"parent\":\"Platform\"}");
			defer delete child;
			Test.Assert(child.Ok, child.Error);
			Test.Assert(child.Payload.Get("entity").Get("parent").AsString() == platformId);
			let loop = Call(server, "entity_update", "{\"entity\":\"Platform\",\"parent\":\"Lamp\"}");
			defer delete loop;
			Test.Assert(loop.Error.StartsWith("an entity cannot move under itself"), loop.Error);
			let updated = Call(server, "entity_update", "{\"entity\":\"Platform/Lamp\",\"name\":\"Torch\",\"active\":false,\"parent\":\"\",\"position\":[0,5,0]}");
			defer delete updated;
			Test.Assert(updated.Ok, updated.Error);
			let torch = updated.Payload.Get("entity");
			Test.Assert(torch.Get("name").AsString() == "Torch");
			Test.Assert(!torch.Get("active").AsBool());
			Test.Assert(torch.Get("parent").IsNull);
			Test.Assert(torch.Get("transform").Get("position").At(1).AsNumber() == 5);
			commands.Undo();
			let lamp = scene.FindEntityByName("Lamp");
			Test.Assert(lamp.IsAssigned && scene.IsActive(lamp) && (scene.GetParent(lamp) == scene.FindEntityByName("Platform")), "one undo takes the whole update back");
			commands.Redo();
		}

		// A prefab placed and linked to its prefab, at its position; an unknown one refused.
		{
			let spawned = Call(server, "prefab_spawn", scope $"{{\"prefab\":\"{page.PrefabId}\",\"position\":[4,0,-2]}}");
			defer delete spawned;
			Test.Assert(spawned.Ok, spawned.Error);
			let root = spawned.Payload.Get("entity");
			Test.Assert(root.Get("name").AsString() == "Crate");
			Test.Assert(root.Get("transform").Get("position").At(0).AsNumber() == 4);
			Test.Assert(scene.FindPrefabInstanceByRoot(Guid.Parse(root.Get("guid").AsString())) != null, "linked to its prefab");
			let missing = Call(server, "prefab_spawn", scope $"{{\"prefab\":\"{Guid.Create()}\"}}");
			defer delete missing;
			Test.Assert(missing.Error.StartsWith("no prefab"), missing.Error);
		}

		// A script on an entity: entity_inspect lists the behaviour the component holds (its
		// class is not cooked here, so its properties would be named by hash).
		{
			let script = Guid.Create();
			let target = page.EditContext.Resolve(Guid.Parse(platformId));
			let scripts = page.EditContext.FindManager(typeof(Sedulous.Engine.Script.ScriptComponent));
			page.EditContext.AddComponent(Guid.Parse(platformId), typeof(Sedulous.Engine.Script.ScriptComponent));
			let component = (Sedulous.Engine.Script.ScriptComponent*)scripts.GetComponentAddress(target);
			let behavior = new Sedulous.Engine.Script.ScriptBehavior();
			behavior.Script = .(script);
			component.Behaviors.Add(behavior);
			let inspected = Call(server, "entity_inspect", "{\"entity\":\"Platform\"}");
			defer delete inspected;
			Test.Assert(inspected.Ok, inspected.Error);
			let components = inspected.Payload.Get("entity").Get("components");
			JsonValue behaviors = null;
			for (int i < components.Count)
				if (components.At(i).Get("type").AsString() == "script")
					behaviors = components.At(i).Get("behaviors");
			Test.Assert((behaviors != null) && (behaviors.Count == 1));
			Test.Assert(behaviors.At(0).Get("script").AsString() == script.ToString(.. scope .()));
			Test.Assert(behaviors.At(0).Get("enabled").AsBool());
			let refused = Call(server, "behavior_add", scope $"{{\"entity\":\"Platform\",\"script\":\"{script}\"}}");
			defer delete refused;
			Test.Assert(refused.Error.Contains("is not a cooked script class"), refused.Error);
		}

		// A deletion takes the subtree; while simulating, every edit is refused.
		{
			let deleted = Call(server, "entity_delete", "{\"entity\":\"Platform\"}");
			defer delete deleted;
			Test.Assert(deleted.Ok, deleted.Error);
			Test.Assert(!scene.FindEntityByName("Platform").IsAssigned);
			page.Simulating = true;
			let locked = Call(server, "entity_create", "{\"name\":\"Late\"}");
			defer delete locked;
			Test.Assert(locked.Error.Contains("is simulating"), locked.Error);
			let gone = Call(server, "entity_delete", "{\"entity\":\"Nobody\"}");
			defer delete gone;
			Test.Assert(!gone.Ok);
		}
	}

	/// A behaviour is one more component to the tools: added by the id its [Behaviour] states, at
	/// its defaults; entity_inspect shows its public fields and the base's Enabled (an enum by name,
	/// an entity reference by guid) and not its private state; component_set writes a float, an
	/// enum by name, an entity reference, a string and Enabled, a step each; component_remove
	/// deletes it, and its undo brings it back with every value.
	[Test]
	public static void ABehaviourIsOneMoreComponentToTheTools()
	{
		let context = scope EditorContext();
		let page = (EditablePage)context.AdoptPage(new EditablePage(Guid.Create()));
		context.SetActivePage(page);
		let edit = page.EditContext;
		let scene = edit.Scene;
		let hoppers = scene.AddSystem<BehaviourManager<Hopper>>();
		let frogId = edit.CreateEntity("Frog");
		let padId = edit.CreateEntity("Pad");
		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		let commands = page.Commands;
		Hopper Live()
		{
			return hoppers.Get(edit.Resolve(frogId));
		}

		{
			let added = Call(server, "component_add", "{\"entity\":\"Frog\",\"component\":\"test.hopper\"}");
			defer delete added;
			Test.Assert(added.Ok, added.Error);
			let hopper = ComponentOf(added.Payload.Get("entity"), "test.hopper");
			Test.Assert(hopper != null, "named by its [Behaviour] id");
			Test.Assert(hopper.Get("typeName").AsString() == "Hopper");
			let properties = hopper.Get("properties");
			Test.Assert(properties.Get("Height").AsNumber() == 1.5);
			Test.Assert(properties.Get("Mode").AsString() == "Off", "an enum by name");
			Test.Assert(properties.Get("Target").IsNull, "an unset entity reference");
			Test.Assert(properties.Get("Label").AsString() == "hop");
			Test.Assert(properties.Get("Enabled").AsBool(), "the base's field");
			Test.Assert(!properties.Has("mAirTime"), "runtime state is not shown");
			Test.Assert(Live() != null);
		}

		void SetOk(StringView property, StringView valueJson)
		{
			let got = Call(server, "component_set", scope $"{{\"entity\":\"Frog\",\"component\":\"test.hopper\",\"property\":\"{property}\",\"value\":{valueJson}}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("component").AsString() == "test.hopper");
		}
		SetOk("Height", "2.5");
		Test.Assert(Live().Height == 2.5f);
		SetOk("Mode", "\"Fast\"");
		Test.Assert(Live().Mode == .Fast);
		SetOk("Target", scope $"\"{padId}\"");
		Test.Assert(Live().Target.Id == padId);
		SetOk("Label", "\"leapy\"");
		Test.Assert(Live().Label == "leapy");
		SetOk("Enabled", "false");
		Test.Assert(!Live().Enabled);
		// A step a call: one undo takes back the last set alone, and redo puts it back.
		commands.Undo();
		Test.Assert(Live().Enabled && (Live().Label == "leapy"));
		commands.Undo();
		Test.Assert(Live().Label == "hop");
		Test.Assert(Live().Target.Id == padId);
		commands.Redo();
		commands.Redo();
		Test.Assert(!Live().Enabled && (Live().Label == "leapy"));
		{
			let inspected = Call(server, "entity_inspect", "{\"entity\":\"Frog\"}");
			defer delete inspected;
			Test.Assert(inspected.Ok, inspected.Error);
			let properties = ComponentOf(inspected.Payload.Get("entity"), "test.hopper").Get("properties");
			Test.Assert(properties.Get("Mode").AsString() == "Fast");
			Test.Assert(properties.Get("Target").AsString() == padId.ToString(.. scope .()));
			Test.Assert(!properties.Get("Enabled").AsBool());
		}
		{
			let wrong = Call(server, "component_set", "{\"entity\":\"Frog\",\"component\":\"test.hopper\",\"property\":\"Mode\",\"value\":\"Sideways\"}");
			defer delete wrong;
			Test.Assert(!wrong.Ok);
			Test.Assert(wrong.Error.StartsWith("field 'Mode' takes one of: Off, Slow, Fast"), wrong.Error);
			let hidden = Call(server, "component_set", "{\"entity\":\"Frog\",\"component\":\"test.hopper\",\"property\":\"mAirTime\",\"value\":1}");
			defer delete hidden;
			Test.Assert(!hidden.Ok, "private state is not a field the tools set");
		}
		commands.Undo();
		Test.Assert(Live().Enabled);
		commands.Undo();
		Test.Assert(Live().Label == "hop");
		commands.Undo();
		Test.Assert(Live().Target.IsNil);
		commands.Redo();
		commands.Redo();
		commands.Redo();

		// Removed and brought back by its undo, every value read from its record.
		{
			let removed = Call(server, "component_remove", "{\"entity\":\"Frog\",\"component\":\"test.hopper\"}");
			defer delete removed;
			Test.Assert(removed.Ok, removed.Error);
			Test.Assert(!HasComponent(removed.Payload.Get("entity"), "test.hopper"));
			Test.Assert(Live() == null);
		}
		commands.Undo();
		Test.Assert(Live() != null);
		Test.Assert((Live().Height == 2.5f) && (Live().Mode == .Fast) && (Live().Target.Id == padId));
		Test.Assert((Live().Label == "leapy") && !Live().Enabled);
	}

	/// A behaviour's asset reference is its guid to the tools, as a component's is: null while
	/// unset, and the guid component_set wrote, which is the identity the instance holds.
	[Test]
	public static void ABehavioursAssetReferenceIsItsGuidToTheTools()
	{
		let context = scope EditorContext();
		let page = (EditablePage)context.AdoptPage(new EditablePage(Guid.Create()));
		context.SetActivePage(page);
		let edit = page.EditContext;
		let hoppers = edit.Scene.AddSystem<BehaviourManager<Hopper>>();
		let frogId = edit.CreateEntity("Frog");
		let server = scope McpServer();
		SceneMcpTools.Register(server, context);

		{
			let added = Call(server, "component_add", "{\"entity\":\"Frog\",\"component\":\"test.hopper\"}");
			defer delete added;
			Test.Assert(added.Ok, added.Error);
			Test.Assert(ComponentOf(added.Payload.Get("entity"), "test.hopper").Get("properties").Get("Prize").IsNull, "an unset reference");
		}
		let prizeId = Guid.Create();
		let prizeText = prizeId.ToString(.. scope String());
		{
			let got = Call(server, "component_set", scope $"{{\"entity\":\"Frog\",\"component\":\"test.hopper\",\"property\":\"Prize\",\"value\":\"{prizeText}\"}}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
		}
		Test.Assert(hoppers.Get(edit.Resolve(frogId)).Prize.Id == prizeId, "the instance holds the identity");
		{
			let inspected = Call(server, "entity_inspect", "{\"entity\":\"Frog\"}");
			defer delete inspected;
			Test.Assert(inspected.Ok, inspected.Error);
			let properties = ComponentOf(inspected.Payload.Get("entity"), "test.hopper").Get("properties");
			Test.Assert(properties.Get("Prize").AsString() == prizeText, "shown as its guid");
		}
	}
}
